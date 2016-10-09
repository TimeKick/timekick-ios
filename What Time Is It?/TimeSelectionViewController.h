//
//  TimeSelectionViewController.h
//  What Time Is It?
//
//  Created by Beyer, Paul on 3/30/15.
//  Copyright (c) 2015 What Time Is It?. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, TimeSelectionMode) {
    TimeSelectionModeInterval,
    TimeSelectionModeCountdown,
    TimeSelectionModeTarget
};

@protocol TimeSelectionDelegate <NSObject>
- (void)timerSelectedWithDuration:(NSTimeInterval)duration andReminderInterval:(NSTimeInterval)interval timerDate:(NSDate *)timerDate selectionMode:(TimeSelectionMode)selectionMode;
@end

@interface TimeSelectionViewController : UIViewController <UIPickerViewDelegate>

@property NSInteger hours;
@property NSInteger mins;
@property NSInteger secs;

@property (nonatomic, strong) NSDate *initialDate;
@property (nonatomic, assign) NSTimeInterval initialTimeInterval;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (assign) IBOutlet id<TimeSelectionDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIView *foregroundView;
@property (strong, nonatomic) IBOutlet UIDatePicker *dateTimePicker;
@property (weak, nonatomic) IBOutlet UIPickerView *dateTimerPickerView;
@property (weak, nonatomic) IBOutlet UIButton *submitButton;
@property (nonatomic, assign) TimeSelectionMode selectionMode;
- (IBAction)submitButtonPushed:(UIButton *)sender;

@end
