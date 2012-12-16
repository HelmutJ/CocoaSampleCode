/*
     File: Images.m
 Abstract: Images is the controller for displaying the list of ImageFile objects. In addition to holding on to the ImageFile instances, it will load the window, and also flash its flashView when a miss occurs in any of the ImageFile instances it's keeping.
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

#import "Images.h"
#import "ImageFile.h"

@interface Images ()
@property(readwrite, copy) NSString *lastMiss;	// Redeclaration of property as readwrite
@end

@implementation Images
@synthesize lastMiss, imageFiles;

/* We enumerate the folder, and create instances of the Image class for each image file. If an error occurs while enumerating the folder, nil is returned and *errorPtr is set to an appropriate NSError.
*/
- (id)initWithContentsOfFolder:(NSString *)folder error:(NSError **)errorPtr {
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folder error:errorPtr];
    if (!files) {
    	[self release];
	return nil;	// This will have set *errorPtr
    }
    
    if (self = [super init]) {
        NSArray *imageTypes = [NSImage imageFileTypes];
        NSNotificationCenter *noteCenter = [NSNotificationCenter defaultCenter];
        
	imageFiles = [[NSMutableArray alloc] init];
	for (NSString *path in files) {
	    if ([imageTypes containsObject:[path pathExtension]]) {
		ImageFile *imageFile = [[ImageFile alloc] initWithPath:[folder stringByAppendingPathComponent:path]];
		if (imageFile) {
		    [imageFiles addObject:imageFile];
		    // We observe all the images in this window for cache misses
                    [noteCenter addObserver:self selector:@selector(didMissCache:) name:ImageFileDidMissCacheNotification object:imageFile];
		    [imageFile release];
		}
	    }
	}
        
	// So far so good; load the UI
	(void)[NSBundle loadNibNamed:@"Images" owner:self];
        [[flashView window] makeKeyAndOrderFront:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.lastMiss = nil;
    [imageFiles release];
    [super dealloc];
}

- (void)didMissCache:(NSNotification *)note {
    // Cache miss causes a flash and displays the name of the missed image
    self.lastMiss = [[note object] name];
    [flashView flash:nil];
}

@end
