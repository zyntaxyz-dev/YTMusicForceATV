#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface YTIBrowseRequest : NSObject
- (id)ytm_navigationEndpoint;
- (void)ytm_setNavigationEndpoint:(id)endpoint;
@end

@interface YTMutableClientEndpointBuilderDataModel : NSObject
- (void)setBrowseId:(id)browseId;
- (void)setBrowseEndpointParams:(id)params;
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

// DIAGNOSTIC BUILD: confirm where the album browseId lives and what value
// (MPREb vs OLAK) iOS sends, using real selectors (no invented KVC keys).

%hook YTIBrowseRequest
- (id)ytm_navigationEndpoint {
    id e = %orig;
    @try {
        LogATV([NSString stringWithFormat:@"[nav] endpoint=%@", NSStringFromClass([e class])]);
        @try {
            id b = [e valueForKey:@"browseId"];
            if (b) LogATV([NSString stringWithFormat:@"  endpoint.browseId=%@", b]);
        } @catch (NSException *x) {
            LogATV([NSString stringWithFormat:@"  endpoint.browseId exc: %@", x.name]);
        }
    } @catch (NSException *x) {
        LogATV([NSString stringWithFormat:@"[nav] exc: %@", x.name]);
    }
    return e;
}

- (void)ytm_setNavigationEndpoint:(id)endpoint {
    @try {
        LogATV([NSString stringWithFormat:@"[setNav] endpoint=%@", NSStringFromClass([endpoint class])]);
        @try {
            id b = [endpoint valueForKey:@"browseId"];
            if (b) LogATV([NSString stringWithFormat:@"  setNav.browseId=%@", b]);
        } @catch (NSException *x) {
            LogATV([NSString stringWithFormat:@"  setNav.browseId exc: %@", x.name]);
        }
    } @catch (NSException *x) {
        LogATV([NSString stringWithFormat:@"[setNav] exc: %@", x.name]);
    }
    return %orig(endpoint);
}
%end

%hook YTMutableClientEndpointBuilderDataModel
- (void)setBrowseId:(id)browseId {
    LogATV([NSString stringWithFormat:@"[setBrowseId] %@", browseId ?: @"(nil)"]);
    return %orig(browseId);
}
%end