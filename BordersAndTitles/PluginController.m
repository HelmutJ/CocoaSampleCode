/*
 
 File:PluginController.m
 
 Abstract: Demonstrate how to create a edit plugin for use in Aperture
 
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
 
 Copyright (C) 2008 Apple Inc. All Rights Reserved.
 
 */

#import "PluginController.h"
#import "BordersTitlesView.h"

@implementation PluginController

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
		_editManager = [[_apiManager apiForProtocol:@protocol(ApertureEditManager)] retain];

		if (_editManager == nil)
		{
			[self release];
			return nil;
		}
				
		// Finish your initialization here
	}
	
	return self;
}

- (void)dealloc
{
	//	Release the top-level objects from the nib.
	[_topLevelNibObjects makeObjectsPerformSelector:@selector(release)];
	[_topLevelNibObjects release];

	[_editManager release];
	[_versionID release];
	[_thumbnail release];
	
	[super dealloc];
}

- (void)awakeFromNib
{
	//	Allow the color panel to have transparency
	[NSColor setIgnoresAlpha:NO];
	
	[_imageView setImage:_thumbnail];	
	[_imageView setFullImageSize:_fullImageSize];
	
	[_borderWidthSlider setMaxValue:(_fullImageSize.width / 8.0)];
	
	[_bordeCcolorWell setColor:[_imageView borderColor]];
	[_borderWidthSlider setFloatValue:[_imageView borderWidth]];
}

#pragma mark -
#pragma mark ApertureEditPlugIn Methods

- (NSWindow *)editWindow
{
	if (_editWindow == nil)
	{
		NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
		NSNib *myNib = [[NSNib alloc] initWithNibNamed:@"PluginUI" bundle:myBundle];
		
		//	Load the nib, if this fails _editWindow will still be nil and Aperture can react appropriately
		if ([myNib instantiateNibWithOwner:self topLevelObjects:&_topLevelNibObjects])
		{
			[_topLevelNibObjects retain];
		}
		[myNib release];
	}
	
	return _editWindow;
}

- (void)beginEditSession
{
	//	Get the ID for the selected version
	_versionID = [[[_editManager selectedVersionIds] objectAtIndex:0] retain];
	
	//	Get the thumbnail from Aperture
	_thumbnail = [[_editManager thumbnailForVersion:_versionID size:kExportThumbnailSizeThumbnail] retain];

	//	We need the size of the full image so that we can properly scale to fit the thumbnail
	NSDictionary *properties = [_editManager propertiesWithoutThumbnailForVersion:_versionID];
	_fullImageSize = [[properties objectForKey:kExportKeyImageSize] sizeValue];
}

//	Our plugin doesn't need to import so these import methods are left empty
- (void)editManager:(id<ApertureEditManager>)editManager didImportImageAtPath:(NSString *)path versionUniqueID:(NSString *)versionUniqueID
{
}

- (void)editManager:(id<ApertureEditManager>)editManager didNotImportImageAtPath:(NSString *)path error:(NSError *)error
{
}

#pragma mark -
#pragma mark Private Methods

- (void)_renderImageAtPath:(NSString*)imagePath
{
	NSImage *image = [[NSImage alloc] initWithContentsOfFile:imagePath];
	
	//	For our drawing purposes the size of the image needs to be in pixels, not points
	[image setSize:_fullImageSize];
	
	//	Draw the border and titles on top of the image
	[image lockFocus];
	[_imageView compositeBordersAndTitlesInRect:(NSRect){NSZeroPoint, _fullImageSize}];
	[image unlockFocus];

	//	Write the image to disk
	[[image TIFFRepresentation] writeToFile:imagePath atomically:YES];
	
	[image release];
}

#pragma mark -
#pragma mark Text Delegate

- (void)textDidChange:(NSNotification *)notification
{
	[self updateTitles:self];
}

#pragma mark -
#pragma mark Action Methods

- (IBAction)updateBorderColor:(id)sender
{
	[_imageView setBorderColor:[sender color]];
}

- (IBAction)updateBorderWidth:(id)sender
{
	[_imageView setBorderWidth:[sender floatValue]];
}

- (IBAction)updateTitles:(id)sender
{
	[_imageView setNeedsDisplay:YES];
}

- (void)add:(id)sender
{
	//	Create a new dictionary with the default properties of a title
	NSAttributedString *newString = [[NSAttributedString alloc] initWithString:@"Hello" attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Helvetica" size:48], NSFontAttributeName, [NSColor whiteColor], NSForegroundColorAttributeName, nil]];
	NSMutableDictionary *newDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:newString, @"attributedString", [NSNumber numberWithFloat:1.0], @"scale", [NSValue valueWithPoint:NSMakePoint(0.5, 0.5)], @"position", nil];

	[_stringsController addObject:newDict];
	[_imageView setNeedsDisplay:YES];
	
	[newString release];
}

- (void)remove:(id)sender
{
	[_stringsController remove:sender];
	[_imageView setNeedsDisplay:YES];
}

- (IBAction)showFontPanel:(id)sender
{
	NSFontPanel *fontPanel = [NSFontPanel sharedFontPanel];
	
	[[_textView window] makeFirstResponder:_textView];
	[_textView selectAll:self];
	[fontPanel setPanelFont:[_textView font] isMultiple:NO];
	[fontPanel orderFront:self];
}

- (IBAction)cancel:(id)sender
{
	[_editManager endEditSession];
}

- (IBAction)done:(id)sender
{
	//	Get an editable version
	[_editManager editableVersionsOfVersions:[NSArray arrayWithObject:_versionID] requestedFormat:kApertureImageFormatTIFF8 stackWithOriginal:YES];
	
	//	Get the path to the editable version
	NSString *editableVersionId = [[_editManager editableVersionIds] objectAtIndex:0];
	NSString *imagePath = [_editManager pathOfEditableFileForVersion:editableVersionId];
	
	//	Render our changes into the editable version
	[self _renderImageAtPath:imagePath];
	
	//	Add the list of titles the user added as custom metadata
	NSArray *titles = [[_stringsController content] valueForKeyPath:@"attributedString.string"];
	if ([titles count] > 0)
	{
		NSDictionary *metadata = [NSDictionary dictionaryWithObject:[titles componentsJoinedByString:@", "] forKey:@"Title from Borders and Titles"];
		[_editManager addCustomMetadata:metadata toVersions:[_editManager editableVersionIds]];
	}
	
	//	Tag the image with a custom keyword
	[_editManager addHierarchicalKeywords:[NSArray arrayWithObject:[NSArray arrayWithObject:@"Edited with Borders and Titles"]] toVersions:[_editManager editableVersionIds]];
	
	//	And we're done
	[_editManager endEditSession];	
}

@end
