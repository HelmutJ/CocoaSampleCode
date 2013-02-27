/*
 
 File: DrawProcs.c
 
 Abstract: //	This file contains the functions that draw the content
		   //   in the windows.
 
 Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Computer, Inc. ("Apple") in consideration of your agreement to the
 following terms, and your use, installation, modification or
 redistribution of this Apple software constitutes acceptance of these
 terms.  If you do not agree with these terms, please do not use,
 install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Computer,
 Inc. may be used to endorse or promote products derived from the Apple
 Software without specific prior written permission from Apple.  Except
 as expressly stated in this notice, no other rights or licenses, express
 or implied, are granted by Apple herein, including but not limited to
 any patent rights that may be infringed by your derivative works or by
 other works in which the Apple Software may be incorporated.
 
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
 
 Copyright © 2005 Apple Computer, Inc., All Rights Reserved
 
 */ 


#include "DrawProcs.h"
#include "arcs.h"
#include "ovals.h"
#include "rects.h"

/*
ArcsDrawEventHandler : Handles the draw events for the "Arcs" window.

Parameter DescriptionsinHandler : A reference to the current handler call chain. This is passed to your handler so that you can call CallNextEventHandler if you need to.
inEvent : The event that triggered this call.
inUserData : The application-specific data you passed in to InstallEventHandler.
*/
OSStatus ArcsDrawEventHandler (EventHandlerCallRef inHandler, EventRef inEvent, void* inUserData) {
	OSStatus status = eventNotHandledErr;
	CGContextRef context;
    CGRect r;
	
	//CallNextEventHandler in order to make sure the default handling of the inEvent 
	// (drawing the white background) happens
	status = CallNextEventHandler( inHandler, inEvent );
	require_noerr(status, CantCallNextEventHandler);
	
	// Get the CGContextRef
	status = GetEventParameter (inEvent, 
								kEventParamCGContextRef, 
								typeCGContextRef, 
								NULL, 
								sizeof (CGContextRef),
								NULL,
								&context);
	require_noerr(status, CantGetEventParameter);
	
	//  Draw the outer arcs in the left portion of the window
	r.size.height = 210;
    r.origin.x = 20;
    r.origin.y = 20;
    r.size.width = 210;
    frameArc(context, r, 0, 135);
    frameArc(context, r, 180 - 10, 20);
    frameArc(context, r, 225, 45);
    frameArc(context, r, 315 - 20, 40);
	
	// Draw the inner arcs in the left portion of the window
    r.size.height = 145;
    r.origin.x = 75;
    r.origin.y = 55;
    r.size.width = 100;
    frameArc(context, r, 0, 135);
    frameArc(context, r, 180 - 10, 20);
    frameArc(context, r, 225, 45);
    frameArc(context, r, 315 - 20, 40);
	
    /* Set the fill color to green. */
    CGContextSetRGBFillColor(context, 0, 1, 0, 1);
	
	// Draw and fill the outer arcs in the right portion of the window
    r.size.height = 210;
    r.origin.x = 270;
    r.origin.y = 20;
    r.size.width = 210;
    paintArc(context, r, 0, 135);
    paintArc(context, r, 180 - 10, 20);
    paintArc(context, r, 225, 45);
    paintArc(context, r, 315 - 20, 40);
	
    /* Set the fill color to yellow. */
    CGContextSetRGBFillColor(context, 1, 1, 0, 1);

	// Draw and fill the inner arcs in the right portion of the window
    r.size.height = 145;
    r.origin.x = 325;
    r.origin.y = 55;
    r.size.width = 100;
    paintArc(context, r, 0, 135);
    paintArc(context, r, 180 - 10, 20);
    paintArc(context, r, 225, 45);
    paintArc(context, r, 315 - 20, 40);
	
CantCallNextEventHandler:
CantGetEventParameter:
	
		return status;
}

/*
OvalsDrawEventHandler : Handles the draw events for the "Ovals" window.

Parameter DescriptionsinHandler : A reference to the current handler call chain. This is passed to your handler so that you can call CallNextEventHandler if you need to.
inEvent : The event that triggered this call.
inUserData : The application-specific data you passed in to InstallEventHandler.
*/
OSStatus OvalsDrawEventHandler (EventHandlerCallRef inHandler, EventRef inEvent, void* inUserData) {
	OSStatus status = eventNotHandledErr;
	CGContextRef context;
    CGRect r;
	
	//CallNextEventHandler in order to make sure the default handling of the inEvent 
	// (drawing the white background) happens
	status = CallNextEventHandler( inHandler, inEvent );
	require_noerr(status, CantCallNextEventHandler);
	
	// Get the CGContextRef
	status = GetEventParameter (inEvent, 
								kEventParamCGContextRef, 
								typeCGContextRef, 
								NULL, 
								sizeof (CGContextRef),
								NULL,
								&context);
	require_noerr(status, CantGetEventParameter);
	
	// Draw the outer oval in the left portion of the window
    r.size.height = 210;
    r.origin.x = 20;
    r.origin.y = 20;
    r.size.width = 210;
    frameOval(context, r);
	
	// Draw the inner oval in the left portion of the window
    r.size.height = 145;
    r.origin.x = 75;
    r.origin.y = 55;
    r.size.width = 100;
    frameOval(context, r);
	
    /* Set the fill color to green. */
    CGContextSetRGBFillColor(context, 0, 1, 0, 1);
	
	// Draw and fill the outter oval in the right portion of the window
    r.size.height = 210;
    r.origin.x = 270;
    r.origin.y = 20;
    r.size.width = 210;
    paintOval(context, r);
	
    /* Set the fill color to yellow. */
    CGContextSetRGBFillColor(context, 1, 1, 0, 1);
	
	// Draw and fill the inner oval in the right portion of the window
    r.size.height = 145;
    r.origin.x = 325;
    r.origin.y = 55;
    r.size.width = 100;
    paintOval(context, r);

CantCallNextEventHandler:
CantGetEventParameter:
		
		return status;
}

/*
RectanglesDrawEventHandler : Handles the draw events for the "Rectangles" window.

Parameter DescriptionsinHandler : A reference to the current handler call chain. This is passed to your handler so that you can call CallNextEventHandler if you need to.
inEvent : The event that triggered this call.
inUserData : The application-specific data you passed in to InstallEventHandler.
*/
OSStatus RectanglesDrawEventHandler (EventHandlerCallRef inHandler, EventRef inEvent, void* inUserData) {
	OSStatus status = eventNotHandledErr;
	CGContextRef context;
    CGRect r;
	
	//CallNextEventHandler in order to make sure the default handling of the inEvent 
	// (drawing the white background) happens
	status = CallNextEventHandler( inHandler, inEvent );
	require_noerr(status, CantCallNextEventHandler);
	
	// Get the CGContextRef
	status = GetEventParameter (inEvent, 
								kEventParamCGContextRef, 
								typeCGContextRef, 
								NULL, 
								sizeof (CGContextRef),
								NULL,
								&context);
	require_noerr(status, CantGetEventParameter);
	
	/* Set the stroke color to black. */
    CGContextSetRGBStrokeColor(context, 0, 0, 0, 1);
	
    r.size.height = 210;
    r.origin.x = 20;
    r.origin.y = 20;
    r.size.width = 210;
    frameRect(context, r);
	
    r.size.height = 145;
    r.origin.x = 75;
    r.origin.y = 55;
    r.size.width = 100;
    frameRect(context, r);

    /* Set the fill color to green. */
    CGContextSetRGBFillColor(context, 0, 1, 0, 1);
	
    r.size.height = 210;
    r.origin.x = 270;
    r.origin.y = 20;
    r.size.width = 210;
    paintRect(context, r);
	
    /* Set the fill color to yellow. */
    CGContextSetRGBFillColor(context, 1, 1, 0, 1);
	
    r.size.height = 145;
    r.origin.x = 325;
    r.origin.y = 55;
    r.size.width = 100;
    paintRect(context, r);
	
CantCallNextEventHandler:
CantGetEventParameter:
		
		return status;
}

/*
OvalTeenDrawEventHandler : Handles the draw events for the "Ovalteen" window.

Parameter DescriptionsinHandler : A reference to the current handler call chain. This is passed to your handler so that you can call CallNextEventHandler if you need to.
inEvent : The event that triggered this call.
inUserData : The application-specific data you passed in to InstallEventHandler.
*/
OSStatus OvalTeenDrawEventHandler (EventHandlerCallRef inHandler, EventRef inEvent, void* inUserData) {
	OSStatus status = eventNotHandledErr;
	CGContextRef context;
	CGRect bounds;
	double a, b;
	int count, k;
	
	//CallNextEventHandler in order to make sure the default handling of the inEvent 
	// (drawing the white background) happens
	status = CallNextEventHandler( inHandler, inEvent );
	require_noerr(status, CantCallNextEventHandler);
	
	// Get the CGContextRef
	status = GetEventParameter (inEvent, 
								kEventParamCGContextRef, 
								typeCGContextRef, 
								NULL, 
								sizeof (CGContextRef),
								NULL,
								&context);
	require_noerr(status, CantGetEventParameter);
	
	// Get the bounding rectangle
	status = HIViewGetBounds ((HIViewRef) inUserData, &bounds);
	require_noerr(status, CantGetViewBounds);

	// Calculate the dimensions for an oval inside the bounding box
	a = 0.9 * bounds.size.width/4;
	b = 0.3 * bounds.size.height/2;
	count = 5;
	
	// Set the fill color to a partially transparent blue
	CGContextSetRGBFillColor(context, 0, 0, 1, 0.5);

	// Set the stroke color to an opaque black
	CGContextSetRGBStrokeColor(context, 0, 0, 0, 1);

	// Set the line width to be used, in user space units.
	CGContextSetLineWidth(context, 3);

	// Save the conexts state because we are going to be moving the origin and
	// rotating context for drawing, but we would like to restore the current
	// state before drawing the next image.
	CGContextSaveGState(context);
	
	// Move the origin to the middle of the first image (left side) to draw.
	CGContextTranslateCTM(context, bounds.size.width/4, bounds.size.height/2);
	
	// Draw "count" ovals, rotating the context around the newly translated origin
	// 1/count radians after drawing each oval
	for (k = 0; k < count; k++)
		 {
		 // Paint the oval with the fill color
		paintOval(context, CGRectMake(-a, -b, 2 * a, 2 * b));

		// Frame the oval with the stroke color
		frameOval(context, CGRectMake(-a, -b, 2 * a, 2 * b));

		// Rotate the context around the center of the image
		CGContextRotateCTM(context, pi / count);
		 }
	// Restore the saved state to a known state for dawing the next image
	CGContextRestoreGState(context);

	// Calculate a bounding box for the rounded rect
	a = 0.9 * bounds.size.width/4;
	b = 0.3 * bounds.size.height/2;
	count = 5;
	
	// Set the fill color to a partially transparent red
	CGContextSetRGBFillColor(context, 1, 0, 0, 0.5);

	// Set the stroke color to an opaque black
	CGContextSetRGBStrokeColor(context, 0, 0, 0, 1);

	// Set the line width to be used, in user space units.
	CGContextSetLineWidth(context, 3);

	// Save the conexts state because we are going to be moving the origin and
	// rotating context for drawing, but we would like to restore the current
	// state before drawing the next image.
	CGContextSaveGState(context);
	
	// Move the origin to the middle of the second image (right side) to draw.
	CGContextTranslateCTM(context, bounds.size.width/4 + bounds.size.width/2, bounds.size.height/2);

	for (k = 0; k < count; k++)
		 {
		 // Fill then stroke the rounding rect, otherwise the fill would cover the stroke
		fillRoundedRect(context, CGRectMake(-a, -b, 2 * a, 2 * b), 20, 20);
		strokeRoundedRect(context, CGRectMake(-a, -b, 2 * a, 2 * b), 20, 20);
		// Rotate the context for the next rounded rect
		CGContextRotateCTM(context, pi / count);
		 }
	CGContextRestoreGState(context);

CantCallNextEventHandler:
CantGetEventParameter:
CantGetViewBounds:
		
		return status;
}
