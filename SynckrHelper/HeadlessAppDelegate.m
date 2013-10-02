//
//  AppDelegate.m
//  SynckrHelper
//
//  Created by Vladimir Katardjiev on 9/30/13.
//  Copyright (c) 2013 d2dx. All rights reserved.
//

#import "HeadlessAppDelegate.h"

@implementation HeadlessAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    [super applicationDidFinishLaunching:aNotification];
    
    [[NSUserDefaults standardUserDefaults] addSuiteNamed:@"com.apple.ServicesMenu.Services"];
    
    NSDictionary *test = [[NSUserDefaults standardUserDefaults] valueForKey:@"NSServices"];
    
    NSDictionary *d = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.d2dx.Synckr"];
    
    NSArray *a = [[NSUserDefaults standardUserDefaults] persistentDomainNames];
}



- (void)oauthAuthenticationAction
{
    [[NSApplication sharedApplication] terminate:self];
}

@end
