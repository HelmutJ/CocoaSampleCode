/*
    File: FindPanelLayoutAppDelegate.m
Abstract: Creates interface elements and lays out the window
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

Copyright (C) 2011 Apple Inc. All Rights Reserved.

*/

#import "FindPanelLayoutAppDelegate.h"
#import <AppKit/NSLayoutConstraint.h>

@implementation FindPanelLayoutAppDelegate

@synthesize window;

/* programmatically create button.  This doesn't demonstrate anything new to autolayout.
 */
- (NSButton *)addPushButtonWithTitle:(NSString *)title identifier:(NSString *)identifier superView:(NSView *)superview {
    NSButton *pushButton = [[[NSButton alloc] init] autorelease];
    [pushButton setIdentifier:identifier];
    [pushButton setBezelStyle:NSRoundRectBezelStyle];
    [pushButton setFont:[NSFont systemFontOfSize:12.0]];        
    [pushButton setAutoresizingMask:NSViewMaxXMargin|NSViewMinYMargin];
    [pushButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [superview addSubview:pushButton];
    if (title) [pushButton setTitle:title];
    
    [pushButton setTarget:self];
    [pushButton setAction:@selector(shuffleTitleOfSender:)];
    
    return pushButton;
}

/* programmatically create text field.  This doesn't demonstrate anything new to autolayout.
 */
- (NSTextField *)addTextFieldWithidentifier:(NSString *)identifier superView:(NSView *)superview {
    NSTextField *textField = [[[NSTextField alloc] init] autorelease];
    [textField setIdentifier:identifier];
    [[textField cell] setControlSize:NSSmallControlSize];
    [textField setBordered:YES];
    [textField setBezeled:YES];
    [textField setSelectable:YES];
    [textField setEditable:YES];
    [textField setFont:[NSFont systemFontOfSize:11.0]];
    [textField setAutoresizingMask:NSViewMaxXMargin|NSViewMinYMargin];
    [textField setTranslatesAutoresizingMaskIntoConstraints:NO];
    [superview addSubview:textField];
    return textField;
}


- (void)awakeFromNib {
    [super awakeFromNib];
    
    /*
     Add views to the window.
     */
    
    NSView *contentView = [[self window] contentView];
    
    id find = [self addPushButtonWithTitle:NSLocalizedString(@"Find", nil) identifier:@"find" superView:contentView];
    id findNext = [self addPushButtonWithTitle:NSLocalizedString(@"Find Next", nil) identifier:@"findNext" superView:contentView];
    id findField = [self addTextFieldWithidentifier:@"findField" superView:contentView];
    id replace = [self addPushButtonWithTitle:NSLocalizedString(@"Replace", nil) identifier:@"replace" superView:contentView];
    id replaceAndFind = [self addPushButtonWithTitle:NSLocalizedString(@"Replace & Find", nil) identifier:@"replaceAndFind" superView:contentView];
    id replaceField = [self addTextFieldWithidentifier:@"replaceField" superView:contentView];
    NSDictionary *views = NSDictionaryOfVariableBindings(find, findNext, findField, replace, replaceAndFind, replaceField);

    /*
     View layout
     */
    
    // Basic layout of the two rows
    // Give the text fields a hard minimum width, because it looks good.
    [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[find]-[findNext]-[findField(>=20)]-|" options:NSLayoutFormatAlignAllTop metrics:nil views:views]];
    [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[replace]-[replaceAndFind]-[replaceField(>=20)]-|" options:NSLayoutFormatAlignAllTop metrics:nil views:views]];
    
    // Vertical layout.  We just need to specify what happens to one thing in each row, since everything within a row is already top aligned.  We'll use the text fields, since then we can align their leading edges as well in one step.
    [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[findField]-[replaceField]-(>=20)-|" options:NSLayoutFormatAlignAllLeading metrics:nil views:views]];
            
    // lower the content hugging priority of the text fields from NSLayoutPriorityDefaultLow, so that they expand to fill extra space rather than the buttons.
    for (NSView *view in [NSArray arrayWithObjects:findField, replaceField, nil]) {
        [view setContentHuggingPriority:NSLayoutPriorityDefaultLow - 1 forOrientation:NSLayoutConstraintOrientationHorizontal];
    }
        
    // In the row in which the buttons are smaller (whichever that is), it is still ambiguous how the buttons expand from their preferred widths to fill the extra space between the window edge and the text field. 
    // They should prefer to be equal width, more weakly than our other constraints.
    [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[find(==findNext@25)]" options:0 metrics:nil views:views]];
    [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[replace(==replaceAndFind@25)]" options:0 metrics:nil views:views]];
        
    // see what it looks like if you visualize some of the constraints.
//    [[contentView window] visualizeConstraints:[replaceField constraintsAffectingLayoutForOrientation:NSLayoutConstraintOrientationHorizontal]];

    // after you see that, try removing the calls to set content hugging priority above, and see what visualization looks like in that case.  This demonstrates an ambiguous situation.
    
    // now, see what it looks like in German and Arabic!
}


- (IBAction)shuffleTitleOfSender:(id)sender {
    NSArray *strings = [NSArray arrayWithObjects:@"S", @"Short", @"Absolutely ginormous string (for a button)", nil];
    NSInteger previousStringIndex = [strings indexOfObject:[sender title]];
    NSInteger nextStringIndex = (((previousStringIndex == NSNotFound) ? -1 : previousStringIndex) + 1) % 3;
    [sender setTitle:[strings objectAtIndex:nextStringIndex]];
}

@end
