/*
     File: ImageBrowserController.m 
 Abstract: IKImageBrowserView is a view that can display and browse a large amount of images and movies.
 This sample code demonstrate how to use it in a Cocoa Application.
  
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

#import "ImageBrowserController.h"

// openFiles is a simple C function that opens an NSOpenPanel and return an array of URLs
static NSArray *openFiles()
{ 
    NSOpenPanel *panel;

    panel = [NSOpenPanel openPanel];        
    [panel setFloatingPanel:YES];
    [panel setCanChooseDirectories:YES];
    [panel setCanChooseFiles:YES];
	NSInteger i = [panel runModal];
	if (i == NSOKButton)
    {
		return [panel URLs];
    }
    
    return nil;
}

/* Our datasource object */
@interface myImageObject : NSObject
{
    NSString *_path; 
}
@end

@implementation myImageObject

- (void)dealloc
{
    [_path release];
    [super dealloc];
}

/* our datasource object is just a filepath representation */
- (void)setPath:(NSString *)path
{
    if(_path != path)
    {
        [_path release];
        _path = [path retain];
    }
}


/* required methods of the IKImageBrowserItem protocol */
#pragma mark -
#pragma mark item data source protocol

/* let the image browser knows we use a path representation */
- (NSString *)imageRepresentationType
{
	return IKImageBrowserPathRepresentationType;
}

/* give our representation to the image browser */
- (id)imageRepresentation
{
	return _path;
}

/* use the absolute filepath as identifier */
- (NSString *)imageUID
{
    return _path;
}

@end


/* the controller */
@implementation ImageBrowserController

- (void)dealloc
{
    [_images release];
    [_importedImages release];
    [super dealloc];
}

- (void)awakeFromNib
{
    // create two arrays : the first one is our datasource representation,
    // the second one are temporary imported images (for thread safeness) 

    _images = [[NSMutableArray alloc] init];
    _importedImages = [[NSMutableArray alloc] init];
    
    //allow reordering, animations et set draggind destination delegate
    [_imageBrowser setAllowsReordering:YES];
    [_imageBrowser setAnimates:YES];
    [_imageBrowser setDraggingDestinationDelegate:self];
}

/* entry point for reloading image-browser's data and setNeedsDisplay */
- (void)updateDatasource
{
    //-- update our datasource, add recently imported items
    [_images addObjectsFromArray:_importedImages];
	
	//-- empty our temporary array
    [_importedImages removeAllObjects];
    
    //-- reload the image browser and set needs display
    [_imageBrowser reloadData];
}


#pragma mark -
#pragma mark import images from file system

/* Code that parse a repository and add all items in an independant array,
   When done, call updateDatasource, add these items to our datasource array
   This code is performed in an independant thread.
*/
- (void)addAnImageWithPath:(NSString *)path
{   
    myImageObject *p;

	/* add a path to our temporary array */
    p = [[myImageObject alloc] init];
    [p setPath:path];
    [_importedImages addObject:p];
    [p release];
}

- (void)addImagesWithPath:(NSString *)path recursive:(BOOL)recursive
{
    NSInteger i, n;
    BOOL dir;

    [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&dir];
    
    if (dir)
    {
        NSArray *content = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
        
        n = [content count];

		// parse the directory content
        for (i=0; i<n; i++)
        {
            if (recursive)
                [self addImagesWithPath:[path stringByAppendingPathComponent:[content objectAtIndex:i]] recursive:YES];
            else
                [self addAnImageWithPath:[path stringByAppendingPathComponent:[content objectAtIndex:i]]];
        }
    }
    else
    {
        [self addAnImageWithPath:path];
    }
}

/* performed in an independant thread, parse all paths in "paths" and add these paths in our temporary array */
- (void)addImagesWithPaths:(NSArray *)urls
{   
    NSInteger i, n;
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [urls retain];

    n = [urls count];
    for ( i= 0; i < n; i++)
    {
        NSURL *url = [urls objectAtIndex:i];
        [self addImagesWithPath:[url path] recursive:NO];
    }

	/* update the datasource in the main thread */
    [self performSelectorOnMainThread:@selector(updateDatasource) withObject:nil waitUntilDone:YES];

    [urls release];
    [pool release];
}


#pragma mark -
#pragma mark actions

/* "add" button was clicked */
- (IBAction)addImageButtonClicked:(id)sender
{   
    NSArray *urls = openFiles();
    
    if (!urls)
    { 
        NSLog(@"No files selected, return..."); 
        return; 
    }
	
	/* launch import in an independent thread */
    [NSThread detachNewThreadSelector:@selector(addImagesWithPaths:) toTarget:self withObject:urls];
}

/* action called when the zoom slider did change */
- (IBAction)zoomSliderDidChange:(id)sender
{
	/* update the zoom value to scale images */
    [_imageBrowser setZoomValue:[sender floatValue]];
	
	/* redisplay */
    [_imageBrowser setNeedsDisplay:YES];
}


#pragma mark -
#pragma mark IKImageBrowserDataSource

/* implement image-browser's datasource protocol 
   Our datasource representation is a simple mutable array
*/

- (NSUInteger)numberOfItemsInImageBrowser:(IKImageBrowserView *)view
{
	/* item count to display is our datasource item count */
    return [_images count];
}

- (id)imageBrowser:(IKImageBrowserView *)view itemAtIndex:(NSUInteger)index
{
    return [_images objectAtIndex:index];
}


/* implement some optional methods of the image-browser's datasource protocol to be able to remove and reoder items */

/*	remove
	The user wants to delete images, so remove these entries from our datasource.	
*/
- (void)imageBrowser:(IKImageBrowserView *)view removeItemsAtIndexes:(NSIndexSet *)indexes
{
	[_images removeObjectsAtIndexes:indexes];
}

// reordering:
// The user wants to reorder images, update our datasource and the browser will reflect our changes
- (BOOL)imageBrowser:(IKImageBrowserView *)view moveItemsAtIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)destinationIndex
{
      NSUInteger index;
      NSMutableArray *temporaryArray;
	  
      temporaryArray = [[[NSMutableArray alloc] init] autorelease];
      
	  /* first remove items from the datasource and keep them in a temporary array */
      for (index = [indexes lastIndex]; index != NSNotFound; index = [indexes indexLessThanIndex:index])
      {
          if (index < destinationIndex)
              destinationIndex --;
          
          id obj = [_images objectAtIndex:index];
          [temporaryArray addObject:obj];
          [_images removeObjectAtIndex:index];
      }
  
	  /* then insert removed items at the good location */
      NSInteger n = [temporaryArray count];
      for (index=0; index < n; index++)
      {
          [_images insertObject:[temporaryArray objectAtIndex:index] atIndex:destinationIndex];
      }
	
      return YES;
}


#pragma mark -
#pragma mark drag n drop 

/* Drag'n drop support, accept any kind of drop */
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    return NSDragOperationCopy;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
    return NSDragOperationCopy;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSData *data = nil;
    NSString *errorDescription;
	
    NSPasteboard *pasteboard = [sender draggingPasteboard];

	/* look for paths in pasteboard */
    if ([[pasteboard types] containsObject:NSFilenamesPboardType]) 
        data = [pasteboard dataForType:NSFilenamesPboardType];

    if (data)
    {
		/* retrieves paths */
        NSArray *filenames = [NSPropertyListSerialization propertyListFromData:data 
                                             mutabilityOption:kCFPropertyListImmutable 
                                             format:nil 
                                             errorDescription:&errorDescription];
    
    
		/* add paths to our datasource */
        NSInteger i;
        NSInteger n = [filenames count];
        for (i=0; i<n; i++){
            [self addAnImageWithPath:[filenames objectAtIndex:i]];
        }
		
		/* make the image browser reload our datasource */
        [self updateDatasource];
    }

	/* we accepted the drag operation */
	return YES;
}

@end
