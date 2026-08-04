#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface YTQueueItem : NSObject
- (BOOL)hasATVOMVPair;
- (id)rendererForContentMode:(NSInteger)contentMode;
@end

@interface YTMQueueUpdateCommand : NSObject
- (NSString *)videoIDOfQueueItem:(id)queueItem userContentMode:(NSInteger)contentMode;
@end

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
// Content mode: 0 = OMV, 1 = ATV.
// Hook YTQueueItem -rendererForContentMode: to always return the ATV renderer,
// regardless of the content mode parameter passed. This bypasses:
// - forceATVPreferredWhenPlayAudioOnly (only affects audio-only mode)
// - initialUserContentModeATVPreferred (never called during video playback)
// - hasATVOMVPair (always 0 in this flow - never set by YTM)

%hook YTQueueItem
- (id)rendererForContentMode:(NSInteger)contentMode {
    LogATV([NSString stringWithFormat:@"rendererForContentMode:%ld -> forcing ATV (1)", (long)contentMode]);
    return %orig(1);
}
%end

%hook YTMQueueUpdateCommand
- (NSString *)videoIDOfQueueItem:(id)queueItem userContentMode:(NSInteger)contentMode {
    NSString *vid = %orig(queueItem, 1);
    LogATV([NSString stringWithFormat:@"videoIDOfQueueItem:userContentMode:%ld -> forcing ATV (1) = %@", (long)contentMode, vid ?: @"(nil)"]);
    return vid;
}
%end
