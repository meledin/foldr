//
//  SerialDict.h
//  Synckr
//
//  Created by Vladimir Katardjiev on 9/28/13.
//  Copyright (c) 2013 d2dx. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SerialDict : NSObject

+ (void) serialise: (NSDictionary *)d into: (NSString*)path;
+ (NSMutableDictionary*) deserialize: (NSString *)path;

@end
