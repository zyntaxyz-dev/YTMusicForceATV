#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

static BOOL PreferATV(void) {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"preferATV"];
}

static void LogATV(NSString *msg) {
    NSString *docs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *path = [docs stringByAppendingPathComponent:@"ForceATV.log"];
    NSString *line = [NSString stringWithFormat:@"%@\n", msg];
    NSFileHandle *h = [NSFileHandle fileHandleForWritingAtPath:path];
    if (h) {
        [h seekToEndOfFile];
        [h writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
        [h closeFile];
    } else {
        [[line dataUsingEncoding:NSUTF8StringEncoding] writeToFile:path atomically:YES];
    }
}

%ctor {
    LogATV(@"ForceATV dylib loaded");
    LogATV([NSString stringWithFormat:@"preferATV=%@", PreferATV() ? @"YES" : @"NO"]);
}

// Prefer ATV (Art Track) over OMV/Visualizer when the pair exists.
// Toggle: iOS Settings.bundle -> "preferATV" (BOOL, default OFF), key directa en NSUserDefaults.

%hook YTDefaultQueueConfig
- (BOOL)forceATVPreferredWhenPlayAudioOnly {
    LogATV(@"forceATVPreferredWhenPlayAudioOnly called");
    return PreferATV() ? YES : %orig;
}
%end

%hook YTMQueueConfigImpl
- (BOOL)forceATVPreferredWhenPlayAudioOnly {
    LogATV(@"YTMQueueConfigImpl forceATVPreferredWhenPlayAudioOnly called");
    return PreferATV() ? YES : %orig;
}
%end

%hook YTQueueController
- (BOOL)initialUserContentModeATVPreferred {
    LogATV(@"initialUserContentModeATVPreferred called");
    return PreferATV() ? YES : %orig;
}
%end
