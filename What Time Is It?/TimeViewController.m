//
//  TimeViewController.m
//  TimeKick
//
//  Created by Beyer, Paul on 1/30/16.
//  Copyright © 2016 What Time Is It?. All rights reserved.
//

#import "TimeViewController.h"

@interface TimeViewController()<AVSpeechSynthesizerDelegate, TimeSelectionDelegate, UIAlertViewDelegate>
@end

@implementation TimeViewController

- (void)launchWithReferenceDate:(NSDate *)referenceDate reminderDuration:(NSTimeInterval)duration {
    self.referenceDate = referenceDate;
    if (duration == 0) {
        duration = 60;
    }
    self.reminderDuration = duration;
    [[AppSettings sharedSettings] setLastReminderInterval:self.reminderDuration];
    self.reminderDurationString = [self hmsStringFromDuration:duration];
    self.reminderDurationSpeech = [self hmsStringFromDuration:duration];

    [self start:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self updateLabels];
    
    self.favoritesButton.imageView.tintColor = [UIColor darkPurpleTextColor];
    
    self.availableIntervals = @[NSLocalizedString(@"1_MINUTE", nil),NSLocalizedString(@"5_MINUTES", nil),NSLocalizedString(@"10_MINUTES", nil)];
    self.availableIntervalDurationSpeech = @[NSLocalizedString(@"1_MINUTE_SPEECH", nil),NSLocalizedString(@"5_MINUTES_SPEECH", nil),NSLocalizedString(@"10_MINUTES_SPEECH", nil)];
    self.availableIntervalDurations = @[@60,@300,@600];
    
    self.everySecondTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(updateLabels) userInfo:nil repeats:YES];
    
    if ([[UIScreen mainScreen] bounds].size.height < 500) {
        self.topSpaceConstraint.constant = 50;
    }
    
    self.shareButton.layer.borderColor = self.shareButton.titleLabel.textColor.CGColor;
    self.shareButton.layer.borderWidth = 1.5f;
    self.shareButton.layer.cornerRadius = 8.0f;
    self.shareButton.hidden = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillClose:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self updateLabels];
    
    if (![[AppSettings sharedSettings] didShowTour]) {
        @try {
            [self performSegueWithIdentifier:@"TourSegue" sender:self];
        }
        @catch (NSException *exception) {
            //Probably one of the subclasses so who cares
        }
    }
}

- (void)updateLabels {
    [self updateLabelsForRunModeRunningClock];
    [self handleFavorites];
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
    
    //if (self.nextReminderDateTime && _synth) {
    //    [self updateNextReminderLabel];
    //}
}

- (void)updateNextReminderLabel {
    self.nextReminderLabel.hidden = NO;
    self.changeIntervalButton.hidden = NO;
    self.remindingEveryLabel.hidden = NO;
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"h:mm a"];
    NSString *time = [formatter stringFromDate:self.nextReminderDateTime];
    
    self.nextReminderLabel.text = [NSString stringWithFormat:NSLocalizedString(@"NEXT_REMINDER", nil),time];
    //self.remindingEveryLabel.text = [NSString stringWithFormat:NSLocalizedString(@"REMINDER_EVERY", nil),self.reminderDurationSpeech];
}

- (IBAction)startStopButtonPushed:(UIButton *)sender {
    if (_synth) {
        [self stop];
        [self updateLabels];
    } else {
        if ([[AppSettings sharedSettings] isAlreadyRunning]) {
            [[[UIAlertView alloc] initWithTitle:@"Already Running" message:@"You can only run a single mode at a time." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
        } else {
            [self presentActionSheetOrPopOverFromSender:sender];
        }
    }
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
            [self setRecurringReminder];
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

- (void)setRecurringReminder {
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    NSDate *date = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute fromDate:date];
    components.day += 1;
    date = [calendar dateFromComponents:components];
    
    NSString *body = nil;
    switch (self.tabBarController.selectedIndex) {
        case 0:
            body = [NSString stringWithFormat:@"Would you like to launch Time mode again?"];
            break;
        case 1:
        {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setTimeStyle:NSDateFormatterShortStyle];
            body = [NSString stringWithFormat:@"Would you like to launch a Countdown mode for %@ again?",[formatter stringFromDate:self.referenceDate]];
        }
            break;
        case 2:
        {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setTimeStyle:NSDateFormatterShortStyle];
            body = [NSString stringWithFormat:@"Would you like to launch a %@ Target mode again?",[formatter stringFromDate:self.referenceDate]];
        }
            break;
        case 3:
            body = [NSString stringWithFormat:@"Would you like to launch Forward mode again?"];
            break;
        default:
            break;
    }
    NSString *urlString = [NSString stringWithFormat:@"tkapp://share?mode=%lu&reminderDuration=%.0f&referenceDate=%.0f",self.tabBarController.selectedIndex,self.reminderDuration,self.referenceDate.timeIntervalSince1970];
    
    UIMutableUserNotificationAction *notificationAction1 = [[UIMutableUserNotificationAction alloc] init];
    notificationAction1.identifier = @"Launch";
    notificationAction1.title = @"Launch";
    notificationAction1.activationMode = UIUserNotificationActivationModeForeground;
    notificationAction1.destructive = NO;
    notificationAction1.authenticationRequired = NO;
    
    UIMutableUserNotificationAction *notificationAction2 = [[UIMutableUserNotificationAction alloc] init];
    notificationAction2.identifier = @"Stop";
    notificationAction2.title = @"Stop Asking";
    notificationAction2.activationMode = UIUserNotificationActivationModeBackground;
    notificationAction2.destructive = YES;
    notificationAction2.authenticationRequired = NO;
    
    UIMutableUserNotificationCategory *notificationCategory = [[UIMutableUserNotificationCategory alloc] init];
    notificationCategory.identifier = @"Daily";
    [notificationCategory setActions:@[notificationAction1,notificationAction2] forContext:UIUserNotificationActionContextDefault];
    [notificationCategory setActions:@[notificationAction1,notificationAction2] forContext:UIUserNotificationActionContextMinimal];
    
    NSSet *categories = [NSSet setWithObjects:notificationCategory, nil];
    
    UIUserNotificationType notificationType = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
    UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:notificationType categories:categories];
    
    [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
    
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.fireDate = date;
    notification.category = @"Daily";
    notification.alertBody = body;
    notification.soundName = UILocalNotificationDefaultSoundName;
    notification.userInfo = @{@"url":urlString};
    notification.repeatInterval = NSCalendarUnitDay;
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
}

- (void)start {
    [self start:NO];
}

- (void)start:(BOOL)alreadyConfigured {
    self.shareButton.hidden = NO;
    [self.startStopButton setImage:[UIImage imageNamed:@"btn_off"] forState:UIControlStateNormal];
    
    self.audioSession = [AVAudioSession sharedInstance];
    [_audioSession setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionDuckOthers error:nil];
    [_audioSession setActive:YES error:nil];
    
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:[NSString stringWithFormat:@"Now reminding you every %@.",self.reminderDurationSpeech]];
    utterance.rate = UTTERANCE_RATE;
    //utterance.volume = [[AppSettings sharedSettings] volumeLevel].floatValue/100;
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
    
    self.clockModuleLabel.hidden = NO;
    self.dateTimePicker.alpha = 0.0f;
    
    [[AppSettings sharedSettings] setIsAlreadyRunning:YES];
    self.tabBarController.selectedViewController.tabBarItem.badgeValue = @"!";
    
    [FBSDKAppEvents logEvent:@"start" parameters:@{@"type":@"Time",@"reminderDuration":self.reminderDurationSpeech,@"timeOfDay":[AppSettings timeOfDayStringForDate:nil]}];
}


- (void)stop {
    self.shareButton.hidden = YES;
    [self.startStopButton setImage:[UIImage imageNamed:@"btn_on"] forState:UIControlStateNormal];
    
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
    
    [[AppSettings sharedSettings] setIsAlreadyRunning:NO];
    self.tabBarController.selectedViewController.tabBarItem.badgeValue = nil;
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
    _timeSelectionViewController.selectionMode = TimeSelectionModeInterval;
    
    
    //Animate
    _timeSelectionViewController.view.alpha = 0.0f;
    [self.view addSubview:_timeSelectionViewController.view];
    
    [UIView animateWithDuration:0.25f animations:^{
        _timeSelectionViewController.view.alpha = 1.0f;
    } completion:^(BOOL finished) {}];
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
    //utterance.volume = [[AppSettings sharedSettings] volumeLevel].floatValue/100;
    [_synth speakUtterance:utterance];
    _synth.delegate = self;
    
    self.nextReminderDateTime = [currentDate dateByAddingTimeInterval:self.reminderDuration];
}

- (NSString *)hmsStringFromDuration:(NSTimeInterval)duration {
    NSString *hString = @"", *mString = @"", *sString = @"";
    
    NSInteger ti = (NSInteger)duration;
    NSInteger seconds = ti % 60;
    NSInteger minutes = (ti / 60) % 60;
    NSInteger hours = (ti / 3600);
    
    if (self.reminderDuration <= 4) {
        return [NSString stringWithFormat:@"%2ld",(long)seconds];
    }
    
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


#pragma mark Final Countdown
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
            //utterance.volume = [[AppSettings sharedSettings] volumeLevel].floatValue/100;
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

#pragma mark Speech Sythesizer Delegate
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer
 didFinishSpeechUtterance:(AVSpeechUtterance *)utterance {
    if (!self.finalCountdownStarted) {
        [_audioSession setActive:NO error:nil];
    }
}

#pragma mark Favorites
- (IBAction)saveAsFavoriteButtonPushed:(UIButton *)sender {
    if ([[AppSettings sharedSettings] lastReminderInterval] <= 0) {
        [[[UIAlertView alloc] initWithTitle:@"Reminder Interval" message:@"You must start a timer and select a reminder interval before saving a favorite." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
        return;
    }
    [[AppSettings sharedSettings] setSavedFavoriteRunMode:self.tabBarController.selectedIndex];
    [[AppSettings sharedSettings] setSavedFavoriteTimeInterval:self.dateTimePicker.countDownDuration];
    [[AppSettings sharedSettings] setSavedFavoriteReminderInterval:[[AppSettings sharedSettings] lastReminderInterval]];
    [self updateLabels];

    CABasicAnimation *pulseAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    pulseAnimation.duration = .3;
    pulseAnimation.toValue = [NSNumber numberWithFloat:1.3];
    pulseAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    pulseAnimation.autoreverses = YES;
    pulseAnimation.repeatCount = 1;
    [self.saveAsFavoriteButton.layer addAnimation:pulseAnimation forKey:nil];
    
    NSString *type = @"Time";
    switch (self.tabBarController.selectedIndex) {
        case 0:
            type = @"Time";
            break;
        case 1:
            type = @"Countdown";
            break;
        case 2:
            type = @"Target";
            break;
        case 3:
            type = @"Forward";
            break;
        default:
            break;
    }
    
    [FBSDKAppEvents logEvent:@"saveFavorite" parameters:@{@"type":type}];
}

- (IBAction)favoritesButtonPushed:(id)sender {
    if ([[AppSettings sharedSettings] isAlreadyRunning]) {
        return [[[UIAlertView alloc] initWithTitle:@"Already Running" message:@"You can only run a single mode at a time." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
    }
    NSInteger index = [[AppSettings sharedSettings] savedFavoriteRunMode];
    [self.tabBarController setSelectedIndex:index];
    TimeViewController *vc = self.tabBarController.viewControllers[index];
    vc.reminderDuration = [[AppSettings sharedSettings] savedFavoriteReminderInterval];
    vc.dateTimePicker.countDownDuration = [[AppSettings sharedSettings] savedFavoriteTimeInterval];
    NSInteger minutes = vc.reminderDuration/60;
    vc.reminderDurationSpeech = [NSString stringWithFormat:@"%ld minutes",(long)minutes];
    [vc start];
    [FBSDKAppEvents logEvent:@"loadFavorite"];
}

- (void)handleFavorites {
    if ([self favoriteExists]) {
        self.favoritesButton.hidden = NO;
    } else {
        self.favoritesButton.hidden = YES;
    }
    
    if ([self isFavorite]) {
        [self.saveAsFavoriteButton setImage:[UIImage imageNamed:@"pin_fav"] forState:UIControlStateNormal];
    } else {
        [self.saveAsFavoriteButton setImage:[UIImage imageNamed:@"pin"] forState:UIControlStateNormal];
    }
}

- (BOOL)isFavorite {
    if (self.tabBarController.selectedIndex == [[AppSettings sharedSettings] savedFavoriteRunMode] && [[AppSettings sharedSettings] savedFavoriteReminderInterval] > 0) {
        return YES;
    }
    
    return NO;
//        if (self.tabBarController.selectedIndex == 1) {
//            if (self.dateTimePicker.countDownDuration == [[AppSettings sharedSettings] savedFavoriteTimeInterval] && [[AppSettings sharedSettings] lastReminderInterval] == [[AppSettings sharedSettings] savedFavoriteReminderInterval]) {
//                return YES;
//            }
//        }
//        if ([[AppSettings sharedSettings] lastReminderInterval] > 0 && [[AppSettings sharedSettings] lastReminderInterval] == [[AppSettings sharedSettings] savedFavoriteReminderInterval]) {
//            return YES;
//        }
//    }
    
    return NO;
}

- (IBAction)shareButtonPushed:(id)sender {
    NSString *string = @"TimeKick";
    //NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"tkapp://?mode=%lu&reminderDuration=%.0f&referenceDate=%.0f",self.tabBarController.selectedIndex,self.reminderDuration,self.referenceDate.timeIntervalSince1970]];
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.timekickap.com/share?mode=%lu&reminderDuration=%.0f&referenceDate=%.0f",self.tabBarController.selectedIndex,self.reminderDuration,self.referenceDate.timeIntervalSince1970]];
    
    UIActivityViewController *activityViewController =
    [[UIActivityViewController alloc] initWithActivityItems:@[string, URL]
                                      applicationActivities:nil];
    [self presentViewController:activityViewController
                                       animated:YES
                                     completion:^{
                                         // ...
                                     }];
}

- (BOOL)favoriteExists {
    if ([[AppSettings sharedSettings] savedFavoriteReminderInterval] > 0) {
        return YES;
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
        //utterance.volume = [[AppSettings sharedSettings] volumeLevel].floatValue/100;
        [_synth speakUtterance:utterance];
        _synth.delegate = self;
        
        UILocalNotification *notification = [[UILocalNotification alloc]init];
        notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:60*2];
        [notification setAlertBody:@"Remember to keep TimeKick open while you have an active timer."];
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    }
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


@end
