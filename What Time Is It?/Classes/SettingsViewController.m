//
//  SettingsViewController.m
//  What Time Is It?
//
//  Created by Beyer, Paul on 3/22/15.
//  Copyright (c) 2015 What Time Is It?. All rights reserved.
//

#import "SettingsViewController.h"
#import "AppSettings.h"
#import "WTUIHeader.h"
#import "SwitchCell.h"
#import "SliderCell.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>

@interface SettingsViewController() <UITableViewDataSource,UITableViewDelegate>
@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationBar setBackgroundImage:[UIImage imageNamed:@"WHATTIME_topsettingsbar"] forBarMetrics:UIBarMetricsDefault];
    [self.navigationBar setTitleTextAttributes:@{NSFontAttributeName:[UIFont helveticaNeueRegularWithSize:21],NSForegroundColorAttributeName:[UIColor purpleTextColor]}];
    
    CGRect navBarRect = self.navigationBar.frame;
    navBarRect.origin.y = [[UIScreen mainScreen] bounds].size.height;
    self.navigationBar.frame = navBarRect;
    
    CGRect tblRect = self.settingsTableView.frame;
    tblRect.origin.y = [[UIScreen mainScreen] bounds].size.height;
    self.settingsTableView.frame = tblRect;
    
    self.effectView.alpha = 0.0f;
    
    self.backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_backButton setImage:[[UIImage imageNamed:@"WHATTIME_iPad-backbutton_on"] imageWithTint:[UIColor purpleTextColor]] forState:UIControlStateNormal];
    _backButton.frame = CGRectMake(10, 6, 30, 30);
    [_backButton addTarget:self action:@selector(dismiss:) forControlEvents:UIControlEventTouchUpInside];
    [self.navigationBar addSubview:_backButton];
}

-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    [self setMaskTo:self.navigationBar byRoundingCorners:UIRectCornerTopLeft|UIRectCornerTopRight];
    [self setMaskTo:self.settingsTableView byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight];
    
    UIView *tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.settingsTableView.frame.size.width, 140)];
    tableFooterView.backgroundColor = [UIColor clearColor];
    
    UILabel *topLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, self.settingsTableView.frame.size.width-20, 20)];
    topLabel.text = @"TimeKick is the brainchild of Stacey-Ann Johnson.";
    topLabel.numberOfLines = 0;
    topLabel.textAlignment = NSTextAlignmentCenter;
    topLabel.textColor = [UIColor darkGrayColor];
    [topLabel sizeToFit];
    topLabel.frame = CGRectMake(10, 10, topLabel.frame.size.width, topLabel.frame.size.height);
    //[tableFooterView addSubview:topLabel];
    topLabel.center = CGPointMake(tableFooterView.frame.size.width/2, topLabel.center.y);
    
    UILabel *bottomLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, self.settingsTableView.frame.size.width-20, 20)];
    bottomLabel.text = @"Copyright © TimeKick\nAll Rights Reserved";
    bottomLabel.numberOfLines = 0;
    bottomLabel.font = [UIFont systemFontOfSize:15.0f];
    bottomLabel.textAlignment = NSTextAlignmentCenter;
    bottomLabel.textColor = [UIColor darkGrayColor];
    [bottomLabel sizeToFit];
    bottomLabel.frame = CGRectMake(10, tableFooterView.frame.size.height - bottomLabel.frame.size.height, bottomLabel.frame.size.width, bottomLabel.frame.size.height);
    [tableFooterView addSubview:bottomLabel];
    bottomLabel.center = CGPointMake(tableFooterView.frame.size.width/2, bottomLabel.center.y);
    
    UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"timekick_logo_full"]];
    logo.frame = CGRectMake(0, 0, 150, 90);
    logo.contentMode = UIViewContentModeScaleAspectFit;
    [tableFooterView addSubview:logo];
    logo.center = CGPointMake(tableFooterView.frame.size.width/2, (tableFooterView.frame.size.height/2)-20);
    
    self.settingsTableView.tableFooterView = tableFooterView;
}

- (IBAction)dismiss:(id)sender {
    [UIView animateWithDuration:0.5f animations:^{
        CGRect frame = _navigationBar.frame;
        frame.origin.y = self.view.frame.size.height;
        _navigationBar.frame = frame;
        
        frame = _settingsTableView.frame;
        frame.origin.y = self.view.frame.size.height;
        _settingsTableView.frame = frame;
        
        self.effectView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [self.view removeFromSuperview];
    }];
}

#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 4;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 1) {
        return 70.0;
    }
    
    return 45.0;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"SwitchCell";
    if (indexPath.row == 0) {
        SwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[SwitchCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        
        // Configure the cell...
        cell.textLabel.textColor = [UIColor darkPurpleTextColor];
        cell.textLabel.font = [UIFont helveticaNeueRegularWithSize:17.0f];
        cell.textLabel.text = @"View Seconds";
        
        cell.toggle.on = [[AppSettings sharedSettings] showSeconds];
        [cell.toggle addTarget:self action:@selector(toggleChanged:) forControlEvents:UIControlEventValueChanged];
        
        return cell;
    } else if (indexPath.row == 1) {
        static NSString *SliderCellIdentifier = @"SliderCell";
        
        SliderCell *cell = [tableView dequeueReusableCellWithIdentifier:SliderCellIdentifier];
        if (cell == nil) {
            cell = [[SliderCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:SliderCellIdentifier];
        }
        
        // Configure the cell...
        cell.textLabel.backgroundColor = [UIColor clearColor];
        cell.textLabel.textColor = [UIColor darkPurpleTextColor];
        cell.textLabel.font = [UIFont helveticaNeueRegularWithSize:17.0f];
        cell.textLabel.numberOfLines = 2;
        cell.textLabel.text = @"Speech/System Volume\n";
        //cell.slider.value = [[AppSettings sharedSettings] volumeLevel].floatValue;

        MPVolumeView *myVolumeView = [[MPVolumeView alloc] initWithFrame:cell.slider.frame];
        [cell.contentView addSubview:myVolumeView];
        myVolumeView.center = CGPointMake(self.settingsTableView.frame.size.width/2, myVolumeView.center.y);
        
        cell.slider.hidden = YES;

        //cell.toggle.on = [[AppSettings sharedSettings] showSeconds];
        
        return cell;
    }
    else if (indexPath.row == 2) {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
        cell.textLabel.textColor = [UIColor darkPurpleTextColor];
        cell.textLabel.font = [UIFont helveticaNeueRegularWithSize:17.0f];
        cell.textLabel.text = @"Leave Feedback";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        return cell;
    }
    else if (indexPath.row == 3) {
        SwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[SwitchCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        
        // Configure the cell...
        cell.textLabel.textColor = [UIColor darkPurpleTextColor];
        cell.textLabel.font = [UIFont helveticaNeueRegularWithSize:17.0f];
        cell.textLabel.numberOfLines = 2;
        cell.textLabel.text = @"Never Ask For Feedback";
        
        cell.toggle.on = [[AppSettings sharedSettings] didLeaveFeedback];
        [cell.toggle addTarget:self action:@selector(didChangeFeedback:) forControlEvents:UIControlEventValueChanged];
        
        return cell;

    }
    else if (indexPath.row == 4) {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
        cell.textLabel.textColor = [UIColor darkPurpleTextColor];
        cell.textLabel.font = [UIFont helveticaNeueRegularWithSize:17.0f];
        cell.textLabel.text = @"Load Favorite Setting";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        UIImageView *pin = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"pin"]];
        [cell.contentView addSubview:pin];
        pin.frame = CGRectMake(cell.frame.size.width - 10 - pin.frame.size.width, 0, pin.frame.size.width, pin.frame.size.height);
        pin.center = CGPointMake(pin.center.x, 25.5);
        
        return cell;
    }
    
    return [[UITableViewCell alloc] init];
}

#pragma mark -
#pragma mark Table view delegate
-(void)didChangeFeedback:(UISwitch *)sender {
    [[AppSettings sharedSettings] setDidLeaveFeedback:sender.on];
    if (sender.on) {
        [FBSDKAppEvents logEvent:@"neverLeaveFeedback" parameters:@{@"value":@"ON"}];
    } else {
        [FBSDKAppEvents logEvent:@"neverLeaveFeedback" parameters:@{@"value":@"OFF"}];
    }
}

- (void)toggleChanged:(UISwitch *)sender {
    [[AppSettings sharedSettings] setShowSeconds:sender.on];
    if (sender.on) {
        [FBSDKAppEvents logEvent:@"showSeconds" parameters:@{@"value":@"ON"}];
    } else {
        [FBSDKAppEvents logEvent:@"showSeconds" parameters:@{@"value":@"OFF"}];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row==2) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.timekickap.com/support/"]];
        [FBSDKAppEvents logEvent:@"leaveFeedback" parameters:@{@"from":@"Settings"}];
        
    } else if (indexPath.row == 4) {
        if ([[AppSettings sharedSettings] savedFavoriteReminderInterval] > 0) {
            [self.tabBarController setSelectedIndex:[[AppSettings sharedSettings] savedFavoriteRunMode]];
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Favorite" message:@"This retrieves your favorites. Please save a favorite scenario first." delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alertView show];
        }
    }
}

/*
 - (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
 return 44.0f;
 }
 */


#pragma mark UI Helper Methods
- (void)setMaskTo:(UIView*)view byRoundingCorners:(UIRectCorner)corners {
    UIBezierPath *rounded = [UIBezierPath bezierPathWithRoundedRect:view.bounds
                                                  byRoundingCorners:corners
                                                        cornerRadii:CGSizeMake(4.0, 4.0)];
    CAShapeLayer *shape = [[CAShapeLayer alloc] init];
    [shape setPath:rounded.CGPath];
    view.layer.mask = shape;
}

@end
