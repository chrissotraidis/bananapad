#import "native_ui_state.h"

#import <UIKit/UIKit.h>

#include <atomic>

namespace {

std::atomic_bool g_native_ui_input_suppressed{true};

} // namespace

@interface BananaPadNativeUIStateMonitor : NSObject
@property(nonatomic, strong) CADisplayLink* displayLink;
- (void)startMonitoring;
- (void)forceSuppressed;
- (void)refresh;
@end


@implementation BananaPadNativeUIStateMonitor

+ (void)load {
    dispatch_async(dispatch_get_main_queue(), ^{
        static BananaPadNativeUIStateMonitor* monitor;
        monitor = [BananaPadNativeUIStateMonitor new];
        [monitor startMonitoring];
    });
}

- (void)startMonitoring {
    NSNotificationCenter* notifications = NSNotificationCenter.defaultCenter;
    [notifications addObserver:self
                      selector:@selector(forceSuppressed)
                          name:UIApplicationWillResignActiveNotification
                        object:nil];
    [notifications addObserver:self
                      selector:@selector(refresh)
                          name:UIApplicationDidBecomeActiveNotification
                        object:nil];
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(refresh)];
    [self.displayLink addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
    [self refresh];
}

- (void)forceSuppressed {
    g_native_ui_input_suppressed.store(true, std::memory_order_release);
}

- (void)refresh {
    UIApplication* application = UIApplication.sharedApplication;
    BOOL suppressed = application.applicationState != UIApplicationStateActive;
    if (!suppressed) {
        for (UIScene* scene in application.connectedScenes) {
            if (![scene isKindOfClass:UIWindowScene.class]) continue;
            for (UIWindow* window in ((UIWindowScene*)scene).windows) {
                if (window.hidden || window.alpha <= 0.0 || window.rootViewController == nil) continue;
                if (window.rootViewController.presentedViewController != nil) {
                    suppressed = YES;
                    break;
                }
            }
            if (suppressed) break;
        }
    }
    g_native_ui_input_suppressed.store(suppressed, std::memory_order_release);
}

@end

extern "C" int BananaPad_IsNativeUIInputSuppressed(void) {
    return g_native_ui_input_suppressed.load(std::memory_order_acquire) ? 1 : 0;
}
