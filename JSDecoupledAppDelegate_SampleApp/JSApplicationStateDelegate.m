//
//  JSApplicationStateDelegate.m
//  JSDecoupledAppDelegate_SampleApp
//
//  Created by Javier Soto on 9/9/13.
//  Copyright (c) 2013 JavierSoto. All rights reserved.
//

#import "JSApplicationStateDelegate.h"

@implementation JSApplicationStateDelegate

+ (void)load
{
    [JSDecoupledAppDelegate sharedAppDelegate].appStateDelegate = [[self alloc] init];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    return YES;
}

@end
