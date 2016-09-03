//
//  SwitchCell.h
//  What Time Is It?
//
//  Created by Beyer, Paul on 3/30/15.
//  Copyright (c) 2015 What Time Is It?. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SwitchCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UISwitch *toggle;
- (IBAction)toggleChanged:(UISwitch *)sender;

@end
