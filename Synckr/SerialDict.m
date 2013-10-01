//
//  SerialDict.m
//  Synckr
//
//  Created by Vladimir Katardjiev on 9/28/13.
//  Copyright (c) 2013 d2dx. All rights reserved.
//

#import "SerialDict.h"

@implementation SerialDict

+ (void) serialise: (NSDictionary *)d into: (NSString*)path
{
    NSMutableString *str = [[NSMutableString alloc] init];
    
    [d enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [str appendFormat:@"%@ = %@\n", key, obj];
    }];
    
    [str writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

+ (NSMutableDictionary*) deserialize: (NSString *)path
{
    NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
    
    NSString *str = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    
    NSArray *lines = [str componentsSeparatedByString:@"\n"];
    
    for (int i=0; i<lines.count; i++)
    {
        NSArray *parts = [lines[i] componentsSeparatedByString:@"="];
        
        if (parts.count != 2)
            continue;
        
        NSString *key = [parts[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *value = [parts[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        [d setValue:value forKey:key];
    }
    
    return d;
}

@end
