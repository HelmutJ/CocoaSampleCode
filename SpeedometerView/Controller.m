/*
     File: Controller.m 
 Abstract: Main window's controller. 
  Version: 1.3 
  
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


#import "Controller.h"

@implementation Controller

	/* keys used in our preset dictionaries */
NSString *kCurveKey = @"curve";
NSString *kLevelKey = @"speed";
NSString *kTicksKey = @"ticks";
NSString *kTitleKey = @"title";

@synthesize presetButtonOne;
@synthesize presetButtonTwo;
@synthesize presetButtonThree;
@synthesize presetOneValues;
@synthesize presetTwoValues;
@synthesize presetThreeValues;

- (void)awakeFromNib {

	[NSApp setDelegate: self];

		/* set the timings for the preset buttons */
	[presetButtonOne setPeriodicDelay:1.0 interval:60.0];
	[presetButtonTwo setPeriodicDelay:1.0 interval:60.0];
	[presetButtonThree setPeriodicDelay:1.0 interval:60.0];
	
		/* set up some default preset values */
	 presetOneValues = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
							[NSNumber numberWithFloat:90.0], kCurveKey,
							[NSNumber numberWithFloat:33.0], kLevelKey,
							[NSNumber numberWithInt:14], kTicksKey,
							nil];
	 presetTwoValues = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
							[NSNumber numberWithFloat:30.0], kCurveKey,
							[NSNumber numberWithFloat:56.0], kLevelKey,
							[NSNumber numberWithInt:9], kTicksKey,
							nil];
	 presetThreeValues = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
							[NSNumber numberWithFloat:75.0], kCurveKey,
							[NSNumber numberWithFloat:89.0], kLevelKey,
							[NSNumber numberWithInt:14], kTicksKey,
							nil];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
	return YES;
}

- (void)savePreset:(NSButton *)theButton toStore:(NSDictionary **)presetValues {
		
		/* set the title to acknowledge that we're setting the preset */
	NSString *savedTitle = [theButton title];
	[theButton setTitle: @"SET"];
	[*presetValues release];
	*presetValues = [[[NSDictionary alloc] initWithObjectsAndKeys:
						[NSNumber numberWithFloat:[speedView curvature]], kCurveKey,
						[NSNumber numberWithFloat:[speedView speed]], kLevelKey,
						[NSNumber numberWithInt:[speedView ticks]], kTicksKey,
						savedTitle, kTitleKey,
						nil] autorelease];
}

- (void)gotoPreset:(NSDictionary *)presetValues forButton:(NSButton *)theButton {

	[speedView setCurvature: [[presetValues objectForKey:kCurveKey] floatValue]];
	[speedView setSpeed: [[presetValues objectForKey:kLevelKey] floatValue]];
	[speedView setTicks: [[presetValues objectForKey:kTicksKey] intValue]];
		/* call the set speed action handler to set the parameters for the
		view and force a redraw */
	NSString *theTitle = [presetValues objectForKey:kTitleKey];
	if ( theTitle != nil ) {
			/* set the title back to normal. */
		[theButton setTitle: theTitle];
	}
}

- (IBAction)presetOne:(id)sender {
		/* if the current event type is NSPeriodic when our action message
		handler is called, then the mouse is being held down.  In this case,
		we set the preset to the current values displayed on the sliders.  */
	if ( [[NSApp currentEvent] type] == NSPeriodic ) {
		
		NSMutableDictionary *presetValues = nil;
        [self savePreset: presetButtonOne toStore:&presetValues];
        self.presetOneValues = presetValues;

	} else {
			/* otherwise this is a click on our button so we should
			set the sliders to the values we have stored for this preset. */
		[self gotoPreset: presetOneValues forButton: presetButtonOne];
	}
}

- (IBAction)presetTwo:(id)sender {
	
	if ( [[NSApp currentEvent] type] == NSPeriodic ) {
		
		NSMutableDictionary *presetValues = nil;
        [self savePreset:presetButtonTwo toStore:&presetValues];
        self.presetTwoValues = presetValues;

	} else {

		[self gotoPreset:presetTwoValues forButton:presetButtonTwo];
	}
}

- (IBAction)presetThree:(id)sender {
	
	if ( [[NSApp currentEvent] type] == NSPeriodic ) {
		
		NSMutableDictionary *presetValues = nil;
        [self savePreset:presetButtonThree toStore:&presetValues];
        self.presetThreeValues = presetValues;

	} else {

		[self gotoPreset:presetThreeValues forButton:presetButtonThree];
	}
}

- (void)dealloc
{
    self.presetOneValues = nil;
    self.presetTwoValues = nil;
    self.presetThreeValues = nil;
    
    [super dealloc];
}

@end
