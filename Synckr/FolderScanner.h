//
//  FolderScanner.h
//  Synckr
//
//  Created by Vladimir Katardjiev on 2013-09-28.
//  Copyright (c) 2013 d2dx. All rights reserved.
//

#import <CDEvents/CDEventsDelegate.h>
#import <Foundation/Foundation.h>

@interface FolderScanner : NSObject<CDEventsDelegate>

- (void) ensureDirExists: (NSString *)relPath;
- (void) download: (NSMutableDictionary*)file;
- (NSMutableDictionary*) indexedDirAtSubPath: (NSString*)subPath;
- (NSString *)absolutePath: (NSString *)relPath;
- (NSUInteger) numTasks;
+ (FolderScanner*)instance;

@end
