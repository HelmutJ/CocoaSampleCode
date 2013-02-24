/*

File: ImageMap.m

Abstract: image map widget

Version: <1.0>

Disclaimer: IMPORTANT:  This Apple software is supplied to you by 
Apple Inc. ("Apple") in consideration of your agreement to the
following terms, and your use, installation, modification or
redistribution of this Apple software constitutes acceptance of these
terms.  If you do not agree with these terms, please do not use,
install, modify or redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and
subject to these terms, Apple grants you a personal, non-exclusive
license, under Apple's copyrights in this original Apple software (the
"Apple Software"), to use, reproduce, modify and redistribute the Apple
Software, with or without modifications, in source and/or binary forms;
provided that if you redistribute the Apple Software in its entirety and
without modifications, you must retain this notice and the following
text and disclaimers in all such redistributions of the Apple Software. 
Neither the name, trademarks, service marks or logos of Apple Inc. 
may be used to endorse or promote products derived from the Apple
Software without specific prior written permission from Apple.  Except
as expressly stated in this notice, no other rights or licenses, express
or implied, are granted by Apple herein, including but not limited to
any patent rights that may be infringed by your derivative works or by
other works in which the Apple Software may be incorporated.

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

Copyright (C) 2005-2009 Apple Inc. All Rights Reserved.

*/ 


#import "ImageMapPrivate.h"

@implementation ImageMap

- (id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
	hotSpotInfo = [[NSMutableArray alloc] init];
	hotSpotPaths = [[NSMutableArray alloc] init];
	hotSpotsVisibleColor =  [[[NSColor grayColor] colorWithAlphaComponent:0.5] retain];
	selectedHotSpotColor = [[[NSColor grayColor] colorWithAlphaComponent:1] retain];
	rolloverHotSpotColor = [[[NSColor grayColor] colorWithAlphaComponent:0.75] retain];
	selectedHotSpotIndex = NSNotFound;
	rolloverHotSpotIndex = NSNotFound;
	hotSpotCompositeOperation = NSCompositePlusDarker;
    }
    return self;
}

- (void)dealloc {
    // mse-evil should do this when removed from superview (also fix when added)
    [self setRolloverHighlighting:NO];
    
    [image autorelease];
    [hotSpotsVisibleColor autorelease];
    [selectedHotSpotColor autorelease];
    [rolloverHotSpotColor autorelease];
    [hotSpotInfo autorelease];
    [hotSpotPaths autorelease];
    [defaultInfo autorelease];
    [super dealloc];
}

- (BOOL)isFlipped {
    return isHTMLImageMap;
}

- (BOOL)isHTMLImageMap {
    return isHTMLImageMap;
}

- (void)setImage:(NSImage *)newImage {
    [image autorelease];
    image = [newImage retain];
    [image setFlipped:isHTMLImageMap];
    [self setFrameSize:[newImage size]];
}

- (id)target {
    return target;
}

- (void)setTarget:(id)object {
    target = object;
}

- (SEL)action {
    return action;
}

- (void)setAction:(SEL)selector {
    action = selector;
}

- (BOOL)hasDefault {
    return hasDefault;
}

- (void)setHasDefault:(BOOL)flag {
    flag = flag != NO;
    if (hasDefault != flag) {
	hasDefault = flag;
    }
}

- (id)defaultInfo {
    return defaultInfo;
}

- (void)setDefaultInfo:(id)info {
    if (defaultInfo != info) {
	[defaultInfo autorelease];
	defaultInfo = [info retain];
    }
}

- (int)numHotSpots {
    return [hotSpotInfo count];

}

- (void)removeAllHotSpots {
    if ([self numHotSpots] > 0) {
	[hotSpotInfo removeAllObjects];
	[hotSpotPaths removeAllObjects];
	selectedHotSpotIndex = NSNotFound;
	rolloverHotSpotIndex = NSNotFound;
	[self setNeedsDisplay:YES];
    }
}

- (void)addHotSpotForPath:(NSBezierPath *)path info:(id)info {
    [hotSpotInfo addObject:info];
    [hotSpotPaths addObject:path];
    selectedHotSpotIndex = NSNotFound;
    rolloverHotSpotIndex = NSNotFound;
    [self setNeedsDisplay:YES];
}

- (void)addHotSpotForRect:(NSRect)rect info:(id)info {
    NSBezierPath *path = [NSBezierPath bezierPathWithRect:rect];
    [self addHotSpotForPath:path info:info];
}

- (void)addHotSpotForCircle:(NSPoint)center radius:(float)radius info:(id)info {
    NSRect rect = NSMakeRect(center.x - radius, center.y - radius, 2*radius, 2*radius);
    
    NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect:rect];
    [self addHotSpotForPath:path info:info];
}

- (void)addHotSpotForPolygon:(NSPoint *)points count:(int)count info:(id)info {
    if (count > 0) {
	NSBezierPath *path = [[NSBezierPath alloc] init];
	[path moveToPoint:points[0]];
	int i;
	for (i = 1; i < count; ++i) {
	    [path lineToPoint:points[i]];
	}
	[path closePath];
	[self addHotSpotForPath:path info:info];
	[path release];
    }
}

- (BOOL)hotSpotsVisible {
    return hotSpotsVisible;
}

- (void)setHotSpotsVisible:(BOOL)flag {
    flag = flag != NO;
    if (hotSpotsVisible != flag) {
	hotSpotsVisible = flag;
	[self setNeedsDisplay:YES];
    }
}

- (id)infoForHotSpotAtIndex:(int)index {
    return [hotSpotInfo objectAtIndex:index];
}

- (NSRect)boundsForHotSpotAtIndex:(int)index {
    NSBezierPath *path = [hotSpotPaths objectAtIndex:index];
    return [path bounds];
}

- (id)selectedHotSpotInfo {
    NSString *result = nil;
    if (selectedHotSpotIndex == NSNotFound) {
	if ([self hasDefault]) {
	    result = [self defaultInfo];
	}
    } else if (selectedHotSpotIndex < [self numHotSpots]) {
	result = [self infoForHotSpotAtIndex:selectedHotSpotIndex];
    }
    return result;
}

- (int)hotSpotIndexForPoint:(NSPoint)point {
    int result = NSNotFound;
    int numHotSpots = [self numHotSpots];
    int i;
    for (i = 0; i < numHotSpots; ++i) {
	NSBezierPath *path = [hotSpotPaths objectAtIndex:i];
	if ([path containsPoint:point]) {
	    result = i;
	    break;
	}
    }
    return result;
}

- (BOOL)hotSpotAtIndex:(int)index containsPoint:(NSPoint)point {
    BOOL result = NO;
    if (index != NSNotFound && index < [self numHotSpots]) {
	NSBezierPath *path = [hotSpotPaths objectAtIndex:index];
	result = [path containsPoint:point];
    }
    return result;
}

- (NSColor *)hotSpotsVisibleColor {
    return hotSpotsVisibleColor;
}

- (void)setHotSpotsVisibleColor:(NSColor *)color {
    if (![hotSpotsVisibleColor isEqual:color]) {
	[hotSpotsVisibleColor autorelease];
	hotSpotsVisibleColor = [color retain];
	[self setNeedsDisplay:YES];
    }
}

- (NSColor *)selectedHotSpotColor {
    return selectedHotSpotColor;
}

- (void)setSelectiedHotSpotColor:(NSColor *)color {
    if (![selectedHotSpotColor isEqual:color]) {
	[selectedHotSpotColor autorelease];
	selectedHotSpotColor = [color retain];
	[self setNeedsDisplay:YES];
    }
}

- (NSColor *)rolloverHotSpotColor {
    return rolloverHotSpotColor;
}

- (void)setRolloverHotSpotColor:(NSColor *)color {
    if (![rolloverHotSpotColor isEqual:color]) {
	[rolloverHotSpotColor autorelease];
	rolloverHotSpotColor = [color retain];
	[self setNeedsDisplay:YES];
    }
}

- (NSCompositingOperation)hotSpotCompositeOperation {
    return hotSpotCompositeOperation;
}

- (void)setHotSpotCompositeOperation:(NSCompositingOperation)op {
    if (hotSpotCompositeOperation != op) {
	hotSpotCompositeOperation = op;
	[self setNeedsDisplay:YES];
    }
}

- (void)drawRect:(NSRect)rect {
    
    [image drawInRect:rect fromRect:rect operation:NSCompositeSourceOver fraction:1.0];

    NSGraphicsContext *curContext = [NSGraphicsContext currentContext];
    NSCompositingOperation savedCompositingOperation = [curContext compositingOperation];
    [curContext setCompositingOperation:hotSpotCompositeOperation];

    int numHotSpots = [self numHotSpots];
    int i;
    for (i = 0; i < numHotSpots; ++i) {
	NSColor *fillColor = nil;
	if (isCurrentlySelected && selectedHotSpotIndex == i) {
	    fillColor = [self selectedHotSpotColor];
	} else if (rolloverHotSpotIndex == i && [[self window] isKeyWindow]) {
	    fillColor = [self rolloverHotSpotColor];
	} else if (hotSpotsVisible) {
	    fillColor = [self hotSpotsVisibleColor];
	}
	
	if (fillColor != nil) {
	    NSBezierPath *path = [hotSpotPaths objectAtIndex:i];
	    [fillColor set];
	    [path fill];
	}
    }
    
    [curContext setCompositingOperation:savedCompositingOperation];
}

- (void)performActionForHotSpotAtIndex:(int)index {
    if (target != nil && action != NULL) {
	if (index != NSNotFound || [self hasDefault]) {
	    selectedHotSpotIndex = index;
	    [target performSelector:action withObject:self];
	    selectedHotSpotIndex = NSNotFound;
	}
    }
}

- (void)mouseDown:(NSEvent *)event {
    NSPoint point = [self convertPoint:[event locationInWindow] fromView:nil];
    int index = [self hotSpotIndexForPoint:point];
    if (index != NSNotFound || [self hasDefault]) {
	selectedHotSpotIndex = index;
	isCurrentlySelected = YES;
	if (selectedHotSpotIndex != NSNotFound) {
	    [self setNeedsDisplay:YES];
	}
    }
}

- (void)mouseDragged:(NSEvent *)event {
    if (selectedHotSpotIndex != NSNotFound) {
	NSPoint point = [self convertPoint:[event locationInWindow] fromView:nil];
	BOOL newState = [self hotSpotAtIndex:selectedHotSpotIndex containsPoint:point];
	    
	if (isCurrentlySelected != newState) {
	    isCurrentlySelected = newState;
	    [self setNeedsDisplay:YES];
	}
    }
}

- (void)mouseUp:(NSEvent *)event {
    if (isCurrentlySelected) {
	[self performActionForHotSpotAtIndex:selectedHotSpotIndex];
	selectedHotSpotIndex = NSNotFound;
	isCurrentlySelected = NO;
	[self setNeedsDisplay:YES];
    }
}


//
// rollover highlighting support
//

// Rollover highlighting is implemented in two stages. First, tracking rects are used to determine when the mouse is anywhere over the image map. Second, while the mouse is over the map we observe NSWindowDidUpdateNotifications on our window. Update notifications are sent on every pass through the event loop. To ensure this happens whenever the mouse moves, we configure the window to accepts mouse move events. Note: responding to mouse moved events (by implementing the mouseMoved method instead of observing update notifications) will not work for our purposes because mouse moved events are only sent to the first responder.

- (void)setupRolloverTrackingRect {
    NSPoint screenPoint = [NSEvent mouseLocation];
    NSPoint windowPoint = [[self window] convertScreenToBase:screenPoint];
    NSPoint point = [self convertPoint:windowPoint fromView:nil];
    BOOL mouseInside = NSMouseInRect(point, [self bounds], [self isFlipped]);

    rolloverTrackingRectTag = [self addTrackingRect:[self bounds] owner:self userData:NULL assumeInside:mouseInside];
}

- (void)updateRolloverTrackingRect:(NSNotification *)notification {
    if (rolloverHighlighting) {
	[self removeTrackingRect:rolloverTrackingRectTag];
	[self setupRolloverTrackingRect];
    }
}

- (BOOL)rolloverHighlighting {
    return rolloverHighlighting;
}

- (void)setRolloverHighlighting:(BOOL)flag {
    flag = flag != NO;
    if (rolloverHighlighting != flag) {
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	rolloverHighlighting = flag;
	if (flag) {
	    [self setupRolloverTrackingRect];
	    [nc addObserver:self selector:@selector(updateRolloverTrackingRect:) name:NSViewFrameDidChangeNotification object:self];
	    [self startRolloverTracking];
	} else {
	    [self stopRolloverTracking];
	    [nc removeObserver:self name:NSViewFrameDidChangeNotification object:self];
	    [self removeTrackingRect:rolloverTrackingRectTag];
	}
    }
}

- (void)rolloverTrackingHandleWindowUpdate:(NSNotification *)notification {
    NSPoint screenPoint = [NSEvent mouseLocation];
    NSPoint windowPoint = [[self window] convertScreenToBase:screenPoint];
    NSPoint point = [self convertPoint:windowPoint fromView:nil];
    
    if (NSMouseInRect(point, [self bounds], [self isFlipped])) {
	int index = [self hotSpotIndexForPoint:point];
	if (rolloverHotSpotIndex != index) {
	    rolloverHotSpotIndex = index;
	    [self setNeedsDisplay:YES];
	}
    } else {
	[self stopRolloverTracking];
    }
}

- (void)rolloverTrackingHandleKeyWindowChange:(NSNotification *)notification {
    [self setNeedsDisplay:YES];
}

- (void)startRolloverTracking {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(rolloverTrackingHandleWindowUpdate:) name:NSWindowDidUpdateNotification object:[self window]];
    [nc addObserver:self selector:@selector(rolloverTrackingHandleKeyWindowChange:) name:NSWindowDidBecomeKeyNotification object:[self window]];
    [nc addObserver:self selector:@selector(rolloverTrackingHandleKeyWindowChange:) name:NSWindowDidResignKeyNotification object:[self window]];
    
    windowAcceptsMouseMovedEvents = [[self window] acceptsMouseMovedEvents];
    if (!windowAcceptsMouseMovedEvents) {
	[[self window] setAcceptsMouseMovedEvents:YES];
    }
    
    [self rolloverTrackingHandleWindowUpdate:nil];
}

- (void)stopRolloverTracking {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:NSWindowDidUpdateNotification object:[self window]];
    [nc removeObserver:self name:NSWindowDidBecomeKeyNotification object:[self window]];
    [nc removeObserver:self name:NSWindowDidResignKeyNotification object:[self window]];
    if (!windowAcceptsMouseMovedEvents) {
	[[self window] setAcceptsMouseMovedEvents:NO];
    }
    
    if (rolloverHotSpotIndex != NSNotFound) {
	rolloverHotSpotIndex = NSNotFound;
	[self setNeedsDisplay:YES];
    }
}

- (void)mouseEntered:(NSEvent *)event {
    [self startRolloverTracking];
}

- (void)mouseExited:(NSEvent *)event {
    [self stopRolloverTracking];
}


//
// HTML client-side image map format support
//

/*

<!-- Image maps in HTML look something like this -->

<map name="foo">
<area shape="rect" coords="24,26,80,96" href="http://foo.com/body" alt="body">
<area shape="circle" coords="149,82,22" href="http://foo.com/head" alt="head">
<area shape="poly" coords="13,148,33,187,109,185,118,150" href="http://foo.com/arm" alt="arm">
<area shape="default" href="http://foo.com/somewhere">
</map>

*/

static NSDictionary *dictionaryWithLowercaseKeys(NSDictionary *dict) {
    NSDictionary *result = nil;
    NSArray *keys = [dict allKeys];
    NSArray *objects = [dict allValues];
    NSMutableArray *lowercaseKeys = [[NSMutableArray alloc] initWithCapacity:[keys count]];
    NSEnumerator *e = [keys objectEnumerator];
    NSString *key;
    while ((key = [e nextObject])) {
	[lowercaseKeys addObject:[key lowercaseString]];
    }
    result = [NSDictionary dictionaryWithObjects:objects forKeys:lowercaseKeys];
    [lowercaseKeys release];
    return result;
}

static NSDictionary *HTMLHotSpotInfo(NSDictionary *attrs) {
    static NSString *infoAttrs[] = {@"alt" , @"href", @"title"};
    static numInfoAttrs = sizeof(infoAttrs)/sizeof(*infoAttrs);
    
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    int i;
    for(i = 0; i < numInfoAttrs; ++i) {
	NSString *attrName = infoAttrs[i];
	id attrValue = [attrs valueForKey:attrName];
	if (attrValue != nil) {
	    [result setObject:attrValue forKey:attrName];
	}
    }
    return result;
}

static NSArray *parseIntList(NSString *intList) {
    static NSMutableCharacterSet *delimeters = nil;
    if (delimeters == nil) {
	delimeters = [[NSCharacterSet whitespaceAndNewlineCharacterSet] mutableCopy];
	[delimeters addCharactersInString:@","];
    }
    NSScanner *scanner = [[NSScanner alloc] initWithString:intList];
    [scanner setCharactersToBeSkipped:delimeters];
    
    NSMutableArray *result = [NSMutableArray array];
    int intValue;
    while ([scanner scanInt:&intValue]) {
	[result addObject:[NSNumber numberWithInt:intValue]];
    }
    [scanner release];
    return result;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict {
    if ([elementName caseInsensitiveCompare:@"map"] == 0) {
	NSDictionary *attrs = dictionaryWithLowercaseKeys(attributeDict);
	if ([[attrs valueForKey:@"name"] isEqualToString:HTMLImageMapName]) {
	    parsingHTMLMapElement = YES;
	}
    } else if (parsingHTMLMapElement && ([elementName caseInsensitiveCompare:@"area"] == 0)) {
	NSDictionary *attrs = dictionaryWithLowercaseKeys(attributeDict);
	NSString *shape  = [attrs valueForKey:@"shape"];
	NSString *coords = [attrs valueForKey:@"coords"];
	if ([shape caseInsensitiveCompare:@"rect"] == 0) {
	    NSArray *rectCoords = parseIntList(coords);
	    if ([rectCoords count] == 4) {
		float x1 = [[rectCoords objectAtIndex:0] floatValue];
		float y1 = [[rectCoords objectAtIndex:1] floatValue];
		float x2 = [[rectCoords objectAtIndex:2] floatValue];
		float y2 = [[rectCoords objectAtIndex:3] floatValue];
		
		// allow any two opposing corners to specify the rect
		float x = MIN(x1, x2);
		float y = MIN(y1, y2);
		float width = abs(x2 - x1);
		float height = abs(y2 - y1);
		
		NSRect rect = NSMakeRect(x, y, width, height);
		[self addHotSpotForRect:rect info:HTMLHotSpotInfo(attrs)];
	    } else {
		NSLog(@"illegal format for rect coords: %@", coords);
	    }
	} else if ([shape caseInsensitiveCompare:@"circle"] == 0) {
	    NSArray *circleCoords = parseIntList(coords);
	    if ([circleCoords count] == 3) {
		float x = [[circleCoords objectAtIndex:0] floatValue];
		float y = [[circleCoords objectAtIndex:1] floatValue];
		NSPoint center = NSMakePoint(x, y);
		float radius = [[circleCoords objectAtIndex:2] floatValue];
		[self addHotSpotForCircle:center radius:radius info:HTMLHotSpotInfo(attrs)];
	    } else {
		NSLog(@"illegal format for circle coords: %@", coords);
	    }
	} else if ([shape caseInsensitiveCompare:@"poly"] == 0) {
	    NSArray *polyCoords = parseIntList(coords);
	    unsigned numCoords = [polyCoords count];
	    // Require an even number of coords specifying at least three points.
	    if (((numCoords % 2) == 0) && (numCoords >= 6)) {
		unsigned numPoints = numCoords / 2;
		NSPoint points[numPoints];
		int i;
		for (i = 0; i < numPoints; ++i) {
		    float x = [[polyCoords objectAtIndex:2*i    ] floatValue];
		    float y = [[polyCoords objectAtIndex:2*i + 1] floatValue];
		    points[i] = NSMakePoint(x, y);
		}
		[self addHotSpotForPolygon:points count:numPoints info:HTMLHotSpotInfo(attrs)];
	    } else {
		NSLog(@"illegal format for poly coords: %@", coords);
	    }
	} else if ([shape caseInsensitiveCompare:@"default"] == 0) {
	    [self setDefaultInfo:HTMLHotSpotInfo(attrs)];
	    [self setHasDefault:YES];
	} else {
	    NSLog(@"skipping unknown type of shape: %@", shape);
	}
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    if (parsingHTMLMapElement) {
	parsingHTMLMapElement = NO;
	[parser abortParsing];
    }
}

- (void)setHotSpotsFromImageMapNamed:(NSString *)name inHTMLFile:(NSString *)path {
    NSURL *url = [NSURL fileURLWithPath:path];
    if (url != nil) {
	NSXMLParser *parser = [[NSXMLParser alloc] initWithContentsOfURL:url];
	[self removeAllHotSpots];
	[parser setDelegate:self];
	HTMLImageMapName = name;
	[parser parse];
	HTMLImageMapName = nil;
	[parser release];
	isHTMLImageMap = YES;
	[image setFlipped:isHTMLImageMap];
    }
}

- (void)setImageAndHotSpotsFromImageAndImageMapNamed:(NSString *)name {
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *mapPath = [bundle pathForResource:name ofType:@"html"];
    
    [self setImage:[NSImage imageNamed:name]];
    [self setHotSpotsFromImageMapNamed:name inHTMLFile:mapPath];
}

@end
