//
//  SliderCell.h
//  TimeKick
//
//  Created by Beyer, Paul on 5/7/15.
//  Copyright (c) 2015 What Time Is It?. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SliderCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UISlider *slider;
- (IBAction)sliderChanged:(UISlider *)sender;

@end
