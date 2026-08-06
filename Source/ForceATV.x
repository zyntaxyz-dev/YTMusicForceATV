#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface YTIPlaylistPanelVideoRenderer : NSObject
- (NSString *)yt_videoID;
- (NSString *)bindingVideoID;
- (NSString *)bindingPlaylistID;
- (id)yt_musicVideoType;
@end

@interface YTQueueItem : NSObject
- (id)rendererForContentMode:(NSInteger)contentMode;
- (id)videoRenderer;
- (id)audioModeRenderer;
- (id)videoModeRenderer;
- (BOOL)hasATVOMVPair;
@end

@interface YTMMusicShelfSectionController : NSObject
- (void)handleEntries:(id)entries;
- (id)shelfRenderer;
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

static void LogRenderer(NSString *tag, id renderer) {
    YTIPlaylistPanelVideoRenderer *r = renderer;
    if (!r || ![r respondsToSelector:@selector(yt_videoID)]) return;
    LogATV([NSString stringWithFormat:@"[%s] yt_videoID=%@ | bindingVideoID=%@ | bindingPlaylistID=%@ | mvt=%ld",
        tag.UTF8String,
        [r yt_videoID] ?: @"(nil)",
        [r bindingVideoID] ?: @"(nil)",
        [r bindingPlaylistID] ?: @"(nil)",
        (long)[(NSNumber *)[r yt_musicVideoType] integerValue]]);
}

%ctor {
    LogATV(@"ForceATV dylib loaded");
}

// DIAGNOSTIC BUILD: verify whether the album's PlaylistPanelVideoRenderer carries
// a populated bindingVideoID (ATV) at the point where the response is parsed
// (handleEntries) and at the queue-item renderer point (rendererForContentMode).

%hook YTMMusicShelfSectionController
- (void)handleEntries:(id)entries {
    LogATV([NSString stringWithFormat:@"[shelf] handleEntries: class=%@ count=%lu",
        NSStringFromClass([entries class]), (unsigned long)[entries count]]);
    @try {
        id shelf = self.shelfRenderer;
        LogATV([NSString stringWithFormat:@"[shelf] shelfRenderer=%@", NSStringFromClass([shelf class])]);
    } @catch (...) {}
    return %orig(entries);
}
%end

%hook YTQueueItem
- (id)rendererForContentMode:(NSInteger)contentMode {
    id r = %orig(contentMode);
    LogATV([NSString stringWithFormat:@"[queueItem] rendererForContentMode:%ld -> %@", (long)contentMode, NSStringFromClass([r class])]);
    LogRenderer(@"rendererForContentMode", r);
    LogRenderer(@"videoRenderer", self.videoRenderer);
    LogRenderer(@"audioModeRenderer", self.audioModeRenderer);
    LogRenderer(@"videoModeRenderer", self.videoModeRenderer);
    return r;
}

- (BOOL)hasATVOMVPair {
    BOOL v = %orig;
    if (v) LogATV(@"[queueItem] hasATVOMVPair=YES");
    return v;
}
%end