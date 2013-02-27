/*

File: ServiceWatcher.h

Abstract: This class registers for notifications from IMService. It takes
incoming notifications and processes them into their respective AB cards,
which the PeopleDataSource then responds to.

Version: 1.0

Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
Computer, Inc. ("Apple") in consideration of your agreement to the
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
Neither the name, trademarks, service marks or logos of Apple Computer,
Inc. may be used to endorse or promote products derived from the Apple
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

Copyright © 2006 Apple Computer, Inc., All Rights Reserved

*/ 

#import "ServiceWatcher.h"
#import <InstantMessage/IMService.h>
#import <AddressBook/AddressBook.h>

NSString * kAddressBookPersonStatusChanged = @"AddressBookPersonStatusChanged";

@implementation ServiceWatcher

- (void) startMonitoring
{
	NSNotificationCenter * nCenter = [IMService notificationCenter];

	[nCenter addObserver: self
				selector: @selector(imServiceStatusChangedNotification:)
					name: IMServiceStatusChangedNotification
				  object: nil];

	[nCenter addObserver: self
				selector: @selector(imPersonStatusChangedNotification:)
					name: IMPersonStatusChangedNotification
				  object: nil];
	
	[nCenter addObserver: self
				selector: @selector(imPersonInfoChangedNotification:)
					name: IMPersonInfoChangedNotification
				  object: nil];
	
	[nCenter addObserver: self
				selector: @selector(imStatusImagesChangedAppearanceNotification:)
				    name: IMServiceStatusChangedNotification
				  object: nil];
}

- (void) stopMonitoring
{
	NSNotificationCenter * nCenter = [IMService notificationCenter];

	[nCenter removeObserver: self];
}

- (void) awakeFromNib
{
	[self startMonitoring];
}


#pragma mark -
#pragma mark Notifications
/*! Received from IMService's custom notification center. Posted when the user logs in, logs off, goes away, and so on. 
	This notification is relevant to no particular object. The user information dictionary will not contain keys. The client 
	should call <tt>status</tt> to get the new status. */
- (void) imServiceStatusChangedNotification:(NSNotification *)notification
{
	
}

/*! Received from IMService's custom notification center. Posted when a different user (screenName) logs in, logs off, goes away, 
	and so on. This notification is for the IMService object.The user information dictionary will always contain an 
	IMPersonScreenNameKey and an IMPersonStatusKey, and no others. */
- (void) imPersonStatusChangedNotification:(NSNotification *)notification
{
	IMService * service = [notification object];
	NSDictionary * userInfo = [notification userInfo];
	NSString * screenName = [userInfo objectForKey: IMPersonScreenNameKey];
	
	NSArray * abPersons = [service peopleWithScreenName: screenName];

	for (ABPerson * person in abPersons)
		[[NSNotificationCenter defaultCenter] postNotificationName: kAddressBookPersonStatusChanged
															object: person];
}

/*! Received from IMService's custom notification center. Posted when a screenName changes some aspect of their published information. 
	This notification is for the IMService object. The user information dictionary will always contain an IMPersonScreenNameKey and may 
	contain any of the following keys as described by "Dictionary Keys" in this document: <tt>IMPersonStatusMessageKey, IMPersonIdleSinceKey, 
	IMPersonFirstNameKey, IMPersonLastNameKey, IMPersonEmailKey, IMPersonPictureDataKey, IMPersonAVBusyKey, IMPersonCapabilitiesKey</tt>.
	If a particular attribute has been removed, the value for the relevant key will be NSNull.*/
- (void) imPersonInfoChangedNotification:(NSNotification *)notification
{
	IMService * service = [notification object];
	NSDictionary * userInfo = [notification userInfo];
	
	NSString * screenName = [userInfo objectForKey: IMPersonScreenNameKey];
	
	NSArray * abPersons = [service peopleWithScreenName: screenName];
	
	for (ABPerson * person in abPersons)
		[[NSNotificationCenter defaultCenter] postNotificationName: kAddressBookPersonStatusChanged
															object: person];
}

/*! Received from IMService's custom notification center. Posted when the user changes their preferred images for displaying status. 
	This notification is relevant to no particular object. The user information dictionary will not contain keys. Clients that display 
	status information graphically (using the green/yellow/red dots) should call <tt>imageURLForStatus:</tt> to get the new image. 
	See "Class Methods" for IMService in this document. */
- (void) imStatusImagesChangedAppearanceNotification:(NSNotification *)notification
{
}

@end
