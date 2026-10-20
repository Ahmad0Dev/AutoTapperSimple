#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "ATEngine.h"
#import "ATTerms.h"
#import "ATSimplePanel.h"
#import "ATMarker.h"
#import "ATHelpView.h"
#import "ATSilencer.h"
#import "ATGuard.h"

#pragma mark - Passthrough Windows

@interface ATFloatWindow : UIWindow @end
@implementation ATFloatWindow
- (UIView *)hitTest:(CGPoint)p withEvent:(UIEvent *)e {
    UIView *hit = [super hitTest:p withEvent:e];
    if (hit == self || hit == self.rootViewController.view) return nil;
    return hit;
}
@end

#pragma mark - Main Controller

@interface ATController : NSObject
@property (nonatomic, strong) ATFloatWindow  *floatWin;
@property (nonatomic, strong) UIWindow       *panelWin;
@property (nonatomic, strong) AhmadDevLayoutWindow *markerWin;
@property (nonatomic, strong) T8neeAnimator  *panel;
@property (nonatomic, strong) AhmadDevLayout       *marker;
@property (nonatomic, strong) UIButton       *floatBtn;
@property (nonatomic, assign) BOOL panelVisible;
@property (nonatomic, assign) BOOL isDragging;
+ (instancetype)shared;
- (void)setup;
@end

@implementation ATController

+ (instancetype)shared {
    static ATController *i; static dispatch_once_t t;
    dispatch_once(&t, ^{ i = [ATController new]; }); return i;
}

- (UIWindow *)makeWin:(CGRect)f level:(UIWindowLevel)lv {
    UIWindow *w = nil;
    for (UIWindowScene *s in [UIApplication sharedApplication].connectedScenes)
        if (s.activationState == UISceneActivationStateForegroundActive)
            { w = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)s]; break; }
    if (!w) w = [[UIWindow alloc] initWithFrame:f];
    w.frame = f; w.windowLevel = lv; w.backgroundColor = [UIColor clearColor];
    return w;
}

- (void)setup {
    [self setupMarker];
    [self setupPanel];
    [self setupFloat];

    // إشعار النبض
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onTap)
                                                 name:@"AhmadDevDelegateDidTap" object:nil];
}

#pragma mark - Setup Marker

- (void)setupMarker {
    CGSize sc = [UIScreen mainScreen].bounds.size;

    // Passthrough window للماركر
    AhmadDevLayoutWindow *mw = nil;
    for (UIWindowScene *s in [UIApplication sharedApplication].connectedScenes)
        if (s.activationState == UISceneActivationStateForegroundActive)
            { mw = [[AhmadDevLayoutWindow alloc] initWithWindowScene:(UIWindowScene *)s]; break; }
    if (!mw) mw = [[AhmadDevLayoutWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    mw.frame = [UIScreen mainScreen].bounds;
    mw.windowLevel = UIWindowLevelAlert + 60;
    mw.backgroundColor = [UIColor clearColor];
    mw.hidden = YES;

    UIViewController *vc = [UIViewController new];
    vc.view.backgroundColor = [UIColor clearColor];
    mw.rootViewController = vc;

    self.marker = [[AhmadDevLayout alloc] init];
    self.marker.center = CGPointMake(sc.width/2, sc.height/2);
    self.marker.position = self.marker.center;
    [vc.view addSubview:self.marker];
    [mw makeKeyAndVisible];
    mw.hidden = YES;
    self.markerWin = mw;
}

#pragma mark - Setup Panel

- (void)setupPanel {
    CGSize sc = [UIScreen mainScreen].bounds.size;
    CGFloat pw = 252, ph = 282;

    UIWindow *pw_win = [self makeWin:CGRectMake((sc.width-pw)/2,(sc.height-ph)/2,pw,ph)
                               level:UIWindowLevelAlert+100];
    pw_win.hidden = YES;

    UIViewController *vc = [UIViewController new];
    vc.view.backgroundColor = [UIColor clearColor];
    pw_win.rootViewController = vc;

    self.panel = [[T8neeAnimator alloc] initWithFrame:CGRectMake(0,0,pw,ph)];
    [self.panel setMarkerWindow:self.markerWin marker:self.marker];

    // Pan لتحريك اللوحة
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]
                                    initWithTarget:self action:@selector(panelPan:)];
    [self.panel addGestureRecognizer:pan];

    [vc.view addSubview:self.panel];
    [pw_win makeKeyAndVisible];
    pw_win.hidden = YES;
    self.panelWin = pw_win;
}

#pragma mark - Setup Float Button

- (void)setupFloat {
    CGFloat bs = 56;
    CGSize sc = [UIScreen mainScreen].bounds.size;

    // Passthrough window للزر
    ATFloatWindow *fw = nil;
    for (UIWindowScene *s in [UIApplication sharedApplication].connectedScenes)
        if (s.activationState == UISceneActivationStateForegroundActive)
            { fw = [[ATFloatWindow alloc] initWithWindowScene:(UIWindowScene *)s]; break; }
    if (!fw) fw = [[ATFloatWindow alloc] initWithFrame:CGRectMake(sc.width-bs-14,180,bs,bs)];
    fw.frame = CGRectMake(sc.width-bs-14, 180, bs, bs);
    fw.windowLevel = UIWindowLevelAlert + 300;
    fw.backgroundColor = [UIColor clearColor];

    UIViewController *vc = [UIViewController new];
    vc.view.backgroundColor = [UIColor clearColor];
    fw.rootViewController = vc;

    // الزر العائم
    self.floatBtn = [[UIButton alloc] initWithFrame:CGRectMake(0,0,bs,bs)];
    // خلفية
    self.floatBtn.backgroundColor = [UIColor colorWithRed:0.11 green:0.17 blue:0.23 alpha:1.0];
    self.floatBtn.layer.cornerRadius = bs/2;
    self.floatBtn.layer.masksToBounds = YES;
    self.floatBtn.layer.borderColor = [UIColor colorWithRed:0.18 green:0.80 blue:0.44 alpha:0.6].CGColor;
    self.floatBtn.layer.borderWidth = 1.5;

    // رسم شعار Ahmad Dev داخل الزر
    UIView *logoView = [[UIView alloc] initWithFrame:CGRectMake(0,0,bs,bs)];
    logoView.backgroundColor = [UIColor clearColor];
    logoView.userInteractionEnabled = NO;

    // الخطوط الثلاثة (يسار)
    UIColor *green = [UIColor colorWithRed:0.18 green:0.80 blue:0.44 alpha:1.0];
    UIColor *white = [UIColor whiteColor];

    // خط علوي أخضر (مائل)
    UIView *l1 = [[UIView alloc] initWithFrame:CGRectMake(8, 13, 17, 5)];
    l1.backgroundColor = green; l1.layer.cornerRadius = 2.5;
    l1.transform = CGAffineTransformMakeRotation(-0.35);
    [logoView addSubview:l1];

    // خط أوسط أبيض
    UIView *l2 = [[UIView alloc] initWithFrame:CGRectMake(7, 25, 19, 5)];
    l2.backgroundColor = white; l2.layer.cornerRadius = 2.5;
    [logoView addSubview:l2];

    // خط سفلي أخضر (مائل)
    UIView *l3 = [[UIView alloc] initWithFrame:CGRectMake(8, 37, 17, 5)];
    l3.backgroundColor = green; l3.layer.cornerRadius = 2.5;
    l3.transform = CGAffineTransformMakeRotation(0.35);
    [logoView addSubview:l3];

    // نص "AD" (Ahmad Dev)
    UILabel *adLbl = [[UILabel alloc] initWithFrame:CGRectMake(28, 17, 22, 22)];
    adLbl.text = @"AD";
    adLbl.font = [UIFont boldSystemFontOfSize:11];
    adLbl.textColor = white;
    adLbl.textAlignment = NSTextAlignmentCenter;
    [logoView addSubview:adLbl];

    [self.floatBtn addSubview:logoView];

    [self.floatBtn addTarget:self action:@selector(floatTap)
            forControlEvents:UIControlEventTouchUpInside];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]
                                    initWithTarget:self action:@selector(floatPan:)];
    [self.floatBtn addGestureRecognizer:pan];

    [vc.view addSubview:self.floatBtn];
    [fw makeKeyAndVisible];
    self.floatWin = fw;
}

#pragma mark - Float Button Actions

- (void)floatTap {
    if (self.isDragging) { self.isDragging = NO; return; }
    [self togglePanel];
}

- (void)floatPan:(UIPanGestureRecognizer *)g {
    CGSize sc = [UIScreen mainScreen].bounds.size;
    CGFloat bs = self.floatWin.frame.size.width;
    CGPoint t = [g translationInView:self.floatWin];

    if (g.state == UIGestureRecognizerStateBegan) self.isDragging = NO;
    if (g.state == UIGestureRecognizerStateChanged) {
        self.isDragging = YES;
        CGRect f = self.floatWin.frame;
        f.origin.x = MAX(0, MIN(sc.width-bs, f.origin.x+t.x));
        f.origin.y = MAX(20, MIN(sc.height-bs-20, f.origin.y+t.y));
        self.floatWin.frame = f;
        [g setTranslation:CGPointZero inView:self.floatWin];
    }
    if (g.state == UIGestureRecognizerStateEnded || g.state == UIGestureRecognizerStateCancelled)
        [self snapToEdge];
}

- (void)snapToEdge {
    CGSize sc = [UIScreen mainScreen].bounds.size;
    CGFloat bs = self.floatWin.frame.size.width;
    CGRect f = self.floatWin.frame;
    CGFloat cx = f.origin.x + bs/2;
    CGFloat tx = (cx < sc.width/2) ? 12 : sc.width-bs-12;
    CGFloat ty = MAX(30, MIN(sc.height-bs-30, f.origin.y));
    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.7
      initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut
                 animations:^{ self.floatWin.frame = CGRectMake(tx,ty,bs,bs); }
                 completion:nil];
}

#pragma mark - Panel Actions

- (void)panelPan:(UIPanGestureRecognizer *)g {
    CGSize sc = [UIScreen mainScreen].bounds.size;
    CGPoint t = [g translationInView:self.panelWin];
    CGRect f = self.panelWin.frame;
    f.origin.x = MAX(0, MIN(sc.width-f.size.width, f.origin.x+t.x));
    f.origin.y = MAX(20, MIN(sc.height-f.size.height-20, f.origin.y+t.y));
    self.panelWin.frame = f;
    [g setTranslation:CGPointZero inView:self.panelWin];
}

- (void)togglePanel {
    self.panelVisible = !self.panelVisible;
    if (self.panelVisible) {
        self.panelWin.hidden = NO;
        self.panelWin.alpha = 0;
        self.panelWin.transform = CGAffineTransformMakeScale(0.92,0.92);
        [self.panelWin makeKeyAndVisible];
        [UIView animateWithDuration:0.22 delay:0 usingSpringWithDamping:0.75
          initialSpringVelocity:0.5 options:0
                     animations:^{
            self.panelWin.alpha = 1;
            self.panelWin.transform = CGAffineTransformIdentity;
        } completion:nil];
    } else {
        [UIView animateWithDuration:0.18 animations:^{
            self.panelWin.alpha = 0;
            self.panelWin.transform = CGAffineTransformMakeScale(0.92,0.92);
        } completion:^(BOOL d) {
            self.panelWin.hidden = YES;
            self.panelWin.transform = CGAffineTransformIdentity;
        }];
    }
}

- (void)onTap {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ATDidTap" object:nil];
}

@end

#pragma mark - Constructor

static void (*origSendEvent)(id,SEL,UIEvent*);
static void hookedSendEvent(id self, SEL cmd, UIEvent *event) {
    origSendEvent(self, cmd, event);
    static BOOL ready = NO;
    if (!ready) {
        for (UITouch *t in event.allTouches) {
            if (t.phase == UITouchPhaseBegan) {
                ready = YES;
                [[NSNotificationCenter defaultCenter]
                    postNotificationName:@"ATTouchReady" object:nil];
                break;
            }
        }
    }
}

__attribute__((constructor))
static void ATAutoTapperInit(void) {
    // Swizzle UIWindow.sendEvent
    Method m = class_getInstanceMethod([UIWindow class], @selector(sendEvent:));
    if (m) {
        origSendEvent = (void(*)(id,SEL,UIEvent*))method_getImplementation(m);
        method_setImplementation(m, (IMP)hookedSendEvent);
    }

    // إسكات رسائل h5gg فوراً
    [AhmadDevContext silence];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5*NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [[ATController shared] setup];
    // بدء نظام الحماية
    [T8neeObserver startGuarding];
    });
}
