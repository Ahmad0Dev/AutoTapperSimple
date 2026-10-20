#import <UIKit/UIKit.h>

@interface T8neeChain : NSObject
+ (instancetype)shared;
+ (void)setup;
+ (NSInteger)getAvailablePointId;
+ (NSInteger)fakeTouchId:(NSInteger)pointId
                 atPoint:(CGPoint)point
          withTouchPhase:(UITouchPhase)phase;
@end
