/*
     File: TextViewAspect.m
 Abstract: Superclass for the various illustrative aspect subclasses.
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


#import "TextViewAspect.h"

const CGFloat LargeNumberForText = 1.0e7; // Any larger dimensions and the text could become blurry.

@implementation TextViewAspect
@synthesize textView;

/* Sets up a standard Cocoa text system, made up of a layout manager, text container, and text view, as well as the text storage given as an initialization parameter.
 */
- (id)initWithTextStorage:(NSTextStorage *)givenStorage {
    self = [super init];
    if (self) {
        textStorage = [givenStorage retain];
        NSLayoutManager *layoutManager = [self layoutManagerForTextStorage:textStorage];
        NSTextContainer *textContainer = [self textContainerForLayoutManager:layoutManager];
        textView = [self textViewForTextContainer:textContainer]; // not retained, the text storage is owner of the whole system
    }
    return self;
}

- (void)dealloc {
    textView = nil;
    [textStorage release];
    [super dealloc];
}

/* No special action is taken, but subclasses can override this to configure the layout manager more specifically.
 */
- (NSLayoutManager *)layoutManagerForTextStorage:(NSTextStorage *)givenStorage {
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    [givenStorage addLayoutManager:layoutManager];
    return [layoutManager autorelease];
}

/* The text container is created with very large dimensions so as not to impede the natural flow of the text by forcing it to wrap. The value of LargeNumberForText was not chosen arbitrarily; any larger and the text would begin to look blurry. It's a limitation of floating point numbers and goes all the way down to Postscript. No other special action is taken in setting up the text container, but subclasses can override this to configure it more specifically.
 */
- (NSTextContainer *)textContainerForLayoutManager:(NSLayoutManager *)layoutManager {
    NSTextContainer *textContainer = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(LargeNumberForText, LargeNumberForText)];
    [layoutManager addTextContainer:textContainer];
    return [textContainer autorelease];
}

/* Sets up a text view with reasonable initial settings. Subclasses can override this to configure it more specifically.
 */
- (NSTextView *)textViewForTextContainer:(NSTextContainer *)textContainer {
    NSTextView *view = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, 100, 100) textContainer:textContainer];
    [view setMaxSize:NSMakeSize(LargeNumberForText, LargeNumberForText)];
    [view setSelectable:YES];
    [view setEditable:YES];
    [view setRichText:YES];
    [view setImportsGraphics:YES];
    [view setUsesFontPanel:YES];
    [view setUsesRuler:YES];
    [view setAllowsUndo:YES];
    return [view autorelease];
}

#pragma mark -

/* This is the view that will be added to the window. Subclasses might choose to make this a box or scroll view, for example.
 */
- (NSView *)containerView {
    return textView;
}

- (NSString *)title {
    return NSLocalizedString(@"Generic Text View", @"Title for a generic text view (intended to be overriden)");
}

- (NSTextStorage *)textStorage {
    return [[textStorage retain] autorelease];
}

- (void)setTextStorage:(NSTextStorage *)newStorage {
    if (textStorage != newStorage) {
        [[self.textView layoutManager] replaceTextStorage:newStorage];
        [textStorage release];
        textStorage = [newStorage retain];
    }
}

@end
