//
//  MMMAppUpdater.m
//
//  Created by martin pilch on 03/09/15.
//  Copyright (c) 2015 MMMAppUpdater. All rights reserved.
//

#import "MMMAppUpdater.h"

NSString * const kItunesLookupString = @"https://itunes.apple.com/lookup?bundleId=%@";

NSString * const kItunesURLKey = @"com.followio.followio.itunes.url";

@interface MMMAppUpdater ()

@end

@implementation MMMAppUpdater

+ (instancetype)sharedInstance
{
    static dispatch_once_t token;
    static MMMAppUpdater *instance;
    dispatch_once(&token, ^{
        instance = [[MMMAppUpdater alloc] init];
    });
    return instance;
}

- (BOOL)openAppstoreURL
{
    NSString *path = [[NSUserDefaults standardUserDefaults] objectForKey:kItunesURLKey];
    if ( !path ) {
        return NO;
    }
    NSURL *url = [NSURL URLWithString:path];
    if ( [[UIApplication sharedApplication] canOpenURL:url] ) {
        [[UIApplication sharedApplication] openURL:url];
        return YES;
    }
    return NO;
}

- (void)checkForNewVersionWithCompletion:(void (^)(BOOL, NSURL *))completion
{   
    NSDictionary *bundleInfo = [[NSBundle mainBundle] infoDictionary];
    NSString *bundleIdentifier = [bundleInfo valueForKey:@"CFBundleIdentifier"];
    NSURL *searchURL = [NSURL URLWithString:[NSString stringWithFormat:kItunesLookupString, bundleIdentifier]];
    
    __weak __typeof(self)weakSelf = self;
    
    // make request to check version
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithURL:searchURL
                                        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                            __strong __typeof(weakSelf)strongSelf = weakSelf;
                                            [strongSelf processResponse:response
                                                               withData:data
                                                                  error:error
                                                             completion:completion];
                                        }];
    [task resume];
}

#pragma mark - Private

- (void)processResponse:(NSURLResponse *)response withData:(NSData *)data error:(NSError *)error completion:(void(^)(BOOL, NSURL *))completion
{
    if ( error || !data ) {
        if ( completion ) {
            completion(NO, nil);
        }
        return;
    }
    
    // parse response data
    NSError *parseError = nil;
    NSDictionary *info = [NSJSONSerialization JSONObjectWithData:data
                                                         options:NSJSONReadingAllowFragments
                                                           error:&parseError];
    if ( parseError ) {
        if ( completion ) {
            completion(NO, nil);
        }
        return;
    }
    
    NSArray *results = info[@"results"];
    NSDictionary *result = (results.count > 0) ? results[0] : nil;
    BOOL newVersionAvailable = [self compareCurrentVersionWithVersion:result[@"version"]];
    
    NSString *appItunesPath = [result[@"trackViewUrl"] stringByReplacingOccurrencesOfString:@"&uo=4" withString:@""];
    NSURL *appItunesUrl = [NSURL URLWithString:appItunesPath];
    [[NSUserDefaults standardUserDefaults] setObject:appItunesPath forKey:kItunesURLKey];
    
    if ( completion ) {
        completion(newVersionAvailable, appItunesUrl);
    }
}

- (BOOL)compareCurrentVersionWithVersion:(NSString *)latestVersion
{
    if ( !latestVersion ) {
        return NO;
    }
    
    NSDictionary *infoDictionary = [[NSBundle mainBundle]infoDictionary];
    NSString *currentVersion = infoDictionary[@"CFBundleShortVersionString"];
    
    BOOL newVersionAvailable = ![latestVersion isEqualToString:currentVersion];
    return newVersionAvailable;
}

@end
