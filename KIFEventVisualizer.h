#import <UIKit/UIKit.h>

@interface KIFEventVisualizer : NSObject
+ (instancetype)sharedVisualizer;
- (void)visualizeEvent:(UIEvent *)event;
@end
