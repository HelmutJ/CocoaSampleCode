/*
     File: Controller.m
 Abstract: Implementation of the Controller class.
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


#import <AppKit/AppKit.h>
#import "Controller.h"


#define ZOOM_IN_FACTOR  1.414214
#define ZOOM_OUT_FACTOR 0.7071068


@implementation Controller
// ---------------------------------------------------------------------------------------------------------------------
- (BOOL)applicationShouldTerminateAfterLastWindowClosed: (NSApplication *)sender
{
    // terminate when last window was closed
    return YES;
}

// ---------------------------------------------------------------------------------------------------------------------
- (void)openImageURL: (NSURL*)url
{
    // use ImageIO to get the CGImage, image properties, and the image-UTType
    //
    CGImageRef          image = NULL;
    CGImageSourceRef    isr = CGImageSourceCreateWithURL( (__bridge CFURLRef)url, NULL);
    
    if (isr)
    {
		NSDictionary *options = [NSDictionary dictionaryWithObject: (id)kCFBooleanTrue  forKey: (id) kCGImageSourceShouldCache];
        image = CGImageSourceCreateImageAtIndex(isr, 0, (__bridge CFDictionaryRef)options);
        
        if (image)
        {
            _imageProperties = (NSDictionary*)CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(isr, 0, (__bridge CFDictionaryRef)_imageProperties));
            
            _imageUTType = (__bridge NSString*)CGImageSourceGetType(isr);
        }
		CFRelease(isr);

    }
    
    if (image)
    {
        [_imageView setImage: image
             imageProperties: _imageProperties];
		
		CGImageRelease(image);
        
        [_window setTitleWithRepresentedFilename: [url path]];
    }
}

// ---------------------------------------------------------------------------------------------------------------------
- (void)awakeFromNib
{
    // open the sample files that's inside the application bundle
    
    NSString *   path = [[NSBundle mainBundle] pathForResource: @"earring"
                                                        ofType: @"jpg"];
    NSURL *      url = [NSURL fileURLWithPath: path];
    
    [self openImageURL: url];
   
    // customize the IKImageView...
    [_imageView setDoubleClickOpensImageEditPanel: YES];
    [_imageView setCurrentToolMode: IKToolModeMove];
    [_imageView zoomImageToFit: self];
    [_imageView setDelegate: self];

}

// ---------------------------------------------------------------------------------------------------------------------
- (void)windowDidResize:(NSNotification *)notification
{
    // whenever the window gets resized - do a zoom-to-fit
    
    [CATransaction begin];
    [CATransaction setValue: [NSNumber numberWithFloat: 0]
                                               forKey: kCATransactionAnimationDuration];
    [_imageView zoomImageToFit: self];
    [CATransaction commit];
}

// ---------------------------------------------------------------------------------------------------------------------
- (IBAction)switchToolMode: (id)sender
{
    // switch the tool mode...
    
    NSInteger newTool;
    
    if ([sender isKindOfClass: [NSSegmentedControl class]])
        newTool = [sender selectedSegment];
    else
        newTool = [sender tag];
    
    switch (newTool)
    {
        case 0:
            [_imageView setCurrentToolMode: IKToolModeMove];
            break;
        case 1:
            [_imageView setCurrentToolMode: IKToolModeSelect];
            break;
        case 2:
            [_imageView setCurrentToolMode: IKToolModeCrop];
            break;
        case 3:
            [_imageView setCurrentToolMode: IKToolModeRotate];
            break;
        case 4:
            [_imageView setCurrentToolMode: IKToolModeAnnotate];
            break;
    }
}

// ---------------------------------------------------------------------------------------------------------------------
- (IBAction)doZoom: (id)sender
{
    // handle zoom tool...
    
    NSInteger zoom;
    CGFloat   zoomFactor;
    
    if ([sender isKindOfClass: [NSSegmentedControl class]])
        zoom = [sender selectedSegment];
    else
        zoom = [sender tag];
    
    switch (zoom)
    {
        case 0:
            zoomFactor = [_imageView zoomFactor];
            [_imageView setZoomFactor: zoomFactor * ZOOM_OUT_FACTOR];
            break;
        case 1:
            zoomFactor = [_imageView zoomFactor];
            [_imageView setZoomFactor: zoomFactor * ZOOM_IN_FACTOR];
            break;
        case 2:
            [_imageView zoomImageToActualSize: self];
            break;
        case 3:
            [_imageView zoomImageToFit: self];
            break;
    }
}

#pragma mark -------- file opening

// ---------------------------------------------------------------------------------------------------------------------
- (void)openPanelDidEnd: (NSOpenPanel *)panel 
             returnCode: (int)returnCode
            contextInfo: (void  *)contextInfo
{
    if (returnCode == NSOKButton)
    {
        // user did select an image...
        
        [self openImageURL: [[panel URLs] objectAtIndex: 0]];
    }
}

// ---------------------------------------------------------------------------------------------------------------------
- (IBAction)openImage: (id)sender
{
    // present open panel...
    
    NSString *    extensions = @"tiff/tif/TIFF/TIF/jpg/jpeg/JPG/JPEG";
    NSArray *     types = [extensions pathComponents];

	// Let the user choose an output file, then start the process of writing samples
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setAllowedFileTypes:types/*[NSArray arrayWithObject:AVFileTypeQuickTimeMovie]*/];
	[openPanel setCanSelectHiddenExtension:YES];
	[openPanel beginSheetModalForWindow:_window completionHandler:^(NSInteger result) {
		if (result == NSFileHandlingPanelOKButton)
        {
                // user did select an image...
                
                [self openImageURL: [openPanel URL]];
        }
	}];
}

#pragma mark -------- file saving

// ---------------------------------------------------------------------------------------------------------------------
- (void)savePanelDidEnd: (NSSavePanel *)sheet
             returnCode: (NSInteger)returnCode
{
    // save the image
    
    if (returnCode == NSOKButton)
    {
        NSString * newUTType = [_saveOptions imageUTType];
        CGImageRef image;
    
        // get the current image from the image view
        image = [_imageView image];
        
        if (image)
        {
            // use ImageIO to save the image in the user specified format
            NSURL *               url = [sheet URL];
            CGImageDestinationRef dest = CGImageDestinationCreateWithURL((__bridge CFURLRef)url, (__bridge CFStringRef)newUTType, 1, NULL);
            
            if (dest)
            {
                CGImageDestinationAddImage(dest, image, (__bridge CFDictionaryRef)[_saveOptions imageProperties]);
                CGImageDestinationFinalize(dest);
                CFRelease(dest);
            }
        } else
        {
            NSLog(@"*** saveImageToPath - no image");
        }
    }
}

// ---------------------------------------------------------------------------------------------------------------------
- (IBAction)saveImage: (id)sender
{
    // Let the user choose an output file, then start the process of writing samples
	NSSavePanel *savePanel = [NSSavePanel savePanel];
    _saveOptions = [[IKSaveOptions alloc] initWithImageProperties: _imageProperties
                                                      imageUTType: _imageUTType];
    
    [_saveOptions addSaveOptionsAccessoryViewToSavePanel: savePanel];
	[savePanel setCanSelectHiddenExtension:YES];
    [savePanel setNameFieldStringValue:[[_window representedFilename] lastPathComponent]];
	[savePanel beginSheetModalForWindow:_window completionHandler:^(NSInteger result) {
		if (result == NSFileHandlingPanelOKButton)
            [self savePanelDidEnd:savePanel returnCode:result];
	}];

    
}

@end
