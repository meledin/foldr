//
//  AppDelegate.h
//  Foldr
//
//  Created by Vladimir Katardjiev on 2013-09-28.
//  Copyright (c) 2013 d2dx. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ObjectiveFlickr/ObjectiveFlickr.h>

@class FoldrCommand;

@interface AppDelegate : NSObject <NSApplicationDelegate, OFFlickrAPIRequestDelegate>
{
    OFFlickrAPIContext *_flickrContext;
    OFFlickrAPIRequest *_flickrRequest;
    
    NSString *_frob;
}

+ (AppDelegate*)instance;
- (void) queueCommand: (FoldrCommand *) command;
- (void)oauthAuthenticationAction;

@property (assign) IBOutlet NSWindow *window;

@end
