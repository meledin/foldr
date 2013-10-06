//
//  Synckr.h
//  Synckr
//
//  Created by Vladimir Katardjiev on 2013-09-28.
//  Copyright (c) 2013 d2dx. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSMutableDictionary+SynckrFile.h"

#define CONFIG_SYNCKR_DIR @"synckrDirectory"
#define CONFIG_PHOTO_RESOLUTION @"photoSizeIdx"
#define CONFIG_REFRESH_INTERVAL @"refreshInterval"
#define CONFIG_LAST_EVENT_ID @"lastEventId"
#define CONFIG_DAEMON @"enableDaemon"

#define KEY_REFRESH_INTERVAL CONFIG_REFRESH_INTERVAL
#define KEY_NEXT_REFRESH @"nextRefresh"

#define MIN_REFRESH_INTERVAL 15

@interface Synckr : NSObject

+ (Synckr*) instance;
+ (void) reset;

- (void) testLogin;
//- (void) uploadItem: (File*) item;
- (void) itemCreated: (NSMutableDictionary*)item atPath: (NSString *)path;
- (NSString*)username;

@end
