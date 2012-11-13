
/*
     File: CIMicroPaintView.m
 Abstract: Subclass of SampleCIView to handle painting.
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

#import "CIMicroPaintView.h"

@interface CIMicroPaintView ()

@property (nonatomic, strong) CIImageAccumulator *imageAccumulator;
@property (nonatomic, strong) NSColor *color;
@property (nonatomic, strong) CIFilter *brushFilter;
@property (nonatomic, strong) CIFilter *compositeFilter;
@property (assign) CGFloat brushSize;

@end




@implementation CIMicroPaintView
{
}

- (id)initWithFrame:(NSRect)frame 
{
    self = [super initWithFrame:frame];
    if (self != nil) {
        _brushSize = 25.0;

        _color = [NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:1.0];

        _brushFilter = [CIFilter filterWithName: @"CIRadialGradient" keysAndValues:
               @"inputColor1", [CIColor colorWithRed:0.0 green:0.0
               blue:0.0 alpha:0.0], @"inputRadius0", @0.0, nil];

        _compositeFilter = [CIFilter filterWithName: @"CISourceOverCompositing"];
    }
    return self;
}

- (void)viewBoundsDidChange:(NSRect)bounds
{
    if ((self.imageAccumulator != nil) && (CGRectEqualToRect (*(CGRect *)&bounds, [self.imageAccumulator extent]))) {
        return;
    }

    /* Create a new accumulator and composite the old one over the it. */

    CIImageAccumulator *newAccumulator = [[CIImageAccumulator alloc] initWithExtent:*(CGRect *)&bounds format:kCIFormatRGBA16];
    CIFilter *filter = [CIFilter filterWithName:@"CIConstantColorGenerator" keysAndValues:@"inputColor", [CIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0], nil];
    [newAccumulator setImage:[filter valueForKey:@"outputImage"]];

    if (self.imageAccumulator != nil)
    {
        filter = [CIFilter filterWithName:@"CISourceOverCompositing"
             keysAndValues:@"inputImage", [self.imageAccumulator image],
             @"inputBackgroundImage", [newAccumulator image], nil];
        [newAccumulator setImage:[filter valueForKey:@"outputImage"]];
    }

    self.imageAccumulator = newAccumulator;

    [self setImage:[self.imageAccumulator image]];
}


- (void)mouseDragged:(NSEvent *)event
{
    CIFilter *brushFilter = self.brushFilter;
    
    NSPoint  loc = [self convertPoint:[event locationInWindow] fromView:nil];
    [brushFilter setValue:@(self.brushSize) forKey:@"inputRadius1"];
    
    CIColor *cicolor = [[CIColor alloc] initWithColor:self.color];
    [brushFilter setValue:cicolor forKey:@"inputColor0"];

    CIVector *inputCenter = [CIVector vectorWithX:loc.x Y:loc.y];
    [brushFilter setValue:inputCenter forKey:@"inputCenter"];
    
    
    CIFilter *compositeFilter = self.compositeFilter;

    [compositeFilter setValue:[brushFilter valueForKey:@"outputImage"] forKey:@"inputImage"];
    [compositeFilter setValue:[self.imageAccumulator image] forKey:@"inputBackgroundImage"];
    
    CGFloat brushSize = self.brushSize;
    CGRect rect = CGRectMake(loc.x-brushSize, loc.y-brushSize, 2.0*brushSize, 2.0*brushSize);

    [self.imageAccumulator setImage:[compositeFilter valueForKey:@"outputImage"] dirtyRect:rect];
    [self setImage:[self.imageAccumulator image] dirtyRect:rect];
}


- (void)mouseDown:(NSEvent *)event
{
    [self mouseDragged: event];
}


@end
