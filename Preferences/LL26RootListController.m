#import <UIKit/UIKit.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <spawn.h>

extern char **environ;

static NSString * const LL26PrefsDomain = @"com.zm.liquidlock26";
static CFStringRef const LL26PrefsChangedNotification = CFSTR("com.zm.liquidlock26/preferences.changed");

@interface LL26RootListController : PSListController
@end

@implementation LL26RootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }

    return _specifiers;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"LiquidLock26";
}

- (id)readPreferenceValue:(PSSpecifier *)specifier {
    id value = [super readPreferenceValue:specifier];
    return value ?: [specifier propertyForKey:@"default"];
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    [super setPreferenceValue:value specifier:specifier];
    CFPreferencesAppSynchronize((__bridge CFStringRef)LL26PrefsDomain);
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), LL26PrefsChangedNotification, NULL, NULL, YES);
}

- (void)respring {
    pid_t pid;
    const char *argv[] = {"sbreload", NULL};
    posix_spawn(&pid, "/var/jb/usr/bin/sbreload", NULL, NULL, (char * const *)argv, environ);
}

@end
