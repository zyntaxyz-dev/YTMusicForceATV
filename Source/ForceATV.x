#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface YTMWatchViewController : NSObject
- (NSString *)videoTitle;
- (NSString *)videoArtist;
- (NSString *)activeVideoID;
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

// DIAGNOSTIC BUILD: confirm title/artist + queue videoID are readable at
// playback time, to design the search-based ATV resolver.

%hook YTMWatchViewController
- (NSString *)videoTitle {
    NSString *t = %orig;
    LogATV([NSString stringWithFormat:@"[watch] videoTitle=%@ | videoArtist=%@ | activeVideoID=%@",
        t ?: @"(nil)", self.videoArtist ?: @"(nil)", self.activeVideoID ?: @"(nil)"]);
    return t;
}
%end

%hook YTMQueueUpdateCommand
- (NSString *)videoIDOfQueueItem:(id)queueItem userContentMode:(NSInteger)contentMode {
    NSString *vid = %orig(queueItem, contentMode);
    LogATV([NSString stringWithFormat:@"[queue] contentMode=%ld videoID=%@", (long)contentMode, vid ?: @"(nil)"]);
    return vid;
}
%end