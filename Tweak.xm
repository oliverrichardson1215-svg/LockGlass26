#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

static NSString * const LL26PrefsDomain = @"com.zm.liquidlock26";
static CFStringRef const LL26PrefsChangedNotification = CFSTR("com.zm.liquidlock26/preferences.changed");

static BOOL LL26BoolPref(NSString *key, BOOL fallback) {
    CFPropertyListRef value = CFPreferencesCopyAppValue((__bridge CFStringRef)key, (__bridge CFStringRef)LL26PrefsDomain);
    if (!value) return fallback;
    BOOL result = fallback;
    if (CFGetTypeID(value) == CFBooleanGetTypeID()) result = CFBooleanGetValue((CFBooleanRef)value);
    CFRelease(value);
    return result;
}

static CGFloat LL26FloatPref(NSString *key, CGFloat fallback) {
    CFPropertyListRef value = CFPreferencesCopyAppValue((__bridge CFStringRef)key, (__bridge CFStringRef)LL26PrefsDomain);
    if (!value) return fallback;
    CGFloat result = fallback;
    if (CFGetTypeID(value) == CFNumberGetTypeID()) CFNumberGetValue((CFNumberRef)value, kCFNumberCGFloatType, &result);
    CFRelease(value);
    return result;
}

@interface LL26LiquidClockView : UIView
@property (nonatomic, strong) UILabel *batteryLabel;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UILabel *glowLabel;
@property (nonatomic, strong) UILabel *glassMaskLabel;
@property (nonatomic, strong) UILabel *outlineLabel;
@property (nonatomic, strong) UILabel *highlightLabel;
@property (nonatomic, strong) UIVisualEffectView *blurTextView;
@property (nonatomic, strong) NSDateFormatter *timeFormatter;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) CGFloat topOffset;
@property (nonatomic, assign) CGFloat clockScale;
@property (nonatomic, assign) CGFloat opacity;
@end

@implementation LL26LiquidClockView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;

    self.userInteractionEnabled = NO;
    self.backgroundColor = UIColor.clearColor;

    _timeFormatter = [NSDateFormatter new];
    _timeFormatter.locale = [NSLocale currentLocale];
    _timeFormatter.dateFormat = @"HH:mm";

    _batteryLabel = [UILabel new];
    _batteryLabel.textAlignment = NSTextAlignmentCenter;
    _batteryLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold];
    _batteryLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.82];
    _batteryLabel.layer.shadowColor = UIColor.blackColor.CGColor;
    _batteryLabel.layer.shadowOpacity = 0.16;
    _batteryLabel.layer.shadowRadius = 10.0;
    _batteryLabel.layer.shadowOffset = CGSizeMake(0.0, 2.0);
    [self addSubview:_batteryLabel];

    _dateLabel = [UILabel new];
    _dateLabel.textAlignment = NSTextAlignmentCenter;
    _dateLabel.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightSemibold];
    _dateLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.86];
    _dateLabel.layer.shadowColor = UIColor.blackColor.CGColor;
    _dateLabel.layer.shadowOpacity = 0.14;
    _dateLabel.layer.shadowRadius = 10.0;
    _dateLabel.layer.shadowOffset = CGSizeMake(0.0, 2.0);
    [self addSubview:_dateLabel];

    UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialLight];
    _blurTextView = [[UIVisualEffectView alloc] initWithEffect:effect];
    _blurTextView.userInteractionEnabled = NO;
    _blurTextView.alpha = 0.26;
    [self addSubview:_blurTextView];

    _glassMaskLabel = [UILabel new];
    _glassMaskLabel.textAlignment = NSTextAlignmentCenter;
    _glassMaskLabel.adjustsFontSizeToFitWidth = YES;
    _glassMaskLabel.minimumScaleFactor = 0.55;
    _blurTextView.maskView = _glassMaskLabel;

    _glowLabel = [UILabel new];
    _glowLabel.textAlignment = NSTextAlignmentCenter;
    _glowLabel.adjustsFontSizeToFitWidth = YES;
    _glowLabel.minimumScaleFactor = 0.55;
    _glowLabel.textColor = [UIColor colorWithRed:0.82 green:0.96 blue:1.0 alpha:0.13];
    _glowLabel.layer.shadowColor = [UIColor colorWithRed:0.22 green:0.56 blue:1.0 alpha:1.0].CGColor;
    _glowLabel.layer.shadowOpacity = 0.62;
    _glowLabel.layer.shadowRadius = 28.0;
    _glowLabel.layer.shadowOffset = CGSizeZero;
    [self addSubview:_glowLabel];

    _outlineLabel = [UILabel new];
    _outlineLabel.textAlignment = NSTextAlignmentCenter;
    _outlineLabel.adjustsFontSizeToFitWidth = YES;
    _outlineLabel.minimumScaleFactor = 0.48;
    _outlineLabel.layer.shadowColor = [UIColor colorWithWhite:1.0 alpha:1.0].CGColor;
    _outlineLabel.layer.shadowOpacity = 0.58;
    _outlineLabel.layer.shadowRadius = 9.0;
    _outlineLabel.layer.shadowOffset = CGSizeZero;
    [self addSubview:_outlineLabel];

    _highlightLabel = [UILabel new];
    _highlightLabel.textAlignment = NSTextAlignmentCenter;
    _highlightLabel.adjustsFontSizeToFitWidth = YES;
    _highlightLabel.minimumScaleFactor = 0.55;
    _highlightLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.12];
    _highlightLabel.layer.shadowColor = UIColor.whiteColor.CGColor;
    _highlightLabel.layer.shadowOpacity = 0.46;
    _highlightLabel.layer.shadowRadius = 6.0;
    _highlightLabel.layer.shadowOffset = CGSizeMake(-1.0, -1.5);
    [self addSubview:_highlightLabel];

    [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateText) name:UIDeviceBatteryLevelDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateText) name:UIDeviceBatteryStateDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateText) name:UIApplicationSignificantTimeChangeNotification object:nil];

    [self reloadPreferences];
    [self updateText];
    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateText) userInfo:nil repeats:YES];

    return self;
}

- (void)dealloc {
    [_timer invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)reloadPreferences {
    self.topOffset = LL26FloatPref(@"TopOffset", 38.0);
    self.clockScale = LL26FloatPref(@"ClockScale", 1.0);
    self.opacity = LL26FloatPref(@"Opacity", 1.0);
    self.alpha = MAX(0.15, MIN(self.opacity, 1.0));
    [self setNeedsLayout];
}

- (UIFont *)clockFontWithSize:(CGFloat)size {
    UIFontDescriptor *descriptor = [UIFontDescriptor fontDescriptorWithFontAttributes:@{
        UIFontDescriptorFamilyAttribute: @".SF Pro Rounded",
        UIFontDescriptorTraitsAttribute: @{ UIFontWeightTrait: @(UIFontWeightUltraLight) }
    }];
    UIFont *font = [UIFont fontWithDescriptor:descriptor size:size];
    return font ?: [UIFont systemFontOfSize:size weight:UIFontWeightUltraLight];
}

- (NSAttributedString *)glassClockString:(NSString *)text strokeWidth:(CGFloat)strokeWidth strokeColor:(UIColor *)strokeColor fillColor:(UIColor *)fillColor {
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.alignment = NSTextAlignmentCenter;

    return [[NSAttributedString alloc] initWithString:text attributes:@{
        NSStrokeWidthAttributeName: @(strokeWidth),
        NSStrokeColorAttributeName: strokeColor,
        NSForegroundColorAttributeName: fillColor,
        NSParagraphStyleAttributeName: paragraphStyle,
        NSKernAttributeName: @(-2.0)
    }];
}

- (NSString *)weekdayStringForDate:(NSDate *)date {
    NSInteger weekday = [[NSCalendar currentCalendar] component:NSCalendarUnitWeekday fromDate:date];
    NSArray<NSString *> *weekdays = @[
        @"\u661F\u671F\u65E5",
        @"\u661F\u671F\u4E00",
        @"\u661F\u671F\u4E8C",
        @"\u661F\u671F\u4E09",
        @"\u661F\u671F\u56DB",
        @"\u661F\u671F\u4E94",
        @"\u661F\u671F\u516D"
    ];
    if (weekday < 1 || weekday > weekdays.count) return @"";
    return weekdays[weekday - 1];
}

- (NSString *)lunarStringForDate:(NSDate *)date {
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierChinese];
    NSDateComponents *components = [calendar components:NSCalendarUnitMonth | NSCalendarUnitDay fromDate:date];

    NSArray<NSString *> *months = @[
        @"\u6B63\u6708",
        @"\u4E8C\u6708",
        @"\u4E09\u6708",
        @"\u56DB\u6708",
        @"\u4E94\u6708",
        @"\u516D\u6708",
        @"\u4E03\u6708",
        @"\u516B\u6708",
        @"\u4E5D\u6708",
        @"\u5341\u6708",
        @"\u51AC\u6708",
        @"\u814A\u6708"
    ];

    NSArray<NSString *> *days = @[
        @"\u521D\u4E00", @"\u521D\u4E8C", @"\u521D\u4E09", @"\u521D\u56DB", @"\u521D\u4E94",
        @"\u521D\u516D", @"\u521D\u4E03", @"\u521D\u516B", @"\u521D\u4E5D", @"\u521D\u5341",
        @"\u5341\u4E00", @"\u5341\u4E8C", @"\u5341\u4E09", @"\u5341\u56DB", @"\u5341\u4E94",
        @"\u5341\u516D", @"\u5341\u4E03", @"\u5341\u516B", @"\u5341\u4E5D", @"\u4E8C\u5341",
        @"\u5EFF\u4E00", @"\u5EFF\u4E8C", @"\u5EFF\u4E09", @"\u5EFF\u56DB", @"\u5EFF\u4E94",
        @"\u5EFF\u516D", @"\u5EFF\u4E03", @"\u5EFF\u516B", @"\u5EFF\u4E5D", @"\u4E09\u5341"
    ];

    if (components.month < 1 || components.month > months.count || components.day < 1 || components.day > days.count) {
        return @"";
    }

    NSString *leapPrefix = components.leapMonth ? @"\u95F0" : @"";
    return [NSString stringWithFormat:@"%@%@%@", leapPrefix, months[components.month - 1], days[components.day - 1]];
}

- (void)updateText {
    NSDate *now = [NSDate date];
    NSString *time = [self.timeFormatter stringFromDate:now];
    self.glowLabel.text = time;
    self.glassMaskLabel.text = time;
    self.outlineLabel.attributedText = [self glassClockString:time strokeWidth:3.4 strokeColor:[UIColor colorWithWhite:1.0 alpha:0.86] fillColor:UIColor.clearColor];
    self.highlightLabel.attributedText = [self glassClockString:time strokeWidth:-1.4 strokeColor:[UIColor colorWithWhite:1.0 alpha:0.50] fillColor:[UIColor colorWithWhite:1.0 alpha:0.075]];

    NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitMonth | NSCalendarUnitDay fromDate:now];
    NSString *dateText = [NSString stringWithFormat:@"%ld\u6708%ld\u65E5", (long)dateComponents.month, (long)dateComponents.day];
    NSString *weekdayText = [self weekdayStringForDate:now];
    NSString *lunarText = [self lunarStringForDate:now];
    self.dateLabel.text = [NSString stringWithFormat:@"%@ %@ \u519C\u5386%@", dateText, weekdayText, lunarText];

    float battery = [UIDevice currentDevice].batteryLevel;
    UIDeviceBatteryState state = [UIDevice currentDevice].batteryState;
    if (battery >= 0.0f) {
        NSInteger percent = (NSInteger)lrintf(battery * 100.0f);
        NSString *prefix = (state == UIDeviceBatteryStateCharging || state == UIDeviceBatteryStateFull) ? @"\u6B63\u5728\u5145\u7535" : @"\u76EE\u524D\u7535\u91CF";
        self.batteryLabel.text = [NSString stringWithFormat:@"%@ %ld%%", prefix, (long)percent];
    } else {
        self.batteryLabel.text = @"";
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat width = CGRectGetWidth(self.bounds);
    CGFloat size = MIN(232.0, MAX(188.0, width * 0.50)) * self.clockScale;
    UIFont *clockFont = [self clockFontWithSize:size];
    self.glowLabel.font = clockFont;
    self.glassMaskLabel.font = clockFont;
    self.outlineLabel.font = clockFont;
    self.highlightLabel.font = clockFont;

    CGFloat safeTop = self.window.safeAreaInsets.top;
    CGFloat clockTop = safeTop + self.topOffset;
    CGFloat clockHeight = size * 1.18;
    CGRect clockFrame = CGRectMake(-38.0, clockTop, width + 76.0, clockHeight);

    self.batteryLabel.frame = CGRectMake(16.0, safeTop + 5.0, width - 32.0, 20.0);
    self.dateLabel.frame = CGRectMake(16.0, safeTop + 29.0, width - 32.0, 24.0);
    self.blurTextView.frame = clockFrame;
    self.blurTextView.maskView.frame = self.blurTextView.bounds;
    self.glowLabel.frame = CGRectOffset(clockFrame, 0.0, 1.0);
    self.outlineLabel.frame = clockFrame;
    self.highlightLabel.frame = CGRectOffset(clockFrame, -1.0, -1.0);
}

@end

@interface LL26Manager : NSObject
@property (nonatomic, weak) UIView *currentHostView;
@property (nonatomic, strong) LL26LiquidClockView *clockView;
@property (nonatomic, strong) NSHashTable<UIView *> *hiddenStockViews;
- (void)preferencesChanged;
@end

@implementation LL26Manager

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    _hiddenStockViews = [NSHashTable weakObjectsHashTable];
    return self;
}

+ (instancetype)sharedInstance {
    static LL26Manager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [LL26Manager new];
    });
    return manager;
}

- (BOOL)isEnabled {
    return LL26BoolPref(@"Enabled", YES);
}

- (void)attachToCoverSheetView:(UIView *)hostView {
    if (!hostView) return;

    if (![self isEnabled]) {
        [self.clockView removeFromSuperview];
        self.clockView = nil;
        [self restoreStockClock];
        return;
    }

    if (self.clockView.superview != hostView) {
        [self.clockView removeFromSuperview];
        self.clockView = [[LL26LiquidClockView alloc] initWithFrame:hostView.bounds];
        self.clockView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [hostView addSubview:self.clockView];
        self.currentHostView = hostView;
    }

    self.clockView.frame = hostView.bounds;
    [self.clockView reloadPreferences];
    [self hideStockClockInView:hostView];
    [hostView bringSubviewToFront:self.clockView];
}

- (BOOL)shouldHideView:(UIView *)view inHost:(UIView *)hostView {
    if (view == self.clockView || [view isDescendantOfView:self.clockView]) return NO;

    NSString *className = NSStringFromClass(view.class);
    NSArray<NSString *> *clockClassMarkers = @[
        @"LockScreenDateView",
        @"DateView",
        @"TimeLabel",
        @"ClockView",
        @"TimeView"
    ];

    BOOL classLooksLikeClock = NO;
    for (NSString *marker in clockClassMarkers) {
        if ([className rangeOfString:marker options:NSCaseInsensitiveSearch].location != NSNotFound) {
            classLooksLikeClock = YES;
            break;
        }
    }

    CGRect frame = [view.superview convertRect:view.frame toView:hostView];
    BOOL inClockZone = CGRectGetMinY(frame) < 330.0 && CGRectGetMaxY(frame) > 35.0;

    if (classLooksLikeClock && inClockZone) return YES;

    if ([view isKindOfClass:UILabel.class] && inClockZone) {
        UILabel *label = (UILabel *)view;
        NSString *text = label.text ?: @"";
        NSRegularExpression *timeRegex = [NSRegularExpression regularExpressionWithPattern:@"^[0-9]{1,2}:[0-9]{2}$" options:0 error:nil];
        BOOL isTimeText = [timeRegex firstMatchInString:text options:0 range:NSMakeRange(0, text.length)] != nil;
        BOOL isLarge = label.font.pointSize > 24.0;
        if (isTimeText || isLarge) return YES;
    }

    return NO;
}

- (void)hideStockClockInView:(UIView *)view {
    if (!view || !self.currentHostView) return;

    for (UIView *subview in view.subviews) {
        if ([self shouldHideView:subview inHost:self.currentHostView]) {
            subview.hidden = YES;
            subview.alpha = 0.0;
            [self.hiddenStockViews addObject:subview];
        } else {
            [self hideStockClockInView:subview];
        }
    }
}

- (void)restoreStockClock {
    for (UIView *view in self.hiddenStockViews) {
        view.hidden = NO;
        view.alpha = 1.0;
    }
    [self.hiddenStockViews removeAllObjects];
}

- (void)preferencesChanged {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (![self isEnabled]) {
            [self.clockView removeFromSuperview];
            self.clockView = nil;
            [self restoreStockClock];
            return;
        }

        if (self.currentHostView) {
            [self attachToCoverSheetView:self.currentHostView];
        }
    });
}

@end

static void LL26PreferencesChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [[LL26Manager sharedInstance] preferencesChanged];
}

%hook CSCoverSheetViewController

- (void)viewDidLayoutSubviews {
    %orig;
    UIView *coverSheetView = ((UIViewController *)self).view;
    [[LL26Manager sharedInstance] attachToCoverSheetView:coverSheetView];
}

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    UIView *coverSheetView = ((UIViewController *)self).view;
    [[LL26Manager sharedInstance] attachToCoverSheetView:coverSheetView];
}

%end

%hook CSMainPageViewController

- (void)viewDidLayoutSubviews {
    %orig;
    UIView *mainPageView = ((UIViewController *)self).view;
    [[LL26Manager sharedInstance] attachToCoverSheetView:mainPageView];
}

%end

%ctor {
    @autoreleasepool {
        if ([[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.springboard"]) {
            CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, LL26PreferencesChanged, LL26PrefsChangedNotification, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
            %init;
        }
    }
}
