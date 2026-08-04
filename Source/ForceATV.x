#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

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

// Diagnostic hooks: find the actual videoId selection path.

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
%end

%hook YTQueueItem
- (id)rendererForContentMode:(NSInteger)contentMode {
    LogATV([NSString stringWithFormat:@"rendererForContentMode: %ld, hasATVOMVPair=%@", (long)contentMode, self.hasATVOMVPair ? @"YES" : @"NO"]);
    return %orig;
}
%end