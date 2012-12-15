/*
     File: PhotoCellViewController.m 
 Abstract: The view controller for each Photo Cell View. It is responsible for setting up the representedObject dictionary from a URL, determining the photo orientation, and providing the images for dragging.
  
  Version: 1.2 
  
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

#import "PhotoCellViewController.h"

// Helper function
NSImage *cacheImageOfView(NSView *view);

@implementation PhotoCellViewController

@synthesize photoView;
@synthesize labelView;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    
    return self;
}

- (void)loadView {
    [super loadView];
    [self.photoView unregisterDraggedTypes];
}

+ (PhotoCellViewController *)photoCellViewControllerWithURL:(NSURL *)url {
    MDItemRef mdItemRef = MDItemCreateWithURL(kCFAllocatorDefault, (CFURLRef)url);
    assert(mdItemRef);
    NSString *commentStr = [(NSString*)MDItemCopyAttribute(mdItemRef, kMDItemFinderComment) autorelease];
    if (!commentStr) commentStr = @"";
    CFRelease(mdItemRef);
    
    PhotoCellViewController *pcvController = [[PhotoCellViewController alloc] initWithNibName:@"PhotoCellView" bundle:nil];
    pcvController.representedObject = [NSDictionary dictionaryWithObjectsAndKeys:url, kImageUrlKey, commentStr, kLabelKey, nil];
    [pcvController loadView];
    
    return [pcvController autorelease];
}

- (PhotoCellOrientation)photoCellOrientation {
    PhotoCellOrientation orientation;
    NSImage *image = self.photoView.image;
    
    if (image) {
        NSSize imageSize = image.size;
        if (imageSize.width >= imageSize.height) {
            orientation = kPhotoCellOrientationLandscape;
        } else {
            orientation = kPhotoCellOrientationPortrait;
        }
    } else {
        orientation = kPhotoCellOrientationLandscape;
    }
    
    return orientation;
}

/* This method is called by MultiPhotoView to generate the dragging image components. The dragging image components for a Photo Cell View consist of the matte background, photo image, and comment label.
*/
- (NSArray*)imageComponentsForDrag {
    NSDraggingImageComponent *imageComponent;
    NSMutableArray *components = [NSMutableArray arrayWithCapacity:3];
    
    // Each dragging component image animates indpendantly. Since the photoView and labelView are subviews of the matte background view, we need to hide them so they are not included in the background image component snapshot.
    [self.photoView setHidden:YES];
    [self.labelView setHidden:YES];
    
    // dragging Image Components are painted from back to front, so but the background image first in the array.
    imageComponent = [NSDraggingImageComponent draggingImageComponentWithKey:@"background"];
    imageComponent.frame = self.view.bounds;
    imageComponent.contents = cacheImageOfView(self.view);
    [components addObject:imageComponent];
    
    // The matte background image snapshot is complete, we can show these views again.
    [self.photoView setHidden:NO];
    [self.labelView setHidden:NO];
    
    // snapshot the photo image
    imageComponent = [NSDraggingImageComponent draggingImageComponentWithKey:NSDraggingImageComponentIconKey];
    imageComponent.frame = [self.view convertRect:self.photoView.bounds fromView:self.photoView];
    imageComponent.contents = cacheImageOfView(self.photoView);
    [components addObject:imageComponent];
    
    // snapshot the label image
    imageComponent = [NSDraggingImageComponent draggingImageComponentWithKey:NSDraggingImageComponentLabelKey];
    imageComponent.frame = [self.view convertRect:self.labelView.bounds fromView:self.labelView];
    imageComponent.contents = cacheImageOfView(self.labelView);
    [components addObject:imageComponent];
    
    return components;
}

@end


NSImage *cacheImageOfView(NSView *view) {
    NSRect bounds = view.bounds;
    NSBitmapImageRep *bitmapImageRep = [view bitmapImageRepForCachingDisplayInRect:bounds];
    bzero([bitmapImageRep bitmapData], [bitmapImageRep bytesPerRow] * [bitmapImageRep pixelsHigh]);
    [view cacheDisplayInRect:bounds toBitmapImageRep:bitmapImageRep];
    NSImage *imageCache = [[NSImage alloc] initWithSize:[bitmapImageRep size]];
    [imageCache addRepresentation:bitmapImageRep];
    
    return [imageCache autorelease];
}



NSString * const kImageUrlKey = @"imageURL";
NSString * const kLabelKey = @"label";

