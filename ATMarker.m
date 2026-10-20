#import "ATMarker.h"

@interface AhmadDevLayout ()
@property (nonatomic, strong) UIView *ring;
@property (nonatomic, assign) BOOL pulsing;
@end

@implementation AhmadDevLayout

- (instancetype)init {
    self = [super initWithFrame:CGRectMake(0,0,56,56)];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self buildUI];
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]
                                        initWithTarget:self action:@selector(pan:)];
        [self addGestureRecognizer:pan];
    }
    return self;
}

- (void)buildUI {
    CGFloat s = 56;

    // حلقة النبض
    self.ring = [[UIView alloc] initWithFrame:CGRectMake(-8,-8,s+16,s+16)];
    self.ring.backgroundColor = [UIColor clearColor];
    self.ring.layer.cornerRadius = (s+16)/2;
    self.ring.layer.borderColor = [[UIColor systemRedColor] colorWithAlphaComponent:0.4].CGColor;
    self.ring.layer.borderWidth = 2;
    self.ring.alpha = 0;
    self.ring.userInteractionEnabled = NO;
    [self addSubview:self.ring];

    // الدائرة الخارجية
    UIView *outer = [[UIView alloc] initWithFrame:CGRectMake(0,0,s,s)];
    outer.backgroundColor = [UIColor clearColor];
    outer.layer.cornerRadius = s/2;
    outer.layer.borderColor = [UIColor systemRedColor].CGColor;
    outer.layer.borderWidth = 2;
    outer.userInteractionEnabled = NO;
    [self addSubview:outer];

    // النقطة المركزية
    CGFloat d = 10;
    UIView *dot = [[UIView alloc] initWithFrame:CGRectMake((s-d)/2,(s-d)/2,d,d)];
    dot.backgroundColor = [UIColor systemRedColor];
    dot.layer.cornerRadius = d/2;
    dot.userInteractionEnabled = NO;
    [self addSubview:dot];

    // خطوط التقاطع
    UIView *h = [[UIView alloc] initWithFrame:CGRectMake(0,s/2-.5,s,1)];
    h.backgroundColor = [[UIColor systemRedColor] colorWithAlphaComponent:0.5];
    h.userInteractionEnabled = NO;
    [self addSubview:h];

    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(s/2-.5,0,1,s)];
    v.backgroundColor = [[UIColor systemRedColor] colorWithAlphaComponent:0.5];
    v.userInteractionEnabled = NO;
    [self addSubview:v];
}

- (void)pan:(UIPanGestureRecognizer *)g {
    CGPoint t = [g translationInView:self.superview];
    CGSize screen = [UIScreen mainScreen].bounds.size;
    CGPoint nc = CGPointMake(
        MAX(28, MIN(screen.width-28, self.center.x + t.x)),
        MAX(28, MIN(screen.height-28, self.center.y + t.y))
    );
    self.center = nc;
    self.position = nc;
    [g setTranslation:CGPointZero inView:self.superview];
}

- (void)pulse:(CGFloat)speed {
    if (self.pulsing) return;
    self.pulsing = YES;
    self.ring.alpha = 0.7;
    self.ring.transform = CGAffineTransformIdentity;
    NSTimeInterval d = MAX(0.08, 0.35/speed);
    [UIView animateWithDuration:d delay:0
                        options:UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction
                     animations:^{
        self.ring.transform = CGAffineTransformMakeScale(1.7,1.7);
        self.ring.alpha = 0;
    } completion:^(BOOL done) {
        self.ring.transform = CGAffineTransformIdentity;
        self.pulsing = NO;
    }];
}

@end

@implementation AhmadDevLayoutWindow

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hit = [super hitTest:point withEvent:event];
    // مرر للتطبيق إذا لم يكن على الماركر
    if (hit == self || hit == self.rootViewController.view) return nil;
    return hit;
}

@end
