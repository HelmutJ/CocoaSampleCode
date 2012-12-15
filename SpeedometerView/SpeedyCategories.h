/*
     File: SpeedyCategories.h
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

#import <Cocoa/Cocoa.h>


@interface NSAffineTransform (RectMapping)

	/* initialize the NSAffineTransform so it maps points in 
	srcBounds proportionally to points in dstBounds */
- (NSAffineTransform *)mapFrom:(NSRect)srcBounds to:(NSRect)dstBounds;

	/* scale the rectangle 'bounds' proportionally to the given height centered
	above the origin with the bottom of the rectangle a distance of height above
	the a particular point.  Handy for revolving items around a particular point. */
- (NSAffineTransform *)scaleBounds:(NSRect)bounds 
		toHeight:(float)height centeredDistance:(float)distance abovePoint:(NSPoint)location;

	/* same as the above, except it centers the item above the origin.  */
- (NSAffineTransform *)scaleBounds:(NSRect)bounds
		toHeight:(float)height centeredAboveOrigin:(float)distance;

	/* initialize the NSAffineTransform so it will flip the contents of bounds
	vertically. */
- (NSAffineTransform *)flipVertical:(NSRect)bounds;

@end



@interface NSBezierPath (ShadowDrawing)

	/* fill a bezier path, but draw a shadow under it offset by the
	given angle (counter clockwise from the x-axis) and distance. */
- (void)fillWithShadowAtDegrees:(float)angle withDistance:(float)distance;

@end



@interface BezierNSLayoutManager: NSLayoutManager {
	NSBezierPath *theBezierPath;
}
- (void)dealloc;

@property (nonatomic, copy) NSBezierPath *theBezierPath;

	/* convert the NSString into a NSBezierPath using a specific font. */
- (void)showPackedGlyphs:(char *)glyphs length:(unsigned)glyphLen
		glyphRange:(NSRange)glyphRange atPoint:(NSPoint)point font:(NSFont *)font
		color:(NSColor *)color printingAdjustment:(NSSize)printingAdjustment;
@end


@interface NSString (BezierConversions)

	/* convert the NSString into a NSBezierPath using a specific font. */
- (NSBezierPath *)bezierWithFont:(NSFont *)theFont;

@end


