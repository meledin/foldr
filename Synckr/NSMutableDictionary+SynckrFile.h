//
//  NSObject+NSMutableDictionary_SynckrFile.h
//  Synckr
//
//  Created by Vladimir Katardjiev on 9/30/13.
//  Copyright (c) 2013 d2dx. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableDictionary (SynckrFile)

@property (strong) NSString *name;
@property (strong) NSString *type;
@property (strong) NSDate *creationDate;
@property (strong) NSDate *modificationDate;
@property (strong) NSString *path;
@property (strong) NSString *relativePath;
@property NSUInteger inode;


@property NSString *flickrPhotoTitle;
@property NSString *flickrPhotoId;
@property NSString *flickrPhotoSecret;
@property NSString *flickrPhotoServer;
@property NSString *flickrPhotoFarm;

@property NSString *flickrUrl1024; // 1024 res
@property NSString *flickrUrl2048; // 2048 res

// This flag allows us to insert an item without a race condition occurring.
// Happens when we download something off of Flickr.
@property BOOL ignoreFirstModification;

// Even hackier, simply ignore the item until further notice.
@property BOOL ignore;

@end
