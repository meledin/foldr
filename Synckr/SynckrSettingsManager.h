//
//  SynckrSettingsManager.h
//  Synckr
//
//  Created by Vladimir Katardjiev on 10/5/13.
//  Copyright (c) 2013 d2dx. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SynckrSettingsManager : NSObject

+ (void) startServer;
+ (SynckrSettingsManager*) sharedManager;
- (void) agentDidLogout;

@end
