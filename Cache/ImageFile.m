/*
     File: ImageFile.m
 Abstract: ImageFile represents the items displayed in the tableview. ImageFile hangs on to the image name and its original path, and will fetch the actual NSImage from an NSCache. If the NSImage has been evicted, ImageFile will recreate it and put it back in the cache.  It also sends out a ImageFileDidMissCacheNotification at that time.
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

#import "ImageFile.h"
#import <Foundation/NSCache.h>

NSString * const ImageFileDidMissCacheNotification = @"ImageFileDidMissCache";

static NSCache *imageCache = nil;

@implementation ImageFile
@synthesize path, name;

/* We use a single NSCache for all instances of ImageFile.  The count limit is set to a value that allows demonstrating the cache evicting objects.
*/
+ (void)initialize {
    if (self == [ImageFile class]) {
        imageCache = [[NSCache alloc] init];
        [imageCache setCountLimit:40];
    }
}

+ (NSCache *)imageCache {
    return imageCache;
}

/* In case we want to have a per-instance cache.
*/
- (NSCache *)imageCache {
    return imageCache;
}

/* We hang on to the path and name of each image.
*/
- (id)initWithPath:(NSString *)location {
    if (self = [super init]) {
	path = [location copy];
        name = [[[NSFileManager defaultManager] displayNameAtPath:location] copy];
    }
    return self;
}

- (void)dealloc {
    [[self imageCache] removeObjectForKey:self.path];
    [path release];
    [name release];
    [super dealloc];
}

/* To return the actual NSImage, we first look in the cache; if that fails, we create a new NSImage and put that in the cache.
*/
- (NSImage *)image {
    NSCache *cache = [self imageCache];
    NSString *imagePath = [self path];
    NSImage *image;
    if (!(image = [cache objectForKey:imagePath])) {
	// Cache miss, recreate image
	image = [[[NSImage alloc] initByReferencingFile:imagePath] autorelease];
	if (image) {	// Insert image in cache
	    [cache setObject:image forKey:imagePath];
	}
        
        [[NSNotificationCenter defaultCenter] postNotificationName:ImageFileDidMissCacheNotification object:self];
    }
    return image;
}

@end
