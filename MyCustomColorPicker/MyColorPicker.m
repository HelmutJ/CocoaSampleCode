/*
	MyColorPicker.m
	Copyright © 2006, Apple Computer, Inc., all rights reserved.
*/

/*
 IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc. ("Apple") in
 consideration of your agreement to the following terms, and your use, installation, 
 modification or redistribution of this Apple software constitutes acceptance of these 
 terms.  If you do not agree with these terms, please do not use, install, modify or 
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject to these 
 terms, Apple grants you a personal, non-exclusive license, under Apple’s copyrights in 
 this original Apple software (the "Apple Software"), to use, reproduce, modify and 
 redistribute the Apple Software, with or without modifications, in source and/or binary 
 forms; provided that if you redistribute the Apple Software in its entirety and without 
 modifications, you must retain this notice and the following text and disclaimers in all 
 such redistributions of the Apple Software.  Neither the name, trademarks, service marks 
 or logos of Apple Computer, Inc. may be used to endorse or promote products derived from 
 the Apple Software without specific prior written permission from Apple. Except as expressly
 stated in this notice, no other rights or licenses, express or implied, are granted by Apple
 herein, including but not limited to any patent rights that may be infringed by your 
 derivative works or by other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO WARRANTIES, 
 EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, 
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS 
 USE AND OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL 
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS 
 OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, 
 REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND 
 WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR 
 OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "MyColorPicker.h"

// defined control tags for each color radio button
#define kRedTag		1
#define kGreenTag	2
#define kBlueTag	3
#define kWhiteTag	4
#define kOtherTag	5


@implementation MyColorPicker

- (void)dealloc
{
	[currColor release];

	[super dealloc];
}

// the adopted protocol to return our picker icon which is displayed in the NSColorPanel
- (NSImage*)provideNewButtonImage
{
	NSImage* image;
	
	image = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"icon" ofType:@"tiff"]];
	[image setScalesWhenResized:YES];
	[image setSize:NSMakeSize(32.0,32.0)];
	
	return [image autorelease];
}

// provide a tooltip for our color picker icon in the NSColorPanel
- (NSString *)_buttonToolTip
{
	return @"MyColorPicker";
}

// provide a description string for our color picker
- (NSString *)description
{
	return @"MyColorPicker - A simple RGB color picker";
}

// You build your own custom color picker as a bundle by subclassing NSColorPicker and adopting the NSColorPickingCustom protocol.
// MyColorPicker is launched by adopting the NSColorPickingCustom's protocol -
//
- (NSView*)provideNewView:(BOOL)initialRequest
{
	// the param "initialRequest" is YES on the very first call, at that moment
	// you ask your NSBundle to load its nib.
	//
	if (initialRequest)
		[NSBundle loadNibNamed:@"MyColorPicker" owner:self];
	
	return colorPickerView;
}

// determine which picking color mode we support (used by the NSColorPanel)
- (BOOL)supportsMode:(int)mode
{
	switch (mode)
	{
		case NSColorPanelAllModesMask:	// we support all modes
			return YES;
	}
	return NO;
}

// return our current color picker mode (used by the NSColorPanel)
- (int)currentMode
{
	return NSColorPanelAllModesMask;
}

// map a specific NSColor to our radio button tags
-(int)colorToTag:(NSColor*)color
{
	int tag;
	
	NSString* colorSpaceName;
	colorSpaceName = [color colorSpaceName];
	
	if (color == [NSColor redColor])
		tag = kRedTag;
	else if (color == [NSColor greenColor])
		tag = kGreenTag;
	else if (color == [NSColor blueColor])
		tag = kBlueTag;
	else if (color == [NSColor whiteColor])
		tag = kWhiteTag;
	else if (color == [NSColor selectedControlColor])
		tag = kWhiteTag;
	else if (colorSpaceName == NSCalibratedWhiteColorSpace)
		tag = kWhiteTag;
	else if (colorSpaceName == NSCalibratedRGBColorSpace)
		tag = kOtherTag;
	else
		tag = kOtherTag;

	return tag;
}

// map a specific radio button tag to an NSColor
-(NSColor*)tagToColor:(int)tag
{
	NSColor* c;
	switch (tag)
	{
		case kRedTag:	// red
			c = [NSColor redColor];
			break;
			
		case kGreenTag:	// green
			c = [NSColor greenColor];
			break;
		
		case kBlueTag:	// blue
			c = [NSColor blueColor];
			break;
			
		case kWhiteTag: // white
			c = [NSColor whiteColor];
			break;
			
		case kOtherTag:	// other (default gray)
			c = [NSColor lightGrayColor];
			break;
	}
		
	return c;
}

// called from "colorChanged" action method to update our radio buttons
- (void)setColor:(NSColor *)color
{	
	[currColor release];
	currColor = [color retain];

	[radios selectCellWithTag: [self colorToTag: color]];	// update which radio is selected
}

// the user chose a particular color from one of the radio buttons
- (IBAction)colorChanged:(id)sender
{
	NSColor* c;
	
	NSCell* radioCell = [radios selectedCell];
	if (radioCell != NULL)
		c = [self tagToColor: [radioCell tag]];
	
	[[self colorPanel] setColor:c];
}

// the user clicked the preferences button
- (IBAction)showPrefs:(id)sender
{
	[NSApp beginSheet:colorPickerPrefs modalForWindow:[colorPickerView window] modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

// save our preferences (if any) when the user closes the prefs dialog
- (IBAction)savePrefs:(id)sender
{
	// save any prefs you have right here...
	[NSApp endSheet:colorPickerPrefs];
}

// removes the preferences sheet when finished
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void*)contextInfo
{
	[sheet orderOut:self];
}

@end
