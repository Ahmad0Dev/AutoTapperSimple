#import "ATTouchPool.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <os/lock.h>
#import <mach/mach_time.h>
#import <dlfcn.h>

// ── IOHIDEvent ──
typedef struct __IOHIDEvent *IOHIDEventRef;
typedef IOHIDEventRef (*CreateDigitizerFn)(CFAllocatorRef,uint64_t,uint32_t,uint32_t,uint32_t,uint32_t,uint32_t,uint32_t,double,double,double,double,double,double,double,double,Boolean,Boolean,uint32_t);
typedef IOHIDEventRef (*CreateFingerFn)(CFAllocatorRef,uint64_t,uint32_t,uint32_t,uint32_t,uint32_t,uint32_t,uint32_t,double,double,double,double,double,double,double,double,Boolean,Boolean,uint32_t);
typedef void (*SetIntFn)(IOHIDEventRef,uint32_t,int32_t);
typedef void (*AppendFn)(IOHIDEventRef,IOHIDEventRef);

static CreateDigitizerFn _createDigitizer = NULL;
static CreateFingerFn    _createFinger    = NULL;
static SetIntFn          _setInt          = NULL;
static AppendFn          _append          = NULL;

static void loadIOHID(void) {
    static dispatch_once_t t;
    dispatch_once(&t, ^{
        void *h = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_NOW);
        if (!h) h = dlopen("/System/Library/PrivateFrameworks/IOKit.framework/IOKit", RTLD_NOW);
        if (h) {
            _createDigitizer = dlsym(h, "IOHIDEventCreateDigitizerEvent");
            _createFinger    = dlsym(h, "IOHIDEventCreateDigitizerFingerEventWithQuality");
            _setInt          = dlsym(h, "IOHIDEventSetIntegerValue");
            _append          = dlsym(h, "IOHIDEventAppendEvent");
        }
    });
}

// ── بناء IOHIDEvent من touches (مطابق لـ IDA 100%) ──
static IOHIDEventRef buildHIDEvent(NSArray *touches) {
    loadIOHID();
    if (!_createDigitizer || !_createFinger) return NULL;

    uint64_t ts = mach_absolute_time();
    IOHIDEventRef digitizer = _createDigitizer(kCFAllocatorDefault, ts,
        3,0,0,2,0,0, 0,0,0,0,0,0,0,0, YES,YES,0);
    if (!digitizer) return NULL;
    _setInt(digitizer, 720921, 1);

    for (UITouch *touch in touches) {
        if ([touch isKindOfClass:[NSNull class]]) continue;
        uint32_t mask    = (touch.phase == UITouchPhaseMoved) ? 4 : 3;
        BOOL     isTouch = (touch.phase != UITouchPhaseEnded);
        CGPoint  loc     = [touch locationInView:nil];
        uint32_t idx     = (uint32_t)[touches indexOfObject:touch] + 1;

        IOHIDEventRef finger = _createFinger(kCFAllocatorDefault, ts,
            idx, 2, mask,
            (uint32_t)isTouch, (uint32_t)isTouch, 0,
            loc.x, loc.y, 0, 0, 0, 5.0, 5.0, 1.0,
            YES, YES, 0);
        if (finger) {
            _setInt(finger, 720921, 1);
            _append(digitizer, finger);
            CFRelease(finger);
        }
    }
    return digitizer;
}

// ── UITouch private methods (نستدعيها مباشرة بدون Categories) ──
static void touch_setWindow(UITouch *t, UIWindow *w) {
    SEL s = NSSelectorFromString(@"setWindow:");
    if ([t respondsToSelector:s])
        ((void(*)(id,SEL,id))objc_msgSend)(t, s, w);
    else
        [t setValue:w forKey:@"window"];
}

static void touch_setView(UITouch *t, UIView *v) {
    SEL s = NSSelectorFromString(@"setView:");
    if ([t respondsToSelector:s])
        ((void(*)(id,SEL,id))objc_msgSend)(t, s, v);
    else if (v)
        [t setValue:v forKey:@"view"];
}

static void touch_setLocationInWindow(UITouch *t, CGPoint p, BOOL reset) {
    SEL s = NSSelectorFromString(@"_setLocationInWindow:resetPrevious:");
    if ([t respondsToSelector:s]) {
        typedef void(*fn)(id,SEL,CGPoint,BOOL);
        ((fn)objc_msgSend)(t, s, p, reset);
    } else {
        [t setValue:[NSValue valueWithCGPoint:p] forKey:@"locationInWindow"];
    }
}

static void touch_setPhaseAndTimestamp(UITouch *t, UITouchPhase phase) {
    // setPhaseAndUpdateTimestamp: (من IDA)
    NSTimeInterval uptime = [[NSProcessInfo processInfo] systemUptime];
    SEL ts = NSSelectorFromString(@"setTimestamp:");
    if ([t respondsToSelector:ts])
        ((void(*)(id,SEL,NSTimeInterval))objc_msgSend)(t, ts, uptime);
    SEL ps = NSSelectorFromString(@"setPhase:");
    if ([t respondsToSelector:ps])
        ((void(*)(id,SEL,NSInteger))objc_msgSend)(t, ps, (NSInteger)phase);
}

static void touch_setHIDEvent(UITouch *t, IOHIDEventRef ev) {
    // _setHidEvent: هو الـ selector الصحيح من IDA
    const char *selNames[] = {"_setHidEvent:", "_setHIDEvent:", "kif_setHidEvent"};
    for (int i = 0; i < 3; i++) {
        SEL s = sel_registerName(selNames[i]);
        if ([t respondsToSelector:s]) {
            typedef void(*fn)(id,SEL,IOHIDEventRef);
            ((fn)objc_msgSend)(t, s, ev);
            return;
        }
    }
}

// ── UITouch إنشاء من IDA initAtPoint:inWindow: ──
static UITouch *buildTouch(CGPoint point, UIWindow *win) {
    UITouch *t = [[UITouch alloc] init];
    if (!t) return nil;

    touch_setWindow(t, win);
    touch_setLocationInWindow(t, point, YES); // resetPrevious=YES

    UIView *hit = [win hitTest:point withEvent:nil];
    touch_setView(t, hit);

    // setPhase:0 (Began)
    SEL ps = NSSelectorFromString(@"setPhase:");
    if ([t respondsToSelector:ps])
        ((void(*)(id,SEL,NSInteger))objc_msgSend)(t, ps, 0);

    // _setIsFirstTouchForView: أو _setIsTapToClick:
    SEL s1 = NSSelectorFromString(@"_setIsFirstTouchForView:");
    SEL s2 = NSSelectorFromString(@"_setIsTapToClick:");
    if ([t respondsToSelector:s1])
        ((void(*)(id,SEL,BOOL))objc_msgSend)(t, s1, YES);
    else if ([t respondsToSelector:s2])
        ((void(*)(id,SEL,BOOL))objc_msgSend)(t, s2, YES);

    // setTimestamp:
    NSTimeInterval uptime = [[NSProcessInfo processInfo] systemUptime];
    SEL ts = NSSelectorFromString(@"setTimestamp:");
    if ([t respondsToSelector:ts])
        ((void(*)(id,SEL,NSTimeInterval))objc_msgSend)(t, ts, uptime);

    // setGestureView:
    SEL gs = NSSelectorFromString(@"setGestureView:");
    if ([t respondsToSelector:gs])
        ((void(*)(id,SEL,id))objc_msgSend)(t, gs, hit);

    // kif_setHidEvent (iOS 9+)
    IOHIDEventRef hid = buildHIDEvent(@[t]);
    if (hid) {
        touch_setHIDEvent(t, hid);
        CFRelease(hid);
    }

    return t;
}

// ── إرسال event (مطابق لـ AhmadDev eventWithTouches: من IDA) ──
static void sendTouches(NSArray *_ahmaddevPool) {
    // فلترة NSNull
    NSMutableArray *validTouches = [NSMutableArray array];
    for (id t in _ahmaddevPool) {
        if (![t isKindOfClass:[NSNull class]])
            [validTouches addObject:t];
    }
    if (validTouches.count == 0) return;

    UIApplication *app = [UIApplication sharedApplication];

    // _touchesEvent (من IDA)
    SEL tes = NSSelectorFromString(@"_touchesEvent");
    if (![app respondsToSelector:tes]) return;
    UIEvent *event = ((UIEvent*(*)(id,SEL))objc_msgSend)(app, tes);
    if (!event) return;

    // _clearTouches
    SEL cs = NSSelectorFromString(@"_clearTouches");
    if ([event respondsToSelector:cs])
        ((void(*)(id,SEL))objc_msgSend)(event, cs);

    // ahmaddev_processEvent: → t8nee_commitEvent:
    IOHIDEventRef hid = buildHIDEvent(validTouches);
    if (hid) {
        SEL setHID = NSSelectorFromString(@"_setHIDEvent:");
        if ([event respondsToSelector:setHID]) {
            typedef void(*fn)(id,SEL,IOHIDEventRef);
            ((fn)objc_msgSend)(event, setHID, hid);
        }
        CFRelease(hid);
    }

    // _addTouch:forDelayedDelivery:
    SEL addTouch = NSSelectorFromString(@"_addTouch:forDelayedDelivery:");
    if ([event respondsToSelector:addTouch]) {
        for (UITouch *t in validTouches) {
            typedef void(*fn)(id,SEL,id,BOOL);
            ((fn)objc_msgSend)(event, addTouch, t, NO);
        }
    }

    [app sendEvent:event];
}

// ── Pool ──
#define AT_POOL_SIZE 100
static NSMutableArray *_ahmaddevPool = nil;
static os_unfair_lock _lock = OS_UNFAIR_LOCK_INIT;

@implementation T8neeChain

+ (void)setup {
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        _ahmaddevPool = [[NSMutableArray alloc] init];
        for (int i = 0; i < AT_POOL_SIZE; i++)
            [_ahmaddevPool addObject:[NSNull null]];
    });
}

+ (NSInteger)getAvailablePointId {
    if (!_ahmaddevPool) [self setup];
    os_unfair_lock_lock(&_lock);

    NSMutableArray *avail = [NSMutableArray array];
    NSInteger limit = (NSInteger)_ahmaddevPool.count - 50;
    for (NSInteger i = 0; i < limit; i++) {
        id obj = _ahmaddevPool[i];
        if ([obj isKindOfClass:[NSNull class]]) {
            [avail addObject:@(i+1)]; continue;
        }
        UITouchPhase p = [(UITouch*)obj phase];
        if (p == UITouchPhaseEnded || p == UITouchPhaseStationary)
            [avail addObject:@(i+1)];
    }

    NSInteger result = 0;
    if (avail.count > 0)
        result = [avail[arc4random() % avail.count] integerValue];

    os_unfair_lock_unlock(&_lock);
    return result;
}

+ (NSInteger)fakeTouchId:(NSInteger)pointId
                 atPoint:(CGPoint)point
          withTouchPhase:(UITouchPhase)phase {

    if (!_ahmaddevPool) [self setup];
    if (pointId == 0) {
        pointId = [self getAvailablePointId];
        if (pointId == 0) return 0;
    }

    NSInteger index = pointId - 1;
    if (index < 0 || index >= (NSInteger)_ahmaddevPool.count) return 0;

    @try {
        id obj = _ahmaddevPool[index];
        UITouch *touch = nil;

        if (phase == UITouchPhaseBegan || [obj isKindOfClass:[NSNull class]]) {
            UIWindow *win = [self keyWindow];
            if (!win) return 0;
            touch = buildTouch(point, win);
            if (!touch) return 0;
            [_ahmaddevPool replaceObjectAtIndex:index withObject:touch];
            // setLocationInWindow: (resetPrevious=NO من IDA)
            touch_setLocationInWindow(touch, point, NO);
        } else {
            touch = (UITouch *)obj;
            // setLocationInWindow: (resetPrevious=NO)
            touch_setLocationInWindow(touch, point, NO);
            touch_setPhaseAndTimestamp(touch, phase);
        }

        // إرسال (مطابق لـ h5gg)
        sendTouches(_ahmaddevPool);

        // بعد الإرسال: Began أو Moved → Stationary
        UITouchPhase cur = touch.phase;
        if (cur == UITouchPhaseBegan || cur == UITouchPhaseMoved)
            touch_setPhaseAndTimestamp(touch, UITouchPhaseStationary);

    } @catch (NSException *e) {
    // NSLog(@"[ATPool] %@", e);
    }

    return pointId;
}

+ (UIWindow *)keyWindow {
    for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if (scene.activationState == UISceneActivationStateForegroundActive) {
            for (UIWindow *w in scene.windows)
                if (w.isKeyWindow) return w;
            return scene.windows.firstObject;
        }
    }
    return nil;
}

+ (instancetype)shared {
    static T8neeChain *i; static dispatch_once_t t;
    dispatch_once(&t, ^{ i = [T8neeChain new]; });
    return i;
}

@end
