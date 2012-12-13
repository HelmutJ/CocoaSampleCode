/*
     File: FieldAspect.m
 Abstract: This example demonstrates how to configure several text views to behave like fields.
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


#import "FieldAspect.h"

#define DEFAULT_TEXT NSLocalizedString(@"Yellow Curls", @"Default text to initialize the fields in FieldLikeTextController with.")

const CGFloat NotQuiteAsLargeNumberForText = 0.5e7; // Too large and the Cocoa text system stops aligning text, for various reasons

/* Unlike the other TextViewController subclasses, this class starts with a nib file containing six boxes and places text views within them. The text views are configured to behave as "field editors", meaning when the user presses tab, return, or another such key, it is interpreted as movement (i.e. to another field) rather than inserting text. As delegate, the controller implements the necessary logic to actually change focus. The text views are also created "from the top down" by initializing an NSTextView first, rather than in the other classes (which build the text system up from an NSTextStorage).
 */
@implementation FieldAspect
/* Sets up attributes common to all six text views, such as disabling rich text and enabling field editor behavior.
 */
- (void)setUpCommonTextViewAttributes:(NSTextView *)boxText {
    NSTextContainer *textContainer = [boxText textContainer];

    // Set up container
    [textContainer setContainerSize:NSMakeSize(NotQuiteAsLargeNumberForText, NSHeight([boxText frame]))];
    [textContainer setWidthTracksTextView:NO];
    [textContainer setHeightTracksTextView:NO];

    // Set up size attributes
    [boxText setHorizontallyResizable:YES];
    [boxText setVerticallyResizable:NO];
    [boxText setTextContainerInset:NSMakeSize(0, 2)];
    
    // Set up editing attributes
    [boxText setSelectable:YES];
    [boxText setEditable:YES];
    
    // Set up rich text attributes
    [boxText setRichText:NO];
    [boxText setImportsGraphics:NO];
    [boxText setUsesFontPanel:NO];
    [boxText setUsesRuler:NO];
    
    // Set up colors
    [boxText setDrawsBackground:YES];
    [boxText setBackgroundColor:[NSColor textBackgroundColor]];
    [boxText setTextColor:[NSColor controlTextColor]];
    [boxText setSelectedTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor selectedControlTextColor], NSForegroundColorAttributeName, [NSColor selectedTextBackgroundColor], NSBackgroundColorAttributeName, nil]];
    
    // And most importantly...
    [boxText setFieldEditor:YES];
    [boxText setDelegate:self];
}

/* Creates a text view inside the given box that will grow to fit its contents. The text view will grow no larger than the box itself, though. Because text views always grow to the right, however, special handling is needed in textViewDidChangeFrame: for keeping the centered view centered and the right-aligned view pinned to the right. In addition, a shrinking text view does not necessarily cause its superview to repaint the area it just occupied, so we have to handle that in textViewDidChangeFrame: as well.
 */
- (NSTextView *)makeFieldTextWithAlignment:(NSTextAlignment)alignment inBox:(NSBox *)box {    
    // Create the view
    NSRect frame = [[box contentView] bounds];
    NSTextView *boxText = [[NSTextView alloc] initWithFrame:frame];

    // Set up text view
    [self setUpCommonTextViewAttributes:boxText];
    [boxText setAlignment:alignment];

    [boxText setMinSize:NSMakeSize((2.0 * [[boxText textContainer] lineFragmentPadding]), NSHeight(frame))];
    [boxText setMaxSize:frame.size];
    
    if (alignment == NSCenterTextAlignment) {
        [boxText setAutoresizingMask:(NSViewMinXMargin | NSViewMaxXMargin)];
    } else if (alignment == NSRightTextAlignment) {
        [boxText setAutoresizingMask:NSViewMinXMargin];
    } else {
        // NSLeftTextAlignment
        [boxText setAutoresizingMask:NSViewMaxXMargin];
    }
    
    // Add it to the box.
    [box addSubview:boxText];
    [[box contentView] setAutoresizesSubviews:YES];
    [boxText release];

    // Give the field a default value and force layout.
    [boxText setString:DEFAULT_TEXT];
    [boxText sizeToFit];

    NSRect textFrame = [boxText frame];

    // Reposition the view if alignment requires it.
    if (alignment == NSCenterTextAlignment) {
        [boxText setFrameOrigin:NSMakePoint((NSMidX(frame) - (NSWidth(textFrame) / 2.0)), NSMinY(frame))];
    } else if (alignment == NSRightTextAlignment) {
        [boxText setFrameOrigin:NSMakePoint((NSMaxX(frame) - NSWidth(textFrame)), NSMinY(frame))];
    }
    
    // We need to register for frame changes in order to keep the view aligned properly
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textViewDidChangeFrame:) name:NSViewFrameDidChangeNotification object:boxText];
    
    return boxText;
}

/* Creates a clip view inside the given box, then creates a text view inside of that. The text view will grow as necessary to fit its contents, but will never be smaller than the box. The clip view allows the text to scroll.
 */
- (NSTextView *)makeScrollingFieldTextWithAlignment:(NSTextAlignment)alignment inBox:(NSBox *)box {
    // Creates and returns a field editor-ish text view which has been added as a subview of the given box and is retained only by the box.

    NSRect frame = [[box contentView] bounds];
    
    // Create the clip view
    NSClipView *clipView = [[NSClipView alloc] initWithFrame:frame];
    [clipView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    
    // Add it to the box
    [box addSubview:clipView];
    [[box contentView] setAutoresizesSubviews:YES];
    [clipView release];

    // Create the text view
    NSTextView *boxText = [[NSTextView alloc] initWithFrame:frame];

    // Set up text view
    [self setUpCommonTextViewAttributes:boxText];
    [boxText setAlignment:alignment];

    [boxText setMinSize:frame.size];
    [boxText setMaxSize:NSMakeSize(NotQuiteAsLargeNumberForText, NSHeight(frame))];
    [boxText setAutoresizingMask:NSViewNotSizable];
    
    // Add the text view to the clip view.
    [clipView setDocumentView:boxText];
    [clipView setAutoresizesSubviews:NO];
    [boxText release];

    // Give the field a default value and force layout.
    [boxText setString:DEFAULT_TEXT];
    [boxText sizeToFit];

    return boxText;
}

#pragma mark -

/* Called when a non-scrolling text view's frame changes. The method keeps the centered text view centered and the right-aligned text view pinned to the right. In addition, when the text view shrinks the method tells the superview that it needs to redraw the area the text view just vacated.
 */
- (void)textViewDidChangeFrame:(NSNotification *)notification {
    NSTextView *resizedTextView = [notification object];
    NSRect *oldFrame = NULL;
    NSRect newFrame = [resizedTextView frame];
    
    // First move the text view's origin, and figure out which old frame we're dealing with
    if (resizedTextView == leftAlignedTextView) {
        oldFrame = &leftTVKnownFrame;
    } else if (resizedTextView == centerAlignedTextView) {
        NSRect contentBounds = [[centerAlignedBox contentView] bounds];
        [resizedTextView setFrameOrigin:NSMakePoint((NSMidX(contentBounds) - (NSWidth(newFrame) / 2.0)), NSMinY(newFrame))];
        oldFrame = &centerTVKnownFrame;
    } else if (resizedTextView == rightAlignedTextView) {
        NSRect contentBounds = [[rightAlignedBox contentView] bounds];
        [resizedTextView setFrameOrigin:NSMakePoint((NSMaxX(contentBounds) - NSWidth(newFrame)), NSMinY(newFrame))];
        oldFrame = &rightTVKnownFrame;
    }

    // Then check to see if we shrunk.  If we did, our superview will need some redrawing.  NSView should do this itself, but it doesn't as of Leopard.
    if (oldFrame) {
        if (NSWidth(*oldFrame) > NSWidth(newFrame)) {
            // This isn't exactly general code for invalidating the areas we've exposed, but since we know something about the way it happens, we can make a few assumptions.  We know that only the width is changing.  We also know, based on the alignment exactly how the origin is moving based on the size differences.  In other applications these assumptions might not hold.
            CGFloat widthChange = NSWidth(*oldFrame) - NSWidth(newFrame);
            switch ([resizedTextView alignment]) {
                case NSCenterTextAlignment:
                    [[resizedTextView superview] setNeedsDisplayInRect:NSMakeRect(NSMinX(newFrame) - (widthChange / 2.0), NSMinY(newFrame), widthChange / 2.0, NSHeight(newFrame))];
                    [[resizedTextView superview] setNeedsDisplayInRect:NSMakeRect(NSMaxX(newFrame), NSMinY(newFrame), widthChange / 2.0, NSHeight(newFrame))];
                    break;
                case NSRightTextAlignment:
                    [[resizedTextView superview] setNeedsDisplayInRect:NSMakeRect(NSMinX(newFrame) - widthChange, NSMinY(newFrame), widthChange, NSHeight(newFrame))];
                    break;
                case NSLeftTextAlignment:
                default:
                    [[resizedTextView superview] setNeedsDisplayInRect:NSMakeRect(NSMaxX(newFrame), NSMinY(newFrame), widthChange, NSHeight(newFrame))];
                    break;
            }
        }
        // Remember the frame for next time.
        *oldFrame = newFrame;
    }
}

/* Called when editing ends in one of the field editor text views. If the reason was because the user pressed Tab or Backtab (usually shift-Tab), we switch to the next (or previous) key view in the window. Normally this behavior is handled by the NSControl subclass that is using the field editor.
 */
- (void)textDidEndEditing:(NSNotification *)notification {
    NSTextView *text = [notification object];
    NSUInteger whyEnd = [[[notification userInfo] objectForKey:@"NSTextMovement"] unsignedIntegerValue];
    NSTextView *newKeyView = text;

    // Unscroll the previous text.
    [text scrollRangeToVisible:NSMakeRange(0, 0)];
    
    // Find the next valid key view. This is important because NSTabView inserts key views in the focus loop.
    if (whyEnd == NSTabTextMovement) {
        newKeyView = (NSTextView *)[text nextValidKeyView];
    } else if (whyEnd == NSBacktabTextMovement) {
        newKeyView = (NSTextView *)[text previousValidKeyView];
    }

    // Set the new key view and select its whole contents. 
    [[text window] makeFirstResponder:newKeyView];
    [newKeyView setSelectedRange:NSMakeRange(0, [[newKeyView textStorage] length])];
}

#pragma mark -

/* Returns YES if the boxes draw a non-transparent background, NO if not. Since the boxes' background colors are all synchronized, only the non-scrolling left-aligned box is checked. Because it's not safe to use a floating-point value returned from messaging nil, we handle that specially, even though the result is meaningless.
 */
- (BOOL)boxesDrawBackgrounds {
    if (leftAlignedBox == nil) {
        return NO;
    } else {
        return [[leftAlignedBox fillColor] alphaComponent] > 0.0;
    }
}

/* Sets the background color of all the boxes to the text background color if the argument is YES, and to a clear color if the argument is NO.
 */
- (void)setBoxesDrawBackgrounds:(BOOL)shouldDrawBackgrounds {
    NSColor *backgroundColor = (shouldDrawBackgrounds ? [NSColor textBackgroundColor] : [NSColor clearColor]);
    
    [leftAlignedBox setFillColor:backgroundColor];
    [centerAlignedBox setFillColor:backgroundColor];
    [rightAlignedBox setFillColor:backgroundColor];
    
    // The following three lines don't actually affect how the boxes are displayed because the text view inside each of them always takes up the full bounds anyway. They're here anyway to demonstrate that fact.
    [scrollingLeftAlignedBox setFillColor:backgroundColor];
    [scrollingCenterAlignedBox setFillColor:backgroundColor];
    [scrollingRightAlignedBox setFillColor:backgroundColor];
}

#pragma mark -

- (NSString *)title {
    return NSLocalizedString(@"Field-like text", @"Display name for FieldLikeTextController");
}

/* Returns the scroll view that the fields are all contained in. If the correct nib hasn't been loaded yet, it is loaded and the six text views are created.
 */
- (NSView *)containerView {
    if (!containerView) {
        [NSBundle loadNibNamed:@"FieldAspect" owner:self];
        
        // Create the non-scrolling text views
        leftAlignedTextView = [self makeFieldTextWithAlignment:NSLeftTextAlignment inBox:leftAlignedBox];
        centerAlignedTextView = [self makeFieldTextWithAlignment:NSCenterTextAlignment inBox:centerAlignedBox];
        rightAlignedTextView = [self makeFieldTextWithAlignment:NSRightTextAlignment inBox:rightAlignedBox];
        
        // Remember their frames, so we can properly mark their superviews dirty in textViewDidChangeFrame:
        leftTVKnownFrame = [leftAlignedTextView frame];
        centerTVKnownFrame = [centerAlignedTextView frame];
        rightTVKnownFrame = [rightAlignedTextView frame];

        // Create the scrolling text views (and their enclosing clip views)
        scrollingLeftAlignedTextView = [self makeScrollingFieldTextWithAlignment:NSLeftTextAlignment inBox:scrollingLeftAlignedBox];
        scrollingCenterAlignedTextView = [self makeScrollingFieldTextWithAlignment:NSCenterTextAlignment inBox:scrollingCenterAlignedBox];
        scrollingRightAlignedTextView = [self makeScrollingFieldTextWithAlignment:NSRightTextAlignment inBox:scrollingRightAlignedBox];

        // Set up a tab order (which we will have to handle ourselves in the textDidEndEditing: notification).
        [leftAlignedTextView setNextKeyView:centerAlignedTextView];
        [centerAlignedTextView setNextKeyView:rightAlignedTextView];
        [rightAlignedTextView setNextKeyView:scrollingLeftAlignedTextView];
        [scrollingLeftAlignedTextView setNextKeyView:scrollingCenterAlignedTextView];
        [scrollingCenterAlignedTextView setNextKeyView:scrollingRightAlignedTextView];
        [scrollingRightAlignedTextView setNextKeyView:leftAlignedTextView];
    }
    return containerView;
}

/* Rather than use the text view TextViewController provides for us, we pick one of the text views created for the boxes. This is actually necessary since TextSizingController uses this view as the first responder. Note too that it is perfectly fine to override a property accessor, even though the original accessor was synthesized.
 */
- (NSTextView *)textView {
    return [[leftAlignedTextView retain] autorelease];
}

- (void)dealloc {
    [containerView release]; // releases all its subviews as well
    [super dealloc];
}

@end
