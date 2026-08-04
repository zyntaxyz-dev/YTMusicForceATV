#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

static BOOL PreferATV(void) {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"preferATV"];
}

// Prefer ATV (Art Track) over OMV/Visualizer when the pair exists.
// Toggle: iOS Settings.bundle -> "preferATV" (BOOL, default OFF), key directa en NSUserDefaults.

%hook YTDefaultQueueConfig
- (BOOL)forceATVPreferredWhenPlayAudioOnly {
    return PreferATV() ? YES : %orig;
}
%end

%hook YTMQueueConfigImpl
- (BOOL)forceATVPreferredWhenPlayAudioOnly {
    return PreferATV() ? YES : %orig;
}
%end

%hook YTQueueController
- (BOOL)initialUserContentModeATVPreferred {
    return PreferATV() ? YES : %orig;
}
%end
