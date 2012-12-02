/*
     File: DateDiffCalculator.m
 Abstract: Subclass of NSObject that keeps two dates and their difference. The units that are considered in the difference are determined from four additional properties, doYear, doMonth, etc.
  Version: 1.2
 
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


#import "DateDiffCalculator.h"

@implementation DateDiffCalculator

@synthesize date1, date2, diff, doesEra, doesYear, doesMonth, doesWeek, doesDay;

/* We initialize all the properties in the init method.
*/
- (id)init {
    if (self = [super init]) {
        self.doesEra = self.doesYear = self.doesMonth = self.doesWeek = self.doesDay = YES;
        self.date1 = self.date2 = [NSDate date];    // Sets these to "now"
        [self computeDateDiff];			    // Let's start with a properly cleared diff
    }
    return self;
}

/* Deallocate allocated objects.
*/
- (void)dealloc {
    self.date1 = self.date2 = nil;  // This deallocates these instance variables
    self.diff = nil;                // This deallocates these instance variables
    [super dealloc];
}

/* This method computes the difference and stores the result.
*/
- (void)computeDateDiff {
    self.diff = [[NSCalendar currentCalendar] components:(self.doesEra ? NSEraCalendarUnit : 0) | (self.doesYear ? NSYearCalendarUnit : 0) | (self.doesMonth ? NSMonthCalendarUnit : 0) | (self.doesWeek ? NSWeekCalendarUnit : 0) | (self.doesDay ? NSDayCalendarUnit : 0) fromDate:self.date1 toDate:self.date2 options:0];
}

/* Action method to explicitly cause the difference to be recomputed.
*/
- (IBAction)computeDateDiff:(id)sender {
    [self computeDateDiff];
}

@end

