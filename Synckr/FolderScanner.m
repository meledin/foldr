//
//  FolderScanner.m
//  Synckr
//
//  Created by Vladimir Katardjiev on 2013-09-28.
//  Copyright (c) 2013 d2dx. All rights reserved.
//

#import "FolderScanner.h"
#import <CDEvents/CDEvents.h>
#import <CDEvents/CDEvent.h>
#import "File.h"
#import "Synckr.h"

FolderScanner *fsInstance;

@implementation FolderScanner
{
    CDEvents *events;
    NSMutableDictionary *contents;
    NSString *path;
    NSOperationQueue *downloads;
    NSUInteger numDownloads;
}

//- (void) indexSubDirectory: (NSString*)path;

- (void) indexDirectory: (NSString*)dirPath intoDictionary: (NSMutableDictionary*)dict recursively: (BOOL) isRecursive
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *theFiles =  [fileManager contentsOfDirectoryAtURL:[NSURL fileURLWithPath:dirPath]
                                    includingPropertiesForKeys:[NSArray arrayWithObject:NSURLNameKey]
                                                       options:NSDirectoryEnumerationSkipsHiddenFiles
                                                         error:nil];
    NSArray* fileNames = [theFiles valueForKeyPath:@"lastPathComponent"];
    if ( [fileNames count] > 0 ) {
        for (NSInteger i=0; i<[fileNames count]; i=i+1) {
            NSString *currentPath = [dirPath stringByAppendingPathComponent:[fileNames objectAtIndex:i]];
            NSError *error;
            NSDictionary *fileInfo = [fileManager attributesOfItemAtPath:currentPath error:&error];
            
            File *cf = [[File alloc] init];
            cf.name = [fileNames objectAtIndex:i];
            cf.type = fileInfo.fileType;
            cf.path = currentPath;
            cf.inode = fileInfo.fileSystemFileNumber;
            cf.creationDate = fileInfo.fileCreationDate;
            cf.modificationDate = fileInfo.fileModificationDate;
            cf.relativePath = [self getRelativePath:cf.path];
            
            if (cf.type == NSFileTypeDirectory)
            {
                if (!isRecursive)
                {
                    [dict setValue:cf forKey:cf.name];
                    continue;
                }
                
                NSMutableDictionary *subdir = [[NSMutableDictionary alloc] init];
                [dict setValue:subdir forKey:cf.name];
                [self indexDirectory:cf.path intoDictionary:subdir recursively:true];
            }
            else if (cf.type == NSFileTypeRegular)
            {
                if ([cf.name rangeOfString:@"."].location == 0)
                    continue; // Don't add hidden files.
                
                [dict setValue:cf forKey:cf.name];
            }
            
            //[files addObject:currentFile];
        }
    }
}

+ (FolderScanner*)instance
{
    return fsInstance;
}

- (id) init
{
    self = [super init];
    
    if (self)
    {
        fsInstance = self;
        downloads = [[NSOperationQueue alloc] init];
        path = [@"~/Pictures/Synckr" stringByExpandingTildeInPath];
        
        unsigned long lastEvent = [[NSUserDefaults standardUserDefaults] integerForKey:@"lastEvent"];
        numDownloads = 0;
        
        if (!lastEvent) lastEvent = kCDEventsSinceEventNow;
        
        // lastEvent = 214665687;
        
        @synchronized(self)
        {
        
        events = [[CDEvents alloc] initWithURLs:[NSArray arrayWithObject:[NSURL URLWithString: path]] delegate:self onRunLoop:[NSRunLoop currentRunLoop]  sinceEventIdentifier: lastEvent
            notificationLantency:0.1
            ignoreEventsFromSubDirs:CD_EVENTS_DEFAULT_IGNORE_EVENT_FROM_SUB_DIRS
            excludeURLs:nil
            streamCreationFlags:kCDEventsDefaultEventStreamFlags];
        
        contents = [NSMutableDictionary dictionaryWithContentsOfFile:@"~/Pictures/Synckr/.SynckrIndex"];
        
        if (!contents)
        {
            contents = [[NSMutableDictionary alloc] init];
            
            // Index the contents
            
            [self indexDirectory: path intoDictionary: contents recursively:true];
            
            NSLog(@"%@", [contents description]);
        }
            
        }
        

    }
    
    return self;
}

- (void)URLWatcher:(CDEvents *)URLWatcher eventOccurred:(CDEvent *)event
{
    NSLog(@"Got Event");
    [NSThread sleepForTimeInterval:0.25];
    
    NSString *eventPath = [event.URL path];
    
    if ([path caseInsensitiveCompare: [eventPath substringToIndex:[path length]]] != NSOrderedSame)
        return;
    
    /*NSMutableDictionary *dict = contents;
    
    if ([eventPath length] > [path length])
    {
        NSString *subPath = [eventPath substringFromIndex:[path length] + 1];
        NSArray *arr = [subPath pathComponents];
        
        for (int i=0; i<arr.count; i++)
        {
            NSMutableDictionary *cDict = [dict valueForKey: arr[i]];
            
            if (!cDict)
            {
                //TODO: FIXME!
                return;
            }
            
            dict = cDict;
        }
    }*/
    
    @synchronized(self)
    {
        NSMutableDictionary *indexed = [self getPath:eventPath];
        NSMutableDictionary *real = [[NSMutableDictionary alloc] init];
        
        [self indexDirectory:eventPath intoDictionary:real recursively:false];
        
        NSArray *keys = [real allKeys];
        
        // Check for new files
        for (int i=0; i<keys.count; i++)
        {
            NSString *key = keys[i];
            File *realItem = (File*)[real valueForKey:key];
            NSObject *value = [indexed valueForKey: key];
            
            if (!value)
            {
                // CREATED!
                
                if ([realItem.name rangeOfString:@"untitled folder"].location == 0)
                    continue;
                
                NSString *newPath = [eventPath stringByAppendingPathComponent:key];
                NSLog(@"New file at: %@", newPath);
                
                if (realItem.type == NSFileTypeRegular)
                    [indexed setValue:realItem forKey:key];
                
                [[Synckr instance] itemCreated: realItem atPath:[self getRelativePath:newPath]];
            }
            else
            {
                if ([value respondsToSelector:@selector(name)])
                {
                    File *f = (File*)value;
                    
                    if (f.ignore)
                    {
                        // do_nothing_loop()
                    }
                    else if (f.ignoreFirstModification)
                    {
                        f.ignoreFirstModification = false;
                        f.modificationDate = realItem.modificationDate;
                        
                        f.inode = realItem.inode;
                        f.path = realItem.path;
                        f.creationDate = realItem.creationDate;
                        f.relativePath = [self getRelativePath:f.path];
                        
                    }
                    else if ([f.modificationDate compare:realItem.modificationDate] != NSOrderedSame)
                    {
                        // MODIFIED!!!
                        NSLog(@"Modified file at: %@", realItem.path);
                        f.modificationDate = realItem.modificationDate;
                    }
                    
                }
            }
        }
        
    }
}

- (NSString *)getRelativePath: (NSString*)dirPath
{
    
    if ([dirPath length] > [path length])
    {
        return [dirPath substringFromIndex:[path length] + 1];
    }
    else
        return @"";
}

- (NSMutableDictionary *)getPath: (NSString *)dirPath
{
    NSMutableDictionary *dict = contents;
    
    if ([dirPath length] > [path length])
    {
        NSString *subPath = [dirPath substringFromIndex:[path length] + 1];
        return [self indexedDirAtSubPath:subPath];
    }
    
    return dict;

}

- (NSMutableDictionary*) indexedDirAtSubPath: (NSString*)subPath
{
    NSMutableDictionary *dict = contents;
    
    if (subPath.length > 0)
    {
        NSArray *arr = [subPath pathComponents];
        
        for (int i=0; i<arr.count; i++)
        {
            NSMutableDictionary *cDict = [dict valueForKey: arr[i]];
            
            if (!cDict)
            {
                //TODO: FIXME!
                return NULL;
            }
            
            dict = cDict;
        }
    }
    
    return dict;
}

- (void) ensureDirExists:(NSString *)relPath
{
    if (relPath.length == 0)
        return;
    
    NSArray *parts = [relPath pathComponents];
    NSMutableDictionary *d = contents;
    
    for (int i=0; i<parts.count; i++)
    {
        NSString *part = parts[i];
        
        NSMutableDictionary *childDir = [contents valueForKeyPath:part];
        
        if (!childDir)
        {
            childDir = [[NSMutableDictionary alloc] init];
            [d setValue:childDir forKey:part];
        }
        
        d = childDir;
    }
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSString *absolute = [path stringByAppendingPathComponent:relPath];
    if (![fm fileExistsAtPath: absolute])
        [fm createDirectoryAtPath:absolute withIntermediateDirectories:YES attributes:nil error:nil];
    
}

- (void) download: (File*)file
{
    [self download:file andOverwrite:false];
}

- (void) download: (File*)file andOverwrite: (BOOL) overwrite
{
    file.ignore = true;
    file.path = [path stringByAppendingPathComponent:file.relativePath];
    
    // Test if there is any existing.
    NSString *basePath = [file.path stringByDeletingPathExtension];
    NSString *jpgPath = [basePath stringByAppendingPathExtension:@"jpg"];
    NSString *pngPath = [basePath stringByAppendingPathExtension:@"png"];
    NSString *gifPath = [basePath stringByAppendingPathExtension:@"gif"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:jpgPath])
    {
        if (!overwrite)
            return;
        
        [[NSFileManager defaultManager] removeItemAtPath:jpgPath error:nil];
    }
    else if ([[NSFileManager defaultManager] fileExistsAtPath:pngPath])
    {
        if (!overwrite)
            return;
        
        [[NSFileManager defaultManager] removeItemAtPath:pngPath error:nil];
    }
    else if ([[NSFileManager defaultManager] fileExistsAtPath:gifPath])
    {
        if (!overwrite)
            return;
        
        [[NSFileManager defaultManager] removeItemAtPath:gifPath error:nil];
    }
    
    NSString *downloadUrl = file.flickrUrl1024;
    
    NSLog(@"%ld", [[NSUserDefaults standardUserDefaults] integerForKey:@"SynckrSizeIdx"]);
    
    if ([[NSUserDefaults standardUserDefaults] integerForKey:@"SynckrSizeIdx"] == 1 && file.flickrUrl2048 && file.flickrUrl2048.length > 0)
        downloadUrl = file.flickrUrl2048;
    
    // Null download - do nothing loop
    if (!downloadUrl)
        return;
    
    NSURLRequest *req = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString: downloadUrl] cachePolicy:NSURLCacheStorageAllowed timeoutInterval:60.0];
    
    NSDictionary *d = [self getPath:[file.path stringByDeletingLastPathComponent]];
    [d setValue:file forKey:file.name];
    
    NSLog(@"Queueing request for: %@", file.flickrUrl1024);
    @synchronized(self)
    {
        numDownloads++;
    }
    [NSURLConnection sendAsynchronousRequest:req queue:downloads completionHandler:^(NSURLResponse *resp, NSData *data, NSError *err) {
        NSLog(@"Request completed");
        @synchronized(self)
        {
            numDownloads--;
        }
        [data writeToFile:file.path atomically:true];
        
        NSDictionary *attr = [NSDictionary dictionaryWithObjectsAndKeys:file.creationDate, NSFileCreationDate, file.modificationDate, NSFileModificationDate, nil];
        [[NSFileManager defaultManager] setAttributes: attr ofItemAtPath:file.path error:nil];
        
        file.ignore = false;
        
    }];
    
    [downloads operationCount];
    [downloads isSuspended];
    [downloads setSuspended:NO];
    downloads.maxConcurrentOperationCount = 2;
}

- (NSString*)absolutePath:(NSString *)relPath
{
    return [path stringByAppendingPathComponent:relPath];
}

- (NSUInteger) numTasks
{
    return numDownloads;
}

@end
