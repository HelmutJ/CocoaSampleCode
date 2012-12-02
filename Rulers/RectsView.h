/*
     File: RectsView.h
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


#import <AppKit/AppKit.h>

@class Edge, ColorRect;


/* RectsView is the ruler view's client in this test app. It tries to handle
 * most ruler operations. */

@interface RectsView : NSView
{
    NSMutableArray *rects;
    ColorRect *selectedItem;
}

+ (void)initialize;
- (id)initWithFrame:(NSRect)frameRect;
- (void)awakeFromNib;
- (BOOL)acceptsFirstResponder;
- (void)drawRect:(NSRect)aRect;
- (void)mouseDown:(NSEvent *)theEvent;

- (void)selectRect:(ColorRect *)aColorRect;
- (void)lock:(id)sender;
- (void)zoomIn:(id)sender;
- (void)zoomOut:(id)sender;
- (void)nestle:(id)sender;

- (void)drawRulerlinesWithRect:(NSRect)aRect;
- (void)updateRulerlinesWithOldRect:(NSRect)oldRect newRect:(NSRect)newRect;
- (void)eraseRulerlinesWithRect:(NSRect)aRect;
- (void)updateHorizontalRuler;
- (void)updateVerticalRuler;
- (void)updateRulers;
- (void)updateSelectedRectFromRulers;


- (BOOL)rulerView:(NSRulerView *)aRulerView
    shouldMoveMarker:(NSRulerMarker *)aMarker;
- (CGFloat)rulerView:(NSRulerView *)aRulerView
    willMoveMarker:(NSRulerMarker *)aMarker
    toLocation:(CGFloat)location;
- (void)rulerView:(NSRulerView *)aRulerView
    didMoveMarker:(NSRulerMarker *)aMarker;
- (BOOL)rulerView:(NSRulerView *)aRulerView
    shouldRemoveMarker:(NSRulerMarker *)aMarker;
- (void)rulerView:(NSRulerView *)aRulerView
    didRemoveMarker:(NSRulerMarker *)aMarker;
- (BOOL)rulerView:(NSRulerView *)aRulerView
    shouldAddMarker:(NSRulerMarker *)aMarker;
- (CGFloat)rulerView:(NSRulerView *)aRulerView
    willAddMarker:(NSRulerMarker *)aMarker
    atLocation:(CGFloat)location;
- (void)rulerView:(NSRulerView *)aRulerView
    didAddMarker:(NSRulerMarker *)aMarker;
- (void)rulerView:(NSRulerView *)aRulerView
    handleMouseDown:(NSEvent *)theEvent;
- (void)rulerView:(NSRulerView *)aRulerView
    willSetClientView:(NSView *)newClient;


@end
