//
//  UIFont+WTCustomFont.m
//  What Time Is It?
//
//  Created by Beyer, Paul on 3/30/15.
//  Copyright (c) 2015 What Time Is It?. All rights reserved.
//

#import "UIFont+WTCustomFont.h"

@implementation UIFont (WTCustomFont)

+ (UIFont *)helveticaNeueRegularWithSize:(CGFloat)size {
    return [UIFont fontWithName:@"HelveticaNeue" size:size];
}

+ (UIFont *)helveticaNeueLightWithSize:(CGFloat)size {
    return [UIFont fontWithName:@"HelveticaNeue-Light" size:size];
}

+ (UIFont *)helveticaNeueMediumWithSize:(CGFloat)size {
    return [UIFont fontWithName:@"HelveticaNeue-Medium" size:size];
}

@end
