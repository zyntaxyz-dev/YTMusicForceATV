#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface YTQueueItem : NSObject
- (BOOL)hasATVOMVPair;
- (id)rendererForContentMode:(NSInteger)contentMode;
- (id)watchEndpointForContentMode:(NSInteger)contentMode;
@end

@interface YTMQueueUpdateCommand : NSObject
- (NSString *)videoIDOfQueueItem:(id)queueItem userContentMode:(NSInteger)contentMode;
@end

@interface YTQueueController : NSObject
- (NSString *)nowPlayingVideoID;
- (NSInteger)userContentMode;
- (void)updateUserContentModeForVideoAtIndex:(NSInteger)index forceATVPreferred:(BOOL)forceATV;
@end

static NSString *lastVideoID = nil;

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

%hook YTQueueController
- (NSString *)nowPlayingVideoID {
    NSString *vid = %orig;
    if (vid && ![vid isEqualToString:lastVideoID]) {
        lastVideoID = vid;
        LogATV([NSString stringWithFormat:@"nowPlayingVideoID changed: %@", vid]);
    }
    return vid;
}

- (void)updateUserContentModeForVideoAtIndex:(NSInteger)index forceATVPreferred:(BOOL)forceATV {
    LogATV([NSString stringWithFormat:@"updateUserContentModeForVideoAtIndex:%ld forceATVPreferred:%d", (long)index, forceATV]);
    %orig(index, forceATV);
}
%end

%hook YTMQueueUpdateCommand
- (NSString *)videoIDOfQueueItem:(id)queueItem userContentMode:(NSInteger)contentMode {
    NSString *vid = %orig(queueItem, contentMode);
    LogATV([NSString stringWithFormat:@"videoIDOfQueueItem:userContentMode:%ld -> %@", (long)contentMode, vid ?: @"(nil)"]);
    return vid;
}
%end

%hook YTQueueItem
- (id)watchEndpointForContentMode:(NSInteger)contentMode {
    id endpoint = %orig(contentMode);
    LogATV([NSString stringWithFormat:@"watchEndpointForContentMode:%ld -> %@", (long)contentMode, endpoint ? @"(endpoint)" : @"(nil)"]);
    return endpoint;
}

- (id)rendererForContentMode:(NSInteger)contentMode {
    LogATV([NSString stringWithFormat:@"rendererForContentMode:%ld hasATVOMVPair=%d", (long)contentMode, self.hasATVOMVPair]);
    return %orig;
}
%end