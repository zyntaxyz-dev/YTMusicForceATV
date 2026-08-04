#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface YTIPlaylistPanelVideoRenderer : NSObject
- (NSString *)yt_videoID;
- (NSString *)bindingVideoID;
- (NSString *)bindingPlaylistID;
- (NSNumber *)yt_musicVideoType;
@end

@interface YTQueueItem : NSObject
- (id)initWithPlaylistPanelVideoRenderer:(id)renderer;
- (BOOL)hasATVOMVPair;
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

// DIAGNOSTIC BUILD: determine whether the album's PlaylistPanelVideoRenderer
// carries a populated bindingVideoID (the ATV counterpart), which decides
// between a local videoId swap vs a search-based resolver.

%hook YTQueueItem
- (id)initWithPlaylistPanelVideoRenderer:(id)renderer {
    YTIPlaylistPanelVideoRenderer *r = renderer;
    LogATV([NSString stringWithFormat:@"[init renderer] yt_videoID=%@ | bindingVideoID=%@ | bindingPlaylistID=%@ | musicVideoType=%ld",
        r.yt_videoID ?: @"(nil)",
        r.bindingVideoID ?: @"(nil)",
        r.bindingPlaylistID ?: @"(nil)",
        (long)r.yt_musicVideoType.integerValue]);
    return %orig(renderer);
}

- (BOOL)hasATVOMVPair {
    return %orig;
}
%end

%hook YTMQueueUpdateCommand
- (NSString *)videoIDOfQueueItem:(id)queueItem userContentMode:(NSInteger)contentMode {
    NSString *vid = %orig(queueItem, contentMode);
    LogATV([NSString stringWithFormat:@"[queue] contentMode=%ld videoID=%@", (long)contentMode, vid ?: @"(nil)"]);
    return vid;
}
%end