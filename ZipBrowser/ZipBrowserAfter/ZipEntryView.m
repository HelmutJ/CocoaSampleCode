 /*
 
 File: ZipEntryView.m
 
 Abstract: ZipEntryView is a view used to present an archive entry
 in the browser's preview column.  It shows an icon and some text.
 
 Version: 1.1
 
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
 
 Copyright (C) 2008-2009 Apple Inc. All Rights Reserved.
 
 */ 

#import "ZipEntryView.h"
#import "ZipEntry.h"
#import "ZipDocument.h"
#import "AccessibilityElement.h"

#define X_OFFSET 5
#define Y_OFFSET 5
#define Y_SPACING 5

@implementation ZipEntryView

@synthesize viewController;
@synthesize zipDocument;

/* Methods for drawing */

- (BOOL)isFlipped {
    return YES;
}

- (NSString *)entryName {
    return [(ZipEntry *)[[self viewController] representedObject] name];
}

- (NSString *)formattedStringForUnsignedLong:(unsigned long)val {
    if (!numberFormatter) {
        numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
        [numberFormatter setUsesGroupingSeparator:NO];
    }
    return [numberFormatter stringFromNumber:[NSNumber numberWithUnsignedLong:val]];
}

- (NSString *)storedSizeString {
    return [NSString stringWithFormat:NSLocalizedString(@"Stored size: %@", @"Stored size label"), [self formattedStringForUnsignedLong:(unsigned long)[(ZipEntry *)[[self viewController] representedObject] compressedSize]]];
}

- (NSString *)originalSizeString {
    return [NSString stringWithFormat:NSLocalizedString(@"Original size: %@", @"Original size label"), [self formattedStringForUnsignedLong:(unsigned long)[(ZipEntry *)[[self viewController] representedObject] uncompressedSize]]];
}

- (NSImage *)image {
    return [[NSWorkspace sharedWorkspace] iconForFileType:[[self entryName] pathExtension]];
}

- (NSDictionary *)textAttributes {
    return [NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:0], NSFontAttributeName, nil];
}

- (void)getImageRect:(NSRectPointer)imageRect nameRect:(NSRectPointer)nameRect storedSizeRect:(NSRectPointer)storedSizeRect originalSizeRect:(NSRectPointer)originalSizeRect {
    NSSize imageSize = [[self image] size], proposedStringSize = NSMakeSize([self bounds].size.width - 2 * X_OFFSET, 1.0e6);
    NSDictionary *attributes = [self textAttributes];
    NSRect localImageRect = NSMakeRect(X_OFFSET, Y_OFFSET, imageSize.width, imageSize.height), localNameRect = NSZeroRect, localStoredSizeRect = NSZeroRect, localOriginalSizeRect = NSZeroRect;

    if (nameRect || storedSizeRect || originalSizeRect) {
        localNameRect = [[self entryName] boundingRectWithSize:proposedStringSize options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes];
        localNameRect.origin = NSMakePoint(X_OFFSET, NSMaxY(localImageRect));
    }
    if (storedSizeRect || originalSizeRect) {
        localStoredSizeRect = [[self storedSizeString] boundingRectWithSize:proposedStringSize options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes];
        localStoredSizeRect.origin = NSMakePoint(X_OFFSET, NSMaxY(localNameRect) + Y_SPACING);
    }
    if (originalSizeRect) {
        localOriginalSizeRect = [[self originalSizeString] boundingRectWithSize:proposedStringSize options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes];
        localOriginalSizeRect.origin = NSMakePoint(X_OFFSET, NSMaxY(localStoredSizeRect));
    }
    if (imageRect) *imageRect = localImageRect;
    if (nameRect) *nameRect = localNameRect;
    if (storedSizeRect) *storedSizeRect = localStoredSizeRect;
    if (originalSizeRect) *originalSizeRect = localOriginalSizeRect;
}

- (void)drawRect:(NSRect)rect {
    NSRect imageRect, nameRect, storedSizeRect, originalSizeRect;
    NSDictionary *attributes = [self textAttributes];

    [self getImageRect:&imageRect nameRect:&nameRect storedSizeRect:&storedSizeRect originalSizeRect:&originalSizeRect];
    
    [[self image] compositeToPoint:NSMakePoint(imageRect.origin.x, NSMaxY(imageRect)) operation:NSCompositeSourceOver];
    [[self entryName] drawWithRect:nameRect options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes];
    [[self storedSizeString] drawWithRect:storedSizeRect options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes];
    [[self originalSizeString] drawWithRect:originalSizeRect options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes];
}


/* Methods for dragging */

- (BOOL)acceptsFirstMouse:(NSEvent *)event {
    // Clicks that begin drags should accept first mouse but delay window ordering
    if (([event type] == NSLeftMouseDown || [event type] == NSLeftMouseDragged) && [event clickCount] == 1) {
        NSPoint viewPoint = [self convertPoint:[event locationInWindow] fromView:nil];
        NSRect imageRect, nameRect;
        [self getImageRect:&imageRect nameRect:&nameRect storedSizeRect:NULL originalSizeRect:NULL];
        if (NSPointInRect(viewPoint, NSUnionRect(imageRect, nameRect))) return YES;
    }
    return NO;
}

- (BOOL)shouldDelayWindowOrderingForEvent:(NSEvent *)event {
    return [self acceptsFirstMouse:event];
}

- (void)mouseDown:(NSEvent *)event {
    ZipDocument *document = [self zipDocument];
    if (document && [self acceptsFirstMouse:event]) {
        // Ask the document to write to the pasteboard
        NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSDragPboard];
        if ([document writeSelectionToPasteboard:pasteboard]) {
            // Start a drag, with the document as the source, and the image starting at its origin in the view
            NSRect imageRect;
            [self getImageRect:&imageRect nameRect:NULL storedSizeRect:NULL originalSizeRect:NULL];
            [self dragImage:[self image] at:NSMakePoint(imageRect.origin.x, NSMaxY(imageRect)) offset:NSZeroSize event:event pasteboard:pasteboard source:document slideBack:YES];
        }
    }
}


/* Methods for accessibility */

- (NSArray *)childAccessibilityElements {
    NSRect imageRect, nameRect, storedSizeRect, originalSizeRect;
    AccessibilityElement *imageElement, *nameElement, *storedSizeElement, *originalSizeElement;
    
    if (childAccessibilityElements) {
        imageElement = [childAccessibilityElements objectAtIndex:0];
        nameElement = [childAccessibilityElements objectAtIndex:1];
        storedSizeElement = [childAccessibilityElements objectAtIndex:2];
        originalSizeElement = [childAccessibilityElements objectAtIndex:3];
    } else {
        imageElement = [[AccessibilityElement alloc] initWithRole:NSAccessibilityImageRole parentView:self index:0];
        nameElement = [[AccessibilityElement alloc] initWithRole:NSAccessibilityStaticTextRole parentView:self index:1];
        storedSizeElement = [[AccessibilityElement alloc] initWithRole:NSAccessibilityStaticTextRole parentView:self index:2];
        originalSizeElement = [[AccessibilityElement alloc] initWithRole:NSAccessibilityStaticTextRole parentView:self index:3];
        childAccessibilityElements = [NSArray arrayWithObjects:imageElement, nameElement, storedSizeElement, originalSizeElement, nil];
    }
    
    [self getImageRect:&imageRect nameRect:&nameRect storedSizeRect:&storedSizeRect originalSizeRect:&originalSizeRect];
    [imageElement setStringValue:[self entryName]];
    [imageElement setBounds:imageRect];
    [nameElement setStringValue:[self entryName]];
    [nameElement setBounds:nameRect];
    [storedSizeElement setStringValue:[self storedSizeString]];
    [storedSizeElement setBounds:storedSizeRect];
    [originalSizeElement setStringValue:[self originalSizeString]];
    [originalSizeElement setBounds:originalSizeRect];

    return childAccessibilityElements;
}

- (id)accessibilityAttributeValue:(NSString *)attribute {
    return ([attribute isEqualToString:NSAccessibilityChildrenAttribute] ? [self childAccessibilityElements] : [super accessibilityAttributeValue:attribute]);
}

- (id)accessibilityHitTest:(NSPoint)point {
    NSPoint viewPoint = [self convertPoint:[[self window] convertScreenToBase:point] fromView:nil];
    for (AccessibilityElement *element in [self childAccessibilityElements]) {
	if (NSPointInRect(viewPoint, [element bounds])) return [element accessibilityHitTest:point];
    }
    return NSAccessibilityUnignoredAncestor(self);
}

- (id)accessibilityFocusedUIElement {
    return NSAccessibilityUnignoredAncestor(self);
}

@end