AddressBookCocoa
This sample demonstrates how to create, access, add, search, and retrieve Address Book records using Address Book's Objective-C APIs. It defines and implements the addElba and findElba methods to perform these tasks.
The addElba method creates a person named Elba, sets its first and last name, address, and phone number information, and adds him to the Address Book. The findElba method looks for Elba in Address Book using the searchElementForPropert method and fetches his first name, street address, and work fax number.


Build requirements
Xcode 3.0 or later 

Runtime requirements
Mac OS X 10.4 or later


Using the Sample
Build and run this sample using Xcode 3.0 or later .
The application shows the first and last name, address, and phone number of a contact named Elba. 
Click on the "Add this person to ..." button to add Elba to your Address Book. 
Click on the "Find this info for... " button to retrieve Elba's first name, street address, and work fax number.



Further Reading
Address Book Programming Guide
<http://developer.apple.com/documentation/UserExperience/Conceptual/AddressBook/AddressBook.html>

Change from Previous Versions
-Upgraded to support Xcode 3.0 or later.
-Set Base SDK and Deploypment Target to Mac OS X 10.5 and Mac OS X 10.4, respectively.


Copyright (C) 2002-2010 Apple Inc. All rights reserved.