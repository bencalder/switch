//
//  AppDelegate.m
//  switch
//
//  Created by Ben Calder on 4/1/15.
//  Copyright (c) 2015 BTS. All rights reserved.
//

#import "AppDelegate.h"
#import <Parse/Parse.h>
#import "ATConnect.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	/*** Apptentive added by Config.io ***/
	[ATConnect sharedConnection].apiKey = @"0a3d40abfa224a6d915d1c4e56f337c7b8c54b6b1d6267ee01d6dfcb060f2a78";
 // Override point for customization after application launch.
 [Parse enableLocalDatastore];
 
    // Initialize Parse.
 [Parse setApplicationId:@"E2CBcCERDwGxW58MpRc1wjM22utEX31apnYL2P3N"
               clientKey:@"QI7AGhnibNV6DcNKff1g8AOX6AMaty7BALBlavzH"];
 
    // [Optional] Track statistics around application opens.
 [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
 
 return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application
{
 // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
 // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application
{
 // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
 // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application
{
 // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application
{
 // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application
{
 // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
