QuickLookDownloader
v1.0

QuickLookDownloader manages file downloads from the internet, displaying thumbnail images in the download list and high-detail previews using the new QLPreviewPanel class in Snow Leopard.  This application demonstrates the two methods for displaying Quick Look content inside your application.

DownloadItem.m shows how to asynchronously get the Quick Look thumbnail for a file.

AppDelegate.m shows how to open and close the Quick Look panel. The standard menu shortcut for the Quick Look panel is ⌘-Y but the user should also be able to use the space key.

MyDocument.m shows how to control and provide the delegate and data source of the Quick Look panel.

DownloadsTableView.m subclasses NSTableView to handle the space key and open the Quick Look panel.

Build requirements
Xcode 3.2 or later

Runtime requirements
Mac OS X v10.6 or later

Using the Sample
Build and run this sample using Xcode 3.2 or later.

Enter the URL of a file that's capable of being previewed, e.g. http://developer.apple.com/documentation/UserExperience/Conceptual/AppleHIGuidelines/OSXHIGuidelines.pdf

Once the download is complete, observe how the standard document icon is replaced by a Quick Look thumbnail.  Select the file in the table and hit the space bar to show the document in the Quick Look preview panel.

Further Reading
Quick Look Reference (Snow Leopard Dev Center)
https://developer.apple.com/snowleopard/library/documentation/UserExperience/Reference/Quicklook_Framework_Reference/index.html#//apple_ref/doc/uid/TP40005021