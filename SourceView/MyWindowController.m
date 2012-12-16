/*
     File: MyWindowController.m 
 Abstract: Interface for MyWindowController class, the main controller class for this sample.
  
  Version: 1.3 
  
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

#import "IconViewController.h"
#import "FileViewController.h"
#import "ChildEditController.h"
#import "ChildNode.h"
#import "ImageAndTextCell.h"
#import "SeparatorCell.h"

#define COLUMNID_NAME			@"NameColumn"	// the single column name in our outline view
#define INITIAL_INFODICT		@"Outline"		// name of the dictionary file to populate our outline view

#define ICONVIEW_NIB_NAME		@"IconView"		// nib name for the icon view
#define FILEVIEW_NIB_NAME		@"FileView"		// nib name for the file view
#define CHILDEDIT_NAME			@"ChildEdit"	// nib name for the child edit window controller

#define UNTITLED_NAME			@"Untitled"		// default name for added folders and leafs

#define HTTP_PREFIX				@"http://"

// default folder titles
#define DEVICES_NAME			@"DEVICES"
#define PLACES_NAME				@"PLACES"

// keys in our disk-based dictionary representing our outline view's data
#define KEY_NAME				@"name"
#define KEY_URL					@"url"
#define KEY_SEPARATOR			@"separator"
#define KEY_GROUP				@"group"
#define KEY_FOLDER				@"folder"
#define KEY_ENTRIES				@"entries"

#define kMinOutlineViewSplit	120.0f

#define kNodesPBoardType		@"myNodesPBoardType"	// drag and drop pasteboard type

#pragma mark -

// -------------------------------------------------------------------------------
//	TreeAdditionObj
//
//	This object is used for passing data between the main and secondary thread
//	which populates the outline view.
// -------------------------------------------------------------------------------
@interface TreeAdditionObj : NSObject
{
	NSIndexPath *indexPath;
	NSString	*nodeURL;
	NSString	*nodeName;
	BOOL		selectItsParent;
}

@property (readonly) NSIndexPath *indexPath;
@property (readonly) NSString *nodeURL;
@property (readonly) NSString *nodeName;
@property (readonly) BOOL selectItsParent;

@end


#pragma mark -

@implementation TreeAdditionObj

@synthesize indexPath, nodeURL, nodeName, selectItsParent;

// -------------------------------------------------------------------------------
//  initWithURL:url:name:select
// -------------------------------------------------------------------------------
- (id)initWithURL:(NSString *)url withName:(NSString *)name selectItsParent:(BOOL)select
{
	self = [super init];
	
	nodeName = name;
	nodeURL = url;
	selectItsParent = select;
	
	return self;
}
@end


#pragma mark -

@implementation MyWindowController

@synthesize dragNodesArray;

// -------------------------------------------------------------------------------
//	initWithWindow:window
// -------------------------------------------------------------------------------
- (id)initWithWindow:(NSWindow *)window
{
	self = [super initWithWindow:window];
	if (self)
	{
		contents = [[NSMutableArray alloc] init];
		
		// cache the reused icon images
		folderImage = [[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericFolderIcon)] retain];
		[folderImage setSize:NSMakeSize(16,16)];
		
		urlImage = [[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericURLIcon)] retain];
		[urlImage setSize:NSMakeSize(16,16)];
	}
	
	return self;
}

// -------------------------------------------------------------------------------
//	dealloc
// -------------------------------------------------------------------------------
- (void)dealloc
{
	[folderImage release];
	[urlImage release];
	
	[iconViewController release];
	
	[contents release];
	
	[separatorCell release];
	
	self.dragNodesArray = nil;
	
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReceivedContentNotification object:nil];
    
	[super dealloc];
}

// -------------------------------------------------------------------------------
//	awakeFromNib
// -------------------------------------------------------------------------------
- (void)awakeFromNib
{
	// load the icon view controller for later use
	iconViewController = [[IconViewController alloc] initWithNibName:ICONVIEW_NIB_NAME bundle:nil];
	
	// load the file view controller for later use
	fileViewController = [[FileViewController alloc] initWithNibName:FILEVIEW_NIB_NAME bundle:nil];
	
	// load the child edit view controller for later use
	childEditController = [[ChildEditController alloc] initWithWindowNibName:CHILDEDIT_NAME];
	
	[[self window] setAutorecalculatesContentBorderThickness:YES forEdge:NSMinYEdge];
	[[self window] setContentBorderThickness:30 forEdge:NSMinYEdge];
	
	// apply our custom ImageAndTextCell for rendering the first column's cells
	NSTableColumn *tableColumn = [myOutlineView tableColumnWithIdentifier:COLUMNID_NAME];
	ImageAndTextCell *imageAndTextCell = [[[ImageAndTextCell alloc] init] autorelease];
	[imageAndTextCell setEditable:YES];
	[tableColumn setDataCell:imageAndTextCell];
   
	separatorCell = [[SeparatorCell alloc] init];
    [separatorCell setEditable:NO];
	
	// build our default tree on a separate thread,
	// some portions are from disk which could get expensive depending on the size of the dictionary file:
	[NSThread detachNewThreadSelector:	@selector(populateOutlineContents:)
										toTarget:self		// we are the target
										withObject:nil];
	
	// add images to our add/remove buttons
	NSImage *addImage = [NSImage imageNamed:NSImageNameAddTemplate];
	[addFolderButton setImage:addImage];
	NSImage *removeImage = [NSImage imageNamed:NSImageNameRemoveTemplate];
	[removeButton setImage:removeImage];
	
	// insert an empty menu item at the beginning of the drown down button's menu and add its image
	NSImage *actionImage = [NSImage imageNamed:NSImageNameActionTemplate];
	[actionImage setSize:NSMakeSize(10,10)];
	
	NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
	[[actionButton menu] insertItem:menuItem atIndex:0];
	[menuItem setImage:actionImage];
	[menuItem release];
	
	// truncate to the middle if the url is too long to fit
	[[urlField cell] setLineBreakMode:NSLineBreakByTruncatingMiddle];
	
	// scroll to the top in case the outline contents is very long
	[[[myOutlineView enclosingScrollView] verticalScroller] setFloatValue:0.0];
	[[[myOutlineView enclosingScrollView] contentView] scrollToPoint:NSMakePoint(0,0)];
	
	// make our outline view appear with gradient selection, and behave like the Finder, iTunes, etc.
	[myOutlineView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleSourceList];
	
	// drag and drop support
	[myOutlineView registerForDraggedTypes:[NSArray arrayWithObjects:
											kNodesPBoardType,			// our internal drag type
											NSURLPboardType,			// single url from pasteboard
											NSFilenamesPboardType,		// from Safari or Finder
											NSFilesPromisePboardType,	// from Safari or Finder (multiple URLs)
											nil]];
											
	[webView setUIDelegate:self];	// be the webView's delegate to capture NSResponder calls
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contentReceived:)
                                                 name:kReceivedContentNotification object:nil];
}

// -------------------------------------------------------------------------------
//	setContents:newContents
// -------------------------------------------------------------------------------
- (void)setContents:(NSArray *)newContents
{
	if (contents != newContents)
	{
		[contents release];
		contents = [[NSMutableArray alloc] initWithArray:newContents];
	}
}

// -------------------------------------------------------------------------------
//	contents:
// -------------------------------------------------------------------------------
- (NSMutableArray *)contents
{
	return contents;
}


#pragma mark - Actions

// -------------------------------------------------------------------------------
//	selectParentFromSelection
//
//	Take the currently selected node and select its parent.
// -------------------------------------------------------------------------------
- (void)selectParentFromSelection
{
	if ([[treeController selectedNodes] count] > 0)
	{
		NSTreeNode* firstSelectedNode = [[treeController selectedNodes] objectAtIndex:0];
		NSTreeNode* parentNode = [firstSelectedNode parentNode];
		if (parentNode)
		{
			// select the parent
			NSIndexPath* parentIndex = [parentNode indexPath];
			[treeController setSelectionIndexPath:parentIndex];
		}
		else
		{
			// no parent exists (we are at the top of tree), so make no selection in our outline
			NSArray* selectionIndexPaths = [treeController selectionIndexPaths];
			[treeController removeSelectionIndexPaths:selectionIndexPaths];
		}
	}
}

// -------------------------------------------------------------------------------
//	performAddFolder:treeAddition
// -------------------------------------------------------------------------------
- (void)performAddFolder:(TreeAdditionObj *)treeAddition
{
	// NSTreeController inserts objects using NSIndexPath, so we need to calculate this
	NSIndexPath *indexPath = nil;
	
	// if there is no selection, we will add a new group to the end of the contents array
	if ([[treeController selectedObjects] count] == 0)
	{
		// there's no selection so add the folder to the top-level and at the end
		indexPath = [NSIndexPath indexPathWithIndex:[contents count]];
	}
	else
	{
		// get the index of the currently selected node, then add the number its children to the path -
		// this will give us an index which will allow us to add a node to the end of the currently selected node's children array.
		//
		indexPath = [treeController selectionIndexPath];
		if ([[[treeController selectedObjects] objectAtIndex:0] isLeaf])
		{
			// user is trying to add a folder on a selected child,
			// so deselect child and select its parent for addition
			[self selectParentFromSelection];
		}
		else
		{
			indexPath = [indexPath indexPathByAddingIndex:[[[[treeController selectedObjects] objectAtIndex:0] children] count]];
		}
	}
	
	ChildNode *node = [[ChildNode alloc] init];
    node.nodeTitle = [treeAddition nodeName];
	
	// the user is adding a child node, tell the controller directly
	[treeController insertObject:node atArrangedObjectIndexPath:indexPath];
	
	[node release];
}

// -------------------------------------------------------------------------------
//	addFolder:folderName
// -------------------------------------------------------------------------------
- (void)addFolder:(NSString *)folderName
{
	TreeAdditionObj *treeObjInfo = [[TreeAdditionObj alloc] initWithURL:nil withName:folderName selectItsParent:NO];
	
	if (buildingOutlineView)
	{
		// add the folder to the tree controller, but on the main thread to avoid lock ups
		[self performSelectorOnMainThread:@selector(performAddFolder:) withObject:treeObjInfo waitUntilDone:YES];
	}
	else
	{
		[self performAddFolder:treeObjInfo];
	}
	
	[treeObjInfo release];
}

// -------------------------------------------------------------------------------
//	addFolderAction:sender:
// -------------------------------------------------------------------------------
- (IBAction)addFolderAction:(id)sender
{
	[self addFolder:UNTITLED_NAME];
}

// -------------------------------------------------------------------------------
//	performAddChild:treeAddition
// -------------------------------------------------------------------------------
- (void)performAddChild:(TreeAdditionObj *)treeAddition
{
	if ([[treeController selectedObjects] count] > 0)
	{
		// we have a selection
		if ([[[treeController selectedObjects] objectAtIndex:0] isLeaf])
		{
			// trying to add a child to a selected leaf node, so select its parent for add
			[self selectParentFromSelection];
		}
	}
	
	// find the selection to insert our node
	NSIndexPath *indexPath;
	if ([[treeController selectedObjects] count] > 0)
	{
		// we have a selection, insert at the end of the selection
		indexPath = [treeController selectionIndexPath];
		indexPath = [indexPath indexPathByAddingIndex:[[[[treeController selectedObjects] objectAtIndex:0] children] count]];
	}
	else
	{
		// no selection, just add the child to the end of the tree
		indexPath = [NSIndexPath indexPathWithIndex:[contents count]];
	}
	
	// create a leaf node
	ChildNode *node = [[ChildNode alloc] initLeaf];
	node.urlString = [treeAddition nodeURL];
    
	if ([treeAddition nodeURL])
	{
		if ([[treeAddition nodeURL] length] > 0)
		{
			// the child to insert has a valid URL, use its display name as the node title
			if ([treeAddition nodeName])
                node.nodeTitle = [treeAddition nodeName];
			else
                node.nodeTitle = [[NSFileManager defaultManager] displayNameAtPath:[node urlString]];
		}
		else
		{
			// the child to insert will be an empty URL
            node.nodeTitle = UNTITLED_NAME;
            node.urlString = HTTP_PREFIX;
		}
	}
	
	// the user is adding a child node, tell the controller directly
	[treeController insertObject:node atArrangedObjectIndexPath:indexPath];

	[node release];
	
	// adding a child automatically becomes selected by NSOutlineView, so keep its parent selected
	if ([treeAddition selectItsParent])
		[self selectParentFromSelection];
}

// -------------------------------------------------------------------------------
//	addChild:url:withName:selectParent
// -------------------------------------------------------------------------------
- (void)addChild:(NSString *)url withName:(NSString *)nameStr selectParent:(BOOL)select
{
	TreeAdditionObj *treeObjInfo = [[TreeAdditionObj alloc] initWithURL:url
                                                               withName:nameStr
                                                        selectItsParent:select];
	
	if (buildingOutlineView)
	{
		// add the child node to the tree controller, but on the main thread to avoid lock ups
		[self performSelectorOnMainThread:@selector(performAddChild:)
                               withObject:treeObjInfo
                            waitUntilDone:YES];
	}
	else
	{
		[self performAddChild:treeObjInfo];
	}
	
	[treeObjInfo release];
}

// -------------------------------------------------------------------------------
//	addBookmarkAction:sender
// -------------------------------------------------------------------------------
- (IBAction)addBookmarkAction:(id)sender
{
	// ask our edit sheet for information on the new child to be added
	NSDictionary *newValues = [childEditController edit:nil from:self];
	if (![childEditController wasCancelled] && newValues)
	{
		NSString *itemStr = [newValues objectForKey:@"name"];
        [self addChild:[newValues objectForKey:@"url"]
			withName:([itemStr length] > 0) ? [newValues objectForKey:@"name"] : UNTITLED_NAME
                selectParent:NO];	// add empty untitled child
	}
}

// -------------------------------------------------------------------------------
//	editChildAction:sender
// -------------------------------------------------------------------------------
- (IBAction)editBookmarkAction:(id)sender
{
	NSIndexPath *indexPath = [treeController selectionIndexPath];
	
	// get the selected item's name and url
	NSInteger selectedRow = [myOutlineView selectedRow];
	BaseNode *node = [[myOutlineView itemAtRow:selectedRow] representedObject];
	NSDictionary *editInfo = [NSDictionary dictionaryWithObjectsAndKeys:
								[node nodeTitle], @"name",
								[node urlString], @"url",
								nil];
	
	// only open the edit alert sheet for URL leafs (not folders or file system objects)
	//
	if (([[node urlString] length] == 0) || (![[node urlString] hasPrefix:@"http://"]))
	{
		// it's a folder or a file-system based object, just allow editing the cell title
		[myOutlineView editColumn:0 row:selectedRow withEvent:[NSApp currentEvent] select:YES];
	}
	else
	{
		// ask our sheet to edit these two values
		NSDictionary *newValues = [childEditController edit:editInfo from:self];
		if (![childEditController wasCancelled] && newValues)
		{
			// create a child node
			ChildNode *childNode = [[ChildNode alloc] initLeaf];
			childNode.urlString = [newValues objectForKey:@"url"];
            
            NSString *nodeStr = [newValues objectForKey:@"name"];
			childNode.nodeTitle = ([nodeStr length] > 0) ? [newValues objectForKey:@"name"] : UNTITLED_NAME;
			// remove the current selection and replace it with the newly edited child
			[treeController remove:self];
			[treeController insertObject:childNode atArrangedObjectIndexPath:indexPath];
            [childNode release];
		}
	}
}

// -------------------------------------------------------------------------------
//	addEntries
// -------------------------------------------------------------------------------
- (void)addEntries:(NSDictionary *)entries
{
	NSEnumerator *entryEnum = [entries objectEnumerator];
	
	id entry;
	while ((entry = [entryEnum nextObject]))
	{
		if ([entry isKindOfClass:[NSDictionary class]])
		{
			NSString *urlStr = [entry objectForKey:KEY_URL];
			
			if ([entry objectForKey:KEY_SEPARATOR])
			{
				// its a separator mark, we treat is as a leaf
				[self addChild:nil withName:nil selectParent:YES];
			}
			else if ([entry objectForKey:KEY_FOLDER])
			{
				// its a file system based folder,
				// we treat is as a leaf and show its contents in the NSCollectionView
				NSString *folderName = [entry objectForKey:KEY_FOLDER];
				[self addChild:urlStr withName:folderName selectParent:YES];
			}
			else if ([entry objectForKey:KEY_URL])
			{
				// its a leaf item with a URL
				NSString *nameStr = [entry objectForKey:KEY_NAME];
				[self addChild:urlStr withName:nameStr selectParent:YES];
			}
			else
			{
				// it's a generic container
				NSString *folderName = [entry objectForKey:KEY_GROUP];
				[self addFolder:folderName];
				
				// add its children
				NSDictionary *newChildren = [entry objectForKey:KEY_ENTRIES];
				[self addEntries:newChildren];
				
				[self selectParentFromSelection];
			}
		}
	}
	
	// inserting children automatically expands its parent, we want to close it
	if ([[treeController selectedNodes] count] > 0)
	{
		NSTreeNode *lastSelectedNode = [[treeController selectedNodes] objectAtIndex:0];
		[myOutlineView collapseItem:lastSelectedNode];
	}
}

// -------------------------------------------------------------------------------
//	populateOutline
//
//	Populate the tree controller from disk-based dictionary (Outline.dict)
// -------------------------------------------------------------------------------
- (void)populateOutline
{
	NSDictionary *initData = [NSDictionary dictionaryWithContentsOfFile:
								[[NSBundle mainBundle] pathForResource:INITIAL_INFODICT ofType:@"dict"]];
	NSDictionary *entries = [initData objectForKey:KEY_ENTRIES];
	[self addEntries:entries];
}

// -------------------------------------------------------------------------------
//	addDevicesSection
// -------------------------------------------------------------------------------
- (void)addDevicesSection
{
	// insert the "Devices" group at the top of our tree
	[self addFolder:DEVICES_NAME];
	
	// automatically add mounted and removable volumes to the "Devices" group
	NSArray *mountedVols = [[NSWorkspace sharedWorkspace] mountedLocalVolumePaths]; 
	if ([mountedVols count] > 0)
	{
		for (NSString *element in mountedVols)
			[self addChild:element withName:nil selectParent:YES];
	}

	[self selectParentFromSelection];
}

// -------------------------------------------------------------------------------
//	addPlacesSection
// -------------------------------------------------------------------------------
- (void)addPlacesSection
{
	// add the "Places" section
	[self addFolder:PLACES_NAME];
	
	// add its children
	[self addChild:NSHomeDirectory() withName:nil selectParent:YES];	
	[self addChild:[NSHomeDirectory() stringByAppendingPathComponent:@"Pictures"] withName:nil selectParent:YES];	
	[self addChild:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] withName:nil selectParent:YES];	
	[self addChild:@"/Applications" withName:nil selectParent:YES];

	[self selectParentFromSelection];
}

// -------------------------------------------------------------------------------
//	populateOutlineContents:inObject
//
//	This method is being called on a separate thread to avoid blocking the UI
//	a startup time.
// -------------------------------------------------------------------------------
- (void)populateOutlineContents:(id)inObject
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	buildingOutlineView = YES;		// indicate to ourselves we are building the default tree at startup
		
	[myOutlineView setHidden:YES];	// hide the outline view - don't show it as we are building the contents
	
	[self addDevicesSection];		// add the "Devices" outline section
	[self addPlacesSection];		// add the "Places" outline section
	[self populateOutline];			// add the disk-based outline content
	
	buildingOutlineView = NO;		// we're done building our default tree
	
	// remove the current selection
	NSArray *selection = [treeController selectionIndexPaths];
	[treeController removeSelectionIndexPaths:selection];
	
	[myOutlineView setHidden:NO];	// we are done populating the outline view content, show it again
	
	[pool release];
}


#pragma mark - WebView delegate

// -------------------------------------------------------------------------------
//	webView:makeFirstResponder
//
//	We want to keep the outline view in focus as the user clicks various URLs.
//
//	So this workaround applies to an unwanted side affect to some web pages that might have
//	JavaScript code thatt focus their text fields as we target the web view with a particular URL.
//
// -------------------------------------------------------------------------------
- (void)webView:(WebView *)sender makeFirstResponder:(NSResponder *)responder
{
	if (retargetWebView)
	{
		// we are targeting the webview ourselves as a result of the user clicking
		// a url in our outlineview: don't do anything, but reset our target check flag
		//
		retargetWebView = NO;
	}
	else
	{
		// continue the responder chain
		[[self window] makeFirstResponder:sender];
	}
}

// -------------------------------------------------------------------------------
//  validateMenuItem:item
// -------------------------------------------------------------------------------
- (BOOL)validateMenuItem:(NSMenuItem *)item
{
    BOOL enabled = NO;
    
    // is it our "Edit..." menu item in our action button?
    if ([item action] == @selector(editBookmarkAction:))
    {
        if ([[treeController selectedNodes] count] > 0)
        {
            // only allow for editing http url items or items with out a URL
            // (this avoids accidentally renaming real file system items)
            //
            NSTreeNode *firstSelectedNode = [[treeController selectedNodes] objectAtIndex:0];
            BaseNode *node = [firstSelectedNode representedObject];
            if (!node.urlString || [[node urlString] hasPrefix:HTTP_PREFIX])
                enabled = YES;
        }
    }
    
    return enabled;
}


#pragma mark - Node checks

// -------------------------------------------------------------------------------
//	isSeparator:node
// -------------------------------------------------------------------------------
- (BOOL)isSeparator:(BaseNode *)node
{
    return ([node nodeIcon] == nil && [[node nodeTitle] length] == 0);
}

// -------------------------------------------------------------------------------
//	isSpecialGroup:groupNode
// -------------------------------------------------------------------------------
- (BOOL)isSpecialGroup:(BaseNode *)groupNode
{ 
	return ([groupNode nodeIcon] == nil &&
			([[groupNode nodeTitle] isEqualToString:DEVICES_NAME] || [[groupNode nodeTitle] isEqualToString:PLACES_NAME]));
}


#pragma mark - Managing Views

// -------------------------------------------------------------------------------
//  contentReceived:notif
//
//  Notification sent from IconViewController class,
//  indicating the file system content has been received
// -------------------------------------------------------------------------------
- (void)contentReceived:(NSNotification *)notif
{
    [progIndicator setHidden:YES];
    [progIndicator stopAnimation:self];
}

// -------------------------------------------------------------------------------
//	removeSubview
// -------------------------------------------------------------------------------
- (void)removeSubview
{
	// empty selection
	NSArray *subViews = [placeHolderView subviews];
	if ([subViews count] > 0)
	{
		[[subViews objectAtIndex:0] removeFromSuperview];
	}
	
	[placeHolderView displayIfNeeded];	// we want the removed views to disappear right away
}

// -------------------------------------------------------------------------------
//	changeItemView
// ------------------------------------------------------------------------------
- (void)changeItemView
{
	NSArray	*selection = [treeController selectedNodes];	
	if ([selection count] > 0)
    {
        BaseNode *node = [[selection objectAtIndex:0] representedObject];
        NSString *urlStr = [node urlString];
        if (urlStr)
        {
            NSURL *targetURL = [NSURL fileURLWithPath:urlStr];
            
            if ([urlStr hasPrefix:HTTP_PREFIX])
            {
                // 1) the url is a web-based url
                //
                if (currentView != webView)
                {
                    // change to web view
                    [self removeSubview];
                    currentView = nil;
                    [placeHolderView addSubview:webView];
                    currentView = webView;
                }
                
                // this will tell our WebUIDelegate not to retarget first responder since some web pages force
                // forus to their text fields - we want to keep our outline view in focus.
                retargetWebView = YES;	
                
                [webView setMainFrameURL:urlStr];	// re-target to the new url
            }
            else
            {
                // 2) the url is file-system based (folder or file)
                //
                if (currentView != [fileViewController view] || currentView != [iconViewController view])
                {
                    // detect if the url is a directory
                    NSNumber *isDirectory = nil;
                    
                    NSURL *url = [NSURL fileURLWithPath:[node urlString]];
                    [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
                    if ([isDirectory boolValue])
                    {
                        // avoid a flicker effect by not removing the icon view if it is already embedded
                        if (!(currentView == [iconViewController view]))
                        {
                            // remove the old subview
                            [self removeSubview];
                            currentView = nil;
                        }
                        
                        // change to icon view to display folder contents
                        [placeHolderView addSubview:[iconViewController view]];
                        currentView = [iconViewController view];
                        
                        // its a directory - show its contents using NSCollectionView
                        iconViewController.url = targetURL;
                        
                        // add a spinning progress gear in case populating the icon view takes too long
                        [progIndicator setHidden:NO];
                        [progIndicator startAnimation:self];
                        
                        // note: we will be notifed back to stop our progress indicator
                        // as soon as iconViewController is done fetching its content.
                    }
                    else
                    {
                        // 3) its a file, just show the item info
                        //
                        // remove the old subview
                        [self removeSubview];
                        currentView = nil;
                        
                        // change to file view
                        [placeHolderView addSubview:[fileViewController view]];
                        currentView = [fileViewController view];
                        
                        // update the file's info
                        fileViewController.url = targetURL;
                    }
                }
            }
            
            NSRect newBounds;
            newBounds.origin.x = 0;
            newBounds.origin.y = 0;
            newBounds.size.width = [[currentView superview] frame].size.width;
            newBounds.size.height = [[currentView superview] frame].size.height;
            [currentView setFrame:[[currentView superview] frame]];
            
            // make sure our added subview is placed and resizes correctly
            [currentView setFrameOrigin:NSMakePoint(0,0)];
            [currentView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        }
        else
        {
            // there's no url associated with this node
            // so a container was selected - no view to display
            [self removeSubview];
            currentView = nil;
        }
    }
}


#pragma mark - NSOutlineView delegate

// -------------------------------------------------------------------------------
//	shouldSelectItem:item
// -------------------------------------------------------------------------------
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item;
{
	// don't allow special group nodes (Devices and Places) to be selected
	BaseNode *node = [item representedObject];
	return (![self isSpecialGroup:node] && ![self isSeparator:node]);
}

// -------------------------------------------------------------------------------
//	dataCellForTableColumn:tableColumn:item
// -------------------------------------------------------------------------------
- (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	NSCell *returnCell = [tableColumn dataCell];
	
	if ([[tableColumn identifier] isEqualToString:COLUMNID_NAME])
	{
		// we are being asked for the cell for the single and only column
		BaseNode *node = [item representedObject];
		if ([self isSeparator:node])
            returnCell = separatorCell;
	}
	
	return returnCell;
}

// -------------------------------------------------------------------------------
//	textShouldEndEditing:fieldEditor
// -------------------------------------------------------------------------------
- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
	if ([[fieldEditor string] length] == 0)
	{
		// don't allow empty node names
		return NO;
	}
	else
	{
		return YES;
	}
}

// -------------------------------------------------------------------------------
//	shouldEditTableColumn:tableColumn:item
//
//	Decide to allow the edit of the given outline view "item".
// -------------------------------------------------------------------------------
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	BOOL result = YES;
	
	item = [item representedObject];
	if ([self isSpecialGroup:item])
	{
		result = NO; // don't allow special group nodes to be renamed
	}
	else
	{
		if ([[item urlString] isAbsolutePath])
			result = NO;	// don't allow file system objects to be renamed
	}
	
	return result;
}

// -------------------------------------------------------------------------------
//	outlineView:willDisplayCell:forTableColumn:item
// -------------------------------------------------------------------------------
- (void)outlineView:(NSOutlineView *)olv willDisplayCell:(NSCell*)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{	 
	if ([[tableColumn identifier] isEqualToString:COLUMNID_NAME])
	{
		// we are displaying the single and only column
		if ([cell isKindOfClass:[ImageAndTextCell class]])
		{
			item = [item representedObject];
			if (item)
			{
				if ([item isLeaf])
				{
					// does it have a URL string?
					NSString *urlStr = [item urlString];
					if (urlStr)
					{
						if ([item isLeaf])
						{
							NSImage *iconImage;
							if ([[item urlString] hasPrefix:HTTP_PREFIX])
								iconImage = urlImage;
							else
								iconImage = [[NSWorkspace sharedWorkspace] iconForFile:urlStr];
							[item setNodeIcon:iconImage];
						}
						else
						{
							NSImage* iconImage = [[NSWorkspace sharedWorkspace] iconForFile:urlStr];
							[item setNodeIcon:iconImage];
						}
					}
					else
					{
						// it's a separator, don't bother with the icon
					}
				}
				else
				{
					// check if it's a special folder (DEVICES or PLACES), we don't want it to have an icon
					if ([self isSpecialGroup:item])
					{
						[item setNodeIcon:nil];
					}
					else
					{
						// it's a folder, use the folderImage as its icon
						[item setNodeIcon:folderImage];
					}
				}
			}
			
			// set the cell's image
			[(ImageAndTextCell*)cell setImage:[item nodeIcon]];
		}
	}
}

// -------------------------------------------------------------------------------
//	outlineViewSelectionDidChange:notification
// -------------------------------------------------------------------------------
- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	if (buildingOutlineView)	// we are currently building the outline view, don't change any view selections
		return;

	// ask the tree controller for the current selection
	NSArray *selection = [treeController selectedObjects];
	if ([selection count] > 1)
	{
		// multiple selection - clear the right side view
		[self removeSubview];
		currentView = nil;
	}
	else
	{
		if ([selection count] == 1)
		{
			// single selection
			[self changeItemView];
		}
		else
		{
			// there is no current selection - no view to display
			[self removeSubview];
			currentView = nil;
		}
	}
}

// ----------------------------------------------------------------------------------------
// outlineView:isGroupItem:item
// ----------------------------------------------------------------------------------------
- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
	return ([self isSpecialGroup:[item representedObject]] ? YES : NO);
}


#pragma mark - NSOutlineView drag and drop

// ----------------------------------------------------------------------------------------
// draggingSourceOperationMaskForLocal <NSDraggingSource override>
// ----------------------------------------------------------------------------------------
- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
	return NSDragOperationMove;
}

// ----------------------------------------------------------------------------------------
// outlineView:writeItems:toPasteboard
// ----------------------------------------------------------------------------------------
- (BOOL)outlineView:(NSOutlineView *)ov writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard
{
	[pboard declareTypes:[NSArray arrayWithObjects:kNodesPBoardType, nil] owner:self];
	
	// keep track of this nodes for drag feedback in "validateDrop"
	self.dragNodesArray = items;
	
	return YES;
}

// -------------------------------------------------------------------------------
//	outlineView:validateDrop:proposedItem:proposedChildrenIndex:
//
//	This method is used by NSOutlineView to determine a valid drop target.
// -------------------------------------------------------------------------------
- (NSDragOperation)outlineView:(NSOutlineView *)ov
						validateDrop:(id <NSDraggingInfo>)info
						proposedItem:(id)item
						proposedChildIndex:(NSInteger)index
{
	NSDragOperation result = NSDragOperationNone;
	
	if (!item)
	{
		// no item to drop on
		result = NSDragOperationGeneric;
	}
	else
	{
		if ([self isSpecialGroup:[item representedObject]])
		{
			// don't allow dragging into special grouped sections (i.e. Devices and Places)
			result = NSDragOperationNone;
		}
		else
		{	
			if (index == -1)
			{
				// don't allow dropping on a child
				result = NSDragOperationNone;
			}
			else
			{
				// drop location is a container
				result = NSDragOperationMove;
			}
		}
	}
	
	return result;
}

// -------------------------------------------------------------------------------
//	handleWebURLDrops:pboard:withIndexPath:
//
//	The user is dragging URLs from Safari.
// -------------------------------------------------------------------------------
- (void)handleWebURLDrops:(NSPasteboard *)pboard withIndexPath:(NSIndexPath *)indexPath
{
	NSArray *pbArray = [pboard propertyListForType:@"WebURLsWithTitlesPboardType"];
	NSArray *urlArray = [pbArray objectAtIndex:0];
	NSArray *nameArray = [pbArray objectAtIndex:1];
	
	NSInteger i;
	for (i = ([urlArray count] - 1); i >=0; i--)
	{
		ChildNode *node = [[ChildNode alloc] init];
		
        node.isLeaf = YES;

        node.nodeTitle = [nameArray objectAtIndex:i];
        
        node.urlString = [urlArray objectAtIndex:i];
		[treeController insertObject:node atArrangedObjectIndexPath:indexPath];
		
		[node release];
	}
}

// -------------------------------------------------------------------------------
//	handleInternalDrops:pboard:withIndexPath:
//
//	The user is doing an intra-app drag within the outline view.
// -------------------------------------------------------------------------------
- (void)handleInternalDrops:(NSPasteboard *)pboard withIndexPath:(NSIndexPath *)indexPath
{
	// user is doing an intra app drag within the outline view:
	//
	NSArray* newNodes = self.dragNodesArray;

	// move the items to their new place (we do this backwards, otherwise they will end up in reverse order)
	NSInteger idx;
	for (idx = ([newNodes count] - 1); idx >= 0; idx--)
	{
		[treeController moveNode:[newNodes objectAtIndex:idx] toIndexPath:indexPath];
	}
	
	// keep the moved nodes selected
	NSMutableArray *indexPathList = [NSMutableArray array];
    for (NSUInteger i = 0; i < [newNodes count]; i++)
	{
		[indexPathList addObject:[[newNodes objectAtIndex:i] indexPath]];
	}
	[treeController setSelectionIndexPaths: indexPathList];
}

// -------------------------------------------------------------------------------
//	handleFileBasedDrops:pboard:withIndexPath:
//
//	The user is dragging file-system based objects (probably from Finder)
// -------------------------------------------------------------------------------
- (void)handleFileBasedDrops:(NSPasteboard *)pboard withIndexPath:(NSIndexPath *)indexPath
{
	NSArray *fileNames = [pboard propertyListForType:NSFilenamesPboardType];
	if ([fileNames count] > 0)
	{
		NSInteger i;
		NSInteger count = [fileNames count];
		
		for (i = (count - 1); i >=0; i--)
		{
			ChildNode *node = [[ChildNode alloc] init];

			NSURL *url = [NSURL fileURLWithPath:[fileNames objectAtIndex:i]];
            NSString *name = [[NSFileManager defaultManager] displayNameAtPath:[url path]];
            node.isLeaf = YES;

            node.nodeTitle = name;
            node.urlString = [url path];
            
			[treeController insertObject:node atArrangedObjectIndexPath:indexPath];
			
			[node release];
		}
	}
}

// -------------------------------------------------------------------------------
//	handleURLBasedDrops:pboard:withIndexPath:
//
//	Handle dropping a raw URL.
// -------------------------------------------------------------------------------
- (void)handleURLBasedDrops:(NSPasteboard *)pboard withIndexPath:(NSIndexPath *)indexPath
{
	NSURL *url = [NSURL URLFromPasteboard:pboard];
	if (url)
	{
		ChildNode *node = [[ChildNode alloc] init];

		if ([url isFileURL])
		{
			// url is file-based, use it's display name
			NSString *name = [[NSFileManager defaultManager] displayNameAtPath:[url path]];
            node.nodeTitle = name;
            node.urlString = [url path];
		}
		else
		{
			// url is non-file based (probably from Safari)
			//
			// the url might not end with a valid component name, use the best possible title from the URL
			if ([[[url path] pathComponents] count] == 1)
			{
				if ([[url absoluteString] hasPrefix:HTTP_PREFIX])
				{
					// use the url portion without the prefix
					NSRange prefixRange = [[url absoluteString] rangeOfString:HTTP_PREFIX];
					NSRange newRange = NSMakeRange(prefixRange.length, [[url absoluteString] length]- prefixRange.length - 1);
                    node.nodeTitle = [[url absoluteString] substringWithRange:newRange];
				}
				else
				{
					// prefix unknown, just use the url as its title
                    node.nodeTitle = [url absoluteString];
				}
			}
			else
			{
				// use the last portion of the URL as its title
                node.nodeTitle = [[url path] lastPathComponent];
			}
				
            node.urlString = [url absoluteString];
		}
        node.isLeaf = YES;
		
		[treeController insertObject:node atArrangedObjectIndexPath:indexPath];
		
		[node release];
	}
}

// -------------------------------------------------------------------------------
//	outlineView:acceptDrop:item:childIndex
//
//	This method is called when the mouse is released over an outline view that previously decided to allow a drop
//	via the validateDrop method. The data source should incorporate the data from the dragging pasteboard at this time.
//	'index' is the location to insert the data as a child of 'item', and are the values previously set in the validateDrop: method.
//
// -------------------------------------------------------------------------------
- (BOOL)outlineView:(NSOutlineView*)ov acceptDrop:(id <NSDraggingInfo>)info item:(id)targetItem childIndex:(NSInteger)index
{
	// note that "targetItem" is a NSTreeNode proxy
	//
	BOOL result = NO;
	
	// find the index path to insert our dropped object(s)
	NSIndexPath *indexPath;
	if (targetItem)
	{
		// drop down inside the tree node:
		// feth the index path to insert our dropped node
		indexPath = [[targetItem indexPath] indexPathByAddingIndex:index];
	}
	else
	{
		// drop at the top root level
		if (index == -1)	// drop area might be ambibuous (not at a particular location)
			indexPath = [NSIndexPath indexPathWithIndex:[contents count]]; // drop at the end of the top level
		else
			indexPath = [NSIndexPath indexPathWithIndex:index]; // drop at a particular place at the top level
	}

	NSPasteboard *pboard = [info draggingPasteboard];	// get the pasteboard
	
	// check the dragging type -
	if ([pboard availableTypeFromArray:[NSArray arrayWithObject:kNodesPBoardType]])
	{
		// user is doing an intra-app drag within the outline view
		[self handleInternalDrops:pboard withIndexPath:indexPath];
		result = YES;
	}
	else if ([pboard availableTypeFromArray:[NSArray arrayWithObject:@"WebURLsWithTitlesPboardType"]])
	{
		// the user is dragging URLs from Safari
		[self handleWebURLDrops:pboard withIndexPath:indexPath];		
		result = YES;
	}
	else if ([pboard availableTypeFromArray:[NSArray arrayWithObject:NSFilenamesPboardType]])
	{
		// the user is dragging file-system based objects (probably from Finder)
		[self handleFileBasedDrops:pboard withIndexPath:indexPath];
		result = YES;
	}
	else if ([pboard availableTypeFromArray:[NSArray arrayWithObject:NSURLPboardType]])
	{
		// handle dropping a raw URL
		[self handleURLBasedDrops:pboard withIndexPath:indexPath];
		result = YES;
	}
	
	return result;
}


#pragma mark - Split View Delegate

// -------------------------------------------------------------------------------
//	splitView:constrainMinCoordinate:
//
//	What you really have to do to set the minimum size of both subviews to kMinOutlineViewSplit points.
// -------------------------------------------------------------------------------
- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedCoordinate ofSubviewAt:(int)index
{
	return proposedCoordinate + kMinOutlineViewSplit;
}

// -------------------------------------------------------------------------------
//	splitView:constrainMaxCoordinate:
// -------------------------------------------------------------------------------
- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedCoordinate ofSubviewAt:(int)index
{
	return proposedCoordinate - kMinOutlineViewSplit;
}

// -------------------------------------------------------------------------------
//	splitView:resizeSubviewsWithOldSize:
//
//	Keep the left split pane from resizing as the user moves the divider line.
// -------------------------------------------------------------------------------
- (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize:(NSSize)oldSize
{
	NSRect newFrame = [sender frame]; // get the new size of the whole splitView
	NSView *left = [[sender subviews] objectAtIndex:0];
	NSRect leftFrame = [left frame];
	NSView *right = [[sender subviews] objectAtIndex:1];
	NSRect rightFrame = [right frame];
 
	CGFloat dividerThickness = [sender dividerThickness];
	  
	leftFrame.size.height = newFrame.size.height;

	rightFrame.size.width = newFrame.size.width - leftFrame.size.width - dividerThickness;
	rightFrame.size.height = newFrame.size.height;
	rightFrame.origin.x = leftFrame.size.width + dividerThickness;

	[left setFrame:leftFrame];
	[right setFrame:rightFrame];
}

@end
