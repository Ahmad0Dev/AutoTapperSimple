#import "ATSilencer.h"
#import <objc/runtime.h>
#import <dlfcn.h>

@implementation AhmadDevContext

+ (void)silence {
    [self swizzleH5GGRequire];
}

+ (void)swizzleH5GGRequire {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        Class h5Class = NSClassFromString(@"H5GGTouch");
        if (!h5Class) return;
        SEL reqSel = NSSelectorFromString(@"require:");
        Method method = class_getInstanceMethod(h5Class, reqSel);
        if (!method) return;
        method_setImplementation(method, imp_implementationWithBlock(^(id self, id arg) {}));
    });
}

@end
