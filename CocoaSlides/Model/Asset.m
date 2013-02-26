/*

File: Asset.m

Abstract: Asset Model Class for CocoaSlides

Version: 1.4

Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
Computer, Inc. ("Apple") in consideration of your agreement to the
following terms, and your use, installation, modification or
redistribution of this Apple software constitutes acceptance of these
terms.  If you do not agree with these terms, please do not use,
install, modify or redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and
subject to these terms, Apple grants you a personal, non-exclusive
license, under Apple's copyrights in this original Apple software (the
"Apple Software"), to use, reproduce, modify and redistribute the Apple
Software, with or without modifications, in source and/or binary forms;
provided that if you redistribute the Apple Software in its entirety and
without modifications, you must retain this notice and the following
text and disclaimers in all such redistributions of the Apple Software. 
Neither the name, trademarks, service marks or logos of Apple Computer,
Inc. may be used to endorse or promote products derived from the Apple
Software without specific prior written permission from Apple.  Except
as expressly stated in this notice, no other rights or licenses, express
or implied, are granted by Apple herein, including but not limited to
any patent rights that may be infringed by your derivative works or by
other works in which the Apple Software may be incorporated.

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

Copyright © 2006 Apple Computer, Inc., All Rights Reserved

*/

#import "Asset.h"

@implementation Asset

+ (NSArray *)fileTypes {
    // Subclasses should override this.
    return nil;
}

- initWithURL:(NSURL *)newURL {
    self = [super init];
    if (self) {
        [self setURL:newURL];
    }
    return self;
}

- (void)dealloc {
    [previewImage release];
    [dateLastUpdated release];
    [url release];
    [super dealloc];
}

- (NSURL *)url {
    return url;
}

- (void)setURL:(NSURL *)newURL {
    [url autorelease];
    url = [newURL copy];
}

- (NSString *)filename {
    return [[[[[self url] path] lastPathComponent] copy] autorelease];
}

- (NSString *)localizedTypeDescription {
    NSError *error;
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    NSString *type = [workspace typeOfFile:[[self url] path] error:&error];
    return type ? [workspace localizedDescriptionForType:type] : @"(Unrecognized file type)";
}

- (NSDate *)dateLastUpdated {
    return dateLastUpdated;
}

- (void)setDateLastUpdated:(NSDate *)newDate {
    id old = dateLastUpdated;
    dateLastUpdated = [newDate copy];
    [old release];
}

- (unsigned long long)fileSize {
    if (fileSize == 0) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSDictionary *attributes = [fileManager fileAttributesAtPath:[[self url] path] traverseLink:YES];
        fileSize = [[attributes objectForKey:NSFileSize] unsignedLongLongValue];
    }
    return fileSize;
}

- (void)setFileSize:(unsigned long long)newFileSize {
    fileSize = newFileSize;
}

- (NSImage *)previewImage {
    return previewImage;
}

- (void)setPreviewImage:(NSImage *)newPreviewImage {
    if (previewImage != newPreviewImage) {
        [previewImage autorelease];
        previewImage = [newPreviewImage retain];
    }
}

- (BOOL)includedInSlideshow {
    return includedInSlideshow;
}

- (void)setIncludedInSlideshow:(BOOL)flag {
    includedInSlideshow = flag;
}

- (BOOL)loadMetadata {
    // Subclasses should override this.
    return NO;
}

- (BOOL)loadPreviewImage {
    // Subclasses should override this.
    return NO;
}

- (void)loadPreviewImageInBackgroundThread:(id)unusedObject {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [self loadPreviewImage];
    [pool release];
}

- (void)requestPreviewImage {
    if (previewImage == nil) {
        [NSThread detachNewThreadSelector:@selector(loadPreviewImageInBackgroundThread:) toTarget:self withObject:nil];
    }
}

@end
