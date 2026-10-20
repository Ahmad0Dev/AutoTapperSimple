#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>

// IOHIDEventRef typedef
typedef struct __IOHIDEvent *IOHIDEventRef;

CF_EXTERN_C_BEGIN
IOHIDEventRef t8nee_scheduleEvent(NSArray *touches);
CF_EXTERN_C_END
