#import "ATEngine.h"
#import "ATGuard.h"
#import "ATTouchPool.h"
#import <dlfcn.h>
#import <objc/runtime.h>
#import <mach/mach_time.h>
#import <os/lock.h>

typedef struct __IOHIDEvent *IOHIDEventRef;
typedef IOHIDEventRef (*CreateWithQuality)(CFAllocatorRef,uint64_t,uint32_t,uint32_t,uint32_t,double,double,double,double,double,double,double,double,double,double,bool,bool,uint32_t);
typedef IOHIDEventRef (*CreateBasic)(CFAllocatorRef,uint64_t,uint32_t,uint32_t,uint32_t,double,double,double,double,double,bool,bool,uint32_t);

@interface UITouch (KIF)
- (instancetype)initAtPoint:(CGPoint)p inWindow:(UIWindow *)w;
- (void)setPhaseAndUpdateTimestamp:(UITouchPhase)phase;
- (void)_setLocationInWindow:(CGPoint)p resetPrevious:(BOOL)r;
- (void)_setIsFirstTouchForView:(BOOL)f;
@end

@interface UIEvent (KIF)
+ (instancetype)eventWithTouch:(UITouch *)t;
+ (instancetype)eventWithTouches:(NSArray *)t;
- (void)ahmaddev_dispatchSource:(NSArray *)t;
- (void)t8nee_commitEvent:(NSArray *)t;
@end

@interface AhmadDevDelegate ()
@property (nonatomic, strong) NSTimer   *timer;
@property (nonatomic, assign) BOOL       running;
@property (nonatomic, assign) void      *iokit;
@property (nonatomic, assign) CreateWithQuality createQ;
@property (nonatomic, assign) CreateBasic       createB;
@end

@implementation AhmadDevDelegate

+ (instancetype)shared {
    static AhmadDevDelegate *i; static dispatch_once_t t;
    dispatch_once(&t, ^{ i = [AhmadDevDelegate new]; }); return i;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.tapSpeed = 5.0;
        self.tapX = 200; self.tapY = 400;
        [self loadFrameworks];
        // تهيئة T8neeChain (بديل AhmadDev)
        [T8neeChain setup];
    }
    return self;
}

- (void)loadFrameworks {
    const char *paths[] = {
        "/System/Library/PrivateFrameworks/GraphicsServices.framework/GraphicsServices",
        "/System/Library/Frameworks/IOKit.framework/IOKit"
    };
    for (int i = 0; i < 2; i++) {
        self.iokit = dlopen(paths[i], RTLD_NOW | RTLD_GLOBAL);
        if (self.iokit) {
            self.createQ = (CreateWithQuality)dlsym(self.iokit, "IOHIDEventCreateDigitizerFingerEventWithQuality");
            self.createB = (CreateBasic)dlsym(self.iokit, "IOHIDEventCreateDigitizerFingerEvent");
            if (self.createQ || self.createB) break;
        }
    }
}

- (BOOL)isRunning { return self.running; }

- (void)start {
    if (self.running) return;
    self.running = YES;
    NSTimeInterval d = 1.0 / MAX(self.tapSpeed, 0.1);
    self.timer = [NSTimer scheduledTimerWithTimeInterval:d target:self
                          selector:@selector(tick) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)stop {
    self.running = NO;
    [self.timer invalidate]; self.timer = nil;
}

- (void)tick {
    if (!self.running) { [self stop]; return; }
    if (![T8neeObserver isSystemValid]) { [self stop]; return; }
    CGPoint p = CGPointMake(self.tapX, self.tapY);
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"AhmadDevDelegateDidTap" object:nil];
        [self tap:p];
    });
}

- (void)tap:(CGPoint)point {
    // ── الطريقة 1: T8neeChain (محركنا الجديد) ──
    NSInteger pid = [T8neeChain getAvailablePointId];
    if (pid >= 0) {
        // مطابق لـ h5gg: Began ثم Ended مباشرة بدون delay
        NSInteger newPid = [T8neeChain fakeTouchId:pid atPoint:point withTouchPhase:UITouchPhaseBegan];
        [T8neeChain fakeTouchId:newPid atPoint:point withTouchPhase:UITouchPhaseEnded];
        return;
    }

    // ── الطريقة 2: AhmadDev (h5gg) إذا كان موجوداً ──
    Class PT = NSClassFromString(@"AhmadDev");
    if (PT) {
        SEL gid  = NSSelectorFromString(@"getAvailablePointId");
        SEL ftap = NSSelectorFromString(@"fakeTouchId:AtPoint:withTouchPhase:");
        if ([PT respondsToSelector:gid] && [PT respondsToSelector:ftap]) {
            NSMethodSignature *s = [PT methodSignatureForSelector:gid];
            NSInvocation *inv = [NSInvocation invocationWithMethodSignature:s];
            [inv setTarget:PT]; [inv setSelector:gid]; [inv invoke];
            NSInteger ptPid = -1; [inv getReturnValue:&ptPid];
            if (ptPid >= 0) {
                NSMethodSignature *fs = [PT methodSignatureForSelector:ftap];
                NSInvocation *down = [NSInvocation invocationWithMethodSignature:fs];
                [down setTarget:PT]; [down setSelector:ftap];
                UITouchPhase b = UITouchPhaseBegan;
                [down setArgument:&ptPid atIndex:2];
                [down setArgument:&point atIndex:3];
                [down setArgument:&b atIndex:4];
                [down invoke];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 60*NSEC_PER_MSEC),
                               dispatch_get_main_queue(), ^{
                    NSInvocation *up = [NSInvocation invocationWithMethodSignature:fs];
                    [up setTarget:PT]; [up setSelector:ftap];
                    NSInteger upid = ptPid; CGPoint upP = point;
                    UITouchPhase e = UITouchPhaseEnded;
                    [up setArgument:&upid atIndex:2];
                    [up setArgument:&upP  atIndex:3];
                    [up setArgument:&e    atIndex:4];
                    [up invoke];
                });
                return;
            }
        }
    }

    // NSLog(@"[AT] using KIF fallback");
    // ── الطريقة 3: KIF + IOHIDEvent (Fallback) ──
    UIWindow *win = [self appWindow];
    if (!win) return;
    UITouch *touch = [self buildTouch:point win:win];
    if (!touch) return;
    IOHIDEventRef hid = [self buildHID:point began:YES];
    if (hid) [self attachHID:hid touch:touch];
    [self dispatchTouch:touch win:win];
    if (hid) CFRelease(hid);

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 60*NSEC_PER_MSEC),
                   dispatch_get_main_queue(), ^{
        if ([touch respondsToSelector:@selector(setPhaseAndUpdateTimestamp:)])
            [touch setPhaseAndUpdateTimestamp:UITouchPhaseEnded];
        IOHIDEventRef h2 = [self buildHID:point began:NO];
        if (h2) { [self attachHID:h2 touch:touch]; }
        [self dispatchTouch:touch win:win];
        if (h2) CFRelease(h2);
    });
}

#pragma mark - Touch Builder

- (UITouch *)buildTouch:(CGPoint)p win:(UIWindow *)win {
    UITouch *t = nil;
    @try {
        if ([UITouch instancesRespondToSelector:@selector(initAtPoint:inWindow:)])
            t = [[UITouch alloc] initAtPoint:p inWindow:win];
        else {
            t = [[UITouch alloc] init];
            UIView *hit = [win hitTest:p withEvent:nil];
            if ([t respondsToSelector:@selector(_setLocationInWindow:resetPrevious:)])
                [t _setLocationInWindow:p resetPrevious:YES];
            else {
                [t setValue:[NSValue valueWithCGPoint:p] forKey:@"locationInWindow"];
                [t setValue:[NSValue valueWithCGPoint:p] forKey:@"previousLocationInWindow"];
            }
            [t setValue:win forKey:@"window"];
            if (hit) [t setValue:hit forKey:@"view"];
            [t setValue:@(1) forKey:@"tapCount"];
            [t setValue:@([[NSProcessInfo processInfo] systemUptime]) forKey:@"timestamp"];
            if ([t respondsToSelector:@selector(_setIsFirstTouchForView:)])
                [t _setIsFirstTouchForView:YES];
        }
        if ([t respondsToSelector:@selector(setPhaseAndUpdateTimestamp:)])
            [t setPhaseAndUpdateTimestamp:UITouchPhaseBegan];
        else [t setValue:@(UITouchPhaseBegan) forKey:@"phase"];
    } @catch (NSException *e) {}
    return t;
}

- (IOHIDEventRef)buildHID:(CGPoint)p began:(BOOL)began {
    if (!self.createQ && !self.createB) return NULL;
    CGSize s = [UIScreen mainScreen].bounds.size;
    double nx = p.x/s.width, ny = p.y/s.height;
    uint64_t ts = mach_absolute_time();
    uint32_t mask = began ? 0xF : 0x7;
    if (self.createQ)
        return self.createQ(kCFAllocatorDefault,ts,0,1,mask,nx,ny,0,began?1:0,0,5,5,1,1,0,began,began,0);
    return self.createB(kCFAllocatorDefault,ts,0,1,mask,nx,ny,0,began?1:0,0,began,began,0);
}

- (void)attachHID:(IOHIDEventRef)ev touch:(UITouch *)t {
    @try {
        for (NSString *n in @[@"ahmaddev_allocateStorage:",@"_setHIDEvent:",@"_setHidEvent:"]) {
            SEL s = NSSelectorFromString(n);
            if ([t respondsToSelector:s]) {
                NSMethodSignature *sig = [t methodSignatureForSelector:s];
                NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
                [inv setTarget:t]; [inv setSelector:s];
                [inv setArgument:&ev atIndex:2]; [inv invoke]; return;
            }
        }
    } @catch (NSException *e) {}
}

- (void)dispatchTouch:(UITouch *)touch win:(UIWindow *)win {
    @try {
        UIEvent *ev = nil;
        if ([UIEvent respondsToSelector:@selector(eventWithTouch:)])
            ev = [UIEvent eventWithTouch:touch];
        else if ([UIEvent respondsToSelector:@selector(eventWithTouches:)])
            ev = [UIEvent eventWithTouches:@[touch]];
        if (ev) {
            if ([ev respondsToSelector:@selector(ahmaddev_dispatchSource:)])
                [ev ahmaddev_dispatchSource:@[touch]];
            else if ([ev respondsToSelector:@selector(t8nee_commitEvent:)])
                [ev t8nee_commitEvent:@[touch]];
            [[UIApplication sharedApplication] sendEvent:ev];
        }
    } @catch (NSException *e) {}
}

- (UIWindow *)appWindow {
    for (UIWindowScene *sc in [UIApplication sharedApplication].connectedScenes)
        if (sc.activationState == UISceneActivationStateForegroundActive)
            for (UIWindow *w in sc.windows)
                if (w.windowLevel < UIWindowLevelAlert) return w;
    return nil;
}

@end
