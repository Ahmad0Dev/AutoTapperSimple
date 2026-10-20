#import <UIKit/UIKit.h>

@interface AhmadDevDelegate : NSObject
+ (instancetype)shared;
- (void)start;
- (void)stop;
- (BOOL)isRunning;
@property (nonatomic, assign) CGFloat tapX;
@property (nonatomic, assign) CGFloat tapY;
@property (nonatomic, assign) CGFloat tapSpeed;
@end
