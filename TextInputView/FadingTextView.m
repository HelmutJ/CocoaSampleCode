/*
     File: FadingTextView.m
 Abstract: A view that implements NSTextInputClient by using the Cocoa text system objects NSTextStorage, NSLayoutManager, and NSTextContainer. The view centers and displays any typed text. When the user enters a newline, the text fades out, leaving an empty field. The view also handles marked text, such as the acute accent that appears when typing the character "é" (option-e, then e). Marked characters are displayed in gray.
  Version: 1.2
 
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


#import "FadingTextView.h"

static const NSTimeInterval kDefaultAnimationInterval = 0.02;
static const NSTimeInterval kDefaultAnimationTime = 1.0;

static const CGFloat kLargeWidthForTextContainer = 5e6; // large enough to not clip/wrap text, but not so large the text system stops centering for us
static const CGFloat kTextToFrameRatio = 0.5; // tall enough for most characters to fit in the default window

@implementation FadingTextView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Set up text attributes
        NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [paragraphStyle setAlignment:NSCenterTextAlignment];
        NSFont *font = [NSFont systemFontOfSize:ceil(NSHeight(frame) * kTextToFrameRatio)];
        
        defaultAttributes = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
            paragraphStyle, NSParagraphStyleAttributeName,
            font, NSFontAttributeName,
            nil];
        markedAttributes = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
            paragraphStyle, NSParagraphStyleAttributeName,
            font, NSFontAttributeName,
            [NSColor lightGrayColor], NSForegroundColorAttributeName,
            nil];
        [paragraphStyle release];
        
        // Set up the text system
        backingStore = [[NSTextStorage alloc] initWithString:@"" attributes:defaultAttributes];
        
        layoutManager = [[NSLayoutManager alloc] init];
        [backingStore addLayoutManager:layoutManager];
        textContainer = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(kLargeWidthForTextContainer, NSHeight(frame))];
        [layoutManager addTextContainer:textContainer];

        // Calculate offset from our very wide text container
        centerOffset = floor((NSWidth(frame) - kLargeWidthForTextContainer) / 2.0);
        lineHeight = floor([layoutManager defaultLineHeightForFont:font]);
        
        // Initial values for various things
        selectedRange = NSMakeRange(0, 0);
        markedRange = NSMakeRange(NSNotFound, 0);
        
        // For animation
        currentAlpha = 1.0;
        animationInterval = kDefaultAnimationInterval;
        animationTime = kDefaultAnimationTime;
        cacheImage = [[NSImage alloc] initWithSize:NSZeroSize];
    }
    return self;
}

- (void)dealloc {
    [animateTimer invalidate];
    [animateTimer release];
    [cacheImage release];
    
    [backingStore release];
    [layoutManager release];
    [textContainer release];
    
    [defaultAttributes release];
    [markedAttributes release];
    
    [super dealloc];
}

- (void)finalize {
    [animateTimer invalidate];
    
    [super finalize];
}

- (void)animate:(NSTimer *)timer {    
    if (currentAlpha < 0.0) {
        [self endAnimation];
    } else {
        currentAlpha = 1.0 + ([(NSDate *)[timer userInfo] timeIntervalSinceNow] / animationTime);
    }
    
    [self setNeedsDisplay:YES];
}

- (void)endAnimation {
    [animateTimer invalidate];
    [animateTimer release];
    animateTimer = nil;
    
    [cacheImage recache]; // clear the image data
    [self recalculateDimensions];
    lineHeight = floor([layoutManager defaultLineHeightForFont:[defaultAttributes objectForKey:NSFontAttributeName]]);
}

- (void)recalculateDimensions {
    NSRect bounds = [self bounds];
    
    // Resize font to match new height
    NSFont *font = [NSFont systemFontOfSize:ceil(NSHeight(bounds) * kTextToFrameRatio)];
    [defaultAttributes setValue:font forKey:NSFontAttributeName];
    [markedAttributes setValue:font forKey:NSFontAttributeName];
    [backingStore addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, [backingStore length])];
    
    // Resize text container to match new height
    [textContainer setContainerSize:NSMakeSize(kLargeWidthForTextContainer, NSHeight(bounds))];
    centerOffset = floor((NSWidth(bounds) - kLargeWidthForTextContainer) / 2.0);
    lineHeight = floor([layoutManager defaultLineHeightForFont:font]);
    
    // Pass the word along to our input context
    [[self inputContext] invalidateCharacterCoordinates];
}

#pragma mark -

- (BOOL)isFlipped {
    return YES;
}

- (void)setFrame:(NSRect)frame {
    [super setFrame:frame];
    
    if (!animateTimer) {
        [self recalculateDimensions];
    }
}

- (void)drawRect:(NSRect)rect {    
    // First, redraw the background
    [[NSColor whiteColor] set];
    NSRectFill(rect);
    
    NSRect bounds = [self bounds];
    if (animateTimer) {
        // Use our cached image, which needs to be centered
        NSSize imageSize = [cacheImage size];
        CGFloat offsetX = floor((NSWidth(bounds) - imageSize.width) / 2.0);
        CGFloat offsetY = ceil((NSHeight(bounds) - lineHeight) / 2.0);
        
        NSRect imageRect = rect;
        
        // If the image is larger than the frame, draw the correct part of it
        // Although this changes the destination rect as well, the transform accounts for that
        if (imageSize.width > NSWidth(bounds)) {
            imageRect.origin.x -= offsetX;
        } else {
            rect.origin.x += offsetX;
        }
        
        if (imageSize.height > NSHeight(bounds)) {
            imageRect.origin.y -= offsetY;
        } else {
            rect.origin.y += offsetY;
        }
        
        // Draw it!
        
        [cacheImage drawInRect:rect fromRect:imageRect operation:NSCompositeSourceOver fraction:currentAlpha respectFlipped:YES hints:nil];        
    } else {
        // Draw the text...but only what we need to!
        NSRange glyphRange = [layoutManager glyphRangeForBoundingRect:rect inTextContainer:textContainer];
        
        // Center everything, account for our very wide text container
        NSPoint origin;
        origin.x = centerOffset;
        origin.y = floor((NSHeight(bounds) - lineHeight) / 2.0);
        
        // Draw it!
        [layoutManager drawGlyphsForGlyphRange:glyphRange atPoint:origin];
    }
}

#pragma mark -

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (BOOL)becomeFirstResponder {
    return YES;
}

- (BOOL)resignFirstResponder {
    return YES;
}

- (void)keyDown:(NSEvent *)theEvent {
    [[self inputContext] handleEvent:theEvent];
}

- (void)mouseDown:(NSEvent *)theEvent {
    [[self inputContext] handleEvent:theEvent];
}

- (void)mouseDragged:(NSEvent *)theEvent {
    [[self inputContext] handleEvent:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent {
    [[self inputContext] handleEvent:theEvent];
}

- (void)insertNewline:(id)sender {
    // Save the current text to an image, so we can draw it quickly during animation
    // Then start the animation
    
    // Figure out how much room we need
    NSRange glyphRange = [layoutManager glyphRangeForTextContainer:textContainer];
    NSRect glyphRect = NSIntegralRect([layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:textContainer]);
    
    // And where the glyphs go
    NSPoint glyphOrigin;
    glyphOrigin.x = ceil((NSWidth(glyphRect) - kLargeWidthForTextContainer) / 2.0);
    glyphOrigin.y = NSHeight(glyphRect) - lineHeight;
    
    // Size the image and lock focus
    NSSize imageSize = glyphRect.size;
    if (NSEqualSizes(imageSize, NSZeroSize)) {
        imageSize = NSMakeSize(1,1);
    }
    [cacheImage setSize:imageSize];
    [cacheImage lockFocusFlipped:YES];
    
    // First fill the background, for proper anti-aliasing
    [[NSColor whiteColor] set];
    NSRectFill(NSMakeRect(0, 0, imageSize.width, imageSize.height));
    
    // Then draw the glyphs and unlock focus
    [layoutManager drawGlyphsForGlyphRange:glyphRange atPoint:glyphOrigin];
    [cacheImage unlockFocus];
    
    // Erase the backing store; new text will stop the animation anyway
    [backingStore deleteCharactersInRange:NSMakeRange(0, [backingStore length])];
    selectedRange = NSMakeRange(0,0);
    [self unmarkText];

    // Start fully opaque
    currentAlpha = 1.0;

    // Create the timer...
    [animateTimer invalidate];
    [animateTimer release];
    animateTimer = [[NSTimer timerWithTimeInterval:animationInterval target:self selector:@selector(animate:) userInfo:[NSDate date] repeats:YES] retain];
    
    // And start the animation!
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    [runLoop addTimer:animateTimer forMode:NSDefaultRunLoopMode];
    [runLoop addTimer:animateTimer forMode:NSEventTrackingRunLoopMode]; // for live resize
}

- (void)deleteBackward:(id)sender {
    // Find the range to delete, handling an empty selection and the input point being at 0
    NSRange deleteRange = selectedRange;
    if (deleteRange.length == 0) {
        if (deleteRange.location == 0) {
            return;
        } else {
            deleteRange.location -= 1;
            deleteRange.length = 1;
            
            // Make sure we handle composed characters correctly
            deleteRange = [[backingStore string] rangeOfComposedCharacterSequencesForRange:deleteRange];
        }
    }
    
    [self deleteCharactersInRange:deleteRange];
}

- (void)deleteForward:(id)sender {
    // Find the range to delete, handling an empty selection and the input point being at the end
    NSRange deleteRange = selectedRange;
    if (deleteRange.length == 0) {
        if (deleteRange.location == [backingStore length]) {
            return;
        } else {
            deleteRange.length = 1;
            
            // Make sure we handle composed characters correctly
            deleteRange = [[backingStore string] rangeOfComposedCharacterSequencesForRange:deleteRange];
        }
    }
    
    [self deleteCharactersInRange:deleteRange];
}

- (void)deleteCharactersInRange:(NSRange)range {
    // Update the marked range
    if (NSLocationInRange(NSMaxRange(range), markedRange)) {
        markedRange.length -= NSMaxRange(range) - markedRange.location;
        markedRange.location = range.location;
    } else if (markedRange.location > range.location) {
        markedRange.location -= range.length;
    }
    
    if (markedRange.length == 0) {
        [self unmarkText];
    }
    
    // Actually delete the characters
    [backingStore deleteCharactersInRange:range];
    selectedRange.location = range.location;
    selectedRange.length = 0;
    
    [[self inputContext] invalidateCharacterCoordinates];
    [self setNeedsDisplay:YES];
}

#pragma mark -

- (void)doCommandBySelector:(SEL)aSelector {
    [super doCommandBySelector:aSelector]; // NSResponder's implementation will do nicely
}

- (void)insertText:(id)aString replacementRange:(NSRange)replacementRange {
    // Get a valid range
    if (animateTimer) {
        [self endAnimation];
        replacementRange = NSMakeRange(0, 0);
    } else if (replacementRange.location == NSNotFound) {
        if (markedRange.location != NSNotFound) {
            replacementRange = markedRange;
        } else {
            replacementRange = selectedRange;
        }
    }

    // Add the text
    [backingStore beginEditing];
    if ([aString isKindOfClass:[NSAttributedString class]]) {
        [backingStore replaceCharactersInRange:replacementRange withAttributedString:aString];
    } else {
        [backingStore replaceCharactersInRange:replacementRange withString:aString];
    }
    [backingStore setAttributes:defaultAttributes range:NSMakeRange(replacementRange.location, [aString length])];
    [backingStore endEditing];
    
    // Redisplay
    selectedRange = NSMakeRange([backingStore length], 0); // We don't support selection, so just place the insertion point at the end
    [self unmarkText];
    [[self inputContext] invalidateCharacterCoordinates]; // recentering
    [self setNeedsDisplay:YES];
}
 
- (void)setMarkedText:(id)aString selectedRange:(NSRange)newSelection replacementRange:(NSRange)replacementRange {
    // Get a valid range
    if (animateTimer) {
        [self endAnimation];
        replacementRange = NSMakeRange(0, 0);
    } else if (replacementRange.location == NSNotFound) {
        if (markedRange.location != NSNotFound) {
            replacementRange = markedRange;
        } else {
            replacementRange = selectedRange;
        }
    }

    // Add the text
    [backingStore beginEditing];
    if ([aString length] == 0) {
        [backingStore deleteCharactersInRange:replacementRange];
        [self unmarkText];
    } else {
        markedRange = NSMakeRange(replacementRange.location, [aString length]);
        if ([aString isKindOfClass:[NSAttributedString class]]) {
            [backingStore replaceCharactersInRange:replacementRange withAttributedString:aString];
        } else {
            [backingStore replaceCharactersInRange:replacementRange withString:aString];
        }
        [backingStore addAttributes:markedAttributes range:markedRange];
    }
    [backingStore endEditing];
    
    // Redisplay
    selectedRange.location = replacementRange.location + newSelection.location; // Just for now, only select the marked text
    selectedRange.length = newSelection.length;
    [[self inputContext] invalidateCharacterCoordinates]; // recentering
    [self setNeedsDisplay:YES];
}

- (void)unmarkText {
    markedRange = NSMakeRange(NSNotFound, 0);
    [[self inputContext] discardMarkedText];
}

- (NSRange)selectedRange {
    return selectedRange;
}

- (NSRange)markedRange {
    return markedRange;
}

- (BOOL)hasMarkedText {
    return (markedRange.location == NSNotFound ? NO : YES);
}

- (NSAttributedString *)attributedSubstringForProposedRange:(NSRange)aRange actualRange:(NSRangePointer)actualRange {
    // We choose not to adjust the range, though we have the option
    if (actualRange) {
        *actualRange = aRange;
    }
    return [backingStore attributedSubstringFromRange:aRange];
}

- (NSArray *)validAttributesForMarkedText {
    // We only allow these attributes to be set on our marked text (plus standard attributes)
    // NSMarkedClauseSegmentAttributeName is important for CJK input, among other uses
    // NSGlyphInfoAttributeName allows alternate forms of characters
    return [NSArray arrayWithObjects:NSMarkedClauseSegmentAttributeName, NSGlyphInfoAttributeName, nil];
}

- (NSRect)firstRectForCharacterRange:(NSRange)aRange actualRange:(NSRangePointer)actualRange {
    // Ask the layout manager
    NSRange glyphRange = [layoutManager glyphRangeForCharacterRange:aRange actualCharacterRange:actualRange];
    NSRect glyphRect = [layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:textContainer];
    glyphRect.origin.x += centerOffset;
    
    // Convert the rect to screen coordinates
    glyphRect = [self convertRectToBase:glyphRect];
    glyphRect.origin = [[self window] convertBaseToScreen:glyphRect.origin];
    return glyphRect;
}

- (NSUInteger)characterIndexForPoint:(NSPoint)aPoint {
    // Convert the point from screen coordinates
    NSPoint localPoint = [self convertPointFromBase:[[self window] convertScreenToBase:aPoint]];
    localPoint.x -= centerOffset;
    
    // Ask the layout manager
    NSUInteger glyphIndex = [layoutManager glyphIndexForPoint:localPoint inTextContainer:textContainer fractionOfDistanceThroughGlyph:NULL];
    return [layoutManager characterIndexForGlyphAtIndex:glyphIndex];
}

- (NSAttributedString *)attributedString {
    // This method is optional, but our backing store is an attributed string anyway
    return backingStore;
}

- (NSInteger)windowLevel {
    // This method is optional but easy to implement
    return [[self window] level];
}

- (CGFloat)fractionOfDistanceThroughGlyphForPoint:(NSPoint)aPoint {
    // This method is optional but would help with mouse-related activities, such as selection
    // Unfortunately we don't support selection
    
    // Convert the point from screen coordinates
    NSPoint localPoint = [self convertPointFromBase:[[self window] convertScreenToBase:aPoint]];
    localPoint.x -= centerOffset;
    
    // Ask the layout manager
    CGFloat fraction = 0.5;
    [layoutManager glyphIndexForPoint:localPoint inTextContainer:textContainer fractionOfDistanceThroughGlyph:&fraction];
    return fraction;
}

- (CGFloat)baselineDeltaForCharacterAtIndex:(NSUInteger)anIndex {
    // This method is optional but helps position other elements next to the characters, such as the box that allows you to choose which Chinese or Japanese characters you want to input.
    
    // Get the first glyph corresponding to this character
    NSUInteger glyphIndex = [layoutManager glyphIndexForCharacterAtIndex:anIndex];
    
    if (glyphIndex != NSNotFound) {
        // Ask the layout manager's typesetter
        return [[layoutManager typesetter] baselineOffsetInLayoutManager:layoutManager glyphIndex:glyphIndex];
    } else {
        // Fall back to the layout manager and font
        return [layoutManager defaultBaselineOffsetForFont:[defaultAttributes objectForKey:NSFontAttributeName]];
    }
}

// No implementation of -drawsVerticallyForCharacterAtIndex:, which means all characters are assumed to be drawn horizontally.
// This is consistent with the current behavior of NSLayoutManager.
// If you are drawing vertically, you should implement this method.

#pragma mark -

- (NSString *)stringValue {
    return [[[backingStore string] retain] autorelease];
}

- (void)setStringValue:(NSString *)aString {
    [backingStore beginEditing];
    [backingStore replaceCharactersInRange:NSMakeRange(0, [backingStore length]) withString:aString];
    [backingStore setAttributes:defaultAttributes range:NSMakeRange(0, [aString length])];
    [backingStore endEditing];
        
    [self unmarkText];
    selectedRange = NSMakeRange([aString length], 0);
    
    if (animateTimer) {
        [self endAnimation];
    }
    
    [[self inputContext] invalidateCharacterCoordinates];
    [self setNeedsDisplay:YES];
}

@synthesize animationInterval, animationTime;
@end
