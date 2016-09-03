//
//  SliderCell.m
//  TimeKick
//
//  Created by Beyer, Paul on 5/7/15.
//  Copyright (c) 2015 What Time Is It?. All rights reserved.
//

#import "SliderCell.h"
#import "AppSettings.h"

@implementation SliderCell

- (IBAction)sliderChanged:(UISlider *)sender {
    if (sender.value <= 25) {
        sender.value = 25;
    }
    
    [[AppSettings sharedSettings] setVolumeLevel:@(sender.value)];
}

@end
