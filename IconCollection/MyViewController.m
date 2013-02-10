/*
     File: MyViewController.m 
 Abstract: Controls the collection view of icons.
  
  Version: 1.2 
  
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
  
 Copyright (C) 2011 Apple Inc. All Rights Reserved. 
  
 */

#import "MyViewController.h"

@implementation IconViewBox

// -------------------------------------------------------------------------------
//	hitTest:aPoint
// -------------------------------------------------------------------------------
- (NSView *)hitTest:(NSPoint)aPoint
{
    // don't allow any mouse clicks for subviews in this NSBox
    return nil;
}

@end


@implementation MyScrollView

// -------------------------------------------------------------------------------
//	awakeFromNib
// -------------------------------------------------------------------------------
- (void)awakeFromNib
{
    // set up the background gradient for this custom scrollView
    backgroundGradient = [[NSGradient alloc] initWithStartingColor:
                          [NSColor colorWithDeviceRed:0.349f green:0.6f blue:0.898f alpha:0.0f]
                                endingColor:[NSColor colorWithDeviceRed:0.349f green:0.6f blue:.898f alpha:0.6f]];
}

// -------------------------------------------------------------------------------
//	drawRect:rect
// -------------------------------------------------------------------------------
- (void)drawRect:(NSRect)rect
{
    // draw our special background as a gradient
    [backgroundGradient drawInRect:[self documentVisibleRect] angle:90.0f];
}

// -------------------------------------------------------------------------------
//	dealloc
// -------------------------------------------------------------------------------
- (void)dealloc
{
    [backgroundGradient release];
    [super dealloc];
}

@end


@implementation MyViewController

@synthesize images, sortingMode, alternateColors;

#define KEY_IMAGE	@"icon"
#define KEY_NAME	@"name"

// -------------------------------------------------------------------------------
//	awakeFromNib
// -------------------------------------------------------------------------------
- (void)awakeFromNib
{
    // save this for later when toggling between alternate colors
    savedAlternateColors = [[collectionView backgroundColors] retain];
    
    [self setSortingMode:0];		// icon collection in ascending sort order
    [self setAlternateColors:NO];	// no alternate background colors (initially use gradient background)
    
    // Determine the content of the collection view by reading in the plist "icons.plist",
    // and add extra "named" template images with the help of NSImage class.
    //
    NSBundle		*bundle = [NSBundle mainBundle];
    NSString		*path = [bundle pathForResource: @"icons" ofType: @"plist"];
    NSArray			*iconEntries = [NSArray arrayWithContentsOfFile: path];
    NSMutableArray	*tempArray = [[NSMutableArray alloc] init];
    
    // read the list of icons from disk in 'icons.plist'
    if (iconEntries != nil)
    {
        NSInteger idx;
        NSInteger count = [iconEntries count];
        for (idx = 0; idx < count; idx++)
        {
            NSDictionary *entry = [iconEntries objectAtIndex:idx];
            if (entry != nil)
            {
                NSString *codeStr = [entry valueForKey: KEY_IMAGE];
                NSString *iconName = [entry valueForKey: KEY_NAME];
                
                OSType code = UTGetOSTypeFromString((CFStringRef)codeStr);
                NSImage *picture = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(code)];
                [tempArray addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       picture, KEY_IMAGE,
                                       iconName, KEY_NAME,
                                       nil]];
            }
        }
    }
    
    // now add named image templates
    [tempArray addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:
                           [NSImage imageNamed:NSImageNameIconViewTemplate], KEY_IMAGE,
                           NSImageNameIconViewTemplate, KEY_NAME,
                           nil]];
    
    [tempArray addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:
                           [NSImage imageNamed:NSImageNameBluetoothTemplate], KEY_IMAGE,
                           NSImageNameBluetoothTemplate, KEY_NAME,
                           nil]];
    
    [tempArray addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:
                           [NSImage imageNamed:NSImageNameIChatTheaterTemplate], KEY_IMAGE,
                           NSImageNameIChatTheaterTemplate, KEY_NAME,
                           nil]];
    
    [tempArray addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:
                           [NSImage imageNamed:NSImageNameSlideshowTemplate], KEY_IMAGE,
                           NSImageNameSlideshowTemplate, KEY_NAME,
                           nil]];
    
    [tempArray addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:
                           [NSImage imageNamed:NSImageNameActionTemplate], KEY_IMAGE,
                           NSImageNameActionTemplate, KEY_NAME,
                           nil]];
    
    [tempArray addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:
                           [NSImage imageNamed:NSImageNameSmartBadgeTemplate], KEY_IMAGE,
                           NSImageNameSmartBadgeTemplate, KEY_NAME,
                           nil]];
    
    // Finder icon templates
    [tempArray addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:
                           [NSImage imageNamed:NSImageNameListViewTemplate], KEY_IMAGE,
                           NSImageNameListViewTemplate, KEY_NAME,
                           nil]];
    [tempArray addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:
                           [NSImage imageNamed:NSImageNameColumnViewTemplate], KEY_IMAGE,
                           NSImageNameColumnViewTemplate, KEY_NAME,
                           nil]];
    [tempArray addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:
                           [NSImage imageNamed:NSImageNameFlowViewTemplate], KEY_IMAGE,
                           NSImageNameFlowViewTemplate, KEY_NAME,
                           nil]];
    [tempArray addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:
                           [NSImage imageNamed:NSImageNamePathTemplate], KEY_IMAGE,
                           NSImageNamePathTemplate, KEY_NAME,
                           nil]];
    
    [tempArray addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:
                           [NSImage imageNamed:NSImageNameInvalidDataFreestandingTemplate], KEY_IMAGE,
                           NSImageNameInvalidDataFreestandingTemplate, KEY_NAME,
                           nil]];
    [tempArray addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:
                           [NSImage imageNamed:NSImageNameLockLockedTemplate], KEY_IMAGE,
                           NSImageNameLockLockedTemplate, KEY_NAME,
                           nil]];
    [tempArray addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:
                           [NSImage imageNamed:NSImageNameLockUnlockedTemplate], KEY_IMAGE,
                           NSImageNameLockUnlockedTemplate, KEY_NAME,
                           nil]];
    
    [self setImages:tempArray];
    [tempArray release];

    [collectionView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:NO];
}


// -------------------------------------------------------------------------------
//	dealloc
// -------------------------------------------------------------------------------
- (void)dealloc
{
    [savedAlternateColors release];
    [super dealloc];
}

// -------------------------------------------------------------------------------
//	setAlternateColors:useAlternateColors
// -------------------------------------------------------------------------------
- (void)setAlternateColors:(BOOL)useAlternateColors
{
    alternateColors = useAlternateColors;
    if (alternateColors)
    {
        [collectionView setBackgroundColors:[NSArray arrayWithObjects:[NSColor gridColor], [NSColor lightGrayColor], nil]];
    }
    else
    {
        [collectionView setBackgroundColors:savedAlternateColors];
    }
}

// -------------------------------------------------------------------------------
//	setSortingMode:newMode
// -------------------------------------------------------------------------------
- (void)setSortingMode:(NSUInteger)newMode
{
    sortingMode = newMode;
    NSSortDescriptor *sort = [[[NSSortDescriptor alloc]
                               initWithKey:KEY_NAME
                               ascending:(sortingMode == 0)
                               selector:@selector(caseInsensitiveCompare:)] autorelease];
    [arrayController setSortDescriptors:[NSArray arrayWithObject:sort]];
}

// -------------------------------------------------------------------------------
//	collectionView:writeItemsAtIndexes:indexes:pasteboard
//
//	Collection view drag and drop
//  User must click and hold the item(s) to perform a drag.
// -------------------------------------------------------------------------------
- (BOOL)collectionView:(NSCollectionView *)cv writeItemsAtIndexes:(NSIndexSet *)indexes toPasteboard:(NSPasteboard *)pasteboard
{
    NSMutableArray *urls = [NSMutableArray array];
    NSURL *temporaryDirectoryURL = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop)
        {
            NSDictionary *dictionary = [[cv content] objectAtIndex:idx];
            NSImage *image = [dictionary objectForKey:KEY_IMAGE];
            NSString *name = [dictionary objectForKey:KEY_NAME];
            if (image && name)
            {
                NSURL *url = [temporaryDirectoryURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.tiff", name]];
                [urls addObject:url];
                [[image TIFFRepresentation] writeToURL:url atomically:YES];
            }
        }];
    if ([urls count] > 0)
    {
        [pasteboard clearContents];
        return [pasteboard writeObjects:urls];
    }
    return NO;
}

@end
