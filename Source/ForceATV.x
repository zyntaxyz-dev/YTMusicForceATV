#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface YTClientEndpointBuilderDataModel : NSObject
- (id)browseId;
- (id)browseEndpointParams;
@end

@interface YTBrowseServiceImpl : NSObject
- (void)makeRequest:(id)request refresh:(BOOL)refresh responseBlock:(id)responseBlock errorBlock:(id)errorBlock;
@end

@interface YTMAlbumViewModel : NSObject
- (id)initWithPlaylistID:(id)playlistID;
@end

@interface YTMQueueServiceController : NSObject
- (void)fetchQueueItemsForPlaylistID:(id)playlistID atInsertPosition:(id)insertPosition clickTrackingParams:(id)clickTrackingParams completion:(id)completion;
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

// DIAGNOSTIC BUILD (album-level): determine which browseId/params the iOS app
// actually sends when opening an album, and which playlistID drives the queue.

%hook YTClientEndpointBuilderDataModel
- (id)browseId {
    id v = %orig;
    if ([v isKindOfClass:[NSString class]] && [(NSString *)v length] > 3) {
        LogATV([NSString stringWithFormat:@"[endpoint] browseId=%@", v]);
    }
    return v;
}

- (id)browseEndpointParams {
    id v = %orig;
    LogATV([NSString stringWithFormat:@"[endpoint] browseEndpointParams=%@", v ?: @"(nil)"]);
    return v;
}
%end

%hook YTBrowseServiceImpl
- (void)makeRequest:(id)request refresh:(BOOL)refresh responseBlock:(id)responseBlock errorBlock:(id)errorBlock {
    NSString *reqClass = NSStringFromClass([request class]);
    NSString *browseId = @"(n/a)";
    if ([request respondsToSelector:@selector(browseId)]) {
        id b = [request browseId];
        browseId = [b isKindOfClass:[NSString class]] ? b : @"(obj)";
    }
    LogATV([NSString stringWithFormat:@"[browseReq] class=%@ browseId=%@", reqClass, browseId]);
    return %orig(request, refresh, responseBlock, errorBlock);
}
%end

%hook YTMAlbumViewModel
- (id)initWithPlaylistID:(id)playlistID {
    LogATV([NSString stringWithFormat:@"[albumVM] initWithPlaylistID=%@", playlistID ?: @"(nil)"]);
    return %orig(playlistID);
}
%end

%hook YTMQueueServiceController
- (void)fetchQueueItemsForPlaylistID:(id)playlistID atInsertPosition:(id)insertPosition clickTrackingParams:(id)clickTrackingParams completion:(id)completion {
    LogATV([NSString stringWithFormat:@"[queue] fetchQueueItemsForPlaylistID=%@", playlistID ?: @"(nil)"]);
    return %orig(playlistID, insertPosition, clickTrackingParams, completion);
}
%end