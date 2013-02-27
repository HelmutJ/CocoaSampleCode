/*
 
 File: arcs.c
 
 Abstract: //	These are the functions that implement equivalents to the QuickDraw arc drawing APIs,
		   //   FrameArc and PaintArc.
		   //	See DrawProcs.c for sample usage
 
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

#include "arcs.h"

/*
pathForArc : Adds an arc (a segment of an oval) fitting inside a rectangle to the path.

Parameter Descriptions
context : The CG context to render to.
r : The CG rectangle that defines the arc's boundary..
startAngle : The angle indicating the start of the arc.
arcAngle : The angle indicating the arc’s extent.
*/

void pathForArc(CGContextRef context, CGRect r, int startAngle, int arcAngle)
{
    float start, end;
    CGAffineTransform matrix;
	
	// Save the context's state because we are going to scale it
    CGContextSaveGState(context);
	
	// Create a transform to scale the context so that a radius of 1 maps to the bounds
	// of the rectangle, and transform the origin of the context to the center of
	// the bounding rectangle.
    matrix = CGAffineTransformMake(r.size.width/2, 0,
								   0, r.size.height/2,
								   r.origin.x + r.size.width/2,
								   r.origin.y + r.size.height/2);
								   
	// Apply the transform to the context
    CGContextConcatCTM(context, matrix);
		
	// Calculate the start and ending angles
    if (arcAngle > 0) {
		start = (90 - startAngle - arcAngle) * M_PI / 180;
		end = (90 - startAngle) * M_PI / 180;
    } else {
		start = (90 - startAngle) * M_PI / 180;
		end = (90 - startAngle - arcAngle) * M_PI / 180;
    }
	
	// Add the Arc to the path
    CGContextAddArc(context, 0, 0, 1, start, end, false);
	
	// Restore the context's state. This removes the translation and scaling
	// but leaves the path, since the path is not part of the graphics state.
    CGContextRestoreGState(context);
}

/*
frameArc : Draws an arc of the oval that fits inside a rectangle.

Parameter Descriptions
context : The CG context to render to.
r : The CG rectangle that defines the arc's boundary..
startAngle : The angle indicating the start of the arc.
arcAngle : The angle indicating the arc’s extent.
*/

void frameArc(CGContextRef context, CGRect r, int startAngle, int arcAngle)
{

	// Signal the start of a path
    CGContextBeginPath(context);

	// Add to the path the arc of the oval that fits inside the rectangle.
	pathForArc(context,r,startAngle,arcAngle);
	
	// Stroke the path
    CGContextStrokePath(context);
}

/*
paintArc : Paints a wedge of the oval that fits inside a rectangle.

Parameter Descriptions
context : The CG context to render to.
r : The CG rectangle that defines the arc's boundary..
startAngle : The angle indicating the start of the arc.
arcAngle : The angle indicating the arc’s extent.
*/

void paintArc(CGContextRef context, CGRect r, int startAngle, int arcAngle)
{
    float start, end;
	
	// Signal the start of a path
    CGContextBeginPath(context);
	
	// Set the start of the path to the arcs focal point
    CGContextMoveToPoint(context, r.origin.x + r.size.width/2, r.origin.y + r.size.height/2);
	
	// Add to the path the arc of the oval that fits inside the rectangle.
	pathForArc(context,r,startAngle,arcAngle);

	// Complete the path closing the arc at the focal point
    CGContextClosePath(context);
	
	// Fill the path
    CGContextFillPath(context);
}
