//
//  FoldrCommand.m
//  Foldr
//
//  Created by Vladimir Katardjiev on 2013-09-28.
//  Copyright (c) 2013 d2dx. All rights reserved.
//

#import "FoldrCommand.h"

@implementation FoldrCommand

+ (FoldrCommand*) get: (NSString *) flickrCommand
{
    FoldrCommand *cmd = [[FoldrCommand alloc] init];
    cmd.op = kFoldrCommandGET;
    cmd.flickrCommand = flickrCommand;
    
    __weak FoldrCommand *weakCmd = cmd;
    cmd.execute = ^(OFFlickrAPIRequest *req)
    {
        [req callAPIMethodWithGET:weakCmd.flickrCommand arguments:weakCmd.arguments];
    };
    return cmd;
}

+ (FoldrCommand*) post: (NSString *) flickrCommand
{
    FoldrCommand *cmd = [[FoldrCommand alloc] init];
    cmd.op = kFoldrCommandPOST;
    cmd.flickrCommand = flickrCommand;
    
    __weak FoldrCommand *weakCmd = cmd;
    cmd.execute = ^(OFFlickrAPIRequest *req)
    {
        [req callAPIMethodWithPOST:weakCmd.flickrCommand arguments:weakCmd.arguments];
    };
    return cmd;
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didCompleteWithResponse:(NSDictionary *)inResponseDictionary
{
    NSLog(@"%s, return: %@", __PRETTY_FUNCTION__, inResponseDictionary);
    
    // Unmatched session info should be one of our toys...
    self.onSuccess(inResponseDictionary);
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didFailWithError:(NSError *)inError
{
    NSLog(@"%s, error: %@", __PRETTY_FUNCTION__, inError);
   
    if (self.onError)
        self.onError(inError);
}


- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest imageUploadSentBytes:(NSUInteger)inSentBytes totalBytes:(NSUInteger)inTotalBytes
{
    NSLog(@"%s %lu/%lu", __PRETTY_FUNCTION__, inSentBytes, inTotalBytes);
}


@end
