//
//  StopwatchViewController.m
//  TimeKick
//
//  Created by Beyer, Paul on 5/21/16.
//  Copyright © 2016 What Time Is It?. All rights reserved.
//

#import "StopwatchViewController.h"

@interface StopwatchViewController () <TimeSelectionDelegate>

@end

@implementation StopwatchViewController

- (void)updateLabels {
    [self updateLabelsForStopwatch];
    [self handleFavorites];
}

- (void)updateLabelsForStopwatch {
    if (!self.referenceDate) {
        self.clockModuleLabel.text = @"00:00";
    } else {
        NSTimeInterval diff = fabs([self.referenceDate timeIntervalSinceNow]);
        NSString *str = [self stringFromTimeInterval:diff];
       
        self.clockModuleLabel.text = str;
    }
    
    //if (self.nextReminderDateTime && _synth) {
    //    [self updateNextReminderLabel];
    //}
}

- (void)start {
    self.shareButton.hidden = NO;
    self.referenceDate = [NSDate date];

    [self.startStopButton setImage:[UIImage imageNamed:@"btn_off"] forState:UIControlStateNormal];
    
    self.audioSession = [AVAudioSession sharedInstance];
    [self.audioSession setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionDuckOthers error:nil];
    [self.audioSession setActive:YES error:nil];
    
//    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:[NSString stringWithFormat:@"Now reminding you every %@.",self.reminderDurationSpeech]];
//    utterance.rate = UTTERANCE_RATE;
//    //utterance.volume = [[AppSettings sharedSettings] volumeLevel].floatValue/100;
    self.synth = [[AVSpeechSynthesizer alloc] init];
    self.synth.delegate = (id)self;
//    [self.synth speakUtterance:utterance];
    
    self.bgTask = UIBackgroundTaskInvalid;
    UIApplication *app = [UIApplication sharedApplication];
    self.bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
        [app endBackgroundTask:self.bgTask];
    }];
    [self.intervalTimer invalidate];
    self.intervalTimer = [NSTimer scheduledTimerWithTimeInterval:self.reminderDuration target:self selector:@selector(updateUser) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.intervalTimer forMode:UITrackingRunLoopMode];
    
    [[AppSettings sharedSettings] setIsAlreadyRunning:YES];
    self.tabBarController.selectedViewController.tabBarItem.badgeValue = @"!";
    
    [FBSDKAppEvents logEvent:@"start" parameters:@{@"type":@"Forward",@"reminderDuration":self.reminderDurationSpeech,@"timeOfDay":[AppSettings timeOfDayStringForDate:nil]}];
}

- (NSString *)stringFromTimeInterval:(NSTimeInterval)interval {
    NSInteger ti = (NSInteger)interval;
    NSInteger seconds = ti % 60;
    NSInteger minutes = (ti / 60) % 60;
    NSInteger hours = (ti / 3600);
    if ([[AppSettings sharedSettings] showSeconds]) {
        return [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hours, (long)minutes, (long)seconds];
    } else {
        if (minutes <= 0 && hours <=  0) {
            return [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hours, (long)minutes, (long)seconds];
        } else {
            return [NSString stringWithFormat:@"%02ld:%02ld", (long)hours, (long)minutes];
        }

    }
}

- (void)showTimeSelectionView {
    if (self.timeSelectionViewController) {
        [self.timeSelectionViewController.view removeFromSuperview];
        self.timeSelectionViewController = nil;
    }
    self.timeSelectionViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"TimeSelectionViewController"];
    //self.timeSelectionViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"NewTimeSelectionViewController"];
    self.timeSelectionViewController.delegate = self;
    if (self.referenceDate) {
        self.timeSelectionViewController.initialDate = self.referenceDate;
    } else if (self.timerDuration > 0) {
        self.timeSelectionViewController.initialTimeInterval = self.timerDuration;
    }
    self.timeSelectionViewController.selectionMode = TimeSelectionModeInterval;
    
    
    //Animate
    self.timeSelectionViewController.view.alpha = 0.0f;
    [self.view addSubview:self.timeSelectionViewController.view];
    
    [UIView animateWithDuration:0.25f animations:^{
        self.timeSelectionViewController.view.alpha = 1.0f;
    } completion:^(BOOL finished) {}];
}

- (void)updateUser {
    NSTimeInterval diff = fabs([self.referenceDate timeIntervalSinceNow]);
    NSString *remaining = [self hmsStringFromDuration:diff];
    
    if (!self.audioSession) {
        self.audioSession = [AVAudioSession sharedInstance];
        [self.audioSession setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionDuckOthers error:nil];
    }
    [self.audioSession setActive:YES error:nil];
    NSString *speechString = [NSString stringWithFormat:NSLocalizedString(@"ELAPSED_REMINDER", nil),remaining];
    //if (minutes<=0 && (seconds == 0 || seconds == 1)) {
    //    speechString = NSLocalizedString(@"TIME_UP", nil);
    //}
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:speechString];
    utterance.rate = (self.reminderDuration<=5)?UTTERANCE_RATE_FASTER:UTTERANCE_RATE;
    //utterance.volume = [[AppSettings sharedSettings] volumeLevel].floatValue/100;
    [self.synth speakUtterance:utterance];
    self.synth.delegate = self;
}

@end
