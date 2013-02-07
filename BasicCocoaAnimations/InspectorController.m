/*
     File: InspectorController.m 
 Abstract: Header file for the Inspector window controller. 
  Version: 1.1 
  
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
  
 Copyright (C) 2011 Apple Inc. All Rights Reserved. 
  
 */

#import "InspectorController.h"


@implementation InspectorController

-(id)init {
    self = [super initWithWindowNibName:@"Inspector"];
    return self;
}

-(void)dealloc {
    [fadeTimer release];
    [super dealloc];
}


-(void)setFadeTimer:(NSTimer *)timer {
    if (fadeTimer != timer) {
	[fadeTimer invalidate];
	[fadeTimer release];
	fadeTimer = [timer retain];
    }
}


// When the window loads add the tracking area to catch mouse entered and mouse exited events
-(void)windowDidLoad {
    NSView *containingView = [[[self window] contentView] superview];
    
    NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:[containingView frame] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect owner:self userInfo:nil];
    [containingView addTrackingArea:area];
    [area release];
    
	NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:4.0 target:self selector:@selector(startFade:) userInfo:nil repeats:NO];
	[self setFadeTimer: timer];

}


// Mouse entered.  Turn off the fade timer, and animate to full opacity
-(void)mouseEntered:(NSEvent *)event {

	[self setFadeTimer: nil];
	[[[self window] animator] setAlphaValue:1.0];
}


// Mouse exited.  Set a timer to give a few seconds before we start fading.
// (Note that this effect could also be done with a custom CAKeyframeAnimation)
-(void)mouseExited:(NSEvent *)event {
	NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(startFade:) userInfo:nil repeats:NO];
	[self setFadeTimer: timer];
    
}

// After a delay start the fade.
-(void)startFade:(NSTimer *)timer {
	[NSAnimationContext beginGrouping];
	[[NSAnimationContext currentContext] setDuration:10.0];	
	[[[self window] animator] setAlphaValue:0.3];
	[NSAnimationContext endGrouping];
	
	[self setFadeTimer: nil];
}



@end
