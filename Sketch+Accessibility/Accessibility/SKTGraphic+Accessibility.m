
/*
     File: SKTGraphic+Accessibility.m
 Abstract: Adds accessibility methods to SKTGraphic.
 
  Version: 1.1
 
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
 
 Copyright (C) 2009 Apple Inc. All Rights Reserved.
 
 */


#import "SKTGraphic+Accessibility.h"
#import "SKTHandleUIElement.h"
#import "SKTCircle.h"
#import "SKTImage.h"
#import "SKTRectangle.h"
#import "SKTText.h"

@implementation SKTGraphic (Accessibility)

- (NSString *)shapeDescription {
	return NSLocalizedStringFromTable(@"shape", @"Accessibility", @"accessibility description for generic shape");
}

/* Need to be able to return to the accessibility proxy object which handle enum values are used by a graphic.  Note this method is overridden by SKTLine, which only has two handles.
 */
- (NSIndexSet *)handleCodes {
	return [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 8)];
}



/* A handle UI element has no idea of its screen location, it needs help from its parent, the graphic proxy.  The graphic proxy needs to ask the actual graphic for the location.
 */
- (NSRect)rectangleForHandleCode:(NSInteger)handleCode {
    NSPoint startPoint;
    NSRect bounds = [self bounds];
    switch (handleCode) {
		case SKTGraphicUpperLeftHandle:
			startPoint = NSMakePoint(NSMinX(bounds), NSMinY(bounds));
			break;
		case SKTGraphicUpperMiddleHandle:
			startPoint = NSMakePoint(NSMidX(bounds), NSMinY(bounds));
			break;
		case SKTGraphicUpperRightHandle:
			startPoint = NSMakePoint(NSMaxX(bounds), NSMinY(bounds));
			break;
		case SKTGraphicMiddleLeftHandle:
			startPoint = NSMakePoint(NSMinX(bounds), NSMidY(bounds));
			break;
		case SKTGraphicMiddleRightHandle:
			startPoint = NSMakePoint(NSMaxX(bounds), NSMidY(bounds));
			break;
		case SKTGraphicLowerLeftHandle:
			startPoint = NSMakePoint(NSMinX(bounds), NSMaxY(bounds));
			break;
		case SKTGraphicLowerMiddleHandle:
			startPoint = NSMakePoint(NSMidX(bounds), NSMaxY(bounds));
			break;
		case SKTGraphicLowerRightHandle:
			startPoint = NSMakePoint(NSMaxX(bounds), NSMaxY(bounds));
			break;	    
		default:
			startPoint = NSZeroPoint;
			break;
    }
    
    NSRect handleBounds;
    handleBounds.origin.x = startPoint.x - SKTGraphicHandleHalfWidth;
    handleBounds.origin.y = startPoint.y - SKTGraphicHandleHalfWidth;
    handleBounds.size.width = SKTGraphicHandleWidth;
    handleBounds.size.height = SKTGraphicHandleWidth;
    
    return handleBounds;
    
}

- (NSString *)descriptionForHandleCode:(NSInteger)handleCode {
    NSString *accessibilityDescription = nil;
    
    switch (handleCode) {
		case SKTGraphicUpperLeftHandle:
			accessibilityDescription = NSLocalizedStringFromTable(@"upper left", @"Accessibility", @"accessibility description for graphics handles");
			break;
		case SKTGraphicUpperMiddleHandle:
			accessibilityDescription = NSLocalizedStringFromTable(@"upper middle", @"Accessibility", @"accessibility description for graphics handles");
			break;
		case SKTGraphicUpperRightHandle:
			accessibilityDescription = NSLocalizedStringFromTable(@"upper right", @"Accessibility", @"accessibility description for graphics handles");
			break;
		case SKTGraphicMiddleLeftHandle:
			accessibilityDescription = NSLocalizedStringFromTable(@"middle left", @"Accessibility", @"accessibility description for graphics handles");
			break;
		case SKTGraphicMiddleRightHandle:
			accessibilityDescription = NSLocalizedStringFromTable(@"middle right", @"Accessibility", @"accessibility description for graphics handles");
			break;
		case SKTGraphicLowerLeftHandle:
			accessibilityDescription = NSLocalizedStringFromTable(@"lower left", @"Accessibility", @"accessibility description for graphics handles");
			break;
		case SKTGraphicLowerMiddleHandle:
			accessibilityDescription = NSLocalizedStringFromTable(@"lower middle", @"Accessibility", @"accessibility description for graphics handles");
			break;
		case SKTGraphicLowerRightHandle:
			accessibilityDescription = NSLocalizedStringFromTable(@"lower right", @"Accessibility", @"accessibility description for graphics handles");
			break;	    
		default:
			accessibilityDescription = @"";
			break;
    }
    
    return accessibilityDescription;
    
}


@end

/* Adding a shape description to all the other SKTShape subclasses.  Putting them all in this file so we don't have a giant proliferation of files just to add one accessibility-related method per class.  If in the future one or more subclasses requires more customization for accessibility, consider moving that category into its own file.
 */
@implementation SKTCircle (Accessibility)

- (NSString *)shapeDescription {
	return NSLocalizedStringFromTable(@"circle", @"Accessibility", @"accessibility description for circle graphic");
}

@end

@implementation SKTImage (Accessibility)

- (NSString *)shapeDescription {
	return NSLocalizedStringFromTable(@"image", @"Accessibility", @"accessibility description for image graphic");
}

@end

@implementation SKTRectangle (Accessibility)

- (NSString *)shapeDescription {
	return NSLocalizedStringFromTable(@"rectangle", @"Accessibility", @"accessibility description for rectangle graphic");
}

@end

@implementation SKTText (Accessibility)

- (NSString *)shapeDescription {
	return NSLocalizedStringFromTable(@"text", @"Accessibility", @"accessibility description for text graphic");
}

@end
