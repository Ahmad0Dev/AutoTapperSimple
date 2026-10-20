#import "ATSimplePanel.h"
#import "ATCrypt.h"
#import "ATHelpView.h"
#import "ATHelpView.h"
#import "ATEngine.h"
#import "ATMarker.h"

@interface T8neeAnimator ()
@property (nonatomic, strong) UILabel  *statusLbl;
@property (nonatomic, strong) UILabel  *coordLbl;
@property (nonatomic, strong) UIButton *markerBtn;
@property (nonatomic, strong) UIButton *startStopBtn;
@property (nonatomic, strong) UISlider *slider;
@property (nonatomic, strong) UITextField *speedField;
@property (nonatomic, weak)   UIWindow *markerWindow;
@property (nonatomic, weak)   AhmadDevLayout *marker;
@property (nonatomic, assign) BOOL markerOn;
@end

@implementation T8neeAnimator

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) [self build];
    return self;
}

- (void)setMarkerWindow:(UIWindow *)mw marker:(UIView *)marker {
    self.markerWindow = mw;
    self.marker = (AhmadDevLayout *)marker;
}

- (void)build {
    // خلفية
    self.backgroundColor = [[UIColor colorWithRed:0.08 green:0.08 blue:0.12 alpha:0.94] copy];
    self.layer.cornerRadius = 16;
    self.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.12].CGColor;
    self.layer.borderWidth = 0.5;
    self.clipsToBounds = YES;

    CGFloat p = 13, w = self.frame.size.width - p*2, y = p;

    // ── العنوان ──
    // عنوان مع زر المساعدة
    UILabel *title = [self label:AT("b8c0fb7a1b2f2e350e3b2a2a3f287a247a1b32373b3e1e3f2c") size:15 bold:YES color:[UIColor whiteColor]
                           frame:CGRectMake(p,y,w-36,22)];
    title.textAlignment = NSTextAlignmentCenter;
    [self addSubview:title];

    // زر التعليمات ؟
    UIButton *helpBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width-p-28, y-2, 26, 26)];
    [helpBtn setTitle:@"?" forState:UIControlStateNormal];
    [helpBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    helpBtn.titleLabel.font = [UIFont boldSystemFontOfSize:13];
    helpBtn.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.15];
    helpBtn.layer.cornerRadius = 13;
    [helpBtn addTarget:self action:@selector(showHelp) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:helpBtn];
    y += 28;

    [self sep:y w:w p:p]; y += 8;

    // ── الحالة ──
    self.statusLbl = [self label:AT("b8cdd57a83df82f083d283d883db") size:12 bold:YES color:[UIColor systemRedColor]
                           frame:CGRectMake(p,y,w,16)];
    self.statusLbl.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.statusLbl]; y += 20;

    // ── الإحداثيات ──
    self.coordLbl = [self label:@"X: ---   Y: ---" size:12 bold:NO color:[UIColor systemYellowColor]
                          frame:CGRectMake(p,y,w,16)];
    self.coordLbl.font = [UIFont monospacedDigitSystemFontOfSize:12 weight:UIFontWeightMedium];
    self.coordLbl.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.coordLbl]; y += 22;

    [self sep:y w:w p:p]; y += 8;

    // ── زر الماركر ──
    self.markerBtn = [self btn:AT("aac5c9d77a82fd83de83df82fd82eb83d982eb607a83df82e083de83d8") color:[[UIColor whiteColor] colorWithAlphaComponent:0.15]
                         frame:CGRectMake(p,y,w,38)];
    [self.markerBtn addTarget:self action:@selector(toggleMarker) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.markerBtn]; y += 46;

    [self sep:y w:w p:p]; y += 8;

    // ── السرعة ──
    UILabel *speedTitle = [self label:AT("82fd83de82e982eb82e382f37a7a7282ec82e082ed82f37582f182fd83dc83d082f373") size:10 bold:NO
                                color:[[UIColor whiteColor] colorWithAlphaComponent:0.5]
                                frame:CGRectMake(p,y,w,14)];
    [self addSubview:speedTitle]; y += 18;

    self.slider = [[UISlider alloc] initWithFrame:CGRectMake(p,y,w-58,28)];
    self.slider.minimumValue = 1; self.slider.maximumValue = 10; self.slider.value = 5;
    self.slider.tintColor = [UIColor systemBlueColor];
    [self.slider addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:self.slider];

    self.speedField = [[UITextField alloc] initWithFrame:CGRectMake(self.frame.size.width-p-52,y,52,28)];
    self.speedField.text = @"5.0";
    self.speedField.textColor = [UIColor whiteColor];
    self.speedField.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.1];
    self.speedField.textAlignment = NSTextAlignmentCenter;
    self.speedField.font = [UIFont monospacedDigitSystemFontOfSize:12 weight:UIFontWeightMedium];
    self.speedField.keyboardType = UIKeyboardTypeDecimalPad;
    self.speedField.layer.cornerRadius = 7;
    [self.speedField addTarget:self action:@selector(fieldChanged:) forControlEvents:UIControlEventEditingChanged];
    [self addSubview:self.speedField]; y += 36;

    [self sep:y w:w p:p]; y += 8;

    // ── زر التشغيل/الإيقاف ──
    self.startStopBtn = [self btn:AT("b8ccec7a7a82f082ee82e083d083de") color:[[UIColor whiteColor] colorWithAlphaComponent:0.15]
                            frame:CGRectMake(p,y,w,42)];
    self.startStopBtn.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    [self.startStopBtn addTarget:self action:@selector(toggleStartStop) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.startStopBtn]; y += 50;

    // ── تنبيه اللمسة الأولى ──
    UILabel *hint = [self label:AT("b8c0fab5e2d57a82fd83de83df82e97a82fd83de82ee82fd82ee82f37a83df82eb82f37a83de82f083dd83d082fc82f37a82fd83de83df82f782eb83d9") size:9 bold:NO
                          color:[[UIColor systemYellowColor] colorWithAlphaComponent:0.6]
                          frame:CGRectMake(p,y,w,12)];
    hint.textAlignment = NSTextAlignmentCenter;
    hint.tag = 9001;
    [self addSubview:hint];

    // إخفاء التنبيه بعد أول لمسة
    [[NSNotificationCenter defaultCenter] addObserverForName:@"ATTouchReady" object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *n) {
        UIView *h = [self viewWithTag:9001];
        [UIView animateWithDuration:0.3 animations:^{ h.alpha = 0; }];
    }];

    // إغلاق الكيبورد بالضغط خارجه
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                    initWithTarget:self action:@selector(dismissKB)];
    tap.cancelsTouchesInView = NO;
    [self addGestureRecognizer:tap];

    // Timer التحديث
    [NSTimer scheduledTimerWithTimeInterval:0.15 target:self
                                   selector:@selector(updateUI) userInfo:nil repeats:YES];

    // إشعار النبض
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onTap)
                                                 name:@"ATDidTap" object:nil];
}

- (void)showHelp {
    UIWindow *win = self.window;
    if (win) [T8neeHelpView showInWindow:win];
}

#pragma mark - Help

#pragma mark - Actions

- (void)toggleMarker {
    self.markerOn = !self.markerOn;
    self.markerWindow.hidden = !self.markerOn;

    if (self.markerOn) {
        // ضبط الإحداثيات عند إظهار الماركر
        CGSize screen = [UIScreen mainScreen].bounds.size;
        if (CGPointEqualToPoint(self.marker.position, CGPointZero)) {
            self.marker.center = CGPointMake(screen.width/2, screen.height/2);
            self.marker.position = self.marker.center;
        }
        [AhmadDevDelegate shared].tapX = self.marker.position.x;
        [AhmadDevDelegate shared].tapY = self.marker.position.y;
        [self.markerBtn setTitle:AT("aac5c9d77a82fd83de83df82fd82eb83d982eb607a83d082e383df83de") forState:UIControlStateNormal];
        [UIView animateWithDuration:0.2 animations:^{
            self.markerBtn.backgroundColor = [UIColor systemGreenColor];
        }];
    } else {
        [self.markerBtn setTitle:AT("aac5c9d77a82fd83de83df82fd82eb83d982eb607a83df82e083de83d8") forState:UIControlStateNormal];
        [UIView animateWithDuration:0.2 animations:^{
            self.markerBtn.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.15];
        }];
        // إيقاف التشغيل عند إخفاء الماركر
        [[AhmadDevDelegate shared] stop];
    }
}

- (void)toggleStartStop {
    AhmadDevDelegate *e = [AhmadDevDelegate shared];
    if (e.isRunning) {
        [e stop];
    } else {
        if (!self.markerOn) {
            // هز الزر إذا الماركر مغلق
            [self shake:self.markerBtn];
            return;
        }
        // تحديث الإحداثيات من الماركر
        [AhmadDevDelegate shared].tapX = self.marker.position.x;
        [AhmadDevDelegate shared].tapY = self.marker.position.y;
        [e start];
    }
}

- (void)sliderChanged:(UISlider *)s {
    CGFloat v = roundf(s.value*2)/2.0;
    [AhmadDevDelegate shared].tapSpeed = MAX(1, MIN(10, v));
    self.speedField.text = [NSString stringWithFormat:@"%.1f", v];
    if ([AhmadDevDelegate shared].isRunning) {
        [[AhmadDevDelegate shared] stop];
        [[AhmadDevDelegate shared] start];
    }
}

- (void)fieldChanged:(UITextField *)f {
    CGFloat v = [f.text floatValue];
    if (v >= 1 && v <= 10) {
        [AhmadDevDelegate shared].tapSpeed = v;
        self.slider.value = v;
        if ([AhmadDevDelegate shared].isRunning) {
            [[AhmadDevDelegate shared] stop];
            [[AhmadDevDelegate shared] start];
        }
    }
}

- (void)dismissKB { [self.speedField resignFirstResponder]; }

- (void)onTap {
    if (self.markerOn) [self.marker pulse:[AhmadDevDelegate shared].tapSpeed];
    // تحديث الإحداثيات من الماركر عند كل ضغطة
    [AhmadDevDelegate shared].tapX = self.marker.position.x;
    [AhmadDevDelegate shared].tapY = self.marker.position.y;
}

#pragma mark - Update UI

- (void)updateUI {
    AhmadDevDelegate *e = [AhmadDevDelegate shared];
    BOOL run = e.isRunning;

    // الإحداثيات - تحديث مستمر من الماركر
    if (self.markerOn) {
        self.coordLbl.text = [NSString stringWithFormat:@"X: %.0f   Y: %.0f",
                               self.marker.position.x, self.marker.position.y];
        // مزامنة الإحداثيات مع الماركر
        e.tapX = self.marker.position.x;
        e.tapY = self.marker.position.y;
    }

    // حالة التشغيل
    if (run) {
        self.statusLbl.text = AT("b8cdd57a83d082e383df83de");
        self.statusLbl.textColor = [UIColor systemGreenColor];
        [self.startStopBtn setTitle:AT("b8ccfa7a7a82ff83d083d882fd83db") forState:UIControlStateNormal];
        self.startStopBtn.backgroundColor = [UIColor systemRedColor];
    } else {
        self.statusLbl.text = AT("b8cdd57a83df82f083d283d883db");
        self.statusLbl.textColor = [UIColor systemRedColor];
        [self.startStopBtn setTitle:AT("b8ccec7a7a82f082ee82e083d083de") forState:UIControlStateNormal];
        self.startStopBtn.backgroundColor = self.markerOn ?
            [UIColor systemGreenColor] : [[UIColor whiteColor] colorWithAlphaComponent:0.15];
    }
}

#pragma mark - Helpers

- (UILabel *)label:(NSString *)t size:(CGFloat)s bold:(BOOL)b color:(UIColor *)c frame:(CGRect)f {
    UILabel *l = [[UILabel alloc] initWithFrame:f];
    l.text = t; l.textColor = c;
    l.font = b ? [UIFont boldSystemFontOfSize:s] : [UIFont systemFontOfSize:s];
    return l;
}

- (UIButton *)btn:(NSString *)title color:(UIColor *)color frame:(CGRect)frame {
    UIButton *b = [[UIButton alloc] initWithFrame:frame];
    [b setTitle:title forState:UIControlStateNormal];
    [b setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    b.backgroundColor = color;
    b.titleLabel.font = [UIFont boldSystemFontOfSize:13];
    b.layer.cornerRadius = 9;
    return b;
}

- (void)sep:(CGFloat)y w:(CGFloat)w p:(CGFloat)p {
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(p,y,w,.5)];
    v.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.1];
    [self addSubview:v];
}

- (void)shake:(UIButton *)btn {
    CAKeyframeAnimation *a = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
    a.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    a.duration = 0.3; a.values = @[@(-6),@(6),@(-4),@(4),@(-2),@(2),@(0)];
    [btn.layer addAnimation:a forKey:@"shake"];
}

@end
