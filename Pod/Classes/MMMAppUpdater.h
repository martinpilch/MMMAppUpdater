//
//  MMMAppUpdater.h
//
//  Created by martin pilch on 03/09/15.
//  Copyright (c) 2015 MMMAppUpdater. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MMMAppUpdater : NSObject

+ (instancetype)sharedInstance;
- (BOOL)openAppstoreURL;
- (void)checkForNewVersionWithCompletion:(void(^)(BOOL newVersion, NSURL *appURL))completion;

@end
