#import "ATHelpView.h"
#import "ATCrypt.h"

static UIWindow *helpWindow;
static BOOL helpWindowIntact = NO;  // حالة النافذة

@interface T8neeHelpView ()
@property (nonatomic, strong) UIScrollView *scroll;
@end

@implementation T8neeHelpView

+ (void)show {
    // إنشاء window مستقلة تملأ الشاشة
    for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if (scene.activationState == UISceneActivationStateForegroundActive) {
            helpWindow = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
            break;
        }
    }
    if (!helpWindow) helpWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    helpWindow.frame = [UIScreen mainScreen].bounds;
    helpWindow.windowLevel = UIWindowLevelAlert + 500;
    helpWindow.backgroundColor = [UIColor clearColor];

    UIViewController *vc = [[UIViewController alloc] init];
    vc.view.backgroundColor = [UIColor clearColor];
    helpWindow.rootViewController = vc;
    [helpWindow makeKeyAndVisible];
    helpWindowIntact = YES;

    T8neeHelpView *help = [[T8neeHelpView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [vc.view addSubview:help];

    help.alpha = 0;
    help.transform = CGAffineTransformMakeScale(0.95, 0.95);
    [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:0.8
      initialSpringVelocity:0.5 options:0
                 animations:^{ help.alpha = 1; help.transform = CGAffineTransformIdentity; }
                 completion:nil];
}

+ (BOOL)isIntact {
    return helpWindowIntact;
}

+ (void)showInWindow:(UIWindow *)window {
    [self show];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) [self build];
    return self;
}

- (void)build {
    CGSize screen = [UIScreen mainScreen].bounds.size;

    // خلفية شبه شفافة
    UIView *bg = [[UIView alloc] initWithFrame:self.bounds];
    bg.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
    [self addSubview:bg];

    // البطاقة - تملأ معظم الشاشة
    CGFloat p = 14;
    CGFloat cw = screen.width - 48;
    CGFloat cx = 24;
    CGFloat cy = screen.height * 0.12;
    CGFloat ch = screen.height * 0.76;

    UIView *card = [[UIView alloc] initWithFrame:CGRectMake(cx, cy, cw, ch)];
    card.backgroundColor = [UIColor colorWithRed:0.13 green:0.14 blue:0.18 alpha:0.98];
    card.layer.cornerRadius = 20;
    card.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.12].CGColor;
    card.layer.borderWidth = 0.5;
    card.clipsToBounds = YES;
    [self addSubview:card];

    CGFloat w = cw - p*2;
    CGFloat y = p;

    // زر الإغلاق
    UIButton *closeBtn = [[UIButton alloc] initWithFrame:CGRectMake(cw-44, 8, 36, 36)];
    [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    [closeBtn setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:0.7] forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:closeBtn];

    // العنوان
    UILabel *title = [self lbl:AT("b8c0fb7a1b2f2e350e3b2a2a3f287a247a1b32373b3e1e3f2c") size:22 bold:YES color:[UIColor whiteColor]
                         frame:CGRectMake(p, y, w-44, 28)];
    title.textAlignment = NSTextAlignmentCenter;
    [card addSubview:title]; y += 34;

    // by Ahmad Dev
    UILabel *by = [self lbl:AT("38237a1b32373b3e1e3f2c7a267a0e62343f3f") size:14 bold:NO
                      color:[[UIColor colorWithRed:0.18 green:0.80 blue:0.44 alpha:1.0] colorWithAlphaComponent:0.9]
                      frame:CGRectMake(p, y, w, 20)];
    by.textAlignment = NSTextAlignmentCenter;
    [card addSubview:by]; y += 28;

    // فاصل
    [self sep:y w:w p:p inView:card]; y += 12;

    // Scroll للخطوات
    CGFloat scrollH = ch - y - 200;
    self.scroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, y, cw, scrollH)];
    self.scroll.showsVerticalScrollIndicator = YES;
    self.scroll.alwaysBounceVertical = YES;
    [card addSubview:self.scroll];

    CGFloat sy = 10;
    NSArray *steps = @[
        @[@"1️⃣", @"فتح اللوحة", @"اضغط الزر العائم لفتح لوحة التحكم وإغلاقها"],
        @[@"2️⃣", @"تفعيل الماركر", @"اضغط زر 📍 الماركر ليظهر التقاطع الأحمر على الشاشة"],
        @[@"3️⃣", @"تحديد الموقع", @"اسحب الماركر للمكان الذي تريد الضغط عليه\nيمكنك اللمس خلف الماركر بحرية"],
        @[@"4️⃣", @"ضبط السرعة", @"حرك السلايدر لضبط السرعة من 1 إلى 10 ضغطات في الثانية"],
        @[@"5️⃣", @"التشغيل", @"اضغط ▶ تشغيل لبدء الضغط التلقائي\nيتحول الزر للأحمر عند التشغيل"],
        @[@"⚠️", @"اللمسة الأولى", @"عند أول تشغيل للأداة في كل مرة\nالمس الشاشة مرة واحدة لتهيئة محرك اللمس\nبعدها تعمل الأداة بشكل تلقائي"],
    ];

    for (NSArray *step in steps) {
        // أيقونة
        UILabel *icon = [self lbl:step[0] size:28 bold:NO color:[UIColor whiteColor]
                            frame:CGRectMake(p, sy, 36, 36)];
        [self.scroll addSubview:icon];

        // العنوان
        UILabel *stitle = [self lbl:step[1] size:16 bold:YES color:[UIColor whiteColor]
                              frame:CGRectMake(p+44, sy+2, w-44, 22)];
        [self.scroll addSubview:stitle];

        // الوصف
        NSString *desc = step[2];
        CGRect descBounds = [desc boundingRectWithSize:CGSizeMake(w-44, 999)
                                               options:NSStringDrawingUsesLineFragmentOrigin
                                           attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14]}
                                               context:nil];
        UILabel *dl = [self lbl:desc size:14 bold:NO
                          color:[[UIColor whiteColor] colorWithAlphaComponent:0.65]
                          frame:CGRectMake(p+44, sy+26, w-44, descBounds.size.height+4)];
        dl.numberOfLines = 0;
        [self.scroll addSubview:dl];

        sy += MAX(70, descBounds.size.height + 42);

        // فاصل خفيف
        if (step != steps.lastObject) {
            UIView *line = [[UIView alloc] initWithFrame:CGRectMake(p+44, sy-10, w-44, 0.5)];
            line.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.1];
            [self.scroll addSubview:line];
        }
    }
    self.scroll.contentSize = CGSizeMake(cw, sy + 16);

    // ── قسم التواصل ──
    CGFloat socialY = ch - 190;
    [self sep:socialY w:w p:p inView:card];

    UILabel *followLbl = [self lbl:AT("82f082fd82f282e383dc82fd") size:13 bold:NO
                             color:[[UIColor whiteColor] colorWithAlphaComponent:0.5]
                             frame:CGRectMake(p, socialY+8, w, 16)];
    followLbl.textAlignment = NSTextAlignmentCenter;
    [card addSubview:followLbl];

    CGFloat btnY = socialY + 28;
    CGFloat btnH = 44;
    CGFloat gap  = 8;

    // ── زر EnjoyTeam ──
    UIButton *etBtn = [[UIButton alloc] initWithFrame:CGRectMake(p, btnY, w, btnH)];
    etBtn.backgroundColor = [UIColor colorWithRed:0.22 green:0.23 blue:0.28 alpha:1.0];
    etBtn.layer.cornerRadius = 10;

    // أيقونة تاج SVG - مرسومة بـ UIBezierPath
    UIView *crownView = [[UIView alloc] initWithFrame:CGRectMake(14, 10, 24, 24)];
    crownView.backgroundColor = [UIColor clearColor];
    crownView.userInteractionEnabled = NO;
    CAShapeLayer *crownLayer = [CAShapeLayer layer];
    UIBezierPath *crown = [UIBezierPath bezierPath];
    // رسم التاج
    [crown moveToPoint:CGPointMake(2, 20)];
    [crown addLineToPoint:CGPointMake(2, 8)];
    [crown addLineToPoint:CGPointMake(7, 14)];
    [crown addLineToPoint:CGPointMake(12, 4)];
    [crown addLineToPoint:CGPointMake(17, 14)];
    [crown addLineToPoint:CGPointMake(22, 8)];
    [crown addLineToPoint:CGPointMake(22, 20)];
    [crown closePath];
    crownLayer.path = crown.CGPath;
    crownLayer.fillColor = [UIColor whiteColor].CGColor;
    crownLayer.strokeColor = [UIColor clearColor].CGColor;
    [crownView.layer addSublayer:crownLayer];
    [etBtn addSubview:crownView];

    UILabel *etLbl = [[UILabel alloc] initWithFrame:CGRectMake(46, 0, w-60, btnH)];
    etLbl.text = AT("1f343035230e3f3b37");
    etLbl.textColor = [UIColor whiteColor];
    etLbl.font = [UIFont boldSystemFontOfSize:15];
    [etBtn addSubview:etLbl];
    [etBtn addTarget:self action:@selector(openEnjoyTeam) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:etBtn];
    btnY += btnH + gap;

    // ── زر Twitter ──
    UIButton *xBtn = [[UIButton alloc] initWithFrame:CGRectMake(p, btnY, w, btnH)];
    xBtn.backgroundColor = [UIColor colorWithRed:0.22 green:0.23 blue:0.28 alpha:1.0];
    xBtn.layer.cornerRadius = 10;
    

    // أيقونة X مرسومة
    UIView *xView = [[UIView alloc] initWithFrame:CGRectMake(14, 10, 24, 24)];
    xView.backgroundColor = [UIColor clearColor];
    xView.userInteractionEnabled = NO;
    CAShapeLayer *xLayer = [CAShapeLayer layer];
    UIBezierPath *xPath = [UIBezierPath bezierPath];
    [xPath moveToPoint:CGPointMake(2, 2)];   [xPath addLineToPoint:CGPointMake(22, 22)];
    [xPath moveToPoint:CGPointMake(22, 2)];  [xPath addLineToPoint:CGPointMake(2, 22)];
    xLayer.path = xPath.CGPath;
    xLayer.strokeColor = [UIColor whiteColor].CGColor;
    xLayer.lineWidth = 3.0;
    xLayer.lineCap = kCALineCapRound;
    [xView.layer addSublayer:xLayer];
    [xBtn addSubview:xView];

    UILabel *xLbl = [[UILabel alloc] initWithFrame:CGRectMake(46, 0, w-60, btnH)];
    xLbl.text = AT("0e2d332e2e3f28");
    xLbl.textColor = [UIColor whiteColor];
    xLbl.font = [UIFont boldSystemFontOfSize:15];
    [xBtn addSubview:xLbl];
    [xBtn addTarget:self action:@selector(openTwitter) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:xBtn];
    btnY += btnH + gap;

    // ── زر Telegram ──
    UIButton *tgBtn = [[UIButton alloc] initWithFrame:CGRectMake(p, btnY, w, btnH)];
    tgBtn.backgroundColor = [UIColor colorWithRed:0.22 green:0.23 blue:0.28 alpha:1.0];
    tgBtn.layer.cornerRadius = 10;

    // أيقونة Telegram مرسومة (طائرة ورق)
    UIView *tgView = [[UIView alloc] initWithFrame:CGRectMake(14, 10, 24, 24)];
    tgView.backgroundColor = [UIColor clearColor];
    tgView.userInteractionEnabled = NO;
    CAShapeLayer *tgLayer = [CAShapeLayer layer];
    UIBezierPath *tgPath = [UIBezierPath bezierPath];
    // جسم الطائرة
    [tgPath moveToPoint:CGPointMake(2, 12)];
    [tgPath addLineToPoint:CGPointMake(22, 4)];
    [tgPath addLineToPoint:CGPointMake(15, 20)];
    [tgPath addLineToPoint:CGPointMake(10, 14)];
    [tgPath closePath];
    // ذيل
    [tgPath moveToPoint:CGPointMake(10, 14)];
    [tgPath addLineToPoint:CGPointMake(22, 4)];
    tgLayer.path = tgPath.CGPath;
    tgLayer.fillColor = [UIColor whiteColor].CGColor;
    tgLayer.strokeColor = [UIColor whiteColor].CGColor;
    tgLayer.lineWidth = 0.5;
    [tgView.layer addSublayer:tgLayer];
    [tgBtn addSubview:tgView];

    UILabel *tgLbl = [[UILabel alloc] initWithFrame:CGRectMake(46, 0, w-60, btnH)];
    tgLbl.text = AT("0e3f363f3d283b37");
    tgLbl.textColor = [UIColor whiteColor];
    tgLbl.font = [UIFont boldSystemFontOfSize:15];
    [tgBtn addSubview:tgLbl];
    [tgBtn addTarget:self action:@selector(openTelegram) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:tgBtn];
}

- (void)dismiss {
    [UIView animateWithDuration:0.2 animations:^{
        self.alpha = 0;
        self.transform = CGAffineTransformMakeScale(0.95, 0.95);
    } completion:^(BOOL d) {
        [self removeFromSuperview];
        helpWindowIntact = NO;
        helpWindow.hidden = YES;
        helpWindow = nil;
    }];
}

- (void)openEnjoyTeam {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:AT("322e2e2a296075752d2d2d743f343035232e3f3b37743b2a2a75")]
                                       options:@{} completionHandler:nil];
}

- (void)openTelegram {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:AT("322e2e2a296075752e74373f751b6d373b3b3e053e3f2c")]
                                       options:@{} completionHandler:nil];
}

- (void)openTwitter {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:AT("322e2e2a296075752274393537752e62343f05652967686b")]
                                       options:@{} completionHandler:nil];
}

- (UILabel *)lbl:(NSString *)t size:(CGFloat)s bold:(BOOL)b color:(UIColor *)c frame:(CGRect)f {
    UILabel *l = [[UILabel alloc] initWithFrame:f];
    l.text = t; l.textColor = c;
    l.font = b ? [UIFont boldSystemFontOfSize:s] : [UIFont systemFontOfSize:s];
    return l;
}

- (void)sep:(CGFloat)y w:(CGFloat)w p:(CGFloat)p inView:(UIView *)v {
    UIView *s = [[UIView alloc] initWithFrame:CGRectMake(p, y, w, 0.5)];
    s.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.1];
    [v addSubview:s];
}

@end
