//
//  UIApplication-T8nee.m
//  KIF
//
//  Created by Eric Firestone on 5/20/11.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#import "UIApplication-KIFAdditions.h"
#import "UIWindow-KIFAdditions.h"
#import "LoadableCategory.h"
#import "UIView-KIFAdditions.h"
#import "NSError-KIFAdditions.h"
#import "KIFEventVisualizer.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import <objc/message.h>

MAKE_CATEGORIES_LOADABLE(UIApplication_T8nee)

static BOOL _KIF_UIApplicationMockOpenURL = NO;
static BOOL _KIF_UIApplicationMockOpenURL_returnValue = NO;

SInt32 KIFRunLoopRunInModeRelativeToAnimationSpeed(CFStringRef mode, CFTimeInterval seconds, Boolean returnAfterSourceHandled)
{
    CFTimeInterval scaledSeconds = seconds / [UIApplication sharedApplication].animationSpeed;
    return CFRunLoopRunInMode(mode, scaledSeconds, returnAfterSourceHandled);
}

@interface UIApplication (Undocumented)
- (void)pushRunLoopMode:(id)arg1;
- (void)pushRunLoopMode:(id)arg1 requester:(id)requester;
- (void)popRunLoopMode:(id)arg1;
- (void)popRunLoopMode:(id)arg1 requester:(id)requester;
@end

NSString *const UIApplicationDidMockOpenURLNotification = @"UIApplicationDidMockOpenURLNotification";
NSString *const UIApplicationDidMockCanOpenURLNotification = @"UIApplicationDidMockCanOpenURLNotification";
NSString *const UIApplicationOpenedURLKey = @"UIApplicationOpenedURL";
static const void *KIFRunLoopModesKey = &KIFRunLoopModesKey;

@implementation UIApplication (T8nee)

#pragma mark - Finding elements

- (UIAccessibilityElement *)accessibilityElementWithLabel:(NSString *)label accessibilityValue:(NSString *)value traits:(UIAccessibilityTraits)traits;
{
    // Go through the array of windows in reverse order to process the frontmost window first.
    // When several elements with the same accessibilitylabel are present the one in front will be picked.
    for (UIWindow *window in [self.windowsWithKeyWindow reverseObjectEnumerator]) {
        if (window.hidden) {
            continue;
        }
        UIAccessibilityElement *element = [window accessibilityElementWithLabel:label accessibilityValue:value traits:traits];
        if (element) {
            return element;
        }
    }
    
    return nil;
}

- (UIAccessibilityElement *)accessibilityElementMatchingBlock:(BOOL(^)(UIAccessibilityElement *))matchBlock;
{
    return [self accessibilityElementMatchingBlock:matchBlock disableScroll:NO];
}

- (UIAccessibilityElement *)accessibilityElementMatchingBlock:(BOOL(^)(UIAccessibilityElement *))matchBlock disableScroll:(BOOL)scrollDisabled;
{
    for (UIWindow *window in [self.windowsWithKeyWindow reverseObjectEnumerator]) {
        UIAccessibilityElement *element = [window accessibilityElementMatchingBlock:matchBlock disableScroll:scrollDisabled];
        if (element) {
            return element;
        }
    }
    
    return nil;
}

#pragma mark - Interesting windows

- (UIWindow *)keyboardWindow;
{
    for (UIWindow *window in self.windowsWithKeyWindow) {
        if ([NSStringFromClass([window class]) isEqual:@"UITextEffectsWindow"]) {
            return window;
        }
    }
    
    return nil;
}

- (UIWindow *)datePickerWindow;
{
    return [self getWindowForSubviewClass:@"UIDatePicker"];
}

- (UIWindow *)pickerViewWindow;
{
    return [self getWindowForSubviewClass:@"UIPickerView"];
}

- (UIWindow *)dimmingViewWindow;
{
    return [self getWindowForSubviewClass:@"UIDimmingView"];
}

- (NSArray<UIResponder *> *)firstResponders;
{
    NSMutableArray *responders = [NSMutableArray array];

    for (UIWindow *window in [[self windowsWithKeyWindow] reverseObjectEnumerator]) {
        UIResponder *responder = window.firstResponder;
        if (responder) {
            [responders addObject:responder];
        }
    }

    return [responders copy];
}

- (UIWindow *)getWindowForSubviewClass:(NSString*)className;
{
    for (UIWindow *window in self.windowsWithKeyWindow) {
        NSArray *subViews = [window subviewsWithClassNameOrSuperClassNamePrefix:className];
        if (subViews.count > 0) {
            return window;
        }
    }

    return nil;
}

- (NSArray *)windowsWithKeyWindow
{
    NSMutableArray *windows = [NSMutableArray array];
    
    for (UIWindowScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if ([scene isKindOfClass:[UIWindowScene class]]) {
            [windows addObjectsFromArray:scene.windows];
        }
    }
    
    return windows;
}

- (UIWindow *)windowSceneKeyWindow
{
    for (UIWindow *window in [self windowsWithKeyWindow]) {
        if (window.isKeyWindow) {
            return window;
        }
    }
    
    return nil;
}

- (float)animationSpeed
{
    UIWindow *keyWindow = [self windowSceneKeyWindow];
    if (!keyWindow) {
        return 1.0f;
    }
    return keyWindow.layer.speed;
}

- (void)setAnimationSpeed:(float)animationSpeed
{
    for (UIWindow *window in [self windowsWithKeyWindow]) {
        window.layer.speed = animationSpeed;
    }
}

#pragma mark - Screenshotting

- (BOOL)writeScreenshotForLine:(NSUInteger)lineNumber inFile:(NSString *)filename description:(NSString *)description error:(NSError **)error;
{
    NSString *outputPath = [[[NSProcessInfo processInfo] environment] objectForKey:@"KIF_SCREENSHOTS"];
    if (!outputPath) {
        if (error) {
            *error = [NSError KIFErrorWithFormat:@"Screenshot path not defined. Please set KIF_SCREENSHOTS environment variable."];
        }
        return NO;
    }
    
    NSArray *windows = [self windowsWithKeyWindow];
    if (windows.count == 0) {
        if (error) {
            *error = [NSError KIFErrorWithFormat:@"Could not take screenshot.  No windows were available."];
        }
        return NO;
    }
    
    if (!filename.length) {
        if (error) {
            *error = [NSError KIFErrorWithFormat:@"Missing screenshot filename."];
        }
        return NO;
    }

    UIWindow *keyboardWindow = [self keyboardWindow];

    UIGraphicsBeginImageContextWithOptions([[windows objectAtIndex:0] bounds].size, YES, 0);
    for (UIWindow *window in windows) {
		//avoid https://github.com/kif-framework/KIF/issues/679
		if (window.hidden) {
			continue;
		}

        if (@available(iOS 17.0, *)) {
            if (window == keyboardWindow) {
                continue;
            }
        }

        if ([window respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
            [window drawViewHierarchyInRect:window.bounds afterScreenUpdates:YES];
        } else {
            [window.layer renderInContext:UIGraphicsGetCurrentContext()];
        }
    }
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    outputPath = [outputPath stringByExpandingTildeInPath];

    NSError *directoryCreationError = nil;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:outputPath withIntermediateDirectories:YES attributes:nil error:&directoryCreationError]) {
        if (error) {
            *error = [NSError KIFErrorWithFormat:@"Couldn't create directory at path %@ (details: %@)", outputPath, directoryCreationError];
        }
        return NO;
    }

    NSString *imageName = [self imageNameForFile:filename lineNumber:lineNumber description:description];
    
    outputPath = [outputPath stringByAppendingPathComponent:imageName];
    outputPath = [outputPath stringByAppendingPathExtension:@"png"];

    if (![UIImagePNGRepresentation(image) writeToFile:outputPath atomically:YES]) {
        if (error) {
            *error = [NSError KIFErrorWithFormat:@"Could not write file at path %@", outputPath];
        }
        return NO;
    }
    
    return YES;
}

- (NSString *)imageNameForFile:(NSString *)filename lineNumber:(NSUInteger)lineNumber description:(NSString *)description {
    if (!filename.length) {
        return nil;
    }
    
    NSString *imageName = [filename lastPathComponent];
    
    if (lineNumber > 0) {
        imageName = [imageName stringByAppendingFormat:@", line %lu", (unsigned long)lineNumber];
    }
    
    if (description.length) {
        imageName = [imageName stringByAppendingFormat:@", %@", description];
    }

    return imageName;
}

#pragma mark - Run loop monitoring

- (NSMutableArray *)t8nee_activeModes;
{
    NSMutableArray *modes = objc_getAssociatedObject(self, KIFRunLoopModesKey);
    if (!modes) {
        modes = [NSMutableArray arrayWithObject:(id)kCFRunLoopDefaultMode];
        objc_setAssociatedObject(self, KIFRunLoopModesKey, modes, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return modes;
}

- (CFStringRef)currentRunLoopMode;
{
    return (__bridge CFStringRef)[self t8nee_activeModes].lastObject;
}

- (void)t8nee_pushContext:(NSString *)mode;
{
    [[self t8nee_activeModes] addObject:mode];
    [self t8nee_pushContext:mode];
}

- (void)t8nee_pushContext:(NSString *)mode requester:(id)requester;
{
    [[self t8nee_activeModes] addObject:mode];
    [self t8nee_pushContext:mode requester:requester];
}

- (void)ahmaddev_popContext:(NSString *)mode;
{
    [[self t8nee_activeModes] removeLastObject];
    [self ahmaddev_popContext:mode];
}


- (void)ahmaddev_popContext:(NSString *)mode requester:(id)requester;
{
    [[self t8nee_activeModes] removeLastObject];
    [self ahmaddev_popContext:mode requester:requester];
}

- (BOOL)ahmaddev_resolveURL:(NSURL *)URL;
{
    if (_KIF_UIApplicationMockOpenURL) {
        [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidMockOpenURLNotification object:self userInfo:@{UIApplicationOpenedURLKey: URL}];
        return _KIF_UIApplicationMockOpenURL_returnValue;
    } else {
        return [self ahmaddev_resolveURL:URL];
    }
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000
- (BOOL)ahmaddev_resolveURL:(NSURL *)URL options:(NSDictionary<NSString *, id> *)options completionHandler:(void (^ __nullable)(BOOL success))completionHandler;
{
    if (_KIF_UIApplicationMockOpenURL) {
        [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidMockOpenURLNotification object:self userInfo:@{UIApplicationOpenedURLKey: URL}];
        return _KIF_UIApplicationMockOpenURL_returnValue;
    } else {
        return [self ahmaddev_resolveURL:URL options: options completionHandler: completionHandler];
    }
}
#endif

- (BOOL)t8nee_validateURL:(NSURL *)URL;
{
    if (_KIF_UIApplicationMockOpenURL) {
        [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidMockCanOpenURLNotification object:self userInfo:@{UIApplicationOpenedURLKey: URL}];
        return _KIF_UIApplicationMockOpenURL_returnValue;
    } else {
        return [self t8nee_validateURL:URL];
    }
}

static inline void Swizzle(Class c, SEL orig, SEL new)
{
    Method origMethod = class_getInstanceMethod(c, orig);
    Method newMethod = class_getInstanceMethod(c, new);
    if(class_addMethod(c, orig, method_getImplementation(newMethod), method_getTypeEncoding(newMethod)))
        class_replaceMethod(c, new, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    else
        method_exchangeImplementations(origMethod, newMethod);
}

+ (void)swizzleRunLoop;
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Swizzle(self, @selector(pushRunLoopMode:), @selector(t8nee_pushContext:));
        Swizzle(self, @selector(pushRunLoopMode:requester:), @selector(t8nee_pushContext:requester:));
        Swizzle(self, @selector(popRunLoopMode:), @selector(ahmaddev_popContext:));
        Swizzle(self, @selector(popRunLoopMode:requester:), @selector(ahmaddev_popContext:requester:));
    });
}

#pragma mark - openURL mocking

+ (void)startMockingOpenURLWithReturnValue:(BOOL)returnValue;
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Swizzle(self, @selector(openURL:), @selector(ahmaddev_resolveURL:));
        #if __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000
            Swizzle(self, @selector(openURL:options:completionHandler:), @selector(ahmaddev_resolveURL:options:completionHandler:));
        #endif
        Swizzle(self, @selector(canOpenURL:), @selector(t8nee_validateURL:));
    });

    _KIF_UIApplicationMockOpenURL = YES;
    _KIF_UIApplicationMockOpenURL_returnValue = returnValue;
}

+ (void)stopMockingOpenURL;
{
    _KIF_UIApplicationMockOpenURL = NO;
}

#pragma mark - Send Event

- (void)kif_sendEvent:(UIEvent *)event
{
    // [[KIFEventVisualizer sharedVisualizer] visualizeEvent:event]; // disabled
    [self sendEvent:event];
}

@end
