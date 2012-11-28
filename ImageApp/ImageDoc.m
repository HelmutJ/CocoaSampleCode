/*

File: ImageDoc.m

Abstract: ImageDoc.m class implementation

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

Copyright © 2005-2012 Apple Inc. All Rights Reserved.

*/

#import "ImageDoc.h"
#import "PrintView.h"
#import "ImageInfoPanel.h"


/* 
 *  Typically, an application that uses NSDocument can only
 *  support a static list of file formats enumrated in its Info.plist 
 *  file.
 *  
 *  This subclass of NSDocument is provided so that this
 *  application can dynamically support all the file formats supported 
 *  by ImageIO.
 */
 
static NSString* ImageIOLocalizedString (NSString* key)
{
    static NSBundle* b = nil;
    
    if (b==nil)
        b = [NSBundle bundleWithIdentifier:@"com.apple.ImageIO.framework"];
    
    // Returns a localized version of the string designated by 'key' in table 'CGImageSource'. 
    return [b localizedStringForKey:key value:key table: @"CGImageSource"];
}


@implementation ImageDoc


// Return the names of the types for which this class can be instantiated to play the 
// Editor or Viewer role.  
//
+ (NSArray*) readableTypes
{    
    return ([self filterUndeclaredTypes:(__bridge_transfer NSArray*)CGImageSourceCopyTypeIdentifiers()]);
}


// Return the names of the types which this class can save. Typically this includes all types 
// for which the application can play the Viewer role, plus types than can be merely exported by 
// the application.
//
+ (NSArray*) writableTypes
{
    return (__bridge_transfer NSArray*)CGImageDestinationCopyTypeIdentifiers();
}


// Return YES if instances of this class can be instantiated to play the Editor role.
//
+ (BOOL)isNativeType:(NSString *)type
{
    return [[self writableTypes] containsObject:type];
}

// Given a list of supported UTIs, filter out any undeclared image types.
+(NSArray *) filterUndeclaredTypes:(NSArray *)supportedTypes
{
    NSMutableArray *filteredTypes = [NSMutableArray arrayWithCapacity:0];    

    [supportedTypes enumerateObjectsUsingBlock:^(id obj, NSUInteger index, BOOL *stop)
     {
         BOOL supported = [[NSWorkspace sharedWorkspace] type:obj conformsToType:(NSString *)kUTTypeImage];
         if (supported) 
         {
             [filteredTypes addObject:obj];
         }
     }];
    
    return filteredTypes;
}

- (void) dealloc
{
    CGImageRelease(mImage);
    if (mMetadata) CFRelease(mMetadata);
    
    if (mSaveMetaAndOpts) CFRelease(mSaveMetaAndOpts);

    [[self undoManager] removeAllActionsWithTarget: self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (NSString*) windowNibName
{
    return @"ImageDoc"; 
}


#pragma mark -

- (NSArray*) profiles
{
    if (mProfiles == nil)
    {
        NSArray* profArray = [Profile arrayOfAllProfiles];
        if (profArray) 
        {            
            CFIndex i, count = [profArray count];
            NSMutableArray* profs = [NSMutableArray arrayWithCapacity:0];
            
            for (i=0; i<count; i++)
            {
                // check profile space and class
                Profile* prof = (Profile*)[profArray objectAtIndex:i];
                icColorSpaceSignature pSpace = [prof spaceType];
                icProfileClassSignature pClass = [prof classType];
                
                // look only for image profiles with RGB, CMYK and Gray color spaces,
                // and only monitor and printer profiles
                if ((pSpace == icSigRgbData || pSpace == icSigCmykData || pSpace == icSigGrayData) && 
                    (pClass == icSigDisplayClass || pClass == icSigOutputClass) && [prof description])
                    [profs addObject:prof];
            }            
            mProfiles = profs;
        }
    }
    return mProfiles;
}

// getter for image effects state (on or off)
- (BOOL) switchState
{
    return [mSwitchValue boolValue];
}

- (NSNumber*) exposure
{
    return mExposureValue;
}

- (NSNumber*) saturation
{
    return mSaturationValue;
}

- (Profile*) profile
{
    return mProfileValue;
}


// Keep track of image effects state
//  val parameter is TRUE if effects are turned on for the image
//  val parameter is FALSE if effects are turned off for the image
//
- (void) setSwitchState:(NSNumber*)val
{
    if (val == mSwitchValue)
        return;
    
    if (mSwitchValue)
    {
        [[self undoManager] registerUndoWithTarget:self selector:@selector(setSwitchState:) object:mSwitchValue];
        [[self undoManager] setActionName:[mSwitchValue intValue]?@"Disable Effects":@"Enable Effects"];
    }
    
    mSwitchValue = val;
    [mImageView setNeedsDisplay:YES];
}


// Setter for image exposure value
//
- (void) setExposure:(NSNumber*)val
{
    if (val == mExposureValue)
        return;
    
    if (mExposureValue)
    {
        [[self undoManager] registerUndoWithTarget:self selector:@selector(setExposure:) object:mExposureValue];
        [[self undoManager] setActionName:@"Exposure"];
    }

    mExposureValue = val;
    [mFilteredImage setExposure:mExposureValue];
    [mImageView setNeedsDisplay:YES];
}


// Setter for image saturation value
//
- (void) setSaturation:(NSNumber*)val
{
    if (val == mSaturationValue)
        return;
    
    if (mSaturationValue)
    {
        [[self undoManager] registerUndoWithTarget:self selector:@selector(setSaturation:) object:mSaturationValue];
        [[self undoManager] setActionName:@"Saturation"];
    }
    
    mSaturationValue = val;
    [mFilteredImage setSaturation:mSaturationValue];
    [mImageView setNeedsDisplay:YES];
}


// Setter for image profile
//
- (void) setProfile:(Profile*)val
{
    if (val == mProfileValue)
        return;
    
    if (mProfileValue)
    {
        [[self undoManager] registerUndoWithTarget:self selector:@selector(setProfile:) object:mProfileValue];
        [[self undoManager] setActionName:[[mProfilePopup selectedItem] title]];
    }
    
    mProfileValue = val;
    [mFilteredImage setProfile:mProfileValue];
    [mImageView setNeedsDisplay:YES];
}


// Initialization for image exposure slider
//
- (void) setupExposure
{
    CIFilter*      filter = [CIFilter filterWithName: @"CIExposureAdjust"];
    NSDictionary*  input = [[filter attributes] objectForKey: @"inputEV"];
    
    [mExposureSlider setMinValue: [[input objectForKey: @"CIAttributeSliderMin"] floatValue]/4.0];
    [mExposureSlider setMaxValue: [[input objectForKey: @"CIAttributeSliderMax"] floatValue]/4.0];

    [self setExposure:[input objectForKey: @"CIAttributeIdentity"]];
}


// Initialization for image saturation slider
//
- (void) setupSaturation
{
    CIFilter*      filter = [CIFilter filterWithName: @"CIColorControls"];
    NSDictionary*  input = [[filter attributes] objectForKey: @"inputSaturation"];
    
    [mSaturationSlider setMinValue: [[input objectForKey: @"CIAttributeSliderMin"] floatValue]];
    [mSaturationSlider setMaxValue: [[input objectForKey: @"CIAttributeSliderMax"] floatValue]];
    
    [self setSaturation:[input objectForKey: @"CIAttributeIdentity"]];
}


- (void) setupAll
{
    // Reset the sliders et. al.
    [self setSwitchState:[NSNumber numberWithBool:FALSE]];
    [self setupExposure];
    [self setupSaturation];
    [self setProfile:[Profile profileWithSRGB]];
    
    // Un-dirty the file and remove any undo state
    [self updateChangeCount:NSChangeCleared];
    [[self undoManager] removeAllActions];
}


#pragma mark -

// Getter for image dpi width value
//
- (float) dpiWidth
{
    NSNumber* val = [(__bridge NSDictionary*)mMetadata objectForKey:(id)kCGImagePropertyDPIWidth];
    float  f = [val floatValue];
    return (f==0 ? 72 : f); // return default 72 if none specified
}


// Getter for image dpi height value
//
- (float) dpiHeight
{
    NSNumber* val = [(__bridge NSDictionary*)mMetadata objectForKey:(id)kCGImagePropertyDPIHeight];
    float  f = [val floatValue];
    return (f==0 ? 72 : f); // return default 72 if none specified
}


// Getter for display orientation of the image. 
//
- (int) orientation
{
    // If present, the value of the kCGImagePropertyOrientation key is a 
    // CFNumberRef with the same value as defined by the TIFF and Exif 
    // specifications.  That is:
    //  1 =  row 0 top, col 0 lhs  =  normal
    //  2 =  row 0 top, col 0 rhs  =  flip horizontal
    //  3 =  row 0 bot, col 0 rhs  =  rotate 180
    //  4 =  row 0 bot, col 0 lhs  =  flip vertical
    //  5 =  row 0 lhs, col 0 top  =  rot -90, flip vert
    //  6 =  row 0 rhs, col 0 top  =  rot 90
    //  7 =  row 0 rhs, col 0 bot  =  rot 90, flip vert
    //  8 =  row 0 lhs, col 0 bot  =  rotate -90
    
    NSNumber* val = [(__bridge NSDictionary*)mMetadata objectForKey:(id)kCGImagePropertyOrientation];
    int orient = [val intValue];
    if (orient<1 || orient>8)
        orient = 1;
    return orient;
}


// Getter for image transform
//
- (CGAffineTransform) imageTransform
{
    float xdpi = [self dpiWidth];
    float ydpi = [self dpiHeight];
    int orient = [self orientation];
    
    float x = (ydpi>xdpi) ? ydpi/xdpi : 1;
    float y = (xdpi>ydpi) ? xdpi/ydpi : 1;
    float w = x * CGImageGetWidth(mImage);
    float h = y * CGImageGetHeight(mImage);
    
    CGAffineTransform ctms[8] = {
        { x, 0, 0, y, 0, 0},  //  1 =  row 0 top, col 0 lhs  =  normal
        {-x, 0, 0, y, w, 0},  //  2 =  row 0 top, col 0 rhs  =  flip horizontal
        {-x, 0, 0,-y, w, h},  //  3 =  row 0 bot, col 0 rhs  =  rotate 180
        { x, 0, 0,-y, 0, h},  //  4 =  row 0 bot, col 0 lhs  =  flip vertical
        { 0,-x,-y, 0, h, w},  //  5 =  row 0 lhs, col 0 top  =  rot -90, flip vert
        { 0,-x, y, 0, 0, w},  //  6 =  row 0 rhs, col 0 top  =  rot 90
        { 0, x, y, 0, 0, 0},  //  7 =  row 0 rhs, col 0 bot  =  rot 90, flip vert
        { 0, x,-y, 0, h, 0}   //  8 =  row 0 lhs, col 0 bot  =  rotate -90
    };
        
    return ctms[orient-1];
}


// Returns a new image representing the original image with the transform
// matrix ctm appended to it. 
//
- (CIImage*) currentCIImageWithTransform:(CGAffineTransform)ctm
{
    if ([self switchState])
        return [mFilteredImage imageWithTransform:ctm];
    else
        return nil;
}


// getter for image size
//
- (CGSize) imageSize
{
    return CGSizeMake(CGImageGetWidth(mImage), CGImageGetHeight(mImage));
}


// Draw the document image

- (void) drawImage:(CGContextRef) drawContext imageRect:(CGRect)drawImageRect
{
    // image effects turned on?
    if ([self switchState])
        [mFilteredImage drawFilteredImage:drawContext imageRect:drawImageRect];
    else
        CGContextDrawImage(drawContext, drawImageRect, mImage);
}


#pragma mark -


- (void) windowControllerDidLoadNib:(NSWindowController*) aController
{
    [super windowControllerDidLoadNib:aController];

    NSWindow* window = [self windowForSheet];
    [window setDelegate:self];
    [window setDisplaysWhenScreenProfileChanges:YES];
    
    [self setupAll];
}


- (BOOL) readFromURL:(NSURL *)absURL ofType:(NSString *)typeName error:(NSError **)outError
{
    BOOL status = YES;
    
    // Release and clear any old image variables
    
    mFilteredImage = nil;
    
    if (mMetadata) CFRelease(mMetadata);
    mMetadata = nil;
    
    CGImageRelease(mImage);
    mImage = nil;
    
    // Load (or reload) the image
    CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)absURL, NULL);
    if (!source)
        status = NO;
    
    // build options dictionary for image creation that specifies: 
    //
    // kCGImageSourceShouldCache = kCFBooleanTrue
    //      Specifies that image should be cached in a decoded form.
    //
    // kCGImageSourceShouldAllowFloat = kCFBooleanTrue
    //      Specifies that image should be returned as a floating
    //      point CGImageRef if supported by the file format.
    
    CGImageRef image = nil;
    NSDictionary* options = nil;
    
    if (status)
    {
        options = [NSDictionary dictionaryWithObjectsAndKeys:
                                 (id)kCFBooleanTrue, (id)kCGImageSourceShouldCache,
                                 (id)kCFBooleanTrue, (id)kCGImageSourceShouldAllowFloat,
                                 nil];
        
        image = CGImageSourceCreateImageAtIndex(source, 0, (__bridge CFDictionaryRef)options);
        
        // Assign user preferred default profiles if image is not tagged with a profile
        if (!image)
            status = NO;
    }
    
    if (status)
    {
        mImage = nil;
        
        Profile* dfltRGB  = [Profile profileDefaultRGB];
        Profile* dfltGray = [Profile profileDefaultGray];
        Profile* dfltCMYK = [Profile profileDefaultCMYK];
        
        CGColorSpaceRef devRGB  = CGColorSpaceCreateDeviceRGB();
        CGColorSpaceRef devGray = CGColorSpaceCreateDeviceGray();
        CGColorSpaceRef devCMYK = CGColorSpaceCreateDeviceCMYK();
        
        if (dfltRGB && CFEqual(devRGB,CGImageGetColorSpace(image)))
            mImage = CGImageCreateCopyWithColorSpace(image, [dfltRGB colorspace]);
        if (dfltGray && CFEqual(devGray,CGImageGetColorSpace(image)))
            mImage = CGImageCreateCopyWithColorSpace(image, [dfltGray colorspace]);
        if (dfltCMYK && CFEqual(devCMYK,CGImageGetColorSpace(image)))
            mImage = CGImageCreateCopyWithColorSpace(image, [dfltCMYK colorspace]);
        
        if (mImage == nil)
            mImage = CGImageRetain(image);
        
        if (!mImage) 
        {
            status = NO;
        }
        
        CFRelease(devRGB);
        CFRelease(devGray);
        CFRelease(devCMYK);
    }
    
    if (status) 
    {
        mMetadata = (CFMutableDictionaryRef)CGImageSourceCopyPropertiesAtIndex(source, 0, (__bridge CFDictionaryRef)options);
        if (!mMetadata) 
        {
            status = NO;
        }
    }

    if (status) {
        mFilteredImage = [(ImageFilter*)[ImageFilter alloc] initWithImage:mImage];
        if (!mFilteredImage) 
        {
            status = NO;
        }
    }
    
    if (source) 
    {
        CFRelease(source);
    }
    
    if (image) 
    {
        CGImageRelease(image);
    }
    
    if (mImage != nil)
    {
        status = YES;
    }
    
    if (status==NO && outError)
    {
        *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:nil];
    }
    
    return status;
}


#pragma mark -


/* 
    These methods NSDocument allow this document to present custom interface
    when saving.  The interface hace a custom format popup, quality slider,
    and compression type popup.
 */

- (NSMutableDictionary*) saveMetaAndOpts
{
    if (mSaveMetaAndOpts == nil)
    {
        if (mMetadata)
            mSaveMetaAndOpts = CFDictionaryCreateMutableCopy(nil, 0, mMetadata);
        else
            mSaveMetaAndOpts = CFDictionaryCreateMutable(nil, 0,
                         &kCFTypeDictionaryKeyCallBacks,  &kCFTypeDictionaryValueCallBacks);
    
        // save a dictionary of the image properties
        CFDictionaryRef tiffProfs = CFDictionaryGetValue(mSaveMetaAndOpts, kCGImagePropertyTIFFDictionary);

        CFMutableDictionaryRef tiffProfsMut;
        if (tiffProfs)
            tiffProfsMut = CFDictionaryCreateMutableCopy(nil, 0, tiffProfs);
        else
            tiffProfsMut = CFDictionaryCreateMutable(nil, 0,
                         &kCFTypeDictionaryKeyCallBacks,  &kCFTypeDictionaryValueCallBacks);
        CFDictionarySetValue(mSaveMetaAndOpts, kCGImagePropertyTIFFDictionary, tiffProfsMut);
        CFRelease(tiffProfsMut);
        
        CFDictionarySetValue(mSaveMetaAndOpts, kCGImageDestinationLossyCompressionQuality, 
                                    (__bridge const void *)[NSNumber numberWithFloat:0.85]);
    }
    return (__bridge NSMutableDictionary*)mSaveMetaAndOpts;
}


// Binding methods for save panel's image fomat popup menu.
//
- (NSArray*) saveTypes
{
    NSArray* wt = [ImageDoc writableTypes];
    NSMutableArray* wtl = [NSMutableArray arrayWithCapacity:0];
    NSEnumerator* enumerator = [wt objectEnumerator];
    NSString* type;
    while ((type = [enumerator nextObject]))
    {
        [wtl addObject:
            [NSDictionary dictionaryWithObjectsAndKeys:
                        type,@"uti",  
                        ImageIOLocalizedString(type),@"localized",  nil]];
    }
    return wtl;
}

- (NSString*) saveType
{
    if (mSaveUTI==nil)
    {
        if ([[ImageDoc writableTypes] containsObject:[self fileType]])
            mSaveUTI = [self fileType];
        else
            mSaveUTI = @"public.tiff";
    }
    return mSaveUTI;
}

- (void) setSaveType:(NSString*)uti
{
    [self willChangeValueForKey:@"saveTab"];
    mSaveUTI = uti;
    [self didChangeValueForKey:@"saveTab"];
    
    // get the file extension so we can control file types shown
    CFDictionaryRef utiDecl = UTTypeCopyDeclaration((__bridge CFStringRef)mSaveUTI);
    CFDictionaryRef utiSpec = CFDictionaryGetValue(utiDecl, kUTTypeTagSpecificationKey);
    CFTypeRef ext = CFDictionaryGetValue(utiSpec, kUTTagClassFilenameExtension);

    NSSavePanel* savePanel = (NSSavePanel*)[mSavePanelView window];
    if (CFGetTypeID(ext) == CFStringGetTypeID())
    {
         NSArray* type = [NSArray arrayWithObject:(__bridge id) ext];
        [savePanel setAllowedFileTypes:type];
    }
    else
        [savePanel setAllowedFileTypes:(__bridge NSArray*)ext];

    CFRelease(utiDecl);
}


// Binding method for save panel's tabless tab view.
// This tabless tabview (below file type popup) contains 
// panes with apporpiate UI for various file format. 
// In this simple implementaion:
//  pane index 2 contains the compression type popup for TIFF,
//  pane index 1 contains the quality slider for JPG and JP2,
//  pane index 0 is empty for all other formats.
//
- (int) saveTab
{
    // return the appropriate tab view index based on chosen format
    if ([mSaveUTI isEqual:@"public.tiff"])
        return 2;
    else if ([mSaveUTI isEqual:@"public.jpeg"] || [mSaveUTI isEqual:@"public.jpeg-2000"])
        return 1;
    else
        return 0;
}


// Binding methods for save panel's image quality slider.
// The slider's value is bound to the kCGImageDestinationLossyCompressionQuality
// value of the metadata/options dictionary to use when saving.
//
// We set the kCGImageDestinationLossyCompressionQuality option to specify
// the compression quality to use when writing to a jpeg or jp2 image
// desination. 0.0=maximum compression, 1.0=lossless compression
//
- (NSNumber*) saveQuality
{
    return [[self saveMetaAndOpts] objectForKey:(id)kCGImageDestinationLossyCompressionQuality];
}

- (void) setSaveQuality:(NSNumber*)q
{
    [[self saveMetaAndOpts] setObject:q forKey:(id)kCGImageDestinationLossyCompressionQuality];
}


// Binding methods for save panel's image compression popup.
// The popup's tag value is bound to the kCGImagePropertyTIFFCompression
// value of the kCGImagePropertyTIFFDictionary of the 
// metadata/options dictionary to use when saving.
//
// We set kCGImagePropertyTIFFDictionary > kCGImagePropertyTIFFCompression
// to specify the compression type to use when writing to a tiff image 
// destination. 1=no compression, 5=LZW,  32773=PackBits.
//
// Note: values for the compression options as just described (5=LZW, and so on)
//       are not currently defined in the Quartz (Core Graphics) interfaces, but 
//       these are the same as those defined in the Cocoa interfaces for 
//       _NSTIFFCompression as shown here (taken from NSBitmapImageRep.h):
//
// typedef enum _NSTIFFCompression {
//     NSTIFFCompressionNone		= 1,
//     NSTIFFCompressionCCITTFAX3	= 3,		/* 1 bps only */
//     NSTIFFCompressionCCITTFAX4	= 4,		/* 1 bps only */
//     NSTIFFCompressionLZW         = 5,
//     NSTIFFCompressionJPEG		= 6,		/* No longer supported for input or output */
//     NSTIFFCompressionNEXT		= 32766,	/* Input only */
//     NSTIFFCompressionPackBits	= 32773,
//     NSTIFFCompressionOldJPEG		= 32865		/* No longer supported for input or output */
// } NSTIFFCompression;
//

- (int) saveCompression
{
    NSNumber* val = [[[self saveMetaAndOpts] objectForKey:(id)kCGImagePropertyTIFFDictionary]
                            objectForKey:(id)kCGImagePropertyTIFFCompression];
    int comp = [val intValue];
    return (comp==1 || comp==5 || comp==32773) ? comp : 1;
}

- (void) setSaveCompression:(int)c
{
    [[[self saveMetaAndOpts] objectForKey:(id)kCGImagePropertyTIFFDictionary]
                                setObject:[NSNumber numberWithInt:c]
                                forKey:(id)kCGImagePropertyTIFFCompression];
}


// Insert our cusom save panel view
//
- (BOOL) prepareSavePanel:(NSSavePanel*)savePanel
{
    [savePanel setAccessoryView: mSavePanelView];

    // Set format popup to current UTI (or TIFF if current UTI is not writable)
    [self setSaveType:[self saveType]];
    
    return YES;
}


// We need to override this because our save panel has its own format popup
//
- (NSString*) fileTypeFromLastRunSavePanel
{
    return mSaveUTI;
}


#pragma mark -


// This method is subclassed so that we can reload the image
// and update the user interface after writing the file.
//
- (BOOL) saveToURL:(NSURL *)absURL ofType:(NSString *)type forSaveOperation:(NSSaveOperationType)saveOp 
         error:(NSError **)outError
{
    BOOL status = [super saveToURL:absURL ofType:type forSaveOperation:saveOp error:outError];

    if (status==YES && (saveOp==NSSaveOperation || saveOp==NSSaveAsOperation))
    {
        NSURL* url = [self fileURL];

        // reload the image (this could faile)
        status = [self readFromURL:url ofType:type error:outError];

        // re-initialize the UI
        [self setupAll];

        // Tell the info panel that the url changed
        [ImageInfoPanel setURL:url];
    }

    return status;
}


// This actually writes the file using CGImageDestination API
//
- (BOOL) writeImageToURL:(NSURL *)absURL ofType:(NSString *)typeName error:(NSError **)outError
{
    BOOL success = YES;
    CGImageDestinationRef dest = nil;

    if (mImage==nil)
        success = NO;
    
    if (success == YES) 
    {
        // Create an image destination writing to `url'
        dest = CGImageDestinationCreateWithURL((__bridge CFURLRef)absURL, (__bridge CFStringRef)typeName, 1, nil);
        if (dest==nil)
            success = NO;
    }
    
    if (success == YES) 
    {
        // Set the image in the image destination to be `image' with
        // optional properties specified in saved properties dict.
        CGImageDestinationAddImage(dest, mImage, (__bridge CFDictionaryRef)[self saveMetaAndOpts]);
        
        success = CGImageDestinationFinalize(dest);
        
        CFRelease(dest);
    }
    
    
    if (success==NO && outError)
        *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnknownError userInfo:nil];
    
    return success; 
}


- (BOOL) writeToURL:(NSURL *)absURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOp 
originalContentsURL:(NSURL *)absOrigURL error:(NSError **)outError
{
    BOOL success = YES;
    
    if ([self switchState])
    {
        return ([mFilteredImage writeImageToURL:absURL ofType:typeName properties:(CFDictionaryRef)[self saveMetaAndOpts] error:outError]);
    }
    else
    {
        return ([self writeImageToURL:absURL ofType:typeName error:outError]);
    }
    
    return success;
}

#pragma mark -


// Set the "shared" NSPrintInfo for image doc.  The shared print info object is the one that is 
// used automatically by -[NSPageLayout runModal] and +[NSPrintOperation printOperationWithView:].
//
- (void) setPrintInfo:(NSPrintInfo*)info
{
    if (mPrintInfo == info)
        return;
    
    mPrintInfo = [info copy];
}


// Get the "shared" NSPrintInfo for image doc.  The shared print info object is the one that is 
// used automatically by -[NSPageLayout runModal] and +[NSPrintOperation printOperationWithView:].
//
- (NSPrintInfo*) printInfo
{
    if (mPrintInfo == nil)
        [self setPrintInfo: [NSPrintInfo sharedPrintInfo]];
    
    return mPrintInfo;
}


// Create a print operation that can be run to print the document's current contents, and return 
// it if successful. If not successful, return nil after setting *outError to an NSError that 
// encapsulates the reason why the print operation could not be created.
//
- (NSPrintOperation*) printOperationWithSettings:(NSDictionary*) printSettings error: (NSError **) outError
{
    NSPrintInfo* printInfo = [self printInfo];

    NSSize paperSize = [printInfo paperSize];
    NSRect printableRect = [printInfo imageablePageBounds];

    // calculate page margins
    float marginL = printableRect.origin.x;
    float marginR = paperSize.width - (printableRect.origin.x + printableRect.size.width);
    float marginB = printableRect.origin.y;
    float marginT = paperSize.height - (printableRect.origin.y + printableRect.size.height);

    // Make sure margins are symetric and positive
    float marginLR = MAX(0,MAX(marginL,marginR));
    float marginTB = MAX(0,MAX(marginT,marginB));
    
    // Tell printInfo what the nice new margins are
    [printInfo setLeftMargin:   marginLR];
    [printInfo setRightMargin:  marginLR];
    [printInfo setTopMargin:    marginTB];
    [printInfo setBottomMargin: marginTB];

    NSRect printViewFrame = {};
    printViewFrame.size.width = paperSize.width - marginLR*2;
    printViewFrame.size.height = paperSize.height - marginTB*2;

    PrintView* printView = [[PrintView alloc] initWithFrame:printViewFrame document:self];

    NSPrintOperation* printOp = [NSPrintOperation printOperationWithView:printView printInfo:printInfo];

    if (outError) // Clear error.
        *outError = NULL;

    return printOp;
}

@end

