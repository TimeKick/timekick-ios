//
//  AppSettings.m
//  What Time Is It?
//
//  Created by Beyer, Paul on 3/30/15.
//  Copyright (c) 2015 What Time Is It?. All rights reserved.
//

#import "AppSettings.h"
#import <MediaPlayer/MediaPlayer.h>

#define SHOW_SECONDS_FLAG @"showsecondsflag"
#define VOLUME_LEVEL @"volumelevel"
#define FAVORITE_RUN_MODE @"runmode"
#define FAVORITE_TIME_INT @"timeinterval"
#define FAVORITE_REMINDER_INT   @"reminderinterval"
#define DID_SHOW_TOUR @"didshowtour"
#define LAST_REMINDER_INT   @"lastreminderinterval"
#define NUMBER_OF_LAUNCHES @"numberoflaunches"
#define DID_LEAVE_FEEDBACK @"didleavefeedback"

@implementation AppSettings

+ (id)sharedSettings
{
    static AppSettings *sharedSettings = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedSettings = [[self alloc] init];
        sharedSettings.numberOfLaunches++;
    });
    return sharedSettings;
}

- (void)setShowSeconds:(BOOL)showSeconds {
    [[NSUserDefaults standardUserDefaults] setBool:showSeconds forKey:SHOW_SECONDS_FLAG];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)showSeconds {
    return [[NSUserDefaults standardUserDefaults] boolForKey:SHOW_SECONDS_FLAG];
}

- (void)setSavedFavoriteRunMode:(NSInteger)savedFavoriteRunMode {
    [[NSUserDefaults standardUserDefaults] setInteger:savedFavoriteRunMode forKey:FAVORITE_RUN_MODE];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSInteger)savedFavoriteRunMode {
    return [[NSUserDefaults standardUserDefaults] integerForKey:FAVORITE_RUN_MODE];
}

- (void)setSavedFavoriteTimeInterval:(NSTimeInterval)savedFavoriteTimeInterval {
    [[NSUserDefaults standardUserDefaults] setDouble:savedFavoriteTimeInterval forKey:FAVORITE_TIME_INT];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSTimeInterval)savedFavoriteTimeInterval {
    return [[NSUserDefaults standardUserDefaults] doubleForKey:FAVORITE_TIME_INT];
}

- (void)setSavedFavoriteReminderInterval:(NSTimeInterval)savedFavoriteReminderInterval {
    [[NSUserDefaults standardUserDefaults] setDouble:savedFavoriteReminderInterval forKey:FAVORITE_REMINDER_INT];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSTimeInterval)savedFavoriteReminderInterval {
   return [[NSUserDefaults standardUserDefaults] doubleForKey:FAVORITE_REMINDER_INT];
}

- (void)setDidShowTour:(BOOL)didShowTour {
    [[NSUserDefaults standardUserDefaults] setBool:didShowTour forKey:DID_SHOW_TOUR];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)didShowTour {
    return [[NSUserDefaults standardUserDefaults] boolForKey:DID_SHOW_TOUR];
}

- (void)setNumberOfLaunches:(NSInteger)numberOfLaunches {
    [[NSUserDefaults standardUserDefaults] setInteger:numberOfLaunches forKey:NUMBER_OF_LAUNCHES];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSInteger)numberOfLaunches {
    return [[NSUserDefaults standardUserDefaults] integerForKey:NUMBER_OF_LAUNCHES];
}

- (void)setDidLeaveFeedback:(BOOL)didLeaveFeedback {
    [[NSUserDefaults standardUserDefaults] setBool:didLeaveFeedback forKey:DID_LEAVE_FEEDBACK];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)didLeaveFeedback {
    return [[NSUserDefaults standardUserDefaults] boolForKey:DID_LEAVE_FEEDBACK];
}

- (void)setVolumeLevel:(NSNumber *)volumeLevel {
    [[NSUserDefaults standardUserDefaults] setObject:volumeLevel forKey:VOLUME_LEVEL];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSNumber *)volumeLevel {
    NSNumber *vol = nil;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:VOLUME_LEVEL]) {
        vol = [[NSUserDefaults standardUserDefaults] objectForKey:VOLUME_LEVEL];
    } else {
        vol = @(70);
    }
    
    [[MPMusicPlayerController systemMusicPlayer] setVolume:vol.floatValue/100];
    
    //Default
    return vol;
}

//Cache
- (void)setLastReminderInterval:(NSTimeInterval)lastReminderInterval {
    [[NSUserDefaults standardUserDefaults] setDouble:lastReminderInterval forKey:LAST_REMINDER_INT];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSTimeInterval)lastReminderInterval {
    return [[NSUserDefaults standardUserDefaults] doubleForKey:LAST_REMINDER_INT];
}

+ (NSString *)timeOfDayStringForDate:(NSDate *)date {
    NSString *timeOfDayString = @"Unknown";
    if (!date) {
        date = [NSDate date];
    }
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitHour fromDate:date];
    if (components.hour < 5) {
        timeOfDayString = @"Overnight";
    } else if (components.hour < 12) {
        timeOfDayString = @"Morning";
    } else if (components.hour < 17) {
        timeOfDayString = @"Afternoon";
    } else if (components.hour < 22) {
        timeOfDayString = @"Evening";
    } else if (components.hour <= 24) {
        timeOfDayString = @"Overnight";
    }
    
    return timeOfDayString;
}



@end
