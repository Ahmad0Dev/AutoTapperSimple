#import "NSObject+KIFAdditions.h"

@implementation NSObject (T8nee)

- (BOOL)KIF_isAccessibilityAdjustable {
    return (self.accessibilityTraits & UIAccessibilityTraitAdjustable) != 0;
}

@end
