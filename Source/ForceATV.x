#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

static BOOL FAPref(NSString *key) {
    NSDictionary *YTMUltimateDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"YTMUltimate"];
    return [YTMUltimateDict[key] boolValue];
}

// Prefer ATV (Art Track) over OMV/Visualizer when the pair exists.
// Toggle: NSUserDefaults "YTMUltimate" -> preferATV (BOOL, default OFF).

%hook YTDefaultQueueConfig
- (BOOL)forceATVPreferredWhenPlayAudioOnly {
    return FAPref(@"preferATV") ? YES : %orig;
}
%end

%hook YTMQueueConfigImpl
- (BOOL)forceATVPreferredWhenPlayAudioOnly {
    return FAPref(@"preferATV") ? YES : %orig;
}
%end

%hook YTQueueController
- (BOOL)initialUserContentModeATVPreferred {
    return FAPref(@"preferATV") ? YES : %orig;
}
%end

%ctor {
    NSMutableDictionary *YTMUltimateDict = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"YTMUltimate"]];
    if (!YTMUltimateDict[@"preferATV"]) {
        [YTMUltimateDict setObject:@(NO) forKey:@"preferATV"];
        [[NSUserDefaults standardUserDefaults] setObject:YTMUltimateDict forKey:@"YTMUltimate"];
    }
}
