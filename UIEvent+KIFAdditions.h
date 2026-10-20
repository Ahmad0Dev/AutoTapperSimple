//
//  UIEvent+T8nee.h
//  KIF
//
//  Created by Thomas on 3/1/15.
//
//

#import <UIKit/UIKit.h>

// Exposes methods of UITouchesEvent so that the compiler doesn't complain
@interface UIEvent (T8neePrivateHeaders)
- (void)_addTouch:(UITouch *)touch forDelayedDelivery:(BOOL)arg2;
- (void)_clearTouches;
@end

@interface UIEvent (T8nee)
- (void)ahmaddev_processEvent:(NSArray *)touches;
@end
