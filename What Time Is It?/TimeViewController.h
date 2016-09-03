//
//  TimeViewController.h
//  TimeKick
//
//  Created by Beyer, Paul on 1/30/16.
//  Copyright © 2016 What Time Is It?. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "TimeSelectionViewController.h"
#import "SettingsViewController.h"
#import "AppSettings.h"
#import "WTUIHeader.h"

@import MediaPlayer;
@import AVFoundation;

#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define UTTERANCE_RATE (SYSTEM_VERSION_LESS_THAN(@"9.0"))?0.1500f:0.4500f
#define UTTERANCE_RATE_FASTER (SYSTEM_VERSION_LESS_THAN(@"9.0"))?0.1700f:0.5500f


@interface TimeViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIButton *startStopButton;
@property (weak, nonatomic) IBOutlet UIButton *settingsButton;
@property (weak, nonatomic) IBOutlet UIButton *favoritesButton;
@property (weak, nonatomic) IBOutlet UILabel *clockModuleLabel;
@property (weak, nonatomic) IBOutlet UILabel *nextReminderLabel;
@property (weak, nonatomic) IBOutlet UIButton *changeIntervalButton;
@property (weak, nonatomic) IBOutlet UILabel *remindingEveryLabel;
@property (weak, nonatomic) IBOutlet UILabel *targetDateLabel;
@property (weak, nonatomic) IBOutlet UIButton *saveAsFavoriteButton;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topSpaceConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topSpaceToLabelConstraint;

@property(nonatomic,strong) SettingsViewController *settingsViewController;
@property(nonatomic,strong) TimeSelectionViewController *timeSelectionViewController;

//Timers and Tasks
@property(nonatomic,strong) NSDate *timerDate;
@property(nonatomic) NSTimeInterval timerDuration;
@property(nonatomic,strong) NSTimer *everySecondTimer;
@property(nonatomic,strong) NSTimer *intervalTimer;
@property(nonatomic) UIBackgroundTaskIdentifier bgTask;

//Data
@property(nonatomic,strong) NSArray *availableIntervals;
@property(nonatomic,strong) NSArray *availableIntervalDurations;
@property(nonatomic,strong) NSArray *availableIntervalDurationSpeech;

@property(nonatomic,strong) NSDate *referenceDate;
@property(nonatomic,strong) NSDate *referenceDateTime;
@property(nonatomic,strong) NSDate *nextReminderDateTime;
@property(nonatomic,assign) NSTimeInterval reminderDuration;
@property(nonatomic,strong) NSString *reminderDurationString;
@property(nonatomic,strong) NSString *reminderDurationSpeech;

//Speech
@property(nonatomic,strong) AVSpeechSynthesizer *synth;
@property(nonatomic,strong) AVAudioSession *audioSession;

@property(nonatomic) BOOL isFinalCountdown;
@property(nonatomic) BOOL finalCountdownStarted;

@property (strong, nonatomic) AVAudioPlayer *alertPlayer;

@property (strong, nonatomic) UIDatePicker *dateTimePicker;
@property (strong, nonatomic) UIView *overlayView;
@property (strong, nonatomic) NSString *lastSpeechString;

- (void)start;
- (void)startFinalCountdown;
- (IBAction)startStopButtonPushed:(UIButton *)sender;
- (IBAction)settingsButtonPushed:(UIButton *)sender;
- (IBAction)clockModuleButtonPushed:(id)sender;
- (IBAction)changeIntervalButtonPushed:(UIButton *)sender;
- (IBAction)favoritesButtonPushed:(id)sender;
- (IBAction)saveAsFavoriteButtonPushed:(UIButton *)sender;
- (void)handleFavorites;
- (NSString *)hmsStringFromDuration:(NSTimeInterval)duration;
- (void)loadFavorite;
- (BOOL)isFavorite;
- (IBAction)shareButtonPushed:(id)sender;

- (void)launchWithReferenceDate:(NSDate *)referenceDate reminderDuration:(NSTimeInterval)duration;

@end
