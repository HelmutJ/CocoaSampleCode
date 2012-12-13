/*
     File: ExplorerController.m 
 Abstract: Demonstrates how to gather and display various metrics information for installed fonts using NSFont.
  
  Version: 1.1 
  
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

#import "ExplorerController.h"

@implementation ExplorerController

- (void)awakeFromNib
{
	// create empty array to hold device info
	fontArray = [[NSMutableArray alloc] init];

	[self createFontList];
    
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fontSetChanged:)
                                                 name:NSFontSetChangedNotification
                                               object:nil];
}

- (void)dealloc
{
    [fontArray release];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFontSetChangedNotification object:nil];

    [super dealloc];
}
     
- (void)createFontList
{
	NSString *name = NULL;
	NSEnumerator *nameEnum = [[[NSFontManager sharedFontManager] availableFonts] objectEnumerator];
	
	while (name = [nameEnum nextObject])
	{
		NSFont *font;
		NSSize maxAdvancement;
		NSRect boundRect;
		NSMutableDictionary *theDict = NULL;
		NSString *fontDisplayName = NULL;
		
		// create dictionary to hold device info
		theDict = [NSMutableDictionary dictionaryWithCapacity:0];

		font = [NSFont fontWithName:name size:12.0];

		maxAdvancement = [font maximumAdvancement];
		boundRect = [font boundingRectForFont];

		// attempted to retrieve localized name
		fontDisplayName = [font displayName];
		if (fontDisplayName)
			[theDict setObject:fontDisplayName forKey:@"name"];
		else
			[theDict setObject:name forKey:@"name"];

		// glyph count
		[theDict setObject:[NSString stringWithFormat:@"%8d", (int)[font numberOfGlyphs]] forKey:@"#gly"];

		// ascender
		[theDict setObject:[NSString stringWithFormat:@"%8.4f", [font ascender]] forKey:@"ascender"];

		// descender
		[theDict setObject:[NSString stringWithFormat:@"%8.4f", [font descender]] forKey:@"descender"];

		// descender
		[theDict setObject:[NSString stringWithFormat:@"%8.4f", [font leading]] forKey:@"leading"];
        
		// xHeight
		[theDict setObject:[NSString stringWithFormat:@"%8.3f", [font xHeight]] forKey:@"xHeight"];

		// capHeight
		[theDict setObject:[NSString stringWithFormat:@"%8.3f", [font capHeight]] forKey:@"capHeight"];

		// italicAngle
		[theDict setObject:[NSString stringWithFormat:@"%8.3f", [font italicAngle]] forKey:@"italicAngle"];

		// underlinePosition
		[theDict setObject:[NSString stringWithFormat:@"%8.3f", [font underlinePosition]] forKey:@"underlinePosition"];

		// underlineThickness
		[theDict setObject:[NSString stringWithFormat:@"%8.3f", [font underlineThickness]] forKey:@"underlineThickness"];

		// mostCompatibleStringEncoding
		[theDict setObject:[NSString localizedNameOfStringEncoding:[font mostCompatibleStringEncoding]] forKey:@"mostCompatibleStringEncoding"];

		// XBounds
		[theDict setObject:[NSString stringWithFormat:@"%8.3f", NSMinX(boundRect)] forKey:@"XBounds"];

		// YBounds
		[theDict setObject:[NSString stringWithFormat:@"%8.3f", NSMinY(boundRect)] forKey:@"YBounds"];

		// WidthBounds
		[theDict setObject:[NSString stringWithFormat:@"%8.3f", NSWidth(boundRect)] forKey:@"WidthBounds"];

		// HeightBounds
		[theDict setObject:[NSString stringWithFormat:@"%8.3f", NSHeight(boundRect)] forKey:@"HeightBounds"];
		
		// AdvWidth
		[theDict setObject:[NSString stringWithFormat:@"%8.3f", maxAdvancement.width] forKey:@"AdvWidth"];

		// AdvHeight
		[theDict setObject:[NSString stringWithFormat:@"%8.3f", maxAdvancement.height] forKey:@"AdvHeight"];

		// isFixedPitch
		[theDict setObject:[NSString stringWithFormat:@"%s", [font isFixedPitch] ? "YES" : "NO"] forKey:@"isFixedPitch"];

		[fontArray addObject:theDict];
	}

	[myTable reloadData];
}

- (void)fontSetChanged:(NSNotification *)notification
{
	[myTable reloadData];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [fontArray count];
}

- (id)tableView:(NSTableView *)aTableView
      objectValueForTableColumn:(NSTableColumn *)aTableColumn
      row:(int)rowIndex
{
	NSDictionary *deviceDict = NULL;
	
	deviceDict = [fontArray objectAtIndex:rowIndex];
	return [deviceDict objectForKey:[aTableColumn identifier]];
}

@end
