ZipBrowser

This example shows two versions of a single application:  The original version of the application, in ZipBrowserBefore, and the polished version, in ZipBrowserAfter.

ZipBrowser is a simple document-based application used for perusing the contents of a zip archive without having to unarchive it.  The original version of the application has three classes:  a model class, ZipEntry, representing a single entry in the zip archive; a view class, ZipEntryView, used to present a single entry in the browser's preview column; and the NSDocument subclass, ZipDocument, which serves as controller and as delegate to the browser.

Each ZipEntry stores certain minimal information about the entry:  a path (the last component of which is used as a name), a location in the archive, the original uncompressed size, the size as stored compressed, the compression type, and a CRC.  There is an implicit tree structure to the entries in an archive, based on the paths stored in the zip archive name fields, which is used to store directory hierarchies.  This is represented by having two types of ZipEntry, leaf and non-leaf, with the non-leaf entries having an array of child entries.

The ZipEntryView displays a small subset of this information:  an icon from NSWorkspace representing the entry, the name, and the two sizes.  It draws the icon using standard NSImage methods, and it lays out and draws the strings using standard NSStringDrawing methods.

The ZipDocument class reads in the contents of an archive as a tree of ZipEntry instances, starting from a root instance.  One notable feature is that it uses the item-based NSBrowser API introduced in Mac OS X 10.6, which greatly simplifies the task of acting as an NSBrowser delegate.


Differences Between ZipBrowserBefore and ZipBrowserAfter

The modifications between ZipBrowserBefore and ZipBrowserAfter fall into six categories:  64-bit readiness, performance and responsiveness, security, localization and internationalization, usability, and accessibility.  The 64-bit readiness changes consist primarily of changing the types of various integers from unsigned or int to something more appropriate:  NSUInteger or NSInteger for those that represent types used with Cocoa interfaces, and uint32_t or uint16_t for those that represent specifically sized values taken from the zip archive data format.

The performance and responsiveness changes consist of (a) adding a FileBuffer class for file access, and (b) placing most access to this class into the background using an NSOperationQueue.  The FileBuffer class represents a simple wrapper around NSFileHandle, adding some buffering and byte swapping (the zip format is little-endian).  It is deliberately not thread-safe; instead, the application serializes it by assigning a single instance to a single-threaded NSOperationQueue.  The ZipDocument instance creates the FileBuffer for a given document, and uses it only long enough to obtain some basic information and confirm that the file does indeed look like a zip archive; after that, all access to the FileBuffer goes through the ZipDocument's NSOperationQueue.  An operation is created that calls a specific ZipDocument method to read the entries, put them on a queue, and periodically send the collected ZipEntry objects back to the main thread to be added to the document and the user interface.  In addition, NSDocument's concurrent document opening is turned on, to make opening of multiple documents concurrent with respect to each other.

The security changes consist of adding checks at each point that a value is read from the zip archive, to make sure that the value is intelligible and in range.  All offsets within the file are compared both above and below to make sure that they are reasonable, to make sure that they are not made invalid by arithmetic overflow.

The localization and internationalization changes consist of making all static strings into entries in the Localizable.strings file, using an NSNumberFormatter for formatting displayed numbers, and significantly improving the encoding support for reading names from the zip archive entries.  Zip archive entry names were originally DOS Latin US / IBM code page 437, but this was not really specified, and in practice names have simply been strings of bytes.  Mac OS X uses UTF-8, as do a number of recent zip usages; there is now a bit that can be (but isn't always) used to specify UTF-8.  To handle a variety of possible encodings, ZipBrowserAfter uses a single main document encoding (default UTF-8), followed by several fallbacks.  There is also a reopenWithEncoding: method and corresponding menu items; each such menu item specifies an NSStringEncoding as its tag, and causes the document to be re-read with the specified encoding as the new main document encoding.

The usability changes consist of adding drag support both in the browser and in the preview view.  Three pasteboard flavors are used:  file promises, for drags to Finder; filenames, for drags to other attachment-handling applications such as TextEdit; and strings, for everything else.  Creation of the dragged file is always done lazily.  Furthermore, since FileBuffer operations are defined to be on the NSOperationQueue, an operation is created to do this, which calls back to the ZipDocument to read and uncompress the entry and write it to disk.  Currently the drag code waits for the background file operation to complete, so an error can be presented immediately if necessary, but this is not essential.

The accessibility changes consist of adding an AccessibilityElement class to represent each of the elements in the ZipEntryView (one image and three strings) for accessibility purposes.  These are created lazily on demand when accessibility is in use, and they are assigned the contents and bounds of the corresponding elements.

There are some things that this example does not do, that are left as exercises to the reader.  For example, none of the possible filesystem attributes (permissions, etc.) that can potentially be stored in the archive are handled; the drag code retrieves the contents of the entry and nothing else.  Double-clicking on entries is not supported; it might be possible to add support so that this would unarchive and open that specific entry.  More generally, this example serves only as a viewer, not as an editor; no support is added for dragging files into an archive or otherwise modifying it in any way.


Changes from Previous Versions
Updated to latest Snow Leopard API, and updated Xcode project and Interface Builder file formats.


Feedback and Bug Reports
Please send all feedback about this sample by connecting to the Contact ADC page.
Please submit any bug reports about this sample to the Bug Reporting <http://developer.apple.com/bugreporter> page.


Copyright (C) 2008-2009 Apple Inc.  All rights reserved.