#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface YTBrowseServiceImpl : NSObject
- (void)makeRequest:(id)request refresh:(BOOL)refresh responseBlock:(id)responseBlock errorBlock:(id)errorBlock;
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

// DIAGNOSTIC BUILD: discover the real browseId/playlistId that iOS sends when
// opening an album, via defensive KVC on the browse request and its
// navigationEndpoint. Goal: confirm whether the request carries MPREb or OLAK,
// to design the browseId swap (Fase 2).

%hook YTBrowseServiceImpl
- (void)makeRequest:(id)request refresh:(BOOL)refresh responseBlock:(id)responseBlock errorBlock:(id)errorBlock {
    @try {
        LogATV([NSString stringWithFormat:@"[browseReq] class=%@", NSStringFromClass([request class])]);
        id nav = [request valueForKey:@"navigationEndpoint"];
        if (nav) {
            LogATV([NSString stringWithFormat:@"  navEndpoint=%@", NSStringFromClass([nav class])]);
            for (NSString *k in @[@"browseId", @"browseEndpointId", @"playlistId", @"watchPlaylistId", @"browseEndpoint", @"watchEndpoint"]) {
                @try {
                    id v = [nav valueForKey:k];
                    if (v) LogATV([NSString stringWithFormat:@"  nav[%@]=%@", k, v]);
                } @catch (...) {}
            }
        }
        for (NSString *k in @[@"browseId", @"playlistId", @"watchPlaylistId"]) {
            @try {
                id v = [request valueForKey:k];
                if (v) LogATV([NSString stringWithFormat:@"  req[%@]=%@", k, v]);
            } @catch (...) {}
        }
    } @catch (NSException *e) {
        LogATV([NSString stringWithFormat:@"[browseReq] exc: %@", e.reason]);
    }
    return %orig(request, refresh, responseBlock, errorBlock);
}
%end