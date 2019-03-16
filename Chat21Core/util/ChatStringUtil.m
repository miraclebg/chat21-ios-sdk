//
//  ChatStringUtil.m
//  chat21
//
//  Created by Andrea Sponziello on 07/12/2017.
//  Copyright © 2017 Frontiere21. All rights reserved.
//

#import "ChatStringUtil.h"
#import "Common.h"

@implementation ChatStringUtil

+(NSString *)timeFromNowToString:(NSDate *)date {
    /*
     Model from Facebook
     
     a few seconds ago
     about a minute ago
     15 minutes ago
     about one hour ago
     2 hours ago
     23 hours ago
     Yesterday at 5:07pm TODO
     October 11
     */
    NSString *timeMessagePart;
    NSString *unitMessagePart;
    NSDate *now = [[NSDate alloc] init];
    double nowInSeconds = [now timeIntervalSince1970];
    double startDateInSeconds = [date timeIntervalSince1970];
    double secondsElapsed = nowInSeconds - startDateInSeconds;
    if (secondsElapsed < 60) {
        timeMessagePart = [LI18n localizedString:@"FewSecondsAgoLKey"];
        unitMessagePart = @"";
    }
    else if (secondsElapsed >= 60 && secondsElapsed <120) {
        timeMessagePart = [LI18n localizedString:@"AboutAMinuteAgoLKey"];
        unitMessagePart = @"";
    }
    else if (secondsElapsed >= 120 && secondsElapsed <3600) {
        int minutes = secondsElapsed / 60.0;
        timeMessagePart = [[NSString alloc] initWithFormat:@"%d ", minutes];
        unitMessagePart = [LI18n localizedString:@"MinutesAgoLKey"];
    }
    else if (secondsElapsed >=3600 && secondsElapsed < 5400) {
        timeMessagePart = [LI18n localizedString:@"AboutAnHourAgoLKey"];
        unitMessagePart = @"";
    }
    else if (secondsElapsed >= 5400 && secondsElapsed <= 86400) {
        int hours = secondsElapsed / 3600.0;
        timeMessagePart = [[NSString alloc] initWithFormat:@"%d ", hours];
        unitMessagePart = [LI18n localizedString:@"HoursAgoLKey"];
    }
    else {
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        // http://mobiledevelopertips.com/cocoa/date-formatters-examples-take-2.html
        [dateFormat setDateFormat:[LI18n localizedString:@"TimeToStringDateFormat"]];
        NSString *dateString = [[dateFormat stringFromDate:date] capitalizedString];
        //        timeMessagePart = [NSString stringWithFormat:@"%@ %@",NSLocalizedString(@"theLKey", nil), dateString];
        timeMessagePart = dateString;
        unitMessagePart = @"";
    }
    NSString *timeString = [[NSString alloc] initWithFormat:@"%@%@", timeMessagePart, unitMessagePart];
    return timeString;
}

+ (NSInteger)daysBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime
{
    NSDate *fromDate;
    NSDate *toDate;
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    [calendar rangeOfUnit:NSCalendarUnitDay startDate:&fromDate
                 interval:NULL forDate:fromDateTime];
    [calendar rangeOfUnit:NSCalendarUnitDay startDate:&toDate
                 interval:NULL forDate:toDateTime];
    
    NSDateComponents *difference = [calendar components:NSCalendarUnitDay
                                               fromDate:fromDate toDate:toDate options:0];
    
    return [difference day];
}

@end
