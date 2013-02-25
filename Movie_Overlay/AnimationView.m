 /*

File: AnimationView.m

Abstract: Implementation file for our AnimationView class. This is 
			an NSView subView for our overlay window. We use it to 
			perform some simple animations.

Version: 1.1

Disclaimer: IMPORTANT:  This Apple software is supplied to you by 
Apple Inc. ("Apple") in consideration of your agreement to the
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
Neither the name, trademarks, service marks or logos of Apple Inc. 
may be used to endorse or promote products derived from the Apple
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

Copyright (C) 2003-2008 Apple Inc. All Rights Reserved.

*/


#import "AnimationView.h"


@implementation AnimationView


//////////
//
// initWithFrame
//
// Initialize our NSView with frameRect
//
//////////

- (id)initWithFrame:(NSRect)frameRect
{
	id view = [super initWithFrame:frameRect];

	theta = 0.0;

	return view;
}

//////////
//
// initWithCoder
//
// Initializes a newly allocated NSView instance from data in aDecoder.
//
//////////

- (id)initWithCoder:(NSCoder *)aDecoder
{
	id view = [super initWithCoder:aDecoder];

	theta = 0;

	return view;
}

//////////
//
// doStarAnimation
//
// Perform simple animation using NSBezierPath
//
//////////

#define FPS 30.0    // Frames Per Second
#define PI  3.14159

- (void) doStarAnimation
{
    float x,y,t2;
    NSBezierPath *oval;
    
    theta += (2.0 * PI / FPS) / 2.0;    // spin every 2 seconds
    
    x = [self frame].size.width * .60;
    y = [self frame].size.height * .60;
    oval = [NSBezierPath bezierPath];
    
    [oval moveToPoint:
                NSMakePoint(x + cos(theta)*50, y + sin(theta) * 50)];
    for (t2=0; t2<=2*M_PI+.1; t2+=M_PI*.5) 
    {
        [oval curveToPoint:NSMakePoint(x + cos(theta+t2)*50,
                                        y + sin(theta+t2)*50)
                controlPoint1:NSMakePoint(x,y)
                controlPoint2:NSMakePoint(x,y)];
    }
    [ [NSColor blackColor] set];
    [oval stroke];
}

//////////
//
// drawRect
//
// Perform simple animation
//
//////////

- (void)drawRect:(NSRect)rect
{
	[[NSColor whiteColor] set];
	NSRectFill(rect);

	[self doStarAnimation];
}


@end
