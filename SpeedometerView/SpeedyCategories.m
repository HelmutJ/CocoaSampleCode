/*
     File: SpeedyCategories.m 
 Abstract: Simple utility categories used in this example. 
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


#import "SpeedyCategories.h"


@implementation NSAffineTransform (RectMapping)

- (NSAffineTransform *)mapFrom:(NSRect)src to:(NSRect)dst {
	NSAffineTransformStruct at;
	at.m11 = (dst.size.width/src.size.width);
	at.m12 = 0.0;
	at.tX = dst.origin.x - at.m11*src.origin.x;
	at.m21 = 0.0;
	at.m22 = (dst.size.height/src.size.height);
	at.tY = dst.origin.y - at.m22*src.origin.y;
	[self setTransformStruct: at];
	return self;
}

	/* create a transform that proportionately scales bounds to a rectangle of height
	centered distance units above a particular point.   */
- (NSAffineTransform *)scaleBounds:(NSRect)bounds 
		toHeight:(float)height centeredDistance:(float)distance abovePoint:(NSPoint)location {
	NSRect dst = bounds;
	float scale = (height / dst.size.height);
	dst.size.width *= scale;
	dst.size.height *= scale;
	dst.origin.x = location.x - dst.size.width/2.0;
	dst.origin.y = location.y + distance;
	return [self mapFrom:bounds to:dst];
}

	/* create a transform that proportionately scales bounds to a rectangle of height
	centered distance units above the origin.   */
- (NSAffineTransform *)scaleBounds:(NSRect)bounds toHeight:(float)height
			centeredAboveOrigin:(float)distance {
	return [self scaleBounds: bounds toHeight: height centeredDistance:
			distance abovePoint: NSMakePoint(0,0)];
}

	/* initialize the NSAffineTransform so it will flip the contents of bounds
	vertically. */
- (NSAffineTransform *)flipVertical:(NSRect) bounds {
	NSAffineTransformStruct at;
	at.m11 = 1.0;
	at.m12 = 0.0;
	at.tX = 0;
	at.m21 = 0.0;
	at.m22 = -1.0;
	at.tY = bounds.size.height;
	[self setTransformStruct: at];
	return self;
}

@end



@implementation NSBezierPath (ShadowDrawing)

	/* fill a bezier path, but draw a shadow under it offset by the
	given angle (counter clockwise from the x-axis) and distance. */
- (void)fillWithShadowAtDegrees:(float) angle withDistance:(float)distance {
	float radians = angle*(3.141592/180.0);
	
		/* create a new shadow */
	NSShadow* theShadow = [[NSShadow alloc] init];
	
		/* offset the shadow by the indicated direction and distance */
	[theShadow setShadowOffset:NSMakeSize(cosf(radians)*distance, sinf(radians)*distance)];
	
		/* set other shadow parameters */
	[theShadow setShadowBlurRadius:3.0];
	[theShadow setShadowColor:[[NSColor blackColor] colorWithAlphaComponent:0.3]];

		/* save the graphics context */
	[NSGraphicsContext saveGraphicsState];
	
		/* use the shadow */
	[theShadow set];

		/* fill the NSBezierPath */
	[self fill];
	
		/* restore the graphics context */
	[NSGraphicsContext restoreGraphicsState];
	
		/* done with the shadow */
	[theShadow release];
}

@end



@implementation BezierNSLayoutManager

- (void) dealloc {
	self.theBezierPath = nil;
	[super dealloc];
}

- (NSBezierPath *)theBezierPath {
    return [[theBezierPath retain] autorelease];
}

- (void)setTheBezierPath:(NSBezierPath *)value {
    if (theBezierPath != value) {
        [theBezierPath release];
        theBezierPath = [value retain];
    }
}

	/* convert the NSString into a NSBezierPath using a specific font. */
- (void)showPackedGlyphs:(char *)glyphs length:(unsigned)glyphLen
		glyphRange:(NSRange)glyphRange atPoint:(NSPoint)point font:(NSFont *)font
		color:(NSColor *)color printingAdjustment:(NSSize)printingAdjustment {
	
		/* if there is a NSBezierPath associated with this
		layout, then append the glyphs to it. */
	NSBezierPath *bezier = [self theBezierPath];
	
	if ( nil != bezier ) {
	
			/* add the glyphs to the bezier path */
		[bezier moveToPoint:point];
		[bezier appendBezierPathWithPackedGlyphs: glyphs];
	}
}

@end


@implementation NSString (BezierConversions)

- (NSBezierPath *)bezierWithFont: (NSFont*) theFont {
    
	NSBezierPath *bezier = nil; /* default result */
	
		/* put the string's text into a text storage
		so we can access the glyphs through a layout. */
	NSTextStorage *textStore = [[NSTextStorage alloc] initWithString:self];
	NSTextContainer *textContainer = [[NSTextContainer alloc] init];
	BezierNSLayoutManager *myLayout = [[BezierNSLayoutManager alloc] init];
	[myLayout addTextContainer:textContainer];
	[textStore addLayoutManager:myLayout];
	[textStore setFont: theFont];
	
		/* create a new NSBezierPath and add it to the custom layout */
	[myLayout setTheBezierPath:[NSBezierPath bezierPath]];
	
		/* to call drawGlyphsForGlyphRange, we need a destination so we'll
		set up a temporary one.  Size is unimportant and can be small.  */
	NSImage *theImage = [[NSImage alloc] initWithSize: NSMakeSize(10.0, 10.0)];
		 /* lines are drawn in reverse order, so we will draw the text upside down
		 and then flip the resulting NSBezierPath right side up again to achieve
		 our final result with the lines in the right order and the text with
		 proper orientation.  */
	[theImage setFlipped:YES];
	[theImage lockFocus];
	
		/* draw all of the glyphs to collecting them into a bezier path
		using our custom layout class. */
	NSRange glyphRange = [myLayout glyphRangeForTextContainer:textContainer];
	[myLayout drawGlyphsForGlyphRange:glyphRange atPoint:NSMakePoint(0.0, 0.0)];
	
		/* clean up our temporary drawing environment */
	[theImage unlockFocus];
	[theImage release];
	
		/* retrieve the glyphs from our BezierNSLayoutManager instance */
	bezier = [myLayout theBezierPath];
	
		/* clean up our text storage objects */
	[textStore release];
	[textContainer release];
	[myLayout release];
	
		/* Flip the final NSBezierPath. */
	[bezier transformUsingAffineTransform: 
		[[NSAffineTransform transform] flipVertical:[bezier bounds]]];
	
		/* return the new bezier path */
	return bezier;
}
	
@end

