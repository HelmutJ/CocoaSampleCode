/*
     File: DrawerController.m
 Abstract: Controller for the application.
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

#import "DrawerController.h"

@implementation DrawerController

/****************** Left drawer ******************/

/* Our left drawer is a simple drawer, created in IB, with nothing more than a minimum and maximum size. */

- (void)setupLeftDrawer {
    [leftDrawer setMinContentSize:NSMakeSize(100, 100)];
    [leftDrawer setMaxContentSize:NSMakeSize(400, 400)];
}

/* We do not use [NSDrawer open:] to open the drawer, because that method will
autoselect an edge, and we want this drawer to open only on the left edge. */

- (void)openLeftDrawer:(id)sender {[leftDrawer openOnEdge:NSMinXEdge];}

- (void)closeLeftDrawer:(id)sender {[leftDrawer close];}

- (void)toggleLeftDrawer:(id)sender {
    NSDrawerState state = [leftDrawer state];
    if (NSDrawerOpeningState == state || NSDrawerOpenState == state) {
        [leftDrawer close];
    } else {
        [leftDrawer openOnEdge:NSMinXEdge];
    }
}


/****************** Bottom drawer ******************/

/* Our bottom drawer is created programmatically rather than in IB, and has a 
fixed size both vertically and horizontally.  The fixed vertical size is achieved
by setting min and max content sizes equal to the content size.  The fixed horizontal
size is achieved by setting leading and trailing offsets when the parent window resizes. */ 

- (void)setupBottomDrawer {
    NSSize contentSize = NSMakeSize(100, 100);
    bottomDrawer = [[NSDrawer alloc] initWithContentSize:contentSize preferredEdge:NSMinYEdge];
    [bottomDrawer setParentWindow:myParentWindow];
    [bottomDrawer setMinContentSize:contentSize];
    [bottomDrawer setMaxContentSize:contentSize];
}

- (void)openBottomDrawer:(id)sender {[bottomDrawer openOnEdge:NSMinYEdge];}

- (void)closeBottomDrawer:(id)sender {[bottomDrawer close];}

- (void)toggleBottomDrawer:(id)sender {
    NSDrawerState state = [bottomDrawer state];
    if (NSDrawerOpeningState == state || NSDrawerOpenState == state) {
        [bottomDrawer close];
    } else {
        [bottomDrawer openOnEdge:NSMinYEdge];
    }
}

- (void)setBottomDrawerOffsets {
    NSSize frameSize = [myParentWindow frame].size;
    [bottomDrawer setLeadingOffset:50];
    // we want a bottomDrawer width of approximately 220 unscaled.  Figure out an offset to accomplish that size.
    CGFloat bottomDrawerWidth = 220 * [myParentWindow userSpaceScaleFactor];
    [bottomDrawer setTrailingOffset:frameSize.width - bottomDrawerWidth - 50];
}

/****************** Upper right drawer ******************/

/* Our two right drawers divide the right edge of the parent window between them. 
In addition, they resize together horizontally, in such a way as to maintain a
constant total width. */

- (void)setupUpperRightDrawer {
    NSSize contentSize = NSMakeSize(150, 150);
    upperRightDrawer = [[NSDrawer alloc] initWithContentSize:contentSize preferredEdge:NSMaxXEdge];
    [upperRightDrawer setParentWindow:myParentWindow];
    [upperRightDrawer setDelegate:self];
    [upperRightDrawer setMinContentSize:NSMakeSize(50, 50)];
}

- (void)openUpperRightDrawer:(id)sender {[upperRightDrawer openOnEdge:NSMaxXEdge];}

- (void)closeUpperRightDrawer:(id)sender {[upperRightDrawer close];}

- (void)toggleUpperRightDrawer:(id)sender {
    NSDrawerState state = [upperRightDrawer state];
    if (NSDrawerOpeningState == state || NSDrawerOpenState == state) {
        [upperRightDrawer close];
    } else {
        [upperRightDrawer openOnEdge:NSMaxXEdge];
    }
}


/****************** Lower right drawer ******************/

- (void)setupLowerRightDrawer {
    NSSize contentSize = NSMakeSize(150, 150);
    lowerRightDrawer = [[NSDrawer alloc] initWithContentSize:contentSize preferredEdge:NSMaxXEdge];
    [lowerRightDrawer setParentWindow:myParentWindow];
    [lowerRightDrawer setDelegate:self];
    [lowerRightDrawer setMinContentSize:NSMakeSize(50, 50)];
}

- (void)openLowerRightDrawer:(id)sender {[lowerRightDrawer openOnEdge:NSMaxXEdge];}

- (void)closeLowerRightDrawer:(id)sender {[lowerRightDrawer close];}

- (void)toggleLowerRightDrawer:(id)sender {
    NSDrawerState state = [lowerRightDrawer state];
    if (NSDrawerOpeningState == state || NSDrawerOpenState == state) {
        [lowerRightDrawer close];
    } else {
        [lowerRightDrawer openOnEdge:NSMaxXEdge];
    }
}

- (void)setRightDrawerOffsets {
    NSSize frameSize = [myParentWindow frame].size;
    NSUInteger halfHeight = frameSize.height / 2, remainder = frameSize.height - 2 * halfHeight;
    [upperRightDrawer setLeadingOffset:50];
    [upperRightDrawer setTrailingOffset:halfHeight];
    [lowerRightDrawer setLeadingOffset:halfHeight];
    [lowerRightDrawer setTrailingOffset:50 + remainder];
}

- (void)awakeFromNib {
    [self setupLeftDrawer];
    [self setupBottomDrawer];
    [self setupUpperRightDrawer];
    [self setupLowerRightDrawer];
    [self setBottomDrawerOffsets];
    [self setRightDrawerOffsets];
}

/* For best results, drawers should be resized after the window has resized, so we
do the resizing in windowDidResize:. */

- (void)windowDidResize:(NSNotification *)notification {
    [self setBottomDrawerOffsets];
    [self setRightDrawerOffsets];
}

/* The horizontal sizing of the right drawers is controlled by this drawer delegate method. */

- (NSSize)drawerWillResizeContents:(NSDrawer *)sender toSize:(NSSize)contentSize {
    contentSize.width = 10 * ceil(contentSize.width / 10);
    if (contentSize.width < 50) contentSize.width = 50;
    if (contentSize.width > 250) contentSize.width = 250;
    if (sender == upperRightDrawer) {
        [lowerRightDrawer setContentSize:NSMakeSize(300 - contentSize.width, [lowerRightDrawer contentSize].height)];
    } else if (sender == lowerRightDrawer) {
        [upperRightDrawer setContentSize:NSMakeSize(300 - contentSize.width, [upperRightDrawer contentSize].height)];
    }
    return contentSize;
}

@end
