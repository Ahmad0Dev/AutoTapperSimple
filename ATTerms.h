#import <UIKit/UIKit.h>

@interface ATTerms : NSObject
+ (void)showIfNeededWithCompletion:(void(^)(BOOL accepted))completion;
+ (BOOL)hasAccepted;
@end
