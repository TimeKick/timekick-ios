//
//  AppDelegate.m
//  What Time Is It?
//
//  Created by Beyer, Paul on 3/22/15.
//  Copyright (c) 2015 What Time Is It?. All rights reserved.
//

#import "AppDelegate.h"
#import "AppSettings.h"
#import "UIColor+WTCustomColor.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "TimeViewController.h"

@interface AppDelegate () <UIAlertViewDelegate>

@end

@implementation AppDelegate

/*
+ (void)initialize {
    
    [[UITabBarItem appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName : [UIColor lightPurpleTextColor] }
                                             forState:UIControlStateNormal];
    [[UITabBarItem appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName : [UIColor lightPurpleTextColor] }
                                             forState:UIControlStateSelected];
    [[UITabBar appearance] setTintColor:[UIColor lightPurpleTextColor]];
}
 */

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [[FBSDKApplicationDelegate sharedInstance] application:application
                             didFinishLaunchingWithOptions:launchOptions];
    [FBSDKSettings enableLoggingBehavior:FBSDKLoggingBehaviorAppEvents];
    /*
    NSArray *familyNames = [[NSArray alloc] initWithArray:[UIFont familyNames]];
    NSArray *fontNames;
    NSInteger indFamily, indFont;
    for (indFamily=0; indFamily<[familyNames count]; ++indFamily)
    {
        NSLog(@"Family name: %@", [familyNames objectAtIndex:indFamily]);
        fontNames = [[NSArray alloc] initWithArray:
                     [UIFont fontNamesForFamilyName:
                      [familyNames objectAtIndex:indFamily]]];
        for (indFont=0; indFont<[fontNames count]; ++indFont)
        {
            NSLog(@"    Font name: %@", [fontNames objectAtIndex:indFont]);
        }
    }
     */
    [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil]];
    [application cancelAllLocalNotifications];
    
    if ([[AppSettings sharedSettings] numberOfLaunches]%5==0 && ![[AppSettings sharedSettings] didLeaveFeedback]) {
        //Once every 5 launches
        [[[UIAlertView alloc] initWithTitle:@"Feedback" message:@"Thank you for using TimeKick.  Would you please let us know what we could do better?" delegate:self cancelButtonTitle:@"No Thanks" otherButtonTitles:@"Sure", nil] show];
    }
    
    [UITabBarItem.appearance setTitleTextAttributes:
     @{NSForegroundColorAttributeName : [UIColor lightPurpleTextColor]}
                                           forState:UIControlStateNormal];
    
    [UITabBarItem.appearance setTitleTextAttributes:
     @{NSForegroundColorAttributeName : [UIColor darkPurpleTextColor]}
                                           forState:UIControlStateSelected];
    
    //[UILabel appearanceWhenContainedIn:[UITableView class], [UIDatePicker class], nil].textColor = [UIColor darkPurpleTextColor];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [FBSDKAppEvents activateApp];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    
    [self application:application handleOpenURL:url];
    
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                          openURL:url
                                                sourceApplication:sourceApplication
                                                       annotation:annotation];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    if ([url.scheme isEqualToString:@"tkapp"]) {
        NSLog(@"URL: %@",url.absoluteString);
        NSMutableDictionary *queryStringDictionary = [[NSMutableDictionary alloc] init];
        NSArray *urlComponents = [url.absoluteString.stringByRemovingPercentEncoding componentsSeparatedByString:@"?"];
        urlComponents = [urlComponents[1] componentsSeparatedByString:@"&"];
        for (NSString *keyValuePair in urlComponents)
        {
            NSArray *pairComponents = [keyValuePair componentsSeparatedByString:@"="];
            NSString *key = [[pairComponents firstObject] stringByRemovingPercentEncoding];
            NSString *value = [[pairComponents lastObject] stringByRemovingPercentEncoding];
            
            [queryStringDictionary setObject:value forKey:key];
        }
        if (queryStringDictionary[@"mode"]) {
            NSTimeInterval referenceInterval = [queryStringDictionary[@"referenceDate"] doubleValue];
            NSInteger mode = [queryStringDictionary[@"mode"] integerValue];
            if (mode == 1 || mode == 2) {
                //Countdown or Target
                if (referenceInterval <= [[NSDate date] timeIntervalSince1970]) {
                    [[[UIAlertView alloc] initWithTitle:@"You Missed It" message:@"This share has expired." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
                    return NO;
                }
            }
            NSDate *referenceDate = [NSDate dateWithTimeIntervalSince1970:referenceInterval];
            
            UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
            [tabBarController setSelectedIndex:mode];
            
            TimeViewController *vc = (TimeViewController *)tabBarController.viewControllers[mode];
            [vc launchWithReferenceDate:referenceDate reminderDuration:[queryStringDictionary[@"reminderDuration"] doubleValue]];
        }
        
    }
    
    return YES;
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(nullable NSString *)identifier forLocalNotification:(nonnull UILocalNotification *)notification completionHandler:(nonnull void (^)())completionHandler {
    [application setApplicationIconBadgeNumber:0];
    
    if ([identifier isEqualToString:@"Launch"] && notification.userInfo[@"url"]) {
        NSURL *url = [NSURL URLWithString:notification.userInfo[@"url"]];
        [self application:application handleOpenURL:url];

    }
}


#pragma mark UIAlertViewDelegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex==1) {
        //Open feedback
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.timekickap.com/support/"]];
        [FBSDKAppEvents logEvent:@"leaveFeedback" parameters:@{@"from":@"Prompt"}];
        [[AppSettings sharedSettings] setDidLeaveFeedback:YES];
    }
}

@end
