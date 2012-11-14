/*
    File: SuggestibleTextFieldCell.m
Abstract: A custom text field cell to perform two tasks. Draw with white text on a dark background, and expose any associated suggestion window as our accessibility child.
 Version: 1.4

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

#import "SuggestibleTextFieldCell.h"

@implementation SuggestibleTextFieldCell

@synthesize suggestionsWindow = _suggestionsWindow;

/* Force NSTextFieldCell to use white as the text color when drawing on a dark background. NSTextField does this by default when the text color is set to black. In the suggestionsprototype.xib, there is an NSTextField that has a blueish text color. In IB we set the cell of that text field to this class to get the drawing behavior we want.
*/
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    NSColor *textColor = [self textColor];
    if ([self backgroundStyle] == NSBackgroundStyleDark) {
        [self setTextColor:[NSColor whiteColor]];
    }
    
    [super drawWithFrame:cellFrame inView:controlView];
    
    [self setTextColor:textColor];
}

#pragma mark -
#pragma mark Accessibility

/* The search text field in the MainMenu.xib has the class for its cell set to this class so that it will report the suggestions window as one of its accessibility children when the suggestions window is present.
*/
- (id)accessibilityAttributeValue:(NSString *)attribute {
    id attributeValue;
    
    if ([attribute isEqualToString:NSAccessibilityChildrenAttribute] && _suggestionsWindow) {
        attributeValue = [[super accessibilityAttributeValue:NSAccessibilityChildrenAttribute] arrayByAddingObject:NSAccessibilityUnignoredDescendant(_suggestionsWindow)];
    } else {
        attributeValue =  [super accessibilityAttributeValue:attribute];
    }
    
    return attributeValue;
}

@end