/*
     File: SpeedometerView.m 
 Abstract: Implements a custom view that looks very much like
 a speedometer 
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


#import "SpeedometerView.h"
#import "SpeedyCategories.h"

@implementation SpeedometerView

@synthesize speed;
@synthesize curvature;
@synthesize ticks;
@synthesize draggingIndicator;

/* initialization and deallocation. */
	
- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
	if (self) {
        /* set to some startup values */
		self.speed = 30.0f;
		self.curvature = 56.0f;
		self.ticks = 9;
	}
	return self;
}

- (void)dealloc {
	self.boundingFrame = nil;
	[super dealloc];
}

/* overridden accessor methods for our instance variables. NOTE: in the setter
 * methods we bound the input values to acceptable values for our custom view. 
 */
- (void)setSpeed:(float)value {
    float nextLevel;
	
		/* bound setting to acceptable value range */
	if (value < 0.0)
		nextLevel = 0.0;
	else if (value > 100.0)
		nextLevel = 100.0;
	else nextLevel = value;
	
		/* set the new value, on change */
    if (speed != nextLevel) {
        speed = nextLevel;
		[self setNeedsDisplay:YES];
    }
}

- (void)setCurvature:(float)value {
    float nextCurvature;
	
		/* bound setting to acceptable value range */
	if (value < 0.0)
		nextCurvature = 0.0;
	else if (value > 100.0)
		nextCurvature = 100.0;
	else nextCurvature = value;
	
		/* set the new value, on change */
	if (curvature != nextCurvature) {
        curvature = nextCurvature;
		[self setNeedsDisplay:YES];
    }
}

- (void)setTicks:(int)value {
	int nextTicks;
	
    /* bound setting to acceptable value range */
	if (value < 3)
		nextTicks = 3;
	else if (value > 21)
		nextTicks = 21;
	else nextTicks = value;

    /* set the new value, on change */
    if (ticks != nextTicks) {
        ticks = nextTicks;
		[self setNeedsDisplay:YES];
    }
}

- (NSBezierPath *)boundingFrame {
    return [[boundingFrame retain] autorelease];
}

- (void)setBoundingFrame:(NSBezierPath *)value {
    if (boundingFrame != value) {
        [boundingFrame release];
        boundingFrame = [value copy];
    }
}

	/* used for saving information about the position of the pointer
	that we use in our mouse tracking methods for adjusting the speed. */
- (void)saveSweepWithCenter:(NSPoint)centerPt startAngle:(float)stAngle endAngle:(float)enAngle {
    
	iStartAngle = stAngle; /* degrees counter clockwise from the x axis */
	iEndAngle = enAngle; /* degrees counter clockwise from the x axis */
	iCenterPt = centerPt; /* pivot point */
}

    /* method for generating the bezier path we use for drawing our pointer */
- (NSBezierPath *)speedPointerPath {
    
	NSBezierPath* speedPointer = [NSBezierPath bezierPath];
	[speedPointer moveToPoint:NSMakePoint(134.39, 218.05)];
	[speedPointer curveToPoint:NSMakePoint(137.95, 219.75)
		controlPoint1:NSMakePoint(134.39, 218.05)
		controlPoint2:NSMakePoint(137.95, 219.75)];
	[speedPointer curveToPoint:NSMakePoint(141.78, 357.55)
		controlPoint1:NSMakePoint(137.95, 219.75)
		controlPoint2:NSMakePoint(141.78, 357.55)];
	[speedPointer curveToPoint:NSMakePoint(151.13, 356.31)
		controlPoint1:NSMakePoint(141.78, 357.55)
		controlPoint2:NSMakePoint(145.39, 359.54)];
	[speedPointer curveToPoint:NSMakePoint(158.95, 349.86)
		controlPoint1:NSMakePoint(156.87, 353.08)
		controlPoint2:NSMakePoint(158.95, 349.86)];
	[speedPointer curveToPoint:NSMakePoint(134.49, 415.99)
		controlPoint1:NSMakePoint(158.95, 349.86)
		controlPoint2:NSMakePoint(134.49, 415.99)];
	[speedPointer curveToPoint:NSMakePoint(110.02, 349.86)
		controlPoint1:NSMakePoint(134.49, 415.99)
		controlPoint2:NSMakePoint(110.02, 349.86)];
	[speedPointer curveToPoint:NSMakePoint(117.84, 356.31)
		controlPoint1:NSMakePoint(110.02, 349.86)
		controlPoint2:NSMakePoint(112.1, 353.08)];
	[speedPointer curveToPoint:NSMakePoint(127.19, 357.55)
		controlPoint1:NSMakePoint(123.58, 359.54)
		controlPoint2:NSMakePoint(127.19, 357.55)];
	[speedPointer curveToPoint:NSMakePoint(131.02, 219.75)
		controlPoint1:NSMakePoint(127.19, 357.55)
		controlPoint2:NSMakePoint(131.02, 219.75)];
	[speedPointer curveToPoint:NSMakePoint(134.39, 218.05)
		controlPoint1:NSMakePoint(131.02, 219.75)
		controlPoint2:NSMakePoint(134.39, 218.05)];
	[speedPointer closePath];
	[speedPointer setLineJoinStyle:NSRoundLineJoinStyle];
	[speedPointer setLineCapStyle:NSRoundLineCapStyle];
	[speedPointer setLineWidth: 0.75];
	return speedPointer;
}

    /* method for generating the bezier path we use for drawing the ornaments inside of the dial. */
- (NSBezierPath *)ornamentPath {
    
	NSBezierPath *ornament = [NSBezierPath bezierPath];
	[ornament moveToPoint:NSMakePoint(251.77, 135.25)];
	[ornament curveToPoint:NSMakePoint(260.31, 146.12)
		controlPoint1:NSMakePoint(252.88, 144.62)
		controlPoint2:NSMakePoint(260.31, 146.12)];
	[ornament curveToPoint:NSMakePoint(266.06, 343.75)
		controlPoint1:NSMakePoint(260.31, 146.12)
		controlPoint2:NSMakePoint(266.06, 343.75)];
	[ornament curveToPoint:NSMakePoint(251.79, 355.06)
		controlPoint1:NSMakePoint(266.06, 343.75)
		controlPoint2:NSMakePoint(257.38, 346.25)];
	[ornament curveToPoint:NSMakePoint(237.52, 343.75)
		controlPoint1:NSMakePoint(245.5, 345.88)
		controlPoint2:NSMakePoint(237.52, 343.75)];
	[ornament curveToPoint:NSMakePoint(243.27, 146.12)
		controlPoint1:NSMakePoint(237.52, 343.75)
		controlPoint2:NSMakePoint(243.27, 146.12)];
	[ornament curveToPoint:NSMakePoint(251.77, 135.25)
		controlPoint1:NSMakePoint(243.27, 146.12)
		controlPoint2:NSMakePoint(250.25, 144.75)];
	[ornament closePath];
	[ornament setLineJoinStyle:NSRoundLineJoinStyle];
	[ornament setLineCapStyle:NSRoundLineCapStyle];
	[ornament setLineWidth: 0.25];
	return ornament;
}

    /* method for generating the bezier path we use for drawing the tik marks around the outside of the dial. */
- (NSBezierPath *)tickMarkPath {
    
	NSBezierPath *tickMark = [NSBezierPath bezierPath];
	[tickMark moveToPoint:NSMakePoint(225.81, 358.28)];
	[tickMark curveToPoint:NSMakePoint(222.7, 385.11)
		controlPoint1:NSMakePoint(225.81, 358.28)
		controlPoint2:NSMakePoint(222.7, 385.11)];
	[tickMark curveToPoint:NSMakePoint(235.97, 385.11)
		controlPoint1:NSMakePoint(222.7, 385.11)
		controlPoint2:NSMakePoint(235.97, 385.11)];
	[tickMark curveToPoint:NSMakePoint(232.86, 358.28)
		controlPoint1:NSMakePoint(235.97, 385.11)
		controlPoint2:NSMakePoint(232.86, 358.28)];
	[tickMark curveToPoint:NSMakePoint(225.81, 358.28)
		controlPoint1:NSMakePoint(232.86, 358.28)
		controlPoint2:NSMakePoint(225.81, 358.28)];
	[tickMark closePath];
	[tickMark setLineJoinStyle:NSRoundLineJoinStyle];
	[tickMark setLineCapStyle:NSRoundLineCapStyle];
	[tickMark setLineWidth: 0.25];
    
	return tickMark;
}

	/* custom view's main drawing method */
- (void)drawRect:(NSRect)rect {

	const float inset = 8.0; /* inset from edges - padding around drawing */
	const float shadowAngle = -35.0;
	
		/* the bounds of this view */
    NSRect boundary = self.bounds;
	
	float sweepAngle = 270.0*(curvature/100.0) + 45.0;
	float sAngle = 90-sweepAngle/2;
	float eAngle = 90+sweepAngle/2;
	
		/* central axis will be aligned with the bottom axis. */
	
		/* calculate center, and radius. */
	NSPoint center;
	float spread, radius, dip;
		/* center horizontally in the view */
	center.x = boundary.origin.x + (boundary.size.width/2.0);
		/* if the sweep is less than 180 degrees, then we could use
		the distanct from the center to where we'll hit the right
		hand side as the radius.  */
	spread = ( sweepAngle <= 180 ) ?
			sqrtf(pow(center.x,2) + pow(tanf(sAngle*pi/180)*center.x,2))*2 : boundary.size.width;
		/* if the sweep is greater than 180 degrees, then the right and
		left sides will dip down below the center. */
	dip = (sweepAngle > 180) ? fabsf(sinf(sAngle*pi/180)) : 0.0;
		/* calculate the radius based on the height */
	radius = (boundary.size.height/(dip+1.0)) - inset;
		/* then calculate the center based on the radius */
	center.y = boundary.origin.y + radius*dip + (inset/2.0);
		
		/* those calculations could have put us over the right and
		left edges, so limit the radius by the maximum spread. */
	if (radius > spread/2.0 - inset) radius = spread/2.0 - inset;

		/* calculate some heights proportionate to the radius. */
	float tickSize = radius * 5.0/100.0; /* 5% tick mark height */
	float labelSize = radius * 9.0/100.0; /* 7% label text height */
	float indicatorSize = radius * 55.0/100.0; /* 50% indicator needle length */
	float centerSize = radius * 15.0/100.0; /* 15% center cover size */
	float ornamentSize = radius * 40.0/100.0; /* 30% ornament size */
	float paddingSize = radius * 2.0/100.0; /* 2% padding for spacing between items */

		/* adjust the radius and center position incase we're drawing a pie
		shaped wedge so that the bottom of the speedometer is aligned with
		the bottom of the view's rectangle. */
	if ( sweepAngle < 180.0 ) {
		float wedgeOffset = sinf(sAngle*pi/180) * centerSize;
		center.y -= wedgeOffset;
		radius += wedgeOffset;
			/* make sure we aren't going past the right or left edge */
		if (radius > spread/2.0 - inset) radius = spread/2.0 - inset;
	}
	
		/* bottom of the text labels, center the ornaments and needle below this */
	float bottomOfText = radius - tickSize - labelSize - paddingSize*3;
	
		/* top and bottom position for the ornaments */
	float ornamentTop = (bottomOfText + centerSize + ornamentSize)/2.0;
	float ornamentBottom = ornamentTop - ornamentSize;

		/* top and bottom position for the indicator arm */
	float armTop = (bottomOfText + centerSize + indicatorSize)/2.0;
	float armBottom = armTop - indicatorSize;


		/* make a bezier path for the background */
	NSBezierPath *frame = [[[NSBezierPath alloc] init] autorelease];
	[frame appendBezierPathWithArcWithCenter:center radius:centerSize startAngle:eAngle endAngle:sAngle clockwise:YES];
	[frame appendBezierPathWithArcWithCenter:center radius:radius startAngle:sAngle endAngle:eAngle];
	[frame closePath];
	[frame setLineWidth: 0.5];
	[frame setLineJoinStyle:NSRoundLineJoinStyle];
	
		/* fill with light blue, stroke with black. */
	[[NSColor colorWithCalibratedRed:.95 green:.95 blue:1.0 alpha: 1.0] set];
	[frame fillWithShadowAtDegrees:shadowAngle withDistance: inset/2];
    [[NSColor blackColor] set];
	[frame stroke];

		/* save a copy of the bounding frame */
	[self setBoundingFrame: frame];

		/* construct a tick mark path centered at the origin */
	NSBezierPath *tickmark = self.tickMarkPath;
	[tickmark transformUsingAffineTransform: 
		[[NSAffineTransform transform]
				scaleBounds: [tickmark bounds] toHeight: tickSize centeredAboveOrigin: (radius - paddingSize - tickSize)]];

		/* construct a small background decoration centered at the origin */
	NSBezierPath *ornament = [self ornamentPath];
	[ornament transformUsingAffineTransform: 
		[[NSAffineTransform transform]
				scaleBounds: [ornament bounds] toHeight: ornamentSize centeredAboveOrigin: ornamentBottom]];

		/* construct a the indicator pointer centered at the origin */
	NSBezierPath *speedPointer = [self speedPointerPath];
	[speedPointer transformUsingAffineTransform: 
		[[NSAffineTransform transform]
				scaleBounds: [speedPointer bounds] toHeight: indicatorSize centeredAboveOrigin: armBottom]];

		/* blending colors for the ornaments and tick marks */
	NSColor *startColor = [NSColor greenColor];
	NSColor *midColor = [NSColor yellowColor];
	NSColor *endColor = [NSColor redColor];

		/* calculate the font to use for the label */
	NSFont *labelFont = [[NSFont labelFontOfSize:labelSize] printerFont];

		/* transforms used during drawing */
	NSAffineTransform *transform;
	NSAffineTransform *identity = [NSAffineTransform transform];
	
		/* calculate the pointer arm's total sweep */
	float pointerWidth = speedPointer.bounds.size.width;
		 /* border on each end of sweep to accomodate width of pointer */
	float tickoutside = ((pointerWidth*.67) / (radius/2.0)) * 180/pi;
		 /* total arm sweep will be background sweep minus border on each side */
	float armSweep = sweepAngle - tickoutside*2;
	
		/* calculate the number of tick mark labels */
	float ornamentWidth = ornament.bounds.size.width;
		 /* border on each end of sweep to accomodate width of pointer */
	float ornamentDegrees = (ornamentWidth / ornamentBottom) * 180/pi;
		/* calculate the maximum number of ornaments that will fit */
	int maxTicks = truncf(armSweep/ornamentDegrees);
		/* limit the number of ticks we'll draw by the maximum */
	int limitedTicks = ((self.ticks > maxTicks) ? maxTicks : self.ticks);
		/* calculate the number of degrees between tickmarks */
	float tickdegrees = (armSweep)/((float)limitedTicks-1.0);

		/* loop drawing tick mark labels and ornaments */
	int i;
    for (i=0; i < limitedTicks; i++) {
	
			/* set up the transform matrix so we're drawing
			at the appropriate angle.  Here, we reset the xform matrix,
			center it on the axis of our dial, and then rotate it to the
			nth position. */
		transform = [[NSAffineTransform alloc] initWithTransform: identity]; /* reset the xform matrix */
		[transform translateXBy:center.x yBy:center.y]; /* set the center to the center of our dial */
		[transform rotateByDegrees: ( (limitedTicks-i-1)*tickdegrees + tickoutside + sAngle - 90 ) ];
		[transform concat];

		/* calculate the label string to display */
		float displayedValue = roundf((float) (100.0/(limitedTicks-1))*i);
		NSString *theLabel = [NSString stringWithFormat:@"%.0f", displayedValue];
		
		/* draw the tick mark label string using a NSBezierPath */
		NSBezierPath *nthLabelPath = [theLabel bezierWithFont:labelFont];
		[nthLabelPath transformUsingAffineTransform: 
			[[NSAffineTransform transform]
					scaleBounds: [nthLabelPath bounds] toHeight:[nthLabelPath bounds].size.height
						centeredAboveOrigin:bottomOfText-[labelFont descender]]];
		[nthLabelPath setLineWidth: 0.5];
		[[NSColor blueColor] set];
		[nthLabelPath fill];
		[[NSColor blackColor] set];
		[nthLabelPath stroke];

			/* draw the ornament.
			Ramp from green to yellow and then from yellow to red. */
		float cfraction = ((float) i / (float)(limitedTicks-1));
		if ( cfraction <= 0.5 )
			[[startColor blendedColorWithFraction:cfraction*2 ofColor:midColor] set];
		else
            [[midColor blendedColorWithFraction:(cfraction-0.5)*2 ofColor:endColor] set];

			/* fill the tickmark and ornament */
		[ornament fill];
		[tickmark fill];
		
			/* stroke the tickmark and ornament */
		[[NSColor blackColor] set];
		[tickmark stroke];
		[ornament stroke];
        
			/* set the coordinates back the way they were */
		[transform invert];
		[transform concat];
        
        [transform release];
	}
					
		/* translate and rotate the indicator arrow to its final position */
	NSAffineTransform *positionSpeedometer = [NSAffineTransform transform];
	[positionSpeedometer translateXBy:center.x yBy:center.y]; /* set the center to the center of our dial */
	[positionSpeedometer rotateByDegrees: (armSweep+tickoutside-(armSweep/100)*speed + sAngle) - 90 ];
	[speedPointer transformUsingAffineTransform: positionSpeedometer];
	
		/* draw the pointer in red, stroke in black */
	[[NSColor redColor] set];
	[speedPointer fillWithShadowAtDegrees:shadowAngle withDistance: inset/2];
    [[NSColor blackColor] set];
	[speedPointer stroke];
	
		/* record arm information for the drag routine */
	[self saveSweepWithCenter:center startAngle:sAngle+tickoutside endAngle:sAngle+tickoutside+armSweep];
}

	/* convert a mouse click inside of the speedometer view into an angle, and then convert
	that angle into the new value that should be displayed. */ 
- (void)setLevelForMouse:(NSPoint) local_point {

		/* calculate the new position */
	float clicked_angle = atanf( (local_point.y - iCenterPt.y) / (local_point.x - iCenterPt.x) ) * (180/pi);
	
		/* convert arc tangent result */
	if ( local_point.x < iCenterPt.x ) clicked_angle += 180;
	
		/* clamp angle between the start and end angles */
	if (clicked_angle > iEndAngle)
		clicked_angle = iEndAngle;
	else if (clicked_angle < iStartAngle)
		clicked_angle = iStartAngle;
		
		/* set the new speed, but only if it has changed */
	float newLevel = (iEndAngle-clicked_angle)/(iEndAngle-iStartAngle) * 100.0;
	if (self.speed != newLevel) {
		self.speed = newLevel;
	}
}

	/* return false so we can track the mouse in our view. */
- (BOOL)mouseDownCanMoveWindow {

    return NO;
}

	/* test for mouse clicks inside of the speedometer area of the view */
- (NSView *)hitTest:(NSPoint)aPoint {
	NSPoint local_point = [self convertPoint:aPoint fromView:[self superview]];
	if ( [self.boundingFrame containsPoint:local_point] ) {
		return self;
	}
	return nil;
}

	/* re-calculate the speed value based on the mouse position for clicks
	in the speedometer area of the view. */
- (void)mouseDown:(NSEvent *)theEvent {
	NSPoint local_point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	if ( [self.boundingFrame containsPoint:local_point] ) {
	
		[self setLevelForMouse:local_point];
		
			/* set the dragging flag */
		[self setDraggingIndicator: YES];
	}
}

	/* re-calculate the speed value based on the mouse position while the mouse
	is being dragged inside of the speedometer area of the view. */
- (void)mouseDragged:(NSEvent *)theEvent {
	NSPoint local_point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	if ( [self.boundingFrame containsPoint:local_point] ) {
	
		[self setLevelForMouse:local_point];
	}
}

	/* clear the dragging flag once the mouse is released. */
- (void)mouseUp:(NSEvent *)theEvent {

	[self setDraggingIndicator: NO];
}

@end





