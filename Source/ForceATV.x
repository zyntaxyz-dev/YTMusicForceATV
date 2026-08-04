#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface YTQueueItem : NSObject
- (BOOL)hasATVOMVPair;
@property (nonatomic, retain) id audioModeRenderer;
@property (nonatomic, retain) id videoModeRenderer;
- (id)rendererForContentMode:(NSInteger)contentMode;
- (id)watchEndpointForContentMode:(NSInteger)contentMode;
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
// Hooks target the actual videoId selection path, not just audio-only flags.

%hook YTQueueItem
- (id)rendererForContentMode:(NSInteger)contentMode {
    if (self.hasATVOMVPair && self.audioModeRenderer) {
        LogATV(@"rendererForContentMode: forced ATV");
        return self.audioModeRenderer;
    }
    return %orig;
}

- (id)watchEndpointForContentMode:(NSInteger)contentMode {
    if (self.hasATVOMVPair) {
        id endpoint = %orig(0);
        if (endpoint) {
            LogATV(@"watchEndpointForContentMode: forced ATV");
            return endpoint;
        }
    }
    return %orig;
}
%end

%hook YTMQueueUpdateCommand
- (NSString *)videoIDOfQueueItem:(id)queueItem userContentMode:(NSInteger)contentMode {
    if ([queueItem hasATVOMVPair]) {
        LogATV(@"videoIDOfQueueItem:userContentMode: forced ATV");
        return %orig(queueItem, 0);
    }
    return %orig;
}
%end

%hook YTQueueController
- (BOOL)initialUserContentModeATVPreferred {
    LogATV(@"initialUserContentModeATVPreferred called");
    return YES;
}
%end