/*
 
 File: Resizer.m
 
 Abstract: <Description, Points of interest, Algorithm approach>
 
 Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by 
 Apple Inc. ("Apple") in consideration of your agreement to the
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
 Neither the name, trademarks, service marks or logos of Apple Inc. 
 may be used to endorse or promote products derived from the Apple
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
 
 Copyright (C) 2007 Apple Inc. All Rights Reserved.
 */

#import "Resizer.h"


@implementation Resizer

//---------------------------------------------------------
// initWithAPIManager:
//
// This method is called when a plug-in is first loaded, and
// is a good point to conduct any checks for anti-piracy or
// system compatibility. This is also your only chance to
// obtain a reference to Aperture's export manager. If you
// do not obtain a valid reference, you should return nil.
// Returning nil means that a plug-in chooses not to be accessible.
//---------------------------------------------------------

 - (id)initWithAPIManager:(id<PROAPIAccessing>)apiManager
{
	if (self = [super init])
	{
		_apiManager	= apiManager;
		_exportManager = [[_apiManager apiForProtocol:@protocol(ApertureExportManager)] retain];
		if (!_exportManager)
			return nil;
		
		_progressLock = [[NSLock alloc] init];
	}
	
	return self;
}

- (void)dealloc
{
	// Release the top-level objects from the nib.
	[_topLevelNibObjects makeObjectsPerformSelector:@selector(release)];
	[_topLevelNibObjects release];
	
	[_progressLock release];
	[_exportManager release];
	
	[super dealloc];
}


#pragma mark -
// UI Methods
#pragma mark UI Methods

- (NSView *)settingsView
{
	if (nil == settingsView)
	{
		// Load the nib using NSNib, and retain the array of top-level objects so we can release
		// them properly in dealloc
		NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
		NSNib *myNib = [[NSNib alloc] initWithNibNamed:@"Resizer" bundle:myBundle];
		if ([myNib instantiateNibWithOwner:self topLevelObjects:&_topLevelNibObjects])
		{
			[_topLevelNibObjects retain];
		}
		[myNib release];
	}
	
	return settingsView;
}

- (NSView *)firstView
{
	return firstView;
}

- (NSView *)lastView
{
	return lastView;
}

- (void)willBeActivated
{
	// Nothing needed here
}

- (void)willBeDeactivated
{
	// Nothing needed here
}

#pragma mark
// Aperture UI Controls
#pragma mark Aperture UI Controls

- (BOOL)allowsOnlyPlugInPresets
{
	return YES;	
}

- (BOOL)allowsMasterExport
{
	return NO;	
}

- (BOOL)allowsVersionExport
{
	return YES;	
}

- (BOOL)wantsFileNamingControls
{
	return YES;	
}

- (void)exportManagerExportTypeDidChange
{
	// Resizer does not allow masters so it should never get this call.
}


#pragma mark -
// Save Path Methods
#pragma mark Save/Path Methods

- (BOOL)wantsDestinationPathPrompt
{
	return YES;
}

- (NSString *)destinationPath
{
	return nil;
}

- (NSString *)defaultDirectory
{
	// Return the user's home directory. As an improvement, Resizer could save the last path used to prefs and return it here. 
	return [@"~/" stringByExpandingTildeInPath];
}


#pragma mark -
// Export Process Methods
#pragma mark Export Process Methods

- (void)exportManagerShouldBeginExport
{
	// Resizer doesn't need to perform any initialization here.
	// As an improvement, it could check to make sure the user entered at least one size
	[_exportManager shouldBeginExport];
}

- (void)exportManagerWillBeginExportToPath:(NSString *)path
{
	// Save our export base path to use later.
	_exportPath = [path copy];
	
	// Update the progress structure to say Beginning Export... with an indeterminate progress bar.
	[self lockProgress];
	exportProgress.totalValue = [_exportManager imageCount];
	exportProgress.indeterminateProgress = YES;
	exportProgress.message = [@"Beginning Export..." retain];
	[self unlockProgress];
}

- (BOOL)exportManagerShouldExportImageAtIndex:(unsigned)index
{
	// Resizer always exports all of the selected images.
	return YES;
}

- (void)exportManagerWillExportImageAtIndex:(unsigned)index
{
	// Nothing to confirm here.
}

- (BOOL)exportManagerShouldWriteImageData:(NSData *)imageData toRelativePath:(NSString *)path forImageAtIndex:(unsigned)index
{
	// Create a base URL
	CFURLRef baseURLRef = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)_exportPath, kCFURLPOSIXPathStyle, true);
	
	// Create our full size CGImage from the provided data
	CGImageSourceRef imageSourceRef = CGImageSourceCreateWithData((CFDataRef)imageData, NULL);
	CGImageRef fullSizeImageRef = CGImageSourceCreateImageAtIndex(imageSourceRef, 0, NULL);
	
	// Loop through each entry in the table and create a thumbnail of the specified size
	NSArray *sizesArray = [_arrayController arrangedObjects];
	int i, count = [sizesArray count];
	for (i = 0; i < count; i++)
	{
		// Create the thumbnail options specifying the thumb size
		NSNumber *thumbnailSizeFromTable = [[sizesArray objectAtIndex:i] valueForKey:@"thumbnailSize"];
		if (thumbnailSizeFromTable == nil)
			continue;
		int size = [thumbnailSizeFromTable intValue];

		// Create the options dictionary that tells CG to create a thumbnail of a specified size.
		CFDictionaryRef options = NULL;
		CFStringRef keys[2];
		CFTypeRef values[2];
		CFNumberRef thumbSizeRef = CFNumberCreate(NULL, kCFNumberIntType, &size);
		keys[0] = kCGImageSourceCreateThumbnailFromImageIfAbsent;
		values[0] = (CFTypeRef)kCFBooleanTrue;
		keys[1] = kCGImageSourceThumbnailMaxPixelSize;
		values[1] = (CFTypeRef)thumbSizeRef;
		options = CFDictionaryCreate(NULL, (const void **)keys, (const void **)values, 2, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		CFRelease(thumbSizeRef);
		
		// Create the thumbnail image
		CGImageRef thumbnailImageRef = CGImageSourceCreateThumbnailAtIndex(imageSourceRef, 0, (CFDictionaryRef)options);
		
		// Create the new filename
		NSString *thumbnailSuffix = [[sizesArray objectAtIndex:i] valueForKey:@"thumbnailSuffix"];
		NSMutableString *thumbnailPath = [path mutableCopy];
		NSRange range = [thumbnailPath rangeOfString:@".jpg"];
		[thumbnailPath insertString:thumbnailSuffix atIndex:range.location];
		
		// Create a CFURLRef to the new file
		CFURLRef thumbnailFileURLRef = CFURLCreateWithFileSystemPathRelativeToBase(kCFAllocatorDefault, (CFStringRef)thumbnailPath, kCFURLPOSIXPathStyle, false, baseURLRef);
		[thumbnailPath release];

		// Write the image
		CGImageDestinationRef thumbnailDestinationRef = CGImageDestinationCreateWithURL(thumbnailFileURLRef, kUTTypeJPEG, 1, NULL);
		CGImageDestinationAddImage(thumbnailDestinationRef, thumbnailImageRef, NULL);
		CGImageDestinationFinalize(thumbnailDestinationRef);
		
		CFRelease(thumbnailFileURLRef);
		CFRelease(thumbnailDestinationRef);
	}
	
	CFRelease(baseURLRef);
	CFRelease(imageSourceRef);
	CFRelease(fullSizeImageRef);
	
	// Update the progress
	[self lockProgress];
	[exportProgress.message release];
	exportProgress.message = [@"Exporting..." retain];
	exportProgress.currentValue = index + 1;
	[self unlockProgress];
	
	// If the user checked the "Include Full Size" checkbox, tell Aperture to write the file out.
	if ([_includeFullCheckbox state] == NSOnState)
		return YES;	
	else
		return NO;
}

- (void)exportManagerDidWriteImageDataToRelativePath:(NSString *)relativePath forImageAtIndex:(unsigned)index
{
	
}

- (void)exportManagerDidFinishExport
{
	// Nothing to cleanup or finish here, so tell Aperture that we're done.
	[_exportManager shouldFinishExport];
}

- (void)exportManagerShouldCancelExport
{
	[_exportManager shouldCancelExport];
}


#pragma mark -
	// Progress Methods
#pragma mark Progress Methods

- (ApertureExportProgress *)progress
{
	return &exportProgress;
}

- (void)lockProgress
{
	
	if (!_progressLock)
		_progressLock = [[NSLock alloc] init];
		
	[_progressLock lock];
}

- (void)unlockProgress
{
	[_progressLock unlock];
}

@end
