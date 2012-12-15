/*
     File: ATFilterItem.m
 Abstract: A basic model object item that is used in the NSBrowser demo. An ATFilterItem represents a CoreImage filter.
 
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

#import "ATFilterItem.h"
#import <Quartz/Quartz.h>

@interface ATFilterItem()
@property (copy) NSString *filterName;
@property (retain) CIFilter *filter;
@end

@implementation ATFilterItem

@synthesize filter = _ciFilter;
@synthesize filterName = _filterName;
@synthesize columnIdx = _columnIdx;
@synthesize childItems = _children;
@synthesize inputKey = _inputKey;

#pragma mark Key Value Observing Dynamic Property Hints
+ (NSSet *)keyPathsForValuesAffectingResultingImage {
    return [NSSet setWithObjects:@"sourceImage", @"inputValue", nil];
}

+ (NSSet *)keyPathsForValuesAffectingResultingNSImage {
    return [NSSet setWithObject:@"resultingImage"];
}

+ (NSSet *)keyPathsForValuesAffectingInputValue {
    return [NSSet setWithObject:@"inputKey"];
}

+ (NSSet *)keyPathsForValuesAffectingInputMin {
    return [NSSet setWithObject:@"inputKey"];
}

+ (NSSet *)keyPathsForValuesAffectingInputMax {
    return [NSSet setWithObject:@"inputKey"];
}

+ (NSSet *)keyPathsForValuesAffectingLocalizedInputKeyName {
    return [NSSet setWithObject:@"inputKey"];
}

#pragma mark Class Methods
+ (ATFilterItem *)filterItemWithFilterName:(NSString*)filterName  inputKey:(NSString *)inputKey {
    return [[[ATFilterItem alloc] initWithFilterName:filterName inputKey:inputKey] autorelease];
}

- (ATFilterItem *)initWithFilterName:(NSString *)filterName inputKey:(NSString *)inputKey {
    if (self = [super init]) {
        // The filter with name @"" is the "None" filter and must be special cased.
        if (![filterName isEqualToString:@""]) {
            self.filter = [CIFilter filterWithName:filterName];
            if (self.filter) {
                [self.filter setDefaults];
                self.filterName = filterName;
                self.inputKey = inputKey;
            } else {
                // Failed to create the CIFilter. Probablay a bad filterName.
                [self release];
                self = nil;
            }
        } else {
            // This is the @"" ie "None" special case.
            self.filterName = filterName;
            // Create a child array with no children to avoid children from being added by the ATFilterBrowserController
            self.childItems = [NSArray array];
        }
    }
    return self;
}

- (void)dealloc {
    [_ciFilter release];
    [_sourceImage release];
    [super dealloc];
}

- (NSString *)localizedFilterName {
    if (self.filter) {
        return [CIFilter localizedNameForFilterName:self.filterName];
    }
    
    return NSLocalizedString(@"None", @"Stop applying filters");
}

- (void)setSourceImage:(CIImage *)sourceImage {
    if (_sourceImage != sourceImage) {
        [_sourceImage release];
        _sourceImage = [sourceImage retain];
    
        if (_sourceImage) {
            [self.filter setValue:_sourceImage forKey:kCIInputImageKey];
        }
    }
}

- (CIImage *)sourceImage {
    return _sourceImage;
}

- (CIImage *)resultingImage {
    CIImage *ciImage = self.sourceImage;
    
    if (ciImage != nil && self.filter != nil) {
        ciImage = [self.filter valueForKey:kCIOutputImageKey];
    }
    
    return ciImage;
}

// Core Image uses CIImage, so it's easer to keep the source and result as CIImages.
// However, we convert the result to an NSImage here to allow binding to an NSImageView.
- (NSImage *)resultingNSImage {
    CIImage *ciImage = self.resultingImage;
    if (ciImage != nil) {
        // We want to create a resulting image that is the same size as the source image.
        // To do that, we manually create a bitmap image rep and draw into it without the
        // extent that the filter applies.
        //
        CGRect imageExtent = [ciImage extent];
        imageExtent.size.width += 2*(imageExtent.origin.x);
        imageExtent.size.height += 2*(imageExtent.origin.y);
        imageExtent.origin = CGPointZero;

        NSSize sourceImageSize = NSSizeFromCGSize(imageExtent.size);
        NSBitmapImageRep *newImageRep = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:sourceImageSize.width
                               pixelsHigh:sourceImageSize.height bitsPerSample:8 samplesPerPixel:4 
                               hasAlpha:YES isPlanar:NO colorSpaceName:@"NSDeviceRGBColorSpace"
                               bytesPerRow:0 bitsPerPixel:0] autorelease];
        
        NSGraphicsContext *newContext = [NSGraphicsContext graphicsContextWithBitmapImageRep:newImageRep];
        [NSGraphicsContext saveGraphicsState]; {
            [NSGraphicsContext setCurrentContext:newContext];
            // This grabs a CoreImage context from the bitmap image rep
            CIContext *context = [[NSGraphicsContext currentContext] CIContext];
            // We can then control the position it is drawn into and from
            [context drawImage:ciImage atPoint:CGPointZero fromRect:imageExtent];
        }
        [NSGraphicsContext restoreGraphicsState];    

        NSImage *newImage = [[[NSImage alloc] initWithSize:sourceImageSize] autorelease];
        [newImage addRepresentation:newImageRep];
        return newImage;
    } else {
        return nil;
    }
}

// ATFilterItem only allows the modification of one filter attribute that must be set during
// initialization. This is done to keep this sample focused on NSBrowser while showing
// binding a user changeable value to a column header. If you want to read more on
// Core Image filters, stacking them, or thier various properties, please see the "Fun House" sample project.
//
- (NSNumber *)inputMin {
    return [[[self.filter attributes] objectForKey:self.inputKey] objectForKey:kCIAttributeSliderMin];
}

- (NSNumber *)inputMax {
    return [[[self.filter attributes] objectForKey:self.inputKey] objectForKey:kCIAttributeSliderMax];
}

- (NSNumber *)inputValue {
    return [self.filter valueForKey:self.inputKey];
}

- (void)setInputValue:(NSNumber *)value {
    [self.filter setValue:value forKey:self.inputKey];
}

- (NSString *)localizedInputKeyName {
    return [[[self.filter attributes] objectForKey:self.inputKey] objectForKey:kCIAttributeDisplayName];
}

@end
