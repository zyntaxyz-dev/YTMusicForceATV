#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface YTMWatchViewController : NSObject
- (void)setVideoTitle:(NSString *)videoTitle videoArtist:(NSString *)videoArtist;
- (NSString *)activeVideoID;
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

// DIAGNOSTIC BUILD: confirm title/artist arrive at setVideoTitle:videoArtist:
// (data needed for the search-based ATV resolver) and activeVideoID at that point.

%hook YTMWatchViewController
- (void)setVideoTitle:(NSString *)videoTitle videoArtist:(NSString *)videoArtist {
    @try {
        LogATV([NSString stringWithFormat:@"[setTitle] title=%@ | artist=%@ | activeVideoID=%@",
            videoTitle ?: @"(nil)",
            videoArtist ?: @"(nil)",
            self.activeVideoID ?: @"(nil)"]);
    } @catch (NSException *e) {
        LogATV([NSString stringWithFormat:@"[setTitle] exc: %@", e.reason]);
    }
    return %orig(videoTitle, videoArtist);
}

- (NSString *)activeVideoID {
    NSString *v = %orig;
    LogATV([NSString stringWithFormat:@"[activeVideoID] %@", v ?: @"(nil)"]);
    return v;
}
%end