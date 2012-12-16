/*
     File: Controller.m
 Abstract: Controller for the Cache demo. On launch it creates the  folder of default demo images and opens it.  The creation of the demo images involves some NSBitmapImageRep usage, using a single image as the template and creating copies labelled with an incrementing number to differentiate them. The Controller also implements open: to enable opening any folder.
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
 
 Copyright (C) 2012 Apple Inc. All Rights Reserved.
 
 */

#import "Controller.h"
#import "Images.h"

@implementation Controller

/* This method returns the folder where the standard demo images are stored. Although this may be a folder in the app bundle, in interest of keeping the sample code distribution small, we just ship one image which is replicated in a temporary location. The temporary folder is kept around and will be reused by further runs of the app by the same user during the same boot session. 

This method will return nil if the standard demo folder cannot be found and cannot be recreated.

One interesting part of the method is the way in which it reads the demo image, and creates additional ones. 
*/
- (NSString *)standardDemoImageFolder {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *demoImageFolder = [NSTemporaryDirectory() stringByAppendingPathComponent:@"com.apple.examples.Cache.DemoImages"];
    BOOL isDir;

    if ([fileManager fileExistsAtPath:demoImageFolder isDirectory:&isDir] && isDir) return demoImageFolder;	// Use existing folder as-is
    if (![fileManager createDirectoryAtPath:demoImageFolder withIntermediateDirectories:YES attributes:nil error:NULL]) return nil;

    // At this point we created the demo image folder, so now create the demo images
    // First load the "template" demo image as an NSBitmapImageRep
    NSURL *demoImageURL = [[NSBundle mainBundle] URLForResource:@"DemoImage" withExtension:@"jpg"];
    NSBitmapImageRep *demoImage = demoImageURL ? [NSBitmapImageRep imageRepWithContentsOfURL:demoImageURL] : nil;
    if (!demoImage) return nil;
    NSSize pixelSize = NSMakeSize([demoImage pixelsWide], [demoImage pixelsHigh]);
    
    // Create a new NSBitmapImageRep for drawing in; make sure it has the same size, resolution, and colorspace as the original
    NSBitmapImageRep *updatedImage = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:pixelSize.width pixelsHigh:pixelSize.height bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0] autorelease];
    updatedImage = [updatedImage bitmapImageRepByRetaggingWithColorSpace:[demoImage colorSpace]];
    [updatedImage setSize:[demoImage size]];

    // Now "focus" on the new NSBitmapImageRep to we can draw on it. Note that although we create many images, we just reuse the same scratch NSBitmapImageRep
    NSGraphicsContext *savedContext = [NSGraphicsContext currentContext];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:updatedImage]];

    // Text attributes to use
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:120.0], NSFontAttributeName, [NSColor whiteColor], NSForegroundColorAttributeName, nil];
    BOOL success = YES;
#define DemoImageCount 80
    NSInteger cnt = 0;
    while (success && cnt < DemoImageCount) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	// Draw the template image
        [demoImage draw];
	// And then the current image number
	[[NSString stringWithFormat:@"%03ld", (long)cnt] drawAtPoint:NSMakePoint(10.0, 10.0) withAttributes:textAttributes];
	// Create a JPEG for it and save it out
	NSData *JPEGRep = [updatedImage representationUsingType:NSJPEGFileType properties:nil];
	if (JPEGRep) {
	    NSURL *outputURL = [[NSURL fileURLWithPath:demoImageFolder isDirectory:YES] URLByAppendingPathComponent:[NSString stringWithFormat:@"Image%03ld.jpg", (long)cnt]];
	    success = [JPEGRep writeToURL:outputURL options:0 error:NULL];
	}
	[pool drain];
	cnt++;
    }

    // Restore graphics context
    [NSGraphicsContext setCurrentContext:savedContext];

    return success ? demoImageFolder : nil;
}

/* If the app is launched by dragging an image folder to the app icon, use that as the source of demo images.
*/
- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename {
    BOOL isDirectory;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filename isDirectory:&isDirectory] && isDirectory) {
        NSError *error;
        Images *demo = [[Images alloc] initWithContentsOfFolder:filename error:&error];
        if (demo) {
            [demo release];
	    openedOne = YES;
            return YES;
        } else {
            [NSApp presentError:error];
            return NO;
        }
    } else {
        return NO;
    }
}

/* This method checks to see if the app was opened by opening a folder; if not, it goes ahead and opens the demo folder of images. (And if the demo folder fails to open, then it puts up an open panel.)
*/
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    if (!openedOne) {
	NSString *demoPath = [self standardDemoImageFolder];
	if (demoPath) {
	    [self application:NSApp openFile:demoPath];
	} else {
	    [self open:nil];
	}
    }
}

- (IBAction)open:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseFiles:NO];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setAllowedFileTypes:[NSArray arrayWithObject:(NSString *)kUTTypeDirectory]];
    if ([openPanel runModal] == NSOKButton) {
        NSURL *url = [openPanel URL];
        if ([url isFileURL]) {
            NSString *path = [url path];
            if (path) {
                [self application:NSApp openFile:path];
            } else {
                NSBeep();
            }
        }
    }
}

@end
