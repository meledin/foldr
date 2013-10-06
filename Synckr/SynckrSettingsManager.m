//
//  SynckrSettingsManager.m
//  Synckr
//
//  Created by Vladimir Katardjiev on 10/5/13.
//  Copyright (c) 2013 d2dx. All rights reserved.
//

#import "SynckrSettingsManager.h"
#import "Synckr.h"
#import "AppDelegate.h"

@interface SynckrSettingsManager()
{
    
}

@end

SynckrSettingsManager *ssmInstance = nil;
NSConnection *ssmConnection = nil;

@implementation SynckrSettingsManager
{
}

+ (void) startServer
{
    if (ssmConnection != nil)
        return;
    
    NSPort *port = [NSPort port];
    ssmConnection = [[NSConnection alloc] initWithReceivePort:port sendPort:nil];
    [[NSPortNameServer systemDefaultPortNameServer] registerPort:port name:@"SynckrSettingsManager"];
    
    ssmInstance = [[SynckrSettingsManager alloc] init];
    
    [ssmConnection setRootObject: ssmInstance];
}

+ (SynckrSettingsManager*) sharedManager
{
    if (ssmInstance == nil)
    {
        NSPort *port = [[NSPortNameServer systemDefaultPortNameServer] portForName:@"SynckrSettingsManager"];
        ssmConnection = [[NSConnection alloc] initWithReceivePort:nil sendPort:port];
        NSDistantObject *obj = [ssmConnection rootProxy];
        ssmInstance = (SynckrSettingsManager*)obj;
    }
    
    return ssmInstance;
}

- (void) agentDidLogout
{
    NSLog(@"Parent received agentDidLogout");
    [[AppDelegate instance] applicationDidFinishLaunching:nil];
}

@end
