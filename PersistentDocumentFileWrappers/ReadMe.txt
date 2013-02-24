
NSPersistentDocumentFileWrappers

This sample demonstrates how you can use directory wrappers with NSPersistentDocument.


A directory wrapper allows you to adopt a package format for your documents.  Document packages give the illusion of a single document to users but provide you with more flexibility in how you store the document data internally(*).

The default implementation of NSPersistentDocument does not support document packages, but it may be useful for some Core Data-based documents to be able to use a package format.  For example, it may be preferable to store image data as separate files rather than embedding that data in the persistent store. 

This sample offers a work-around that you can use in your own projects -- but there is one issue that you need to consider: atomicity during writes.  The principle concern here is that a save operation may be partially, rather than wholly, successful.

If a save operation does not complete successfully, you must decide for yourself what is the appropriate action to take, with consideration for how it will affect the application, and how best to recover. For example, what should happen if the file wrapper saves successfully, but the managed object context fails to save?  Depending on the application, it may be necessary to roll-back or take other steps. 

You may be able to assure atomicity in exchange for performance, by saving the document to a temporary location, and then -- if successful -- replacing the old file with the new.  In the case of very large documents, this could be a slow operation.  Moreover, you must ensure that the "temporary" location resides on the same file system as the original file -- otherwise the replacement cannot be atomic. (The simplest approach would be to locate the temporary file in the same directory as the original, using a different file extension.)



(*) For more about directory wrappers and document packages, see:
"Working With Directory Wrappers" in Reference Library > Guides > Cocoa > File Management > Application File Management
<http://developer.apple.com/documentation/Cocoa/Conceptual/AppFileMgmt/AppFileMgmt.html>
and
"Document Packages" in Reference Library > Guides > Core Foundation > Resource Management > Bundle Programming Guide >
<http://developer.apple.com/documentation/CoreFoundation/Conceptual/CFBundles/CFBundles.html>

