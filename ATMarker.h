#import <UIKit/UIKit.h>

@interface AhmadDevLayout : UIView
@property (nonatomic, assign) CGPoint position;
- (void)pulse:(CGFloat)speed;
@end

// Window تمرر اللمس للتطبيق
@interface AhmadDevLayoutWindow : UIWindow
@end
