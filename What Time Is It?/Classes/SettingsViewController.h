//
//  SettingsViewController.h
//  What Time Is It?
//
//  Created by Beyer, Paul on 3/22/15.
//  Copyright (c) 2015 What Time Is It?. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsViewController : UIViewController
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet UITableView *settingsTableView;
@property (weak, nonatomic) IBOutlet UIVisualEffectView *effectView;
@property (strong, nonatomic) UIButton *backButton;

@end
