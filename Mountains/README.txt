------------------ LocalizedMountains ------------------

LocalizedMountains is a small application which demonstrates how to
internationalize and localize an application.

Some of the techniques illustrated are:

Using localized strings and other data;

Getting data from an NSLocale;

Using an NSLocale with other classes such as NSDateFormatter to generate
appropriately localized results;

Creating a custom locale that overrides some settings from the user-set
locale; and

Embedding parameter ordering information in the format string used with
+[NSString stringWithFormat:(NSString*)format...].

LocalizedMountains has two classes: Mountain and MountainsController.

The Mountain class is a simple key-value coded class that holds three
pieces of information about a particular mountain: its name, its height
(in meters), and the date it was first climbed (if known).  These are
represented using an NSString, NSNumber, and NSDate, respectively.

The MountainsController class coordinates the user interface.  It has a
list of mountains and uses a table view to let the user select one.  It
also allows the user to override the locale's calendar.

There are six localizations provided:  en (English), fr (French), ru
(Russian), ja (Japanese), zh_Hant (traditional Chinese), and en-Dsrt
(Deseret).  The Deseret localization is provided to illustrate that
users are not limited to the locales built into the system.

Each localization contains four files: InfoPlist.strings (the localized
messages used by AppKit to display copyright information), MainMenu.nib
(the nib), Mountains.plist (a locale-specific list of interesting
mountains), and Mountains.strings (localized strings).
