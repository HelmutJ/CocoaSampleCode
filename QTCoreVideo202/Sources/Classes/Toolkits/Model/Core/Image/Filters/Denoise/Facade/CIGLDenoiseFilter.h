//---------------------------------------------------------------------------
//
//	File: CIGLDenoiseFilter.h
//
// Abstract: Utility class for managing Core Image denoise filters.
// 			 
//  Disclaimer: IMPORTANT:  This Apple software is supplied to you by
//  Inc. ("Apple") in consideration of your agreement to the following terms, 
//  and your use, installation, modification or redistribution of this Apple 
//  software constitutes acceptance of these terms.  If you do not agree with 
//  these terms, please do not use, install, modify or redistribute this 
//  Apple software.
//  
//  In consideration of your agreement to abide by the following terms, and
//  subject to these terms, Apple grants you a personal, non-exclusive
//  license, under Apple's copyrights in this original Apple software (the
//  "Apple Software"), to use, reproduce, modify and redistribute the Apple
//  Software, with or without modifications, in source and/or binary forms;
//  provided that if you redistribute the Apple Software in its entirety and
//  without modifications, you must retain this notice and the following
//  text and disclaimers in all such redistributions of the Apple Software. 
//  Neither the name, trademarks, service marks or logos of Apple Inc. may 
//  be used to endorse or promote products derived from the Apple Software 
//  without specific prior written permission from Apple.  Except as 
//  expressly stated in this notice, no other rights or licenses, express
//  or implied, are granted by Apple herein, including but not limited to
//  any patent rights that may be infringed by your derivative works or by
//  other works in which the Apple Software may be incorporated.
//  
//  The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
//  MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
//  THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
//  FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
//  OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
//  
//  IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
//  OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
//  MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
//  AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
//  STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
// 
//  Copyright (c) 2011 Apple Inc., All rights reserved.
//
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

typedef struct CIGLDenoiseFilterData *CIGLDenoiseFilterDataRef;

//---------------------------------------------------------------------------

@interface CIGLDenoiseFilter : NSObject
{
@private
    CIGLDenoiseFilterDataRef mpDenoiseFilter;
} // CIDenoiseFilter

// Designaterd initializers

- (id) initDenoiseFilterFromFile:(NSString *)thePathname
                         context:(NSOpenGLContext *)theContext
                          format:(NSOpenGLPixelFormat *)thePixelFormat;

- (id) initDenoiseFilterWithData:(NSData *)theData
                         context:(NSOpenGLContext *)theContext
                          format:(NSOpenGLPixelFormat *)thePixelFormat;

// Accessors for texture

- (GLenum) target;
- (GLfloat) aspect;

// Accessors for bound & size

- (CGRect) extent;
- (CGSize) size;

// Accessors for noise reduction filter only

- (BOOL) setSharpness:(const CGFloat)theSharpness;
- (BOOL) setNoiseLevel:(const CGFloat)theNoiseLevel;

// For accessing denoised image

- (void) bind;
- (void) unbind;

// Displaying the denoised image bound to a quad

- (void) display;

// Updating the framebuffer

- (void) update;

// Getting a snapshot of the framebuffer

- (BOOL) readback;

- (CGImageRef) snapshot;

// Saving a framebuffer's snapshot

- (BOOL) saveAs:(CFStringRef)theName
         UTType:(CFStringRef)theUTType;

// Denosie filter selection

- (void) median;
- (void) noiseReduction;

// Updating the context with a file or data

- (BOOL) updateWithData:(NSData *)theImageData;
- (BOOL) updateFromFile:(NSString *)theImageFile;

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
