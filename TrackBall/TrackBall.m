/*
     File: TrackBall.m 
 Abstract: Sample control - TrackBall 
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
  
 Copyright (C) 2011 Apple Inc. All Rights Reserved. 
  
 */

#import "TrackBall.h"
#import "TrackBallUIElement.h"

/* Some metric constants */

/* Space made available for the label */
#define LABEL_HEIGHT 18.

/* Space betwen the label and the trackball. */
#define LABEL_TO_TRACKBALL_PADDING 12.

/* Space between the trackball and the top of our view */
#define TOP_PADDING 3.

// Each of our three label regions is divided into a coordinate static text field portion, and an editable angle portion.
// Determine the portion of space allocated to each by specifying the percentage allocated to the coordinate static text field.
//
#define COORD_PORTION_OF_LABEL_RECT .45

// Determine the duration of the animation when the user enters a value directly into a text field.
#define ROTATION_ANIMATION_DURATION .25

// Determine the default amount to rotate when the user rotates with the keyboard, in radians.
static const CGFloat kDefaultKeyboardRotationAngle = M_PI / 48.;

// Because our control has interior elements that can gain focus, we keep track of which part has the focus
// in our focusedPortion instance variable.  It can take on the values below.
//
enum {
    eFocusOnTrackBall,
    eFocusOnXCoord,
    eFocusOnYCoord,
    eFocusOnZCoord,
    
    eFirstFocusPortion = eFocusOnTrackBall,
    eLastFocusPortion = eFocusOnZCoord
};


// Define a simple struct for use as a 3D point, or axis. 
// We have a number of functions below to manipulate these.
//
typedef struct {
    CGFloat x;
    CGFloat y;
    CGFloat z;
} ThreeVector_t;

/* Define some constant axes that we will find useful too */
static const ThreeVector_t kXAxis = {1, 0, 0};
static const ThreeVector_t kYAxis = {0, 1, 0};
static const ThreeVector_t kZAxis = {0, 0, 1};


// Forward declarations of some mathematical functions.
// Implementations of these are at the bottom of this file.


// Due to accumulated error, we may get values which are slightly under zero. 
// Calling sqrt() on these values produces NaNs, which go on to "infect" other values.
// We want the square root of these values to be zero, so we define a function to return zero in this case.
//
static CGFloat safe_sqrt(CGFloat x);

// Function to calculate the distance between two vectors, via the Pythagorean theorem
//
static CGFloat distance(ThreeVector_t a, ThreeVector_t b);

// Function to normalize a vector -
// that is, return a vector pointing in the same direction as the given vector, but with length 1.
//
static ThreeVector_t normalize(ThreeVector_t a);

// Function to multiply two quaternions (result = q1 * q2)
//
static Quaternion_t multiplyQuaternions(Quaternion_t q1, Quaternion_t q2);

// Convert to our notion of Euler angles, from a quaternion.
// Note that we use a somewhat nonstandard order of application to match Quartz Composer:
// the Z rotation is applied first, followed by the Y rotation, followed by the X rotation.
//
static ThreeVector_t eulerAnglesInDegreesFromQuaternion(Quaternion_t q1);

// Convert a rotation about an axis and an angle to a quaternion.
//
static Quaternion_t quaternionFromAxisAndAngle(ThreeVector_t axis, CGFloat angle);


@interface TrackBall (TrackBallAccessibility)

// We need a forwards declaration of an accessibility method, which must be called whenever our rotation changes.
//
- (void)postAccessibilityValueChangedNotificationsWithOldValues:(NSArray *)oldRotation;

@end


@implementation TrackBall

#pragma mark Metrics methods

// Our trackBallView is always a square, with the ball inscribed; the radius of the ball
// is therefore half the width of the square.
//
- (CGFloat)radius {
    return NSWidth([trackBallView frame]) / 2.;
}

// Return the rect (in our local coordinate system) into which we draw the label portion of our control.
// We draw three labels within this rect, evenly spaced.
//
- (NSRect)fullLabelRect {
    NSRect bounds = [self bounds];
    return NSMakeRect(NSMinX(bounds), NSMinY(bounds), NSWidth(bounds), LABEL_HEIGHT);
}

- (NSRect)labelRectForLabelIndex:(NSUInteger)index {
    NSRect fullLabelRect = [self fullLabelRect];
    CGFloat labelWidth = NSWidth(fullLabelRect) / 3.;
    return NSMakeRect(fullLabelRect.origin.x + index * labelWidth, fullLabelRect.origin.y, labelWidth, fullLabelRect.size.height);
}

// Return the rect (in our local coordinate system) where we set up the editable text
// field when the user begins editing a coordinate, specified by index.
// The text field appears only over the numeric portion, not the coordinate label.
//
- (NSRect)editingRectForLabelIndex:(NSUInteger)index {
    /* Each label rect is the same as the full label rect, only with one third the width */
    NSRect labelRect = [self fullLabelRect];
    labelRect.size.width /= 3.;
    labelRect.origin.x += labelRect.size.width * index;
    NSRect coordPortion, numberPortion;
    NSDivideRect(labelRect, &coordPortion, &numberPortion, NSWidth(labelRect) * COORD_PORTION_OF_LABEL_RECT, NSMinXEdge);
    return numberPortion;
}

// Within mouseDown:, we want to determine if the click landed in the trackball (so we can begin tracking),
// or in a label, or some other location.  The helper method pointIsWithinTrackBall: is used to determine if it
// landed within the ball itself.  We could check to see if the point was inside [trackBallView frame].
// However, [trackBallView frame] is a rectangle, and we only want to consider the circular ball, not the area in the corners.
// Fortunately, the math is simple - compare the distance from the center of the ball to the radius. 
// The center of the ball and the center of [trackBallView frame] coincide!
//
- (BOOL)pointIsWithinTrackBall:(NSPoint)point {
    NSRect trackBallViewFrame = [trackBallView frame];
    NSPoint center = NSMakePoint(NSMidX(trackBallViewFrame), NSMidY(trackBallViewFrame));
    return hypot(point.x - center.x, point.y - center.y) < [self radius];
}

// Helper method to convert a point in our 2D bounds to a 3D point in ball-space.
//
- (ThreeVector_t)unprojectPoint:(NSPoint)point {
    NSPoint pointInBallViewSpace = [trackBallView convertPoint:point fromView:self];
    CGFloat radius = [self radius];
    CGFloat xCoordinate = pointInBallViewSpace.x - radius;
    CGFloat yCoordinate = pointInBallViewSpace.y - radius;
    CGFloat zCoordinate = safe_sqrt(radius * radius - xCoordinate * xCoordinate - yCoordinate * yCoordinate);
    return normalize((ThreeVector_t){xCoordinate, yCoordinate, zCoordinate});
}

// Determine what the frame of trackBallView should be, relative to our bounds.
// This is used for repositioning and resizing trackBallView while our control is changing size.
//
- (NSRect)calculateFrameForBallView {
    NSRect bounds = [self bounds];
    CGFloat availableHeight = fmax(NSHeight(bounds) - LABEL_HEIGHT - LABEL_TO_TRACKBALL_PADDING - TOP_PADDING, 0.);
    CGFloat availableWidth = NSWidth(bounds);
    CGFloat trackBallViewDimension = fmin(availableWidth, availableHeight);
    return NSMakeRect(NSMidX(bounds) - trackBallViewDimension/2., NSMaxY(bounds) - trackBallViewDimension - TOP_PADDING, trackBallViewDimension, trackBallViewDimension);
}

// Determine the closest point within our trackball to the given point (in a 2D coordinate system)
//
- (NSPoint)closestTrackBallPointToPoint:(NSPoint)point {
    NSPoint result;
    CGFloat radius = [self radius];
    NSRect ballFrame = [trackBallView frame];
    CGFloat dx = point.x - NSMidX(ballFrame), dy = point.y - NSMidY(ballFrame);
    CGFloat distance = hypot(dx, dy);
    if (distance < radius) result = point;
    else {
	CGFloat angle = atan2(abs(dy), abs(dx));
	result = NSMakePoint(NSMidX(ballFrame) + cos(angle) * (signbit(dx) ? -radius : radius), NSMidY(ballFrame) + sin(angle) * (signbit(dy) ? -radius : radius));
    }
    return result;
}

#pragma mark Mutator methods

// Update the rotation of our ball view based on our own stored rotation, and cause a redisplay.
//
- (void)updateTrackBallViewRotation {
    ThreeVector_t angles = eulerAnglesInDegreesFromQuaternion(rotation);    
    [trackBallView setValue:[NSNumber numberWithDouble:angles.x] forInputKey:@"X_Rotation"];
    [trackBallView setValue:[NSNumber numberWithDouble:angles.y] forInputKey:@"Y_Rotation"];
    [trackBallView setValue:[NSNumber numberWithDouble:angles.z] forInputKey:@"Z_Rotation"];
    [self setNeedsDisplay:YES];
}

// When the user modifies one of our text fields, we need to change one of our Euler angles.
// We do that by getting the existing Euler angles, modifying the proper one, and then converting back
// to a quaternion by constructing the three quaternions representing each of the rotations specified by the three Euler angles.
//
- (void)setAngle:(CGFloat)angle forIndex:(NSUInteger)coordinateIndex {
    NSMutableArray *angles = [NSMutableArray arrayWithArray:[self objectValue]];
    [angles replaceObjectAtIndex:coordinateIndex withObject:[NSNumber numberWithDouble:angle]];
    [self setObjectValue:angles];
}

// Define KVC compliant methods for rotation around each of our axes (X, Y, and Z).
// This lets us take advantage of Cocoa's animation architecture - we get a rotation animation when the user
// enters text into one of our labels for free.
//
- (void)setXRotation:(CGFloat)rotationValue {
    [self setAngle:rotationValue forIndex:0];
    [NSApp sendAction:[self action] to:[self target] from:self];
}

- (void)setYRotation:(CGFloat)rotationValue {
    [self setAngle:rotationValue forIndex:1];
    [NSApp sendAction:[self action] to:[self target] from:self];
}

- (void)setZRotation:(CGFloat)rotationValue {
    [self setAngle:rotationValue forIndex:2];
    [NSApp sendAction:[self action] to:[self target] from:self];
}

// KVC compliant getters are needed as well
//
- (CGFloat)xRotation {
    return eulerAnglesInDegreesFromQuaternion(rotation).x;
}

- (CGFloat)yRotation {
    return eulerAnglesInDegreesFromQuaternion(rotation).y;
}

- (CGFloat)zRotation {
    return eulerAnglesInDegreesFromQuaternion(rotation).z;
}

// Rotate about a given axis and angle
//
- (void)rotateAboutAxis:(ThreeVector_t)axis byRadians:(CGFloat)angle {
    NSArray *oldRotation = [self objectValue];
    Quaternion_t additionalRotation = quaternionFromAxisAndAngle(axis, angle);
    rotation = multiplyQuaternions(additionalRotation, rotation);
    [self updateTrackBallViewRotation];
    [self postAccessibilityValueChangedNotificationsWithOldValues:oldRotation];
}

// Because our control is not completely opaque, it is nice to know the sort of background it is drawing on.
// We use this to make decisions about its appearance - if it is drawing on a light background, we draw the text dark, for example.
// We simply pass this to our cells.
//
- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle {
    [numberCell setBackgroundStyle:backgroundStyle];
    [editingCell setBackgroundStyle:backgroundStyle];
    [coordCell setBackgroundStyle:backgroundStyle];
    [self setNeedsDisplay:YES];
}


#pragma mark Text editing methods

// editCoordinateAtIndex: is the method that gets called when we want to begin editing one of our text fields.
// This can occur either when the user focuses on one of our text fields and hits the return key, or when the user clicks on one of them.
//
- (void)editCoordinateAtIndex:(NSUInteger)index {
    /* Remember in an instance variable which coordinate we are editing */
    editingLabelIndex = index;
    
    /* Field editors are always NSTextViews, unless they are explicitly overridden */
    NSTextView *fieldEditor = (NSTextView *)[[self window] fieldEditor:YES forObject:numberCell];
    [fieldEditor setHorizontallyResizable:YES];
    
    /* Store the existing value into the cell before we edit it, so that the editing text view has the same value as is currently displayed for that coordinate */
    [editingCell setDoubleValue:[[[self objectValue] objectAtIndex:index] doubleValue]];
    [editingCell selectWithFrame:[self editingRectForLabelIndex:index] inView:self editor:fieldEditor delegate:self start:0 length:[[editingCell stringValue] length]];
}

// textShouldEndEditing: gets called while editing a coordinate, when the user attempts to commit the value.
// We ask the cell's formatter to convert the text in the cell to a number.  If the formatter is unable
// to do so then the input is declared invalid.
// We could perform more sophisticated validation here as well.
//
- (BOOL)textShouldEndEditing:(NSText *)textObject {
    return [[editingCell formatter] numberFromString:[textObject string]] != nil;
}

// textDidEndEditing: gets called when editing is finished.
// It is our responsibility to call endEditing: on the edited cell, and then send our target/action.
//
- (void)textDidEndEditing:(NSNotification *)notification {
    NSString *enteredString = [[notification object] string];
    [editingCell endEditing:[notification object]];
    if ([enteredString length] > 0) {
	CGFloat angle = [enteredString doubleValue];
	
	[NSAnimationContext beginGrouping];
	[[NSAnimationContext currentContext] setDuration:ROTATION_ANIMATION_DURATION];
	switch (editingLabelIndex) {   
	    case 0: [[self animator] setXRotation:angle]; break;
	    case 1: [[self animator] setYRotation:angle]; break;
	    case 2: [[self animator] setZRotation:angle]; break;
	}
	[NSAnimationContext endGrouping];
	
	editingLabelIndex = -1;
	[[self window] makeFirstResponder:self];
    }
}


#pragma mark Drawing methods

// Method to draw a single label.  This gets called three times from within drawRect: - once for each coordinate.
// This will draw the coordinate and angle portion.
//
- (void)drawLabelAtIndex:(NSUInteger)index forAngle:(CGFloat)angleInDegrees inRect:(NSRect)labelRect {
    /* Determine the coordinate label from the index. */
    NSString *const labels[] = {@"X:", @"Y:", @"Z:"};
    NSParameterAssert(index < sizeof labels / sizeof *labels);
    NSString *label = labels[index];
    
    /* Determine if we should draw focused.  If we should, then set the focus style and draw a clear rectangle around the label rect. */
    BOOL drawFocused = [[NSApp keyWindow] firstResponder] == self && focusedPortion == index + 1;
    if (drawFocused) {
        [NSGraphicsContext saveGraphicsState];
        /* To draw the focus rect, fill a bezier path containing the union of the rounded region and one (or both, for the center) halves of the label rect */
        NSSetFocusRingStyle(NSFocusRingOnly);
        [[NSColor clearColor] set];
        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(labelRect, 1, 0) xRadius:30 yRadius:30];
        NSRect leftLabelHalf, rightLabelHalf;
        NSDivideRect(labelRect, &leftLabelHalf, &rightLabelHalf, NSWidth(labelRect) / 2., NSMinXEdge);
        if (index < 2)
            [path appendBezierPathWithRect:rightLabelHalf];
        if (index > 0)
            [path appendBezierPathWithRect:leftLabelHalf];
        [path fill];
        [NSGraphicsContext restoreGraphicsState];
    }

    /* Divide the given rectangle into the coordinate and angle portion, and draw them with the coordCell and numberCell respectively. */
    NSRect coordPortion, numberPortion;
    NSDivideRect(labelRect, &coordPortion, &numberPortion, NSWidth(labelRect) * COORD_PORTION_OF_LABEL_RECT, NSMinXEdge);
    
    [coordCell setObjectValue:label];
    [coordCell drawWithFrame:coordPortion inView:self];
    
    [numberCell setObjectValue:[NSNumber numberWithDouble:angleInDegrees]];
    [numberCell drawWithFrame:numberPortion inView:self];
}

- (void)drawRect:(NSRect)rect {
    /* Draw the focus ring, if it is around our trackball.  The focus ring goes around whatever we draw while the focus ring style is set, even if we draw clear.  In this case, we will draw a clear circle coincident with our trackball, and the focus will go around that. */
    BOOL drawFocused = [[NSApp keyWindow] firstResponder] == self && focusedPortion == eFocusOnTrackBall;
    if (drawFocused) {
	[NSGraphicsContext saveGraphicsState];
	NSSetFocusRingStyle(NSFocusRingOnly);
	[[NSColor clearColor] set];
	[[NSBezierPath bezierPathWithOvalInRect:[trackBallView frame]] fill];
	[NSGraphicsContext restoreGraphicsState];
    }
    
    /* Draw a round rect around our labels.  We can determine how to draw based on our background, which is set in our background style. If the background style is dark, we should draw a dark round rect so that the white labels contrast well.  If the background is light, then a light rect allows the dark labels to constrast well.  */
    NSBackgroundStyle backgroundStyle = [numberCell backgroundStyle];
    if (backgroundStyle == NSBackgroundStyleRaised || backgroundStyle == NSBackgroundStyleLight) [[NSColor colorWithCalibratedWhite:.8 alpha:.5] set];
    else [[NSColor colorWithCalibratedWhite:.2 alpha:.5] set];
    [[NSBezierPath bezierPathWithRoundedRect:[self fullLabelRect] xRadius:30 yRadius:30] fill];
    
    /* Set our cells to draw disabled if our control is disabled */
    [coordCell setEnabled:[self isEnabled]];
    [numberCell setEnabled:[self isEnabled]];
    
    /* Draw the labels. */
    ThreeVector_t eulerAngles = eulerAnglesInDegreesFromQuaternion(rotation);
    [self drawLabelAtIndex:0 forAngle:eulerAngles.x inRect:[self labelRectForLabelIndex:0]];
    [self drawLabelAtIndex:1 forAngle:eulerAngles.y inRect:[self labelRectForLabelIndex:1]];
    [self drawLabelAtIndex:2 forAngle:eulerAngles.z inRect:[self labelRectForLabelIndex:2]];
}

#pragma mark Mouse events

- (void)mouseDown:(NSEvent *)event {
    /* If we are disabled, don't do anything */
    if (! [self isEnabled]) return;

    /* The first thing we do when we receive a mouse click is to make ourselves the first responder and, if that fails, to not do anything (return).  For example, if the user is editing another text field and has entered an invalid value, we do not want to let the user start interacting with our control, until our control can successfully gain focus. */
    if (! [[self window] makeFirstResponder:self]) return;
    
    /* Determine the location, in our local coordinate system, where the user clicked.  We will use this to determine the region of the control in which the user clicked. */
    NSPoint location = [self convertPoint:[event locationInWindow] fromView:nil];
    
    /* When we receive a mouse down event, we reset the dragTrackingLocation.  This way, if the user clicks in the label and then begins to drag, we will not start tracking the mouse.  If the user has clicked in the trackball, we will set this to the location of the click later on in this function. */
    dragTrackingLocation = NSMakePoint(-1, -1);
    
    /* Check if the user clicked within the label portion of our view. */
    if (NSPointInRect(location, [self fullLabelRect])) {
	NSUInteger angleIndex;
	for (angleIndex = 0; angleIndex < 3; angleIndex++) {
	    if (NSPointInRect(location, [self labelRectForLabelIndex:angleIndex])) {
		[self editCoordinateAtIndex:angleIndex];
		break;
	    }
	}
    }
    else if ([self pointIsWithinTrackBall:location]) {
	/* Check if the user clicked within the trackball portion of our view.  If so, we begin mouse tracking.  We could implement this with NSCell's method trackMouse: inRect: ofView: untilMouseUp:.  However, it is easier to set a flag indicating we're mouse tracking (in this case, the dragTrackingLocation point), and then respond to mouseDragged: and mouseUp: events. */
	dragTrackingLocation = location;
	
	/* Because we clicked on the trackball, set our internal focus to the trackball portion of our control, and then trigger a redisplay, so that our focus ring draws. */
	focusedPortion = eFocusOnTrackBall;
	[self setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
    }
}

- (void)mouseDragged:(NSEvent *)event {
    if (! [self isEnabled]) return;

    NSPoint newLocation = [self convertPoint:[event locationInWindow] fromView:nil];
    if (dragTrackingLocation.x == -1 && dragTrackingLocation.y == -1) return;
    
    NSPoint newTrackballLocation = [self closestTrackBallPointToPoint:newLocation];
    
    ThreeVector_t start = [self unprojectPoint:dragTrackingLocation];
    ThreeVector_t end = [self unprojectPoint:newTrackballLocation];
    ThreeVector_t crossProduct = (ThreeVector_t){start.y * end.z - start.z * end.y, start.z * end.x - start.x * end.z, start.x * end.y - start.y * end.x};
    if (crossProduct.x == 0. && crossProduct.y == 0 && crossProduct.z == 0) {
	return;
    }

    ThreeVector_t normalizedCrossProduct = normalize(crossProduct);

    const ThreeVector_t origin = (ThreeVector_t){0, 0, 0};
    CGFloat c = distance(start, end);
    CGFloat a = distance(start, origin);
    CGFloat b = distance(end, origin);
    CGFloat rotationAngle = acos((a*a + b*b - c*c) / (2.*a*b));
    
    [self rotateAboutAxis:normalizedCrossProduct byRadians:rotationAngle];
    dragTrackingLocation = newTrackballLocation;
    [NSApp sendAction:[self action] to:[self target] from:self];
    [self setNeedsDisplay:YES];
}

- (void)scrollWheel:(NSEvent *)event {
    if (! [self isEnabled]) return;

    // A delta of 6 represents a large change.  Let's consider a delta of 6 to represent an eighth of a full rotation - that is, pi/4 radians.
	// Therefore, we multiply by pi/4 and divide by 6, which is equivalent to multiplying by pi/24.
    const CGFloat scrollWheelToRadiansConversionFactor = M_PI/24.;
    CGFloat deltaX = [event deltaX], deltaY = [event deltaY], deltaZ = [event deltaZ];
    if (deltaX != 0.) [self rotateAboutAxis:kYAxis byRadians:-deltaX * scrollWheelToRadiansConversionFactor];
    if (deltaY != 0.) [self rotateAboutAxis:kXAxis byRadians:-deltaY * scrollWheelToRadiansConversionFactor];
    if (deltaZ != 0.) [self rotateAboutAxis:kZAxis byRadians:deltaZ * scrollWheelToRadiansConversionFactor];
    
    /* Send the action too */
    if (deltaX || deltaY || deltaZ) {
	[NSApp sendAction:[self action] to:[self target] from:self];
    }
}


#pragma mark Initialization and deallocation

- (void)dealloc {
    [editingCell release];
    [numberCell release];
    [trackBallView release];
    [coordCell release];
    [super dealloc];
}

// Define a convenience method for initialization common to both initWithFrame: and initWithCoder:.
// This sets up variables that are not archived.
//
- (void)commonTrackBallInit {
    /* We start out not editing any label */
    editingLabelIndex = -1;
    
    /* Create our coordinate cell.  This is used to draw the labels to the left of our angle text fields.  We use the same cell to draw each of the three fields. */
    coordCell = [[NSCell alloc] initTextCell:@""];
    [coordCell setAlignment:NSRightTextAlignment];
    [coordCell setEditable:NO];
    [coordCell setFont:[NSFont labelFontOfSize:13.]];
    
    /* Create our number cell.  This is used to draw the angles to the right of our coordinate labels.  We use the same cell to draw each of the three angles. */
    numberCell = [[NSActionCell alloc] initTextCell:@""];
    [numberCell setTarget:self];
    [numberCell setEditable:YES];
    [numberCell setFont:[NSFont labelFontOfSize:13.]];
    [numberCell setAlignment:NSLeftTextAlignment];
    
    /* Give our angle cell a formatter, so that we get correctly localized decimal numbers, and so we can validate it (so the user can't type in something which is not a number) */
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [formatter setMinimumFractionDigits:1];
    [formatter setMaximumFractionDigits:1];
    [formatter setMinimumIntegerDigits:1];
    [numberCell setFormatter:formatter];
    [formatter release];
    
    /* Use a separate cell for editing our text fields than we use for drawing. */
    editingCell = [numberCell copy];
}

// Designated initializer (along with initWithArchiver:).
// We create our cells, and also our trackBallView, which we add as a subview.
//
- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if(! self) return nil;
    
    /* Initialize common variables */
    [self commonTrackBallInit];
    
    /* Create the trackBallView, set it up properly, and add it as a subview */
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"TrackBallComposition" ofType:@"qtz"];
    trackBallView = [[QCView alloc] initWithFrame:[self calculateFrameForBallView]];
    [trackBallView setEraseColor:[NSColor clearColor]];
    [trackBallView setAutostartsRendering:YES];
    [trackBallView loadCompositionFromFile:path];
    [self addSubview:trackBallView];
    
    /* Finally, set our rotation to the identity. */
    rotation = quaternionFromAxisAndAngle((ThreeVector_t){0, 1, 0}, 0);
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    /* It is acceptable to only support keyed archival.  Non-keyed archival may not support new features of classes and should be considered deprecated. */
    NSAssert([coder allowsKeyedCoding], @"Non-keyed coder given to TrackBall");

    /* We always must call super. */
    [super encodeWithCoder:coder];
    
    /* We only encode our trackBallView and rotation.  We do not encode our cells, instead regenerating them in commonTrackBallInit.  This means that it is easy to change some of the features of these cells - such as, say, the number formatter - without needing to worry about previously encoded versions.  Our view, however, will be encoded by NSView, because it is a subview.  Therefore, it is easier to not regenerate it, and instead encode it. */
    [coder encodeObject:trackBallView forKey:@"TrackBallView"];
    
    /* Encode the rotation.  Notice that we use a common prefix - TrackBall - for our keys.  This is to help prevent collisions in the encoding namespace, as a nod to any subclassers. */
    [coder encodeObject:[self objectValue] forKey:@"TrackBallRotation"];
    
    /* We do not need to encode dragTrackingLocation, editingLabelIndex, or focusedPortion, because these are transient; we also do not need to encode our accessibility faux objects because those can be regenerated when needed.  Also note that our target, action, etc. are encoded by NSControl, when it encodes our cell. */
}

- (id)initWithCoder:(NSCoder *)coder {
    /* It is acceptable to only support keyed archival.  Non-keyed archival may not support new features of classes and should be considered deprecated. */
    NSAssert([coder allowsKeyedCoding], @"Non-keyed coder given to TrackBall");
    
    /* Call through to super, of course. */
    self = [super initWithCoder:coder];
    if (! self) return nil;
    
    /* Initialize common variables */
    [self commonTrackBallInit]; 

    /* Decode our trackBallView.  It is already added as a subview by NSView - so this is just a way to properly set our instance variable.  But remember that we have a retain on it! */
    trackBallView = [[coder decodeObjectForKey:@"TrackBallView"] retain];
    
    /* Decode our object value */
    [self setObjectValue:[coder decodeObjectForKey:@"TrackBallRotation"]];
    
    return self;
}


#pragma mark NSControl overrides

// We override cellClass so that NSControl will construct a proper cell for us.
// This is necessary to take advantage of most of NSControl's machinery, including mouse tracking, and target/action.
// It doesn't have to be a custom cell.  In fact, for TrackBall, we return [NSActionCell class], which is surprisingly high
// on the inheritance hierarchy (that is, less-derived), but is sufficient for our needs, mainly target/action. 
// However, we must be wary of having a cell, because it changes some accessibility behavior - NSControl will now attempt to
// return our cell as an accessible child, and we must take steps within the accessibility methods to defeat that.
//
+ (Class)cellClass {
    return [NSActionCell class];
}

// We support animating our three coordinates.
// To do this, we return the default CABasicAnimation for our three properties - xRotation, yRotation, and zRotation.
// The animation kicks in when the user enters values in the text field.
//
+ (id)defaultAnimationForKey:(NSString *)key {
    if ([key isEqualToString:@"xRotation"] || [key isEqualToString:@"yRotation"] || [key isEqualToString:@"zRotation"]) return [CABasicAnimation animation];
    else return [super defaultAnimationForKey:key];
}

// Our object value is an NSArray of three NSNumbers representing rotation about the X, Y, and Z axes, respectively.
//
- (NSArray *)objectValue {
    ThreeVector_t angles = eulerAnglesInDegreesFromQuaternion(rotation);
    return [NSArray arrayWithObjects:[NSNumber numberWithDouble:angles.x], [NSNumber numberWithDouble:angles.y], [NSNumber numberWithDouble:angles.z], nil];
}

// Implementation of setObjectValue:.
// We will treat a nil object value as a nil rotation - that is, all angles 0.
//
- (void)setObjectValue:(id)value {
    /* Save off the old objectValue so we can compare it against the new object value when we need to send an accessibility notification */
    NSArray *oldRotation = [self objectValue];
    
    ThreeVector_t angles = {0, 0, 0};
    if (value) {
	angles.x = [[value objectAtIndex:0] doubleValue];
	angles.y = [[value objectAtIndex:1] doubleValue];
	angles.z = [[value objectAtIndex:2] doubleValue];	
    }
    
    /* To convert the Euler angles to our internal quaternion representation, we will construct a quaternion for rotation around each of the axes, and then multiply them together in the correct order.  This isn't the most efficient approach, but it's simple and easy to reason about. */
    const CGFloat degreesToRadians = M_PI / 180.;
    Quaternion_t xRotation = quaternionFromAxisAndAngle(kXAxis, angles.x * degreesToRadians);
    Quaternion_t yRotation = quaternionFromAxisAndAngle(kYAxis, angles.y * degreesToRadians);
    Quaternion_t zRotation = quaternionFromAxisAndAngle(kZAxis, angles.z * degreesToRadians);
    rotation = multiplyQuaternions(multiplyQuaternions(xRotation, yRotation), zRotation);
    
    /* Reflect the new rotation into our QCView, and then post the accessibility notification. Controls should not send the action from setObjectValue:.  */
    [self updateTrackBallViewRotation];
    [self postAccessibilityValueChangedNotificationsWithOldValues:oldRotation];
}

// acceptsFirstMouse determines whether we support click-through.
// We do support click through, because a click on us is not destructive.
//
- (BOOL)acceptsFirstMouse:(NSEvent *)event {
    return YES;
}

// We override nextKeyView to prevent our trackBallView, or any of the subviews that Quartz Composer might add to it, from gaining focus.
// Note that isDescendantOf: considers a view to be a descendant of itself.
//
- (NSView *)nextKeyView {
    NSView *result = [super nextKeyView];
    while ([result isDescendantOf:trackBallView]) result = [result nextKeyView];
    return result;
}

// We need a somewhat more sophisticated method for laying out our trackBallView than NSView's default layout machinery can provide.
// We override resizeSubviewsWithOldSize: to position the view the way we want.
//
- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
    [super resizeSubviewsWithOldSize:oldSize];
    [trackBallView setFrame:[self calculateFrameForBallView]];
    if (editingLabelIndex != -1) {
	[[self currentEditor] sizeToFit];
	[[[self currentEditor] superview] setFrame:[self editingRectForLabelIndex:editingLabelIndex]];
    }
}

/* keyDown: override.  There are three different actions we can take, depending on the characters typed:
    Arrow keys cause a rotation.  If the option key is depressed, we rotate about the Z axis.
    Tab changes the focused portion.
    Enter/Return begin editing a text field.
*/
- (void)keyDown:(NSEvent *)event {
    BOOL focusChanged = NO;
    BOOL beginEditing = NO;
    
    BOOL optionKeyPressed = !! ([event modifierFlags] & NSAlternateKeyMask);
    
    CGFloat rotationAngle = 0;
    ThreeVector_t rotationAxis = {0};
    
    NSString *characters = [event characters];
    if ([characters length]) {
	switch ([characters characterAtIndex:0]) {
	    case NSUpArrowFunctionKey:
		rotationAxis = (optionKeyPressed ? kZAxis : kXAxis);
		rotationAngle = -kDefaultKeyboardRotationAngle;
		break;
	    
	    case NSDownArrowFunctionKey:
		rotationAxis = (optionKeyPressed ? kZAxis : kXAxis);
		rotationAngle = kDefaultKeyboardRotationAngle;
		break;
		
	    case NSLeftArrowFunctionKey:
		rotationAxis = (optionKeyPressed ? kZAxis : kYAxis);
		rotationAngle = (optionKeyPressed ? kDefaultKeyboardRotationAngle : -kDefaultKeyboardRotationAngle);
		break;
	    
	    case NSRightArrowFunctionKey:
		rotationAxis = (optionKeyPressed ? kZAxis : kYAxis);
		rotationAngle = (optionKeyPressed ? - kDefaultKeyboardRotationAngle : kDefaultKeyboardRotationAngle);
		break;
	    
	    case NSTabCharacter:
		if (focusedPortion < eLastFocusPortion) {
		    focusedPortion++;
		    focusChanged = YES;
		} else if (focusedPortion == eLastFocusPortion) {
            focusedPortion = eFirstFocusPortion;
            focusChanged = YES;
        }
		break;
	    
	    case NSBackTabCharacter:
		if (focusedPortion > eFirstFocusPortion) {
		    focusedPortion--;
		    focusChanged = YES;
		} else if (focusedPortion == eFirstFocusPortion) {
            focusedPortion = eLastFocusPortion;
            focusChanged = YES;
        }
		break;
		
	    case NSEnterCharacter:
	    case NSNewlineCharacter:
	    case NSCarriageReturnCharacter:
		if (focusedPortion != eFocusOnTrackBall) beginEditing = YES;
		break;
	}
    }
    
    if (rotationAngle != 0.) {
	[self rotateAboutAxis:rotationAxis byRadians:rotationAngle];
	[NSApp sendAction:[self action] to:[self target] from:self];
    }
    else if (focusChanged) {
	NSAccessibilityPostNotification(self, NSAccessibilityFocusedUIElementChangedNotification);
	[self setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
    }
    else if (beginEditing) {
	[self editCoordinateAtIndex: focusedPortion - 1];
    }
    else [super keyDown:event];
}

// We add trackBallView as a subview of us.  However, we want to be responsible for all clicks on our view, so we can do mouse tracking.
// We prevent clicks from falling through to trackBallView by checking [super hitTest:].  If the click landed on trackBallView, we return self instead.
// We could accomplish something similar by always returning self; however, this would prevent any other subviews that client programmers might
// add to us from receiving clicks.
//
- (NSView *)hitTest:(NSPoint)hitPoint {
    NSView *result = [super hitTest:hitPoint];
    if (result == trackBallView) result = self;
    return result;
}

@end


@implementation TrackBall (TrackBallAccessibility)

// Whenever our rotation changes, we need to send out accessibility notifications indicating the change for each of the possibile UI elements.
// For each axis, we have two UI elements that change - the Value Indicator UIElement that's part of our "Slider" (trackball),
// and the UI element representing the text field itself.  Check to see if each particular axis actually changed and, if so, send out the notification.
//
- (void)postAccessibilityValueChangedNotificationsWithOldValues:(NSArray *)oldRotation {
    NSArray *newRotation = [self objectValue];
    NSUInteger i;
    for (i=0; i < 3; i++) {
	if (! [[newRotation objectAtIndex:i] isEqual:[oldRotation objectAtIndex:i]]) {
	    NSAccessibilityPostNotification([axisUIElements objectAtIndex:i], NSAccessibilityValueChangedNotification);
	    NSAccessibilityPostNotification([angleTextFieldUIElements objectAtIndex:i], NSAccessibilityValueChangedNotification);
	}
    }
}

// Our control is accessibility-enabled, so indicate NO from accessibilityIsIgnored
//
- (BOOL)accessibilityIsIgnored {
    return NO;
}

- (NSString *)accessibilityRoleAttribute {
    return NSAccessibilitySliderRole;
}

// Our "slider" can't rightly be said to be vertical or horizontal; therefore, we return an unknown orientation value.
// This constant is not exposed through Cocoa, but is available in the HIServices framework.
//
- (NSString *)accessibilityOrientationAttribute {
    return (NSString *)kAXUnknownOrientationValue;
}

/// Override accessibilityAttributeValue: to return a custom value for NSAccessibilityChildrenAttribute.
// Our TrackBall contains a multitude of children.  It contains three ValueIndicator children which represent rotation along the three axes.
// It also has three editable text fields representing the angles as seen at the bottom, and a label for each of these, for a total of nine children.
//
- (id)accessibilityAttributeValue:(NSString *)attribute {
    if ([attribute isEqualToString:NSAccessibilityChildrenAttribute]) {
	NSMutableArray *result = [NSMutableArray arrayWithArray:[super accessibilityAttributeValue:attribute]];
	
	/* Remove our cell, which does not participate in accessibility */
	[result removeObjectIdenticalTo:[self cell]];
	
	/* Add in three writable ValueIndicator FauxUIElements representing the three axes of rotation */
	if (! axisUIElements) {
	    TrackBallUIElement *xAxisIndicator = [TrackBallUIElement elementWithRole:NSAccessibilityValueIndicatorRole parent:self];
	    TrackBallUIElement *yAxisIndicator = [TrackBallUIElement elementWithRole:NSAccessibilityValueIndicatorRole parent:self];
	    TrackBallUIElement *zAxisIndicator = [TrackBallUIElement elementWithRole:NSAccessibilityValueIndicatorRole parent:self];
	    axisUIElements = [[NSArray alloc] initWithObjects:xAxisIndicator, yAxisIndicator, zAxisIndicator, nil];
	}	
	[result addObjectsFromArray:axisUIElements];
	
	/* Add in three static text FauxUIElements representing the coordinate labels */
	if (! labelUIElements) {
	    TrackBallUIElement *xAxisLabel = [FauxUIElement elementWithRole:NSAccessibilityStaticTextRole parent:self];
	    TrackBallUIElement *yAxisLabel = [FauxUIElement elementWithRole:NSAccessibilityStaticTextRole parent:self];
	    TrackBallUIElement *zAxisLabel = [FauxUIElement elementWithRole:NSAccessibilityStaticTextRole parent:self];
	    labelUIElements = [[NSArray alloc] initWithObjects:xAxisLabel, yAxisLabel, zAxisLabel, nil];
	}
	[result addObjectsFromArray:labelUIElements];
	
	/* Add in three editable text FauxUIElements representing the coordinate values */
	if (! angleTextFieldUIElements) {
	    TrackBallUIElement *xAxisValue = [TrackBallUIElement elementWithRole:NSAccessibilityTextFieldRole parent:self];
	    TrackBallUIElement *yAxisValue = [TrackBallUIElement elementWithRole:NSAccessibilityTextFieldRole parent:self];
	    TrackBallUIElement *zAxisValue = [TrackBallUIElement elementWithRole:NSAccessibilityTextFieldRole parent:self];
	    angleTextFieldUIElements = [[NSArray alloc] initWithObjects:xAxisValue, yAxisValue, zAxisValue, nil];
	    
	    /* Set up the title UI element mapping */
	    NSUInteger i;
	    for (i=0; i < 3; i++) {
		[[angleTextFieldUIElements objectAtIndex:i] accessibilitySetOverrideValue:[labelUIElements objectAtIndex:i] forAttribute:NSAccessibilityTitleUIElementAttribute];
		[[labelUIElements objectAtIndex:i] accessibilitySetOverrideValue:[angleTextFieldUIElements subarrayWithRange:NSMakeRange(i, 1)] forAttribute:NSAccessibilityServesAsTitleForUIElementsAttribute];
	    }
	}
	[result addObjectsFromArray:angleTextFieldUIElements];
	
	return result;
    }
    else return [super accessibilityAttributeValue:attribute];
}

// Return the value for either one of our label cells, or one of our axis elements.
//
- (id)axisUIElementValue:(TrackBallUIElement *)trackBallElement {
    NSUInteger index;
    if ((index = [axisUIElements indexOfObjectIdenticalTo:trackBallElement]) != NSNotFound) {
	return [[self objectValue] objectAtIndex:index];
    }
    else if ((index = [angleTextFieldUIElements indexOfObjectIdenticalTo:trackBallElement]) != NSNotFound) {
	// If we are asked for the value of our text field, we have to return the formatted value.
	// Use setObjectValue: to set it on our text field, and then return its string value
	[numberCell setObjectValue:[[self objectValue] objectAtIndex:index]];
	return [numberCell stringValue];
    }
    else return nil;
}

- (id)axisUIElementDescription:(TrackBallUIElement *)trackBallElement {
    NSUInteger index;
    if ((index = [axisUIElements indexOfObjectIdenticalTo:trackBallElement]) != NSNotFound) {
	switch (index) {
	    case 0: return NSLocalizedString(@"X rotation", @"Accessibility description for X rotation axis");
	    case 1: return NSLocalizedString(@"Y rotation", @"Accessibility description for Y rotation axis");
	    case 2: return NSLocalizedString(@"Z rotation", @"Accessibility description for Z rotation axis");
	}
    }
    else if ((index = [angleTextFieldUIElements indexOfObjectIdenticalTo:trackBallElement]) != NSNotFound) {
	switch (index) {
	    case 0: return NSLocalizedString(@"X rotation", @"Accessibility description for X rotation text field");
	    case 1: return NSLocalizedString(@"Y rotation", @"Accessibility description for Y rotation text field");
	    case 2: return NSLocalizedString(@"Z rotation", @"Accessibility description for Z rotation text field");
	}
    }
    return nil;
}

- (id)accessibilityHitTest:(NSPoint)point {
    id result = [super accessibilityHitTest:point];
    /* If our hit lands on our cell, treat it as hitting self, because we want to block our cell from participating in accessibility */
    if (result == [self cell]) result = self;
    
    /* If the hit lands on us, determine if we landed in a label portion and, if so, return the appropriate UI element */
    if (result == self) {
	NSPoint windowPoint = [[self window] convertScreenToBase:point];
	NSPoint localPoint = [self convertPoint:windowPoint fromView:nil];
	NSUInteger labelIndex;
	for (labelIndex = 0; labelIndex < 3; labelIndex++) {
	    NSRect labelRect = [self labelRectForLabelIndex:labelIndex];
	    if (NSPointInRect(localPoint, labelRect)) {
		/* We landed in this label rect.  Determine if we landed in the coordinate portion, or the numeric portion. */
		NSRect coordPortion, numberPortion;
		NSDivideRect(labelRect, &coordPortion, &numberPortion, NSWidth(labelRect) * COORD_PORTION_OF_LABEL_RECT, NSMinXEdge);
		/* If we landed in the coordinate portion, return the label UI element; otherwise return the UI element representing that rotation */
		if (NSPointInRect(localPoint, coordPortion)) return [labelUIElements objectAtIndex:labelIndex];
		else return [angleTextFieldUIElements objectAtIndex:labelIndex];
	    }
	}
    }
    return result;
}

// We can focus only on the numeric (not coordinate) parts of our labels
//
- (BOOL)isFauxUIElementFocusable:(FauxUIElement *)fauxElement {
    return [angleTextFieldUIElements indexOfObjectIdenticalTo:fauxElement] != NSNotFound;
}

- (void)fauxUIElement:(FauxUIElement *)fauxElement setFocus:(id)value {
    NSUInteger index = [angleTextFieldUIElements indexOfObjectIdenticalTo:fauxElement];
    if (index != NSNotFound) {
	focusedPortion = index + 1;
	[self setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
    }
}

// Set the value of a given coordinate from one of our axisUIElements, or from one of our angleTextFieldUIElements.
// The code turns out to be very similar either way.
//
- (void)axisUIElement:(TrackBallUIElement *)trackBallElement setValue:(id)value {
    NSUInteger index = [axisUIElements indexOfObjectIdenticalTo:trackBallElement];
    if (index == NSNotFound) index = [angleTextFieldUIElements indexOfObjectIdenticalTo:trackBallElement];
    [self setAngle:[value doubleValue] forIndex:index];
    [NSApp sendAction:[self action] to:[self target] from:self];
}

// Determine the rect for our UI elements.  The axis elements are not considered to have any rect.
// The angle and label UI elements are at the same location as we draw them, which we determine via labelRectForLabelIndex:.
//
- (NSRect)rectForFauxUIElement:(FauxUIElement *)fauxElement {
    NSUInteger index;
    if ((index = [labelUIElements indexOfObjectIdenticalTo:fauxElement]) != NSNotFound) {
	NSRect labelRect = [self labelRectForLabelIndex:index];
	NSRect coordPortion, numberPortion;
	NSDivideRect(labelRect, &coordPortion, &numberPortion, NSWidth(labelRect) * COORD_PORTION_OF_LABEL_RECT, NSMinXEdge);
	return coordPortion;
    }
    else if ((index = [angleTextFieldUIElements indexOfObjectIdenticalTo:fauxElement]) != NSNotFound) {
	NSRect labelRect = [self labelRectForLabelIndex:index];
	NSRect coordPortion, numberPortion;
	NSDivideRect(labelRect, &coordPortion, &numberPortion, NSWidth(labelRect) * COORD_PORTION_OF_LABEL_RECT, NSMinXEdge);
	return numberPortion;
    }
    else return NSZeroRect;
}

- (NSPoint)fauxUIElementPosition:(FauxUIElement *)fauxElement {
    return [self rectForFauxUIElement:fauxElement].origin;
}

- (NSSize)fauxUIElementSize:(FauxUIElement *)fauxElement {
    return [self rectForFauxUIElement:fauxElement].size;
}

@end


#pragma mark Mathematical functions

/* Below are mathematical functions for manipulating rotations and vectors.  See the prototypes at the top for comments about their behavior. */

static CGFloat safe_sqrt(CGFloat x) {
    if (x <= 0) return 0.;
    else return sqrt(x);
}

static CGFloat distance(ThreeVector_t a, ThreeVector_t b) {
    CGFloat x = a.x - b.x;
    CGFloat y = a.y - b.y;
    CGFloat z = a.z - b.z;
    return safe_sqrt(x*x + y*y + z*z);
}

static ThreeVector_t normalize(ThreeVector_t a) {
    CGFloat normalizer = distance(a, (ThreeVector_t){0, 0, 0});
    a.x /= normalizer;
    a.y /= normalizer;
    a.z /= normalizer;
    return a;
}

static Quaternion_t multiplyQuaternions(Quaternion_t q1, Quaternion_t q2) {
    Quaternion_t result;
    result.x =  q1.x * q2.w + q1.y * q2.z - q1.z * q2.y + q1.w * q2.x;
    result.y = -q1.x * q2.z + q1.y * q2.w + q1.z * q2.x + q1.w * q2.y;
    result.z =  q1.x * q2.y - q1.y * q2.x + q1.z * q2.w + q1.w * q2.z;
    result.w = -q1.x * q2.x - q1.y * q2.y - q1.z * q2.z + q1.w * q2.w;
    return result;
}

static ThreeVector_t eulerAnglesInDegreesFromQuaternion(Quaternion_t q1) {
    CGFloat p0, p1, p2, p3;
    p0 = q1.w;
    p1 = q1.z;
    p2 = q1.y;
    p3 = q1.x;
    CGFloat e = 1.;
    
    CGFloat theta1, theta2, theta3;
    
    CGFloat test = 2*(p0*p2 + e*p1*p3);
    if (abs(test) > .999) { /* top or bottom singularity */
	theta3 = 0;
	theta2 = signbit(test) ? -M_PI/2. : M_PI/2.;
	theta1 = atan2(p1, p0);
    }
    else {	
	theta3 = atan2(2*(p0*p1 - e*p2*p3), 1 - 2*(p1*p1 + p2*p2));
	theta2 = asin(2 * (p0*p2 + e*p1*p3));
	theta1 = atan2(2*(p0*p3 - e*p1*p2), 1 - 2*(p2*p2 + p3*p3));
    }
    
    /* We get values in the range (-PI, PI).  Let's convert those to the range (0, 2 PI) so that we don't display negative angles to the user. */
    if (theta1 < 0) theta1 += 2 * M_PI;
    if (theta2 < 0) theta2 += 2 * M_PI;
    if (theta3 < 0) theta3 += 2 * M_PI;
    
    const CGFloat radiansToDegrees = 180. / M_PI;
    return (ThreeVector_t){theta1 * radiansToDegrees, theta2 * radiansToDegrees, theta3 * radiansToDegrees};
}

static Quaternion_t quaternionFromAxisAndAngle(ThreeVector_t axis, CGFloat angle) {
    Quaternion_t result;
    CGFloat s = sin(angle / 2.);
    result.x = axis.x * s;
    result.y = axis.y * s;
    result.z = axis.z * s;
    result.w = cos(angle / 2.);
    return result;
}

 