//
//  JSDecoupledAppDelegate.m
//
//  Created by Javier Soto on 9/9/13.
//  Copyright (c) 2013 JavierSoto. All rights reserved.
//

#import "JSDecoupledAppDelegate.h"

#import <objc/runtime.h>

static NSSet *_JSSelectorsInProtocol(Protocol *protocol, BOOL required)
{
    unsigned int count;
    struct objc_method_description *methods = protocol_copyMethodDescriptionList(protocol, required, YES, &count);

    NSMutableSet *list = [NSMutableSet setWithCapacity:count];
    for (unsigned i = 0; i < count; i++)
    {
        [list addObject:NSStringFromSelector(methods[i].name)];
    }

    free(methods);

    return list;
}

static NSSet *JSSelectorListInProtocol(Protocol *protocol)
{
    NSMutableSet *list = [NSMutableSet set];

    [list unionSet:_JSSelectorsInProtocol(protocol, YES)];
    [list unionSet:_JSSelectorsInProtocol(protocol, NO)];

    return list;
}

static NSArray *JSApplicationDelegateProperties()
{
    static NSArray *propertiesArray = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        propertiesArray = @[
                            NSStringFromSelector(@selector(appStateDelegate)),
                            NSStringFromSelector(@selector(appDefaultOrientationDelegate)),
                            NSStringFromSelector(@selector(backgroundFetchDelegate)),
                            NSStringFromSelector(@selector(remoteNotificationsDelegate)),
                            NSStringFromSelector(@selector(localNotificationsDelegate)),
                            NSStringFromSelector(@selector(stateRestorationDelegate)),
                            NSStringFromSelector(@selector(URLResouceOpeningDelegate)),
                            NSStringFromSelector(@selector(protectedDataDelegate)),
                          ];
    });

    return propertiesArray;
}

static NSArray *JSApplicationSubprotocolArray()
{
    static NSArray *protocolArray = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        protocolArray = @[
                          NSStringFromProtocol(@protocol(JSApplicationStateDelegate)),
                          NSStringFromProtocol(@protocol(JSApplicationDefaultOrientationDelegate)),
                          NSStringFromProtocol(@protocol(JSApplicationBackgroundFetchDelegate)),
                          NSStringFromProtocol(@protocol(JSApplicationRemoteNotificationsDelegate)),
                          NSStringFromProtocol(@protocol(JSApplicationLocalNotificationsDelegate)),
                          NSStringFromProtocol(@protocol(JSApplicationStateRestorationDelegate)),
                          NSStringFromProtocol(@protocol(JSApplicationURLResourceOpeningDelegate)),
                          NSStringFromProtocol(@protocol(JSApplicationProtectedDataDelegate))
                          ];
    });

    return protocolArray;
}

@implementation JSDecoupledAppDelegate

#pragma mark - Method Proxying

- (BOOL)respondsToSelector:(SEL)aSelector
{
    NSArray *delegateProperties = JSApplicationDelegateProperties();

    // 1. Get the protocol that the method corresponds to
    __block BOOL protocolFound = NO;
    __block BOOL delegateRespondsToSelector = NO;

    [JSApplicationSubprotocolArray() enumerateObjectsUsingBlock:^(NSString *protocolName, NSUInteger idx, BOOL *stop) {
        NSSet *protocolMethods = JSSelectorListInProtocol(NSProtocolFromString(protocolName));

        const BOOL methodCorrespondsToThisProtocol = [protocolMethods containsObject:NSStringFromSelector(aSelector)];
        
        if (methodCorrespondsToThisProtocol)
        {
            protocolFound = YES;

            id delegateObjectForProtocol = [self valueForKey:delegateProperties[idx]];

            delegateRespondsToSelector = [delegateObjectForProtocol respondsToSelector:aSelector];

            *stop = YES;
        }
    }];

    if (protocolFound)
    {
        return delegateRespondsToSelector;
    }
    else
    {
        // 3. Doesn't correspond to any? Then just return whether we respond to it:
        return [super respondsToSelector:aSelector];
    }
}

#pragma mark - JSApplicationStateDelegate

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSParameterAssert(self.appStateDelegate);

    return [self.appStateDelegate application:application willFinishLaunchingWithOptions:launchOptions];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    return [self.appStateDelegate application:application didFinishLaunchingWithOptions:launchOptions];
}

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
    [self.appStateDelegate applicationDidFinishLaunching:application];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [self.appStateDelegate applicationWillResignActive:application];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [self.appStateDelegate applicationDidBecomeActive:application];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [self.appStateDelegate applicationDidEnterBackground:application];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [self.appStateDelegate applicationWillEnterForeground:application];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [self.appStateDelegate applicationWillTerminate:application];
}

#pragma mark - JSApplicationDefaultOrientationDelegate

- (NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
    return [self.appDefaultOrientationDelegate application:application supportedInterfaceOrientationsForWindow:window];
}

#pragma mark - JSApplicationBackgroundFetchDelegate

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler
{
    [self.backgroundFetchDelegate application:application performFetchWithCompletionHandler:completionHandler];
}

#pragma mark - JSApplicationRemoteNotificationsDelegate

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    [self.remoteNotificationsDelegate application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    [self.remoteNotificationsDelegate application:application didFailToRegisterForRemoteNotificationsWithError:error];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    [self.remoteNotificationsDelegate application:application didReceiveRemoteNotification:userInfo];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler
{
    [self.remoteNotificationsDelegate application:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];
}

#pragma mark - JSApplicationLocalNotificationsDelegate

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    [self.localNotificationsDelegate application:application didReceiveLocalNotification:notification];
}

#pragma mark - JSApplicationStateRestorationDelegate

- (UIViewController *)application:(UIApplication *)application viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    return [self.stateRestorationDelegate application:application viewControllerWithRestorationIdentifierPath:identifierComponents coder:coder];
}

- (BOOL)application:(UIApplication *)application shouldSaveApplicationState:(NSCoder *)coder
{
    return [self.stateRestorationDelegate application:application shouldSaveApplicationState:coder];
}

- (BOOL)application:(UIApplication *)application shouldRestoreApplicationState:(NSCoder *)coder
{
    return [self.stateRestorationDelegate application:application shouldRestoreApplicationState:coder];
}

- (void)application:(UIApplication *)application willEncodeRestorableStateWithCoder:(NSCoder *)coder
{
    [self.stateRestorationDelegate application:application willEncodeRestorableStateWithCoder:coder];
}

- (void)application:(UIApplication *)application didDecodeRestorableStateWithCoder:(NSCoder *)coder
{
    [self.stateRestorationDelegate application:application didDecodeRestorableStateWithCoder:coder];
}

#pragma mark - JSApplicationURLResourceOpeningDelegate

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [self.URLResouceOpeningDelegate application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
}

#pragma mark - JSApplicationProtectedDataDelegate

- (void)applicationProtectedDataWillBecomeUnavailable:(UIApplication *)application
{
    [self.protectedDataDelegate applicationProtectedDataWillBecomeUnavailable:application];
}

- (void)applicationProtectedDataDidBecomeAvailable:(UIApplication *)application
{
    [self.protectedDataDelegate applicationProtectedDataDidBecomeAvailable:application];
}

@end
