#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface YTQueueItem : NSObject
- (id)rendererForContentMode:(NSInteger)contentMode;
- (id)videoRenderer;
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

static NSString *KVC(NSString *tag, id obj) {
    if (!obj) return @"(obj nil)";
    id v = nil;
    @try { v = [obj valueForKey:tag]; }
    @catch (NSException *e) { return @"(err)"; }
    return [v isKindOfClass:[NSString class]] ? v : (v ? [NSString stringWithFormat:@"(nonstr %@)", NSStringFromClass([v class])] : @"(nil)");
}

%ctor {
    LogATV(@"ForceATV dylib loaded");
}

// DIAGNOSTIC BUILD (defensive): read yt_videoID/bindingVideoID from the queue
// item renderer via KVC inside @try, to avoid crashing. Goal: verify whether
// the album's PlaylistPanelVideoRenderer carries a populated bindingVideoID (ATV).

%hook YTQueueItem
- (id)rendererForContentMode:(NSInteger)contentMode {
    id r = %orig(contentMode);
    @try {
        LogATV([NSString stringWithFormat:@"[qi] rcm:%ld -> %@ | yt_videoID=%@ | bindingVideoID=%@",
            (long)contentMode,
            NSStringFromClass([r class]),
            KVC(@"yt_videoID", r),
            KVC(@"bindingVideoID", r)]);
        id vr = [self valueForKey:@"videoRenderer"];
        LogATV([NSString stringWithFormat:@"[qi] videoRenderer=%@ | yt_videoID=%@ | bindingVideoID=%@",
            NSStringFromClass([vr class]),
            KVC(@"yt_videoID", vr),
            KVC(@"bindingVideoID", vr)]);
    } @catch (NSException *e) {
        LogATV([NSString stringWithFormat:@"[qi] exception: %@", e.reason]);
    }
    return r;
}
%end