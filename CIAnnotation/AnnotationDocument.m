
/*
     File: AnnotationDocument.m
 Abstract: The AnnotationDocument is the document object of the app. It contains the layers.
  Version: 1.3
 
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

#import "AnnotationDocument.h"
#import "AnnotationView.h"

@interface AnnotationDocument (private) 
- (void)createOutputImage;
@end

@implementation AnnotationDocument

#pragma mark -
#pragma mark Init and Dealloc


- (id)initWithImageURL:(NSURL*)inURL renderView:(AnnotationView*)inRenderView
{
    CGRect	documentRect;
    CIFilter	*colorFilter = [CIFilter filterWithName:@"CIConstantColorGenerator"];
    CIFilter	*cropFilter = [CIFilter filterWithName:@"CICrop"];
    
    self = [super init];
    if(!self)
	return nil;
    renderView = inRenderView;
    // create the layer that holds the image we want to annotate
    imageLayer = [[CIImageLayer alloc] initWithDelegate:self imageURL:inURL];
    documentRect = [imageLayer getRect];    // the image determines the size of our docment
    // create the text annotation layer
    textLayer = [[CITextLayer alloc] initWithDelegate:self targetRect:documentRect ciContext:[renderView ciContext]];
    // create the paint annotation layer
    paintLayer = [[CIPaintLayer alloc] initWithDelegate:self targetRect:documentRect];
    // create the peel off filter - page curl transition
    peelOffFilter = [[CIFilter filterWithName:@"CIPageCurlTransition"] retain];
    [peelOffFilter setDefaults];
    annotationPeel = 0.0;	    // by default show both images
    [peelOffFilter setValue:[NSNumber numberWithDouble:annotationPeel] forKey:@"inputTime"];
    // set the shine image as it is static
    [peelOffFilter setValue:[CIImage imageWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"restrictedshine" ofType: @"tiff"]]] forKey:@"inputShadingImage"];    
    [peelOffFilter setValue:[NSNumber numberWithDouble:0.3] forKey:@"inputAngle"];    // this is the angle at which we want to peel off the annotations
    // create a filter to composite the text and paint annotations together
    annotationCompositeFilter = [[CIFilter filterWithName:@"CISourceOverCompositing"] retain];
    [annotationCompositeFilter setDefaults];
    // create a filter that composites the annotation composite with a backing/parchment image for the backside of the peel off
    annotationCompositeBackingFilter = [[CIFilter filterWithName:@"CISourceOverCompositing"] retain];
    [annotationCompositeBackingFilter setDefaults];
    [colorFilter setValue:[CIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:0.8] forKey:@"inputColor"];
    [cropFilter setValue:[colorFilter valueForKey:@"outputImage"] forKey:@"inputImage"];
    [cropFilter setValue:[CIVector vectorWithX:documentRect.origin.x Y:documentRect.origin.y Z:documentRect.size.width W:documentRect.size.height] forKey:@"inputRectangle"];    
    parchmentBackingImage = [[cropFilter valueForKey:@"outputImage"] retain];
    // setup the view size
    [renderView setFrame:*(NSRect*)&documentRect];
    [renderView setBounds:*(NSRect*)&documentRect];
    [[renderView window] setMaxSize:*(NSSize*)&(documentRect.size)];
    // setup if lens should be shown
    [imageLayer showLens:(annotationPeel <= 0.0)];
    return self;
}

- (void)dealloc
{
    [renderView setImage:nil];
    [textLayer release];
    [paintLayer release];
    [imageLayer release];
    [peelOffFilter release];
    [annotationCompositeFilter release];
    [super dealloc];
}

#pragma mark -
#pragma mark Rendering methods

- (void)createOutputImage
{    
    CIImage	*textImage = [textLayer getLayerImage];
    CIImage	*paintImage = [paintLayer getLayerImage];
    
    // composite the text and paint annotations
    [annotationCompositeFilter setValue:textImage forKey:@"inputImage"];
    [annotationCompositeFilter setValue:paintImage forKey:@"inputBackgroundImage"];
    // special case the 'no peel' and 'full peel' states by leaving out the transition filter in those cases for better performance
    if(annotationPeel <= 0.0)
    {
	[annotationCompositeBackingFilter setValue:[annotationCompositeFilter valueForKey:@"outputImage"] forKey:@"inputImage"];
	[annotationCompositeBackingFilter setValue:[imageLayer getLayerImage] forKey:@"inputBackgroundImage"];
	outputImage = [annotationCompositeBackingFilter valueForKey:@"outputImage"];
    } else {
	[annotationCompositeBackingFilter setValue:parchmentBackingImage forKey:@"inputImage"];
	[annotationCompositeBackingFilter setValue:[annotationCompositeFilter valueForKey:@"outputImage"] forKey:@"inputBackgroundImage"];
	[peelOffFilter setValue:[imageLayer getLayerImage] forKey:@"inputTargetImage"];
	[peelOffFilter setValue:[annotationCompositeFilter valueForKey:@"outputImage"] forKey:@"inputImage"];
	[peelOffFilter setValue:[annotationCompositeBackingFilter valueForKey:@"outputImage"] forKey:@"inputBacksideImage"];    
	outputImage = [peelOffFilter valueForKey:@"outputImage"];
    }
}


- (void)exportImageToURL:(NSURL*)inURL
{
    CGColorSpaceRef	colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    NSDictionary *options = @{ kCIContextOutputColorSpace:(id)colorSpace };
    CIContext *exportContext = [CIContext contextWithCGContext:[[[renderView window] graphicsContext] graphicsPort] options:options];
    CGColorSpaceRelease(colorSpace); // Owned by the context.
    // create an image destination (ImageIO's way of saying we want to save to a file format)
    // note: public.jpeg denotes that we are saving to JPEG
    CGImageDestinationRef imageDestination = CGImageDestinationCreateWithURL((CFURLRef)inURL, (CFStringRef)@"public.jpeg", 1, nil);
    
    if (imageDestination == NULL) {
        NSLog(@"Problem creating image destination.");
        return;
    }
    
    CGImageRef renderedImage = [exportContext createCGImage:outputImage fromRect:[outputImage extent]];
    // add image to the ImageIO destination (specify the image we want to save)
    CGImageDestinationAddImage(imageDestination, renderedImage, NULL);
    // finalize: this saves the image to the JPEG format as data
    if (!CGImageDestinationFinalize(imageDestination))
    {
        NSLog(@"Problem writing JPEG file.");
    }
    CFRelease(imageDestination);
    CGImageRelease(renderedImage);
}

#pragma mark -
#pragma mark User interaction methods

- (void)setMode:(AnnotationEditingMode)inMode
{
    editMode = inMode;
}

- (void)setBrightness:(CGFloat)inValue
{
    [imageLayer setImageSetting:kBrightnessSetting value:inValue];
}

- (void)setContrast:(CGFloat)inValue
{
    [imageLayer setImageSetting:kContrastSetting value:inValue];
}

- (void)setSaturation:(CGFloat)inValue
{
    [imageLayer setImageSetting:kSaturationSetting value:inValue];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    if([theEvent modifierFlags] & NSAlternateKeyMask)	// peel off the annotation layers
    {
	BOOL			    dragActive = YES;
	NSPoint			    location;
	NSAutoreleasePool	    *myPool = nil;
	NSEvent*		    event = NULL;
	NSWindow		    *targetWindow = [renderView window];

	
	myPool = [[NSAutoreleasePool alloc] init];
	while (dragActive)
	{	    
		event = [targetWindow nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)
							    untilDate:[NSDate distantFuture]
							    inMode:NSEventTrackingRunLoopMode
							    dequeue:YES];
	
		if(!event)
			continue;
		location = [renderView convertPoint:[event locationInWindow] fromView:nil];
		switch ([event type])
		{
			case NSLeftMouseDragged:
			    annotationPeel = (location.x * 2.0 / [renderView bounds].size.width);
			    [imageLayer showLens:(annotationPeel <= 0.0)];
			    [peelOffFilter setValue:[NSNumber numberWithDouble:annotationPeel] forKey:@"inputTime"];		    
			    [self refresh];
			    break;
			    
			case NSLeftMouseUp:
			    dragActive = NO;
			    break;
			    
		    default:
			    break;
	    }
	}
	[myPool release];
    } else {
	// handle mouse down events in the respective layer depending on the current edit mode
	switch(editMode)
	{
	    case kMagnifyingMode:
		[imageLayer mouseDown:theEvent view:renderView];
		break;

	    case kPaintMode:
		[paintLayer mouseDown:theEvent view:renderView];
		break;

	    case kTextMode:
		[textLayer mouseDown:theEvent view:renderView];
		break;
	}
    }
}

#pragma mark -
#pragma mark Delegate methods

/* 
  
      Delegate methods
    
*/

- (void)refresh:(CGRect)dirtyRect
{
    [self createOutputImage];
    [renderView setImage:outputImage dirtyRect:dirtyRect];
}

- (void)refresh
{
    [self createOutputImage];
    [renderView setImage:outputImage dirtyRect:[outputImage extent]];
}

- (void)doTextEditSession:(TextObject*)textObject
{        
    //Create editor window if necessary
    if(!editorWindow) 
    {
        editorWindow = [[OverlayWindow alloc] initWithContentRect:[[renderView window] frame] styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
        [editorWindow setParentWindow:[renderView window]];
        [editorWindow setOpaque:NO];
        [editorWindow setReleasedWhenClosed:NO];
        textView = [[NSTextView alloc] initWithFrame:[[renderView window] frame]];
        [textView setRichText:YES];
        [textView setFieldEditor:YES];
        [[textView textContainer] setWidthTracksTextView:NO];
        [[textView textContainer] setHeightTracksTextView:NO];
        [textView setVerticallyResizable:YES];
        [textView setHorizontallyResizable:YES];
        [textView setDrawsBackground:YES];
        [textView setAllowsDocumentBackgroundColorChange:NO];
        [textView setBackgroundColor:[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:0.4]];
        [textView setSelectable:YES];
        [textView setImportsGraphics:NO];
        [textView setDelegate:(id)self];
        [[editorWindow contentView] addSubview:textView];
    }
    [editorWindow setFrame:[[renderView window] frame] display:NO];

    //Preset string
    if([textObject getText])
        [[textView textStorage] setAttributedString:[textObject getText]];
    else
        [textView setString:@" "];
    
    [textView selectAll:nil];
    //Run editor modally
    NSPoint	fieldOrigin = [textObject getTextRect].origin;
    fieldOrigin.x -= [renderView visibleRect].origin.x;
    fieldOrigin.y -= [renderView visibleRect].origin.y - 16.0;	//offset for the titlebar
    [textView setFrameOrigin:fieldOrigin];
    [textView setFrameSize:[textObject getTextRect].size];
    [textView setConstrainedFrameSize:[textObject getTextRect].size];
    [textView sizeToFit];
    [editorWindow setBackgroundColor:[NSColor clearColor]];
    [[editorWindow contentView] display];
    [[renderView window] addChildWindow:editorWindow ordered:NSWindowAbove];
    [editorWindow makeKeyAndOrderFront:nil];
    [editorWindow makeFirstResponder:textView];
    
    if([NSApp runModalForWindow:editorWindow] != NSRunAbortedResponse)
    {
        [textObject setText:[textView textStorage]];
    }
}

-(void)textDidEndEditing:(id)sender
{
    [[renderView window] removeChildWindow:editorWindow];
    [editorWindow close];
    [NSApp stopModal];
}

-(void)textDidChange:(id)sender
{
    [editorWindow display];	// otherwise the resizing text view will leave artifacts behind
}

@end
