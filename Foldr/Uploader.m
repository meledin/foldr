//
//  Uploader.m
//  Foldr
//
//  Created by Vladimir Katardjiev on 2013-09-28.
//  Copyright (c) 2013 d2dx. All rights reserved.
//

#import "Uploader.h"

Uploader *upInstance;

@implementation Uploader
{
    BOOL running;
    NSMutableArray *queue;
    FoldrCommand *cmd;
    OFFlickrAPIRequest *req;
}

+ (Uploader*)instance
{
    if (!upInstance)
        upInstance = [[Uploader alloc] init];
    
    return upInstance;
}

- (id) init
{
    self = [super init];
    
    if (self)
    {
        running = false;
        queue = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (OFFlickrAPIContext*)ctx
{
    return nil;
}

- (void) setCtx:(OFFlickrAPIContext *)ctx
{
    req = [[OFFlickrAPIRequest alloc] initWithAPIContext:ctx];
    [req setDelegate:self];
}

- (void) enqueue: (FoldrCommand*)newCmd
{
    @synchronized(self)
    {
        [queue addObject:newCmd];
    }
    [self flushQueue];
}

- (void) flushQueue
{
    @synchronized(self)
    {
        if (running)
            return;
        
        if (queue.count == 0)
            return;
        
        running = true;
        
        cmd = [queue objectAtIndex:0];
        [queue removeObjectAtIndex:0];
    }
    
    cmd.execute(req);
    
}


- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didCompleteWithResponse:(NSDictionary *)inResponseDictionary
{
    NSLog(@"%s, return: %@", __PRETTY_FUNCTION__, inResponseDictionary);
    
    // Unmatched session info should be one of our toys...
    @try
    {
        cmd.onSuccess(inResponseDictionary);
    }
    @catch(...)
    {
    }
    [self finish];
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didFailWithError:(NSError *)inError
{
    NSLog(@"%s, error: %@", __PRETTY_FUNCTION__, inError);
    
    @try
    {
        if (cmd.onError)
            cmd.onError(inError);
    }
    @catch(...)
    {
    }
    [self finish];
}

- (void) finish
{
    @synchronized(self)
    {
        running = false;
        [self flushQueue];
    }
}

- (NSUInteger) numTasks
{
    @synchronized(self)
    {
        NSUInteger count = [queue count];
        if (running) count++;
        return count;
    }
}


- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest imageUploadSentBytes:(NSUInteger)inSentBytes totalBytes:(NSUInteger)inTotalBytes
{
    NSLog(@"%s %lu/%lu", __PRETTY_FUNCTION__, inSentBytes, inTotalBytes);
}

@end
