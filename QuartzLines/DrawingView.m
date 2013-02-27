/*

File: DrawingView.m
Abstract: This sample code shows 4 different ways of drawing
lines. Each way is measured for performance. These include 
drawing lines:
    - as separate CGPaths
    - as a single CGPath
    - using the new bulk line drawing function in Tiger
    - by limiting the number of lines drawn

Version: <1.0>

© Copyright 2005 Apple Computer, Inc. All rights reserved.

IMPORTANT:  This Apple software is supplied to 
you by Apple Computer, Inc. ("Apple") in 
consideration of your agreement to the following 
terms, and your use, installation, modification 
or redistribution of this Apple software 
constitutes acceptance of these terms.  If you do 
not agree with these terms, please do not use, 
install, modify or redistribute this Apple 
software.

In consideration of your agreement to abide by 
the following terms, and subject to these terms, 
Apple grants you a personal, non-exclusive 
license, under Apple's copyrights in this 
original Apple software (the "Apple Software"), 
to use, reproduce, modify and redistribute the 
Apple Software, with or without modifications, in 
source and/or binary forms; provided that if you 
redistribute the Apple Software in its entirety 
and without modifications, you must retain this 
notice and the following text and disclaimers in 
all such redistributions of the Apple Software. 
Neither the name, trademarks, service marks or 
logos of Apple Computer, Inc. may be used to 
endorse or promote products derived from the 
Apple Software without specific prior written 
permission from Apple.  Except as expressly 
stated in this notice, no other rights or 
licenses, express or implied, are granted by 
Apple herein, including but not limited to any 
patent rights that may be infringed by your 
derivative works or by other works in which the 
Apple Software may be incorporated.

The Apple Software is provided by Apple on an "AS 
IS" basis.  APPLE MAKES NO WARRANTIES, EXPRESS OR 
IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED 
WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY 
AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING 
THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE 
OR IN COMBINATION WITH YOUR PRODUCTS.

IN NO EVENT SHALL APPLE BE LIABLE FOR ANY 
SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL 
DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS 
OF USE, DATA, OR PROFITS; OR BUSINESS 
INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, 
REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF 
THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER 
UNDER THEORY OF CONTRACT, TORT (INCLUDING 
NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN 
IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF 
SUCH DAMAGE.

*/

#import "DrawingView.h"
#include <mach/mach.h>
#include <mach/mach_time.h>


#define NSRectToCGRect(r) CGRectMake(r.origin.x, r.origin.y, r.size.width, r.size.height)

#define kTotalDataPoints 10000
#define kMaxIncrement (1<<20)
#define kGutter 10

float sampledData[kTotalDataPoints];
CGPoint sampledPoints[kTotalDataPoints*2];
float maxDataValue = 0;
char text[256];

static void drawBackground(CGContextRef context, CGRect rect);
static void drawAsOnePath(CGContextRef context, CGRect rect);
static void drawAsLines(CGContextRef context, CGRect rect);
static void drawAsBulkLines(CGContextRef context, CGRect rect);
static void drawAsLimitedLines(CGContextRef context, CGRect rect);
static __inline__ double currentTime(void);

@implementation DrawingView

- (id)initWithFrame:(NSRect)frameRect
{
    int i;
    
    srandom(100);

    if ((self = [super initWithFrame:frameRect]) != nil) {
    
	// initialize the sampled data using random values 
	sampledData[0] = 0;
	for (i = 1 ; i < kTotalDataPoints; i++) {
	    sampledData[i] = sampledData[i-1] + random()%kMaxIncrement-kMaxIncrement/2;
	    if (maxDataValue < abs(sampledData[i])) maxDataValue = abs(sampledData[i]);
	}
    }
    return self;
}

- (void)drawRect:(NSRect)rect
{
    // Get the context to draw to
    NSGraphicsContext *nsctx = [NSGraphicsContext currentContext];
    CGContextRef context = (CGContextRef)[nsctx graphicsPort];
    
    
    CGRect r = NSRectToCGRect(rect);

    drawBackground(context, r);

    drawAsLines(context, r);

    CGContextTranslateCTM(context,0,-50.0);
    drawAsOnePath(context, r);

    CGContextTranslateCTM(context,0,-50.0);
    drawAsBulkLines(context, r);

    CGContextTranslateCTM(context,0,-50.0);
    drawAsLimitedLines(context, r);

    CGContextFlush(context);
}

//
// Draw the background and the axes
//
void drawBackground(CGContextRef context, CGRect rect)
{
    // Clear the background with white
    CGContextSetRGBFillColor(context, 1, 1, 1, 1);
    CGContextFillRect(context, NSRectToCGRect(rect));
    
    // Center the origin at center of a pixel
    CGContextTranslateCTM(context,0.5f,0.5f);
    
    // Draw the axes
    CGContextSaveGState(context);
    CGContextTranslateCTM(context,kGutter, (int)(rect.size.height / 2));
    CGContextBeginPath(context);
    CGContextMoveToPoint(context,0,rect.size.height / 2 - kGutter);
    CGContextAddLineToPoint(context,0, -rect.size.height / 2 + kGutter);
    CGContextMoveToPoint(context,0, 0);
    CGContextAddLineToPoint(context,rect.size.width - 2*kGutter, 0);
    CGContextStrokePath(context);
    CGContextRestoreGState(context);
}






////////////////////////////////////////////////////////////////////////////////////////
// Draw the each line as a separate path
////////////////////////////////////////////////////////////////////////////////////////
void drawAsLines(CGContextRef context, CGRect rect)
{
    int i;
    double time;
    float xscale = (rect.size.width - 2 *kGutter) / kTotalDataPoints;
    float yscale = (rect.size.height - 2 *kGutter) / 2. / maxDataValue;
    	
    // Modify the scale of the axes so that the data is visible
    CGContextSaveGState(context);
    CGContextTranslateCTM(context,kGutter, (int)(rect.size.height / 2));

    // Draw the path in blue
    CGContextSetRGBStrokeColor(context,0,0,1,1);


    // Time only the drawing portion
    time = currentTime();
    
    ////////////////////////////////////////////////////////////////////////////////////////
    // Draw each line as a separate path 
    ////////////////////////////////////////////////////////////////////////////////////////
    for (i = 1; i < kTotalDataPoints; i++) {
	CGContextBeginPath(context);
	CGContextMoveToPoint(context, (i-1) * xscale, sampledData[i-1] * yscale);
	CGContextAddLineToPoint(context, i * xscale, sampledData[i] * yscale);
	CGContextStrokePath(context);
    }
    
    
    time = currentTime() - time;    // calculate the total time taken
	
    CGContextRestoreGState(context);

    sprintf(text, "Drawing %d lines as multiple lines : %.1f ms, %.1f thousand lines/sec\n", 
	    kTotalDataPoints, time*1E3, (kTotalDataPoints / time)/1E3);
    CGContextSetRGBFillColor(context,0,0,1,1);
    CGContextSelectFont(context,"Helvetica",2,kCGEncodingMacRoman);
    CGContextShowTextAtPoint(context,kGutter*2,(int)(rect.size.height / 4),text,strlen(text)-1);

}





////////////////////////////////////////////////////////////////////////////////////////
// Draw the lines as one large path
////////////////////////////////////////////////////////////////////////////////////////
void drawAsOnePath(CGContextRef context, CGRect rect)
{
    CGMutablePathRef path;
    int i;
    double time;
    float xscale = (rect.size.width - 2 *kGutter) / kTotalDataPoints;
    float yscale = (rect.size.height - 2 *kGutter) / 2. / maxDataValue;
   	
    // Modify the scale of the axes so that the data is visible
    CGContextSaveGState(context);
    CGContextTranslateCTM(context,kGutter, (int)(rect.size.height / 2));

    // Draw the path in black
    CGContextSetRGBStrokeColor(context,0,0,0,1);

    // Create a CGPath using the sampled data
    path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, 0, sampledData[0]);
    for (i = 1; i < kTotalDataPoints; i++) {
	CGPathAddLineToPoint(path,NULL,i*xscale,sampledData[i]*yscale);
    }
	
    // Time only the drawing portion
    time = currentTime();

    ////////////////////////////////////////////////////////////////////////////////////////
    // Draw the lines as one large path
    ////////////////////////////////////////////////////////////////////////////////////////
    CGContextBeginPath(context);
    CGContextAddPath(context,path);
    CGContextStrokePath(context);
    
    
    time = currentTime() - time;    // calculate the total time taken
	
    CGContextRestoreGState(context);

    sprintf(text, "Drawing %d lines as one path : %.1f ms, %.1f thousand lines/sec\n", 
	    kTotalDataPoints, time*1E3, (kTotalDataPoints / time)/1E3);
    CGContextSetRGBFillColor(context,0,0,0,1);
    CGContextSelectFont(context,"Helvetica",2,kCGEncodingMacRoman);
    CGContextShowTextAtPoint(context,kGutter*2,(int)(rect.size.height / 4),text,strlen(text)-1);
	
    CFRelease(path);
}





////////////////////////////////////////////////////////////////////////////////////////
// Draw the lines using the bulk API
////////////////////////////////////////////////////////////////////////////////////////
void drawAsBulkLines(CGContextRef context, CGRect rect)
{
    int i, count;
    double time;
    float xscale = (rect.size.width - 2 *kGutter) / kTotalDataPoints;
    float yscale = (rect.size.height - 2 *kGutter) / 2. / maxDataValue;
    	
    // Modify the scale of the axes so that the data is visible
    CGContextSaveGState(context);
    CGContextTranslateCTM(context,kGutter, (int)(rect.size.height / 2));

    // Draw the path in dark green
    CGContextSetRGBStrokeColor(context,0,0.5,0,1);

    // Build the bulk array of points
    count = 0;
    sampledPoints[count].x = 0 * xscale;
    sampledPoints[count].y = sampledData[0] * yscale;
    sampledPoints[++count].x = 1 * xscale;
    sampledPoints[count].y = sampledData[1] * yscale;

    for (i = 1; i < kTotalDataPoints; i++) {
	sampledPoints[++count].x = sampledPoints[count-1].x;
	sampledPoints[count].y = sampledPoints[count-1].y;
	sampledPoints[++count].x = i * xscale;
	sampledPoints[count].y = sampledData[i] * yscale;
    }
    
    // Time only the drawing portion
    time = currentTime();
    
    ////////////////////////////////////////////////////////////////////////////////////////
    // Use the bulk line drawing function to draw all the lines at once
    ////////////////////////////////////////////////////////////////////////////////////////
    CGContextStrokeLineSegments(context, sampledPoints, count );
    
    
    time = currentTime() - time;    // calculate the total time taken
	
    CGContextRestoreGState(context);
    
    sprintf(text, "Drawing %d lines as bulk lines : %.1f ms, %.1f thousand lines/sec\n", 
	    kTotalDataPoints, time*1E3, (kTotalDataPoints / time)/1E3);
    CGContextSetRGBFillColor(context,0,0.5,0,1);
    CGContextSelectFont(context,"Helvetica",2,kCGEncodingMacRoman);
    CGContextShowTextAtPoint(context,kGutter*2,(int)(rect.size.height / 4),text,strlen(text)-1);
    
}




////////////////////////////////////////////////////////////////////////////////////////
// Draw only a limited set of lines based on visibility to convey the same information
// Not all of the lines will be visible and several data points will overlap a single
// pixel, so only a portion of the sampled data needs to be drawn.
////////////////////////////////////////////////////////////////////////////////////////
void drawAsLimitedLines(CGContextRef context, CGRect rect)
{
    int i, count;
    double time;
    float sampleFrequency;
    int pixelWidth = (rect.size.width - 2 * kGutter);
    	
    // Modify the scale of the axes so that the data is visible
    CGContextSaveGState(context);
    CGContextTranslateCTM(context,kGutter, (int)(rect.size.height / 2));

    float yscale = (rect.size.height - 2 *kGutter) / 2. / maxDataValue;

    // Draw the path in red
    CGContextSetRGBStrokeColor(context,1,0,0,1);

    // Build the bulk array of points, but sub-sample the data to a limited set
    count = 0;
    sampledPoints[count].x = 0;
    sampledPoints[count].y = sampledData[0];

    // The sampling frequency is based on the total number of points and the visible number of pixels
    sampleFrequency = (float)kTotalDataPoints / pixelWidth;

    for (i = 1; i < pixelWidth; i++) {
	sampledPoints[++count].x = i;
	sampledPoints[count].y = sampledData[(int)(i*sampleFrequency)] * yscale;
	sampledPoints[++count].x = i;
	sampledPoints[count].y = sampledData[(int)(i*sampleFrequency)] * yscale;
    }


    time = currentTime();

    
    ////////////////////////////////////////////////////////////////////////////////////////
    // Use the bulk line drawing function to draw only the limited set of visible lines
    ////////////////////////////////////////////////////////////////////////////////////////
    
    CGContextStrokeLineSegments(context, sampledPoints, count );
    
    
    
    time = currentTime() - time;    // calculate the total time taken
    
    CGContextRestoreGState(context);

    sprintf(text, "Drawing %d lines instead : %.1f ms\n", pixelWidth, time*1E3);
    CGContextSetRGBFillColor(context,1,0,0,1);
    CGContextSelectFont(context,"Helvetica",2,kCGEncodingMacRoman);
    CGContextShowTextAtPoint(context,kGutter*2,(int)(rect.size.height / 4),text,strlen(text)-1);
}




//
// Returns the current time in seconds
// 
static __inline__ double 
currentTime(void)
{
    static double scale = 0;

    if (scale == 0) {
        mach_timebase_info_data_t info;
        mach_timebase_info(&info);
        scale = info.numer / info.denom * 1e-9;
    }

    return mach_absolute_time() * scale;
}

@end
