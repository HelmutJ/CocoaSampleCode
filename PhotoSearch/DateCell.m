/*
     File: DateCell.m 
 Abstract: Provides a cell implementation that automatically truncates
 the date shown based on the cell size. It uses NSDateFormatter and 
 properly respects the user's date settings.
  
  Version: 1.6 
  
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple 
 Inc. ("Apple") in consideration of your agreement to the following 
 terms, and your use, installation, modification or redistribution of 
 this Apple software constitutes acceptance of these terms.  If you do 
 not agree with these terms, please do not use, install, modify or 
 redistribute this Apple software. 
  
 In consideration of your agreement to abide by the following terms, and 
 subject to these terms, Apple grants you a personal, non-exclusive 
 license, under Apple's copyrights in this original Apple software (the 
 "Apple Software"), to use, reproduce, modify and redistribute the Apple 
 Software, with or without modifications, in source and/or binary forms; 
 provided that if you redistribute the Apple Software in its entirety and 
 without modifications, you must retain this notice and the following 
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Inc. may 
 be used to endorse or promote products derived from the Apple Software 
 without specific prior written permission from Apple.  Except as 
 expressly stated in this notice, no other rights or licenses, express or 
 implied, are granted by Apple herein, including but not limited to any 
 patent rights that may be infringed by your derivative works or by other 
 works in which the Apple Software may be incorporated. 
  
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE 
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION 
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS 
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND 
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS. 
  
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL 
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, 
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED 
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), 
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE 
 POSSIBILITY OF SUCH DAMAGE. 
  
 Copyright (C) 2012 Apple Inc. All Rights Reserved. 
  
 */

#import "DateCell.h"

#define EXPANSION_FRAME_SUPPORT 1

@implementation DateCell

+ (void)initialize {
    // We want to use the new formatting behavior. This allows the user to change the date
    // settings in the Intl Preferences and have it work in our app.
    //
    [NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
}

- (NSMutableDictionary *)textAttributes {
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];

    NSColor *textColor = [self textColor];
	if ([self interiorBackgroundStyle] == NSBackgroundStyleDark) {
        textColor = [NSColor alternateSelectedControlTextColor];
    }
    [attributes setObject:textColor forKey:NSForegroundColorAttributeName];
    
    NSFont *font = [self font];
    if (font != nil) {
        [attributes setObject:font forKey:NSFontAttributeName];
    }
    
    NSMutableParagraphStyle *paraStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [paraStyle setAlignment:[self alignment]];
    [paraStyle setLineBreakMode:[self lineBreakMode]];
    [paraStyle setBaseWritingDirection:[self baseWritingDirection]];
    [attributes setObject:paraStyle forKey:NSParagraphStyleAttributeName];
    [paraStyle release];
    
    return attributes;
}

- (NSDateFormatter *)timeDateFormatter {
    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [dateFormatter setDateStyle:NSDateFormatterNoStyle];
    return dateFormatter;
}

- (NSDateFormatter *)dateFormatterForDetailLevel:(DateCellDetailLevel)detailLevel {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSDateFormatterStyle timeStyle = NSDateFormatterShortStyle;
    NSDateFormatterStyle dateStyle;
    switch (detailLevel) {
        case DateCellDetailFullDateAndTime: dateStyle = NSDateFormatterFullStyle; break;
        case DateCellDetailLongDateAndTime: dateStyle = NSDateFormatterLongStyle; break;
        case DateCellDetailMediumDateAndTime: dateStyle = NSDateFormatterMediumStyle; break;
        case DateCellDetailShortDateAndTime: dateStyle = NSDateFormatterShortStyle; break;
        case DateCellDetailShortDate: dateStyle = NSDateFormatterShortStyle; timeStyle = NSDateFormatterNoStyle; break;
        case DateCellDetailNumberOfDateFormats: NSAssert(NO, @"shouldn't get called");
    }
    [dateFormatter setDateStyle:dateStyle];
    [dateFormatter setTimeStyle:timeStyle];
    return [dateFormatter autorelease];
}

- (CGFloat)widthOfLongestDateStringWithLevel:(DateCellDetailLevel)detailLevel {
    CGFloat result = 0;
    NSTimeZone *timeZone = [NSTimeZone localTimeZone];
    NSDateFormatter *dateFormatter = [self dateFormatterForDetailLevel:detailLevel];
    // This code is rather tied to the gregorian date. We pick an arbitrary date, and
    // iterate through each of the days of the week and each of the months to find the
    // longest string for the given detail level. Because a person can customize
    // (via the intl prefs) the string, we need to iterate through each level for each item.
    //
    NSInteger weekDayCount = [[dateFormatter weekdaySymbols] count];
    if (weekDayCount == 0) weekDayCount= 7;
    // Find the longest week day
    NSInteger longestWeekDay = 1;
    for (NSInteger dayOfWeek = 1; dayOfWeek <= weekDayCount; dayOfWeek++) {
        NSDate *date = [NSCalendarDate dateWithYear:2006 month:1 day:dayOfWeek hour:12 minute:12 second:12 timeZone:timeZone];
        NSString *str = [dateFormatter stringFromDate:date];
        CGFloat length = [str sizeWithAttributes:[self textAttributes]].width;
        if (length > result) {
            result = length;
            longestWeekDay = dayOfWeek;
        }
    }
    
    NSInteger monthCount = [[dateFormatter monthSymbols] count];
    if (monthCount == 0) monthCount = 12;
    for (NSInteger month = 1; month <= monthCount; month++) {
        NSDate *date = [NSCalendarDate dateWithYear:2006 month:month day:longestWeekDay hour:12 minute:12 second:12 timeZone:timeZone];
        NSString *str = [dateFormatter stringFromDate:date];
        CGFloat length = [str sizeWithAttributes:[self textAttributes]].width;
        result = MAX(result, length);
    }
    
    return result;
}

- (NSString *)todayString {
    return NSLocalizedString(@"Today", @"Today title string");
}

- (NSString *)yesterdayString {
    return NSLocalizedString(@"Yesterday", @"Yesterday title string");
}


static BOOL gCalculatedDetailLevelWidths = NO;
static CGFloat gDetailLevelWidths[DateCellDetailNumberOfDateFormats];
static CGFloat gDetailNaturalWidths[DateCellDetailNumberOfTodayAndYesterdays];

- (void)updateDetailLevelWidths
{
    if (gCalculatedDetailLevelWidths) {
        return;
    }

    for (NSInteger i = 0; i < DateCellDetailNumberOfDateFormats; i++) {
        gDetailLevelWidths[i] = [self widthOfLongestDateStringWithLevel:i];
    }
    
    // Fill out the yesterday/today strings with some sample times.
    NSDateFormatter *dateFormatter = [self timeDateFormatter];
    NSString *timeSample = [dateFormatter stringFromDate:[NSDate date]];

    NSString *todayString = [self todayString];
    NSString *yesterdayString = [self yesterdayString];

    NSString *yesterdayWithTime = [NSString stringWithFormat:@"%@, %@", yesterdayString, timeSample];
    NSString *todayWithTime = [NSString stringWithFormat:@"%@, %@", todayString, timeSample];
    
    gDetailNaturalWidths[DateCellDetailYesterdayAndTime] = [yesterdayWithTime sizeWithAttributes:[self textAttributes]].width;
    gDetailNaturalWidths[DateCellDetailYesterday] = [yesterdayString sizeWithAttributes:[self textAttributes]].width;
    gDetailNaturalWidths[DateCellDetailTodayAndTime] = [todayWithTime sizeWithAttributes:[self textAttributes]].width;
    gDetailNaturalWidths[DateCellDetailToday] = [todayString sizeWithAttributes:[self textAttributes]].width;

    gCalculatedDetailLevelWidths = YES;
}

- (void)updateDetailLevel {
    [self updateDetailLevelWidths];

    // Find something that fits well for our current width..
    iDateDetailLevel = DateCellDetailNumberOfDateFormats - 1;
    for (DateCellDetailLevel i = 0; i < DateCellDetailNumberOfDateFormats; i++) {
        if (gDetailLevelWidths[i] <= iLastWidth) {
            iDateDetailLevel = i;
            break;
        }
    }

    // Check to see if we can use the yesterday/today option
    iTodayAndYesterdayLevel = DateCellDetailNumberOfTodayAndYesterdays;
    for (DateCellDetailTodayAndYesterdays i = 0; i < DateCellDetailNumberOfTodayAndYesterdays; i++) {
        // If we have one greater than it, then we can't use it
        if (gDetailNaturalWidths[i] > iLastWidth) {
            break;
        } else {
            iTodayAndYesterdayLevel = i;
        }
    }
}

- (NSString *)dateStringToDraw {
    NSString *stringToDraw = nil;
    
    NSDate *date = [self objectValue];
    
    // Check to see if we should use today/yesterday
    if (iTodayAndYesterdayLevel != DateCellDetailNumberOfTodayAndYesterdays) {
        NSCalendarDate *calendarDate = [NSCalendarDate dateWithTimeIntervalSinceReferenceDate:[date timeIntervalSinceReferenceDate]];
        NSCalendarDate *todaysDate = [NSCalendarDate calendarDate];
        if ([calendarDate yearOfCommonEra] == [todaysDate yearOfCommonEra]) {
            if ([calendarDate dayOfYear] == [todaysDate dayOfYear]) {
                if (iLastWidth >= gDetailNaturalWidths[DateCellDetailTodayAndTime]) {
                    stringToDraw = [NSString stringWithFormat:@"%@, %@", [self todayString], [[self timeDateFormatter] stringFromDate:date]];
                } else if (iLastWidth >= gDetailNaturalWidths[DateCellDetailToday]) {
                    stringToDraw = [self todayString];
                }
            } else if ([calendarDate dayOfYear] == ([todaysDate dayOfYear] - 1)) {
                if (iLastWidth >= gDetailNaturalWidths[DateCellDetailYesterdayAndTime]) {
                    stringToDraw = [NSString stringWithFormat:@"%@, %@", [self yesterdayString], [[self timeDateFormatter] stringFromDate:date]];
                } else if (iLastWidth >= gDetailNaturalWidths[DateCellDetailYesterday]) {
                    stringToDraw = [self yesterdayString];
                }
            }
        }
    }
    if (stringToDraw == nil) {
        stringToDraw = [[self dateFormatterForDetailLevel:iDateDetailLevel] stringFromDate:date];
    }
    return stringToDraw;
} 
 
- (void)drawInteriorWithFrame:(NSRect)bounds inView:(NSView *)controlView {

    if (iLastWidth != NSWidth(bounds)) {
        iLastWidth = NSWidth(bounds);
        [self updateDetailLevel];
    } 

    bounds = NSInsetRect(bounds, 2, 2);

    // First, if we don't have a valid date, then draw "---", like what finder does
    if (![[self objectValue] isKindOfClass:[NSDate class]]) 
    {
        NSAttributedString *unknownDateString = [[NSMutableAttributedString alloc] initWithString:@"---" attributes:[self textAttributes]];
        [unknownDateString drawInRect:bounds];
        [unknownDateString release];
        return;
    }

    NSString *stringToDraw = [self dateStringToDraw];
    [stringToDraw drawInRect:bounds withAttributes:[self textAttributes]];
}

#if EXPANSION_FRAME_SUPPORT

// Expansion tool tip support
- (NSRect)expansionFrameWithFrame:(NSRect)cellFrame inView:(NSView *)view {
    // Always use the "full size" level
    iDateDetailLevel = DateCellDetailFullDateAndTime;
    iTodayAndYesterdayLevel = DateCellDetailNumberOfTodayAndYesterdays;
    iLastWidth = 0; // Force a recalc of the above values when really drawing

    NSString *stringToDraw = [self dateStringToDraw];

    NSSize stringSize = [stringToDraw sizeWithAttributes:[self textAttributes]];
    if (stringSize.width > NSWidth(cellFrame)) {
        // It isn't big enough, so return a modified rect that will contain the right size.
        cellFrame.size = stringSize;
        cellFrame.size.width += 4;
        cellFrame.size.height += 4;
    } else {
        cellFrame = NSZeroRect;
    }
    return cellFrame;
}

- (void)drawWithExpansionFrame:(NSRect)cellFrame inView:(NSView *)view {
    iDateDetailLevel = DateCellDetailFullDateAndTime;
    iTodayAndYesterdayLevel = DateCellDetailNumberOfTodayAndYesterdays;
    iLastWidth = NSWidth(cellFrame);
    [super drawWithExpansionFrame:cellFrame inView:view];
    iLastWidth = 0;
}

#endif

@end
