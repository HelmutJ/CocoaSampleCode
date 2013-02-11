/*
	File:		MyQuartzView.m
	
	Description:	Implementation file for the MyQuartzView class.  Shows how to draw both aliased and anti-aliased arcs.

	Copyright: 	© Copyright 2010 Apple Inc. All rights reserved.
	
	Disclaimer:	IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc.
				("Apple") in consideration of your agreement to the following terms, and your
				use, installation, modification or redistribution of this Apple software
				constitutes acceptance of these terms.  If you do not agree with these terms,
				please do not use, install, modify or redistribute this Apple software.

				In consideration of your agreement to abide by the following terms, and subject
				to these terms, Apple grants you a personal, non-exclusive license, under Apple’s
				copyrights in this original Apple software (the "Apple Software"), to use,
				reproduce, modify and redistribute the Apple Software, with or without
				modifications, in source and/or binary forms; provided that if you redistribute
				the Apple Software in its entirety and without modifications, you must retain
				this notice and the following text and disclaimers in all such redistributions of
				the Apple Software.  Neither the name, trademarks, service marks or logos of
				Apple Computer, Inc. may be used to endorse or promote products derived from the
				Apple Software without specific prior written permission from Apple.  Except as
				expressly stated in this notice, no other rights or licenses, express or implied,
				are granted by Apple herein, including but not limited to any patent rights that
				may be infringed by your derivative works or by other works in which the Apple
				Software may be incorporated.

				The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
				WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
				WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
				PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
				COMBINATION WITH YOUR PRODUCTS.

				IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
				CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
				GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
				ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION
				OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF CONTRACT, TORT
				(INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN
				ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
				
	Change History (most recent first):

		7/16/03		1.0		Initial version

*/


#import "MyQuartzView.h"

//#### utility code
#define PI 3.14159265358979323846

static inline double radians(double degrees) { return degrees * PI / 180; }

static void
drawAnX(CGContextRef gc)
{
    CGPoint p;

    p = CGContextGetPathCurrentPoint(gc);
    CGContextMoveToPoint(gc, p.x + 3, p.y + 3);
    CGContextAddLineToPoint(gc, p.x - 3, p.y - 3);
    CGContextMoveToPoint(gc, p.x + 3, p.y - 3);
    CGContextAddLineToPoint(gc, p.x - 3, p.y + 3);
    CGContextStrokePath(gc);
}
//####


@implementation MyQuartzView

- (id)initWithFrame:(NSRect)frameRect
{
	[super initWithFrame:frameRect];
	return self;
}

- (void)drawRect:(NSRect)rect
{
    int k;
    CGRect pageRect;
    CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    
    //#################################################################
    //##    Insert sample drawing code here
    //##
    //##    Note that at this point, the current context CTM is set up such that
    //##        that the context size corresponds to the size of the view
    //##        i.e. one unit in the context == one pixel
    //##    Also, the origin is in the bottom left of the view with +y pointing up
    //##
    //#################################################################
    
    pageRect = CGRectMake(0, 0, rect.size.width, rect.size.height);

    CGContextBeginPage(context, &pageRect);

    //  Start with black fill and stroke colors
    CGContextSetRGBFillColor(context, 0, 0, 0, 1);
    CGContextSetRGBStrokeColor(context, 0, 0, 0, 1);

    //  The current path for the context starts out empty
    assert(CGContextIsPathEmpty(context));

    CGContextTranslateCTM(context, 50, 50);

    CGContextAddArc(context, 55, 210, 36, radians(25), radians(65), 0);
    CGContextStrokePath(context);

    CGContextAddArc(context, 45, 200, 36, radians(25), radians(65), 1);
    CGContextStrokePath(context);

    //  Drawing (stroking or filling) a path consumes it
    assert(CGContextIsPathEmpty(context));

    //  Draw some wide, non-antialiased ellipses
    CGContextSaveGState(context);
    CGContextSetLineWidth(context, 2);
    CGContextSetShouldAntialias(context, 0);
    CGContextTranslateCTM(context, 150, 195);
    for (k = 0; k < 4; k++) {
	CGContextAddArc(context, 0, 0, 54, 0, 2*PI, 0);
	CGContextStrokePath(context);
	CGContextTranslateCTM(context, 0, -72);
	CGContextScaleCTM(context, 1, 0.75);
    }

    CGContextRestoreGState(context);

    CGContextAddArc(context, 50, 100, 54, radians(40), radians(140), 0);
    CGContextStrokePath(context);

    CGContextBeginPath(context);
    CGContextMoveToPoint(context, 50, 85);
    CGContextAddArc(context, 50, 65, 54, radians(40), radians(140), 0);
    CGContextStrokePath(context);

    CGContextSaveGState(context);

    CGContextTranslateCTM(context, 200, 0);

    CGContextMoveToPoint(context, 50, 50);
    drawAnX(context);
    CGContextMoveToPoint(context, 50, 150);
    drawAnX(context);
    CGContextMoveToPoint(context, 150, 150);
    drawAnX(context);

    CGContextMoveToPoint(context, 50, 50);
    CGContextAddArcToPoint(context, 50, 150, 150, 150, 36);
    CGContextStrokePath(context);

    CGContextRestoreGState(context);

    CGContextEndPage(context);

    CGContextFlush(context);
}

@end
