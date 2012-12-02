/*
     File: RectsView.m
 Abstract: RectsView is the ruler view's client in this test app. It tries to handle most ruler operations.
  Version: 1.1
 
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


#import "RectsView.h"
#import "ColorRect.h"
#import "NestleView.h"


/* These images are displayed as markers on the rulers. */
static NSImage *leftImage;
static NSImage *rightImage;
static NSImage *topImage;
static NSImage *bottomImage;

/* These strings are used to identify the markers. */

#define STR_LEFT   @"Left Edge"
#define STR_RIGHT  @"Right Edge"
#define STR_TOP    @"Top Edge"
#define STR_BOTTOM @"Bottom Edge"


@implementation RectsView


+ (void)initialize
{
    static BOOL beenHere = NO;
    NSBundle *mainBundle;
    NSString *path;
    NSArray *upArray;
    NSArray *downArray;

    if (beenHere) return;

    beenHere = YES;

    mainBundle = [NSBundle mainBundle];
    path = [mainBundle pathForResource:@"EdgeMarkerLeft" ofType:@"tiff"];
    leftImage = [[NSImage alloc] initByReferencingFile:path];

    path = [mainBundle pathForResource:@"EdgeMarkerRight" ofType:@"tiff"];
    rightImage = [[NSImage alloc] initByReferencingFile:path];

    path = [mainBundle pathForResource:@"EdgeMarkerTop" ofType:@"tiff"];
    topImage = [[NSImage alloc] initByReferencingFile:path];

    path = [mainBundle pathForResource:@"EdgeMarkerBottom" ofType:@"tiff"];
    bottomImage = [[NSImage alloc] initByReferencingFile:path];

    upArray = [NSArray arrayWithObjects:[NSNumber numberWithDouble:2.0], nil];
    downArray = [NSArray arrayWithObjects:[NSNumber numberWithDouble:0.5],
        [NSNumber numberWithDouble:0.2], nil];
    [NSRulerView registerUnitWithName:@"Grummets"
        abbreviation:NSLocalizedString(@"gt", @"Grummets abbreviation string")
        unitToPointsConversionFactor:100.0
        stepUpCycle:upArray stepDownCycle:downArray];

    return;
}


- (id)initWithFrame:(NSRect)frameRect
{
    NSRect aRect;
    ColorRect *firstRect;

    self = [super initWithFrame:frameRect];
    if (!self) return nil;

    [self setBoundsOrigin:NSMakePoint(-108.0, -108.0)];

    rects = [[NSMutableArray alloc] init];
    selectedItem = nil;

    aRect = NSMakeRect(30.0, 45.0, 57.0, 118.0);
    firstRect = [[ColorRect alloc] initWithFrame:aRect color:[NSColor blueColor]];
    [rects addObject:firstRect];
    [firstRect release];

    return self;
}


- (void)setRulerOffsets
{
    NSScrollView *scrollView = [self enclosingScrollView];
    NSRulerView *horizRuler;
    NSRulerView *vertRuler;
    NSView *docView;
    NSView *clientView;
    NSPoint zero;
    docView = [scrollView documentView];
    clientView = self;

    if (!scrollView) return;
    horizRuler = [scrollView horizontalRulerView];
    vertRuler = [scrollView verticalRulerView];
   
    zero = [docView convertPoint:[clientView bounds].origin fromView:clientView];
    [horizRuler setOriginOffset:zero.x - [docView bounds].origin.x];

    [vertRuler setOriginOffset:zero.y - [docView bounds].origin.y];

    return;
}


- (void)awakeFromNib
{
    NSScrollView *scrollView = [self enclosingScrollView];

    if (!scrollView) return;
    [scrollView setHasHorizontalRuler:YES];
    [scrollView setHasVerticalRuler:YES];
    [self setRulerOffsets];
    [self updateRulers];
    [scrollView setRulersVisible:YES];

    return;
}


- (BOOL)acceptsFirstResponder
{
    return YES;
}


- (BOOL)isFlipped
{
    return YES;
}


- (void)drawRect:(NSRect)aRect
{
    NSEnumerator *numer;
    ColorRect *thisRect;
    
    [[NSColor whiteColor] set];
    NSRectFill(aRect);

    numer = [rects objectEnumerator];
    while ((thisRect = [numer nextObject])) {
        if (NSIntersectsRect([thisRect frame], aRect)) {
            [thisRect drawRect:aRect selected:(thisRect == selectedItem)];
        }
    }

    [[NSColor blackColor] set];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(-10.0, 0.0) toPoint:NSMakePoint(10.0, 0.0)];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(0.0, -10.0) toPoint:NSMakePoint(0.0, 10.0)];

    return;
}


- (void)moveselectedItemWithEvent:(NSEvent *)theEvent mouseOffset:(NSPoint)mouseOffset
{
    NSRect oldRect, newRect, bounds;
    NSPoint mouseLoc;

    mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];

    bounds = [self bounds];
    oldRect = newRect = [selectedItem frame];
    newRect.origin.x = mouseLoc.x - mouseOffset.x;
    newRect.origin.y = mouseLoc.y - mouseOffset.y;

    if (NSMinX(newRect) < NSMinX(bounds)) {
        newRect.origin.x = NSMinX(bounds);
    }
    if (NSMaxX(newRect) > NSMaxX(bounds)) {
        newRect.origin.x = NSMaxX(bounds) - NSWidth(newRect);
    }
    if (NSMinY(newRect) < NSMinY(bounds)) {
        newRect.origin.y = NSMinY(bounds);
    }
    if (NSMaxY(newRect) > NSMaxY(bounds)) {
        newRect.origin.y = NSMaxY(bounds) - NSHeight(newRect);
    }

    [selectedItem setFrame:newRect];
    [self updateRulerlinesWithOldRect:oldRect newRect:newRect];
    [self setNeedsDisplayInRect:oldRect];
    [self setNeedsDisplayInRect:newRect];
    return;
}


- (void)mouseDown:(NSEvent *)theEvent
{
    NSEnumerator *numer;
    ColorRect *oldselectedItem = selectedItem;
    ColorRect *thisRect;
    NSPoint mouseLoc;
    NSPoint mouseOffset;
    NSUInteger eventMask;
    BOOL dragged = NO;
    BOOL timerOn = NO;
    NSEvent *autoscrollEvent = nil;

    selectedItem = nil;
    if (![[self window] makeFirstResponder:self]) return;

    mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];

    numer = [rects reverseObjectEnumerator];
    while ((thisRect = [numer nextObject])) {
        if ([self mouse:mouseLoc inRect:[thisRect frame]]) {
            selectedItem = thisRect;
            break;
        }
    }

    if (oldselectedItem != selectedItem) {
        [self setNeedsDisplayInRect:[oldselectedItem frame]];
        [self setNeedsDisplayInRect:[selectedItem frame]];
        [self updateRulers];
    }

    if (selectedItem == nil || [selectedItem isLocked]) return;

    mouseOffset.x = mouseLoc.x - [selectedItem frame].origin.x;
    mouseOffset.y = mouseLoc.y - [selectedItem frame].origin.y;

    eventMask = NSLeftMouseDraggedMask | NSLeftMouseUpMask | NSPeriodicMask;
    while ((theEvent = [[self window] nextEventMatchingMask:eventMask])) {
        NSRect visibleRect = [self visibleRect];

        switch ([theEvent type]) {

            case NSPeriodic:
                if (autoscrollEvent) [self autoscroll:autoscrollEvent];
                [self moveselectedItemWithEvent:autoscrollEvent
                      mouseOffset:mouseOffset];
                break;

            case NSLeftMouseDragged:
                if (!dragged) {
                    [self drawRulerlinesWithRect:[selectedItem frame]];
                }
                dragged = YES;
                mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];

                [self moveselectedItemWithEvent:theEvent mouseOffset:mouseOffset];

                if (![self mouse:mouseLoc inRect:visibleRect]) {
                    if (NO == timerOn) {
                        [NSEvent startPeriodicEventsAfterDelay:0.1 withPeriod:0.1];
                        timerOn = YES;
                        if (autoscrollEvent) [autoscrollEvent release];
                        autoscrollEvent = [theEvent retain];
                    } else {
                        if (autoscrollEvent) [autoscrollEvent release];
                        autoscrollEvent = [theEvent retain];
                   }
                    break;
                } else if (YES == timerOn) {
                    [NSEvent stopPeriodicEvents];
                    timerOn = NO;
                    if (autoscrollEvent) [autoscrollEvent release];
                    autoscrollEvent = nil;
                }

                [self displayIfNeeded];
                break;

            case NSLeftMouseUp:
                if (YES == timerOn) {
                    [NSEvent stopPeriodicEvents];   // No need to set timerOn = NO, since we are returning
                    if (autoscrollEvent) [autoscrollEvent release];
                    autoscrollEvent = nil;
                }
                if (dragged) [self eraseRulerlinesWithRect:[selectedItem frame]];
                [self updateRulers];
                return;

            default:
                break;
        }
    }
    if (autoscrollEvent) [autoscrollEvent release];

    return;
}


- (void)selectRect:(ColorRect *)aColorRect
{
    if (selectedItem == aColorRect) return;

    if (selectedItem) [self setNeedsDisplayInRect:[selectedItem frame]];

    if (aColorRect == nil) selectedItem = nil;
    else if ([rects containsObject:aColorRect]) selectedItem = aColorRect;
    [self updateRulers];
    if (selectedItem) [self setNeedsDisplayInRect:[selectedItem frame]];

    return;
}


- (void)lock:(id)sender
{
    if (selectedItem) {
        [selectedItem setLocked:![selectedItem isLocked]];
        [self setNeedsDisplayInRect:[selectedItem frame]];
    }
    return;
}


#define ZOOMINFACTOR   (2.0)
#define ZOOMOUTFACTOR  (1.0 / ZOOMINFACTOR)

- (void)zoomIn:(id)sender
{
    NSRect tempRect;
    NSRect oldBounds;
    NSScrollView *scrollView = [self enclosingScrollView];

    oldBounds = [self bounds];

    tempRect = [self frame];
    tempRect.size.width = ZOOMINFACTOR * NSWidth(tempRect);
    tempRect.size.height = ZOOMINFACTOR * NSHeight(tempRect);
    [self setFrame:tempRect];

    [self setBoundsSize:oldBounds.size];
    [self setBoundsOrigin:oldBounds.origin];

    if (scrollView) [scrollView setNeedsDisplay:YES];
    else [[self superview] setNeedsDisplay:YES];

    return;
}


- (void)zoomOut:(id)sender
{
    NSRect tempRect;
    NSRect oldBounds;
    NSScrollView *scrollView = [self enclosingScrollView];

    oldBounds = [self bounds];

    tempRect = [self frame];
    tempRect.size.width = ZOOMOUTFACTOR * NSWidth(tempRect);
    tempRect.size.height = ZOOMOUTFACTOR * NSHeight(tempRect);
    [self setFrame:tempRect];

    [self setBoundsSize:oldBounds.size];
    [self setBoundsOrigin:oldBounds.origin];

    if (scrollView) [scrollView setNeedsDisplay:YES];
    else [[self superview] setNeedsDisplay:YES];

    return;
}


/* -nestle: slips a larger view between the enclosing NSClipView and the
 * receiver, and adjusts the ruler origin to lie at the same point in the
 * receiver. Apps that tile pages differently might want to do this when
 * an NSView representing a page is moved. */

- (void)nestle:(id)sender
{
    NSScrollView *enclosingScrollView = [self enclosingScrollView];

    if (!enclosingScrollView) return;

    if ([[self superview] isKindOfClass:[NestleView class]]) {
        [enclosingScrollView setDocumentView:self];
    } else {
        NSRect nFrame, rFrame;
        NestleView *nView;

        rFrame = [self frame];
        nFrame = NSMakeRect(0.0, 0.0, rFrame.size.width + 64.0,
            rFrame.size.height + 64.0);

        nView = [[[NestleView alloc] initWithFrame:nFrame] autorelease];
        [enclosingScrollView setDocumentView:nil];  // self vanishes without this!
        [nView addSubview:self];
        rFrame.origin.x = rFrame.origin.y = 32.0;
        [self setFrame:rFrame];
        [enclosingScrollView setDocumentView:nView];
    }

    [[self window] makeFirstResponder:self];
    [self setRulerOffsets];
    [self updateRulers];
    [enclosingScrollView setNeedsDisplay:YES];
    return;
}


- (void)drawRulerlinesWithRect:(NSRect)aRect;
{
    NSScrollView *scrollView = [self enclosingScrollView];
    NSRulerView *horizRuler;
    NSRulerView *vertRuler;
    NSRect convRect;

    if (!scrollView) return;

    horizRuler = [scrollView horizontalRulerView];
    vertRuler = [scrollView verticalRulerView];

    if (horizRuler) {
        convRect = [self convertRect:aRect toView:horizRuler];

        [horizRuler moveRulerlineFromLocation:-1.0
                toLocation:NSMinX(convRect)];
        [horizRuler moveRulerlineFromLocation:-1.0
                toLocation:NSMaxX(convRect)];
    }

    if (vertRuler) {
        convRect = [self convertRect:aRect toView:vertRuler];

        [vertRuler moveRulerlineFromLocation:-1.0
                toLocation:NSMinY(convRect)];
        [vertRuler moveRulerlineFromLocation:-1.0
                toLocation:NSMaxY(convRect)];
    }
    return;
}


- (void)updateRulerlinesWithOldRect:(NSRect)oldRect newRect:(NSRect)newRect
{
    NSScrollView *scrollView = [self enclosingScrollView];
    NSRulerView *horizRuler;
    NSRulerView *vertRuler;
    NSRect convOldRect, convNewRect;

    if (!scrollView) return;

    horizRuler = [scrollView horizontalRulerView];
    vertRuler = [scrollView verticalRulerView];

    if (horizRuler) {
        convOldRect = [self convertRect:oldRect toView:horizRuler];
        convNewRect = [self convertRect:newRect toView:horizRuler];
        [horizRuler moveRulerlineFromLocation:NSMinX(convOldRect)
                toLocation:NSMinX(convNewRect)];
        [horizRuler moveRulerlineFromLocation:NSMaxX(convOldRect)
                toLocation:NSMaxX(convNewRect)];
    }

    if (vertRuler) {
        convOldRect = [self convertRect:oldRect toView:vertRuler];
        convNewRect = [self convertRect:newRect toView:vertRuler];
        [vertRuler moveRulerlineFromLocation:NSMinY(convOldRect)
                toLocation:NSMinY(convNewRect)];
        [vertRuler moveRulerlineFromLocation:NSMaxY(convOldRect)
                toLocation:NSMaxY(convNewRect)];
    }
    return;
}


- (void)eraseRulerlinesWithRect:(NSRect)aRect;
{
    NSScrollView *scrollView = [self enclosingScrollView];
    NSRulerView *horizRuler;
    NSRulerView *vertRuler;

    if (!scrollView) return;

    horizRuler = [scrollView horizontalRulerView];
    vertRuler = [scrollView verticalRulerView];

    if (horizRuler) {
        [horizRuler setNeedsDisplay:YES];
    }

    if (vertRuler) {
        [vertRuler setNeedsDisplay:YES];
    }
    return;
}


- (void)updateHorizontalRuler
{
    NSScrollView *scrollView;
    NSRulerView *horizRuler;
    NSRulerMarker *leftMarker;
    NSRulerMarker *rightMarker;


    scrollView = [self enclosingScrollView];
    if (!scrollView) return;

    horizRuler = [scrollView horizontalRulerView];
    if (!horizRuler) return;

    if ([horizRuler clientView] != self) {
        [horizRuler setClientView:self];
        [horizRuler setMeasurementUnits:@"Grummets"];
    }

    if (!selectedItem) {
        [horizRuler setMarkers:nil];
        return;
    }

    leftMarker = [[NSRulerMarker alloc] initWithRulerView:horizRuler
        markerLocation:NSMinX([selectedItem frame]) image:leftImage
        imageOrigin:NSMakePoint(0.0, 0.0)];

    rightMarker = [[NSRulerMarker alloc] initWithRulerView:horizRuler
        markerLocation:NSMaxX([selectedItem frame]) image:rightImage
        imageOrigin:NSMakePoint(7.0, 0.0)];

    [leftMarker setRemovable:YES];
    [rightMarker setRemovable:YES];
    [leftMarker setRepresentedObject:STR_LEFT];
    [rightMarker setRepresentedObject:STR_RIGHT];

    [horizRuler setMarkers:[NSArray arrayWithObjects:leftMarker, rightMarker, nil]];

    [leftMarker release];
    [rightMarker release];
    
    return;
}


- (void)updateVerticalRuler
{
    NSScrollView *scrollView;
    NSRulerView *vertRuler;
    NSPoint thePoint;   /* Just a temporary scratch variable */
    CGFloat location;
    NSRulerMarker *topMarker;
    NSRulerMarker *bottomMarker;

    scrollView = [self enclosingScrollView];
    if (!scrollView) return;

    vertRuler = [scrollView verticalRulerView];
    if (!vertRuler) return;

    if ([vertRuler clientView] != self) {
        [vertRuler setClientView:self];
        [vertRuler setMeasurementUnits:@"Grummets"];
    }

    if (!selectedItem) {
        [vertRuler setMarkers:nil];
        return;
    }

    if ([self isFlipped]) location = NSMaxY([selectedItem frame]);
    else location = NSMinY([selectedItem frame]);
    
    thePoint = NSMakePoint(8.0, 1.0);
    bottomMarker = [[NSRulerMarker alloc] initWithRulerView:vertRuler
        markerLocation:location image:bottomImage
        imageOrigin:thePoint];
    [bottomMarker setRemovable:YES];
    [bottomMarker setRepresentedObject:STR_BOTTOM];

    if ([self isFlipped]) location = NSMinY([selectedItem frame]);
    else location = NSMaxY([selectedItem frame]);

    thePoint = NSMakePoint(8.0, 8.0);
    topMarker = [[NSRulerMarker alloc] initWithRulerView:vertRuler
        markerLocation:location image:topImage
        imageOrigin:thePoint];
    [topMarker setRemovable:YES];
    [topMarker setRepresentedObject:STR_TOP];

    [vertRuler setMarkers:[NSArray arrayWithObjects:bottomMarker, topMarker, nil]];

    [topMarker release];
    [bottomMarker release];

    return;
}


- (void)updateRulers
{
    [self updateHorizontalRuler];
    [self updateVerticalRuler];
    return;
}


- (void)updateSelectedRectFromRulers
{
    NSRulerView *horizRuler;
    NSRulerView *vertRuler;
    NSArray *markers;
    CGFloat m1Loc, m2Loc;
    NSRect newRect;

    if (!selectedItem) return;

    horizRuler = [[self enclosingScrollView] horizontalRulerView];
    markers = [horizRuler markers];
    if ([markers count] != 2) return;

    m1Loc = [[markers objectAtIndex:0] markerLocation];
    m2Loc = [[markers objectAtIndex:1] markerLocation];
    if (m1Loc < m2Loc) {
        newRect.origin.x = m1Loc;
        newRect.size.width = m2Loc - m1Loc;
    } else {
        newRect.origin.x = m2Loc;
        newRect.size.width = m1Loc - m2Loc;
    }

    vertRuler = [[self enclosingScrollView] verticalRulerView];
    markers = [vertRuler markers];
    if ([markers count] != 2) return;

    m1Loc = [[markers objectAtIndex:0] markerLocation];
    m2Loc = [[markers objectAtIndex:1] markerLocation];
    if (m1Loc < m2Loc) {
        newRect.origin.y = m1Loc;
        newRect.size.height = m2Loc - m1Loc;
    } else {
        newRect.origin.y = m2Loc;
        newRect.size.height = m1Loc - m2Loc;
    }

    [self setNeedsDisplayInRect:[selectedItem frame]];
    [selectedItem setFrame:newRect];
    [self setNeedsDisplayInRect:newRect];

    return;
}


/***********
 * NSRulerView client methods
 */

- (BOOL)rulerView:(NSRulerView *)aRulerView
    shouldMoveMarker:(NSRulerMarker *)aMarker
{
    if (!selectedItem || [selectedItem isLocked]) return NO;
    return YES;
}


- (CGFloat)rulerView:(NSRulerView *)aRulerView
    willMoveMarker:(NSRulerMarker *)aMarker
    toLocation:(CGFloat)location
{
    NSEvent *currentEvent;
    NSUInteger eventFlags;
    BOOL shifted;
    NSRect rect, dirtyRect;
    NSString *theEdge = (NSString *)[aMarker representedObject];

    if (!selectedItem) return location;
    rect = [selectedItem frame];
    dirtyRect = rect;
    dirtyRect.size.width = NSWidth(rect) + 2.0; // fudge to counter hilite prob
    dirtyRect.size.height = NSHeight(rect) + 2.0;
    [self setNeedsDisplayInRect:dirtyRect];

    currentEvent = [NSApp currentEvent];
    eventFlags = [currentEvent modifierFlags];
    shifted = (eventFlags & NSShiftKeyMask) ? YES : NO;

#define MINSIZE (5.0)


    if (!shifted) {
        if ([theEdge isEqualToString:STR_LEFT]) {
            if (location > (NSMaxX(rect) - MINSIZE)) {
                location = (NSMaxX(rect) - MINSIZE);
            }
            rect.size.width = NSMaxX(rect) - location;
            rect.origin.x = location;
        }
        else if ([theEdge isEqualToString:STR_RIGHT]) {
            if (location < (NSMinX(rect) + MINSIZE)) {
                location = (NSMinX(rect) + MINSIZE);
            }
            rect.size.width = location - NSMinX(rect);
        }
        else if ([theEdge isEqualToString:STR_TOP]) {
            if ([self isFlipped]) {
                if (location > (NSMaxY(rect) - MINSIZE)) {
                    location = (NSMaxY(rect) - MINSIZE);
                }
                rect.size.height = NSMaxY(rect) - location;
                rect.origin.y = location;
            } else {
                if (location < (NSMinY(rect) + MINSIZE)) {
                    location = (NSMinY(rect) + MINSIZE);
                }
                rect.size.height = location - NSMinY(rect);
            }
        }
        else if ([theEdge isEqualToString:STR_BOTTOM]) {
            if ([self isFlipped]) {
                if (location < (NSMinY(rect) + MINSIZE)) {
                    location = (NSMinY(rect) + MINSIZE);
                }
                rect.size.height = location - NSMinY(rect);
            } else {
                if (location > (NSMaxY(rect) - MINSIZE)) {
                    location = (NSMaxY(rect) - MINSIZE);
                }
                rect.size.height = NSMaxY(rect) - location;
                rect.origin.y = location;
            }

        } /* if theEdge equal... */
    } else {
        NSArray *markers = [aRulerView markers];
        NSRulerMarker *otherMarker;

        otherMarker = [markers objectAtIndex:0];
        if (otherMarker == aMarker) otherMarker = [markers objectAtIndex:1];

        if ([theEdge isEqualToString:STR_LEFT]) {
            rect.origin.x = location;
            [otherMarker setMarkerLocation:NSMaxX(rect)];
        }
        else if ([theEdge isEqualToString:STR_RIGHT]) {
            rect.origin.x = location - NSWidth(rect);
            [otherMarker setMarkerLocation:NSMinX(rect)];
        }
        else if ([theEdge isEqualToString:STR_TOP]) {
            if ([self isFlipped]) {
                rect.origin.y = location;
                [otherMarker setMarkerLocation:NSMaxY(rect)];
            } else {
                rect.origin.y = location - NSHeight(rect);
                [otherMarker setMarkerLocation:NSMinY(rect)];
            }
        }
        else if ([theEdge isEqualToString:STR_BOTTOM]) {
            if ([self isFlipped]) {
                rect.origin.y = location - NSHeight(rect);
                [otherMarker setMarkerLocation:NSMinY(rect)];
            } else {
                rect.origin.y = location;
                [otherMarker setMarkerLocation:NSMaxY(rect)];
            }
        }
    }

    [selectedItem setFrame:rect];
    [self setNeedsDisplayInRect:rect];

    return location;
}


- (void)rulerView:(NSRulerView *)aRulerView
    didMoveMarker:(NSRulerMarker *)aMarker
{
    [self updateSelectedRectFromRulers];
    return;
}


- (BOOL)rulerView:(NSRulerView *)aRulerView
    shouldRemoveMarker:(NSRulerMarker *)aMarker
{
    if (selectedItem && ![selectedItem isLocked]) return YES;
    return NO;
}


- (void)rulerView:(NSRulerView *)aRulerView
    didRemoveMarker:(NSRulerMarker *)aMarker
{
    if (!selectedItem) return;

    [self setNeedsDisplayInRect:[selectedItem frame]];
    [rects removeObject:selectedItem];
    selectedItem = nil;
    [self updateRulers];

    return;
}


- (BOOL)rulerView:(NSRulerView *)aRulerView
    shouldAddMarker:(NSRulerMarker *)aMarker
{
    return YES;
}


- (CGFloat)rulerView:(NSRulerView *)aRulerView
    willAddMarker:(NSRulerMarker *)aMarker
    atLocation:(CGFloat)location
{
    return location;
}


static CGFloat frand(void) { return (CGFloat)rand() / (pow(2, 31)-1); }


- (void)rulerView:(NSRulerView *)aRulerView
    didAddMarker:(NSRulerMarker *)aMarker
{
    NSRect visibleRect;
    CGFloat theOtherCoord;
    NSRect newRect;
    NSColor *newColor;
    ColorRect *newColorRect;

    visibleRect = [self visibleRect];

    [aMarker setRemovable:YES];

    if ([aRulerView orientation] == NSHorizontalRuler) {
        theOtherCoord = NSMaxY(visibleRect) - 165.0;
        newRect = NSMakeRect([aMarker markerLocation], theOtherCoord, 115.0, 115.0);
    } else {
        if ([self isFlipped]) {
            theOtherCoord = NSMinX(visibleRect) + 50;
            newRect = NSMakeRect(theOtherCoord, [aMarker markerLocation],
                115.0, 115.0);
        } else {
            theOtherCoord = NSMinX(visibleRect) + 50;
            newRect = NSMakeRect(theOtherCoord, [aMarker markerLocation] - 115.0,
                115.0, 115.0);
        }
    }

    newColor = [NSColor colorWithCalibratedRed:frand() green:frand()
        blue:frand() alpha:1.0];

    newColorRect = [[ColorRect alloc] initWithFrame:newRect color:newColor];
    [rects addObject:newColorRect];
    [newColorRect release];
    [self selectRect:newColorRect];

    return;
}


- (void)rulerView:(NSRulerView *)aRulerView
    handleMouseDown:(NSEvent *)theEvent
{
    NSRulerMarker *newMarker;

    if ([aRulerView orientation] == NSHorizontalRuler) {
        newMarker = [[NSRulerMarker alloc] initWithRulerView:aRulerView
            markerLocation:0.0 image:leftImage imageOrigin:NSZeroPoint];
    } else {
        newMarker = [[NSRulerMarker alloc] initWithRulerView:aRulerView
            markerLocation:0.0 image:topImage imageOrigin:NSMakePoint(8.0, 8.0)];
    }
    [aRulerView trackMarker:newMarker withMouseEvent:theEvent];
    [newMarker release];
    return;
}


- (void)rulerView:(NSRulerView *)aRulerView
    willSetClientView:(NSView *)newClient
{
    return;
}


@end
