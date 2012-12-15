/*
     File: ATDesktopEntity.m
 Abstract: A sample model object. A base abstract class (ATDesktopEntity) implements caching of a file URL. One concrete subclass implements the ability to have an array of children (ATDesktopFolderEntity). Another (ATDesktopImageEntity) represents an image suitable for the desktop wallpaper.
 
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

#import "ATDesktopEntity.h"

#define THUMBNAIL_HEIGHT 180.0 

// For the purposes of a demo, we intentionally make things slower.
// Turning off the DEMO_MODE define will make things run at normal speed.
#define DEMO_MODE 1

@implementation ATDesktopEntity

@synthesize fileURL = _fileURL;
@dynamic title;

- (id)initWithFileURL:(NSURL *)fileURL {
    self = [super init];
    _fileURL = [fileURL retain];
    return self;
}

- (void)dealloc {
    [_fileURL release];    
    [super dealloc];
}

- (NSString *)title {
    NSString *result;
    if ([self.fileURL getResourceValue:&result forKey:NSURLLocalizedNameKey error:NULL]) {
        return result;
    }
    return nil;
}

@end

// We create an empty category to add property overrides
@interface ATDesktopImageEntity()

// Private read/write access to the thumbnailImage
@property (readwrite, retain) NSImage *thumbnailImage;
@property (readwrite) BOOL imageLoading;

@end

static NSOperationQueue *ATSharedOperationQueue() {
    static NSOperationQueue *_ATSharedOperationQueue = nil;
    if (_ATSharedOperationQueue == nil) {
        _ATSharedOperationQueue = [[NSOperationQueue alloc] init];
        // We limit the concurrency to see things easier for demo purposes.
        // The default value NSOperationQueueDefaultMaxConcurrentOperationCount will yield
        // better results, as it will create more threads, as appropriate for your processor
        //
#if DEMO_MODE
       [_ATSharedOperationQueue setMaxConcurrentOperationCount:1];
#endif
    }
    return _ATSharedOperationQueue;    
}



@implementation ATDesktopImageEntity

- (id)initWithFileURL:(NSURL *)fileURL {
    self = [super initWithFileURL:fileURL];
    // Initialize our color to specific given color for testing purposes
    static NSInteger lastColorIndex = 0;
    NSColorList *colorList = [NSColorList colorListNamed:@"Crayons"];
    NSArray *keys = [colorList allKeys];
    if (lastColorIndex >= keys.count) {
        lastColorIndex = 0;
    }
    _fillColorName = [[keys objectAtIndex:lastColorIndex++] retain];
    _fillColor = [[colorList colorWithKey:_fillColorName] retain];
    return self;
}

- (void)dealloc {
    [_thumbnailImage release];
    [_image release];
    [_fillColor release];
    [_fillColorName release];
    [super dealloc];
}

@synthesize fillColor = _fillColor;
@synthesize fillColorName = _fillColorName;
@synthesize imageLoading = _imageLoading;
@synthesize image = _image;
@synthesize thumbnailImage = _thumbnailImage;

static NSImage *ATThumbnailImageFromImage(NSImage *image) {
    NSSize imageSize = [image size];
    CGFloat imageAspectRatio = imageSize.width / imageSize.height;
    // Create a thumbnail image from this image (this part of the slow operation)
    NSSize thumbnailSize = NSMakeSize(THUMBNAIL_HEIGHT * imageAspectRatio, THUMBNAIL_HEIGHT);
    NSImage *thumbnailImage = [[NSImage alloc] initWithSize:thumbnailSize];
    [thumbnailImage lockFocus];
    [image drawInRect:NSMakeRect(0, 0, thumbnailSize.width, thumbnailSize.height) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];                
    [thumbnailImage unlockFocus];
    
#if DEMO_MODE
    // We delay things with an explicit sleep to get things slower for the demo!
    usleep(250000);
#endif
    
    return [thumbnailImage autorelease];
}

- (void)loadImage {
    @synchronized (self) {
        if (self.image == nil && !self.imageLoading) {
            self.imageLoading = YES;
            // We would have to keep track of the block with an NSBlockOperation, if we wanted to later support cancelling operations that have scrolled offscreen and are no longer needed. That will be left as an exercise to the user.
            [ATSharedOperationQueue() addOperationWithBlock:^(void) {
                NSImage *image = [[NSImage alloc] initWithContentsOfURL:self.fileURL];
                if (image != nil) {
                    NSImage *thumbnailImage = ATThumbnailImageFromImage(image);
                    // We synchronize access to the image/imageLoading pair of variables
                    @synchronized (self) {
                        self.imageLoading = NO;
                        self.image = image;
                        self.thumbnailImage = thumbnailImage;
                    }
                    [image release];
                }
            }];
        }
    }
}

@end

@implementation ATDesktopFolderEntity

- (void)dealloc {
    [_children release];
    [super dealloc];
}

@dynamic children;

- (NSArray *)children {
    NSArray *result = nil;
    // This property is declared as atomic. We use @synchronized to ensure that promise is kept
    @synchronized(self) {
        // It would be nice if this was asycnhronous to avoid any stalls while we look at the file system.
        // A mechanism similar to how the ATDesktopImageEntity loads images could be used here
        //
        if (_children == nil && self.fileURL != nil) {
            NSArray *imageUTIs = [NSImage imageTypes];
            
            NSError *error = nil;
            // Grab the URLs for the folder and wrap them in our entity objects
            NSArray *urls = [[[NSFileManager defaultManager] contentsOfDirectoryAtURL:self.fileURL includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLLocalizedNameKey, nil] options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsSubdirectoryDescendants error:&error] retain];
            NSMutableArray *newChildren = [[NSMutableArray alloc] initWithCapacity:urls.count];
            for (NSURL *url in urls) {
                // We create folder items or image items, and ignore everything else; all based on the UTI we get from the URL
                NSString *typeIdentifier;
                if ([url getResourceValue:&typeIdentifier forKey:NSURLTypeIdentifierKey error:NULL]) {
                    ATDesktopEntity *entity;
                    if ([imageUTIs containsObject:typeIdentifier]) {
                        entity = [[[ATDesktopImageEntity alloc] initWithFileURL:url] autorelease];
                    } else if ([typeIdentifier isEqualToString:(NSString *)kUTTypeFolder]) {
                        entity = [[[ATDesktopFolderEntity alloc] initWithFileURL:url] autorelease];;
                    } else {
                        entity = nil;
                    }
                    if (entity) {
                        [newChildren addObject:entity];
                    }
                }
            }
            _children = newChildren;
            [urls release];
        }
        result = [[_children retain] autorelease];
    }
    return result;
}

@end

NSString *const ATEntityPropertyNamedFillColor = @"fillColor";
NSString *const ATEntityPropertyNamedFillColorName = @"fillColorName";
NSString *const ATEntityPropertyNamedImage = @"image";
NSString *const ATEntityPropertyNamedThumbnailImage = @"thumbnailImage";

