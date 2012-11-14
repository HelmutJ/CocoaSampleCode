/*
    File: ImagePickerMenuItemView.m
Abstract: A custom view that is used as an NSMenuItem. This view contains up to 4 images and the logic to track the selection of one of those images.
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

#import "ImagePickerMenuItemView.h"
#import "NSImageThumbnailExtensions.h"


@interface ImagePickerMenuItemView ()

/* declare the selectedIndex property in an anonymous category since it is a private property 
*/
@property(nonatomic, assign) NSInteger selectedIndex;

@end

@implementation ImagePickerMenuItemView

// key for dictionary in NSTrackingAreas's userInfo
#define kTrackerKey @"whichImageView"

#define kNoSelection -1

@synthesize selectedIndex = _selectedIndex;
@synthesize imageUrls = _imageUrls;

/* Make sure that any key value observer of selectedImageUrl is notified when change our internal selected index. 
   Note: Internally, keep track of a selected index so that we can eaasily refer to the imageView spinner and URL associated with index. Externally, supply only a selected URL.
*/
+ (NSSet *)keyPathsForValuesAffectingSelectedImageUrl
{
    return [NSSet setWithObjects:@"selectedIndex", nil];
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.selectedIndex = kNoSelection;
    }
    return self;
}

/* Place all the image views and spinners (circular progress indicators) that are wired up in the nib into NSArrays. This dramtically reduces code allowing us to easily link image view, spinners and URL sets.
*/
- (void)awakeFromNib {
    _imageViews = [[NSArray alloc] initWithObjects:imageView1, imageView2, imageView3, imageView4, nil];
    _spinners = [[NSArray alloc] initWithObjects:spinner1, spinner2, spinner3, spinner4, nil];
}

- (void)dealloc {
    // tracking areas are removed from the view during dealloc, all we need to do is release our area of them
    [_trackingAreas release];
    
    [_imageUrls release];
    [_imageViews release];
    [_spinners release];
    
    [super dealloc];
}

/* Custom selectedIndex property setter so that we can be sure to redraw when the selection index changes.
*/
- (void)setSelectedIndex:(NSInteger)index {
    if (_selectedIndex != index) {
        _selectedIndex = index;
    }
    
    [self setNeedsDisplay:YES];
}

/* Custom selectedIndex property setter so that we can be sure to redraw when the image URLs change. Actually, we need to rebuild our thumbnail images, but we don't do that here because we may not even be visible at the moment. Instead, we mark an internal variable noting that the thumbnails need to be updated. see -viewWillDraw.
*/
- (void)setImageUrls:(NSArray *)urls {
    [_imageUrls autorelease];
    _imageUrls = [urls retain];
    _thumbnailsNeedUpdate = YES;
    [self setNeedsDisplay:YES];
}

/* We must create our own selectedImageUrl property getter as there is no underlying member variable to synthesize to. Simply, return URL from _imageUrls at the selected index.
*/
- (NSURL*)selectedImageUrl {
    NSURL *selectedURL = nil;
    
    NSInteger index = self.selectedIndex;
    if (index >= 0 && index < (NSInteger)[self.imageUrls count]) {
        selectedURL = [self.imageUrls objectAtIndex:index];
    }
    
    return selectedURL;
}

/* Do any last minute layout changes such as updating thumnails because we are about to draw. While we are waiting for the thumbnails to be generated, display animated spinners (circular progress indicators).
*/
- (void)viewWillDraw {
    if (_thumbnailsNeedUpdate) {
        // We may have less images than we had last time. Set all image views to a nil image.
        for (NSImageView *imageView in _imageViews) {
            [imageView setImage:nil];
        }
        
        // animating progress indicators in menus can be tricky. We must wait until the menu window becomes key before starting the animation.
        BOOL windowIsKey = [self.window isKeyWindow];
        
        // Generate the thumbnail for each image in the background
        NSArray *imageUrls = self.imageUrls;
        for (NSInteger index = 0; index < (NSInteger)imageUrls.count; index++) {
            NSImageView *imageView = [_imageViews objectAtIndex:index];
            NSURL *imageUrl = [imageUrls objectAtIndex:index];
            NSProgressIndicator *spinner = [_spinners objectAtIndex:index];
            
            [ITESharedOperationQueue() addOperationWithBlock:^(void) {
                NSImage *thumbnailImage = [NSImage iteThumbnailImageWithContentsOfURL:imageUrl width:NSWidth(imageView.bounds)];

                // Thumbnail generation is complete. Now we need to stop the associated animated spinner, hide it, and set the image view to the thumbnail image. Note: we need to do this on the main thread. This is easily done by adding a block to the main NSOperationQueue
                [[NSOperationQueue mainQueue] addOperationWithBlock:^(void) {
                    [spinner stopAnimation:nil];
                    [spinner setHidden:YES];
                    [imageView setImage:thumbnailImage];
                }];
            }];
            
            // show the spinner while thumbnail generation occurs in the background, but only start the animation if the popup menu window is key.
            [spinner setHidden:NO];
            if (windowIsKey) [spinner startAnimation:nil];
        }
        
        // If the popup menu window is not yet key, then we need to listen for the notification of when it does become key. At that point, we can start animating the spinners.
        if (!windowIsKey) {
            // Use a block variable to hold the notificationObserver token so that we can refer to it inside the notification block.
            __block id notificationObserver = nil;
            notificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidBecomeKeyNotification object:self.window queue:nil usingBlock:^(NSNotification *arg1) {
                for (NSProgressIndicator *spinner in _spinners) {
                    /* Only animate spinners that are visible. This solves two potential problems. First, it only starts spinners for the images that are going to display an image (we may have been given fewer URLs than we have image views). Second, if the thumbnail creation ever completes before the window becomes key we don't want to animate the associated spinner. The code above thumbnail generation code will hide the spinner, so we can rely on that here.
                    */
                    if (![spinner isHidden]) {
                        [spinner startAnimation:nil];
                    }
                }
                
                // Once we get this notification, we can stop listening for more.
                [[NSNotificationCenter defaultCenter] removeObserver:notificationObserver];
            }];
        }
        
        _thumbnailsNeedUpdate = NO;
    }
    
    // It is very import to call up to super!
    [super viewWillDraw];
}

/* If there is a selection, fill a rect behind the selected image view. Since the image view is a subview of this view, it will look like a border around the image.
*/
- (void)drawRect:(NSRect)dirtyRect {
    
    NSInteger index = self.selectedIndex;
    if (index >= 0 && index < (NSInteger)[self.imageUrls count]) {
        NSImageView *selectedImageView = [_imageViews objectAtIndex:index];
        NSRect frame = NSInsetRect([self convertRect:selectedImageView.bounds fromView:selectedImageView], -4.0f, -4.0f);
        [[NSColor selectedMenuItemColor] set];
        NSRectFill(frame);
    }
}

/* As the window that contains the popup menu is created, the view associated with the menu item (this view) is added to the window. When the window is destroyed the view is removed from the window, but still retained by the menu item. A new window is created and destroyed each time a menu is displayed. This makes this method the ideal place to start and stop animations.
*/
- (void)viewDidMoveToWindow {
    if (self.window) {
        // In IB, this view is set to stretch to the width of the menu window. However, we cannot set the springs and struts of our containing image and spinner views to auto center themeselves. We get around this by placing the the image and spinner views inside another, non-resizeable NSView in IB. Now, all we need to do here, is center that one non-resizeable container view.
        NSView *containerView = [[self subviews] objectAtIndex:0];
        NSRect parentFrame = self.frame;
        NSRect centeredFrame = containerView.frame;
        centeredFrame.origin.x = floorf((parentFrame.size.width - centeredFrame.size.width) / 2.0f) + parentFrame.origin.x;
        centeredFrame.origin.y = floorf((parentFrame.size.height - centeredFrame.size.height) / 2.0f) + parentFrame.origin.y;
        containerView.frame = centeredFrame;
        
        // Start any animations here
        // The spinner animation is only done when we need to generate new thumbnail images. See the -viewWillDraw method implementation in this file.
    } else {
        // Make sure that all the spinners stop animating
        for  (NSProgressIndicator *spinner in _spinners) {
            [spinner stopAnimation:nil];
            [spinner setHidden:YES];
        }
    }
}

/* Do everything associated with sending the action from user selection such as terminating menu tracking.
*/
- (void)sendAction {
    NSMenuItem *actualMenuItem = [self enclosingMenuItem];
    
    // Send the action set on the actualMenuItem to the target set on the actualMenuItem, and make come from the actualMenuItem.
    [NSApp sendAction:[actualMenuItem action] to:[actualMenuItem target] from:actualMenuItem];
	
	// dismiss the menu being tracked
	NSMenu *menu = [actualMenuItem menu];
	[menu cancelTracking];
    
	[self setNeedsDisplay:YES];
}

#pragma mark -
#pragma mark Mouse Tracking

/* Mouse tracking is easily accomplished via tracking areas. We setup a tracking area for each image view and watch as the mouse moves in and out of those tracking areas. When a mouse up occurs, we can send our action and close the menu.
*/

/* Properly create a tracking area for an image view.
*/
- (id)trackingAreaForIndex:(NSInteger)index {
    // make tracking data (to be stored in NSTrackingArea's userInfo) so we can later determine the imageView without hit testing
    NSDictionary *trackerData = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:index], kTrackerKey, nil];
    NSView *view = [_imageViews objectAtIndex:index];
    
    // Since the tracking area is going to be added to self, we need to convert image view's bounds to self's coordinate system. We use bounds, instead of frame because the view's frame is in the view's superview's coordinate system and that superview may not be (and in this case is not) self. Therefore, converting bounds to self will work regardless of the view hierarchy relationship.
    NSRect trackingRect = [self convertRect:view.bounds fromView:view];
    NSTrackingAreaOptions trackingOptions = NSTrackingEnabledDuringMouseDrag | NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp;
	NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:trackingRect options:trackingOptions owner:self userInfo:trackerData];
    
    return [trackingArea autorelease];
}

/* The view is automatically asked to update the tracking areas at the appropriate time via this overridable methos. 
*/
- (void)updateTrackingAreas {
    // Remove any existing tracking areas
	if (_trackingAreas) {
        for (NSTrackingArea *trackingArea in _trackingAreas) {
            [self removeTrackingArea:trackingArea];
        }
        
        [_trackingAreas release];
    }
    
    NSTrackingArea *trackingArea;
    _trackingAreas = [[NSMutableArray array] retain];	// keep all tracking areas in an array
    
    /* Add a tracking area for each image view. We use an integer for-loop instead of fast enumeration because we need to link the tracking area to the index.
    */
    for (NSInteger index = 0; index < (NSInteger)_imageViews.count; index++) {
        trackingArea = [self trackingAreaForIndex:index];
        [_trackingAreas addObject:trackingArea];
        [self addTrackingArea: trackingArea];
    }
}

/* The mouse is now over one of our child image views. Update selection.
*/
- (void)mouseEntered:(NSEvent*)event {
    // The index of the image view is stored in the user data.
	NSInteger index = [[(NSDictionary*)[event userData] objectForKey:kTrackerKey] integerValue];
    self.selectedIndex = index;
}

/* The mouse has left one of our child image views. Set the selection to no selection.
*/
- (void)mouseExited:(NSEvent*)event {
    self.selectedIndex = kNoSelection;
}

/* The user released the mouse button. Send the action and let the target ask for the selection. Notice that there is no mouseDown: implementation. This is because the user may have held the mouse down as the menu popped up. Or the user may click on this view, but drag into another menu item. That menu item needs to be able to start tracking the mouse. Therefore, we only keep track of our selection via the tracking areas and send our action to our target when the user releases the mouse button inside this view.
*/
- (void)mouseUp:(NSEvent*)event {
    [self sendAction];
}

#pragma mark -
#pragma mark Keyboard Tracking

/* In addition to tracking the mouse, we want to allow changing our selection via the keyboard.
*/

/* Must return YES from -acceptsFirstResponder or we will not get key events. By default NSView return NO.
*/
- (BOOL)acceptsFirstResponder {
    return YES;
}

/* Set the selected index to the first image view if there is no current selection. We check for a current selection because a mouse down inside a child image view will cause this method to be called and we don't want to change the user's mouse selection.
*/
- (BOOL)becomeFirstResponder {
    if (self.selectedIndex == kNoSelection) {
        self.selectedIndex = 0;
    }
    
    return YES;
}

/* We will lose first responder status when the user arrows up or down, or when the menu window is destroyed. If the user keyboard navigates to another NSMenuItem then remove any selection, and if the menu window is destroyed, then the selection no longer matters.
*/
- (BOOL)resignFirstResponder {
    self.selectedIndex = kNoSelection;
    return YES;
}

/* Do the normal AppKit behavior of calling interpretKeyEvents: to allow the input manager to determine the correct keybinding. It is important to call up to super so that user can navigate to other menu items
*/
- (void)keyDown:(NSEvent *)event {
    [self interpretKeyEvents:[NSArray arrayWithObject:event]];
    [super keyDown:event];
}

/* Catch the commands interpreted by interpretKeyEvents:. Normally, if we don't implement (or any other view in the hierarchy implements) the selector, the system beeps. Menu navigation generally doesn't beep, so stop doCommandBySelector: from calling up the hierarchy just to stop the beep.
*/
- (void)doCommandBySelector:(SEL)selector {
    if (   selector == @selector(moveRight:)
        || selector == @selector(moveLeft:)
        || selector == @selector(moveToBeginningOfLine:)
        || selector == @selector(moveToEndOfLine:)
        || selector == @selector(insertNewline:) )
    {
        [super doCommandBySelector:selector];
    }
    
    // do nothing, let the menu handle it (see call to super in -keyDown:)
    // But don't call super to prevent the system beep
}

/* move the selection to the right
*/
- (void)moveRight:(id)sender {
    NSInteger index = self.selectedIndex + 1;
    index = MIN(index, (NSInteger)[self.imageUrls count] - 1);
    self.selectedIndex = index;
}

/* move the selection to the left
*/
- (void)moveLeft:(id)sender {
    NSInteger index = self.selectedIndex - 1;
    index = MAX(0, index);
    self.selectedIndex = index;
}

/* move the selection to index 0
*/
- (void)moveToBeginningOfLine:(id)sender {
    self.selectedIndex = 0;
}

/* move the selection to the greatest valid index
*/
- (void)moveToEndOfLine:(id)sender {
    self.selectedIndex = [self.imageUrls count] - 1;
}

/* The user pressed return or equivilent, send the action
*/
- (void)insertNewline:(id)sender {
    [self sendAction];
}

/* The key event was not interpreted as a command, so interpretKeyEvents: calls this method. In tis case, we want to check for space, because space is also used to select a menu item.
*/
- (void)insertText:(id)insertString {
    if ([insertString isEqualToString:@" "]) {
        [self sendAction];
    }
}
@end
