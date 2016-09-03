//
//  TargetViewController.m
//  TimeKick
//
//  Created by Beyer, Paul on 1/30/16.
//  Copyright © 2016 What Time Is It?. All rights reserved.
//

#import "TargetViewController.h"

@implementation TargetViewController

- (void)updateLabels {
    [self updateLabelsForRunModeCountdown];
    [self updateTargetLabel];
    
    NSDate *currentDate = [NSDate date];
    NSTimeInterval diff = [self.referenceDate timeIntervalSinceDate:currentDate];
    if (diff <= 11 &&  self.synth) {
        [self startFinalCountdown];
    }
    
    [self handleFavorites];
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
            self.dateTimePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, 0, self.clockModuleLabel.frame.size.width, self.clockModuleLabel.frame.size.height)];
            self.dateTimePicker.backgroundColor = [UIColor clearColor];
            self.dateTimePicker.clipsToBounds = YES;
            [self.dateTimePicker setMinimumDate:[NSDate date]];
            self.dateTimePicker.datePickerMode = UIDatePickerModeCountDownTimer;
            
            self.dateTimePicker.countDownDuration = [[AppSettings sharedSettings] savedFavoriteTimeInterval];
            CGFloat offset = 25;
            if ([[UIScreen mainScreen] bounds].size.height < 500) {
                offset = -50;
            } else if ([[UIScreen mainScreen] bounds].size.width == 320) {
                offset = 0;
            }
            self.dateTimePicker.center = CGPointMake(self.view.frame.size.width/2, self.clockModuleLabel.center.y+offset);
            [self.view addSubview:self.dateTimePicker];
            
            self.dateTimePicker.tintColor = [UIColor darkPurpleTextColor];
            //            [self.dateTimePicker setValue:[UIColor darkPurpleTextColor] forKeyPath:@"textColor"];
            //             SEL selector = NSSelectorFromString(@"setHighlightsToday:");
            //             NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDatePicker instanceMethodSignatureForSelector:selector]];
            //             BOOL no = NO;
            //             [invocation setSelector:selector];
            //             [invocation setArgument:&no atIndex:2];
            //             [invocation invokeWithTarget:self.dateTimePicker];
            
        }
        self.dateTimePicker.datePickerMode = UIDatePickerModeDateAndTime;
        
        
        [self.dateTimePicker setMinimumDate:[NSDate date]];
        self.dateTimePicker.alpha = 1.0f;
    }
}

- (void)start {
    self.shareButton.hidden = NO;
    [self.startStopButton setImage:[UIImage imageNamed:@"btn_off"] forState:UIControlStateNormal];

    self.dateTimePicker.alpha = 0.0f;
    self.referenceDate = self.dateTimePicker.date;
    
    self.audioSession = [AVAudioSession sharedInstance];
    [self.audioSession setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionDuckOthers error:nil];
    [self.audioSession setActive:YES error:nil];
    
    NSString *speechString;
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"h:mm"];
    speechString = [NSString stringWithFormat:NSLocalizedString(@"TARGET_START", nil),[formatter stringFromDate:self.referenceDate]];
    
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:speechString];
    utterance.rate = UTTERANCE_RATE;
    //utterance.volume = [[AppSettings sharedSettings] volumeLevel].floatValue/100;
    self.synth = [[AVSpeechSynthesizer alloc] init];
    self.synth.delegate = (id)self;
    [self.synth speakUtterance:utterance];
    
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
    
    [[AppSettings sharedSettings] setIsAlreadyRunning:YES];
    self.tabBarController.selectedViewController.tabBarItem.badgeValue = @"!";
    
    [FBSDKAppEvents logEvent:@"start" parameters:@{@"type":@"Target",@"reminderDuration":self.reminderDurationSpeech,@"timeOfDay":[AppSettings timeOfDayStringForDate:nil]}];
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
    
    NSString *remaining = [self hmsStringFromDuration:diff];
    
    if (!self.audioSession) {
        self.audioSession = [AVAudioSession sharedInstance];
        [self.audioSession setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionDuckOthers error:nil];
    }
    [self.audioSession setActive:YES error:nil];
    NSString *speechString = [NSString stringWithFormat:NSLocalizedString(@"REMAINING_REMINDER", nil),remaining];
    //if (minutes<=0 && (seconds == 0 || seconds == 1)) {
    //    speechString = NSLocalizedString(@"TIME_UP", nil);
    //}
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:speechString];
    utterance.rate = UTTERANCE_RATE;
    //utterance.volume = [[AppSettings sharedSettings] volumeLevel].floatValue/100;
    [self.synth speakUtterance:utterance];
    self.synth.delegate = self;
}

- (NSString *)stringFromTimeInterval:(NSTimeInterval)interval {
    NSInteger ti = (NSInteger)interval;
    NSInteger seconds = ti % 60;
    NSInteger minutes = (ti / 60) % 60;
    NSInteger hours = (ti / 3600);
    return [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hours, (long)minutes, (long)seconds];
}

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

- (BOOL)isFavorite {
    if (self.tabBarController.selectedIndex == [[AppSettings sharedSettings] savedFavoriteRunMode]  && [[AppSettings sharedSettings] savedFavoriteReminderInterval] > 0) {
        if (self.dateTimePicker.countDownDuration == [[AppSettings sharedSettings] savedFavoriteTimeInterval]) {
            return YES;
        }
    }
    
    return NO;
}


@end
