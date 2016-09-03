//
//  MainViewController.m
//  What Time Is It?
//
//  Created by Beyer, Paul on 3/22/15.
//  Copyright (c) 2015 What Time Is It?. All rights reserved.
//

#import "MainViewController.h"
#import "SettingsViewController.h"
#import "TimeSelectionViewController.h"
#import "AppSettings.h"
#import "WTUIHeader.h"

#define RUN_MODE_CONFIRMATION_ALERT 999
#define LOAD_FAVORITE_ALERT         998
#define TOUR_FONT (([[UIScreen mainScreen] bounds].size.height>480)?14.0f:12.0f)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define UTTERANCE_RATE (SYSTEM_VERSION_LESS_THAN(@"9.0"))?0.1500f:0.4500f

@import AVFoundation;
@import MediaPlayer;

@interface MainViewController() <AVSpeechSynthesizerDelegate, TimeSelectionDelegate, UIAlertViewDelegate>
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

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setDefaults];

    [self updateLabels];
    
    if (![[AppSettings sharedSettings] didShowTour]) {
        [self createTourOverlay];
    }
    
    self.everySecondTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(updateLabels) userInfo:nil repeats:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillClose:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [UIApplication sharedApplication].idleTimerDisabled = YES;
}

//UI Defaults
- (void)setDefaults {
    //[self.runModeSegmentedControl setBackgroundImage:[UIImage imageNamed:@"WHATTIME_iPad-selectbuttonbkgrd_off-1"] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [self.runModeSegmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor],NSFontAttributeName:[UIFont helveticaNeueLightWithSize:17.0f]} forState:UIControlStateSelected];
    [self.runModeSegmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor purpleTextColor],NSFontAttributeName:[UIFont helveticaNeueLightWithSize:17.0f]} forState:UIControlStateNormal];
    [self.runModeSegmentedControl setBackgroundImage:[UIImage imageNamed:@"WHATTIME_iPad-selectbuttonbkgrd_on-1"] forState:UIControlStateSelected barMetrics:UIBarMetricsDefault];

    [self.runModeSegmentedControl setTitle:NSLocalizedString(@"RUN_MODE_TIME", nil) forSegmentAtIndex:0];
    [self.runModeSegmentedControl setTitle:NSLocalizedString(@"RUN_MODE_COUNTDOWN", nil) forSegmentAtIndex:1];
    [self.runModeSegmentedControl setTitle:NSLocalizedString(@"RUN_MODE_ALARM", nil) forSegmentAtIndex:2];
    self.runModeSegmentedControl.layer.cornerRadius = 4.0f;
    self.runModeSegmentedControl.layer.masksToBounds = YES;
    
    [self.clockModuleLabel setTextColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"WHATTIME_iPhone6plus-Timegradient"]]];
    self.clockModuleLabel.layer.cornerRadius = 4.0f;
    [self.targetDateLabel setTextColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"WHATTIME_iPhone6plus-Timegradient"]]];
    
    [self.startStopButton setTitle:NSLocalizedString(@"START_BUTTON", nil) forState:UIControlStateNormal];
    self.startStopButton.layer.cornerRadius = 4.0f;
    
    self.availableIntervals = @[NSLocalizedString(@"1_MINUTE", nil),NSLocalizedString(@"5_MINUTES", nil),NSLocalizedString(@"10_MINUTES", nil)];
    self.availableIntervalDurationSpeech = @[NSLocalizedString(@"1_MINUTE_SPEECH", nil),NSLocalizedString(@"5_MINUTES_SPEECH", nil),NSLocalizedString(@"10_MINUTES_SPEECH", nil)];
    self.availableIntervalDurations = @[@60,@300,@600];
    
    self.nextReminderLabel.layer.cornerRadius = 4.0f;
    self.nextReminderLabel.layer.borderColor = [UIColor whiteColor].CGColor;
    self.nextReminderLabel.layer.borderWidth = 1.0f;
    
    UIImage *image = [UIImage imageNamed:@"WHATTIME_iPhone6plus-favicon"];
    [self.favoritesButton setImage:[image imageWithTint:[UIColor whiteColor]] forState:UIControlStateNormal];
    
    [self.runModeSegmentedControl setSelectedSegmentIndex:[[AppSettings sharedSettings] savedFavoriteRunMode]];
    [self runModeDidChange:_runModeSegmentedControl];
}

- (void)hideTour {
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.5f animations:^{
            self.overlayView.alpha = 0.0f;
        } completion:^(BOOL finished) {
            [self.overlayView removeFromSuperview];
            [[AppSettings sharedSettings] setDidShowTour:YES];
        }];
    });
}

- (void)createTourOverlay {
    self.overlayView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    _overlayView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
    
    UIButton *saveAsFavoriteButtonCopy = [UIButton buttonWithType:UIButtonTypeCustom];
    [saveAsFavoriteButtonCopy setImage:self.saveAsFavoriteButton.imageView.image forState:UIControlStateNormal];
    [saveAsFavoriteButtonCopy setTitle:@"Save as Favorite" forState:UIControlStateNormal];
    [saveAsFavoriteButtonCopy setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    saveAsFavoriteButtonCopy.titleLabel.font = [UIFont systemFontOfSize:14.0f];
    [saveAsFavoriteButtonCopy setImageEdgeInsets:UIEdgeInsetsMake(0, -8, 0, 0)];
    saveAsFavoriteButtonCopy.frame = self.saveAsFavoriteButton.frame;
    //[_overlayView addSubview:saveAsFavoriteButtonCopy];
    
    UIButton *loadFavCopy = [UIButton buttonWithType:UIButtonTypeCustom];
    loadFavCopy.userInteractionEnabled = NO;
    loadFavCopy.frame = self.favoritesButton.frame;
    [loadFavCopy setImage:[UIImage imageNamed:@"WHATTIME_iPhone6plus-favicon"] forState:UIControlStateNormal];
    [_overlayView addSubview:loadFavCopy];
    
    UILabel *loadFavLabel = [[UILabel alloc] initWithFrame:CGRectMake(loadFavCopy.frame.origin.x+loadFavCopy.frame.size.width+5, loadFavCopy.frame.origin.y, self.view.frame.size.width-(loadFavCopy.frame.origin.x+loadFavCopy.frame.size.width+5), 1)];
    loadFavLabel.textColor = [UIColor whiteColor];
    loadFavLabel.text = @"← Quickly load your favorite settings...";
    loadFavLabel.font = [UIFont boldSystemFontOfSize:TOUR_FONT];
    [loadFavLabel sizeToFit];
    loadFavLabel.center = CGPointMake(loadFavLabel.center.x, loadFavCopy.center.y);
    [_overlayView addSubview:loadFavLabel];
    
    UISegmentedControl *segControlCopy = [[UISegmentedControl alloc] initWithFrame:self.runModeSegmentedControl.frame];
    [segControlCopy insertSegmentWithTitle:@"Time" atIndex:0 animated:NO];
    [segControlCopy insertSegmentWithTitle:@"Countdown" atIndex:1 animated:NO];
    [segControlCopy insertSegmentWithTitle:@"Target" atIndex:2 animated:NO];
    segControlCopy.tintColor = self.runModeSegmentedControl.tintColor;
    segControlCopy.userInteractionEnabled = NO;
    segControlCopy.selectedSegmentIndex = 0;
    [segControlCopy setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor],NSFontAttributeName:[UIFont helveticaNeueLightWithSize:17.0f]} forState:UIControlStateSelected];
    [segControlCopy setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor purpleTextColor],NSFontAttributeName:[UIFont helveticaNeueLightWithSize:17.0f]} forState:UIControlStateNormal];
    [segControlCopy setBackgroundImage:[UIImage imageNamed:@"WHATTIME_iPad-selectbuttonbkgrd_on-1"] forState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
    segControlCopy.frame = CGRectMake(segControlCopy.frame.origin.x, segControlCopy.frame.origin.y, self.view.frame.size.width-(2*segControlCopy.frame.origin.x), segControlCopy.frame.size.height);
    segControlCopy.backgroundColor = [UIColor lightGrayColor];
    segControlCopy.layer.cornerRadius = 4.0f;
    [_overlayView addSubview:segControlCopy];
    
    UIButton *startButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [startButton setTitle:NSLocalizedString(@"START_BUTTON", nil) forState:UIControlStateNormal];
    startButton.layer.cornerRadius = 4.0f;
    startButton.userInteractionEnabled = NO;
    startButton.clipsToBounds = YES;
    startButton.frame = self.startStopButton.frame;
    startButton.frame = CGRectMake(startButton.frame.origin.x, self.view.frame.size.height-45-startButton.frame.size.height, self.view.frame.size.width-(2*startButton.frame.origin.x), startButton.frame.size.height);

    [startButton setBackgroundImage:[UIImage imageNamed:@"WHATTIME_TellMebutton_on"] forState:UIControlStateNormal];
    [_overlayView addSubview:startButton];
    
    UILabel *startLabel = [[UILabel alloc] initWithFrame:CGRectMake(startButton.frame.origin.x, 0, startButton.frame.size.width, 1)];
    startLabel.textColor = [UIColor whiteColor];
    startLabel.text = @"↓ Tap to select reminder interval and begin the currently selected run mode...";
    startLabel.font = [UIFont boldSystemFontOfSize:TOUR_FONT];
    startLabel.numberOfLines = 0;
    [startLabel sizeToFit];
    startLabel.frame = CGRectMake(startButton.frame.origin.x, startButton.frame.origin.y-10-startLabel.frame.size.height, startLabel.frame.size.width, startLabel.frame.size.height);
    startLabel.center = CGPointMake(self.view.frame.size.width/2, startLabel.center.y);
    [_overlayView addSubview:startLabel];
    
    UILabel *modeLabel = [[UILabel alloc] initWithFrame:CGRectMake(startButton.frame.origin.x, 0, startButton.frame.size.width, 20)];
    modeLabel.textColor = [UIColor whiteColor];
    modeLabel.text = @"↓ Available run modes...";
    modeLabel.font = [UIFont boldSystemFontOfSize:TOUR_FONT];
    modeLabel.frame = CGRectMake(modeLabel.frame.origin.x, CGRectGetMaxY(segControlCopy.frame)+5, startLabel.frame.size.width, modeLabel.frame.size.height);
    [modeLabel sizeToFit];
    modeLabel.center = CGPointMake(self.view.frame.size.width/2, modeLabel.center.y);
    [_overlayView addSubview:modeLabel];
    
    UILabel *modesLabel = [[UILabel alloc] initWithFrame:CGRectMake(startButton.frame.origin.x, CGRectGetMaxY(modeLabel.frame)-2, startButton.frame.size.width, 200)];
    modesLabel.textColor = [UIColor whiteColor];
    modesLabel.numberOfLines = 0;
    modesLabel.text = @"Time ⇢ Choose a reminder interval and we will remind you of the current time until you say stop.\n\nCountdown ⇢ Set a time length and reminder interval and we will let you know how much time you have left.\n\nTarget ⇢ Choose an exact time and reminder interval and we will let you know how much time you have left.\n\nTimeKick even works while your favorite music is playing!";
    modesLabel.font = [UIFont boldSystemFontOfSize:TOUR_FONT];
    [modesLabel sizeToFit];
    [_overlayView addSubview:modesLabel];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideTour)];
    [_overlayView addGestureRecognizer:tap];
    [self.view addSubview:_overlayView];
}

- (IBAction)runModeDidChange:(UISegmentedControl *)sender {
    self.switchingToMode = sender.selectedSegmentIndex;
    if (self.synth) {
        [sender setSelectedSegmentIndex:self.mode];
        [self handleRunModeSwitchConfirmation];
        return;
    }
    
    [self switchMode];
}

- (void)switchMode {
    self.mode = self.switchingToMode;
    [self.runModeSegmentedControl setSelectedSegmentIndex:self.mode];
    
    self.timerDuration = 0;
    self.referenceDate = nil;
    self.dateTimePicker.alpha = 0.0f;;
    
    [self stop];
    [self updateLabels];
    [self updateTargetLabel];
}

- (IBAction)startStopButtonPushed:(UIButton *)sender {
    if (_synth) {
        [self stop];
    } else {
        if (self.mode == RunModeRunningClock) {
            [self presentActionSheetOrPopOverFromSender:sender];
        } else if (self.mode == RunModeCountdown) {
            [self presentActionSheetOrPopOverFromSender:sender];
        } else if (self.mode == RunModeTarget) {
            [self presentActionSheetOrPopOverFromSender:sender];
        }
    }
}

- (IBAction)settingsButtonPushed:(UIButton *)sender {
    if (self.settingsViewController) {
        [self.settingsViewController.view removeFromSuperview];
        self.settingsViewController = nil;
    }
    self.settingsViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"SettingsViewController"];

    //Animate
    _settingsViewController.effectView.alpha = 0.0f;
    CGRect frame = _settingsViewController.navigationBar.frame;
    CGFloat navY = frame.origin.y;
    
    frame = _settingsViewController.settingsTableView.frame;
    CGFloat tblY = frame.origin.y;
    
    [self.view addSubview:_settingsViewController.view];
    
    [UIView animateWithDuration:0.4f animations:^{
        CGRect frame = _settingsViewController.navigationBar.frame;
        frame.origin.y = navY;
        _settingsViewController.navigationBar.frame = frame;
        
        frame = _settingsViewController.settingsTableView.frame;
        frame.origin.y = tblY;
        _settingsViewController.settingsTableView.frame = frame;
        
        _settingsViewController.effectView.alpha = 1.0f;
    } completion:^(BOOL finished) {}];
}

- (IBAction)clockModuleButtonPushed:(id)sender {
    if (self.mode == RunModeTarget || self.mode == RunModeCountdown) {
        [self showTimeSelectionView];
    }
}

- (IBAction)changeIntervalButtonPushed:(UIButton *)sender {
    [self presentActionSheetOrPopOverFromSender:sender];
}

- (IBAction)favoritesButtonPushed:(id)sender {
    if ([[AppSettings sharedSettings] savedFavoriteReminderInterval] > 0) {
        if (self.synth) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Favorite" message:@"Please cancel your current mode to load a favorite scanario." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alertView show];
        } else {
            [UIView animateWithDuration:0.4f animations:^{
                [self.runModeSegmentedControl setSelectedSegmentIndex:[[AppSettings sharedSettings] savedFavoriteRunMode]];
                [self runModeDidChange:_runModeSegmentedControl];
                self.dateTimePicker.countDownDuration = [[AppSettings sharedSettings] savedFavoriteTimeInterval];
                [self updateLabels];
                UIImage *image = [UIImage imageNamed:@"WHATTIME_iPhone6plus-favicon"];
                [self.favoritesButton setImage:image forState:UIControlStateNormal];
            } completion:^(BOOL finished) {
                self.reminderDuration = [[AppSettings sharedSettings] savedFavoriteReminderInterval];
                [[AppSettings sharedSettings] setLastReminderInterval:self.reminderDuration];
                [self start];
            }];
        }
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Favorite" message:@"This button retrieves your favorites. Please save a favorite scenario first." delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        alertView.tag = LOAD_FAVORITE_ALERT;
        [alertView show];
    }
}

- (IBAction)saveAsFavoriteButtonPushed:(UIButton *)sender {
    [[AppSettings sharedSettings] setSavedFavoriteRunMode:self.runModeSegmentedControl.selectedSegmentIndex];
    [[AppSettings sharedSettings] setSavedFavoriteTimeInterval:self.dateTimePicker.countDownDuration];
    [[AppSettings sharedSettings] setSavedFavoriteReminderInterval:[[AppSettings sharedSettings] lastReminderInterval]];
    [self updateLabels];
    
    CABasicAnimation *pulseAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    pulseAnimation.duration = .3;
    pulseAnimation.toValue = [NSNumber numberWithFloat:1.3];
    pulseAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    pulseAnimation.autoreverses = YES;
    pulseAnimation.repeatCount = 1;
    [self.favoritesButton.layer addAnimation:pulseAnimation forKey:nil];
}

- (void)handleRunModeSwitchConfirmation {
    NSString *confirmText = @"", *confirmTitle = @"";
    switch (self.mode) {
        case RunModeCountdown:
            confirmTitle = @"Active Countdown";
            confirmText = @"Switching modes will cancel your current Countdown.";
            break;
        case RunModeRunningClock:
            confirmTitle = @"Active Time";
            confirmText = @"Switching modes will cancel your current Time Reminder.";
            break;
        case RunModeTarget:
            confirmTitle = @"Active Target";
            confirmText = @"Switching modes will cancel your current Target.";
            break;
        default:
            break;
    }
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:confirmTitle message:confirmText delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Continue", nil];
    alertView.tag = RUN_MODE_CONFIRMATION_ALERT;
    [alertView show];
}

#pragma mark
- (void)updateLabels {
    if (self.mode == RunModeRunningClock) {
        [self updateLabelsForRunModeRunningClock];
    } else if (self.mode == RunModeCountdown) {
        [self updateLabelsForRunModeCountdown];
    } else if (self.mode == RunModeTarget) {
        [self updateLabelsForRunModeCountdown];
        [self updateTargetLabel];
    }
    [self colorFavoriteButton];
    
    NSDate *currentDate = [NSDate date];
    NSTimeInterval diff = [self.referenceDate timeIntervalSinceDate:currentDate];
    if (diff <= 11 &&  self.synth && (self.mode == RunModeCountdown || self.mode == RunModeTarget)) {
        [self startFinalCountdown];
    }
}

- (void)updateTargetLabel {
    if (self.referenceDate) {
        self.targetDateLabel.hidden = NO;
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"h:mm a"];
        NSString *time = [formatter stringFromDate:self.referenceDate];
        self.targetDateLabel.text = [NSString stringWithFormat:@"Target: %@",time];
    } else {
        self.targetDateLabel.hidden = YES;
    }
}

- (void)updateLabelsForRunModeRunningClock {
    NSDate *now = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"h:mm"];
    NSString *hhmm = [formatter stringFromDate:now];
    [formatter setDateFormat:@":ss"];
    NSString *s = [formatter stringFromDate:now];
    [formatter setDateFormat:@" a"];
    NSString *a = [formatter stringFromDate:now];
    
    NSMutableAttributedString *timeAttrString = [[NSMutableAttributedString alloc] initWithString:hhmm attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:65.0f]}];
    NSAttributedString *sAttrString = [[NSAttributedString alloc] initWithString:s attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:65.0f]}];
    NSAttributedString *aAttrString = [[NSAttributedString alloc] initWithString:a attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:20.0f]}];
    if ([[AppSettings sharedSettings] showSeconds]) {
        [timeAttrString appendAttributedString:sAttrString];
    }
    [timeAttrString appendAttributedString:aAttrString];
    
    self.clockModuleLabel.attributedText = timeAttrString;
    
    if (self.nextReminderDateTime && _synth) {
        [self updateNextReminderLabel];
    }
}

- (void)updateLabelsForRunModeCountdown {
    if (self.timerDuration || self.referenceDate) {
        NSString *timeString = @"00:00:00";
        if (self.referenceDate) {
            NSTimeInterval until = [self.referenceDate timeIntervalSinceNow];
            if (until > 0) {
                timeString = [self stringFromTimeInterval:until];
            } else {
                timeString = NSLocalizedString(@"TIME_UP_UI", nil);
            }
        } else {
            timeString = [self stringFromTimeInterval:self.timerDuration];
        }
        
        NSMutableAttributedString *timeAttrString = [[NSMutableAttributedString alloc] initWithString:timeString attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:60.0f]}];
        
        self.clockModuleLabel.attributedText = timeAttrString;
        
    } else {
        //self.clockModuleLabel.attributedText = [[NSMutableAttributedString alloc] initWithString:@"00:00:00" attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:60.0f]}];;
        self.clockModuleLabel.text = nil;
        
        if (!self.dateTimePicker) {
            self.dateTimePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, 0, _clockModuleLabel.frame.size.width, _clockModuleLabel.frame.size.height)];
            _dateTimePicker.backgroundColor = [UIColor clearColor];
            _dateTimePicker.clipsToBounds = YES;
            _dateTimePicker.transform = CGAffineTransformMakeScale(.9, 0.8);
            [_dateTimePicker setMinimumDate:[NSDate date]];
            if (self.mode == RunModeCountdown) {
                _dateTimePicker.datePickerMode = UIDatePickerModeCountDownTimer;
            }
            _dateTimePicker.countDownDuration = [[AppSettings sharedSettings] savedFavoriteTimeInterval];
            _dateTimePicker.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2);
            [self.view addSubview:self.dateTimePicker];
            
            //[self.dateTimePicker setValue:[UIColor colorWithPatternImage:[UIImage imageNamed:@"WHATTIME_iPhone6plus-Timegradient"]] forKeyPath:@"textColor"];
            
            /*
            SEL selector = NSSelectorFromString(@"setHighlightsToday:");
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDatePicker instanceMethodSignatureForSelector:selector]];
            BOOL no = NO;
            [invocation setSelector:selector];
            [invocation setArgument:&no atIndex:2];
            [invocation invokeWithTarget:self.dateTimePicker];
            */
        }
        if (self.mode == RunModeCountdown) {
            _dateTimePicker.datePickerMode = UIDatePickerModeCountDownTimer;

        } else if (self.mode == RunModeTarget) {
            _dateTimePicker.datePickerMode = UIDatePickerModeDateAndTime;
        }
        [_dateTimePicker setMinimumDate:[NSDate date]];
        self.dateTimePicker.alpha = 1.0f;
    }
}

- (void)updateNextReminderLabel {
    self.nextReminderLabel.hidden = NO;
    self.changeIntervalButton.hidden = NO;
    self.remindingEveryLabel.hidden = NO;
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"h:mm a"];
    NSString *time = [formatter stringFromDate:self.nextReminderDateTime];
    
    self.nextReminderLabel.text = [NSString stringWithFormat:NSLocalizedString(@"NEXT_REMINDER", nil),time];
    self.remindingEveryLabel.text = [NSString stringWithFormat:NSLocalizedString(@"REMINDER_EVERY", nil),self.reminderDurationSpeech];
}

- (void)presentActionSheetOrPopOverFromSender:(UIButton *)sender {
    UIAlertController *actionController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"ACTION_SHEET_TITLE", nil) message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {}];
    [actionController addAction:cancelAction];
    [self.availableIntervals enumerateObjectsUsingBlock:^(NSString *interval, NSUInteger idx, BOOL *stop) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:interval style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            self.reminderDuration = [self.availableIntervalDurations[idx] floatValue];
            [[AppSettings sharedSettings] setLastReminderInterval:self.reminderDuration];
            self.reminderDurationString = self.availableIntervals[idx];
            self.reminderDurationSpeech = self.availableIntervalDurationSpeech[idx];
            [self start];
        }];
        [actionController addAction:action];
    }];
    UIAlertAction *customAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"CUSTOM_INTERVAL", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) { [self showTimeSelectionView];}];
    [actionController addAction:customAction];
    
    UIPopoverPresentationController *popover = actionController.popoverPresentationController;
    if (popover)
    {
        popover.sourceView = sender;
        popover.sourceRect = sender.bounds;
        popover.permittedArrowDirections = UIPopoverArrowDirectionAny;
    }
    
    [self presentViewController:actionController animated:YES completion:nil];
}

- (void)changeRunMode {
    
}

- (void)start {
    [self.startStopButton setBackgroundImage:[UIImage imageNamed:@"WHATTIME_Stopbutton_on"] forState:UIControlStateNormal];
    [self.startStopButton setTitle:NSLocalizedString(@"STOP_BUTTON", nil) forState:UIControlStateNormal];
    
    if (self.mode == RunModeRunningClock) {
        
        self.audioSession = [AVAudioSession sharedInstance];
        [_audioSession setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionDuckOthers error:nil];
        [_audioSession setActive:YES error:nil];
        
        AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:[NSString stringWithFormat:@"Now reminding you every %@.",self.reminderDurationSpeech]];
        utterance.rate = UTTERANCE_RATE;
        self.synth = [[AVSpeechSynthesizer alloc] init];
        _synth.delegate = (id)self;
        [_synth speakUtterance:utterance];
        
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents *components = [calendar components:(NSCalendarUnitSecond) fromDate:[NSDate date]];
        NSInteger delay = 60 - components.second;
        delay = delay + self.reminderDuration - 60;
        
        self.bgTask = UIBackgroundTaskInvalid;
        UIApplication *app = [UIApplication sharedApplication];
        self.bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
            [app endBackgroundTask:self.bgTask];
        }];
        [self.intervalTimer invalidate];
        self.intervalTimer = [NSTimer scheduledTimerWithTimeInterval:delay target:self selector:@selector(setupAudioWithReminderDuration:) userInfo:nil repeats:NO];
        [[NSRunLoop currentRunLoop] addTimer:self.intervalTimer forMode:UITrackingRunLoopMode];
        
        self.nextReminderDateTime = [[NSDate date] dateByAddingTimeInterval:delay];
        [self updateNextReminderLabel];
    } else if (self.mode == RunModeCountdown) {
        self.dateTimePicker.alpha = 0.0f;
        
        self.timerDuration = _dateTimePicker.countDownDuration;
        //self.reminderDuration = interval;
        
        self.audioSession = [AVAudioSession sharedInstance];
        [_audioSession setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionDuckOthers error:nil];
        [_audioSession setActive:YES error:nil];
        
        AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:[NSString stringWithFormat:@"Countdown started."]];
        utterance.rate = UTTERANCE_RATE;
        self.synth = [[AVSpeechSynthesizer alloc] init];
        _synth.delegate = (id)self;
        [_synth speakUtterance:utterance];
        
        self.bgTask = UIBackgroundTaskInvalid;
        UIApplication *app = [UIApplication sharedApplication];
        self.bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
            [app endBackgroundTask:self.bgTask];
        }];
        [self.intervalTimer invalidate];
        self.intervalTimer = [NSTimer scheduledTimerWithTimeInterval:self.reminderDuration target:self selector:@selector(updateUser) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.intervalTimer forMode:UITrackingRunLoopMode];
        
        self.referenceDate = [[NSDate date] dateByAddingTimeInterval:self.timerDuration];
    } else if (self.mode == RunModeTarget) {
        self.dateTimePicker.alpha = 0.0f;
        self.referenceDate = _dateTimePicker.date;
        
        self.audioSession = [AVAudioSession sharedInstance];
        [_audioSession setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionDuckOthers error:nil];
        [_audioSession setActive:YES error:nil];
        
        NSString *speechString;
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"h:mm"];
        speechString = [NSString stringWithFormat:NSLocalizedString(@"TARGET_START", nil),[formatter stringFromDate:self.referenceDate]];
        
        AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:speechString];
        utterance.rate = UTTERANCE_RATE;
        self.synth = [[AVSpeechSynthesizer alloc] init];
        _synth.delegate = (id)self;
        [_synth speakUtterance:utterance];
        
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents *components = [calendar components:(NSCalendarUnitSecond) fromDate:[NSDate date]];
        NSInteger delay = 60 - components.second;
        delay = delay + self.reminderDuration - 60;
        
        self.bgTask = UIBackgroundTaskInvalid;
        UIApplication *app = [UIApplication sharedApplication];
        self.bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
            [app endBackgroundTask:self.bgTask];
        }];
        [self.intervalTimer invalidate];
        self.intervalTimer = [NSTimer scheduledTimerWithTimeInterval:delay target:self selector:@selector(setupAudioTargetWithReminderDuration:) userInfo:nil repeats:NO];
        [[NSRunLoop currentRunLoop] addTimer:self.intervalTimer forMode:UITrackingRunLoopMode];
    }
    self.clockModuleLabel.hidden = NO;
    self.dateTimePicker.alpha = 0.0f;
}

- (void)stop {
    [self.startStopButton setBackgroundImage:[UIImage imageNamed:@"WHATTIME_TellMebutton_on"] forState:UIControlStateNormal];
    [self.startStopButton setTitle:NSLocalizedString(@"START_BUTTON", nil) forState:UIControlStateNormal];
    
    [self.synth stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    self.synth = nil;
    [self.intervalTimer invalidate];
    
    self.referenceDate = nil;
    self.timerDate = nil;
    
    self.nextReminderLabel.hidden = YES;
    self.changeIntervalButton.hidden = YES;
    self.remindingEveryLabel.hidden = YES;
    
    self.dateTimePicker.countDownDuration = self.timerDuration;
    self.timerDuration = 0;
    
    if (_alertPlayer.playing)
        [_alertPlayer stop];
    [_audioSession setActive:NO error:nil];
}

- (void)setupAudioWithReminderDuration:(id)sender {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.bgTask = UIBackgroundTaskInvalid;
        UIApplication *app = [UIApplication sharedApplication];
        self.bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
            [app endBackgroundTask:self.bgTask];
        }];
        [self.intervalTimer invalidate];
        self.intervalTimer = [NSTimer scheduledTimerWithTimeInterval:self.reminderDuration target:self selector:@selector(updateTime) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.intervalTimer forMode:UITrackingRunLoopMode];
        
        [self updateTime];
    });
}

- (void)setupAudioTargetWithReminderDuration:(id)sender {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.bgTask = UIBackgroundTaskInvalid;
        UIApplication *app = [UIApplication sharedApplication];
        self.bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
            [app endBackgroundTask:self.bgTask];
        }];
        [self.intervalTimer invalidate];
        self.intervalTimer = [NSTimer scheduledTimerWithTimeInterval:self.reminderDuration target:self selector:@selector(updateUser) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.intervalTimer forMode:UITrackingRunLoopMode];
        
        [self updateUser];
    });
}

- (void)updateTime {
    NSString *speechString;
    NSDate *currentDate = [NSDate date];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"mm"];
    if ([[formatter stringFromDate:currentDate] isEqualToString:@"00"]) {
        [formatter setDateFormat:@"h"];
        speechString = [NSString stringWithFormat:NSLocalizedString(@"TIME_REMINDER", nil),[formatter stringFromDate:currentDate]];
    } else {
        [formatter setDateFormat:@"h:mm"];
        speechString = [formatter stringFromDate:currentDate];
    }

    if (!_audioSession) {
        self.audioSession = [AVAudioSession sharedInstance];
        [_audioSession setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionDuckOthers error:nil];
    }
    [_audioSession setActive:YES error:nil];
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:speechString];
    utterance.rate = UTTERANCE_RATE;
    [_synth speakUtterance:utterance];
    _synth.delegate = self;
    
    self.nextReminderDateTime = [currentDate dateByAddingTimeInterval:self.reminderDuration];
}

- (void)updateUser {
    NSDate *currentDate = [NSDate date];
    NSTimeInterval diff = [self.referenceDate timeIntervalSinceDate:currentDate];
    
    if (diff <= 0) {
        self.synth = nil;
        [self.intervalTimer invalidate];
        self.intervalTimer = nil;
        
        return;
    } else if (diff <= 10) {
        self.isFinalCountdown = YES;
        
        return;
    }
    
    /*
    NSInteger minutes = floor(diff/60);
    NSInteger seconds = trunc(diff - minutes * 60);
    if (seconds == 58 || seconds == 59) {
        if (seconds == 58) {
            diff += 2;
        } else if (seconds == 59) {
            diff += 1;
        }
        minutes = floor(diff/60);
        seconds = trunc(diff - minutes * 60);
    }
    
    NSString *remaining;
    if (minutes > 0 && seconds > 0) {
        if (minutes == 1) {
            remaining = [NSString stringWithFormat:@"%.0ld minute and %0ld seconds",(long)minutes,(long)seconds];
        } else {
            remaining = [NSString stringWithFormat:@"%.0ld minutes and %0ld seconds",(long)minutes,(long)seconds];
        }
    } else if (minutes > 0) {
        if (minutes == 1) {
            remaining = @"1 minute";
        } else {
            remaining = [NSString stringWithFormat:@"%.0ld minutes",(long)minutes];
        }
    } else {
        remaining = [NSString stringWithFormat:@"%.0ld seconds",(long)seconds];
    }
    */
    NSString *remaining = [self hmsStringFromDuration:diff];
    
    if (!_audioSession) {
        self.audioSession = [AVAudioSession sharedInstance];
        [_audioSession setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionDuckOthers error:nil];
    }
    [_audioSession setActive:YES error:nil];
    NSString *speechString = [NSString stringWithFormat:NSLocalizedString(@"REMAINING_REMINDER", nil),remaining];
    //if (minutes<=0 && (seconds == 0 || seconds == 1)) {
    //    speechString = NSLocalizedString(@"TIME_UP", nil);
    //}
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:speechString];
    utterance.rate = UTTERANCE_RATE;
    [_synth speakUtterance:utterance];
    _synth.delegate = self;
}

- (void)showTimeSelectionView {
    if (self.timeSelectionViewController) {
        [self.timeSelectionViewController.view removeFromSuperview];
        self.timeSelectionViewController = nil;
    }
    self.timeSelectionViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"TimeSelectionViewController"];
    self.timeSelectionViewController.delegate = self;
    if (self.referenceDate) {
        self.timeSelectionViewController.initialDate = self.referenceDate;
    } else if (self.timerDuration > 0) {
        self.timeSelectionViewController.initialTimeInterval = self.timerDuration;
    }
    if (self.mode == RunModeCountdown) _timeSelectionViewController.selectionMode = TimeSelectionModeInterval;
    else if (self.mode == RunModeRunningClock) _timeSelectionViewController.selectionMode = TimeSelectionModeInterval;
    else if (self.mode == RunModeTarget) _timeSelectionViewController.selectionMode = TimeSelectionModeInterval;
    
    //Animate
    _timeSelectionViewController.view.alpha = 0.0f;
    [self.view addSubview:_timeSelectionViewController.view];
    
    [UIView animateWithDuration:0.25f animations:^{
        _timeSelectionViewController.view.alpha = 1.0f;
    } completion:^(BOOL finished) {}];
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer
 didFinishSpeechUtterance:(AVSpeechUtterance *)utterance {
    if (!self.finalCountdownStarted) {
        [_audioSession setActive:NO error:nil];
    }
}

- (void)startFinalCountdown {
    if (!self.finalCountdownStarted) {
        self.finalCountdownStarted = YES;
        
        [self.intervalTimer invalidate];
        self.intervalTimer = nil;
        
        [_audioSession setActive:YES error:nil];
    }
    
    NSDate *currentDate = [NSDate date];
    NSTimeInterval diff = [self.referenceDate timeIntervalSinceDate:currentDate];
    NSInteger minutes = floor(diff/60);
    NSInteger seconds = floor(diff - minutes * 60);
    
    if (diff < 0) {
        //[_audioSession setActive:NO error:nil];
    } else if (seconds == 0){
        [self playAlert];
    } else {
        NSString *speechString = [NSString stringWithFormat:@"%ld",(long)seconds];
        if (![speechString isEqualToString:self.lastSpeechString]) {
            AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:speechString];
            utterance.rate = UTTERANCE_RATE;
            [_synth speakUtterance:utterance];
            _synth.delegate = self;
            self.lastSpeechString = speechString;
        }
    }
}

- (void)playAlert {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"AlarmClock" ofType:@"mp3"];
    NSURL *soundFileURL = [NSURL fileURLWithPath:path];
    self.alertPlayer =[[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL error:nil];
    _alertPlayer.numberOfLoops = 0;
    [_alertPlayer prepareToPlay];
    [_alertPlayer play];
}

#pragma mark TimeSelectionDelegate
- (void)timerSelectedWithDuration:(NSTimeInterval)duration andReminderInterval:(NSTimeInterval)interval timerDate:(NSDate *)timerDate selectionMode:(TimeSelectionMode)selectionMode {
    switch (selectionMode) {
        case TimeSelectionModeTarget:
            //self.timerDate = timerDate;
            self.referenceDate = timerDate;
            self.timerDuration = duration;
            [self updateLabels];
            break;
        case TimeSelectionModeInterval:
            self.reminderDuration = duration;
            [[AppSettings sharedSettings] setLastReminderInterval:self.reminderDuration];
            self.reminderDurationString = [self hmsStringFromDuration:duration];
            self.reminderDurationSpeech = [self hmsStringFromDuration:duration];
            
            [self start];
            break;
        case TimeSelectionModeCountdown:
            self.timerDuration = duration;
            self.reminderDuration = interval;
            self.timerDate = timerDate;
            [self updateLabels];
            break;
        default:
            break;
    }
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == RUN_MODE_CONFIRMATION_ALERT) {
        if (buttonIndex == 1) {
            [self switchMode];
        }
    }
}

#pragma mark Helper Methods
- (NSString *)hmsStringFromDuration:(NSTimeInterval)duration {
    NSString *hString = @"", *mString = @"", *sString = @"";
    
    NSInteger ti = (NSInteger)duration;
    NSInteger seconds = ti % 60;
    NSInteger minutes = (ti / 60) % 60;
    NSInteger hours = (ti / 3600);
    
    if (seconds == 58) return [self hmsStringFromDuration:duration+2];
    if (seconds == 59) return [self hmsStringFromDuration:duration+1];
    
    if (hours > 0) {
        if (hours == 1) {
            hString = [NSString stringWithFormat:@"%2ld hour ",(long)hours];
        } else {
            hString = [NSString stringWithFormat:@"%2ld hours ",(long)hours];
        }
    }
    if (minutes > 0) {
        if (minutes == 1) {
            mString = [NSString stringWithFormat:@"%2ld minute ",(long)minutes];
        } else {
            mString = [NSString stringWithFormat:@"%2ld minutes ",(long)minutes];
        }
    }
    if (seconds > 0) {
        sString = [NSString stringWithFormat:@" %02ld seconds ",(long)seconds];
    }
    return [NSString stringWithFormat:@"%@%@%@",hString,mString,sString];
}

- (NSString *)stringFromTimeInterval:(NSTimeInterval)interval {
    NSInteger ti = (NSInteger)interval;
    NSInteger seconds = ti % 60;
    NSInteger minutes = (ti / 60) % 60;
    NSInteger hours = (ti / 3600);
    return [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hours, (long)minutes, (long)seconds];
}

- (void)colorFavoriteButton {
    UIImage *image = [UIImage imageNamed:@"WHATTIME_iPhone6plus-favicon"];
    if ([self isFavorite]) {
        [self.favoritesButton setImage:image forState:UIControlStateNormal];
        self.saveAsFavoriteButton.hidden = YES;
    } else {
        [self.favoritesButton setImage:[image imageWithTint:[UIColor whiteColor]] forState:UIControlStateNormal];
        if ([[AppSettings sharedSettings] lastReminderInterval] > 0) {
            self.saveAsFavoriteButton.hidden = NO;
        } else {
            self.saveAsFavoriteButton.hidden = YES;
        }
    }
}

- (BOOL)isFavorite {
    if (self.runModeSegmentedControl.selectedSegmentIndex == [[AppSettings sharedSettings] savedFavoriteRunMode]) {
        if (self.runModeSegmentedControl.selectedSegmentIndex == RunModeCountdown) {
            if (self.dateTimePicker.countDownDuration == [[AppSettings sharedSettings] savedFavoriteTimeInterval] && [[AppSettings sharedSettings] lastReminderInterval] == [[AppSettings sharedSettings] savedFavoriteReminderInterval]) {
                return YES;
            }
        }
        if ([[AppSettings sharedSettings] lastReminderInterval] > 0 && [[AppSettings sharedSettings] lastReminderInterval] == [[AppSettings sharedSettings] savedFavoriteReminderInterval]) {
            return YES;
        }
    }
    
    return NO;
}

- (void)applicationWillClose:(id)sender {
    if (_synth) {
        if (!_audioSession) {
            self.audioSession = [AVAudioSession sharedInstance];
            [_audioSession setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionDuckOthers error:nil];
        }
        
        NSString *speechString = @"For best results, please keep Time Kick open while you have an active timer.";
        [_audioSession setActive:YES error:nil];
        AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:speechString];
        utterance.rate = UTTERANCE_RATE;
        [_synth speakUtterance:utterance];
        _synth.delegate = self;
        
        UILocalNotification *notification = [[UILocalNotification alloc]init];
        notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:60*2];
        [notification setAlertBody:@"Remember to keep TimeKick open while you have an active timer."];
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    }
}

@end
