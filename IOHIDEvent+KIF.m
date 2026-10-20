#import "IOHIDEvent+KIF.h"
#import <UIKit/UIKit.h>
#import <mach/mach_time.h>
#import <dlfcn.h>

// IOHIDEvent functions - من IOKit
typedef CFTypeRef (*IOHIDEventCreateDigitizerEventFunc)(
    CFAllocatorRef, uint64_t, uint32_t, uint32_t, uint32_t,
    uint32_t, uint32_t, uint32_t, double, double,
    double, double, double, double, double, double,
    Boolean, Boolean, uint32_t);

typedef CFTypeRef (*IOHIDEventCreateDigitizerFingerEventWithQualityFunc)(
    CFAllocatorRef, uint64_t, uint32_t, uint32_t, uint32_t,
    uint32_t, uint32_t, uint32_t, double, double,
    double, double, double, double, double, double,
    Boolean, Boolean, uint32_t);

typedef void (*IOHIDEventSetIntegerValueFunc)(CFTypeRef, uint32_t, int32_t);
typedef void (*IOHIDEventAppendEventFunc)(CFTypeRef, CFTypeRef);

static void *iokitHandle = NULL;
static IOHIDEventCreateDigitizerEventFunc _createDigitizerEvent = NULL;
static IOHIDEventCreateDigitizerFingerEventWithQualityFunc _createFingerEvent = NULL;
static IOHIDEventSetIntegerValueFunc _setIntValue = NULL;
static IOHIDEventAppendEventFunc _appendEvent = NULL;

static void loadIOKit(void) {
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        iokitHandle = dlopen("/System/Library/PrivateFrameworks/IOKit.framework/IOKit", RTLD_NOW);
        if (!iokitHandle)
            iokitHandle = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_NOW);
        if (iokitHandle) {
            _createDigitizerEvent = dlsym(iokitHandle, "IOHIDEventCreateDigitizerEvent");
            _createFingerEvent = dlsym(iokitHandle, "IOHIDEventCreateDigitizerFingerEventWithQuality");
            _setIntValue = dlsym(iokitHandle, "IOHIDEventSetIntegerValue");
            _appendEvent = dlsym(iokitHandle, "IOHIDEventAppendEvent");
        }
    });
}

// مطابق 100% لكود h5gg من IDA
IOHIDEventRef t8nee_scheduleEvent(NSArray *touches) {
    loadIOKit();
    if (!_createDigitizerEvent || !_createFingerEvent || !_setIntValue || !_appendEvent)
        return NULL;

    uint64_t ts = mach_absolute_time();

    // IOHIDEventCreateDigitizerEvent - من IDA: يمرر 0 لكل arguments
    IOHIDEventRef digitizerEvent = _createDigitizerEvent(
        kCFAllocatorDefault, ts,
        3, 0, 0, 2, 0, 0,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        YES, YES, 0);

    if (!digitizerEvent) return NULL;

    _setIntValue(digitizerEvent, 720921, 1);

    for (UITouch *touch in touches) {
        // phase: Moved=1 → 4, else → 3
        uint32_t eventMask = (touch.phase == UITouchPhaseMoved) ? 4 : 3;

        // phase != Ended
        BOOL isTouch = (touch.phase != UITouchPhaseEnded);

        // موقع اللمس
        CGPoint loc = [touch locationInView:nil];

        // finger index = indexOfObject + 1
        uint32_t fingerIndex = (uint32_t)[touches indexOfObject:touch] + 1;

        IOHIDEventRef fingerEvent = _createFingerEvent(
            kCFAllocatorDefault, ts,
            fingerIndex,          // finger index
            2,                    // collection usage
            eventMask,            // event mask
            (uint32_t)isTouch,   // touch
            (uint32_t)isTouch,   // range
            0,                    // pressure
            loc.x,               // x
            loc.y,               // y
            0.0, 0.0,            // major/minor radius
            0.0,                 // pressure
            5.0,                 // angle
            5.0,                 // density
            1.0,                 // irregularity
            YES, YES, 0);

        if (fingerEvent) {
            _setIntValue(fingerEvent, 720921, 1);
            _appendEvent(digitizerEvent, fingerEvent);
            CFRelease(fingerEvent);
        }
    }

    return digitizerEvent;
}
