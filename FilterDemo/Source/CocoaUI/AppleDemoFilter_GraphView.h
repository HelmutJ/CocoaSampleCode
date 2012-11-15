/*
     File: AppleDemoFilter_GraphView.h 
 Abstract:  AppleDemoFilter_GraphView.h  
  Version: 1.01 
  
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
#import <Cocoa/Cocoa.h>
#import "Filter.h"

/************************************************************************************************************/
/* NOTE: It is important to rename ALL ui classes when using the XCode Audio Unit with Cocoa View template	*/
/*		 Cocoa has a flat namespace, and if you use the default filenames, it is possible that you will		*/
/*		 get a namespace collision with classes from the cocoa view of a previously loaded audio unit.		*/
/*		 We recommend that you use a unique prefix that includes the manufacturer name and unit name on		*/
/*		 all objective-C source files. You may use an underscore in your name, but please refrain from		*/
/*		 starting your class name with an undescore as these names are reserved for Apple.					*/
/************************************************************************************************************/

@interface AppleDemoFilter_GraphView : NSView
{	
	NSRect	mGraphFrame;		// This is the frame of the drawing area of the view
	float	mActiveWidth;		// The usable portion of the graph
	NSPoint mEditPoint;			// This is the current location in the drawing area that is active
	BOOL	mMouseDown;			// True if the mouse is currently down
	
	NSColor *curveColor;		// the current color of the graph curve
	
	NSImage *mBackgroundCache;	// An image cache of the background so that we don't have to re-draw the grid lines and labels all the time
	
	float mRes;					// internal copy of the resonance value
	float mFreq;				// internal copy of the frequency value
	
	NSBezierPath *mCurvePath;	// The bezier path that is used to draw the curve.
	
	NSDictionary *mDBAxisStringAttributes;		// Text attributes used to draw the strings on the db axis
	NSDictionary *mFreqAxisStringAttributes;	// Text attributes used to draw the strings on the frequency axis
}

-(void) setRes: (float) res;	// sets the graph's internal resonance value (to match the au)
-(void) setFreq: (float) freq;	// sets the graphs' internal frequency value (to match the au

-(float)getRes;					// gets the graph's internal resonance value (so the au can match the graph)
-(float)getFreq;				// gets the graph's internal frequency value (so the au can match the graph)

-(double) locationForFrequencyValue: (double) value;	// converts a frequency value to the pixel coordinate in the graph
-(double) locationForDBValue: (double) value;			// converts a db value to the pixel coordinate in the graph

-(FrequencyResponse *) prepareDataForDrawing: (FrequencyResponse *) data;	// prepares the data for drawing by initializing frequency fields based on values on pixel boundaries
-(void) plotData: (FrequencyResponse *) data;								// draws the curve data
-(void) disableGraphCurve;													// update the view, but don't draw the curve (used when the AU is not initialized and the curve can not be retrieved)

-(void) handleBeginGesture;		// called when parameter automation started
-(void) handleEndGesture;		// called when parameter automation finished

@end
