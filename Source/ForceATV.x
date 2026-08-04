#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface YTMAVSwitch : UIView
- (void)setUserContentMode:(NSInteger)contentMode;
- (void)setUserContentMode:(NSInteger)contentMode animated:(BOOL)animated;
- (NSInteger)userContentMode;
@property (nonatomic, retain) NSString *audioLabel;
@property (nonatomic, retain) NSString *videoLabel;
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

// Force ATV (Art Track) over OMV/Visualizer.
// Content mode: 0 = OMV, 1 = ATV.
// Hook YTMAVSwitch to always use ATV (content mode 1).

%hook YTMAVSwitch
- (void)setUserContentMode:(NSInteger)contentMode {
    if (contentMode != 1) {
        LogATV([NSString stringWithFormat:@"YTMAVSwitch setUserContentMode:%ld -> forcing ATV (1)", (long)contentMode]);
        %orig(1);
        return;
    }
    %orig(contentMode);
}

- (void)setUserContentMode:(NSInteger)contentMode animated:(BOOL)animated {
    if (contentMode != 1) {
        LogATV([NSString stringWithFormat:@"YTMAVSwitch setUserContentMode:%ld animated:%d -> forcing ATV (1)", (long)contentMode, animated]);
        %orig(1, animated);
        return;
    }
    %orig(contentMode, animated);
}
%end