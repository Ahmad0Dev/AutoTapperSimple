#import "ATGuard.h"
#import <objc/runtime.h>
#import "ATHelpView.h"
#import "ATEngine.h"
#import "ATCrypt.h"
#import <WebKit/WebKit.h>

@interface T8neeObserver ()
@property (nonatomic, strong) NSTimer *guardTimer;
@property (nonatomic, assign) NSInteger tamperCount; // عدد محاولات التلاعب
@end

@implementation T8neeObserver

static T8neeObserver *_instance;

+ (instancetype)shared {
    static dispatch_once_t t;
    dispatch_once(&t, ^{ _instance = [T8neeObserver new]; });
    return _instance;
}

+ (void)startGuarding {
    [[T8neeObserver shared] start];
}

+ (BOOL)isSystemValid {
    return [T8neeObserver shared].tamperCount == 0;
}

- (void)start {
    // فحص كل 3 ثوان
    self.guardTimer = [NSTimer scheduledTimerWithTimeInterval:3.0
                                                       target:self
                                                     selector:@selector(check)
                                                     userInfo:nil
                                                      repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.guardTimer forMode:NSRunLoopCommonModes];
}

- (void)check {
    // فحص: هل زر ? لا يزال موجوداً ويعمل؟
    // نتحقق من helpWindowIntact إذا كانت النافذة فُتحت من قبل وأُغلقت بشكل غير طبيعي
    
    // الطريقة: نتحقق من وجود AhmadDevDelegate نفسه
    if (![AhmadDevDelegate shared]) {
        [self handleTamper];
        return;
    }
}

- (void)handleTamper {
    self.tamperCount++;
    
    // إيقاف الأداة فوراً
    [[AhmadDevDelegate shared] stop];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.tamperCount >= 2) {
            // فتح WebView على موقع EnjoyTeam
            [self showEnjoyTeamWebView];
        }
    });
}

- (void)showEnjoyTeamWebView {
    UIWindow *win = nil;
    for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if (scene.activationState == UISceneActivationStateForegroundActive) {
            win = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
            break;
        }
    }
    if (!win) win = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    win.frame = [UIScreen mainScreen].bounds;
    win.windowLevel = UIWindowLevelAlert + 1000;
    win.backgroundColor = [UIColor blackColor];

    UIViewController *vc = [[UIViewController alloc] init];
    vc.view.backgroundColor = [UIColor blackColor];
    win.rootViewController = vc;
    [win makeKeyAndVisible];

    // WebView يفتح موقع EnjoyTeam
    WKWebView *webView = [[WKWebView alloc] initWithFrame:vc.view.bounds];
    webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    NSURL *url = [NSURL URLWithString:AT("322e2e2a296075752d2d2d743f343035232e3f3b37743b2a2a75")]; // https://www.enjoyteam.app/
    [webView loadRequest:[NSURLRequest requestWithURL:url]];
    [vc.view addSubview:webView];

    // رسالة تحذير
    UILabel *warn = [[UILabel alloc] initWithFrame:CGRectMake(0, 40, win.frame.size.width, 40)];
    warn.text = AT("26fafe557a67d61266161061e66361067d61266161061e66366160"); // نص تحذير
    warn.textColor = [UIColor systemRedColor];
    warn.font = [UIFont boldSystemFontOfSize:14];
    warn.textAlignment = NSTextAlignmentCenter;
    [vc.view addSubview:warn];
    
    // حفظ الـ window لمنع تحريره
    objc_setAssociatedObject(self, "guardWin", win, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
