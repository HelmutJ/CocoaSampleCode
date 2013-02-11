/*
    File: MainController.m
Abstract: OverlayView shows a simple method to draw one view on top of other views. This example shows lines extending from the edge of a controller to the edge of its superview, imitating Interface Builder.

 Version: 1.0

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

Copyright (C) 2010 Apple Inc. All Rights Reserved.

*/

#import "MainController.h"
#import "OverlayView.h"

@implementation MainController

- (void)awakeFromNib {
    // Programmatically instantiate an OverlayView and add it as the last (frontmost) subview of the outerBox's superview.  (We could instead create the OverlayView in Interface Builder, but adding the OverlayView at runtime keeps the .xib file easier to edit.)
    overlayView = [[OverlayView alloc] initWithFrame:[outerBox frame]];
    
    // Autoresize together with the outerBox.
    [overlayView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    
    // Start out hidden, since we're not initially in editing mode.
    [overlayView setHidden:!editing];
    
    // Let the overlayView know which view it should hit test for mouse events in (we wish to exclude the overlay view itself).
    [overlayView setOverlaidView:outerBox];
    
    // This is the key to making an overlay view work. When we insert the view into the list of subviews, it is added as the last item in the array, making it the last to draw and therefore 'on top' of the other sibling views.
    [[outerBox superview] addSubview:overlayView];
    
    // Work around an issue that prevents the scroll view from drawing correctly with overlay views when [NSClipView copiesOnScroll] == YES
    [[scrollView contentView] setCopiesOnScroll:NO];
}

- (BOOL)editing {
    return editing;
}

- (void)setEditing:(BOOL)edit {
    if (edit != [self editing]) {
        // Show the overlayView only when editing
        editing = edit;
        [overlayView setHidden:!editing];
    }
}

- (void)dealloc {
    [overlayView release];
    [super dealloc];
}

@end
