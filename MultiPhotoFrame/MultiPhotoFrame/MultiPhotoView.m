/*
     File: MultiPhotoView.m 
 Abstract: The class is responsible for the layout of photos and acts as the dragging source and dragging destination of this application.
 Dragging: Dragging can accept 1-4 image files. Add a Finder comment via Get Info for the label. You can drag 1 photo from the window to create
 a new window.
 
 Layout: This view is made up of Photo Cell Views which are laid out automatically. The Cell Views are loaded from a nib file via PhotoCellViewControllers. Since this demo focuses on dragging, layout is done manually on up to 4 image files. If you drop more images to exceed a total of 4, the currently shown images will fade away during the drop animation.
  
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

#import "MultiPhotoView.h"
#import "PhotoCellViewController.h"

#define kPhotoMargin 10.0
#define kMaxDragWidth 200

@interface MultiPhotoView ()
- (NSMapTable *)suggestedLayoutForPhotoCellViewControllers:(NSArray *)pcvControllers;
- (void)layoutPhotos;
- (NSArray *)vewControllersFromPasteboard:(NSPasteboard *)pasteboard;
- (NSArray *)combinedViewControllersForLayoutWithViewController:(NSArray *)newCellViewControllers;
@end

@implementation MultiPhotoView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self registerForDraggedTypes:[NSArray arrayWithObject:(NSString*)kUTTypeURL]];
        photoCellViewControllers = [[NSMutableArray arrayWithCapacity:4] retain];
    }
    
    return self;
}

- (void)dealloc {
    [photoCellViewControllers release];
    [super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [[NSColor whiteColor] set];
    NSRectFill(dirtyRect);
    
    if (highlightForDragAcceptence) {
        [NSGraphicsContext saveGraphicsState];
        NSSetFocusRingStyle(NSFocusRingOnly);
        [[NSBezierPath bezierPathWithRect: NSInsetRect(self.bounds,2,2)] fill];
        [NSGraphicsContext restoreGraphicsState];
    }
}

- (NSArray *)photoCellViewControllers {
    return [[photoCellViewControllers copy] autorelease];
}

- (void)setPhotoCellViewControllers:(NSArray *)newControllers {
    for (PhotoCellViewController *pcvController in photoCellViewControllers) {
        [pcvController.view removeFromSuperview];
    }
    [photoCellViewControllers release];
    
    photoCellViewControllers = [newControllers mutableCopy];
    [self layoutPhotos];
    for (PhotoCellViewController *pcvController in photoCellViewControllers) {
        [self addSubview:pcvController.view];
    }
}

/* Since this is a view container and it's subviews are considered static for this demo, override hit test so the NSImageView doesn't try to participate in drag and drop.
*/
- (NSView *)hitTest:(NSPoint)aPoint {
    return self;
}

/* This method takes an array of PhtoCellViewControllers and returns a map table containing the suggested layout frames of each cell view. The are two reasons for returning a suggestion table instead of setting the frame of each cell view directly. First, the input array of controllers may contain existing cell views along with new ones for the drag images. We don't want to modify existing cell views when we setup the ones for dragging but, we need the complete set of controllers to properly determine the layout. Second, on drop, we want to animate the frame change.
 
    We try to tastefully layout up to 4 images taking into consideration the orientation of the photos. The orientation really only matters for 2 up and 3 up collections. For 2 up, show two portrait panels side-by-side or two Landscape panels stacked. For 3 up, show 1 portrait with two landscapes stacked to the right, or 1 landscape with two side-by-side portraits underneath.
 
    |-----------|    |-------|    |----| |----|    |----| |------|    |-------|
    |           |    |_______|    |    | |    |    |    | |______|    |_______|
    |           | or           or |    | |    | or |    |          or   
    |           |    |-------|    |    | |    |    |    | |------|    |--| |--|
    |___________|    |_______|    |____| |____|    |____| |______|    |__| |__|
 
       |----| |----|
       |____| |____|
    or       
       |----| |----|
       |____| |____|
*/
- (NSMapTable *)suggestedLayoutForPhotoCellViewControllers:(NSArray *)pcvControllers {
    #define setSuggestion(st,ca,i,r) do { [st setObject:[NSValue valueWithRect:r] forKey:[ca objectAtIndex:i]]; }while(0);
    NSMapTable *suggestionTable = [NSMapTable mapTableWithStrongToStrongObjects];
    
    NSInteger photoCount = [pcvControllers count];
    
    CGFloat photoCellWidth, photoCellHeight, xOffset, yOffset;
    
    if (photoCount == 1) {
        photoCellWidth = NSWidth(self.bounds) - (2 * kPhotoMargin);
        photoCellHeight = NSHeight(self.bounds) - (2 * kPhotoMargin);
        setSuggestion(suggestionTable, pcvControllers, 0, NSMakeRect(kPhotoMargin, kPhotoMargin, photoCellWidth, photoCellHeight));
         
    } else if (photoCount == 2) {
        if ([[pcvControllers objectAtIndex:0] photoCellOrientation] == kPhotoCellOrientationPortrait) {
            photoCellWidth = (NSWidth(self.bounds) - (4 * kPhotoMargin)) / 2;
            photoCellHeight = NSHeight(self.bounds) - (2 * kPhotoMargin);
            xOffset = photoCellWidth + (kPhotoMargin * 2);
            yOffset = 0;
        } else {
            photoCellWidth = NSWidth(self.bounds) - (2 * kPhotoMargin);
            photoCellHeight = (NSHeight(self.bounds) - (4 * kPhotoMargin)) / 2;
            xOffset = 0;
            yOffset = photoCellHeight + (kPhotoMargin * 2);
        }
        
        setSuggestion(suggestionTable, pcvControllers, 0, NSMakeRect(kPhotoMargin, kPhotoMargin + yOffset, photoCellWidth, photoCellHeight));
        setSuggestion(suggestionTable, pcvControllers, 1, NSMakeRect(kPhotoMargin + xOffset, kPhotoMargin, photoCellWidth, photoCellHeight));
    } else if (photoCount == 3) {
        NSMutableArray *landscapeArray = [NSMutableArray arrayWithCapacity:3];
        NSMutableArray *portraitArray = [NSMutableArray arrayWithCapacity:3];
        
        for (PhotoCellViewController *pcvController in pcvControllers) {
            if (pcvController.photoCellOrientation == kPhotoCellOrientationLandscape) {
                [landscapeArray addObject:pcvController];
            } else {
                [portraitArray addObject:pcvController];
            }
        }
        
        NSInteger landscapeCount = [landscapeArray count];
        NSInteger portraitCount = [portraitArray count];
        if (landscapeCount > portraitCount) {
            if (landscapeCount == 3) {
                [portraitArray addObject:[landscapeArray objectAtIndex:2]];
                [landscapeArray removeObjectAtIndex:2];
            }
            
            photoCellWidth = (NSWidth(self.bounds) - (4 * kPhotoMargin)) / 2;
            
            photoCellHeight = NSHeight(self.bounds) - (2 * kPhotoMargin);
            setSuggestion(suggestionTable, portraitArray, 0, NSMakeRect(kPhotoMargin, kPhotoMargin, photoCellWidth, photoCellHeight));
            
            photoCellHeight = (NSHeight(self.bounds) - (4 * kPhotoMargin)) / 2;
            xOffset = photoCellWidth + (kPhotoMargin * 2);
            yOffset = photoCellHeight + (kPhotoMargin * 2);
            setSuggestion(suggestionTable, landscapeArray, 0, NSMakeRect(kPhotoMargin + xOffset, kPhotoMargin + yOffset, photoCellWidth, photoCellHeight));
            setSuggestion(suggestionTable, landscapeArray, 1, NSMakeRect(kPhotoMargin + xOffset, kPhotoMargin, photoCellWidth, photoCellHeight));
        } else {
            if (portraitCount == 3) {
                [landscapeArray addObject:[portraitArray objectAtIndex:2]];
                [portraitArray removeObjectAtIndex:2];
            }
            
            photoCellHeight = (NSHeight(self.bounds) - (4 * kPhotoMargin)) / 2;
            yOffset = photoCellHeight + (kPhotoMargin * 2);
            
            photoCellWidth = NSWidth(self.bounds) - (2 * kPhotoMargin);
            [[landscapeArray objectAtIndex:0] view].frame = NSMakeRect(kPhotoMargin, kPhotoMargin + yOffset, photoCellWidth, photoCellHeight);
            setSuggestion(suggestionTable, landscapeArray, 0, NSMakeRect(kPhotoMargin, kPhotoMargin + yOffset, photoCellWidth, photoCellHeight));
            
            photoCellWidth = (NSWidth(self.bounds) - (4 * kPhotoMargin)) / 2;
            xOffset = photoCellWidth + (kPhotoMargin * 2);
            setSuggestion(suggestionTable, portraitArray, 0, NSMakeRect(kPhotoMargin, kPhotoMargin, photoCellWidth, photoCellHeight));
            setSuggestion(suggestionTable, portraitArray, 1, NSMakeRect(kPhotoMargin + xOffset, kPhotoMargin, photoCellWidth, photoCellHeight));
        }
    } else if (photoCount == 4) {
        photoCellWidth = (NSWidth(self.bounds) - (4 * kPhotoMargin)) / 2;
        photoCellHeight = (NSHeight(self.bounds) - (4 * kPhotoMargin)) / 2;
        xOffset = photoCellWidth + (kPhotoMargin * 2);
        yOffset = photoCellHeight + (kPhotoMargin * 2);
        
        setSuggestion(suggestionTable, pcvControllers, 0, NSMakeRect(kPhotoMargin, kPhotoMargin + yOffset, photoCellWidth, photoCellHeight));
        setSuggestion(suggestionTable, pcvControllers, 1, NSMakeRect(kPhotoMargin + xOffset, kPhotoMargin + yOffset, photoCellWidth, photoCellHeight));
        setSuggestion(suggestionTable, pcvControllers, 2, NSMakeRect(kPhotoMargin, kPhotoMargin, photoCellWidth, photoCellHeight));
        setSuggestion(suggestionTable, pcvControllers, 3, NSMakeRect(kPhotoMargin + xOffset, kPhotoMargin, photoCellWidth, photoCellHeight));
    } else {
        assert(!"Too few or too many PhotoCellViewControllers!. I can only deal with 1-4 of them");
    }
    
    return suggestionTable;
}

- (void)layoutPhotos {
    NSMapTable *suggestionTable = [self suggestedLayoutForPhotoCellViewControllers:photoCellViewControllers];
    
    for (PhotoCellViewController *pcvController in photoCellViewControllers) {
        pcvController.view.frame = [[suggestionTable objectForKey:pcvController] rectValue];
    }
}

/* This is a convience method to create new Photo Cell View Controllers from a pasteboard because we need to do this in more than one place.
*/
- (NSArray *)vewControllersFromPasteboard:(NSPasteboard *)pasteboard {
    NSMutableArray *newCellViewControllers = [NSMutableArray arrayWithCapacity:4];
    
    // By using the search options, we can have NSPasteboard narrow the search for us. In this case, we only want files that are images.
    NSDictionary *searchOptions = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSPasteboardURLReadingFileURLsOnlyKey, [NSArray arrayWithObject:(id)kUTTypeImage], NSPasteboardURLReadingContentsConformToTypesKey, nil];
    
    NSArray *pasteboardURLs = [pasteboard readObjectsForClasses:[NSArray arrayWithObject:[NSURL class]] options:searchOptions];
    
    // Create new Photo Cell View Controllers from the image files found on the pasteboard.
    for (NSURL *url in pasteboardURLs) {
        PhotoCellViewController *pcvController = [PhotoCellViewController photoCellViewControllerWithURL:url];
        [newCellViewControllers addObject:pcvController];
    }
    
    return newCellViewControllers;
}

/* This is a convience method to Photo Cell View Controllers because we need to do this in more than one place.
 */
- (NSArray *)combinedViewControllersForLayoutWithViewController:(NSArray *)newCellViewControllers {
    /* Combine the new Photo Cell View Controllers with the existing Photo Cell View Controllers only if the result is 4 or less photos. If the result is greater than 4 photos then we will discard the existing photos on drop. In this case, only use the new Photo Cell View Controllers to determine the new layout.
     */
    NSArray *controllersForLayout;
    if (([photoCellViewControllers count] + [newCellViewControllers count]) <= 4) {
        controllersForLayout = [[photoCellViewControllers mutableCopy] autorelease];
        [(NSMutableArray *)controllersForLayout addObjectsFromArray:newCellViewControllers];
    } else {
        controllersForLayout = newCellViewControllers;
    }
    
    return controllersForLayout;
}

#pragma mark ======== Dragging Source Methods ========

/* The only thing the user can do in this view is drag one of the photos to create a new window. Drag a photo outside of the view to create a new window. Release the photo inside the view and the drag is cancelled and the photo slides back to it's initial position.
 
   This demonstrates how to change the dragging image after you start the drag. 
*/

NSString *kPrivateDragUTI = @"com.apple.private.MultiPhotoViewNewWindow";

- (void)mouseDown:(NSEvent *)event {
    
    // The Photo Cell View Controller knows how to create the image components that make up the drag image. This little loop determines which controller owns the view the mouse down occured in.
    NSPoint mouseLoc = [self convertPoint:[event locationInWindow] fromView:nil];
    for (PhotoCellViewController *pcvController in photoCellViewControllers) {
        if (NSPointInRect(mouseLoc, pcvController.view.frame)) {
            draggingPcvController = pcvController;
            break;
        }
    }
            
    if (draggingPcvController) {
        // Get the URL of the Photo. This URL will be placed on the dragging pasteboard for us.
        NSDictionary *properties = [draggingPcvController representedObject];
        NSURL *imageURL = [properties objectForKey:kImageUrlKey];
        
        // We want a private dragging type so nothing accepts the drop. This way, as the drag source, we can fake an accept drop when creating a new window
        NSPasteboardItem *pbItem = [NSPasteboardItem new];
        [pbItem setString:[imageURL absoluteString] forType:kPrivateDragUTI];
        
        // Now that we have a pasteboard writer we can create our dragging item.
        NSDraggingItem *dragItem = [[NSDraggingItem alloc] initWithPasteboardWriter:pbItem];
        [pbItem release];
        
        // The draggingFrame needs to be in the coordinate space of this view's bounds. This matches exactly with the frame of the Photo Cell View
        dragItem.draggingFrame = draggingPcvController.view.frame;
        
        // The imageComponentsProvider will be called at a later time. We know that the hit Photo Cell View won't change during this drag, so we can just have the existing Photo Cell View Controller build the image components for us.
        dragItem.imageComponentsProvider = ^ {
            return [draggingPcvController imageComponentsForDrag];
        };
        
        // This method creates the drag. The actual drag will start on the next turn of the run loop.
        NSDraggingSession *draggingSession = [self beginDraggingSessionWithItems:[NSArray arrayWithObject:[dragItem autorelease]] event:event source:self];
        
        // Since dragging hasn't started yet, we can adjust the Dragging Session properties here. Alternatively, you can also adjust the NSDraggingSession properties before the drag starts in your own -draggingSession:willBeginAtPoint: method implementation.
        draggingSession.animatesToStartingPositionsOnCancelOrFail = YES;
        
        // The default formation when starting a drag is NSDraggingFormationNone. We are only dragging one item, so the formation is ignored. However, it is highly recommended to always use NSDraggingFormationNone when starting a drag. This way, it feels like the user has physically grabbed the items. Compare this to the items moving, seemingly independantly of the cursor, when the user starts to drag.
        draggingSession.draggingFormation = NSDraggingFormationNone;
        
        // We want to change the drag image when the drag leaves this view but, we don't want to constantly set the drag image for every update. The dragIsInView ivar helps us keep track of when the cursor leaves or enters our view duting drag.
        dragIsInView = YES;
    }
}

- (NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context {
    // This demo does not allow dragging from this view to the Finder or other application
    switch (context) {
        case NSDraggingContextOutsideApplication:
            return NO;
            
        // by using this fall through pattern, we will remain compatible if the context get more precise in the future.
        case NSDraggingContextWithinApplication:
        default:
            return YES;
        break;
    }
}

/* We use this method to track when the drag moves in and out of the view. We will change the drag image when the drag leaves this view, and set it back when the drag re-enteres this view.
*/
- (void)draggingSession:(NSDraggingSession *)session movedToPoint:(NSPoint)screenPoint {
    NSPoint mouseLocInView = [self convertPoint:[self.window convertRectFromScreen:NSMakeRect(screenPoint.x,screenPoint.y, 0, 0)].origin fromView:nil];
    BOOL mouseIsInView = NSPointInRect(mouseLocInView, self.bounds);
    
    // Only update the drag image when the cursor enters or exits this view
    if (mouseIsInView != dragIsInView) {
        if (!mouseIsInView) {
            // The drag has left the view, change the drag image to one that looks like a window
            [session enumerateDraggingItemsWithOptions:0 forView:nil classes:[NSArray arrayWithObject:[NSPasteboardItem class]] searchOptions:nil usingBlock:^(NSDraggingItem *draggingItem, NSInteger idx, BOOL *stop) {
                // Even though we know for certain that there is only one drag item, we still must enumerate in order to change the drag image. However, we can still use this knowledge to simplify the enumeration block.
                
                NSImage *image =[NSImage imageNamed:@"WindowDragImage"];
                NSRect newFrame = NSMakeRect(0, 0, image.size.width, image.size.height);
                
                // As a drag source, we are completely responsible for where the drag image and cursor line up. To simplify things for this example, I'm centering the drag image on the cursor.
                NSPoint dragLoc = session.draggingLocation;
                newFrame.origin.x = dragLoc.x - NSWidth(newFrame) * 0.5;
                newFrame.origin.y = dragLoc.y - NSHeight(newFrame) * 0.5;
                
                [draggingItem setDraggingFrame:newFrame contents:image];
            }];
        } else {
            // The drag has re-entered the view, restore the drag image.
            [session enumerateDraggingItemsWithOptions:0 forView:nil classes:[NSArray arrayWithObject:[NSPasteboardItem class]] searchOptions:nil usingBlock:^(NSDraggingItem *draggingItem, NSInteger idx, BOOL *stop) {
                // Even though we know for certain that there is only one drag item, we still must enumerate in order to change the drag image. However, we can still use this knowledge to simplify the enumeration block.
                                
                // As a drag source, we are completely responsible for where the drag image and cursor line up. Since we are returning 
                NSRect newFrame = draggingPcvController.view.frame;
                NSPoint dragLoc = session.draggingLocation;
                newFrame.origin.x = dragLoc.x - NSWidth(newFrame) * 0.5;
                newFrame.origin.y = dragLoc.y - NSHeight(newFrame) * 0.5;
                draggingItem.draggingFrame = newFrame;
                
                // We are storing the Photo Cell View controller in an ivar during the drag because we know it won't change during the drag. Simply let the Photo Cell View Controller create the imageComponents for us.
                draggingItem.imageComponentsProvider = ^ {
                    return [draggingPcvController imageComponentsForDrag];
                };
            }];
        }
        dragIsInView = mouseIsInView;
        
        // When the user drops the drag, it will technically fail. However, since we can determine if the drag was dropped over our view or not, we can fake a successful drop by making sure the slide back animation does not happen if we want to fake a success. If the user drops inside the view, then instruct the dragging session to do the normal cancel slide back animation.
        session.animatesToStartingPositionsOnCancelOrFail = dragIsInView;
    }
}

/* The drag has ended! We know that it hasn't ended successfully because we set it up to fail. However, if the drop occurred outside our view, then we want to fake a successful drop by placing a new window at the drop location.
*/
- (void)draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation {
    NSPoint mouseLocInView = [self convertPoint:[self.window convertRectFromScreen:NSMakeRect(screenPoint.x,screenPoint.y, 0, 0)].origin fromView:nil];
    BOOL mouseIsInView = NSPointInRect(mouseLocInView, self.bounds);
    
    if (!mouseIsInView) {
        NSWindowController *winController = [[NSWindowController alloc] initWithWindowNibName:@"MultiPhotoFrameWindow"];
        NSWindow *win = winController.window;
        NSSize windowSize = [win frame].size;
        screenPoint.x -= floor(windowSize.width * 0.5);
        screenPoint.y -= floor(windowSize.height * 0.5);
        [win setFrameOrigin:screenPoint];
        
        PhotoCellViewController *pcvController = [[PhotoCellViewController alloc] initWithNibName:@"PhotoCellView" bundle:nil];
        
        // We could grab the url out of session.pasteboard and look up the label from the file system, but since we created the drag we know what the URL and associate data is. It's the same as the representedObject in the dragged Photo Cell View Controller.
        pcvController.representedObject = draggingPcvController.representedObject;
        [pcvController loadView];
        
        MultiPhotoView *photoView = (MultiPhotoView*)[[[win contentView] subviews] objectAtIndex:0];
        photoView.photoCellViewControllers = [NSArray arrayWithObject:pcvController];
        [pcvController release];
        
        [win makeKeyAndOrderFront:nil];
        
        // When the window is closed, we need to release its window controller.
        __block id observer;
        observer = [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowWillCloseNotification object:win queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            [winController release];
            [[NSNotificationCenter defaultCenter] removeObserver:observer];
        }];
    }
}

#pragma mark ======== Dragging Destination Methods ========
/* As a drag destination, this view accepts 1-4 local file URLS at a time. If the addition of the dropped files results in a total of 4 or less photo in the view, then the dragged photos are added to current ones. However, if the drop would result in more than 4 photos, the currently shows photos are removed and we retain just the dropped photos. This demonstrates two animation done inside this view during the drop animation performed by the OS.
 
   Note 1: You can have more than just photos in the drag, but only the photos (up to 4 of them) are accepted. When you do this, notice that the non photo file drag items dissapear and the cursor badge count changes. If you drag back over the Finder, they return.
 
   Note 2: The comment string displayed under the pictures comes from the Finder's comment field of the file. You can change this via the Finder's Get Info panel.
*/

/* A drag that contains our registered drag type has entered this view. Confirm that we can accept the drag and, if needed, setup the accept drag highlight.
*/
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    NSPasteboard *pasteboard = sender.draggingPasteboard;
    
    // By using the search options, we can have NSPasteboard narrow the search for us. In this case, we only want files that are images.
    NSDictionary *searchOptions = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSPasteboardURLReadingFileURLsOnlyKey, [NSArray arrayWithObject:(id)kUTTypeImage], NSPasteboardURLReadingContentsConformToTypesKey, nil];
    
    // Since we aren't changing the dragging images here, just search the pasteboard directly instead of enumerating.
    NSArray *pasteboardURLs = [pasteboard readObjectsForClasses:[NSArray arrayWithObject:[NSURL class]] options:searchOptions];
    
    // accept 1-4 image file urls on the pasteboard
    NSInteger count = [pasteboardURLs count];
    if (count > 0 && count <= 4) {
        highlightForDragAcceptence = YES;
        [self setNeedsDisplay:YES];
    }
    
    return highlightForDragAcceptence ? NSDragOperationCopy : NSDragOperationNone;
}

/* When the OS has determined that this view is a probable drop target, this method is called. This is the best to update the drag image. Otherwise, too many drag image changes would occur, and that would be distracting to the user.
*/
- (void)updateDraggingItemsForDrag:(id<NSDraggingInfo>)sender {
    
    /* Each cell view may have a different size depending on the number and properties of the photos the drag will result in. (See the comments for -suggestedLayoutForPhotoCellViewControllers above.) The only way to determine the cell view size is to get the pasteboard data, combine it with the exising photos and determine the new layout. Once we know the layout, we can enumerate the dragging items and set the new drag images. Remember that this is a time critical section of code as the user is actively dragging. Since this example only allows a maximum 4 photos in the layout, we are ok.
    */
    NSArray *newCellViewControllers = [self vewControllersFromPasteboard:sender.draggingPasteboard];
    NSArray *controllersForLayout = [self combinedViewControllersForLayoutWithViewController:newCellViewControllers];
    NSMapTable *suggestionTable = [self suggestedLayoutForPhotoCellViewControllers:controllersForLayout];
    
    /* We now have a collection of new Photo Cell View Controllers and a table of suggested frames. At this point, set the frames of the new Photo Cell View Controllers' views. We also adjust the frame proportionally from the suggestion so we don't end up with extremely large drag images. The views of the Photo Cell View Controllers have not been added to this view (or any window), so we can change thier frames without affecting the currenlty visible Photos in this view.
    */
    for (PhotoCellViewController *pcvController in newCellViewControllers) {
        NSRect newFrame = [[suggestionTable objectForKey:pcvController] rectValue];
        newFrame.size.width *= kMaxDragWidth / NSHeight(newFrame);
        newFrame.size.height = kMaxDragWidth;
        pcvController.view.frame = newFrame;
    }
    
    /* We have the information we need to enumerate the dragging items and update the drag images.
    */
    
    // By using the search options, we can have NSPasteboard narrow the search for us. In this case, we only want files that are images.
    NSDictionary *searchOptions = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSPasteboardURLReadingFileURLsOnlyKey, [NSArray arrayWithObject:(id)kUTTypeImage], NSPasteboardURLReadingContentsConformToTypesKey, nil];
    /* The drag may contain files that are not images. We don't accept those files so we hide them. But, our enumeration block is only called for the files we accept. The NSDraggingItemEnumerationClearNonenumeratedImages will do the hiding of the non acceptable file for us.
    */
    [sender enumerateDraggingItemsWithOptions:NSDraggingItemEnumerationClearNonenumeratedImages forView:self classes:[NSArray arrayWithObject:[NSURL class]] searchOptions:searchOptions usingBlock:^(NSDraggingItem *draggingItem, NSInteger idx, BOOL *stop) {
        NSURL *url = (NSURL *)draggingItem.item;
        
        // The collection of new Photo Cell View Controllers contain all the information we need, but we need to correlate which Photo Cell View Controller is associated with this pasteboard item.
        PhotoCellViewController *pcvController = nil;
        for (PhotoCellViewController *controller in newCellViewControllers) {
            if ([[controller.representedObject objectForKey:kImageUrlKey] isEqualTo:url]) {
                pcvController = controller;
                break;
            }
        }
        assert(pcvController);
        
        draggingItem.draggingFrame = pcvController.view.frame;
        draggingItem.imageComponentsProvider = ^ {
            /* Loading the image file and rendering it to create the drag image components can be slow, particularly for files on a newtork volumne, or large images or for a large number of files in the drop. One technique for dealing with this is to start caching the images in a background thread during -draggingEntered: for use here. If your background thread does not complete before this method is called, you can flag that you need to updat the images and update them during -draggingUpdate: if that flag is set.
            */
            return [pcvController imageComponentsForDrag];
        };
    }];
    
    // The number of files in the drag may not be the number of files we are accepting. Set the correct count on the dragging info so that the drag cursor badge is updated correctly.
    sender.numberOfValidItemsForDrop = [newCellViewControllers count];
    
    /* It doesn't matter where the user drops inside our view, we will always need to animate to our arranged layout. By setting the formation to NSDraggingFormationPile, the drag items will pile up to the lower right of the cursor.
     
        If we set the formation to NSDraggingFormationNone, then we also have to modify the code above where we adjust the Photo Cell Views to a max size to also adjust the origins.
    */
    sender.draggingFormation = NSDraggingFormationPile;
}

/* Dragging exited out of this view, make sure that we turn off the drag accept highlight
*/
- (void)draggingExited:(id<NSDraggingInfo>)sender {
    highlightForDragAcceptence = NO;
    [self setNeedsDisplay:YES];
}

/* The user has dropped a drag that we had previously validated as acceptable. Set animatesToDestination to YES so that the drag items animate to thier final arranged locations in the view. (See -performDragOperation: below.)
*/
- (BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender {
    sender.animatesToDestination = YES;
    return YES;
}

/* In this method we need to update our data model with the drag contents, tell the drag info where to animate the dragging items and setup animating the exisiting photos. Before this method is called, an NSAnimationContext is already setup with correct duration to match the drop animation of the dragging items.
*/
- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    /* Each cell view may have a different size depending on the number and properties of the photos the drag will result in. (See the comments for -suggestedLayoutForPhotoCellViewControllers above.) The only way to determine the cell view size is to get the pasteboard data, combine it with the exising photos and determine the new layout. Once we know the layout, we can enumerate the dragging items and set the new drag images. Remember that this is a time critical section of code as the user is actively dragging. Since this example only allows a maximum 4 photos in the layout, we are ok.
     */
    NSArray *newCellViewControllers = [self vewControllersFromPasteboard:sender.draggingPasteboard];
    NSArray *controllersForLayout = [self combinedViewControllersForLayoutWithViewController:newCellViewControllers];
    NSMapTable *suggestionTable = [self suggestedLayoutForPhotoCellViewControllers:controllersForLayout];
    
    NSInteger exisingCellViewCount = [photoCellViewControllers count];
    if (exisingCellViewCount > 0 && (exisingCellViewCount + [newCellViewControllers count]) <= 4) {
        // Animate the existing Photos to thier new layout position
        for (PhotoCellViewController *pcvController in photoCellViewControllers) {
            [pcvController.view.animator setFrame:[[suggestionTable objectForKey:pcvController] rectValue]];
        }
    } else {
        // Animate the existing Photos out
        leavingPhotoCellViewControllers = [photoCellViewControllers retain];
        for (PhotoCellViewController *pcvController in leavingPhotoCellViewControllers) {
            [pcvController.view.animator setAlphaValue:0];
        }
    }
    
    // Set the new Photo Views to thier final frames. These views have not been added to the window yet, so visually nothing will happen. We set the dragging items to these frame so that the drag animates to the correct place. (See -concludeDragOperation: for how / when we add these views as subviews.)
    for (PhotoCellViewController *pcvController in newCellViewControllers) {
        pcvController.view.frame = [[suggestionTable objectForKey:pcvController] rectValue];
    }
    
    // Update out model data
    [photoCellViewControllers release];
    photoCellViewControllers = (NSMutableArray *)[controllersForLayout retain];
    
    /* We have the information we need to enumerate the dragging items and update the drag images.
    */
    
    // By using the search options, we can have NSPasteboard narrow the search for us. In this case, we only want files that are images.
    NSDictionary *searchOptions = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSPasteboardURLReadingFileURLsOnlyKey, [NSArray arrayWithObject:(id)kUTTypeImage], NSPasteboardURLReadingContentsConformToTypesKey, nil];
    /* The drag may contain files that are not images. We don't accept those files so we hide them. But, our enumeration block is only called for the files we accept. The NSDraggingItemEnumerationClearNonenumeratedImages will do the hiding of the non acceptable file for us.
     */
    [sender enumerateDraggingItemsWithOptions:NSDraggingItemEnumerationClearNonenumeratedImages forView:self classes:[NSArray arrayWithObject:[NSURL class]] searchOptions:searchOptions usingBlock:^(NSDraggingItem *draggingItem, NSInteger idx, BOOL *stop) {
        
        NSURL *url = (NSURL *)draggingItem.item;
        
        // The collection of new Photo Cell View Controllers contain all the information we need, but we need to correlate which Photo Cell View Controller is associated with this pasteboard item.
        PhotoCellViewController *pcvController = nil;
        for (PhotoCellViewController *controller in newCellViewControllers) {
            if ([[controller.representedObject objectForKey:kImageUrlKey] isEqualTo:url]) {
                pcvController = controller;
                break;
            }
        }
        assert(pcvController);
        
        // This frame needs to be the final frame in this view's coordinates system.
        draggingItem.draggingFrame = pcvController.view.frame;
        draggingItem.imageComponentsProvider = ^ {
            return [pcvController imageComponentsForDrag];
        };
    }];
    
    // erase the drag acceptance highlight
    highlightForDragAcceptence = NO;
    [self setNeedsDisplay:YES];
    
    return YES;
}

/* The drag has concluded. The drag images have animated to the correct place in this view and the existing photos have either animated to thier new frames or to 0 opacity. Note: the drag image is still on the screen. In this method, we need to update our view contents to achieve a seemless transition when the drag image is removed from the screen after this method returns.
*/
- (void)concludeDragOperation:(id<NSDraggingInfo>)sender{
    // If the existing photos animated out, then remove them from the view and release the memory.
    for (PhotoCellViewController *pcvController in leavingPhotoCellViewControllers) {
        [pcvController.view removeFromSuperview];
    }
    [leavingPhotoCellViewControllers release];
    leavingPhotoCellViewControllers = nil;
    
    // Add any Photo Views that are not allready subviews.
    for (PhotoCellViewController *pcvController in photoCellViewControllers) {
        if (![pcvController.view superview]) [self addSubview:pcvController.view];
    }
}

@end

