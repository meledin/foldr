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

Foldr *instance = nil;

@implementation Foldr
{
    NSDictionary *user;
    AppDelegate *delegate;
    FolderScanner *scanner;
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
        scanner = [[FolderScanner alloc] init];
    }
    
    return self;
}

- (void) testLogin
{
    FoldrCommand *cmd = [FoldrCommand get: @"flickr.test.login"];
    cmd.onSuccess = ^(NSDictionary *resp)
    {
        NSLog(@"Got response: %@", [resp description]);
        user = [resp valueForKeyPath:@"user"];
        NSLog(@"Got Username: %@", [user valueForKeyPath:@"username._text"]);
        
        NSString *dest = [NSString stringWithFormat:@"%@", [user valueForKeyPath:@"username._text"]];
        [scanner ensureDirExists:dest];
        [self downloadPhotosForUserId:[user valueForKeyPath:@"id"] withAttributes:nil intoFolder:dest];
    };
    cmd.onError = ^(NSError *err)
    {
        if (err.code == 99)
            [delegate oauthAuthenticationAction];
    };
    
    [delegate queueCommand: cmd];
}

- (void) downloadPhotosForUserId: (NSString*)flickrUserId withAttributes:(NSDictionary *)inAttrs intoFolder: (NSString*)destination
{
    NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithDictionary:inAttrs];
    [attrs setValue:flickrUserId forKey:@"user_id"];
    [attrs setValue:@"url_k,url_l,date_upload,date_taken" forKey:@"extras"];
    
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
            
            f.relativePath = [NSString stringWithFormat:@"%@/%@", destination, f.name];
            
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
        
        // Only start the procedure if we recognise the file type.
        if (imageType != nil)
        {
            NSInputStream *stream = [NSInputStream inputStreamWithFileAtPath:item.path];
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
            cmd.execute = ^(OFFlickrAPIRequest *req) {
                [req uploadImageStream:stream suggestedFilename:item.name MIMEType:imageType arguments:params];
            };
            cmd.onSuccess = ^(NSDictionary *resp) {
                item.flickrPhotoId = [resp valueForKeyPath:@"photoid._text"];
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
                [self downloadPhotosForUserId:[resp valueForKeyPath:@"user.nsid"] withAttributes:nil intoFolder:dest];
            };
            cmd.onError= ^(NSError *err)
            {
                // Ignore the error
            };
            
            
            [delegate queueCommand:cmd];
            
        }
    }
}


@end
