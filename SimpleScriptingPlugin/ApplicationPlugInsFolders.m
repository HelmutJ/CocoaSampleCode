/*
 
 File: ApplicationPlugInsFolders.m
 
 Abstract: Implementation for an NSApplication category that includes
 some methods for finding and locating scripting plugins. 
 
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

#import "ApplicationPlugInsFolders.h"
#import "scriptLog.h"


@implementation NSApplication (ApplicationPlugInsFolders)



	/* return an array of folders to search for plugins.  This method will return the
	 following paths:
	 
	 applicationBundle/Contents/PlugIns
	 ~/Library/Application Support/applicationSupportDirectory/PlugIns
	 /Library/Application Support/applicationSupportDirectory/PlugIns
	 as described in
	 
	 http://developer.apple.com/documentation/Cocoa/Conceptual/LoadingCode/Concepts/Plugins.html
	 
	 NOTE:  to make this sample more convenient for testing and exploring,
	 this method also returns a path to the folder containing the application's bundle.
	 */
- (NSArray *)applicationPlugInsFolders {
	NSString *applicationName = [[[NSBundle mainBundle] infoDictionary] objectForKey: @"CFBundleName"];
	NSMutableArray *thePaths = [NSMutableArray arrayWithCapacity:3];
	
		/* (A) the main bundle's plugin folder */
	NSString *bundlePluginPath = [[NSBundle mainBundle] builtInPlugInsPath];
	[thePaths addObject:bundlePluginPath];
	
		/* (B) path to directory containing the application
		 NOTE: for convenience during testing, we'll add the directory containing the application
		 that will be the build directory for all of the targets in this Xcode project.  */
	NSString *pathToAppFolder = [[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent];
	[thePaths addObject: pathToAppFolder];
	
	
		/* if we found the application name ... */
	if ( applicationName != nil ) {
		FSRef folder;
		OSErr err = noErr;
		CFURLRef url;
		
			/* (C) ~/Library/Application Support/applicationSupportDirectory/PlugIns
			 The user's application support folder.  Attempt to locate the folder, but
			 do not try to create one if it does not exist.  */
		err = FSFindFolder( kUserDomain, kApplicationSupportFolderType, false, &folder );
		if ( noErr == err ) {
			url = CFURLCreateFromFSRef( kCFAllocatorDefault, &folder );
			if ( url != NULL ) {
				NSString *userAppSupportPluginFolder = [NSString stringWithFormat:@"%@/%@/PlugIns",
														[(NSURL *)url path], applicationName];
				[thePaths addObject:userAppSupportPluginFolder];
			}
		}
		
			/* (D) /Library/Application Support/applicationSupportDirectory/PlugIns
			 The local machine's application support folder.  Attempt to locate the
			 folder, but do not try to create one if it does not exist.  */
		err = FSFindFolder( kLocalDomain, kApplicationSupportFolderType, false, &folder );
		if ( noErr == err ) {
			url = CFURLCreateFromFSRef( kCFAllocatorDefault, &folder );
			if ( url != NULL ) {
				NSString *machineAppSupportPluginFolder = [NSString stringWithFormat:@"%@/%@/PlugIns",
														   [(NSURL *)url path], applicationName];
				[thePaths addObject:machineAppSupportPluginFolder];
			}
		}
	}
	
		/* return the paths */
	return thePaths;
}

 


	/* find all of the plugin bundles with the given suffix and return an
	 array of paths referring to any plugins found.  This method calls
	 -applicationPlugInsFolders to retrieve a list of folders to search. */

- (NSArray *)findApplicationPlugInsWithSuffix:(NSString *)pluginBundleSuffix {
	
		/* get a list of all the plug-in folders */
	NSArray *pluginFolderPaths = [NSApp applicationPlugInsFolders];
	
		/* set up the result */
	NSMutableArray *pluginBundlePaths = [NSMutableArray arrayWithCapacity:10];
	
		/* for enumerating directory contents */
	NSFileManager *fileManager = [NSFileManager defaultManager];
	BOOL isDirectory;
		
		/* scan each folder for matching plugin bundles */
	for ( NSString *nthFolder in pluginFolderPaths ) {
		
			/* make sure the folder exists before trying to enumerate the files in it */
		if ( [fileManager fileExistsAtPath:nthFolder isDirectory:&isDirectory] && isDirectory ) {
			
			SLOG(@"looking for %@ plugins in %@", pluginBundleSuffix, nthFolder);

				/* enumerate items in each plug-in location */
			NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:nthFolder];
			for ( NSString *dirEnt in dirEnum ) {
				
					/* match directories with the proper suffix */
				NSDictionary *itemInfo = [dirEnum fileAttributes];
				if ( [itemInfo objectForKey:NSFileType] == NSFileTypeDirectory ) {
					
						/* check for matching suffix in name */
					if ( [dirEnt hasSuffix: pluginBundleSuffix] ) {
							
							/* create a path to the plugin */
						NSString *pluginPath = [NSString stringWithFormat:@"%@/%@", nthFolder, dirEnt];
						
						SLOG(@"found plugin %@", pluginPath);
						
							/* add matching items to the result */
						[pluginBundlePaths addObject: pluginPath ];
					}
					
						/* do not iterate contents of directories */
					[dirEnum skipDescendents];
					
				}
			}
		}
	}
	
		/* return array of paths */
	return (NSArray *) pluginBundlePaths;
}



@end
