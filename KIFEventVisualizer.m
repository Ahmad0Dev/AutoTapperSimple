#import "KIFEventVisualizer.h"

@implementation KIFEventVisualizer
+ (instancetype)sharedVisualizer {
    static KIFEventVisualizer *i = nil;
    static dispatch_once_t t;
    dispatch_once(&t, ^{ i = [KIFEventVisualizer new]; });
    return i;
}
- (void)visualizeEvent:(UIEvent *)event {}
@end
