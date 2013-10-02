//
//  AppDelegate.h
//  Synckr
//
//  Created by Vladimir Katardjiev on 2013-09-28.
//  Copyright (c) 2013 d2dx. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ObjectiveFlickr/ObjectiveFlickr.h>

@class SynckrCommand;

@interface AppDelegate : NSObject <NSApplicationDelegate, OFFlickrAPIRequestDelegate, NSUserNotificationCenterDelegate>
{
    OFFlickrAPIContext *_flickrContext;
    OFFlickrAPIRequest *_flickrRequest;
    
    NSString *_frob;
}

+ (AppDelegate*)instance;
- (void) queueCommand: (SynckrCommand *) command;
- (void)oauthAuthenticationAction;
- (void) notifyLoggedIn;
- (IBAction)showPreferences:(id)sender;

- (IBAction)performLogin:(id)sender;
- (NSUInteger) numTasks;
- (IBAction)resetToken:(id)sender;
- (IBAction)changeSynckrFolder:(id)sender;

@property (assign) IBOutlet NSWindow *welcomeWindow;
@property (assign) IBOutlet NSWindow *window;
@property (strong) IBOutlet NSMenu *statusMenu;
@property (weak) IBOutlet NSTextField *locationField;

@property (weak) IBOutlet NSBox *loggingInBox;
@property (weak) IBOutlet NSBox *prefsBox;
@property (weak) IBOutlet NSButton *continueButton;
@property (weak) IBOutlet NSProgressIndicator *spinnyBar;

@property (weak) IBOutlet NSMenuItem *statusMenuDownloads;
@property (weak) IBOutlet NSMenuItem *statusMenuUploads;
@property (weak) IBOutlet NSMenuItem *statusMenuTasks;
@property (weak) IBOutlet NSMenuItem *statusMenuLogout;


@end
