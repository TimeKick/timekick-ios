//
//  TimeSelectionViewController.m
//  What Time Is It?
//
//  Created by Beyer, Paul on 3/30/15.
//  Copyright (c) 2015 What Time Is It?. All rights reserved.
//

#import "TimeSelectionViewController.h"

@implementation TimeSelectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.foregroundView.layer.cornerRadius = 4.0f;
    self.submitButton.layer.cornerRadius = 4.0f;
    
    
    UILabel *hourLabel = [[UILabel alloc] initWithFrame:CGRectMake(42, self.dateTimerPickerView.frame.size.height / 2 - 15, 75, 30)];
    hourLabel.text = @"hour";
    [self.dateTimerPickerView addSubview:hourLabel];
    
    UILabel *minsLabel = [[UILabel alloc] initWithFrame:CGRectMake(42 + (self.view.frame.size.width / 3), self.dateTimerPickerView.frame.size.height / 2 - 15, 75, 30)];
    minsLabel.text = @"min";
    [self.dateTimerPickerView addSubview:minsLabel];
    
    UILabel *secsLabel = [[UILabel alloc] initWithFrame:CGRectMake(42 + ((self.view.frame.size.width / 3) * 2), self.dateTimerPickerView.frame.size.height / 2 - 15, 75, 30)];
    secsLabel.text = @"sec";
    [self.dateTimerPickerView addSubview:secsLabel];
    
    self.dateTimerPickerView.delegate = self;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    if (self.selectionMode == TimeSelectionModeInterval) {
        self.titleLabel.text = NSLocalizedString(@"TIME_SELECTION_TITLE_INTERVAL", nil);
    } else if (self.selectionMode == TimeSelectionModeCountdown) {
        self.titleLabel.text = NSLocalizedString(@"TIME_SELECTION_TITLE_COUNTDOWN", nil);
        if (self.initialTimeInterval > 0) {
            self.dateTimePicker.countDownDuration = self.initialTimeInterval;
        }
    } else if (self.selectionMode == TimeSelectionModeTarget) {
        self.titleLabel.text = NSLocalizedString(@"TIME_SELECTION_TITLE_TARGET", nil);
        self.dateTimePicker.datePickerMode = UIDatePickerModeDateAndTime;
        [self.dateTimePicker setMinimumDate:[NSDate date]];
        if (self.initialDate) {
            [self.dateTimePicker setDate:self.initialDate animated:YES];
        }
    }
}

- (IBAction)dismiss:(id)sender {
    [UIView animateWithDuration:0.5f animations:^{
        self.view.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [self.view removeFromSuperview];
    }];
}

- (IBAction)submitButtonPushed:(UIButton *)sender {
    //[self.delegate timerSelectedWithDuration:self.dateTimePicker.countDownDuration andReminderInterval:self.dateTimePicker.countDownDuration timerDate:self.dateTimePicker.date selectionMode:self.selectionMode];
    NSInteger interval = [self getPickerTime];
    [self.delegate timerSelectedWithDuration:interval andReminderInterval:interval timerDate:self.dateTimePicker.date selectionMode:self.selectionMode];
    
    [self dismiss:sender];
}

#pragma mark UIPickerViewDelegate
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 2;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if(component == 0)
        return 24;
    
    return 60;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    return 30;
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    UILabel *columnView = [[UILabel alloc] initWithFrame:CGRectMake(35, 0, self.view.frame.size.width/3 - 35, 30)];
    columnView.text = [NSString stringWithFormat:@"%lu", (long) row];
    columnView.textAlignment = NSTextAlignmentLeft;
    
    return columnView;
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (component == 0) {
        self.hours = row;
    } else if (component == 1) {
        self.mins = row;
    } else if (component == 2) {
        self.secs = row;
    }
}

-(NSInteger)getPickerTime {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitHour|NSCalendarUnitMinute fromDate:self.dateTimePicker.date];
    
    return (components.hour * 60 * 60 + components.minute * 60);
}

@end
