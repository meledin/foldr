//
//  Uploader.h
//  Foldr
//
//  Created by Vladimir Katardjiev on 2013-09-28.
//  Copyright (c) 2013 d2dx. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FoldrCommand.h"
#import <ObjectiveFlickr/ObjectiveFlickr.h>

@interface Uploader : NSObject <OFFlickrAPIRequestDelegate>

@property(strong) OFFlickrAPIContext *ctx;
- (void) enqueue: (FoldrCommand*)newCmd;
+ (Uploader*) instance;
- (NSUInteger) numTasks;

@end
