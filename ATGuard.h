#import <UIKit/UIKit.h>

@interface T8neeObserver : NSObject
+ (void)startGuarding; // يبدأ المراقبة
+ (BOOL)isSystemValid; // هل النظام سليم؟
@end
