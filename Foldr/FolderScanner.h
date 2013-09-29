//
//  FolderScanner.h
//  Foldr
//
//  Created by Vladimir Katardjiev on 2013-09-28.
//  Copyright (c) 2013 d2dx. All rights reserved.
//

#import <CDEvents/CDEventsDelegate.h>
#import <Foundation/Foundation.h>
#import "File.h"

@interface FolderScanner : NSObject<CDEventsDelegate>

- (void) ensureDirExists: (NSString *)relPath;
- (void) download: (File*)file;
- (NSMutableDictionary*) indexedDirAtSubPath: (NSString*)subPath;
- (NSString *)absolutePath: (NSString *)relPath;

@end
