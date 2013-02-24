
/*
     File: SKTLine+Accessibility.m
 Abstract: Adds accessibility support to SKTLine.
 
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


#import "SKTLine.h"
#import "SKTGraphic+Accessibility.h"



/* An SKTLine only has two handles instead of eight.  We override some of the accessibilty-related methods we added in SKTGraphic+Accessiblity.m to return the correct answers for lines.
 */
@implementation SKTLine (Accessibility)

- (NSString *)shapeDescription {
	return NSLocalizedStringFromTable(@"line", @"Accessibility", @"accessibility description for line graphic");
}

- (NSIndexSet *)handleCodes {
	return [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 2)];
}

/* A handle UI element has no idea of its screen location, it needs help from its parent, the graphic proxy.  The graphic proxy needs to ask the actual graphic for the location.
 */

- (NSRect)rectangleForHandleCode:(NSInteger)handleCode {
    NSPoint startPoint;
    switch (handleCode) {
		case SKTLineBeginHandle:
			startPoint = [self beginPoint];
			break;
		case SKTLineEndHandle:
			startPoint = [self endPoint];
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
		case SKTLineBeginHandle:
			accessibilityDescription = NSLocalizedStringFromTable(@"start", @"Accessibility", @"accessibility description for line handles");
			break;
		case SKTLineEndHandle:
			accessibilityDescription = NSLocalizedStringFromTable(@"end", @"Accessibility", @"accessibility description for line handles");
			break;
		default:
			accessibilityDescription = @"";
			break;
    }
    
    return accessibilityDescription;
    
}

@end

