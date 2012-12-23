/*
     File: MyWindowController.m 
 Abstract: The sample's main NSWindowController controlling its primary window.
  
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

#import "MyWindowController.h"
#import "EditController.h"

#define kUse_Bindings_By_Code	0		// this signifies that bindings will be established
										// in code instead of from the nib file

@implementation MyWindowController

// -------------------------------------------------------------------------------
//	awakeFromNib
// -------------------------------------------------------------------------------
- (void)awakeFromNib
{
	// Your NSTableView's content needs to use Cocoa Bindings,
	// use Interface Builder to setup the bindings like so:
	//
	// Each column in the NSTableView needs to use Cocoa Bindings,
	// use Interface Builder to setup the bindings like so:
	//
	//		columnIdentifier: "firstname"
	//			"value" = arrangedObjects.firstname [NSTableArray (NSArrayController)]
	//				Bind To: "TableArray" object (NSArrayController)
	//				Controller Key = "arrangedObjects"
	//				Model Key Path = "firstname" ("firstname" is a key in "TableArray")
	//
	//		columnIdentifier: "lastname"
	//			"value" = arrangedObjects.lastname [NSTableArray (NSArrayController)]
	//				Bind To: "TableArray" object (NSArrayController)
	//				Controller Key = "arrangedObjects"
	//				Model Key Path = "lastname" ("lastname" is a key in "TableArray")
	//
	//		columnIdentifier: "phone"
	//			"value" = arrangedObjects.phone [NSTableArray (NSArrayController)]
	//				Bind To: "TableArray" object (NSArrayController)
	//				Controller Key = "arrangedObjects"
	//				Model Key Path = "phone" ("phone" is a key in "TableArray")
	//
	// or do bindings by code:
#if kUse_Bindings_By_Code
	NSTableColumn *firstNameColumn = [myTableView tableColumnWithIdentifier:@"firstname"];
	[firstNameColumn bind:@"value" toObject:myContentArray withKeyPath:@"arrangedObjects.firstname" options:nil];
	
	NSTableColumn *lastNameColumn = [myTableView tableColumnWithIdentifier:@"lastname"];
	[lastNameColumn bind:@"value" toObject:myContentArray withKeyPath:@"arrangedObjects.lastname" options:nil];
	
	NSTableColumn *phoneColumn = [myTableView tableColumnWithIdentifier:@"phone"];
	[phoneColumn bind:@"value" toObject:myContentArray withKeyPath:@"arrangedObjects.phone" options:nil];
#endif	
	
	// for NSTableView "double-click row" to work you need to use Cocoa Bindings,
	// use Interface Builder to setup the bindings like so:
	//
	//	NSTableView:
	//		"doubleClickArgument":
	//			Bind To: "TableArray" object (NSArrayController)
	//				Controller Key = "selectedObjects"
	//				Selector Name = "inspect:" (don't forget the ":")
	//
	//		"doubleClickTarget":
	//			Bind To: (File's Owner) MyWindowController
	//				Model Key Path = "self"
	//				Selector Name = "inspect:" (don't forget the ":")
	//
	//	... also make sure none of the NSTableColumns are "editable".
	//
	// or do bindings by code:
#if kUse_Bindings_By_Code
	NSDictionary *doubleClickOptionsDict = [NSDictionary dictionaryWithObjectsAndKeys:
												@"inspect:", @"NSSelectorName",
												[NSNumber numberWithBool:YES], @"NSConditionallySetsHidden",
												[NSNumber numberWithBool:YES], @"NSRaisesForNotApplicableKeys",
												nil];
	[myTableView bind:@"doubleClickArgument" toObject:myContentArray withKeyPath:@"selectedObjects" options:doubleClickOptionsDict];
	[myTableView bind:@"doubleClickTarget" toObject:self withKeyPath:@"self" options:doubleClickOptionsDict];
#endif

	// the enabled states of the two buttons "Add", "Remove" are bound to "canRemove" 
	// use Interface Builder to setup the bindings like so:
	//
	//	NSButton ("Add")
	//		"enabled":
	//			Bind To: "TableArray" object (NSArrayController)
	//				Controller Key = "canAdd"
	//
	//	NSButton ("Remove")
	//		"enabled":
	//			Bind To: "TableArray" object (NSArrayController)
	//				Controller Key = "canRemove"
	//
	// or do bindings by code:
#if kUse_Bindings_By_Code
	NSDictionary *enabledOptionsDict = [NSDictionary dictionaryWithObjectsAndKeys:
										[NSNumber numberWithBool:YES], @"NSRaisesForNotApplicableKeys",
										nil];
	[addButton bind:@"enabled" toObject:myContentArray withKeyPath:@"canAdd" options:enabledOptionsDict];
	[removeButton bind:@"enabled" toObject:myContentArray withKeyPath:@"canRemove" options:enabledOptionsDict];
#endif

	// the NSForm's text fields is bound to the current selection in the NSTableView's content array controller,
	// use Interface Builder to setup the bindings like so:
	//
	//	NSFormCell:
	//		"value":
	//			Bind To: "TableArray" object (NSArrayController)
	//				Controller Key = "selection"
	//				Model Key Path = "firstname"
	//
	// or do bindings by code:
#if kUse_Bindings_By_Code
	NSDictionary *valueOptionsDict = [NSDictionary dictionaryWithObjectsAndKeys:
										[NSNumber numberWithBool:YES], @"NSAllowsEditingMultipleValuesSelection",
										[NSNumber numberWithBool:YES], @"NSConditionallySetsEditable",
										[NSNumber numberWithBool:YES], @"NSRaisesForNotApplicableKeys",
										nil];
	[[myFormFields cellAtIndex: 0] bind:@"value" toObject:myContentArray withKeyPath:@"selection.firstname" options:valueOptionsDict];
	[[myFormFields cellAtIndex: 1] bind:@"value" toObject:myContentArray withKeyPath:@"selection.lastname" options:valueOptionsDict];
	[[myFormFields cellAtIndex: 2] bind:@"value" toObject:myContentArray withKeyPath:@"selection.phone" options:valueOptionsDict];
#endif
	
	// start listening for selection changes in our NSTableView's array controller
	[myContentArray addObserver: self
					forKeyPath: @"selectionIndexes"
					options: NSKeyValueObservingOptionNew
					context: NULL];

	// finally, add the first record in the table as a default value.
	//
	// note: to allow the external NSForm fields to alter the table view selection through the "value" bindings,
	// added objects to the content array needs to be an "NSMutableDictionary" -
	//
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									 @"Joe", @"firstname",
									 @"Smith", @"lastname",
									 @"(444) 444-4444", @"phone",
									 nil];
	[myContentArray addObject: dict];
	
	// note: you can turn off column sorting by using the following
	//	[myTableView unbind:@"sortDescriptors"];
}

// -------------------------------------------------------------------------------
//	observeValueForKeyPath:ofObject:change:context:
//
//	This method demonstrates how to observe selection changes in our NSTableView's
//	array controller.
// -------------------------------------------------------------------------------
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	NSLog(@"Table section changed: keyPath = %@, %@", keyPath, [object selectionIndexes]);
}

// -------------------------------------------------------------------------------
//	dealloc
// -------------------------------------------------------------------------------
- (void)dealloc
{
	[myEditController release];
	
	[super dealloc];
}

// -------------------------------------------------------------------------------
//	inspect:selectedObjects
//
//	Inspect our selected objects (user double-clicked them).
//
//  Note: this method will not get called until you make all columns in the table
//	as "non-editable".  So long as they are editable, double clicking a row will
//	cause the current cell to be editied.
// -------------------------------------------------------------------------------
- (void)inspect:(NSArray *)selectedObjects
{
	// handle user double-click
	
	// this is an example of inspecting each selected object in the selection
	NSUInteger index;
	NSUInteger numItems = [selectedObjects count];
	for (index = 0; index < numItems; index++)
	{
		NSDictionary *objectDict = [selectedObjects objectAtIndex:index];
		if (objectDict != nil)
		{
			NSLog(@"inspect item: {%@ %@, %@}",
				  [objectDict valueForKey:@"firstname"],
				  [objectDict valueForKey:@"lastname"],
				  [objectDict valueForKey:@"phone"]);
		}
	}
	
	// setup the edit sheet controller if one hasn't been setup already
	if (myEditController == nil)
		myEditController = [[EditController alloc] init];
	
	// remember which selection index we are changing
	NSUInteger savedSelectionIndex = [myContentArray selectionIndex];

	// get the current selected object and start the edit sheet
	NSDictionary *editItem = [selectedObjects objectAtIndex:0];
	NSDictionary *newValues = [myEditController edit:editItem from:self];
	
	if (![myEditController wasCancelled])
	{
		// remove the current selection and replace it with the newly edited one
		NSArray *selectedObjects = [myContentArray selectedObjects];
		[myContentArray removeObjects:selectedObjects];
	
		// make sure to add the new entry at the same selection location as before
		[myContentArray insertObject:newValues atArrangedObjectIndex:savedSelectionIndex];   
	}
}

// -------------------------------------------------------------------------------
//	add:sender
// -------------------------------------------------------------------------------
- (IBAction)add:(id)sender
{
	if (myEditController == nil)
		myEditController = [[EditController alloc] init];
	
	// ask our edit sheet for information on the record we want to add
	NSDictionary *newValues = [myEditController edit:nil from:self];
	if (![myEditController wasCancelled])
	{
		[myContentArray addObject: newValues];
	}
}

// -------------------------------------------------------------------------------
//	remove:sender
// -------------------------------------------------------------------------------
- (IBAction)remove:(id)sender
{
	[myContentArray removeObjectAtArrangedObjectIndex:[myContentArray selectionIndex]];
}

@end
