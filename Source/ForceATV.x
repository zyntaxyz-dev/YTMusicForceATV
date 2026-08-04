#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

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
}

// Force ATV (Art Track) over OMV/Visualizer when the pair exists.
// Default ON. Toggle in-app coming in next phase.

%hook YTDefaultQueueConfig
- (BOOL)forceATVPreferredWhenPlayAudioOnly {
    LogATV(@"forceATVPreferredWhenPlayAudioOnly called");
    return YES;
}
%end

%hook YTMQueueConfigImpl
- (BOOL)forceATVPreferredWhenPlayAudioOnly {
    LogATV(@"YTMQueueConfigImpl forceATVPreferredWhenPlayAudioOnly called");
    return YES;
}
%end

%hook YTQueueController
- (BOOL)initialUserContentModeATVPreferred {
    LogATV(@"initialUserContentModeATVPreferred called");
    return YES;
}
%end
