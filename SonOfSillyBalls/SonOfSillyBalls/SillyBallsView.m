/*
    File:       SillyBallsView.m

    Contains:   View class for drawing lots of silly balls.

    Written by: DTS

    Copyright:  Copyright (c) 1997-2011 Apple Inc. All Rights Reserved.

    Disclaimer: IMPORTANT: This Apple software is supplied to you by Apple Inc.
                ("Apple") in consideration of your agreement to the following
                terms, and your use, installation, modification or
                redistribution of this Apple software constitutes acceptance of
                these terms.  If you do not agree with these terms, please do
                not use, install, modify or redistribute this Apple software.
                In consideration of your agreement to abide by the following
                terms, and subject to these terms, Apple grants you a personal,
                non-exclusive license, under Apple's copyrights in this
                original Apple software (the "Apple Software"), to use,
                reproduce, modify and redistribute the Apple Software, with or
                without modifications, in source and/or binary forms; provided
                that if you redistribute the Apple Software in its entirety and
                without modifications, you must retain this notice and the
                following text and disclaimers in all such redistributions of
                the Apple Software. Neither the name, trademarks, service marks
                or logos of Apple Inc. may be used to endorse or promote
                products derived from the Apple Software without specific prior
                written permission from Apple.  Except as expressly stated in
                this notice, no other rights or licenses, express or implied,
                are granted by Apple herein, including but not limited to any
                patent rights that may be infringed by your derivative works or
                by other works in which the Apple Software may be incorporated.
                The Apple Software is provided by Apple on an "AS IS" basis. 
                APPLE MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING
                WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT,
                MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING
                THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
                COMBINATION WITH YOUR PRODUCTS.
                IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT,
                INCIDENTAL OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
                TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
                DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY
                OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION
                OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY
                OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR
                OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF
                SUCH DAMAGE.
*/

#import "SillyBallsView.h"

@interface SillyBallsView ()

@property (nonatomic, copy,   readonly ) NSString *     textString;     // the text we're drawing
@property (nonatomic, assign, readonly ) NSSize         textSize;       // the size of that text, cached for performance
@property (nonatomic, retain, readwrite) NSTimer *      drawingTimer;   // a timer for drawing the balls

@end

@implementation SillyBallsView

@synthesize running      = running_;
@synthesize ballInterval = ballInterval_;
@synthesize textString   = textString_;
@synthesize textSize     = textSize_;
@synthesize drawingTimer = drawingTimer_;

- (id)initWithFrame:(NSRect)frameRect
    // See comment in interface part.
{
    self = [super initWithFrame:frameRect];
    if (self != nil) {
        self->running_ = NO;
        self->ballInterval_ = 1.0;

        // Init some basic instance variables.
        
        self->textString_ = [@"Bo3b" copy];
        self->textSize_ = [self->textString_ sizeWithAttributes:nil];
        
        // Observe our own properties so that, when they change, we can respond.
        
        [self addObserver:self forKeyPath:@"running" options:0 context:&self->running_];
        [self addObserver:self forKeyPath:@"ballInterval" options:0 context:&self->ballInterval_];
    }
    return self;
}

- (void)dealloc
{
    // Remove our observers.
    
    [self removeObserver:self forKeyPath:@"running"];
    [self removeObserver:self forKeyPath:@"ballInterval"];
    
    // General clean up.
    
    [self->textString_ release];
    [self->drawingTimer_ invalidate];
    [self->drawingTimer_ release];

    [super dealloc];
}

#pragma mark * Drawing

- (CGFloat)randomCGFloat
    // Returns a random floating point number between 0.0 and 1.0.
{
    return ((CGFloat) rand() / (CGFloat) RAND_MAX);
}

static const CGFloat kBallSize = 32.0;

- (void)drawRandomBallInRect:(const NSRect *)rect
    // Draws Silly Ball(tm) at random coordinates within the specified 
    // rectangle.  This method can assume we're in a state ready to draw, 
    // either inside the view's -drawRect: routine, or otherwise having the 
    // focus locked on this view.
{
    NSRect          ballBounds;
    NSBezierPath *  oval;
    NSPoint         textOrigin;

    // Calculate where the ball should go.
    
    ballBounds.origin.x = rect->origin.x + rect->size.width  * [self randomCGFloat];
    ballBounds.origin.y = rect->origin.x + rect->size.height * [self randomCGFloat];
    ballBounds.size.width  = kBallSize;
    ballBounds.size.height = kBallSize;

    // Set the current colour to a random RGB value.

    [[NSColor colorWithDeviceRed:[self randomCGFloat] green:[self randomCGFloat] blue:[self randomCGFloat] alpha:1.0] set];

    // Now construct a bezier path for an circle and draw it.
    
    oval = [NSBezierPath bezierPath];
    [oval appendBezierPathWithOvalInRect:ballBounds];
    [oval fill];

    // Now set the current colour to black and draw the text centred in the ball.
    
    [[NSColor blackColor] set];

    textOrigin = ballBounds.origin;
    textOrigin.x += (ballBounds.size.width  - self.textSize.width ) / 2.0;
    textOrigin.y += (ballBounds.size.height - self.textSize.height) / 2.0;

    [self.textString drawAtPoint:textOrigin withAttributes:nil];
}

- (void)drawRect:(NSRect)rect
    // NSViews are expected to override this method to do their drawing.  We actually 
    // do nothing in this method, because we don't have any persistent state.  All our 
    // drawing is done in response to drawingTimer firing.  See the sample code read me 
    // for a more thorough explanation of this.
{
    #pragma unused(rect)
}

- (void)drawAnother:(NSTimer *)timer
    // This method is called in response to drawingTimer firing.  Its function is to 
    // lock focus on the view and then call -drawRandomBallInRect:.
{
    NSRect visRect;
    
    assert(timer == self.drawingTimer);
    #pragma unused(timer)

    // Lock focus on ourselves.  We need to do this because we're drawing
    // outside of the context of NSView's -drawRect: method.  This is relatively
    // unusual behaviour for a view.  See the discussion of this in the read me.
    
    [self lockFocus];

    // Draw a ball.
    
    visRect = [self visibleRect];
    [self drawRandomBallInRect:&visRect];

    // And unlock the focus.
    
    [self unlockFocus];

    [[self window] flushWindow];
}

#pragma mark * Responding to external events

- (void)clear
    // See comment in interface part.
{
    [self setNeedsDisplay:YES];
}

- (void)startDrawingTimer
{
    // Invalidate any previous repeat timer.
    
    [self.drawingTimer invalidate];

    // Start the new one.
    
    self.drawingTimer = [NSTimer scheduledTimerWithTimeInterval:self.ballInterval target:self selector:@selector(drawAnother:) userInfo:nil repeats:YES];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == &self->running_) {
        assert([keyPath isEqual:@"running"]);
        assert(object == self);

        // When running changes, either start or stop the drawing timer.
        
        if (self.running) {
            [self startDrawingTimer];
        } else {
            [self.drawingTimer invalidate];
            self.drawingTimer = nil;
        }
    } else if (context == &self->ballInterval_) {
    
        // When ballInterval changes, and we're running, update the drawing 
        // timer to use the specified interval.
        
        if (self.running) {
            [self startDrawingTimer];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
