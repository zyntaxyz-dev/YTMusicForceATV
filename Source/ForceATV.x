#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface YTQueueItem : NSObject
- (BOOL)hasATVOMVPair;
- (void)setHasATVOMVPair:(BOOL)value;
@property (nonatomic, retain) id audioModeRenderer;
@property (nonatomic, retain) id videoModeRenderer;
- (id)rendererForContentMode:(NSInteger)contentMode;
- (id)watchEndpointForContentMode:(NSInteger)contentMode;
- (void)updateVideoRendererForUserContentMode:(NSInteger)contentMode;
@end

@interface YTQueueController : NSObject
- (BOOL)initialUserContentModeATVPreferred;
- (id)videoForUserContentModeAtIndex:(NSInteger)index includeAutoplaySection:(BOOL)includeAutoplay;
- (void)updateUserContentModeForVideoAtIndex:(NSInteger)index forceATVPreferred:(BOOL)forceATV;
- (void)setUserContentMode:(NSInteger)contentMode atPlaybackTime:(double)time;
@end

@interface YTPlayerViewController : UIViewController
- (NSString *)contentVideoID;
@end

static NSString *lastVideoID = nil;
static BOOL lastHasATVOMVPair = NO;

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

%hook YTPlayerViewController
- (NSString *)contentVideoID {
    NSString *vid = %orig;
    if (vid && ![vid isEqualToString:lastVideoID]) {
        lastVideoID = vid;
        LogATV([NSString stringWithFormat:@"contentVideoID changed: %@", vid]);
    }
    return vid;
}
%end

%hook YTQueueController
- (BOOL)initialUserContentModeATVPreferred {
    LogATV(@"initialUserContentModeATVPreferred called");
    return YES;
}

- (id)videoForUserContentModeAtIndex:(NSInteger)index includeAutoplaySection:(BOOL)includeAutoplay {
    id result = %orig(index, includeAutoplay);
    LogATV([NSString stringWithFormat:@"videoForUserContentModeAtIndex:%ld includeAutoplay:%d -> %@", (long)index, includeAutoplay, result ?: @"(nil)"]);
    return result;
}

- (void)updateUserContentModeForVideoAtIndex:(NSInteger)index forceATVPreferred:(BOOL)forceATV {
    LogATV([NSString stringWithFormat:@"updateUserContentModeForVideoAtIndex:%ld forceATVPreferred:%d", (long)index, forceATV]);
    %orig(index, forceATV);
}

- (void)setUserContentMode:(NSInteger)contentMode atPlaybackTime:(double)time {
    LogATV([NSString stringWithFormat:@"setUserContentMode:%ld atPlaybackTime:%.3f", (long)contentMode, time]);
    %orig(contentMode, time);
}
%end

%hook YTQueueItem
- (void)setHasATVOMVPair:(BOOL)value {
    if (value != lastHasATVOMVPair) {
        lastHasATVOMVPair = value;
        LogATV([NSString stringWithFormat:@"setHasATVOMVPair changed to: %@", value ? @"YES" : @"NO"]);
    }
    %orig(value);
}

- (void)updateVideoRendererForUserContentMode:(NSInteger)contentMode {
    LogATV([NSString stringWithFormat:@"updateVideoRendererForUserContentMode:%ld hasATVOMVPair=%d", (long)contentMode, self.hasATVOMVPair]);
    %orig(contentMode);
}
%end