/*
 
 File: ovals.c
 
 Abstract: //	These are the functions  that implement equivalents to the QuickDraw oval
		   //	drawing APIs, FrameOval and PaintOval.
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

#include "ovals.h"
 
 /*
addOvalToPath : Adds to the context a path for an oval just inside the bounding rectangle that you specify.

Parameter Descriptions
context : The CG context to render to.
r :  The CG rectangle that defines the oval’s boundary.
*/

void addOvalToPath(CGContextRef context, CGRect r)
{
    CGAffineTransform matrix;
	
	// Save the context's state because we are going to transform and scale it
    CGContextSaveGState(context);

	// Create a transform to scale the context so that a radius of 1
	// is equal to the bounds of the rectangle, and transform the origin
	// of the context to the center of the bounding rectangle.  The 
	// center of the bounding rectangle will now be the center of
	// the oval.
    matrix = CGAffineTransformMake((r.size.width)/2, 0,
								   0, (r.size.height)/2,
								   r.origin.x + (r.size.width)/2,
								   r.origin.y + (r.size.height)/2);
 
	// Apply the transform to the context
    CGContextConcatCTM(context, matrix);

	// Signal the start of a path
    CGContextBeginPath(context);
	
	// Add a circle to the path.  After the circle is transformed by the
	// context's transformation matrix, it will become an oval lying
	// just inside the bounding rectangle.
    CGContextAddArc(context, 0, 0, 1, 0, 2*pi, true);

	// Restore the context's state. This removes the translation and scaling but leaves
	// the path, since the path is not part of the graphics state.
	CGContextRestoreGState(context);
}

 
/*
paintOval : Paints the interior of an oval just inside the bounding rectangle that you specify.

Parameter Descriptions
context : The CG context to render to.
r :  The CG rectangle that defines the oval’s boundary.
*/

void paintOval(CGContextRef context, CGRect r)
{
	// Add a path for the oval to this context
	addOvalToPath(context,r);

	// Fill the oval
    CGContextFillPath(context);
}

/*
frameOval : Draws an outline of an oval just inside the bounding rectangle that you specify.

Parameter Descriptions
context : The CG context to render to.
r :  The CG rectangle that defines the oval’s boundary.
*/
void frameOval(CGContextRef context, CGRect r)
{
	// Add a path for the oval to this context
	addOvalToPath(context,r);

	// Stroke the path
	CGContextStrokePath(context);
}