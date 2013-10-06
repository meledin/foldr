//
//  StatusMenu.h
//  Synckr
//
//  Created by Vladimir Katardjiev on 2013-09-29.
//  Copyright (c) 2013 d2dx. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FolderScanner;

@interface StatusMenu : NSObject

- (id) initWithScanner: (FolderScanner*)scanner;
- (void) performReset;

@end
