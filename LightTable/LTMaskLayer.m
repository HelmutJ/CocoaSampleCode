/*
     File: LTMaskLayer.m
 Abstract: The LTMaskLayer is a CALayer that is used by  LTView to draw a single slide in the LTView. It acts as the frame and masking layer for its one child layer that is the image for the slide.
 
  Version: 1.0
 
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
 
 Copyright (C) 2009 Apple Inc. All Rights Reserved.
 
 */

#import "LTMaskLayer.h"
#import <ApplicationServices/ApplicationServices.h>


@implementation LTMaskLayer

- (id)init
{
    self = [super init];
    if (self) {
        
		// clip to within the photo area
		self.borderColor = CGColorCreateGenericRGB(0.85f, 0.85f, 0.85f, 1.0f);
		self.borderWidth = 8;
        self.cornerRadius = 26;
		self.masksToBounds = YES;
		
		// add on the visible photo that is masked by the border
		_visiblePhoto = [CALayer layer];
		_visiblePhoto.contents = nil;
        _visiblePhoto.anchorPoint =  CGPointMake(0, 0);
		
        [self addSublayer:_visiblePhoto];
	}
	
	return self;
}

- (void)dealloc
{
    [_source release];
	[super dealloc];
}


#pragma mark CALayer

// Overide hitTest so that our sub layers are never considered. LTMaskLayer is the end of the line.
- (CALayer *)hitTest:(CGPoint)hitPoint {
    hitPoint = [self convertPoint:hitPoint fromLayer:self.superlayer];
    return [self containsPoint:hitPoint] ? self : nil;
}


#pragma mark API

@synthesize photoLayer = _visiblePhoto;
@synthesize source = _source;

- (void)setFrame:(CGRect)frame {
    CGRect oldFrame = self.frame;
    if (!CGSizeEqualToSize(oldFrame.size, frame.size)) {
        CGRect oldPhotoFrame = _visiblePhoto.frame;
        CGFloat scaleFactorX = oldPhotoFrame.size.width / oldFrame.size.width;
        CGFloat scaleFactorY = oldPhotoFrame.size.height / oldFrame.size.height;
        
        CGRect newPhotoFrame;
        newPhotoFrame.size.width = frame.size.width * scaleFactorX;
        newPhotoFrame.size.height = frame.size.height * scaleFactorY;
        newPhotoFrame.origin.x = (oldPhotoFrame.origin.x / oldPhotoFrame.size.width) * newPhotoFrame.size.width;
        newPhotoFrame.origin.y = (oldPhotoFrame.origin.y / oldPhotoFrame.size.height) * newPhotoFrame.size.height;
        
 
        _visiblePhoto.frame = newPhotoFrame;
    }
    [super setFrame:frame];
}

- (id)photo {
    return _visiblePhoto.contents;
}

- (void)setPhoto:(id)newContents {
    _visiblePhoto.contents = newContents;
}

- (CGRect)photoFrame{
    return [self convertRect:_visiblePhoto.frame toLayer:self.superlayer];
}

- (void)setPhotoFrame:(CGRect)frame {
    _visiblePhoto.frame = [self convertRect:frame fromLayer:self.superlayer];
}

- (CGPoint)photoPosition{
    return [self convertPoint:_visiblePhoto.position toLayer:self.superlayer];
}

- (void)setPhotoPosition:(CGPoint)position {
    _visiblePhoto.position = [self convertPoint:position fromLayer:self.superlayer];
}

@end

