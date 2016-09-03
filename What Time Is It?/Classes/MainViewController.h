//
//  MainViewController.h
//  What Time Is It?
//
//  Created by Beyer, Paul on 3/22/15.
//  Copyright (c) 2015 What Time Is It?. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, RunMode) {
    RunModeRunningClock,
    RunModeCountdown,
    RunModeTarget
};

@interface MainViewController : UIViewController

@property (nonatomic) RunMode mode;
@property (nonatomic) RunMode switchingToMode;

@property (weak, nonatomic) IBOutlet UISegmentedControl *runModeSegmentedControl;
@property (weak, nonatomic) IBOutlet UIButton *startStopButton;
@property (weak, nonatomic) IBOutlet UIButton *settingsButton;
@property (weak, nonatomic) IBOutlet UIButton *favoritesButton;
@property (weak, nonatomic) IBOutlet UILabel *clockModuleLabel;
@property (weak, nonatomic) IBOutlet UILabel *nextReminderLabel;
@property (weak, nonatomic) IBOutlet UIButton *changeIntervalButton;
@property (weak, nonatomic) IBOutlet UILabel *remindingEveryLabel;
@property (weak, nonatomic) IBOutlet UILabel *targetDateLabel;
@property (weak, nonatomic) IBOutlet UIButton *saveAsFavoriteButton;

- (IBAction)runModeDidChange:(UISegmentedControl *)sender;
- (IBAction)startStopButtonPushed:(UIButton *)sender;
- (IBAction)settingsButtonPushed:(UIButton *)sender;
- (IBAction)clockModuleButtonPushed:(id)sender;
- (IBAction)changeIntervalButtonPushed:(UIButton *)sender;
- (IBAction)favoritesButtonPushed:(id)sender;
- (IBAction)saveAsFavoriteButtonPushed:(UIButton *)sender;

@end
