/*
 File: MyPeoplePickerController.m
 
 Abstract: Definitions for the MyPeoplePickerController object.
 
 Version: <1.1>
 
 Disclaimer:	IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc.
 ("Apple") in consideration of your agreement to the following terms, and your
 use, installation, modification or redistribution of this Apple software
 constitutes acceptance of these terms.  If you do not agree with these terms,
 please do not use, install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject
 to these terms, Apple grants you a personal, non-exclusive license, under Apple’s
 copyrights in this original Apple software (the "Apple Software"), to use,
 reproduce, modify and redistribute the Apple Software, with or without
 modifications, in source and/or binary forms; provided that if you redistribute
 the Apple Software in its entirety and without modifications, you must retain
 this notice and the following text and disclaimers in all such redistributions of
 the Apple Software.  Neither the name, trademarks, service marks or logos of
 Apple Computer, Inc. may be used to endorse or promote products derived from the
 Apple Software without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or implied,
 are granted by Apple herein, including but not limited to any patent rights that
 may be infringed by your derivative works or by other works in which the Apple
 Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
 WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
 WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
 COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION
 OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF CONTRACT, TORT
 (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 Copyright (C) 2003-2010 Apple Inc. All Rights Reserved.
 */


#import "MyPeoplePickerController.h"
#import <AddressBook/ABGroup.h>
#import <AddressBook/ABGlobals.h>

@implementation MyPeoplePickerController

- (IBAction)getGroups:(id)sender
{
    NSArray *groups = [ppView selectedGroups];
    NSLog(@"getGroups: %i groups selected", [groups count]);
    int index;
    for(index=0; index<[groups count]; index++) {
        NSLog(@"  Group %i: %@", index, [(ABRecord *)[groups objectAtIndex:index] uniqueId]);
    }  
}

// get the records (people) currently selected in the view and iterate through
- (IBAction)getRecords:(id)sender
{
    NSArray *records = [ppView selectedRecords];
    NSLog(@"getRecords: %i records selected", [records count]);
    int index;
    for(index=0; index<[records count]; index++) {
        NSLog(@"  Record %i: %@", index, [(ABRecord *)[records objectAtIndex:index] uniqueId]);
    }
}


// Activate specific values for display
- (IBAction)viewProperty:(NSButton *)sender {
    NSString *property;
    // See MainMenu.nib for the corresponding checkbox tags.
    switch ([sender tag]) {
        case 0: // Phone
            property = kABPhoneProperty;
            break;
        case 1: // Address
            property = kABAddressProperty;
            break;
        case 2: // Email
            property = kABEmailProperty;
            break;
        case 3: // AIM
            property = kABAIMInstantProperty;
            break;
        case 4: // Homepage
            property = kABHomePageProperty;
            break;            
        default:
			 property = kABHomePageProperty;
            break;
    } 
    if ([sender state] == NSOnState) {
        [ppView addProperty:property];
    } else {
        [ppView removeProperty:property];
    }
}


// [dis]allows groupSelection in our peoplepicker.
- (IBAction)setGroupSelection:(NSButton *)sender {
    [ppView setAllowsGroupSelection:([sender state] == NSOnState)];
}

- (IBAction) setMultiRecordSelection:(NSButton *)sender {
    [ppView setAllowsMultipleSelection:([sender state] == NSOnState)];
}

- (IBAction)editInAB:(id)sender {
    [ppView editInAddressBook:sender];
}

- (IBAction)selectInAB:(id)sender {
    [ppView selectInAddressBook:sender];
}

@end
