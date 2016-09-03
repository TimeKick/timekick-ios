//
//  TimeKickTests.m
//  TimeKickTests
//
//  Created by Beyer, Paul on 3/15/16.
//  Copyright © 2016 What Time Is It?. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "AppSettings.h"

@interface TimeKickTests : XCTestCase

@end

@implementation TimeKickTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testTimeOfDayString {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond fromDate:[NSDate date]];
    NSDate *date = nil;
    
    //Test 4 AM
    components.hour = 4;
    components.minute = 0;
    components.second = 0;
    date = [calendar dateFromComponents:components];
    XCTAssertEqualObjects(@"Overnight", [AppSettings timeOfDayStringForDate:date]);
    
    //Test 10:30 AM
    components.hour = 10;
    components.minute = 30;
    components.second = 0;
    date = [calendar dateFromComponents:components];
    XCTAssertEqualObjects(@"Morning", [AppSettings timeOfDayStringForDate:date]);

    //Test 11:59 AM
    components.hour = 11;
    components.minute = 59;
    components.second = 0;
    date = [calendar dateFromComponents:components];
    XCTAssertEqualObjects(@"Morning", [AppSettings timeOfDayStringForDate:date]);
    
    //Test 1 PM
    components.hour = 13;
    components.minute = 0;
    components.second = 0;
    date = [calendar dateFromComponents:components];
    XCTAssertEqualObjects(@"Afternoon", [AppSettings timeOfDayStringForDate:date]);
    
    //Test 6 PM
    components.hour = 18;
    components.minute = 0;
    components.second = 0;
    date = [calendar dateFromComponents:components];
    XCTAssertEqualObjects(@"Evening", [AppSettings timeOfDayStringForDate:date]);
}

@end
