/*
     File: ControllerBrowsing.m 
 Abstract: An extension or category of the Controller class responsible for the IKImageBrowserView. 
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

#import "Controller.h"
#import "ControllerBrowsing.h"

NSString *kDesktopPicturesTitle = @"Desktop Pictures";

// our datasource object which represents one item in the image browser
@interface MyImageObject : NSObject
{
    NSURL *url;
}

@property (retain) NSURL *url;

@end

@implementation MyImageObject

@synthesize url;

- (void)dealloc
{
	[url release];
	[super dealloc];
}


#pragma mark - Item data source protocol

- (NSString *)imageRepresentationType
{
	return IKImageBrowserNSURLRepresentationType;;
}

- (id)imageRepresentation
{
	return self.url;
}

- (NSString *)imageUID
{
	return [NSString stringWithFormat:@"%p", self];
}

- (id)imageTitle
{
	return [url lastPathComponent];
}

@end


@implementation Controller(Browsing)

#pragma mark - Import images from file system

// -------------------------------------------------------------------------------
//	isImageFile:url
//
//	Uses LaunchServices and UTIs to detect if a given NSURL is an image file.
// -------------------------------------------------------------------------------
- (BOOL)isImageFile:(NSURL *)url
{
    BOOL isImageFile = NO;
    
    NSString *utiValue;
    [url getResourceValue:&utiValue forKey:NSURLTypeIdentifierKey error:nil];
    if (utiValue)
    {
        isImageFile = UTTypeConformsTo((CFStringRef)utiValue, kUTTypeImage);
    }
    return isImageFile;
}

// -------------------------------------------------------------------------------
//	addImageWithURL:imageURL
//
//	Code that parses a repository and adds all entries to our data source array.
// -------------------------------------------------------------------------------
- (void)addImageWithURL:(NSURL *)imageURL
{
    NSNumber *hiddenFlag = nil;
    if ([imageURL getResourceValue:&hiddenFlag forKey:NSURLIsHiddenKey error:nil])
    {
        NSNumber *isDirectoryFlag = nil;
        if ([imageURL getResourceValue:&isDirectoryFlag forKey:NSURLIsDirectoryKey error:nil])
        {
            NSNumber *isPackageFlag = nil;
            if ([imageURL getResourceValue:&isPackageFlag forKey:NSURLIsPackageKey error:nil])
            {
                // only "add visible" file system objects, folders and images (no packages)
                if (![hiddenFlag boolValue] && ![isPackageFlag boolValue] &&
                    ([isDirectoryFlag boolValue] || [self isImageFile:imageURL]))
                {
                    MyImageObject *item = [[MyImageObject alloc] init];
                    item.url = imageURL;
                    [images addObject:item];
                    
                    [item release];
                }
            }
        }
    }
}

// -------------------------------------------------------------------------------
//	addImagesFromDirectory:directoryURL
// -------------------------------------------------------------------------------
- (void)addImagesFromDirectory:(NSURL *)directoryURL
{
	NSArray *content = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:directoryURL
                                                     includingPropertiesForKeys:nil
                                                                        options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                          error:nil];
    for (NSURL *imageURL in content)
    {
        [self addImageWithURL:imageURL];
    }

	[imageBrowser reloadData];
}


#pragma mark - Setup Browsing

// -------------------------------------------------------------------------------
//	setupBrowsing
// -------------------------------------------------------------------------------
- (void)setupBrowsing
{
	// allocate our datasource array: will contain instances of MyImageObject
	images = [[NSMutableArray alloc] init];
    
	// as default, add the contents of /Library/Desktop Pictures/ to the image browser
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSLocalDomainMask, YES);
	NSString *libraryDirectory = [paths objectAtIndex:0];
	NSString *finalPath = [libraryDirectory stringByAppendingPathComponent:kDesktopPicturesTitle];
	
    // make sure "Desktop Pictures" is actually there
    if ([[NSFileManager defaultManager] fileExistsAtPath:finalPath])
    {
        NSURL *desktopPicsURL = [NSURL fileURLWithPath:finalPath];
        
        // proceed to add all the images we find to the image browser
        [self addImagesFromDirectory:desktopPicsURL];
        
        // set the same location to our path control
        [pathControl setURL:desktopPicsURL];
    }
}

// -------------------------------------------------------------------------------
//  changeLocationToNewLocation:newLocationURL
//
//  For updating the images based on the new location
// -------------------------------------------------------------------------------
- (void)changeLocationToNewLocation:(NSURL *)newLocationURL
{
	[images removeAllObjects];                      // remove the old content since we are switching directories
	[self addImagesFromDirectory:newLocationURL];	// add the new content
	[imageBrowser reloadData];                      // make sure the browser reloads its content
    
}

// -------------------------------------------------------------------------------
//  updatePathControlWithNewLocation:newLocationURL
//
//  For updating the path control based on the new location.
// -------------------------------------------------------------------------------
- (void)updatePathControlWithNewLocation:(NSURL *)newLocationURL
{
    [pathControl setURL:newLocationURL];
}

// -------------------------------------------------------------------------------
//	changeLocationAction:sender:
// -------------------------------------------------------------------------------
- (IBAction)changeLocationAction:(id)sender
{
    NSPathControl *pathCntl = (NSPathControl *)sender;
    
    // find the path component selected
    NSPathComponentCell *component = [pathCntl clickedPathComponentCell];
    
    NSURL *url = [component URL];
    [self changeLocationToNewLocation:url];
    [self updatePathControlWithNewLocation:url];
}

// -------------------------------------------------------------------------------
//	willDisplayOpenPanel:openPanel:
//
//	Delegate method to NSPathControl to determine how the NSOpenPanel will look/behave.
// -------------------------------------------------------------------------------
- (void)pathControl:(NSPathControl *)pathControl willDisplayOpenPanel:(NSOpenPanel *)openPanel
{	
	// change the wind title and choose buttons title
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanChooseFiles:NO];
	[openPanel setResolvesAliases:YES];
	[openPanel setTitle:@"Choose a directory of images"];
	[openPanel setPrompt:@"Choose"];
}

// -------------------------------------------------------------------------------
//	menuItemAction:sender:
//
//  This is the action method from our custom menu item: "Home" or "Desktop Pictures". 
// -------------------------------------------------------------------------------
- (void)menuItemAction:(id)sender
{
	// set the path control to home directory
	[pathControl setURL:[sender representedObject]];	// goto the URL set on this menu item
	
	[images removeAllObjects];		// remove the old content since we are switching directories
	[self addImagesFromDirectory:[sender representedObject]];	// add the new content
}

// -------------------------------------------------------------------------------
//	willPopUpMenu:menu:
//
//	Before the menu is displayed, add the "Home" directory.
// -------------------------------------------------------------------------------
- (void)pathControl:(NSPathControl *)pathControl willPopUpMenu:(NSMenu *)menu
{
	// add the "Home" menu item
	NSMenuItem *newItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Home"
                                                                               action:@selector(menuItemAction:)
                                                                        keyEquivalent:@""];
	[newItem setTarget:self];
	NSString *homeDir = NSHomeDirectory();
    [newItem setRepresentedObject:[NSURL fileURLWithPath:homeDir]];	// use the URL upon menu item selection in "menuItemAction"
	NSImage *menuItemIcon = [[NSWorkspace sharedWorkspace] iconForFile:NSHomeDirectory()];
	[menuItemIcon setSize:NSMakeSize(16, 16)];
	[newItem setImage:menuItemIcon];
	[menu addItem:[NSMenuItem separatorItem]];
	[menu addItem:newItem];
	[newItem release];
	
	// add the Desktop Pictures menu item
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSLocalDomainMask, YES);
	NSString *libraryDirectory = [paths objectAtIndex:0];
	NSString *finalPath = [libraryDirectory stringByAppendingPathComponent:kDesktopPicturesTitle];
	newItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:kDesktopPicturesTitle
                                                                   action:@selector(menuItemAction:)
                                                            keyEquivalent:@""];
	[newItem setTarget:self];
	[newItem setRepresentedObject:[NSURL fileURLWithPath:finalPath]];	// use the URL upon menu item selection in "menuItemAction"
	menuItemIcon = [[NSWorkspace sharedWorkspace] iconForFile:finalPath];
	[menuItemIcon setSize:NSMakeSize(16, 16)];
	[newItem setImage:menuItemIcon];
	[menu addItem:newItem];
	[newItem release];
}


#pragma mark - Actions

// -------------------------------------------------------------------------------
//	zoomSliderDidChange:sender:
// -------------------------------------------------------------------------------
- (IBAction)zoomSliderDidChange:(id)sender
{
	[imageBrowser setZoomValue:[sender floatValue]];
}


#pragma mark - IKImageBrowserDataSource

// -------------------------------------------------------------------------------
//	numberOfItemsInImageBrowser:view:
//
// Implement image-browser's datasource protocol.
// Our datasource representation is a simple mutable array.
// -------------------------------------------------------------------------------
- (NSUInteger)numberOfItemsInImageBrowser:(IKImageBrowserView *)view
{
	return [images count];
}

// -------------------------------------------------------------------------------
//	imageBrowser:itemAtIndex:index
// -------------------------------------------------------------------------------
- (id)imageBrowser:(IKImageBrowserView *)view itemAtIndex:(NSUInteger)index
{
	return [images objectAtIndex:index];
}


#pragma mark - optional datasource methods

// -------------------------------------------------------------------------------
//	imageBrowser:removeItemsAtIndexes:indexes
//
//	User wants to remove one or more items within the image browser.
// -------------------------------------------------------------------------------
- (void)imageBrowser:(IKImageBrowserView *)aBrowser removeItemsAtIndexes:(NSIndexSet *)indexes
{
	[images removeObjectsAtIndexes:indexes];
	[imageBrowser reloadData];
}

// -------------------------------------------------------------------------------
//	imageBrowser:moveItemsAtIndexes:indexes:toIndex
//
//	User wants to move an image within the image browser.
// -------------------------------------------------------------------------------
- (BOOL)imageBrowser:(IKImageBrowserView *)aBrowser moveItemsAtIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)destinationIndex
{
	NSArray *tempArray = [images objectsAtIndexes:indexes];
	[images removeObjectsAtIndexes:indexes];
	
	destinationIndex -= [indexes countOfIndexesInRange:NSMakeRange(0, destinationIndex)];
	[images insertObjects:tempArray
                atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(destinationIndex, [tempArray count])]];
	[imageBrowser reloadData];
	
	return YES;
}


#pragma mark - IKImageBrowserDelegate

// -------------------------------------------------------------------------------
//	imageBrowserSelectionDidChange:aBrowser
//
//	User chose a new image from the image browser.
// -------------------------------------------------------------------------------
- (void)imageBrowserSelectionDidChange:(IKImageBrowserView *)aBrowser
{
	NSIndexSet *selectionIndexes = [aBrowser selectionIndexes];	
	
	if ([selectionIndexes count] > 0)
	{
        NSDictionary *screenOptions = [[NSWorkspace sharedWorkspace] desktopImageOptionsForScreen:curScreen];
        
        MyImageObject *anItem = [images objectAtIndex:[selectionIndexes firstIndex]];
		NSURL *url = [anItem imageRepresentation];
        
        NSNumber *isDirectoryFlag = nil;
        if ([url getResourceValue:&isDirectoryFlag forKey:NSURLIsDirectoryKey error:nil] && ![isDirectoryFlag boolValue])
        {
            NSError *error = nil;
            [[NSWorkspace sharedWorkspace] setDesktopImageURL:url
                                                    forScreen:curScreen
                                                      options:screenOptions
                                                        error:&error];
            if (error)
            {
                [NSApp presentError:error];
            }
        }
	}
}

// -------------------------------------------------------------------------------
//  imageBrowser:cellWasDoubleClickedAtIndex:index
// -------------------------------------------------------------------------------
- (void)imageBrowser:(IKImageBrowserView *)aBrowser cellWasDoubleClickedAtIndex:(NSUInteger)index
{
    // get the image object
    MyImageObject *imageObject = (MyImageObject *)[images objectAtIndex:index];
    if (imageObject)
    {
        // get the path from the image object that was double-clicked
        NSURL *url = [imageObject url];
        
        // make sure it is a directory we are double-clicking (double-click works on directories only)
        NSNumber *isDirectoryFlag = nil;
        if ([url getResourceValue:&isDirectoryFlag forKey:NSURLIsDirectoryKey error:nil] && [isDirectoryFlag boolValue])
        {
            // change the location to the new path and update the displayed images
            [self changeLocationToNewLocation:url];
            
            // update the path control to reflect the new path
            [self updatePathControlWithNewLocation:url];
        }
    }
}

@end
