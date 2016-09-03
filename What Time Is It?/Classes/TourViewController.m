//
//  TourViewController.m
//  TimeKick
//
//  Created by Beyer, Paul on 1/31/16.
//  Copyright © 2016 What Time Is It?. All rights reserved.
//

#import "TourViewController.h"
#import "AppSettings.h"

@implementation TourViewController

- (IBAction)dismissTour:(id)sender {
    [[AppSettings sharedSettings] setDidShowTour:YES];
    
    [self dismissViewControllerAnimated:YES completion:^{}];
}

@end
