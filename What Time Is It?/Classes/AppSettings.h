//
//  AppSettings.h
//  What Time Is It?
//
//  Created by Beyer, Paul on 3/30/15.
//  Copyright (c) 2015 What Time Is It?. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AppSettings : NSObject

+ (id)sharedSettings;

@property(nonatomic,assign) BOOL isAlreadyRunning;

@property(nonatomic,assign) BOOL showSeconds;
@property(nonatomic,strong) NSNumber *volumeLevel;

@property(nonatomic,assign) NSInteger savedFavoriteRunMode;
@property(nonatomic,assign) NSTimeInterval savedFavoriteTimeInterval;
@property(nonatomic,assign) NSTimeInterval savedFavoriteReminderInterval;
@property(nonatomic,assign) BOOL didShowTour;

@property(nonatomic,assign) NSInteger numberOfLaunches;
@property(nonatomic,assign) BOOL didLeaveFeedback;

//Cache
@property(nonatomic,assign) NSTimeInterval lastReminderInterval;

+ (NSString *)timeOfDayStringForDate:(NSDate *)date;

@end
