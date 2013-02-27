/*
 
 File: AppDrawing.c
 
 Abstract: Sample Quartz drawing code.
 
 Version: <1.0>
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Computer, Inc. ("Apple") in consideration of your agreement to the
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
 Neither the name, trademarks, service marks or logos of Apple Computer,
 Inc. may be used to endorse or promote products derived from the Apple
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
 
 Copyright © 2006 Apple Computer, Inc., All Rights Reserved
 
*/  

#include "AppDrawing.h"
#include "UIHandling.h"
#include "math.h"

/* Defines */
#define kOurImageFile		CFSTR("ptlobos.tif")

// For best performance make bytesPerRow a multiple of 16 bytes.
#define BEST_BYTE_ALIGNMENT 16
#define COMPUTE_BEST_BYTES_PER_ROW(bpr)		( ( (bpr) + (BEST_BYTE_ALIGNMENT-1) ) & ~(BEST_BYTE_ALIGNMENT-1) )

/* Prototypes */
static void drawStrokedAndFilledRects(CGContextRef context);
static void drawAlphaRects(CGContextRef context);
static void drawCGImage(CGContextRef context, CFURLRef url);
static void clipImageToEllipse(CGContextRef context, CFURLRef url);
static void drawSimpleCGLayer(CGContextRef context);
static void drawUncachedForLayer(CGContextRef context);


static inline float DEGREES_TO_RADIANS(float degrees){
    return degrees * M_PI/180;
}

static CGColorSpaceRef myGetGenericRGBSpace(void)
{
    // Only create the color space once.
    static CGColorSpaceRef colorSpace = NULL;
    if ( colorSpace == NULL ) {
	colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    }
    return colorSpace;
}

static CGColorRef myGetBlueColor(void)
{
    // Only create the CGColor object once.
    static CGColorRef blue = NULL;
    if(blue == NULL){
	// R,G,B,A
	float opaqueBlue[4] = { 0, 0, 1, 1 };
	blue = CGColorCreate(myGetGenericRGBSpace(), opaqueBlue);
    }
    return blue;
}

static CGColorRef myGetGreenColor(void)
{
    // Only create the CGColor object once.
    static CGColorRef green = NULL;
    if(green == NULL){
	// R,G,B,A
	float opaqueGreen[4] = { 0, 1, 0, 1 };
	green = CGColorCreate(myGetGenericRGBSpace(), opaqueGreen);
    }
    return green;
}

static CGColorRef myGetRedColor(void)
{
    // Only create the CGColor object once.
    static CGColorRef red = NULL;
    if(red == NULL){
	// R,G,B,A
	float opaqueRed[4] = { 1, 0, 0, 1 };
	red = CGColorCreate(myGetGenericRGBSpace(), opaqueRed);
    }
    return red;
}

static void doDrawImageFile(CGContextRef context, Boolean doclip)
{
    // Only get the image URL the first time the function is called.
    static CFURLRef ourImageURL = NULL;
    if(ourImageURL == NULL){
	CFBundleRef mainBundle = CFBundleGetMainBundle();
	if(mainBundle){
		ourImageURL = CFBundleCopyResourceURL(mainBundle, kOurImageFile, NULL, NULL);
	}else{
	    fprintf(stderr, "Can't get the app bundle!\n");
	}
    }

    if(ourImageURL){
	doclip ? clipImageToEllipse(context, ourImageURL) : drawCGImage(context, ourImageURL);
    }else{
	fprintf(stderr, "Couldn't create the URL for our Image file!\n");
    }

}

/* Dispatch Drawing */

void myDispatchDrawing(CGContextRef context, OSType drawingType)
{
    switch (drawingType){
	case kCommandStrokedAndFilledRects:
	    drawStrokedAndFilledRects(context);
	    break;

	case kCommandAlphaRects:
	    drawAlphaRects(context);
	    break;
		
	case kCommandSimpleClip:
	    doDrawImageFile(context, true);
	    break;
	
	case kCommandDrawImageFile:
	    doDrawImageFile(context, false);
	    break;
	    
	case kCommandDoUncachedDrawing:
	    drawUncachedForLayer(context);
	    break;

	case kCommandDoCGLayer:
	    drawSimpleCGLayer(context);
	    break;
	    
	default:
	    break;
    }
}

void drawStrokedAndFilledRects(CGContextRef context)
{
	// Make a CGRect that has its origin at (40,40)
	// with a width of 130 units and height of 100 units.
	CGRect ourRect = CGRectMake(40, 40, 130, 100);
		 
	// Set the fill color to an opaque blue.
	CGContextSetFillColorWithColor(context, myGetBlueColor());
	// Fill the rect.
	CGContextFillRect(context, ourRect);

	// Set the stroke color to an opaque green.
	CGContextSetStrokeColorWithColor(context, myGetGreenColor());
	// Stroke the rect with a line width of 10 units.
	CGContextStrokeRectWithWidth(context, ourRect, 10);

	// Save the current graphics state.
	CGContextSaveGState(context);
		// Translate the coordinate system origin to the right 
		// by 200 units.
		CGContextTranslateCTM(context, 200, 0);
		// Stroke the rect with a line width of 10 units.
		CGContextStrokeRectWithWidth(context, ourRect, 10);
		// Fill the rect.
		CGContextFillRect(context, ourRect);
	// Restore the graphics state to the previously saved
	// graphics state. This restores all graphics state
	// parameters to those in effect during the last call
	// to CGContextSaveGState. In this example that restores
	// the coordinate system to that in effect prior to the
	// call to CGContextTranslateCTM.
	CGContextRestoreGState(context);
}

/*
    Create a mutable path object that represents 'rect'.
    Note that this is for demonstrating how to create a simple
    CGPath object. The Quartz function CGPathAddRect would normally
    be a better choice for adding a rect to a CGPath object.
*/
static CGPathRef createRectPath(CGRect rect)
{
    CGMutablePathRef path = CGPathCreateMutable();
    
    // Start a new subpath.
    CGPathMoveToPoint(path, NULL, rect.origin.x, rect.origin.y);
    
    // ***** Segment 1 *****
    CGPathAddLineToPoint(path, NULL,  rect.origin.x + rect.size.width, rect.origin.y);
    
    
    // ***** Segment 2 *****
    CGPathAddLineToPoint(path, NULL, rect.origin.x + rect.size.width,
			 rect.origin.y + rect.size.height);
    
    // ***** Segment 3 *****
    CGPathAddLineToPoint(path, NULL, rect.origin.x, rect.origin.y + rect.size.height);
    
    // ***** Segment 4 is created by closing the path *****
    CGPathCloseSubpath(path);
    
    return path;
}


static void drawAlphaRects(CGContextRef context)
{
    CGRect ourRect = CGRectMake(0, 0, 130, 100);
    int numRects = 6;
    float rotateAngle = 2*M_PI/numRects;
    float tint, tintAdjust = 1.0/numRects;

    /*  Create the path object representing our rectangle. This
	example is for demonstrating the use of a CGPath object.
	For a simple rectangular shape, you'd typically use
	CGContextFillRect or CGContextStrokeRect instead of this
	approach.
    */
    CGPathRef path = createRectPath(ourRect);
    
    // Move the origin of coordinates to a location that allows
    // the drawing to be within the window.
    CGContextTranslateCTM(context, 2*ourRect.size.width, 
			   2*ourRect.size.height);
    
    // Set the fill color to a red color.
    CGContextSetFillColorWithColor(context, myGetRedColor());
    
    for(tint = 1.0;  0 < tint ; tint -= tintAdjust){
	// Set the global alpha to the tint value.
	CGContextSetAlpha(context, tint);

	// For a CGPath object that is a simple rect, 
	// this is equivalent to CGContextFillRect.
	CGContextBeginPath(context);
	CGContextAddPath(context, path);
	CGContextFillPath(context);
	
	// These transformations are cummulative.
	CGContextRotateCTM(context, rotateAngle);
    }
    // Release the CGPath object when finished with it.
    CGPathRelease(path);
}

static void drawCGImage(CGContextRef context, CFURLRef url)
{
    // Create a CGImageSource object from 'url'.
    CGImageSourceRef imageSource =  CGImageSourceCreateWithURL(url, NULL);
    
    // Create a CGImage object from the first image in the file. Image
    // indexes are 0 based.
    CGImageRef image = CGImageSourceCreateImageAtIndex( imageSource, 0, NULL );
    
    // Now that we've created the CGImage object, the imageSource is no longer
    // needed so release it. CGImageSource objects are CF objects so they are
    // released with CFRelease.
    CFRelease(imageSource);
    
    // Create a rectangle that has its origin at (100, 100) with the width
    // and height of the image itself.
    CGRect imageRect = CGRectMake(100, 100, CGImageGetWidth(image), CGImageGetHeight(image));
    
    // Draw the image into the rect.
    CGContextDrawImage(context, imageRect, image);
    
    // Release the image object we created. In Mac OS X v10.2 and later, CG objects
    // are CF objects so you can use CFRelease to release them. Image objects can also 
    // be released with CGImageRelease. 
    CFRelease(image);
}

static void clipImageToEllipse(CGContextRef context, CFURLRef url)
{
    // Create a CGImageSource object from 'url'.
    CGImageSourceRef imageSource =  CGImageSourceCreateWithURL(url, NULL);
    
    // Create a CGImage object from the first image in the file. Image
    // indexes are 0 based.
    CGImageRef image = CGImageSourceCreateImageAtIndex( imageSource, 0, NULL );
    
    // Now that we've created the CGImage object, the imageSource is no longer
    // needed so release it. CGImageSource objects are CF objects so they are
    // released with CFRelease.
    CFRelease(imageSource);
    
    // Create a rectangle that has its origin at (100, 100) with the width
    // and height of the image itself.
    CGRect imageRect = CGRectMake(100, 100, CGImageGetWidth(image), CGImageGetHeight(image));
    
	CGContextBeginPath(context);
	// Create an elliptical path corresponding to the image width and height.
	CGContextAddEllipseInRect(context, imageRect);
	// Clip to the current path.
	CGContextClip(context);
	
    // Draw the image into the rect, clipped by the ellipse.
    CGContextDrawImage(context, imageRect, image);
    
    // Release the image object we created. In Mac OS X v10.2 and later, CG objects
    // are CF objects so you can use CFRelease to release them. Image objects can also 
    // be released with CGImageRelease. 
    CFRelease(image);
}

static CGImageRef createRGBAImageFromQuartzDrawing(float dpi, OSType drawingCommand)
{
    // For generating RGBA data from drawing. Use a Letter size page as the 
    // image dimensions. Typically this size would be the minimum necessary to 
    // capture the drawing of interest. We want 8 bits per component and for
    // RGBA data there are 4 components.
    size_t width = 8.5*dpi, height = 11*dpi, bitsPerComponent = 8, numComps = 4;
    // Compute the minimum number of bytes in a given scanline.
    size_t bytesPerRow = width* bitsPerComponent/8 * numComps;

    // This bitmapInfo value specifies that we want the format where alpha is
    // premultiplied and is the last of the components. We use this to produce
    // RGBA data.
    CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast;

    // Round to nearest multiple of BEST_BYTE_ALIGNMENT for optimal performance.
    bytesPerRow = COMPUTE_BEST_BYTES_PER_ROW(bytesPerRow);
    
    // Allocate the data for the bitmap.
    char *data = malloc( bytesPerRow * height );
    
    // Create the bitmap context. Characterize the bitmap data with the
    // Generic RGB color space.
    CGContextRef bitmapContext = CGBitmapContextCreate( 
		    data, width, height, bitsPerComponent, bytesPerRow,
		    myGetGenericRGBSpace(), bitmapInfo);
    
    // Clear the destination bitmap so that it is completely transparent before
    // performing any drawing. This is appropriate for exporting PNG data or
    // other data formats that capture alpha data. If the destination output
    // format doesn't support alpha then a better choice would be to paint
    // to white.
    CGContextClearRect( bitmapContext, CGRectMake(0, 0, width, height) );
    
    // Scale the coordinate system so that 72 units are dpi pixels.
    CGContextScaleCTM( bitmapContext, dpi/72, dpi/72 );
    
    // Perform the requested drawing.
    myDispatchDrawing(bitmapContext, drawingCommand);
    
    // Create a CGImage object from the drawing performed to the bitmapContext.
    CGImageRef image = CGBitmapContextCreateImage(bitmapContext);
    
    // Release the bitmap context object and free the associated raster memory.
    CGContextRelease(bitmapContext);
    free(data);
    
    // Return the CGImage object this code created from the drawing.
    return image;
}

void myExportCGDrawingAsPNG(CFURLRef url, OSType drawingCommand)
{
    float dpi = 300;
    // Create an RGBA image from the Quartz drawing that corresponds to drawingCommand.
    CGImageRef image = createRGBAImageFromQuartzDrawing(dpi, drawingCommand);
    
    CFTypeRef keys[2], values[2]; 
    CFDictionaryRef properties = NULL;
    
    // Create a CGImageDestination object will write PNG data to URL.
    // We specify that this object will hold 1 image.
    CGImageDestinationRef imageDestination = 
	CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, NULL);
    
    // Set the keys to be the x and y resolution properties of the image.
    keys[0] = kCGImagePropertyDPIWidth;
    keys[1] = kCGImagePropertyDPIHeight;
    
    // Create a CFNumber for the resolution and use it as the 
    // x and y resolution.
    values[0] = values[1] = CFNumberCreate(NULL, kCFNumberFloatType, &dpi);
    
    // Create an properties dictionary with these keys.
    properties = CFDictionaryCreate(NULL, 
				 (const void **)keys, 
				 (const void **)values, 
				 2,  
				 &kCFTypeDictionaryKeyCallBacks,
				 &kCFTypeDictionaryValueCallBacks); 
    
    // Release the CFNumber the code created.
    CFRelease(values[0]);
    
    // Add the image to the destination, characterizing the image with
    // the properties dictionary.
    CGImageDestinationAddImage(imageDestination, image, properties);

    // Release the CGImage object that createRGBAImageFromQuartzDrawing
    // created.
    CGImageRelease(image);
    
    // Release the properties dictionary.
    CFRelease(properties);
    
    // When all the images (only 1 in this example) are added to the destination, 
    // finalize the CGImageDestination object. 
    CGImageDestinationFinalize(imageDestination);
    
    // Release the CGImageDestination when finished with it.
    CFRelease(imageDestination);
}

static CGLayerRef createCachedContent(CGContextRef c){
    // The cached content will be 50x50 units.
    float width = 50, height = 50;
    CGLayerRef layer;
    
    // Create the layer to draw into.
    layer = CGLayerCreateWithContext(c,  CGSizeMake(width, height), NULL);
    
    // Get the CG context corresponding to the layer.
    CGContextRef layerContext = CGLayerGetContext(layer);
    
    // Cache some very simple drawing just as an example.
    CGContextFillRect(layerContext, CGRectMake(0, 0, width, height) );
    
    // The layer now contains cached drawing so return it.
    return layer;
}

static void drawSimpleCGLayer(CGContextRef context)
{
    // Create a CGLayer object that represents some drawing.
    CGLayerRef layer = createCachedContent(context);
    
    // Get the size of the layer created.
    CGSize s = CGLayerGetSize(layer); 
    
    // Position the drawing to an appropriate location.
    CGContextTranslateCTM(context, 40, 100);
    
    int i;
    // Paint 4 columns of layer objects.
    for(i = 0 ; i < 4 ; i++){
	// Draw the layer at the point that varies as the code loops.
	CGContextDrawLayerAtPoint(context, 
			    CGPointMake(2*(i+1)*s.width, 0), 
			    layer);
    }
    // Release the layer when finished drawing with it.
    CGLayerRelease(layer); 
}

// The equivalent drawing as doSimpleCGLayer but without creating
// a CGLayer object and caching that drawing to a layer.
static void drawUncachedForLayer(CGContextRef context)
{
    CGRect r = CGRectMake(0, 0, 50, 50); 

    CGContextTranslateCTM(context, 40, 100);

    int i;
    for(i = 0 ; i < 4 ; i++){ // Paint 4 columns of layer objects.
	// Adjust the origin as the code loops. Recall that
	// transformations are cummulative.
	CGContextTranslateCTM( context, 2*CGRectGetWidth(r), 0 );
	CGContextFillRect(context, r); // Do the uncached drawing.
    }
}

// Create a PDF document at 'url' from the drawing represented by drawingCommand. 
void myCreatePDFDocument(CFURLRef url, OSType drawingCommand) 
{
    // mediaRect represents the media box for the PDF document the code is
    // creating. The size here is that of a US Letter size sheet.
    const CGRect mediaRect = CGRectMake(0, 0, 8.5*72, 11*72);
    
    // Create a CGContext object to capture the drawing as a PDF document located
    // at 'url'.
    CGContextRef pdfContext = CGPDFContextCreateWithURL(url, &mediaRect, NULL);
    
    // Start capturing drawing on a page. 
    CGContextBeginPage(pdfContext, &mediaRect);
    
    // Perform drawing for the first page.
    myDispatchDrawing(pdfContext, drawingCommand);
    
    // Tell the PDF context that drawing for the current page is finished.
    CGContextEndPage(pdfContext);
        
    /* If there were more pages they would be captured as:
	
        CGContextBeginPage(pdfContext, &mediaRect);
	
	DrawingForPage2(pdfContext);
    
	CGContextEndPage(pdfContext);
    
	CGContextBeginPage(pdfContext, &mediaRect);
    
	....
    */
    
    // When done with drawing to the PDF context, the code needs to release it.
    // Without releasing the context the contents of the PDF document will not be
    // flushed properly.
    CGContextRelease(pdfContext);  
}
