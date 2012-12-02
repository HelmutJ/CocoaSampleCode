FancyAbout
==========

FancyAbout is an example Cocoa application that displays a plain, borderless “About…” panel and illustrates several techniques to achieve a particular appearance:
• programmatically constructing a window with no title bar
• making a window disappear when the user clicks in it (or clicks in other windows or other applications)
• smooth, animated scrolling of text

If you’re considering using this style of panel, keep in mind that the Application Kit offers a standard “About…” panel that is easy to invoke (see NSApplication’s orderFrontStandardAboutPanel: method) and that displays a panel that looks just like panels put up by most applications. In addition, if your panel provides information that the user may want to select and copy, such as an email address for technical support, they will find it frustrating when clicking to select something makes the window go away!

Even if you choose not to use a panel like this in your application, you can still adopt other techniques from this example, such as creating a borderless window and animating the scrolling of text.


Using this application

• Launch it
• Select “About FancyAbout” from the Apple menu (or click the “Show About Panel” button)
• Click anywhere on the screen to dismiss the About… panel
• Repeat as necessary
• Try clicking the second button, to visualize how the scrolling works.


Techniques illustrated by this application

Creating a window in code (as opposed to loading it from a nib) (see first part of the method createPanelToDisplay)

The code creates a window using NSWindow’s initWithContentRect:styleMask:backing:defer:. To get the minimalist look of an all-white About… panel with no title bar, it:

• passes NSBorderlessWindowMask for the styleMask: argument
• uses setBackgroundColor: to make the panel’s background white
• uses setHasShadow: to give the window an Aqua drop-shadow


Moving one window’s contents to another
(see second part of the method createPanelToDisplay)

To create a window with no title bar takes just a few lines of code — but it would take a lot of code to then fill in the contents of that window.

To create a window full of text and controls is easy in Interface Builder — but IB can’t create a window with no title bar.

To reduce the programming effort, the application takes the best of both worlds: It takes a titled window from a nib file and copies its contents to an untitled one it creates. This means you can easily modify the nib file using IB, and those modifications will appear in the programmatically-created window.

The two windows are panelInNib (an outlet, loaded from the nib file) and panelToDisplay (not an outlet, and created in code as described above). The code that creates panelToDisplay steals the frame and backing type from panelInNib. This means you can change the frame and backing type of the displayed window by changing those attributes of the window in the nib file.

To move the content of the old, titled window to the new, untitled one, the code:
- retains the old window’s content view
- removes the content view from the old window
- sets the new windows content view to that content view
- releases the content view (to balance the retain above)


Obtaining an application’s version information
(see the method displayVersionInfo)

Applications usually include their version number or other release information in the About panel, so users can better report problems or submit enhancement requests.

Most development environments let you enter this information in just one place, so you don’t have to remember to update your About panel’s nib file each time you release a new version. But you still need to show that information in the user interface, so the code asks the application’s “info dictionary” like this:
value = [[NSBundle mainBundle]
objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
if (value != nil)
{
[shortInfoField setStringValue: value];
}


Making the panel disappear
The About… panel used in this application has no close button or other controls (such as “OK” or “Cancel” buttons) that would obviously close the window. Instead of making the user experiment to learn how to dismiss it, this implementation makes the window disappear no matter what the user does. In particular, it disappears:
• when the user presses any key
• when the user clicks it
• when the user clicks other windows
• when the user activates another app

Below are some details on how it does each of the above.

Making the panel disappear — when the user presses any key
(see the method handlesKeyDown:inWindow:)

To learn when the user presses a key, it seems overly complex to hook into NSApplication’s event handling. Instead, it would be nice to make the About… panel become the key window, so it can process any keystrokes. Ordinarily, the AppKit will not allow a window without a title bar to become the key window, so this application subclasses NSPanel to create NSFancyPanel.

Once the panel is the key window, things are still tricky, because keystrokes ordinarily route to views and other parts of the responder chain. To make sure to process keystrokes the way we want, NSFancyPanel overrides sendEvent:, which gets invoked early in routing events such as keystrokes. The implementation checks for a keydown event and, if it finds one, tries to send a handlesKeyDown:inWindow: message to its controller.

AboutPanelController’s implementation of handlesKeyDown:inWindow: always processes the keystroke, hiding the panel, then returning YES to prevent the panel from doing normal processing. Your implementation could be more refined, perhaps processing only the Escape key to dismiss the panel.

(Not every keystroke goes through sendEvent:; command-key equivalents are an exception, and thus don’t cause the panel to disappear.)


Making the panel disappear — when the user clicks it
(see the method handlesMouseDown:inWindow:)

The panel handles mouse clicks (both left- and right-clicks) much like it handles keystrokes. The overridden implementaion of sendEvent: consults the delegate, and the delegate always handles the event by hiding the panel.


Making the panel disappear — when the user clicks other windows
(see the method watchForNotificationsWhichShouldHidePanel)

awakeFromNib invokes watchForNotificationsWhichShouldHidePanel, which watches for NSWindowDidResignMainNotification. If that notification arrives, the application knows that some other window has become the main window, and hides the About... panel.


Making the panel disappear — when the user activates another app
(see the method watchForNotificationsWhichShouldHidePanel)

The watchForNotificationsWhichShouldHidePanel method also watches for NSApplicationWillResignActiveNotification. If that notification arrives, the application knows that some other app has become active, and hides the About... panel.

This is not the same as making the About… panel automatically hide by sending setHidesOnDeactivate:YES — that technique would make the panel hide when the app was no longer active, but then when the app returned to being active, the panel would reappear, a behavior we don’t want for this panel.

Animated scrolling of text
(see the methods startScrollingAnimation, stopScrollingAnimation, setScrollAmount, and scrollOneUnit)

There are several ways to make text scroll, including techniques with a custom view subclass. To keep things simple, this application just puts the text inside an NSScrollView, hides the scroller, and uses a timer to regularly advance the amount by which the text is scrolled.

Scrolling to the end of some text usually means the last line of text is at the bottom of the scrolling area, still in sight. To make the supplied text scroll completely out of sight (like movie credits do), the method loadTextToScroll adds a bunch of blank lines at the end. This solution is not elegant, but works well in practice.

The actual scrolling gets done in scrollOneUnit, which gets invoked regularly from an NSTimer object. It finds the current scroll amount, adds a small increment to it, and updates the scrolling.

If you have anything (such as a logo) placed in front of the scrolling area, it will not redraw on its own when you scroll the text. This is why setScrollAmount: calculates where the scroll-view is in the panel and forces that whole window to redraw. (Try commenting out this code. The Apple logo will slide with the text, because a scrollview’s default behavior is to scroll by copying pixels in the window.)

To see how the scrolling works, click the button “Show About Panel, including scroller in text”, and you can see the scroller moving. This can help you visualize how the scrolling works in the usual (no scroller) case.


Using this functionality in your application

This application does a bunch of things, and you may not want to incorporate all of them in your application, but it’s probably easiest to incorporate everything and then remove what you don’t like. To incorporate all of the functionality:

(1) add these files to your project’s classes:
AboutPanelController.m and .h
NSFancyPanel.m and .h

(2) add these to your project’s resources:
README.txt
AboutPanel.nib  (remember, it’s inside en.lproj)

(3) Add this method to your application’s main controller class (.m and .h files):
- (IBAction) orderFrontCustomAboutPanel: (id) sender
{
[[AboutPanelController sharedInstance] showPanel];
}

(4) Open the main nib file, parse your updated controller header file, and connect your About MyApplication menu item to the orderFrontCustomAboutPanel: action in your controller object.

(5) Build and run the application. The About MyApplication menu item should show the panel, including this README’s text scrolling by.

You can then change things to your liking:
• changing the contents of the README.rtf file
• using a file with some name other than README.rtf
• adjusting SCROLL_DELAY_SECONDS and SCROLL_AMOUNT_PIXELS
• adding other content to the nib file or changing the size of its window
• having displayVersionInfo show other information


===========================================================================
BUILD REQUIREMENTS

Xcode 4.3, Mac OS X 10.7.x or later

===========================================================================
RUNTIME REQUIREMENTS

Mac OS X 10.6.x or later

===========================================================================
CHANGES FROM PREVIOUS VERSIONS

1.2 - Upgraded to Xcode 4.3 and Mac OS X 10.7
1.1 - Project updated for Xcode 4.
1.0 - Initial Version

===========================================================================
Copyright (C) 2003-2012 Apple Inc. All rights reserved.