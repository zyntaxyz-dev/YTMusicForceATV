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
- (void)checkVideoRendererAndMaybePlayItemAtIndex:(NSInteger)index autoplay:(BOOL)autoplay isPlaybackControllerInternalTransition:(BOOL)internal;
- (void)setUserContentMode:(NSInteger)contentMode atPlaybackTime:(double)time;
@end

@interface YTPlayerViewController : UIViewController
- (NSString *)contentVideoID;
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

%hook YTPlayerViewController
- (NSString *)contentVideoID {
    NSString *vid = %orig;
    LogATV([NSString stringWithFormat:@"contentVideoID: %@", vid ?: @"(nil)"]);
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

- (void)checkVideoRendererAndMaybePlayItemAtIndex:(NSInteger)index autoplay:(BOOL)autoplay isPlaybackControllerInternalTransition:(BOOL)internal {
    LogATV([NSString stringWithFormat:@"checkVideoRendererAndMaybePlayItemAtIndex:%ld autoplay:%d internal:%d", (long)index, autoplay, internal]);
    %orig(index, autoplay, internal);
}

- (void)setUserContentMode:(NSInteger)contentMode atPlaybackTime:(double)time {
    LogATV([NSString stringWithFormat:@"setUserContentMode:%ld atPlaybackTime:%.3f", (long)contentMode, time]);
    %orig(contentMode, time);
}
%end

%hook YTQueueItem
- (void)setHasATVOMVPair:(BOOL)value {
    LogATV([NSString stringWithFormat:@"setHasATVOMVPair:%d", value]);
    %orig(value);
}

- (void)updateVideoRendererForUserContentMode:(NSInteger)contentMode {
    LogATV([NSString stringWithFormat:@"updateVideoRendererForUserContentMode:%ld hasATVOMVPair=%d", (long)contentMode, self.hasATVOMVPair]);
    %orig(contentMode);
}

- (id)rendererForContentMode:(NSInteger)contentMode {
    LogATV([NSString stringWithFormat:@"rendererForContentMode:%ld hasATVOMVPair=%d audioModeRenderer=%@", (long)contentMode, self.hasATVOMVPair, self.audioModeRenderer ?: @"(nil)"]);
    return %orig;
}
%end