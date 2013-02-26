/*

File: Asset.h

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

#import <Cocoa/Cocoa.h>

/* An "Asset" is a file-granularity piece of media of some kind: an image, a movie, etc.  The API model presented here allows for every asset to provide a characteristic "preview image" that can be used to represent it in UI: a scaled-down version for an image, a poster frame image for a movie, etc.  CocoaSlides 1.0 only deals specifically with ImageAssets, but the basic characteristics shared by all assets have been split into the "Asset" base class to facilitate possible future extension to handle other kinds of assets such as movie files.
*/

@interface Asset : NSObject
{
    NSURL *url;                     // location of the referenced media file (from which all of the Asset's remaining properties can be obtained)
    NSDate *dateLastUpdated;        // date we last refreshed our cache of the file's metadata
    unsigned long long fileSize;    // size of data pointed to by URL
    NSImage *previewImage;          // preview image (if loaded/created)
    BOOL includedInSlideshow;       // should asset be included in slideshow playback?
}

+ (NSArray *)fileTypes;

- initWithURL:(NSURL *)newURL;

#pragma mark *** Accessors ***

- (NSURL *)url;
- (void)setURL:(NSURL *)newURL;

- (NSString *)filename; // convenience accessor that returns final part of URL

- (NSString *)localizedTypeDescription;

- (NSDate *)dateLastUpdated;
- (void)setDateLastUpdated:(NSDate *)newDate;

- (unsigned long long)fileSize;
- (void)setFileSize:(unsigned long long)newFileSize;

- (NSImage *)previewImage;
- (void)setPreviewImage:(NSImage *)newPreviewImage;

- (BOOL)includedInSlideshow;
- (void)setIncludedInSlideshow:(BOOL)flag;

#pragma mark *** Loading ***

// These are triggered automatically the first time relevant properties are requested, but can be invoked explicitly to force loading earlier.               
- (BOOL)loadMetadata;
- (BOOL)loadPreviewImage;

- (void)requestPreviewImage;

@end
