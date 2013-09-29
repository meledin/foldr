//
//  FoldrCommand.h
//  Foldr
//
//  Created by Vladimir Katardjiev on 2013-09-28.
//  Copyright (c) 2013 d2dx. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ObjectiveFlickr/ObjectiveFlickr.h>
#import "File.h"

@class FoldrCommand;

typedef void (^CommandExecute)(OFFlickrAPIRequest *request);
typedef void (^CommandExecuted)(NSDictionary *response);
typedef void (^CommandFailed)(NSError *err);

typedef enum FoldrCommandOp
{
    kFoldrCommandGET,
    kFoldrCommandPOST
    
} FoldrCommandOp;

@interface FoldrCommand : NSObject <OFFlickrAPIRequestDelegate>

@property (strong) NSString *path;
@property NSUInteger flickrPhotoId;
@property (strong) File *localFile;
@property FoldrCommandOp op;

@property (strong) NSString *flickrCommand;
@property (strong) NSDictionary *arguments;
@property (copy) CommandExecute execute;
@property (copy) CommandExecuted onSuccess;
@property (copy) CommandFailed onError;

// HACK
@property (strong) OFFlickrAPIRequest *req;

+ (FoldrCommand*) get: (NSString *) flickrCommand;
+ (FoldrCommand*) post: (NSString *) flickrCommand;

@end
