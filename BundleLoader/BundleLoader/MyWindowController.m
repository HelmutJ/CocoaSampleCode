/*
     File: MyWindowController.m 
 Abstract: Sample's main NSWindowController. 
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
  
 Copyright (C) 2012 Apple Inc. All Rights Reserved. 
  
 */

#import "MyWindowController.h"
#import "MyBundle.h"

@implementation MyWindowController

// all of our target built bundles for this sample will start with:
NSString* const kPrefixBundleIDStr = @"com.yourcompany.bundleexample";
NSString* const kSearchStr = @"Searching for bundles...";
	

// -------------------------------------------------------------------------------
//	handleActivate:
// -------------------------------------------------------------------------------
- (void)handleActivate:(NSNotification *)notification
{
	NSWindowController *controller = [[notification object] windowController];
	if ([controller isKindOfClass:[MyWindowController class]]) 
	{
		// our main window is now active, check if any bundle windows are still open
		BOOL hasOpenBundle = NO;
		
		// one of our bundle windows is closing, update the our 'hasOpenWindows' flag
		for (NSDictionary *bundleDict in [arrayController arrangedObjects])
        {
			MyBundle *curBundle = [bundleDict objectForKey:@"bundleInstance"];
			if ([curBundle isOpen])
			{
				hasOpenBundle = YES;
				break;
			}
		}
		
		if (!hasOpenBundle)
		{
			// no more bundle windows are open
			[self willChangeValueForKey:@"hasOpenWindows"];
			hasOpenWindows = NO;
			[self didChangeValueForKey:@"hasOpenWindows"];
		}
	}
}

// -------------------------------------------------------------------------------
//	handleClose:notification
// -------------------------------------------------------------------------------
- (void)handleClose:(NSNotification *)notification
{
	NSWindowController *controller = [[notification object] windowController];
	if ([controller isKindOfClass:[MyWindowController class]]) 
	{
		// we are closing our main application window, so close all the bundle windows		
		for (NSDictionary *bundleDict in [arrayController arrangedObjects])
        {
			MyBundle *curBundle = [bundleDict objectForKey:@"bundleInstance"];
			[curBundle close];
		}
	}
	else
	{
		// one of our bundle windows is closing
		//...
	}
}

// -------------------------------------------------------------------------------
//	init
// -------------------------------------------------------------------------------
- (id)init
{
	self = [super init];
	if (self)
	{
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleClose:)
                                                     name:NSWindowWillCloseNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleActivate:)
                                                     name:NSWindowDidBecomeKeyNotification
                                                object:nil];
    }
	return self;
}

// -------------------------------------------------------------------------------
//	dealloc
// -------------------------------------------------------------------------------
- (void)dealloc
{
	[super dealloc];
}

// -------------------------------------------------------------------------------
//	searchDone:bundleInstanceList
// -------------------------------------------------------------------------------
- (void)searchDone:(NSMutableArray *)bundleInstanceList
{
	[searchString setStringValue:@""];
	[searchProgress setHidden:YES];
	[searchProgress stopAnimation:self];
	
	for (MyBundle *curBundle in bundleInstanceList)
    {
		// add all the discovered bundles to our array controller/table view
		NSMutableDictionary *bundleEntryDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
													[curBundle bundleTitle], @"name",
													[curBundle bundleDescription], @"description",
													[curBundle bundleIcon], @"icon",
													curBundle, @"bundleInstance",
													nil];
		[arrayController addObject:bundleEntryDict];
	}
}

// -------------------------------------------------------------------------------
//	startSearch:inObject
// -------------------------------------------------------------------------------
- (void)startSearch:(id)inObject
{
	NSMutableArray *bundleInstanceList = [[NSMutableArray alloc] init];
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSMutableArray *bundlePaths = [NSMutableArray array];
	
	// our built bundles are found inside the app's "PlugIns" folder -
	NSMutableArray *bundleSearchPaths = [NSMutableArray array];
	NSString *folderPath = [[NSBundle mainBundle] builtInPlugInsPath];
	[bundleSearchPaths addObject: folderPath];
	
	// NOTE: if you wish to search other locations for bundles
	//			(i.e. $(HOME)/Library/Application Support/BundleLoader, you can use the following code:
#if 0
	NSArray *librarySearchPaths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSEnumerator *searchPathEnum = [librarySearchPaths objectEnumerator];
    while (currPath = [searchPathEnum nextObject])
    {
	   [bundleSearchPaths addObject: currPath];
    }
#endif	
	
    for (NSString *currPath in bundleSearchPaths)
    {
        NSDirectoryEnumerator *bundleEnum;
        NSString *currBundlePath;
        bundleEnum = [[NSFileManager defaultManager] enumeratorAtPath:currPath];
        if (bundleEnum)
        {
            while ((currBundlePath = [bundleEnum nextObject]))
            {
                if ([[currBundlePath pathExtension] isEqualToString:@"bundle"])
                {
					// we found a bundle, add it to the list
					[bundlePaths addObject:[currPath stringByAppendingPathComponent:currBundlePath]];
                }
            }
        }
    }

	// now that we have all bundle paths, start finding the ones we really want to load -
	NSRange searchRange = NSMakeRange(0, [kPrefixBundleIDStr length]);
	
	for (NSString *currPath in bundlePaths)
    {
        NSBundle *currBundle = [NSBundle bundleWithPath:currPath];
        if (currBundle)
        {
			NSString *bundleIDStr = [currBundle bundleIdentifier];
            
            // check the bundle ID to see if it starts with our know prefix string (kPrefixBundleIDStr)
			// we want to only load the bundles we care about:
			//
			if ([bundleIDStr compare:kPrefixBundleIDStr options:NSLiteralSearch range:searchRange] == NSOrderedSame)
			{
				// load and startup our bundle
				//
				// note: principleClass method actually loads the bundle for us,
				// or we can call [currBundle load] directly.
				//
				Class currPrincipalClass = [currBundle principalClass];
				if (currPrincipalClass)
				{
					id currInstance = [[currPrincipalClass alloc] init];
					if (currInstance)
					{
						[bundleInstanceList addObject:[currInstance autorelease]];
					}
				}
			}
        }
    }
	
	// we are done, update the UI on the main thread
	[self performSelectorOnMainThread:@selector(searchDone:)
                           withObject:bundleInstanceList	// pass back our list of NSBundle instance list
                        waitUntilDone:YES];                 // don't block
	
	[bundleInstanceList release];
	
	[pool release];
}

// -------------------------------------------------------------------------------
//	awakeFromNib
// -------------------------------------------------------------------------------
- (void)awakeFromNib
{
	[searchString setStringValue:kSearchStr];
	[searchProgress setHidden:NO];
	[searchProgress startAnimation:self];
	
	// start looking for our bundles -
	// we detach this search operation on a secondary thread; just in case,
	// this is to illustrate how this can be done without blocking the UI.
	//
	// You may choose to install your bundles elsewhere along with dozens of others
	// that might not be yours to run:
	//
	// So our target built bundles will be found in:
	//		$(HOME)/Library/Application Support/BundleLoader"
	
	[NSThread detachNewThreadSelector:@selector(startSearch:)
                             toTarget:self		// we are the target
                           withObject:nil];
				
	[[self window] setFrameAutosaveName:@"MainWindow"];	// remember our window size and position next time
}

// -------------------------------------------------------------------------------
//	applicationShouldTerminateAfterLastWindowClosed:sender
//
//	NSApplication delegate method placed here so the sample conveniently quits
//	after we close the window.
// -------------------------------------------------------------------------------
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
	return YES;
}

// -------------------------------------------------------------------------------
//	openBundle:bundleDict
//
//	Searches our internal list of bundle instances based on the NSDictionary
//	object fetched from our array controller.
// -------------------------------------------------------------------------------
- (void)openBundle:(NSDictionary *)bundleDict
{
	MyBundle *bundleInstance = [bundleDict objectForKey:@"bundleInstance"];
	if (bundleInstance && [bundleInstance open])		// open the windows for this bundle
	{
		[self willChangeValueForKey:@"hasOpenWindows"];
		hasOpenWindows = YES;
		[self didChangeValueForKey:@"hasOpenWindows"];
	}
}

// -------------------------------------------------------------------------------
//	inspect:selectedObjects
//
//	User double-clicked an item in the table, find the bundle instance in our list based
//	on the selected in our arrayController.
// -------------------------------------------------------------------------------
- (IBAction)inspect:(NSArray *)selectedObjects
{
	if ([selectedObjects count] > 0)
	{
		// find the bundle instance from our internal list; if we find a match, open it
		NSDictionary *objectDict = [selectedObjects objectAtIndex:0];
		if (objectDict)
		{
			[self openBundle:objectDict];
		}
	}
}

// -------------------------------------------------------------------------------
//	openAction:sender
//
//	User clicked the "Open" button, find the bundle instance in our list based
//	on the selected in our arrayController.
// -------------------------------------------------------------------------------
- (IBAction)openAction:(id)sender
{
	// find the bundle instance from our internal list; if we find a match, open it
	if ([[arrayController selectedObjects] count] > 0)
	{
		NSDictionary *objectDict = [[arrayController selectedObjects] objectAtIndex:0];
		if (objectDict)
		{
			[self openBundle:objectDict];
		}
	}
}

// -------------------------------------------------------------------------------
//	closeAllAction:sender
//
//	User clicked the "Close All" button, close all opened bundle windows.
// -------------------------------------------------------------------------------
- (IBAction)closeAllAction:(id)sender
{
	for (NSDictionary *bundleDict in [arrayController arrangedObjects])
    {
		MyBundle *curBundle = [bundleDict objectForKey:@"bundleInstance"];
		if ([curBundle isOpen])
			[curBundle close];
	}
	
	[self willChangeValueForKey:@"hasOpenWindows"];
	hasOpenWindows = NO;
	[self didChangeValueForKey:@"hasOpenWindows"];
}

@end
