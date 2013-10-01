//
//  Foldr.m
//  Foldr
//
//  Created by Vladimir Katardjiev on 2013-09-28.
//  Copyright (c) 2013 d2dx. All rights reserved.
//

#import "Foldr.h"
#import "AppDelegate.h"
#import "FoldrCommand.h"
#import "FolderScanner.h"
#import <ObjectiveFlickr/ObjectiveFlickr.h>
#import "SerialDict.h"
#import "StatusMenu.h"

Foldr *instance = nil;

@implementation Foldr
{
    NSDictionary *user;
    AppDelegate *delegate;
    FolderScanner *scanner;
    StatusMenu *status;
}

+ (Foldr*) instance
{
    if (!instance)
    {
        instance = [[Foldr alloc] init];
    }
    return instance;
}

- (id) init
{
    self = [super init];
    
    if (self)
    { 
        delegate = [AppDelegate instance];
    }
    
    return self;
}

- (void) testLogin
{
    FoldrCommand *cmd = [FoldrCommand get: @"flickr.test.login"];
    cmd.onSuccess = ^(NSDictionary *resp)
    {
        
        scanner = [[FolderScanner alloc] init];
        status = [[StatusMenu alloc] init];
        
        NSLog(@"Got response: %@", [resp description]);
        user = [resp valueForKeyPath:@"user"];
        NSLog(@"Got Username: %@", [user valueForKeyPath:@"username._text"]);
        
        [delegate notifyLoggedIn];
        
        NSString *dest = [NSString stringWithFormat:@"%@", [user valueForKeyPath:@"username._text"]];
        [scanner ensureDirExists:dest];
        
        NSString *dirPath = [scanner absolutePath:dest];
        
        NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
        
        [d setValue:[user valueForKeyPath:@"id"] forKey:@"user_id"];
        [d setValue:@"flickr.photos.search" forKey:@"query"];
        
        [SerialDict serialise:d into:[dirPath stringByAppendingPathComponent:@".query"]];
        
        [self rescanTask];
        
        //[self downloadPhotosForUserId:[user valueForKeyPath:@"id"] withAttributes:nil intoFolder:dest];
    };
    cmd.onError = ^(NSError *err)
    {
        if (err.code == 99 || err.code == 2147418115)
            [delegate oauthAuthenticationAction];
    };
    
    [delegate queueCommand: cmd];
}

//- (void) downloadPhotosForUserId: (NSString*)flickrUserId withAttributes:(NSDictionary *)inAttrs intoFolder: (NSString*)destination
- (void) performFlickrPhotosSearchWithAttributes: (NSDictionary *)inAttrs intoFolder:(NSString*)relativePath
{
    NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithDictionary:inAttrs];
    [attrs setValue:@"url_k,url_l,date_upload,date_taken" forKey:@"extras"];
    [attrs setValue:@"30" forKey:@"per_page"];
    
    FoldrCommand *cmd = [FoldrCommand get:@"flickr.photos.search"];
    cmd.arguments = attrs;
    cmd.onSuccess = ^(NSDictionary *resp)
    {
        //NSLog(@"Got response: %@", [resp description]);
        
        NSArray *photos = [resp valueForKeyPath:@"photos.photo"];
        NSLog(@"%@", [photos description]);
        
        for (int i=0; i<photos.count; i++)
        {
            NSDictionary *photo = photos[i];
            File *f = [[File alloc] init];
            f.flickrPhotoId = [photo valueForKeyPath:@"id"];
            f.flickrPhotoFarm = [photo valueForKeyPath:@"farm"];
            f.flickrPhotoSecret = [photo valueForKeyPath:@"secret"];
            f.flickrPhotoServer = [photo valueForKeyPath:@"server"];
            f.flickrPhotoTitle = [photo valueForKeyPath:@"title"];
            f.flickrUrl2048 = [photo valueForKeyPath:@"url_k"];
            f.flickrUrl1024 = [photo valueForKeyPath:@"url_l"];
            
            if (!f.flickrPhotoTitle || f.flickrPhotoTitle.length == 0)
                f.flickrPhotoTitle = f.flickrPhotoId;
            
            f.name = [NSString stringWithFormat:@"%@.jpg", f.flickrPhotoTitle];
            
            f.relativePath = [NSString stringWithFormat:@"%@/%@", relativePath, f.name];
            
            NSString *dateUploadedStr = [photo valueForKeyPath:@"dateupload"];
            
            if (dateUploadedStr && dateUploadedStr.length > 0)
            {
                NSInteger uploaded = [dateUploadedStr integerValue];
                f.modificationDate = [NSDate dateWithTimeIntervalSince1970:uploaded];
            }
            
            NSString *dateTakenStr = [photo valueForKeyPath:@"datetaken"];
            
            if (dateTakenStr && dateTakenStr.length > 0)
            {
                f.creationDate = [NSDate dateWithNaturalLanguageString:dateTakenStr];
            }
            
            if (!f.creationDate)
                f.creationDate = f.modificationDate;
            
            [scanner download:f];
        }
    };
    [delegate queueCommand:cmd];
}
- (void) itemCreated: (File*)item atPath: (NSString *)relativePath
{
    if (item.type == NSFileTypeRegular)
    {
        // We have a file. Probably an image. Should verify.
        // Screw that, this is a hack!
        
        NSString *imageType = nil;
        if ([[item.path lowercaseString] hasSuffix:@"png"])
            imageType = @"image/png";
        else if ([[item.path lowercaseString] hasSuffix:@"jpg"])
            imageType = @"image/jpg";
        else if ([[item.path lowercaseString] hasSuffix:@"gif"])
            imageType = @"image/gif";
        else if ([[item.path lowercaseString] hasSuffix:@"webloc"])
        {
            [self createFolderForItem: item];
            return;
        }
        
        // Only start the procedure if we recognise the file type.
        if (imageType != nil)
        {
            
            if (![item.relativePath hasPrefix: [user valueForKeyPath:@"username._text"]])
                return;
            
            NSString *title = [item.name stringByDeletingPathExtension];
            NSString *desc = @"";
            
            NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                    title, @"title",
                                    desc, @"description",
                                    @"0", @"is_public",
                                    @"0", @"is_friend",
                                    @"0", @"is_family",
                                    nil];
            
            NSLog(@"Preparing to upload: %@", item.path);
            
            FoldrCommand *cmd = [FoldrCommand post:nil];
            __weak FoldrCommand *embedded = cmd;
            cmd.execute = ^(OFFlickrAPIRequest *req) {
                NSInputStream *stream = [NSInputStream inputStreamWithFileAtPath:item.path];
                [req uploadImageStream:stream suggestedFilename:item.name MIMEType:imageType arguments:params];
            };
            cmd.onSuccess = ^(NSDictionary *resp) {
                item.flickrPhotoId = [resp valueForKeyPath:@"photoid._text"];
            };
            cmd.onError = ^(NSError *err) {
                if (err.code == 2147418114 || err.code == 4)
                    [delegate performSelector:@selector(queueCommand:) withObject:embedded afterDelay:2.0];
            };
            
            [delegate queueCommand:cmd];
    
        }
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
    else if (item.type == NSFileTypeDirectory)
    {
        // This is a folder.
        NSArray *parts = [relativePath pathComponents];
        
        if (parts.count == 1)
        {
            
            // Download data on new user!
            NSString *remoteUserName = parts[0];
            
            FoldrCommand *cmd = [FoldrCommand get:@"flickr.people.findByUsername"];
            cmd.arguments = [NSDictionary dictionaryWithObjectsAndKeys:remoteUserName, @"username", nil];
            cmd.onSuccess = ^(NSDictionary *resp)
            {                
                NSString *dest = [NSString stringWithFormat:@"%@", remoteUserName];
                [scanner ensureDirExists:dest];
                NSLog(@"%@", [resp description]);
                
                NSString *dirPath = [scanner absolutePath:dest];
                
                NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
                
                [d setValue:[resp valueForKeyPath:@"user.nsid"] forKey:@"user_id"];
                [d setValue:@"flickr.photos.search" forKey:@"query"];
                
                [SerialDict serialise:d into:[dirPath stringByAppendingPathComponent:@".query"]];
                
                [self rescan];
                
                //[self downloadPhotosForUserId:[resp valueForKeyPath:@"user.nsid"] withAttributes:nil intoFolder:dest];
            };
            cmd.onError= ^(NSError *err)
            {
                // Ignore the error
            };
            
            
            [delegate queueCommand:cmd];
            
        }
    }
}

// Dropped a webloc. Read and convert plx.
- (void) createFolderForItem: (File*)item
{
    NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:item.path];
    NSString *url = [d valueForKey:@"URL"];
    NSLog(@"%@", url);
    [[NSFileManager defaultManager] removeItemAtPath:item.path error:nil];
    
    NSURLRequest *req = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    NSLog(@"Queueing request for: %@", url);
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse *resp, NSData *data, NSError *err) {
        NSLog(@"Request completed");
        
        NSString *responseData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSError *error = NULL;
        //NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"groups_discuss\\.gne\\?id=([0-9]+@N[0-9+])&amp;"
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"([0-9]+@N[0-9]+)"
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:&error];
        
        NSRange rangeOfFirstMatch = [regex rangeOfFirstMatchInString:responseData options:0 range:NSMakeRange(0, [responseData length])];
        if (!NSEqualRanges(rangeOfFirstMatch, NSMakeRange(NSNotFound, 0))) {
            NSString *groupId = [responseData substringWithRange:rangeOfFirstMatch];
            
            
            FoldrCommand *cmd = [FoldrCommand get:@"flickr.groups.getInfo"];
            cmd.arguments = [NSDictionary dictionaryWithObjectsAndKeys:groupId, @"group_id", nil];
            cmd.onSuccess = ^(NSDictionary *resp)
            {
                NSString *groupName = [resp valueForKeyPath:@"group.name._text"];
                NSString *dest = [NSString stringWithFormat:@"%@", groupName];
                [scanner ensureDirExists:dest];
                
                NSString *dirPath = [scanner absolutePath:dest];
                
                NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
                
                [d setValue:groupId forKey:@"group_id"];
                [d setValue:@"flickr.photos.search" forKey:@"query"];
                
                [SerialDict serialise:d into:[dirPath stringByAppendingPathComponent:@".query"]];
                [self rescan];
            };
            cmd.onError= ^(NSError *err)
            {
                // Ignore the error
            };
            
            
            [delegate queueCommand:cmd];
            
        }
        
    }];

}

- (void) rescan
{
    NSDictionary *d = [scanner indexedDirAtSubPath:@""];
    NSArray *dirNames = [d allKeys];
    
    NSDate *now = [[NSDate alloc] init];
    
    for (int i=0; i<dirNames.count; i++)
    {
        NSString *dir = dirNames[i];
        NSMutableDictionary *props = [SerialDict deserialize:[scanner absolutePath:[dir stringByAppendingPathComponent:@".props"]]];
        NSDate *nextScan = [NSDate dateWithString:[props valueForKey:@"nextScan"]];
        
        if ([nextScan isGreaterThan:now])
        {
            NSLog(@"Directory %@ does not need rescanning. Next due at %@", dir, nextScan);
            continue;
        }
        // Rescan the directory.
        nextScan = [now dateByAddingTimeInterval:60*60];
        [props setValue:nextScan forKey:@"nextScan"];
        
        NSMutableDictionary *query = [SerialDict deserialize:[scanner absolutePath:[dir stringByAppendingPathComponent:@".query"]]];
        NSString *q = [query valueForKey:@"query"];
        [query removeObjectForKey:@"query"];
        
        if ([@"flickr.photos.search" caseInsensitiveCompare:q] == NSOrderedSame)
        {
            NSLog(@"Found directory that needs scanning... Performing it!");
            [self performFlickrPhotosSearchWithAttributes:query intoFolder:dir];
        }
        
        [SerialDict serialise:props into:[scanner absolutePath:[dir stringByAppendingPathComponent:@".props"]]];
        
    }
}

- (void) rescanTask
{
    [self rescan];
    
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:
                                [self methodSignatureForSelector:@selector(rescan)]];
    [invocation setTarget:self];
    [invocation setSelector:@selector(rescan)];
    [[NSRunLoop mainRunLoop] addTimer:[NSTimer timerWithTimeInterval:5 invocation:invocation repeats:YES] forMode:NSRunLoopCommonModes];
}

@end
