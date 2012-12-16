/*
     File: IconViewController.m 
 Abstract: Controller object for our icon collection view.
  
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

#import "IconViewController.h"

// key values for the icon view dictionary
NSString *KEY_NAME = @"name";
NSString *KEY_ICON = @"icon";

// notification for indicating file system content has been received
NSString *kReceivedContentNotification = @"ReceivedContentNotification";

@implementation IconViewBox
- (NSView *)hitTest:(NSPoint)aPoint
{
	// don't allow any mouse clicks for subviews in this NSBox
	return nil;
}
@end

@interface IconViewController ()

@property (readwrite, retain) IBOutlet NSArrayController *iconArrayController;
@property (readwrite, retain) NSMutableArray *icons;

@end


@implementation IconViewController

@synthesize iconArrayController, url, icons;

// -------------------------------------------------------------------------------
//	awakeFromNib
// -------------------------------------------------------------------------------
- (void)awakeFromNib
{
	// listen for changes in the url for this view
	[self addObserver:	self
						forKeyPath:@"url"
						options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) 
						context:NULL];
}

// -------------------------------------------------------------------------------
//	dealloc
// -------------------------------------------------------------------------------
- (void)dealloc
{
	self.url = nil;
	self.icons = nil;
    
	[self removeObserver:self forKeyPath:@"url"];
	
	[super dealloc];
}

// -------------------------------------------------------------------------------
//	updateIcons:iconArray
//
//	The incoming object is the NSArray of file system objects to display.
//-------------------------------------------------------------------------------
- (void)updateIcons:(id)iconArray
{
    self.icons = iconArray;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kReceivedContentNotification object:nil];
}

// -------------------------------------------------------------------------------
//	gatherContents:inObject
//
//	Gathering the contents and their icons could be expensive.
//	This method is being called on a separate thread to avoid blocking the UI.
// -------------------------------------------------------------------------------
- (void)gatherContents:(id)inObject
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
    NSMutableArray *contentArray = [[NSMutableArray alloc] init];
    
    NSArray *fileURLs = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:url
                                                      includingPropertiesForKeys:[NSArray array]
                                                                         options:0
                                                                           error:nil];
	if (fileURLs)
    {
        for (NSURL *element in fileURLs)
        {
            NSString *elementNameStr = nil;
            NSImage *elementIcon = [[NSWorkspace sharedWorkspace] iconForFile:[element path]];

            // only allow visible objects
            NSNumber *hiddenFlag = nil;
            if ([element getResourceValue:&hiddenFlag forKey:NSURLIsHiddenKey error:nil])
            {
                if (![hiddenFlag boolValue])
                {
                    if ([element getResourceValue:&elementNameStr forKey:NSURLNameKey error:nil])
                    {
                        // file system object is visible so add to our array
                        [contentArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                    elementIcon, KEY_ICON,
                                                    elementNameStr, KEY_NAME,
                                                 nil]];
                    }
                }
            }
        }
    }
    
    // call back on the main thread to update the icons in our view
    [self performSelectorOnMainThread:@selector(updateIcons:) withObject:contentArray waitUntilDone:YES];
    
    [contentArray release];
    
	[pool release];
}

// -------------------------------------------------------------------------------
//	observeValueForKeyPath:ofObject:change:context
//
//	Listen for changes in the file url.
//	Given a url, obtain its contents and add only the invisible items to the collection.
// -------------------------------------------------------------------------------
- (void)observeValueForKeyPath:(NSString *)keyPath
								ofObject:(id)object 
								change:(NSDictionary *)change 
								context:(void *)context
{
	// build our directory contents on a separate thread,
	// some portions are from disk which could get expensive depending on the size
    //
	[NSThread detachNewThreadSelector:	@selector(gatherContents:)
										toTarget:self		// we are the target
										withObject:url];
}

@end
