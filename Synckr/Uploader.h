//
//  Uploader.h
//  Synckr
//
//  Created by Vladimir Katardjiev on 2013-09-28.
//  Copyright (c) 2013 d2dx. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SynckrCommand.h"
#import <ObjectiveFlickr/ObjectiveFlickr.h>

@interface Uploader : NSObject <OFFlickrAPIRequestDelegate>

@property(strong) OFFlickrAPIContext *ctx;
- (void) enqueue: (SynckrCommand*)newCmd;
+ (Uploader*) instance;
- (NSUInteger) numTasks;

@end
