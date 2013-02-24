
/*
     File: SKTHandleUIElement.m
 Abstract: Concrete implementation of a element object for accessibility.
 
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


#import "SKTHandleUIElement.h"
#import "SKTGraphicAccessibilityProxy.h"

@implementation SKTHandleUIElement

- (id)initWithHandleCode:(NSInteger)code parent:(id)aParent {
    self = [super initWithRole:NSAccessibilityHandleRole parent:aParent];
    if (self) {
	handleCode = code;
    }
    return self;
}

+ (SKTHandleUIElement *)graphicHandleWithCode:(NSInteger)code parent:(id)aParent {
    return [[[SKTHandleUIElement alloc] initWithHandleCode:code parent:aParent] autorelease];
}

- (NSInteger)handleCode {
    return handleCode;
}

#pragma mark -
#pragma mark Attributes

- (NSArray *)accessibilityAttributeNames {
    NSMutableArray *names = [[[super accessibilityAttributeNames] mutableCopy] autorelease];
    [names addObject:NSAccessibilityEnabledAttribute];
    [names addObject:NSAccessibilityDescriptionAttribute];
    return names;
}

- (id)accessibilityAttributeValue:(NSString *)attribute {
    if ([attribute isEqualToString:NSAccessibilityDescriptionAttribute]) {
	// Ask our parent for the right description
	return [parent descriptionForHandleCode:[self handleCode]];
		
    } else if ([attribute isEqualToString:NSAccessibilityEnabledAttribute]) {
	// A handle is always enabled in Sketch
	return [NSNumber numberWithBool:YES];
	
    } else {
	return [super accessibilityAttributeValue:attribute];
    }
}

- (BOOL)accessibilityIsAttributeSettable:(NSString *)attribute {
    if ([attribute isEqualToString:NSAccessibilityPositionAttribute]) {
	return YES;
    } else {
	return [super accessibilityIsAttributeSettable:attribute];
    }
}

- (void)accessibilitySetValue:(id)value forAttribute:(NSString *)attribute {
    if ([attribute isEqualToString:NSAccessibilityPositionAttribute]) {
	if ([value isKindOfClass:[NSValue class]]) {
	    NSPoint screenPoint = [value pointValue];
	    [parent setPosition:screenPoint forHandleUIElement:self];
	} else {
	    NSAccessibilityRaiseBadArgumentException(self, attribute, value);
	}
    } else {
	[super accessibilitySetValue:value forAttribute:attribute];
    }
    
}

#pragma mark -
#pragma mark NSObject overridden methods

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[SKTHandleUIElement self]]) {
        SKTHandleUIElement *other = object;
        return (handleCode == other->handleCode) && [super isEqual:object];
    } else {
        return NO;
    }
}

- (NSUInteger)hash {
    // Equal objects must hash the same.
    return [super hash] + handleCode;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ Handle Code: %ld", [super description], (long)handleCode];
}


@end

