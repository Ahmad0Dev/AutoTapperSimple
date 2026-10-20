# AutoTapperSimple - توثيق المشروع الكامل
**by AhmadDev | t8nee**

---

## نظرة عامة

AutoTapperSimple هو dylib يُحقن في تطبيقات iOS عبر esign لتنفيذ لمسات تلقائية. مبني بالكامل من تحليل IDA Pro لـ h5gg (ATTouchEngine.dylib) مع إعادة كتابة كاملة بدون الاعتماد على أي مكتبة خارجية نشطة.

---

## هيكل المشروع

```
AutoTapperSimple/
├── main.m              ← نقطة الدخول + Constructor
├── ATEngine.m/h        ← محرك التشغيل (Timer)
├── ATTouchPool.m/h     ← محرك اللمس الحقيقي
├── ATSimplePanel.m/h   ← واجهة المستخدم
├── ATHelpView.m/h      ← صفحة التعليمات
├── ATMarker.m/h        ← مؤشر موضع اللمس
├── ATGuard.m/h         ← نظام الحماية
├── ATSilencer.m/h      ← إسكات رسائل h5gg
├── ATTerms.m/h         ← نافذة شروط الاستخدام
├── ATWatermark.m       ← توقيع المطور
├── ATCrypt.h           ← تشفير XOR للنصوص
├── IOHIDEvent+KIF.m/h  ← بناء IOHIDEvent
└── [ملفات KIF]         ← UIKit extensions مُعاد تسميتها
```

---

## المكونات الأساسية

### 1. ATTouchPool - محرك اللمس

هذا هو قلب المشروع. مبني 100% من تحليل IDA Pro لـ `PTFakeMetaTouch` في h5gg.

#### Pool (مصفوفة اللمسات)

```
[NSNull, NSNull, ..., NSNull]  ← 100 عنصر
 index:  0       1        99
 pointId:1       2        100
```

- 100 عنصر يمثلون نقاط لمس متاحة
- `NSNull` = متاح للاستخدام
- `UITouch` = مستخدم حالياً

#### getAvailablePointId
```
- يبحث في أول 50 عنصر فقط (count - 50)
- يجمع المتاحين (NSNull أو Ended أو Stationary)
- يختار عشوائياً بـ arc4random
- يعيد index + 1 (وليس index مباشرة)
- يعيد 0 عند الفشل
```

#### fakeTouchId:atPoint:withTouchPhase:
```
phase == Began:
  → buildTouch() ← ينشئ UITouch جديد
  → replaceObjectAtIndex ← يضعه في الـ pool
  → sendTouches() ← يرسل
  → setPhase:Stationary ← بعد الإرسال

phase != Began:
  → setLocationInWindow (resetPrevious=NO)
  → setPhaseAndTimestamp
  → sendTouches()
  → setPhase:Stationary (إذا Began أو Moved)
```

#### buildTouch (من IDA initAtPoint:inWindow:)
```objc
UITouch *t = [[UITouch alloc] init]
setWindow(t, keyWindow)
_setLocationInWindow:resetPrevious:YES   ← YES عند الإنشاء
hitTest → setView(hit)
setPhase:0 (Began)
_setIsFirstTouchForView:YES
setTimestamp:uptime
setGestureView:hit
buildHIDEvent → _setHidEvent:           ← ربط IOHIDEvent
```

#### sendTouches (من IDA PTFakeMetaTouch eventWithTouches:)
```objc
UIEvent *event = [UIApplication _touchesEvent]
[event _clearTouches]
IOHIDEventRef hid = buildHIDEvent(touches)
[event _setHIDEvent:hid]
for touch in touches:
    [event _addTouch:touch forDelayedDelivery:NO]
[UIApplication sendEvent:event]
```

#### buildHIDEvent (من IDA kif_IOHIDEventWithTouches)
```objc
ts = mach_absolute_time()

// Digitizer رئيسي
digitizer = IOHIDEventCreateDigitizerEvent(kCFAllocatorDefault, ts, 3,0,0,2,...)
IOHIDEventSetIntegerValue(digitizer, 720921, 1)

// Finger لكل touch
for touch in touches:
    mask = (phase==Moved) ? 4 : 3
    isTouch = (phase != Ended)
    loc = locationInView:nil
    idx = indexOfObject:touch + 1
    finger = IOHIDEventCreateDigitizerFingerEventWithQuality(...)
    IOHIDEventSetIntegerValue(finger, 720921, 1)
    IOHIDEventAppendEvent(digitizer, finger)
```

---

### 2. ATEngine - محرك التشغيل

يتحكم في سرعة اللمس والتوقيت عبر NSTimer.

```
start() → NSTimer (interval = 1/tapSpeed)
timer fires → tick() → tap(x, y)

tap(x, y):
  pid = getAvailablePointId
  fakeTouchId(pid, Began)  ← فوري
  fakeTouchId(pid, Ended)  ← فوري بدون delay
```

**أنماط اللمس المستخرجة من IDA:**

| النمط | التسلسل |
|-------|---------|
| **tap** | Began → Ended فوراً |
| **press** | Began → dispatch_after(delay) → Ended |
| **swipe** | dispatch_after(d/2) → Began(x1,y1) → dispatch_after(d/2) → Moved(x2,y2) → dispatch_after(d/2) → Ended(x2,y2) |
| **touchstart** | pid = Began → حفظ pid |
| **touchmove** | Moved(pid المحفوظ) |
| **touchend** | Ended(pid المحفوظ) |

---

### 3. ATSimplePanel - واجهة المستخدم

لوحة تحكم عائمة تحتوي:
- سلايدر السرعة (1-30 tap/sec)
- زر تشغيل/إيقاف
- عرض الإحداثيات الحالية
- زر التعليمات

---

### 4. ATMarker - مؤشر اللمس

دائرة شفافة تظهر على الشاشة في مكان اللمس المحدد.

---

### 5. ATGuard - نظام الحماية

يتحقق من سلامة الأداة دورياً. عند اكتشاف تلاعب يفتح enjoyteam.app تلقائياً.

---

### 6. ATSilencer - إسكات h5gg

يعطل رسالة الترحيب في H5GGTouch عبر method swizzle في حال وجود h5gg.

---

### 7. ATTerms - شروط الاستخدام

نافذة تظهر عند أول تشغيل تحتوي على شروط الاستخدام وحقوق الملكية.

- الموافقة محفوظة في **Keychain** (لا يمكن حذفها بسهولة)
- جميع النصوص مشفرة بـ XOR
- لا تظهر مرة ثانية بعد الموافقة

---

### 8. ATCrypt - تشفير النصوص

تشفير XOR بـ key = 0x5A لجميع النصوص الحساسة.

```objc
#define AT(hex) _d(hex)

// مثال - تشفير نص
// "telegram" → AT("3b3f363631353b")
```

لتشفير نص جديد:
```python
KEY = 0x5A
def encrypt(s):
    return ''.join(f'{b ^ KEY:02x}' for b in s.encode('utf-8'))
```

---

## لماذا نجح الكود

المشكلة الأساسية كانت أن KIF Categories لا تُحمَّل تلقائياً في dylib.

**الحل:** استدعاء private methods مباشرة عبر `objc_msgSend` و `NSSelectorFromString` بدون Categories:

```objc
// بدل (لا يعمل بدون Categories محملة)
[touch setPhaseAndUpdateTimestamp:phase];

// نستخدم
SEL s = NSSelectorFromString(@"setPhase:");
((void(*)(id,SEL,NSInteger))objc_msgSend)(touch, s, phase);
```

---

## الأسماء في IDA (Obfuscation)

| الاسم الظاهر في IDA | الوظيفة الحقيقية |
|--------------------|----------------|
| `T8neeChain` | ATTouchPool |
| `NSURLSessionDelegate` | ATEngine |
| `CAEventDispatchQueue` | ATSimplePanel |
| `CFSocketRunLoopSource` | ATMarker |
| `UITextInteractionSession` | ATGuard |
| `NSInputManagerContext` | ATSilencer |
| `UIInputSystemClient` | ATHelpView |
| `ahmaddev_processEvent` | sendTouches |
| `t8nee_scheduleEvent` | kif_setEventWithTouches |
| `_ahmaddevPool` | touchAry (pool array) |
| `AhmadDev` | توقيع المطور |
| `T8nee` | اسم الفريق |

---

## التقنيات المستخدمة

| التقنية | الاستخدام |
|---------|-----------|
| `objc_msgSend` مباشر | استدعاء private methods |
| `IOKit dlopen` | تحميل IOHIDEvent functions |
| `mach_absolute_time` | timestamp دقيق |
| `os_unfair_lock` | thread safety للـ pool |
| `Security/Keychain` | حفظ موافقة الشروط |
| `dispatch_once` | تهيئة آمنة |
| XOR encryption | إخفاء النصوص |

---

## ملاحظات مهمة

- يعمل على **iOS 15+** وتم اختباره على **iOS 26.1**
- يُحقن عبر **esign** مباشرة في الـ IPA
- مستقل تماماً - لا يحتاج h5gg أو أي dylib خارجي
- جميع الحقوق محفوظة لـ **AhmadDev | t8nee** ©

