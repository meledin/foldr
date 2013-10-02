//
//  NSObject+NSMutableDictionary_SynckrFile.m
//  Synckr
//
//  Created by Vladimir Katardjiev on 9/30/13.
//  Copyright (c) 2013 d2dx. All rights reserved.
//

#import "NSMutableDictionary+SynckrFile.h"

@implementation NSMutableDictionary (SynckrFile)

- (NSString *) name
{
    return [self valueForKey:@"name"];
}

- (NSString *) type
{
    return [self valueForKey:@"type"];
}

- (NSDate *) creationDate
{
    return [NSDate dateWithString: [self valueForKey:@"creationDate"]];
}

- (NSDate *) modificationDate
{
    return [NSDate dateWithString: [self valueForKey:@"modificationDate"]];
}

- (NSString *) path
{
    return [self valueForKey:@"path"];
}

- (NSString *) relativePath
{
    return [self valueForKey:@"relativePath"];
}

- (NSUInteger) inode
{
    return [[self valueForKey:@"inode"] integerValue];
}

- (NSString *) flickrPhotoTitle
{
    return [self valueForKey:@"flickrPhotoTitle"];
}

- (NSString *) flickrPhotoId
{
    return [self valueForKey:@"flickrPhotoId"];
}

- (NSString *) flickrPhotoSecret
{
    return [self valueForKey:@"flickrPhotoSecret"];
}

- (NSString *) flickrPhotoServer
{
    return [self valueForKey:@"flickrPhotoServer"];
}

- (NSString *) flickrPhotoFarm
{
    return [self valueForKey:@"flickrPhotoFarm"];
}

- (NSString *) flickrUrl1024
{
    return [self valueForKey:@"flickrUrl1024"];
}

- (NSString *) flickrUrl2048
{
    return [self valueForKey:@"flickrUrl2048"];
}

- (BOOL) ignoreFirstModification
{
    return [[self valueForKey:@"ignoreFirstModification"] booleanValue];
}

- (BOOL) ignore
{
    return [[self valueForKey:@"ignore"] booleanValue];
}

- (void) setCreationDate:(NSDate *)creationDate
{
    [self setValue:[creationDate description] forKey:@"creationDate"];
}

- (void) setFlickrPhotoFarm:(NSString *)flickrPhotoFarm
{
    [self setValue:flickrPhotoFarm forKey:@"flickrPhotoFarm"];
}

- (void) setFlickrPhotoId:(NSString *)flickrPhotoId
{
    [self setValue:flickrPhotoId forKey:@"flickrPhotoId"];
}

- (void) setFlickrPhotoSecret:(NSString *)flickrPhotoSecret
{
    [self setValue:flickrPhotoSecret forKey:@"flickrPhotoSecret"];
}

- (void) setFlickrPhotoServer:(NSString *)flickrPhotoServer
{
    [self setValue:flickrPhotoServer forKey:@"flickrPhotoServer"];
}

- (void) setFlickrPhotoTitle:(NSString *)flickrPhotoTitle
{
    [self setValue:flickrPhotoTitle forKey:@"flickrPhotoTitle"];
}

- (void)setFlickrUrl1024:(NSString *)flickrUrl1024
{
    [self setValue:flickrUrl1024 forKey:@"flickrUrl1024"];
}

- (void) setFlickrUrl2048:(NSString *)flickrUrl2048
{
    [self setValue:flickrUrl2048 forKey:@"flickrUrl2048"];
}

- (void) setIgnore:(BOOL)ignore
{
    [self setValue:ignore?@"YES":@"NO" forKey:@"ignore"];
}

- (void) setIgnoreFirstModification:(BOOL)ignoreFirstModification
{
    [self setValue:ignoreFirstModification?@"YES":@"NO" forKey:@"ignoreFirstModification"];
}

- (void) setInode:(NSUInteger)inode
{
    [self setValue:[NSNumber numberWithInteger:inode] forKey:@"inode"];
}

- (void) setModificationDate:(NSDate *)modificationDate
{
    [self setValue:[modificationDate description] forKey:@"modificationDate"];
}

- (void) setName:(NSString *)name
{
    [self setValue:name forKey:@"name"];
}

- (void) setPath:(NSString *)path
{
    [self setValue:path forKey:@"path"];
}

- (void) setRelativePath:(NSString *)relativePath
{
    [self setValue:relativePath forKey:@"relativePath"];
}

- (void) setType:(NSString *)type
{
    [self setValue:type forKey:@"type"];
}

@end
