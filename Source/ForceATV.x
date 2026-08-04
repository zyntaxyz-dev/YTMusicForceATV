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
- (NSInteger)userContentMode;
@end

@interface YTMAVSwitch : UIView
- (void)setUserContentMode:(NSInteger)contentMode;
- (void)setUserContentMode:(NSInteger)contentMode animated:(BOOL)animated;
- (NSInteger)userContentMode;
- (void)didTap:(id)sender;
@property (nonatomic, retain) NSString *audioLabel;
@property (nonatomic, retain) NSString *videoLabel;
@end

@interface YTPlayerViewController : UIViewController
- (NSString *)contentVideoID;
- (void)playbackController:(id)controller didActivateNewPlaybackWithContentVideo:(id)video;
@end

static NSString *lastVideoID = nil;
static BOOL lastHasATVOMVPair = NO;
static NSInteger lastUserContentMode = -1;

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

%hook YTMAVSwitch
- (void)setUserContentMode:(NSInteger)contentMode {
    LogATV([NSString stringWithFormat:@"YTMAVSwitch setUserContentMode:%ld (was:%ld)", (long)contentMode, (long)lastUserContentMode]);
    lastUserContentMode = contentMode;
    %orig(contentMode);
}

- (NSInteger)userContentMode {
    NSInteger mode = %orig;
    LogATV([NSString stringWithFormat:@"YTMAVSwitch userContentMode:%ld", (long)mode]);
    return mode;
}
%end

%hook YTQueueController
- (NSInteger)userContentMode {
    NSInteger mode = %orig;
    if (mode != lastUserContentMode) {
        LogATV([NSString stringWithFormat:@"YTQueueController userContentMode changed to:%ld", (long)mode]);
        lastUserContentMode = mode;
    }
    return mode;
}

- (void)updateUserContentModeForVideoAtIndex:(NSInteger)index forceATVPreferred:(BOOL)forceATV {
    LogATV([NSString stringWithFormat:@"updateUserContentModeForVideoAtIndex:%ld forceATVPreferred:%d", (long)index, forceATV]);
    %orig(index, forceATV);
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
%end

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