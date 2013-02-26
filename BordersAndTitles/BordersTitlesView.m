/*
 
 File:BordersTitlesView.m
 
 Abstract: A custom view that draws an image with a border and title strings
 
 Version: 1.0
 
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
 
 Copyright (C) 2008 Apple Inc. All Rights Reserved.
 
 */

#import "BordersTitlesView.h"
#import "PluginController.h"

@interface BordersTitlesView (Private)
- (NSRect)_imageRect;
@end

@implementation BordersTitlesView

- (void)awakeFromNib
{
	[self setBorderColor:[NSColor whiteColor]];
	[self setBorderWidth:10];
	[self setFullImageSize:NSZeroSize];
}

- (void)dealloc
{
	[_image release];
	[_borderColor release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark - Accessors

- (NSImage*)image
{
	return _image;
}

- (void)setImage:(NSImage*)image
{
	if ([_image isEqual:image])
		return;
	
	[_image release];
	_image = [image retain];
	
	[self setNeedsDisplay:YES];
}

- (NSColor*)borderColor
{
	return _borderColor;
}

- (void)setBorderColor:(NSColor*)color
{
	if ([_borderColor isEqual:color])
		return;
	
	[_borderColor release];
	_borderColor = [color retain];
	
	[self setNeedsDisplay:YES];
}

- (float)borderWidth
{
	return _borderWidth;
}

- (void)setBorderWidth:(float)width
{
	if (_borderWidth == width)
		return;
	
	_borderWidth = width;
	
	[self setNeedsDisplay:YES];
}

- (NSSize)fullImageSize
{
	return _fullImageSize;
}

- (void)setFullImageSize:(NSSize)size
{
	if (NSEqualSizes(_fullImageSize, size))
		return;
	
	_fullImageSize = size;
	
	[self setNeedsDisplay:YES];
}

#pragma mark -
#pragma mark - Drawing

- (NSRect)_imageRectForFrame:(NSRect)frame
{
    NSSize imageSize = [[self image] alignmentRect].size;
	
	//	Scale the image size to fit the frame
	if (imageSize.width > frame.size.width || imageSize.height > frame.size.height) {
		float xMag, yMag, mag;
		
		xMag = frame.size.width / imageSize.width;
		yMag = frame.size.height / imageSize.height;
		
		mag = MIN(xMag, yMag);
		
		imageSize.width = ceil(imageSize.width * mag);
		imageSize.height = ceil(imageSize.height * mag);
	}
    
	//	Center the image rect in the frame
    NSPoint drawOrigin;

	drawOrigin.x = frame.origin.x + (frame.size.width - imageSize.width) / 2;
	drawOrigin.y = frame.origin.y + (frame.size.height - imageSize.height) / 2;
	
	drawOrigin.x = floor(drawOrigin.x);
	drawOrigin.y = floor(drawOrigin.y);
	
    return NSMakeRect(drawOrigin.x, drawOrigin.y, imageSize.width, imageSize.height);
}

- (void)drawRect:(NSRect)rect
{
	//	Draw the background
	[[NSColor colorWithCalibratedWhite:0.18 alpha:1.0] set];
	NSRectFill(rect);
	
	//	Clip the rest of the drawing to fit inside the image
	NSRect imageRect = [self _imageRectForFrame:[self bounds]];
	NSRectClip(imageRect);
	
	//	Draw the scaled image
	[[self image] drawInRect:imageRect fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];

	[self compositeBordersAndTitlesInRect:imageRect];
}

- (void)compositeBordersAndTitlesInRect:(NSRect)imageRect
{
	//	Draw the border
	float scale = (NSWidth(imageRect) / [self fullImageSize].width);
	float borderWidth = [self borderWidth] * scale;
	NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSInsetRect(imageRect, borderWidth / 2, borderWidth / 2)];
	[path setLineWidth:borderWidth];
	
	[[self borderColor] set];
	[path stroke];
	
	//	Draw each title
	NSArray *stringsArray = [_stringsController content];
	unsigned int stringIndex, numStrings = [stringsArray count];
	
	for (stringIndex = 0; stringIndex < numStrings; stringIndex++)
	{
		NSMutableDictionary *stringDict = [stringsArray objectAtIndex:stringIndex];
		NSAttributedString *attributedString = [stringDict objectForKey:@"attributedString"];
		float stringScale = [[stringDict objectForKey:@"scale"] floatValue];
		NSSize stringSize = [attributedString size];
		stringSize.width *= scale * stringScale;
		stringSize.height *= scale * stringScale;
		
		if (stringSize.width == 0 || stringSize.height == 0)
			continue;

		NSPoint position = [[stringDict objectForKey:@"position"] pointValue];
		
		//	Convert position from percent to pixels
		position.x = NSMinX(imageRect) + position.x * NSWidth(imageRect);
		position.y = NSMinY(imageRect) + position.y * NSHeight(imageRect);
		
		//	Center the string
		position.x = floor(position.x - (stringSize.width) / 2.);
		position.y = floor(position.y - (stringSize.height) / 2.);
		
		[[NSGraphicsContext currentContext] saveGraphicsState];
		
		//	Scale the title
		NSAffineTransform *transform = [NSAffineTransform transform];
		[transform translateXBy:position.x yBy:position.y];
		[transform scaleBy:stringScale * scale];
		[transform concat];

		//	Draw the tite
		[attributedString drawAtPoint:NSZeroPoint];
		
		[[NSGraphicsContext currentContext] restoreGraphicsState];
	}
}

#pragma mark -
#pragma mark - Event Handling

- (void)mouseDown:(NSEvent*)event
{
	NSRect frame = [self bounds];
	NSRect imageRect = [self _imageRectForFrame:frame];

	do
	{
		if ([event type] == NSLeftMouseUp)
			break;
		
		NSPoint point = [self convertPoint:[event locationInWindow] fromView:nil];
		
		//	Convert position from pixels to percent
		float xPos = (point.x - NSMinX(imageRect)) / NSWidth(imageRect);
		float yPos = (point.y - NSMinY(imageRect)) / NSHeight(imageRect);
		
		//	Store the new position in the array controller's selection
		[[_stringsController selection] setValue:[NSValue valueWithPoint:NSMakePoint(xPos, yPos)] forKey:@"position"];
		
		//	We could only invalidate the rect of the selected string, but since the whole image is still going to be redrawn it doesn't matter
		[self setNeedsDisplay:YES];
	}
	while (event = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask|NSLeftMouseUpMask)]);
	
	if (event)
		[[self window] discardEventsMatchingMask:NSAnyEventMask beforeEvent:event];	
}

@end
