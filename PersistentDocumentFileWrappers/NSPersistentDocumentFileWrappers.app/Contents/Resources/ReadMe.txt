NSPersistentDocumentFileWrappers

This sample demonstrates how directory file wrappers can be used with NSPersistentDocument. A directory file wrapper allows you to adopt a package format for your documents. Document packages give the illusion of a single document to users but provide you with more flexibility in how you store the document data internally (see http://developer.apple.com/documentation/CoreFoundation/Conceptual/CFBundles/Concepts/DocumentBundles.html).

The standard implementation of NSPersistentDocument does not support this functionality, but it may be useful for some Core Data Documents to be able to use a package format. For example, it may be preferable to store image data as separate files rather than embedding that data in the persistent store. 

This sample offers a work-around that developers can use in their own projects but there is one caveat that should be considered, which is the issue of atomicity during writes. This is discussed in more detail at the end of the ReadMe.

Atomicity during writes:

The principle concern here is that a save operation may be partially, rather than wholly, successful. The appropriate action in this case must be determined by the developer, with consideration for how it will affect his application, and how best to recover. Should the file wrapper save successfully, but the managed object context fail to save, what then? Depending on the application, it may be necessary to roll-back or take other steps. 

Atomicity could be assured in exchange for performance by saving the document to a temporary location, and then - if successful, replacing the old file with the new. However, in the case of very large documents, this could also be a slow operation. The developer will have to choose between speed and atomicity.