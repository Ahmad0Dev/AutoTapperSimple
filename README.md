# AutoTapperSimple

An iOS tweak that adds a floating panel and movable marker for repeating taps at a chosen screen position.

**Topics:** iOS, Objective-C, Theos, UIKit, IOHID, accessibility, jailbreak tweak

## English

### What it does

- Displays a movable floating control panel and tap marker.
- Starts and stops repeated taps at the selected point.
- The current control panel offers a rate from **1 to 10 taps per second**.
- Builds as an Objective-C Theos tweak for arm64, with an iOS 15.0 deployment target.

### Repository contents

- `main.m` and the `AT*.m` / `AT*.h` files implement the tweak, panel, touch synthesis, guard, help and marker components.
- `Makefile`, `control`, and `AutoTapperSimple.plist` contain Theos packaging and injection configuration.
- `AutoTapperSimple_Docs.md` is the Arabic document from the supplied archive.
- `KIF*` and related helper files are KIF-derived test/event helpers; see `KIF-LICENSE` for their Apache-2.0 notice.

### Build

Build on macOS or Linux with Theos and a compatible iOS SDK:

```sh
export THEOS=/path/to/theos
make package
```

This is a tweak, not a standalone App Store app. It uses private UIKit and IOHID touch interfaces. The source has not been built or device-tested during repository preparation.

### Known limitations

- The Arabic archive document describes 1–30 taps per second and press/swipe/touch-sequence modes. Those claims do not match the current panel, which exposes 1–10 taps per second and repeated taps.
- `ATTerms` contains a consent flow, but the current initialization path does not invoke it.
- The guard checks a singleton accessor that creates the singleton when called, so its missing-instance check does not work as intended.
- Private iOS interfaces can change between system versions.

### Rights and use

The supplied project documentation states © AhmadDev and all rights reserved; it contains no license grant for the project code. KIF-derived files retain their upstream Apache-2.0 notice in `KIF-LICENSE`. Check that you have the necessary rights and permissions before redistributing or using this tweak.

## العربية

### وصف المشروع

تعديل لنظام iOS يضيف لوحة عائمة ومؤشرًا قابلًا للتحريك لتكرار النقر في موضع محدد على الشاشة.

### الوظائف الحالية

- لوحة تحكم عائمة يمكن تحريكها مع مؤشر لموضع النقر.
- بدء وإيقاف النقر المتكرر.
- معدل النقر المتاح حاليًا من **1 إلى 10 نقرات في الثانية**.
- مشروع Objective-C يُبنى باستخدام Theos لمعمارية arm64، وبحد أدنى مستهدف iOS 15.0.

### محتويات المستودع

- يحتوي `main.m` وملفات `AT*.m` و`AT*.h` على منطق التعديل واللوحة وتوليد اللمس والحماية والمساعدة والمؤشر.
- يحتوي `Makefile` و`control` و`AutoTapperSimple.plist` على إعدادات بناء وحزم Theos.
- الملف `AutoTapperSimple_Docs.md` هو المستند العربي الموجود في الأرشيف الأصلي.
- ملفات `KIF*` والملفات المساعدة ذات الصلة مشتقة من KIF؛ راجع إشعار Apache 2.0 في `KIF-LICENSE`.

### البناء

يتطلب البناء macOS أو Linux مع Theos وSDK مناسب لـ iOS:

```sh
export THEOS=/path/to/theos
make package
```

هذا تعديل للنظام وليس تطبيقًا مستقلًا في App Store. يعتمد على واجهات لمس خاصة في UIKit وIOHID. لم يُبنَ المشروع ولم يُختبر على جهاز أثناء إعداد المستودع.

### القيود المعروفة

- يذكر المستند العربي في الأرشيف معدلًا من 1 إلى 30 نقرة في الثانية وأنماط ضغط وسحب وتسلسلات لمس. هذه المعلومات لا تطابق اللوحة الحالية، التي توفر 1–10 نقرات في الثانية والنقر المتكرر فقط.
- يحتوي `ATTerms` على شاشة موافقة، لكن مسار التهيئة الحالي لا يستدعيها.
- يستدعي فحص الحماية دالة singleton تنشئ الكائن عند استدعائها؛ لذلك لا يعمل فحص غياب الكائن كما هو مقصود.
- قد تتغير واجهات iOS الخاصة بين الإصدارات.

### الحقوق والاستخدام

تنص وثائق المشروع المرفقة على © AhmadDev وجميع الحقوق محفوظة، ولا تتضمن ترخيصًا عامًا لشيفرة المشروع. ملفات KIF المشتقة تحتفظ بإشعار Apache 2.0 في `KIF-LICENSE`. تأكد من امتلاكك الحقوق والتصاريح اللازمة قبل إعادة التوزيع أو الاستخدام.
