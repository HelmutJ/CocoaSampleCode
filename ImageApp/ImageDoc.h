/*

File: ImageDoc.h

Abstract: ImageDoc.h interface file

Version: <1.0>

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

Copyright © 2005-2011 Apple Inc. All Rights Reserved.

*/

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <ApplicationServices/ApplicationServices.h>

#import "Profile.h"
#import "ImageView.h"
#import "ImageFilter.h"

@interface ImageDoc : NSDocument <NSWindowDelegate>
{
    IBOutlet ImageView*			mImageView;
    IBOutlet NSSlider*			mExposureSlider;
    IBOutlet NSSlider*			mSaturationSlider;
    IBOutlet NSPopUpButton*		mProfilePopup;

    IBOutlet NSView*			mSavePanelView;
    NSString*					mSaveUTI;
    CFMutableDictionaryRef		mSaveMetaAndOpts;

    CGImageRef					mImage;
    CFDictionaryRef				mMetadata;
    ImageFilter*				mFilteredImage;

    NSArray*					mProfiles;

    NSNumber*					mSwitchValue;	
    Profile*					mProfileValue;
    NSNumber*					mExposureValue;	
    NSNumber*					mSaturationValue;

    NSPrintInfo*				mPrintInfo;
}

- (CGAffineTransform) imageTransform;
- (CIImage*) currentCIImageWithTransform:(CGAffineTransform)ctm;
- (CGSize) imageSize;

- (void) setupExposure;
- (void) setupSaturation;

- (BOOL) switchState;

- (NSNumber*) exposure;

- (Profile*) profile;

- (NSArray*) profiles;

- (NSNumber*) saturation;

- (int) saveCompression;

- (NSNumber*) saveQuality;

- (int) saveTab;

- (NSString*) saveType;

- (NSArray*) saveTypes;

- (void) drawImage:(CGContextRef) drawContext imageRect:(CGRect)drawImageRect;
- (BOOL) writeImageToURL:(NSURL *)absURL ofType:(NSString *)typeName error:(NSError **)outError;
- (BOOL) writeToURL:(NSURL *)absURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOp 
originalContentsURL:(NSURL *)absOrigURL error:(NSError **)outError;
+ (NSArray *) filterUndeclaredTypes:(NSArray *)supportedTypes;

@end
