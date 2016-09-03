//
//  UIColor+WTCustomColor.m
//  What Time Is It?
//
//  Created by Beyer, Paul on 3/30/15.
//  Copyright (c) 2015 What Time Is It?. All rights reserved.
//

#import "UIColor+WTCustomColor.h"

@implementation UIColor (WTCustomColor)

+ (UIColor *)darkPurpleTextColor {
    return [UIColor colorWithHexString:@"562E58"];
}

+ (UIColor *)purpleTextColor {
    return [UIColor colorWithRed:89.0f/255.0 green:0.0f blue:218.0f/255.0 alpha:1.0f];
}

//9c5f9e
+ (UIColor *)lightPurpleTextColor {
    return [self colorWithHexString:@"9c5f9e"];
}

+ (UIColor *)grayTextColor {
    return [UIColor colorWithRed:215.0f/255.0 green:212.0f blue:237.0f/255.0 alpha:1.0f];
}

+ (UIColor*)colorWithHexString:(NSString*)hex
{
    NSString *cString = [[hex stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    
    // String should be 6 or 8 characters
    if ([cString length] < 6) return [UIColor grayColor];
    
    // strip 0X if it appears
    if ([cString hasPrefix:@"0X"]) cString = [cString substringFromIndex:2];
    
    if ([cString length] != 6) return  [UIColor grayColor];
    
    // Separate into r, g, b substrings
    NSRange range;
    range.location = 0;
    range.length = 2;
    NSString *rString = [cString substringWithRange:range];
    
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    
    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    return [UIColor colorWithRed:((float) r / 255.0f)
                           green:((float) g / 255.0f)
                            blue:((float) b / 255.0f)
                           alpha:1.0f];
}


@end
