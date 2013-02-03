DerivedProperty
===============

This example illustrates two concepts:

1) Using a Derived Property in Core Data

    The 'LogEntry' entity in the sample model contains two fields; 'regularText' is the text as it was entered by the user. 'normalizedText' is a normalized representation of the text stored as a derived property.
    
2) Using a Value Transformer to override a predicate in a search field

    The search field is bound to create the predicate 'normalizedText contains $value' 
    But value is unnormalized, so we  use a value transformer to recreate the predicate with a normalized version of value.


Running the Sample:

- Create log entries using strings that contain different cases and accents
- Type in a search string without worrying about matching the exact accents of the original text and it should still succeed.

Additional Note:

This solution of maintaining a derived property and searching is much more efficient than using a predicate like the following in the search field

 'regularText contains[dc] $value'
 
for large data sets, each row in the regularText table will be transformed at search time. With the example solution we normalize the string once when it's created and then use it to perform a much more efficient search.

===========================================================================
BUILD REQUIREMENTS

Xcode 3.2, Mac OS X 10.6 Snow Leopard or later.

===========================================================================
RUNTIME REQUIREMENTS

Mac OS X 10.6 Snow Leopard or later.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS

Version 1.2
- Project updated for Xcode 4.
Version 1.1
- Updated build requirements to be Xcode 3.1 instead of 3.0.
Version 1.0
- Initial Version

===========================================================================
Copyright (C) 2008-2011 Apple Inc. All rights reserved.
