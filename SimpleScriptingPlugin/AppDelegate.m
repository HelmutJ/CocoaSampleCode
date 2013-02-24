/*
 
 File: AppDelegate.m
 
 Abstract: a category of NSApplication where we
 implement all of our application objects properties
 and elements.  The main parts of the Objective-C code
 for supporting scripting plugins is in the NSApplication
 delegate.
 
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
 
 Copyright (C) 2009 Apple Inc. All Rights Reserved. 
 
 */

#import "AppDelegate.h"
#import "ApplicationPlugInsFolders.h"
#import "scriptLog.h"


	/* loadedPlugInInfo NSDictionary key definitions */
NSString *kPluginPathKey = @"path";
NSString *kPluginBundleKey = @"bundle";
NSString *kPluginNameKey = @"name";



@implementation AppDelegate


@synthesize loadedPlugInInfo;



	/* quit app when main window is closed */
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
	SLOG();
	return YES;
}



	/* for loading plugins and installing the custom dictionary Apple event handler. */
- (void)applicationWillFinishLaunching:(NSNotification *)notification {
	
	SLOG();
	
	NSMutableArray *localLoadedPlugIns = [NSMutableArray arrayWithCapacity:10];
	NSError *loadError = nil;

		/* retrieve a list of paths to plugins on disk */
	NSArray *appPluginPaths = [NSApp findApplicationPlugInsWithSuffix:@".simplePlugIn"];
	
		/* iterate over the plugins that were found on disk and
		 load them into the app.  It's important to perform this step
		 now so that the classes are available for Cocoa Scripting later
		 after -handleGetSDEFEvent:withReplyEvent: is called.   */
	for ( NSString *nthPluginPath in appPluginPaths ) {
		
			/* get a bundle reference for the path */
		NSBundle *plugInBundle = [NSBundle bundleWithPath:nthPluginPath];
		if ( nil != plugInBundle ) {
			
				/* load the plugin */
			if ( [plugInBundle loadAndReturnError:&loadError] ) {
				
					/* add the object to the list of loaded plug-ins */
				[localLoadedPlugIns addObject:
				 [NSDictionary dictionaryWithObjectsAndKeys:
				  nthPluginPath, kPluginPathKey,
				  plugInBundle, kPluginBundleKey,
				  [nthPluginPath lastPathComponent], kPluginNameKey,
				  nil]];
				
				SLOG(@"loaded plugin %@", plugInBundle);
				
			} else {
				
				SLOG(@"Error loading plug-in '%@': %@", nthPluginPath, loadError);
				
			}
		}
	}
	
		/* store plug-in list in delegate ivar */
	self.loadedPlugInInfo = localLoadedPlugIns;

		/* install the custom dictionary event handler */
	[[NSAppleEventManager sharedAppleEventManager]
	 setEventHandler:self andSelector:@selector(handleGetSDEFEvent:withReplyEvent:)
	 forEventClass:'ascr' andEventID:'gsdf'];		

}



 


	/* The Apple event handler for providing a custom scripting dictionary */

- (void)handleGetSDEFEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
	
	SLOG();
	
	NSError *theError = nil;
	
		/* gather all of the .sdef paths into this array */
	NSMutableArray *dictionaryList = [NSMutableArray arrayWithCapacity:10];
	
		/* search for .sdef files in the app's bundle */
	NSArray *applicationSdefPaths = [[NSBundle mainBundle]
										pathsForResourcesOfType:@"sdef" inDirectory:nil];
	if ( applicationSdefPaths != nil ) {
		[dictionaryList addObjectsFromArray:applicationSdefPaths];
	}
	
		/* search for .sdef files in the plugin bundle(s) */
	for ( NSDictionary *nthLoadedPlugIn in self.loadedPlugInInfo ) {
		NSArray *nthPlugInSdefPaths = [[nthLoadedPlugIn objectForKey:kPluginBundleKey]
										pathsForResourcesOfType:@"sdef" inDirectory:nil];
		if ( nthPlugInSdefPaths != nil ) {
			[dictionaryList addObjectsFromArray:nthPlugInSdefPaths];
		}
	}

		/* load the first .sdef file's xml data.  All of the scripting definitions
		 from the app and the plugins will be combined into this NSXMLDocument and then
		 copied into the response Apple event descriptor as UTF-8 XML text.  */
	NSString *primaryDictionaryPath = [dictionaryList objectAtIndex:0];
	NSURL *primaryDictionaryURL = [NSURL fileURLWithPath:primaryDictionaryPath];
	NSXMLDocument *primaryDictionaryXML =
		[[NSXMLDocument alloc] initWithContentsOfURL: primaryDictionaryURL
											 options:NSXMLNodeOptionsNone error:&theError];
	if ( primaryDictionaryXML != nil ) {
		
		/* retrieve the root element from the first .sdef found.  This will be
		 the <dictionary>...</dictionary> element, and it will become the root
		 of the final combined dictionary. */
		NSXMLElement *primaryDictionaryRoot = [[primaryDictionaryXML rootElement] autorelease];
		
			/* merge in the remaining .sdef files to the primary xml */
		for ( NSString *nthDictionaryPath in [dictionaryList subarrayWithRange:NSMakeRange(1, [dictionaryList count]-1)] ) {
			
				/* load the next .sdef file */
			NSURL *nthDictionaryURL = [NSURL fileURLWithPath:nthDictionaryPath];
			NSXMLDocument *nthDictionaryXML =
				[[NSXMLDocument alloc] initWithContentsOfURL:nthDictionaryURL
													 options:NSXMLNodeOptionsNone error:&theError];
			if ( nthDictionaryXML != nil ) {
				
					/* retrieve the root xml element for the .sdef file.
					 This will be the file's <dictionary>...</dictionary> element. */
				NSXMLElement *nthDictionaryRoot = [nthDictionaryXML rootElement];
	
					/* move all of the definitions in the nth dictionary over to the primary one */
				for ( NSXMLNode *nthChild in [nthDictionaryRoot children] ) {
					
						/* move the nthChild to the primary dictionary */
					[nthChild detach];
					[primaryDictionaryRoot addChild:nthChild];
				}
				
					/* done with the nth .sdef file */
				[nthDictionaryXML release];
				
			} else {
				SLOG(@"Error loading secondary .sdef file '%@': %@", nthDictionaryPath, theError);
			}
		}
			
			/* set the character encoding to UTF-8 */
		[primaryDictionaryXML setCharacterEncoding:
			(NSString *) CFStringConvertEncodingToIANACharSetName(kCFStringEncodingUTF8)];

			/* convert to XML data */
		NSData *combinedXML = [primaryDictionaryXML XMLDataWithOptions:NSXMLDocumentValidate];
		
			/* convert to an Apple event descriptor */
		NSAppleEventDescriptor *xmlDictionaryDescriptor =
			[NSAppleEventDescriptor descriptorWithDescriptorType:typeUTF8Text data: combinedXML];
		
			/* descriptor into the Apple event reply */
		[replyEvent setDescriptor:xmlDictionaryDescriptor forKeyword:keyDirectObject];
		
	} else {
		SLOG(@"Error loading primary .sdef file '%@': %@", primaryDictionaryPath, theError);
	}
	
	SLOG(@"handleGetSDEFEvent reply event = %@", replyEvent);
}



@end
