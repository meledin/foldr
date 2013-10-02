//
//  StatusMenu.m
//  Synckr
//
//  Created by Vladimir Katardjiev on 2013-09-29.
//  Copyright (c) 2013 d2dx. All rights reserved.
//

#import "StatusMenu.h"
#import "AppDelegate.h"
#import "FolderScanner.h"
#import "Uploader.h"
#import "Synckr.h"

@implementation StatusMenu
{
    NSStatusItem *mStatus;
    AppDelegate *del;
    FolderScanner *down;
    Uploader *up;
    int count;
}

- (id) init
{
    self = [super init];
    if (self)
    {
        mStatus = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
        del = [AppDelegate instance];
        up = [Uploader instance];
        down = [FolderScanner instance];
        count = 0;
        [mStatus setMenu:del.statusMenu];
        [mStatus setImage:[NSImage imageNamed:@"menuicon.png"]];
        [mStatus setAlternateImage:[NSImage imageNamed:@"menuicon.png"]];
        [mStatus setHighlightMode:YES];
        del.statusMenuLogout.title = [NSString stringWithFormat:@"Log out %@...", [[Synckr instance] username]];
        [self refreshTask];
    }
    return self;
}

- (void) refreshTask
{
    [self refresh];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:
                                [self methodSignatureForSelector:@selector(refresh)]];
    [invocation setTarget:self];
    [invocation setSelector:@selector(refresh)];
    [[NSRunLoop mainRunLoop] addTimer:[NSTimer timerWithTimeInterval:0.4 invocation:invocation repeats:YES] forMode:NSRunLoopCommonModes];

}

- (void) refresh
{
    del.statusMenuDownloads.title = [self createTitle: @"Download" forCount: [down numTasks]];
    del.statusMenuUploads.title = [self createTitle: @"Upload" forCount: [up numTasks]];
    del.statusMenuTasks.title = [self createTitle: @"Task" forCount: [del numTasks]];
}

- (NSString*) createTitle: (NSString*)title forCount: (NSUInteger) tc
{
    if (tc <= 0)
        return [NSString stringWithFormat:@"No %@s", title];
    else if (tc == 1)
        return [NSString stringWithFormat:@"%ld %@", tc, title];
    else
        return [NSString stringWithFormat:@"%ld %@s", tc, title];
}

@end
