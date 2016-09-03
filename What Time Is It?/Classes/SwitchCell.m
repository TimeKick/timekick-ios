//
//  SwitchCell.m
//  What Time Is It?
//
//  Created by Beyer, Paul on 3/30/15.
//  Copyright (c) 2015 What Time Is It?. All rights reserved.
//

#import "SwitchCell.h"
#import "AppSettings.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>

@implementation SwitchCell

- (IBAction)toggleChanged:(UISwitch *)sender {
    [[AppSettings sharedSettings] setShowSeconds:sender.on];
}

@end
