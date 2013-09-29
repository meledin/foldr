//
//  AppDelegate.m
//  Foldr
//
//  Created by Vladimir Katardjiev on 2013-09-28.
//  Copyright (c) 2013 d2dx. All rights reserved.
//

#import "AppDelegate.h"
#import "FolderScanner.h"
#import "FoldrCommand.h"
#import "Foldr.h"
#import "Uploader.h"

#define API_KEY @"eac9c2f5dec0750e66e03494ef5b425a"
#define API_SHARED_SECRET @"a5e43bcba7cf4499"


static NSString *kCallbackURLBaseString = @"flickrfoldr://callback";
static NSString *kOAuthAuth = @"OAuth";
static NSString *kFrobRequest = @"Frob";
static NSString *kTryObtainAuthToken = @"TryAuth";
static NSString *kTestLogin = @"TestLogin";
static NSString *kUpgradeToken = @"UpgradeToken";

const NSTimeInterval kTryObtainAuthTokenInterval = 3.0;

@implementation AppDelegate
{
    NSMutableArray *commandQueue;
    bool sending;
    FoldrCommand *currentCommand;
}

AppDelegate *mInstance = nil;

+ (AppDelegate*) instance
{
    return mInstance;
}

- (id) init
{
    self = [super init];
    
    if (self)
    {
        sending = false;
        commandQueue = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (NSUInteger) numTasks
{
    @synchronized(commandQueue)
    {
        NSUInteger count = [commandQueue count];
        if (sending)
            count++;
        return count;
    }
}

- (IBAction)resetToken:(id)sender {
    _flickrContext.OAuthToken = @"";
    _flickrContext.OAuthTokenSecret = @"";
    
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    [def setValue:@"" forKey:@"access_token"];
    [def setValue:@"" forKey:@"access_secret"];
}

- (void) queueCommand: (FoldrCommand *) command
{
    
    if (command.op == kFoldrCommandPOST)
    {
        // Better thread this on a separate thread because. That's why.
        [[Uploader instance] enqueue:command];
        return;
    }
    
    @synchronized(commandQueue)
    {
        [commandQueue addObject:command];
    }
    
    [self flushCommands];
}

- (void) flushCommands
{
    @synchronized(commandQueue)
    {
        if (sending)
            return;
        
        if ([commandQueue count] == 0)
            return;
        
        sending = true;
        
        currentCommand = [commandQueue objectAtIndex:0];
        [commandQueue removeObjectAtIndex:0];
        
        _flickrRequest.sessionInfo = NULL;
        
        
    }
    currentCommand.execute(_flickrRequest);
        
}

- (void)handleIncomingURL:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
    
    NSURL *callbackURL = [NSURL URLWithString:[[event paramDescriptorForKeyword:keyDirectObject] stringValue]];
    NSLog(@"Callback URL: %@", [callbackURL absoluteString]);
    
    NSString *requestToken= nil;
    NSString *verifier = nil;
    
    BOOL result = OFExtractOAuthCallback(callbackURL, [NSURL URLWithString:kCallbackURLBaseString], &requestToken, &verifier);
    if (!result) {
        NSLog(@"Invalid callback URL");
    }
    
    [_flickrRequest fetchOAuthAccessTokenWithRequestToken:requestToken verifier:verifier];
}



- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    
    mInstance = self;
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
                                                             [@"~/Pictures/Foldr" stringByExpandingTildeInPath], @"foldrLocation",
                                                             @"5", @"foldrRefresh",
                                                             @"0", @"foldrSizeIdx",
                                                             nil]];
    
	[[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(handleIncomingURL:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
    
    
    _flickrContext = [[OFFlickrAPIContext alloc] initWithAPIKey:API_KEY sharedSecret:API_SHARED_SECRET];
    
    _flickrRequest = [[OFFlickrAPIRequest alloc] initWithAPIContext:_flickrContext];
    _flickrRequest.delegate = self;
    _flickrRequest.requestTimeoutInterval = 60.0;
    
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    
    _flickrContext.OAuthToken = [def stringForKey:@"access_token"];
    _flickrContext.OAuthTokenSecret = [def stringForKey:@"access_secret"];
    
    [[Uploader instance] setCtx:_flickrContext];
    
    [[Foldr instance] testLogin];
    
    //[self oauthAuthenticationAction];
}

- (void)oauthAuthenticationAction
{
    //[_progressIndicator startAnimation:self];
    //[_progressLabel setStringValue:@"Starting OAuth authentication..."];
    
    [self.loggingInBox setHidden:YES];
    [self.prefsBox setHidden:NO];
    [self.continueButton setEnabled:YES];
    [self.window makeKeyAndOrderFront:self];
    
    //[_oldStyleAuthButton setEnabled:NO];
    //[_oauthAuthButton setEnabled:NO];
}

- (void)testLoginAction
{
    if (_flickrContext.OAuthToken || _flickrContext.authToken) {
        _flickrRequest.sessionInfo = kTestLogin;
        [_flickrRequest callAPIMethodWithGET:@"flickr.test.login" arguments:nil];
        //[_progressLabel setStringValue:@"Calling flickr.test.login..."];
        
        
        // this tests flickr.photos.getInfo
        /*
         NSString *somePhotoID = @"42";
         [_flickrRequest callAPIMethodWithGET:@"flickr.photos.getInfo" arguments:[NSDictionary dictionaryWithObjectsAndKeys:somePhotoID, @"photo_id", nil]];
         [_progressLabel setStringValue:@"Calling flickr.photos.getInfo..."];
         
         */
        
        
        // this tests flickr.photos.setMeta, a method that requires POST
        /*
         NSString *somePhotoID = @"42";
         NSString *someTitle = @"Lorem iprum!";
         NSString *someDesc = @"^^ :)";
         NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
         somePhotoID, @"photo_id",
         someTitle, @"title",
         someDesc, @"description",
         nil];
         [_flickrRequest callAPIMethodWithPOST:@"flickr.photos.setMeta" arguments:params];
         [_progressLabel setStringValue:@"Calling flickr.photos.setMeta..."];
         
         */
        
        
        // test photo uploading
        /*
         NSString *somePath = @"/tmp/test.png";
         NSString *someFilename = @"Foo.png";
         NSString *someTitle = @"Lorem iprum!";
         NSString *someDesc = @"^^ :)";
         NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
         someTitle, @"title",
         someDesc, @"description",
         nil];
         [_flickrRequest uploadImageStream:[NSInputStream inputStreamWithFileAtPath:somePath] suggestedFilename:someFilename MIMEType:@"image/png" arguments:params];
         [_progressLabel setStringValue:@"Uploading photos..."];
         */
        
    }
    else {
        NSRunAlertPanel(@"No Auth Token", @"Please authenticate first", @"Dismiss", nil, nil);
    }
}

- (void)tryObtainAuthToken
{
    _flickrRequest.sessionInfo = kTryObtainAuthToken;
    [_flickrRequest callAPIMethodWithGET:@"flickr.auth.getToken" arguments:[NSDictionary dictionaryWithObjectsAndKeys:_frob, @"frob", nil]];
}


- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didObtainOAuthRequestToken:(NSString *)inRequestToken secret:(NSString *)inSecret;
{
    _flickrContext.OAuthToken = inRequestToken;
    _flickrContext.OAuthTokenSecret = inSecret;
    
    NSURL *authURL = [_flickrContext userAuthorizationURLWithRequestToken:inRequestToken requestedPermission:OFFlickrWritePermission];
    NSLog(@"Auth URL: %@", [authURL absoluteString]);
    [[NSWorkspace sharedWorkspace] openURL:authURL];
    
    //[_progressLabel setStringValue:@"Waiting fo user authentication (OAuth)..."];
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didObtainOAuthAccessToken:(NSString *)inAccessToken secret:(NSString *)inSecret userFullName:(NSString *)inFullName userName:(NSString *)inUserName userNSID:(NSString *)inNSID
{
    _flickrContext.OAuthToken = inAccessToken;
    _flickrContext.OAuthTokenSecret = inSecret;
    
    NSLog(@"Token: %@, secret: %@", inAccessToken, inSecret);
    
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    [def setValue:inAccessToken forKey:@"access_token"];
    [def setValue:inSecret forKey:@"access_secret"];
    
    [self.loggingInBox setHidden:YES];
    [self.prefsBox setHidden:NO];
    [self.continueButton setEnabled:YES];
    [self.window orderOut:self];
    [self.spinnyBar stopAnimation:self];
    
    [[Foldr instance] testLogin];
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didCompleteWithResponse:(NSDictionary *)inResponseDictionary
{
    NSLog(@"%s, return: %@", __PRETTY_FUNCTION__, inResponseDictionary);
    
    //[_progressIndicator stopAnimation:self];
    //[_progressLabel setStringValue:@"API call succeeded"];
    
    if (inRequest.sessionInfo == kFrobRequest) {
        _frob = [[inResponseDictionary valueForKeyPath:@"frob._text"] copy];
        NSLog(@"%@: %@", kFrobRequest, _frob);
        
        NSURL *authURL = [_flickrContext loginURLFromFrobDictionary:inResponseDictionary requestedPermission:OFFlickrWritePermission];
        [[NSWorkspace sharedWorkspace] openURL:authURL];
        
        [self performSelector:@selector(tryObtainAuthToken) withObject:nil afterDelay:kTryObtainAuthTokenInterval];
        
    }
    else if (inRequest.sessionInfo == kTryObtainAuthToken) {
        NSString *authToken = [inResponseDictionary valueForKeyPath:@"auth.token._text"];
        NSLog(@"%@: %@", kTryObtainAuthToken, authToken);
        
        _flickrContext.authToken = authToken;
        _flickrRequest.sessionInfo = nil;
    }
    else if (inRequest.sessionInfo == kUpgradeToken) {
        NSString *oat = [inResponseDictionary valueForKeyPath:@"auth.access_token.oauth_token"];
        NSString *oats = [inResponseDictionary valueForKeyPath:@"auth.access_token.oauth_token_secret"];
        
        _flickrContext.authToken = nil;
        _flickrContext.OAuthToken = oat;
        _flickrContext.OAuthTokenSecret = oats;
    }
    else if (inRequest.sessionInfo == kTestLogin) {
        _flickrRequest.sessionInfo = nil;
        NSRunAlertPanel(@"Test OK!", @"API returns successfully", @"Dismiss", nil, nil);
    }
    else
    {
        // Unmatched session info should be one of our toys...
        currentCommand.onSuccess(inResponseDictionary);
        
        if (inRequest == _flickrRequest)
            sending = false;
        [self flushCommands];
    }
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didFailWithError:(NSError *)inError
{
    NSLog(@"%s, error: %@", __PRETTY_FUNCTION__, inError);
    
    if (inRequest.sessionInfo == kTryObtainAuthToken) {
        [self performSelector:@selector(tryObtainAuthToken) withObject:nil afterDelay:kTryObtainAuthTokenInterval];
    }
    else {
        if (currentCommand.onError)
        {
            currentCommand.onError(inError);
            
            if (inRequest == _flickrRequest)
                sending = false;
            [self flushCommands];
            return;
        }
        NSRunAlertPanel(@"API Error", [NSString stringWithFormat:@"An error occurred in the stage \"%@\", error: %@", inRequest.sessionInfo, inError], @"Dismiss", nil, nil);
        
        if (inRequest == _flickrRequest)
            sending = false;
        [self flushCommands];
    }
}


- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest imageUploadSentBytes:(NSUInteger)inSentBytes totalBytes:(NSUInteger)inTotalBytes
{
    NSLog(@"%s %lu/%lu", __PRETTY_FUNCTION__, inSentBytes, inTotalBytes);
}

- (IBAction)performLogin:(id)sender {
    _flickrRequest.sessionInfo = kOAuthAuth;
    [_flickrRequest fetchOAuthRequestTokenWithCallbackURL:[NSURL URLWithString:kCallbackURLBaseString]];
    [self.loggingInBox setHidden:NO];
    [self.prefsBox setHidden:YES];
    [self.spinnyBar startAnimation:self];
    [self.continueButton setEnabled:NO];
}

- (void) notifyLoggedIn
{
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    [notification setTitle:@"Foldr Login Success!"];
    [notification setInformativeText:@"You are now logged in to Foldr. It has hidden itself for your convenience. Enjoy!"];
    
    [self performSelector:@selector(removeNotification:) withObject:notification afterDelay:10];
    
    NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
    [center setDelegate:self];
    [center deliverNotification:notification];
}

- (IBAction)showPreferences:(id)sender {
}

- (void) removeNotification: (NSUserNotification *)notification
{
    NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
    [center removeDeliveredNotification:notification];
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}

@end
