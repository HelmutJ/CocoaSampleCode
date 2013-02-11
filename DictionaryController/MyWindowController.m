/*
     File: MyWindowController.m 
 Abstract: Tthis sample's primary NSWindowController. 
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
  
 Copyright (C) 2011 Apple Inc. All Rights Reserved. 
  
 */

#import "MyWindowController.h"

@implementation MyWindowController

@synthesize currentPerson;

// the keys to our array controller to be displayed in the table view,
#define KEY_LAST	@"lastName"
#define KEY_FIRST	@"firstName"

// -------------------------------------------------------------------------------
//	awakeFromNib:
// -------------------------------------------------------------------------------
- (void)awakeFromNib
{
	NSBundle *bundle = [NSBundle mainBundle];
	NSString *path = [bundle pathForResource: @"people" ofType: @"dict"];
	NSArray *listFromFile = [NSArray arrayWithContentsOfFile: path];

	[tableView setSortDescriptors:[NSArray arrayWithObjects:[[[NSSortDescriptor alloc] initWithKey:@"lastName" ascending:YES] autorelease],
																 [[[NSSortDescriptor alloc] initWithKey:@"firstName" ascending:YES] autorelease],
																 nil]];
															  
	[peopleList addObserver:self forKeyPath:@"selectionIndexes" options:NSKeyValueObservingOptionNew context:nil];
	
	// read the list of PEOPLE from disk in 'people.dict'
	if (listFromFile != nil)
	{
		[peopleList addObjects:listFromFile];
	}
	
	// select the first person in the table
	[peopleList setSelectionIndex:0];
	
	// bind the "currentPerson" dictionary to our dictionary controller
	[dictController bind:NSContentDictionaryBinding toObject:self withKeyPath:@"currentPerson" options:nil];
	// another way is:
	// [dictController setContent:entry];
	// but that would tie the content to the current dictionary instance
	// binding the dictionary means that if we replace the dictionary itself with a new one
	// the content of the dictionary controller will be updated as well
	
	// load 2 localized key strings for display in the table to the right,
	// note: we could use localized keys for the "entire" dictionary but we are
	// illustrating here to be selective with only two keys
	//
	NSString *firstNameLocalizedKey = NSLocalizedString(@"firstName", @"");
	NSString *lastNameLocalizedKey = NSLocalizedString(@"lastName", @"");
	[dictController setLocalizedKeyDictionary:
		[NSDictionary dictionaryWithObjectsAndKeys: firstNameLocalizedKey, KEY_FIRST,
													lastNameLocalizedKey, KEY_LAST,
													nil]];
													
	// note: each person has one "excluded key" called "id",
	// which we could use as private data - not to be displayed to the user.
}

// -------------------------------------------------------------------------------
//	dealloc:
// -------------------------------------------------------------------------------
- (void)dealloc
{
    self.currentPerson = nil;	// causes a release
	[super dealloc];
}

// -------------------------------------------------------------------------------
//	sortDesc:
// -------------------------------------------------------------------------------
- (NSArray *)sortDesc
{
	return [tableView sortDescriptors];
}

// -------------------------------------------------------------------------------
//	observeValueForKeyPath:keyPath:object:change:context
// -------------------------------------------------------------------------------
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	// has the array controller's "selectionIndexes" binding changed?
	if (object == peopleList)
	{
		if ([[object selectedObjects] count] > 0)
		{
			// update our current person and reflect the change to our dictionary controller
			[self setCurrentPerson: [[object selectedObjects] objectAtIndex:0]];
			[dictController bind:NSContentDictionaryBinding toObject:self withKeyPath:@"currentPerson" options:nil];
		}
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

@end
