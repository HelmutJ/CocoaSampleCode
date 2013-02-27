/*
 
 File: ArcView.c
 
 Abstract: Defines and implements the ArcView custom HIView subclass to
 draw text on a curve and illustrate best practices with CoreText.
 
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
 
 Copyright (C) 2007 Apple Inc. All Rights Reserved.
 
 */ 

#include "ArcView.h"

#define ARCVIEW_DEFAULT_FONT_NAME	CFSTR("Didot")
#define ARCVIEW_DEFAULT_FONT_SIZE	64.0
#define ARCVIEW_DEFAULT_RADIUS		150.0

struct ArcView {
	HIObjectRef		object;
	CTFontRef		font;			// retained
	CFStringRef		string;			// retained
	CGFloat			radius;
	OptionBits		options;
	
	CGContextRef	context;		// not retained
};

typedef struct GlyphArcInfo {
	CGFloat			width;
	CGFloat			angle;	// in radians
} GlyphArcInfo;

static CTFontRef ArcViewCreateDefaultFont(void); 

static void ArcViewDispose(ArcView *arcView);
static ArcView *ArcViewCreate(HIObjectRef object);

static void PrepareGlyphArcInfo(CTLineRef line, CFIndex glyphCount, GlyphArcInfo *glyphArcInfo);
static CFAttributedStringRef ArcViewCreateAttributedString(ArcView *arcView);

static OSStatus ArcViewEventHandler(EventHandlerCallRef inCaller, EventRef inEvent, void* inRefcon);

static HIObjectClassRef sArcViewClass = NULL;

// Register the arc view class. This should be done very early, before the nib is loaded.
OSStatus ArcViewRegisterClass(void) 
{
	static const EventTypeSpec kArcViewEvents[] = {
		{ kEventClassHIObject, kEventHIObjectConstruct },
		{ kEventClassHIObject, kEventHIObjectDestruct },
		{ kEventClassControl, kEventControlDraw }
	};
	
	return HIObjectRegisterSubclass(kArcViewClassID, kHIViewClassID, 0, (EventHandlerUPP)ArcViewEventHandler, GetEventTypeCount(kArcViewEvents), kArcViewEvents, NULL, &sArcViewClass);
}

// Convenience to get the arc view for the specified window.
ArcView *GetArcViewForWindow(HIWindowRef window) 
{
	static const HIViewID	arcID = { kArcViewControlSignature, kArcViewControlID };
	HIViewRef view;
	
	verify_noerr(HIViewFindByID(HIViewGetRoot(window), arcID, &view));
	
	return HIObjectDynamicCast((HIObjectRef)view, kArcViewClassID);
}

// Set the font for the arc view. This properly releases the existing font and marks the view as needing display.
void ArcViewSetFont(ArcView *arcView, CTFontRef font) 
{
	if (arcView->font != font) {
		if (arcView->font != NULL)
			CFRelease(arcView->font);
		arcView->font = (CTFontRef)CFRetain(font);
		
		HIViewSetNeedsDisplay((HIViewRef)arcView->object, true);
	}
}

// Get the current font.
CTFontRef ArcViewGetFont(const ArcView *arcView)
{
	return arcView->font;
}

// Set the content string for the arc view. This properly releases the existing string and marks the view as needing display.
void ArcViewSetString(ArcView *arcView, CFStringRef string)
{
	if (arcView->string != string) {
		if (arcView->string != NULL)
			CFRelease(arcView->string);
		arcView->string = (CFStringRef)CFRetain(string);
		
		HIViewSetNeedsDisplay((HIViewRef)arcView->object, true);
	}
}

// Get the current content string.
CFStringRef ArcViewGetString(const ArcView *arcView) 
{
	return arcView->string;
}

// Set the state for the specified option(s)
void ArcViewSetOptions(ArcView *arcView, ArcViewOptions optionsMask, Boolean state) 
{
	if (state) {
		arcView->options |= optionsMask;
	} else {
		arcView->options &= ~optionsMask;
	}
	HIViewSetNeedsDisplay((HIViewRef)arcView->object, true);
}

// Returns true if specified options are enabled
Boolean ArcViewGetOptions(ArcView *arcView, ArcViewOptions optionsMask)
{
	return (arcView->options & optionsMask) == optionsMask;
}

// Draw the view in the provided context. This should not be called directly as it draws in response events.
void ArcViewDraw(ArcView *arcView, CGContextRef context)
{
	HIRect			bounds;
	CFIndex			glyphCount;
	GlyphArcInfo *	glyphArcInfo;
	
	// Don't draw if we don't have a font or string
	if (arcView->font == NULL || arcView->string == NULL) 
		return;
	
	verify_noerr(HIViewGetBounds((HIViewRef)arcView->object, &bounds));
	
	// Transform HIView coordinates to Quartz coordinates
	CGContextTranslateCTM(context, 0, bounds.size.height);
	CGContextScaleCTM(context, 1.0, -1.0);
	
	// Draw a white background
	CGContextSetFillColorWithColor(context, CGColorGetConstantColor(kCGColorWhite)); 
	CGContextFillRect(context, bounds);
	
	// Create the attributed string
	CFAttributedStringRef attrString = ArcViewCreateAttributedString(arcView);
	assert(attrString != NULL);
	
	CTLineRef line = CTLineCreateWithAttributedString(attrString);
	CFRelease(attrString);
	assert(line != NULL);
	
	glyphCount = CTLineGetGlyphCount(line);
	if (glyphCount == 0) {
		CFRelease(line);
		return;
	}
	
	glyphArcInfo = (GlyphArcInfo*)calloc(glyphCount, sizeof(GlyphArcInfo));
	PrepareGlyphArcInfo(line, glyphCount, glyphArcInfo);
	
	// Move the origin from the lower left of the view nearer to its center.
	CGContextSaveGState(context);
	CGContextTranslateCTM(context, CGRectGetMidX(bounds), CGRectGetMidY(bounds) - arcView->radius / 2.0);
	
	// Stroke the arc in red for verification.
	CGContextBeginPath(context);
	CGContextAddArc(context, 0.0, 0.0, arcView->radius, M_PI, 0.0, 1);
	CGContextSetRGBStrokeColor(context, 1.0, 0.0, 0.0, 1.0);
	CGContextStrokePath(context);
	
	// Rotate the context 90 degrees counterclockwise.
	CGContextRotateCTM(context, M_PI_2);
	
	// Now for the actual drawing. The angle offset for each glyph relative to the previous glyph has already been calculated; with that information in hand, draw those glyphs overstruck and centered over one another, making sure to rotate the context after each glyph so the glyphs are spread along a semicircular path.
	CGPoint textPosition = CGPointMake(0.0, arcView->radius);
	CGContextSetTextPosition(context, textPosition.x, textPosition.y);
	
	CFArrayRef runArray = CTLineGetGlyphRuns(line);
	CFIndex runCount = CFArrayGetCount(runArray);
	
	CFIndex glyphOffset = 0;
	CFIndex runIndex = 0;
	for (; runIndex < runCount; runIndex++) {
		CTRunRef run = (CTRunRef)CFArrayGetValueAtIndex(runArray, runIndex);
		CFIndex runGlyphCount = CTRunGetGlyphCount(run);
		Boolean	drawSubstitutedGlyphsManually = false;
		CTFontRef runFont = CFDictionaryGetValue(CTRunGetAttributes(run), kCTFontAttributeName);
		
		// Determine if we need to draw substituted glyphs manually. Do so if the runFont is not the same as the overall font.
		if ((arcView->options & kArcViewDimSubstitutedGlyphsOption) !=0 && !CFEqual(arcView->font, runFont)) {
			drawSubstitutedGlyphsManually = true;
		}
		
		CFIndex runGlyphIndex = 0;
		for (; runGlyphIndex < runGlyphCount; runGlyphIndex++) {
			CFRange glyphRange = CFRangeMake(runGlyphIndex, 1);
			CGContextRotateCTM(context, -(glyphArcInfo[runGlyphIndex + glyphOffset].angle));
			
			// Center this glyph by moving left by half its width.
			CGFloat glyphWidth = glyphArcInfo[runGlyphIndex + glyphOffset].width;
			CGFloat halfGlyphWidth = glyphWidth / 2.0;
			CGPoint positionForThisGlyph = CGPointMake(textPosition.x - halfGlyphWidth, textPosition.y);
			
			// Glyphs are positioned relative to the text position for the line, so offset text position leftwards by this glyph's width in preparation for the next glyph.
			textPosition.x -= glyphWidth;
			
			CGAffineTransform textMatrix = CTRunGetTextMatrix(run);
			textMatrix.tx = positionForThisGlyph.x;
			textMatrix.ty = positionForThisGlyph.y;
			CGContextSetTextMatrix(context, textMatrix);
			
			if (!drawSubstitutedGlyphsManually) {
				CTRunDraw(run, context, glyphRange);
			} 
			else {
				// We need to draw the glyphs manually in this case because we are effectively applying a graphics operation by setting the context fill color. Normally we would use kCTForegroundColorAttributeName, but this does not apply as we don't know the ranges for the colors in advance, and we wanted demonstrate how to manually draw.
				CGFontRef cgFont = CTFontCopyGraphicsFont(runFont, NULL);
				CGGlyph glyph;
				CGPoint position;
				
				CTRunGetGlyphs(run, glyphRange, &glyph);
				CTRunGetPositions(run, glyphRange, &position);
				
				CGContextSetFont(context, cgFont);
				CGContextSetFontSize(context, CTFontGetSize(runFont));
				CGContextSetRGBFillColor(context, 0.25, 0.25, 0.25, 0.5);
				CGContextShowGlyphsAtPositions(context, &glyph, &position, 1);
				
				CFRelease(cgFont);
			}
			
			// Draw the glyph bounds 
			if ((arcView->options & kArcViewShowGlyphBoundsOption) != 0) {
				CGRect glyphBounds = CTRunGetImageBounds(run, context, glyphRange);
				
				CGContextSetRGBStrokeColor(context, 0.0, 0.0, 1.0, 1.0);
				CGContextStrokeRect(context, glyphBounds);
			}
			// Draw the bounding boxes defined by the line metrics
			if ((arcView->options & kArcViewShowLineMetricsOption) != 0) {
				CGRect lineMetrics;
				CGFloat ascent, descent;
				
				CTRunGetTypographicBounds(run, glyphRange, &ascent, &descent, NULL);
				
				// The glyph is centered around the y-axis
				lineMetrics.origin.x = -halfGlyphWidth;
				lineMetrics.origin.y = positionForThisGlyph.y - descent;
				lineMetrics.size.width = glyphWidth; 
				lineMetrics.size.height = ascent + descent;

				CGContextSetRGBStrokeColor(context, 0.0, 1.0, 0.0, 1.0);
				CGContextStrokeRect(context, lineMetrics);
			}
		}
		
		glyphOffset += runGlyphCount;
	}
	
	CGContextRestoreGState(context);
	
	free(glyphArcInfo);
	CFRelease(line);	
}

// Handles events for the ArcView HIObject subclass. The only event we really care about is the control drawing event to trigger drawing of content.
static OSStatus ArcViewEventHandler(EventHandlerCallRef inCaller, EventRef inEvent, void* inRefcon)
{
	OSStatus result = eventNotHandledErr;
	ArcView *arcView = (ArcView *)inRefcon;
	OSType class = GetEventClass(inEvent);
	UInt32 kind = GetEventKind(inEvent);
	
	switch (class) {
		case kEventClassHIObject:
		{
			switch (kind) {
				case kEventHIObjectConstruct:
				{
					HIObjectRef object;
					
					// Get the HIObject from the event
					result = GetEventParameter(inEvent, kEventParamHIObjectInstance, typeHIObjectRef, NULL, sizeof(HIObjectRef), NULL, &object);
					require_noerr(result, ParameterMissing);
					
					// Create the ArcView
					arcView = ArcViewCreate(object);
					require_action(arcView != NULL, CantCreateArcView, result = memFullErr);
					
					// Set the ArcView as the data for the object
					verify_noerr(SetEventParameter(inEvent, kEventParamHIObjectInstance, typeVoidPtr, sizeof(void *), &arcView));
					break;
				}
				case kEventHIObjectDestruct:
				{
					// Dispose the ArcView
					ArcViewDispose(arcView);
					break;
				}
				default:
					break;
			}
			break;
		}
		case kEventClassControl:
		{
			switch (kind) {
				case kEventControlDraw:
				{	
					CGContextRef context;
					
					// Get the context from the event
					verify_noerr(GetEventParameter(inEvent, kEventParamCGContextRef, typeCGContextRef, NULL, sizeof(CGContextRef), NULL, &context));
					
					// Draw the ArcView
					ArcViewDraw(arcView, context);
					break;
				}
				default:
					break;
			}
			break;
		}
		default:
			break;
	}
CantCreateArcView:
ParameterMissing:
	return result;
}

// Create an attributed string with the current font and string.
static CFAttributedStringRef ArcViewCreateAttributedString(ArcView *arcView)
{
	assert(arcView->font != NULL);
	
	int zero = 0;
	CFNumberRef number = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &zero);
	
	const CFStringRef keys[] = {
		kCTFontAttributeName,
		kCTLigatureAttributeName
	};
	const CFTypeRef values[] = {
		arcView->font,
		number
	};
	
	// Create our attributes
	CFDictionaryRef attributes = CFDictionaryCreate(kCFAllocatorDefault, (const void**)&keys, (const void**)&values, sizeof(keys)/sizeof(keys[0]), &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	assert(attributes != NULL);

	CFRelease(number);
	
	// Create the attributed string
	CFAttributedStringRef attrString = CFAttributedStringCreate(kCFAllocatorDefault, arcView->string, attributes);
	CFRelease(attributes);
	
	return attrString;
}

// Precompute glyph positioning information
static void PrepareGlyphArcInfo(CTLineRef line, CFIndex glyphCount, GlyphArcInfo *glyphArcInfo)
{
	CFArrayRef runArray = CTLineGetGlyphRuns(line);
	CFIndex runCount = CFArrayGetCount(runArray);
	
	// Examine each run in the line, updating glyphOffset to track how far along the run is in terms of glyphCount.
	CFIndex glyphOffset = 0;
	CFIndex runIndex = 0;
	for (; runIndex < runCount; runIndex++) {
		CTRunRef run = (CTRunRef)CFArrayGetValueAtIndex(runArray, runIndex);
		CFIndex runGlyphCount = CTRunGetGlyphCount(run);
		
		// Ask for the width of each glyph in turn.
		CFIndex runGlyphIndex = 0;
		for (; runGlyphIndex < runGlyphCount; runGlyphIndex++) {
			glyphArcInfo[runGlyphIndex + glyphOffset].width = CTRunGetTypographicBounds(run, CFRangeMake(runGlyphIndex, 1), NULL, NULL, NULL);
		}
		
		glyphOffset += runGlyphCount;
	}
	
	double lineLength = CTLineGetTypographicBounds(line, NULL, NULL, NULL);
	
	CGFloat prevHalfWidth = glyphArcInfo[0].width / 2.0;
	glyphArcInfo[0].angle = (prevHalfWidth / lineLength) * M_PI;
	
	// Divide the arc into slices such that each one covers the distance from one glyph's center to the next.
	CFIndex lineGlyphIndex = 1;
	for (; lineGlyphIndex < glyphCount; lineGlyphIndex++) {
		CGFloat halfWidth = glyphArcInfo[lineGlyphIndex].width / 2.0;
		CGFloat prevCenterToCenter = prevHalfWidth + halfWidth;
		
		glyphArcInfo[lineGlyphIndex].angle = (prevCenterToCenter / lineLength) * M_PI;
		
		prevHalfWidth = halfWidth;
	}
}

// Create a default font
static CTFontRef ArcViewCreateDefaultFont(void) 
{
	return CTFontCreateWithName(ARCVIEW_DEFAULT_FONT_NAME, ARCVIEW_DEFAULT_FONT_SIZE, NULL);
}

// Create the ArcView object
static ArcView *ArcViewCreate(HIObjectRef object)
{
	ArcView *arcView = NULL;
	
	require(object != NULL, ParameterMissing);
	
	arcView = (ArcView *)malloc(sizeof(ArcView));
	require(arcView != NULL, MallocFailed);
	
	arcView->object = object;
	
	arcView->font = ArcViewCreateDefaultFont();
	
	arcView->string = NULL;
	
	arcView->radius = ARCVIEW_DEFAULT_RADIUS;
	
	arcView->options = 0;
	
MallocFailed:
ParameterMissing:
	return arcView;
}

// Dispose of the ArcView object
static void ArcViewDispose(ArcView *arcView)
{
	if (arcView->font != NULL) 
		CFRelease(arcView->font);
	if (arcView->string != NULL) 
		CFRelease(arcView->string);
	
	free(arcView);
}
