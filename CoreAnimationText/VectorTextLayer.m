//    File: VectorTextLayer.m
//Abstract: A subclass of CALayer that lays out CAShapeLayers containing glyph paths
// Version: 1.0
//
//Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
//Inc. ("Apple") in consideration of your agreement to the following
//terms, and your use, installation, modification or redistribution of
//this Apple software constitutes acceptance of these terms.  If you do
//not agree with these terms, please do not use, install, modify or
//redistribute this Apple software.
//
//In consideration of your agreement to abide by the following terms, and
//subject to these terms, Apple grants you a personal, non-exclusive
//license, under Apple's copyrights in this original Apple software (the
//"Apple Software"), to use, reproduce, modify and redistribute the Apple
//Software, with or without modifications, in source and/or binary forms;
//provided that if you redistribute the Apple Software in its entirety and
//without modifications, you must retain this notice and the following
//text and disclaimers in all such redistributions of the Apple Software.
//Neither the name, trademarks, service marks or logos of Apple Inc. may
//be used to endorse or promote products derived from the Apple Software
//without specific prior written permission from Apple.  Except as
//expressly stated in this notice, no other rights or licenses, express or
//implied, are granted by Apple herein, including but not limited to any
//patent rights that may be infringed by your derivative works or by other
//works in which the Apple Software may be incorporated.
//
//The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
//MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
//THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
//FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
//OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
//
//IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
//OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
//MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
//AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
//STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
//POSSIBILITY OF SUCH DAMAGE.
//
//Copyright (C) 2010 Apple Inc. All Rights Reserved.
//

#import "VectorTextLayer.h"

// This implements a very simple glyph cache.
// It maps from CTFontRef to CGGlyph to CGPathRef in order to reuse glyphs.
// It does NOT try to retain the keys that are used (CTFontRef or CGGlyph)
// but that is not an issue with respect to how it is used by this sample.
@interface GlyphCache : NSObject
{
	CFMutableDictionaryRef cache;
}

-(id)init;
-(CGPathRef)pathForGlyph:(CGGlyph)glyph fromFont:(CTFontRef)font;

@end

@implementation GlyphCache

-(id)init
{
	self = [super init];
	if(self != nil)
	{
		cache = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, &kCFTypeDictionaryValueCallBacks);
	}
	return self;
}

-(void)dealloc
{
	CFRelease(cache);
	[super dealloc];
}

-(CGPathRef)pathForGlyph:(CGGlyph)glyph fromFont:(CTFontRef)font
{
	// First we lookup the font to get to its glyph dictionary
	CFMutableDictionaryRef glyphDict = (CFMutableDictionaryRef)CFDictionaryGetValue(cache, font);
	if(glyphDict == NULL)
	{
		// And if this font hasn't been seen before, we'll create and set the dictionary for it
		glyphDict = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, &kCFTypeDictionaryValueCallBacks);
		CFDictionarySetValue(cache, font, glyphDict);
		CFRelease(glyphDict);
	}
	// Next we try to get a path for the given glyph from the glyph dictionary
	CGPathRef path = (CGPathRef)CFDictionaryGetValue(glyphDict, (const void *)(uintptr_t)glyph);
	if(path == NULL)
	{
		// If the path hasn't been seen before, then we'll create the path from the font & glyph and cache it.
		path = CTFontCreatePathForGlyph(font, glyph, NULL);
		if(path == NULL)
		{
			// If a glyph does not have a path, then we need a placeholder to set in the dictionary
			path = (CGPathRef)kCFNull;
		}
		CFDictionarySetValue(glyphDict, (const void *)(uintptr_t)glyph, path);
		CFRelease(path);
	}
	if(path == (CGPathRef)kCFNull)
	{
		// If we got the placeholder, then set the path to NULL
		// (this will happen either after discovering the glyph path is NULL,
		// or after looking that up in the dictionary).
		path = NULL;
	}
	return path;
}

@end

#pragma mark -

@interface VectorTextLayer()
-(void)layout;
-(CAShapeLayer*)createShapeLayer;
@end

@implementation VectorTextLayer

-(id)init
{
	self = [super init];
	if(self != nil)
	{
		glyphLayers = [[NSMutableArray alloc] init];
		string = nil;
		line = NULL;
		zoomToFit = YES;
		// It is likely that your text rendering will assume that 0,0 is upper left
		// proceeding downwards, so we'll make that assumption here as well.
		self.geometryFlipped = YES;
	}
	return self;
}

-(void)dealloc
{
	[glyphLayers release];
	[string release];
	if(line != NULL)
	{
		CFRelease(line);
	}
	[super dealloc];
}

-(BOOL)zoomToFit
{
	return zoomToFit;
}

-(void)setZoomToFit:(BOOL)ztf
{
	if(ztf != zoomToFit)
	{
		zoomToFit = ztf;
		[self setNeedsLayout];
	}
}

-(id)string
{
	return string;
}

-(void)setString:(id)s
{
	if(s == nil)
	{
		// The rest of this code is not prepared for nil, so use a placeholder instead.
		s = @"";
	}
	// If given an NSAttributedString, then copy it and layout.
	if([s isKindOfClass:[NSAttributedString class]])
	{
		if(![string isEqualToAttributedString:s])
		{
			[string release];
			string = [s copy];
			[self layout];
		}
	}
	// If given an NSString, create an NSAttributedString from it and layout.
	else if([s isKindOfClass:[NSString class]])
	{
		NSAttributedString *newString = [[NSAttributedString alloc] initWithString:s];
		if(![string isEqualToAttributedString:newString])
		{
			[string release];
			string = [newString retain];
			[self layout];
		}
		[newString release];
	}
}

-(void)layoutSublayers
{
	if(line != NULL)
	{
		// Grab the typographic bounds
		// Image bounds might be more appropriate here, but we don't have a context.
		CGFloat ascent, descent, leading;
		double width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
		double height = ascent + descent + leading;
		
		// Start with the identity transform, we'll modify from here.
		CATransform3D transform = CATransform3DIdentity; 
		
		// If zoomToFit is turned on, then use the lesser of the x and y scale factors to zoom
		if(zoomToFit)
		{
			// Grab layer geometry to figure out how to scale.
			CGRect bounds = self.bounds;
			CGPoint anchorPoint = self.anchorPoint;
			CGFloat scaleX = bounds.size.width / width;
			CGFloat scaleY = bounds.size.height / height;
			CGFloat anchorX = bounds.origin.x + bounds.size.width * anchorPoint.x;
			CGFloat anchorY = bounds.origin.y + bounds.size.height * anchorPoint.y;

			// Translate to the origin so we can scale properly
			transform = CATransform3DTranslate(transform, -anchorX, -anchorY, 0.0);
			if(scaleX > scaleY)
			{
				transform = CATransform3DScale(transform, scaleY, scaleY, 1.0);
			}
			else
			{
				transform = CATransform3DScale(transform, scaleX, scaleX, 1.0);
			}
			// Then translate back to the anchorPoint so the transform applies correctly.
			transform = CATransform3DTranslate(transform, anchorX, anchorY, 0.0);
		}
		// Translate to move the text down by the height of the line.
		transform = CATransform3DTranslate(transform, 0.0, ascent, 0.0);
		
		// And apply the transform to all sublayers.
		[CATransaction setDisableActions:YES];
		self.sublayerTransform = transform;
		[CATransaction commit];
	}
}

CGColorRef CreateCGColorFromNSColor(NSColor *color)
{
	NSColor *rgb = [color colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	CGFloat rgba[4];
	[rgb getComponents:rgba];
	return CGColorCreateGenericRGB(rgba[0], rgba[1], rgba[2], rgba[3]);
}

// Since the parameters from a particular text attribute dictionary dictates the
// appearance of multiple layers, we convert a text attribute dictionary to a style
// dictionary in order to set multiple parameters of a layer at once.
NSDictionary *AttributesToStyle(NSDictionary *attributes)
{
	NSMutableDictionary *style = [NSMutableDictionary dictionary];
	
	CGColorRef fillColor;
	// First look if the Core Text attribute is available, as it is a CGColorRef that we can use directly.
	id tmp = [attributes objectForKey:(id)kCTForegroundColorAttributeName];
	if(tmp != nil)
	{
		// Great, use it!
		fillColor = CGColorRetain((CGColorRef)tmp);
	}
	else
	{
		// If not, check to see if the AppKit attribute is available
		// (which in our context is usually the case)
		// A pure Core Text client should not need to do this check.
		tmp = [attributes objectForKey:NSForegroundColorAttributeName];
		if(tmp != nil)
		{
			// The NSForegroundColorAttributeName attribute is an NSColor, so we have to convert it.
			fillColor = CreateCGColorFromNSColor(tmp);
		}
		else
		{
			// Otherwise there is no foreground attribute, and we use the default foreground color, black.
			fillColor = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 1.0);
		}
	}
	[style setObject:(id)fillColor forKey:@"fillColor"];
	CGColorRelease(fillColor);
	
	return style;
}

-(CAShapeLayer*)createShapeLayer
{
	CAShapeLayer *layer = [CAShapeLayer layer];
	// If this layer has geometry flipped, then we want to flip the shape layer's geometry
	// to ensure that glyphs are right-side-up.
	// If not, then we want to make sure it is not flipped for the same reason.
	layer.geometryFlipped = self.geometryFlipped;
	return layer;
}

-(void)layout
{
	// Let Core Text layout the text.
	if(line != NULL)
	{
		CFRelease(line);
	}
	line = CTLineCreateWithAttributedString((CFAttributedStringRef)string);
	
	// Turn off animations.
	[CATransaction setDisableActions:YES];

	// Ensure there are enough layers for the new layout.
	CFIndex glyphCount = CTLineGetGlyphCount(line);
	for(CFIndex i = [glyphLayers count]; i < glyphCount; ++i)
	{
		CAShapeLayer *newLayer = [self createShapeLayer];
		[glyphLayers addObject:newLayer];
		[self addSublayer:newLayer];
	}
	// For those layers that we won't be using anymore, remove their paths.
	for(CFIndex i = glyphCount; i < [glyphLayers count]; ++i)
	{
		((CAShapeLayer*)[glyphLayers objectAtIndex:i]).path = NULL;
	}
	
	// Create and use a glyph cache to ensure that we reuse paths when we reuse glyphs from a font
	// See comments on the GlyphCache class above.
	GlyphCache *cache = [[GlyphCache alloc] init];
	
	// Now lets get down to layout.
	CFIndex glyphIndex = 0;
	CFArrayRef glyphRuns = CTLineGetGlyphRuns(line);
	CFIndex runCount = CFArrayGetCount(glyphRuns);
	for(CFIndex i = 0; i < runCount; ++i)
	{
		// For each run, we need to get the glyphs, their font (to get the path) and their locations.
		CTRunRef run = CFArrayGetValueAtIndex(glyphRuns, i);
		CFIndex runGlyphCount = CTRunGetGlyphCount(run);
		CGPoint positions[runGlyphCount];
		CGGlyph glyphs[runGlyphCount];
		
		// Grab the glyphs, positions, and font
		CTRunGetPositions(run, CFRangeMake(0, 0), positions);
		CTRunGetGlyphs(run, CFRangeMake(0, 0), glyphs);
		CFDictionaryRef attributes = CTRunGetAttributes(run);
		CTFontRef runFont = CFDictionaryGetValue(attributes, kCTFontAttributeName);
		NSDictionary *style = AttributesToStyle((NSDictionary*)attributes);
		for(CFIndex j = 0; j < runGlyphCount; ++j, ++glyphIndex)
		{
			// Layout each of the shape layers to place them at the correct position with the correct path.
			CAShapeLayer *layer = [glyphLayers objectAtIndex:glyphIndex];
			layer.style = style;
			// We name them for identification purposes.
			layer.name = [NSString stringWithFormat:@"Font %@ Run %i Index %i Glyph 0x%.4X", runFont, i, j, glyphs[j]];
			layer.position = positions[j];
			layer.path = [cache pathForGlyph:glyphs[j] fromFont:runFont];
		}
	}
	[cache release];

	// Commit animations, and request a relayout (ends up in -layoutSublayers).
	[CATransaction commit];
	[self setNeedsLayout];
}

@end
