To build and install GLUT Framework:
------------------------------------

Launch terminal

# change to glut project directory
cd (GLUT project directory)

# build the framework into /tmp
# Note: glut should be built with gcc3 or greater
xcodebuild install 

# copy the framework and replace the existing one (note, sudo requires the admin password)
sudo ditto /tmp/GLUT_External.dst/System/Library/Frameworks/GLUT.framework /System/Library/Frameworks/GLUT.framework

NOTE: Due to archiving and unarchiving for posting of this sample code, the
libForeground.a library may have inconsistant dates (Xcode will note 
this error if it exists).  The can be fixed by running "ranlib" on this 
library as follows:

# change to glut project directory
cd (GLUT project directory)

# update Foreground.o library
ranlib libForeground.a

NOTE: Installing a software update, which contains GLUT, over top of this 
build will replace the framework built by this sample code.  Developers should 
rebuild/reinstall this development build after a software update.

GLUT for Mac OS X (GLUT-3.4.0) Read Me (4/10/2007)
===========================
Additions:
----------

*)  Support for Garbage Collection

*)  Support for HiDPI


GLUT for Mac OS X (GLUT-3.3.9) Read Me (10/10/2005)
===========================
Additions:
----------

*)  Added no_recovery support for pixel format selection.  Logic added to both
mode enums and string handling.


GLUT for Mac OS X (GLUT-3.3.8) Read Me (9/22/2005)
===========================

Bug Fixes:
----------

*)  Fixed full screen stereo handling.

*)  Fixed inverted print/save/copy images.


GLUT for Mac OS X (GLUT-3.3.7) Read Me (8/30/2005)
===========================

Additions:
----------

*)  Added support for windowed stereo.  You can still get full screen stereo by using the fullscreen APIs in GLUT.

Bug Fixes:
----------

*)  Fixed state handling in print and save along with better alpha handling.


GLUT for Mac OS X (GLUT-3.3.6) Read Me (4/7/2005)
===========================

Additions:
----------

*)  Improvement in glutGetProcAddress dyld handling.

Bug Fixes:
----------

*)  Fixed bundle detection code to allow resources for packaged GLUT apps and console apps to run seamlessly.

*)  Fixed a number of minor warnings.

*)  Fix: (3526681) slow launch due to HID devices.

*)  Fix: (3935188) Issue with lack of autorelease pool at shutdown.

*)  Fix: (3961182) GLUT project fails to build with gcc-4.0

*)  Fixed a number of minor warnings.

*)  Fix: (3495231) GLUT 3 button mouse: if 2/3 buttons depressed, not all releases registered

*)  Fix: (3481381) OpenGL Glut Framework prepareForMiniaturization

*)  Fix: (3526681) glutSetCursor not behaving as expected

*)  Fix: (3852364) GLUT keyboard input stuck keys

*)  Fix: (3928640) GLUT Prefs "Set Defaults" button does not work

*)  Fix: (3928650) GLUT Prefs can save zero height default window size

*)  Fix: (3935190) glutTimerFunc doesn't work

*)  Fix: (3450425) glutLeaveGameMode doesn't leave fullscreen

*)  Fix: (3494200) glut resize bug

*)  Fix: (3495227) GLUT callbacks to joysticks/gamepads: rarely work correctly

*)  Fix: (3569992) Convert GLUT to native Xcode

*)  Fix: (3655228) glut window visibility events are not properly generated (glutFullScreen related)

*)  Fix: (3935184) glutEnterGameMode() spews "glutEnterGameMode entered"

*)  Fix: (3935591) glutSetCursor(GLUT_CURSOR_NONE) doesn't work


GLUT for Mac OS X (GLUT-3.2.8) Read Me
===========================

Additions:
----------

*)  Spaceball support for devices with 6+ axis, fully configurable.

*)  Added ability to use -useExtendedDesktop to allow glut to consider the
    full multi-monitor desktop when doing full screen windows and for window
    location.  Note the upper left of the desktop will be consider by glut to 
    be (0, 0) no matter where the menu bar is.  Current driver issues prevent
    good spanning full screen performance at this time, but a fix is in work.
	
*)  The visibility of MacOS X specific GLUT API extensions is now controlled
    by the GLUT_MACOSX_IMPLEMENTATION pre-processor macro. By default, all
    extensions are enabled. You may however turn them off by setting
    GLUT_MACOSX_IMPLEMENTATION to 0 before including the glut.h header. That
    way its easy to check whether your GLUT application is calling MacOS X
    specific APIs or not.

*)  Packaged GLUT applications now get automatically an About dialog. The dialog
    displays the application's version information and some optional text.
    The version number is taken from the CFBundleShortVersionString from the
    Info.plist. The optional text should be stored in a file called 'Credits.rtf'
    in the application's Resource folder.
    
*)  Added glutCheckLoop() and glutWMCloseFunc() APIs based on the same functions
    developed by Mr. Rob Fletcher for the Win32 GLUT version.
    
*)  Imported glutGetProcAddress() function from the Mesa3D project.

*)  Imported GLUT_FPS environment variable from the Mesa3D project.

*)  New preferences dialog. Allows global configuration of:
    - initialization variables (will affect next window creation or app launch
      depending on scope of configuration item)
    - Mouse emulation (normally turned on if a mouse with < 3 buttons is 
      found but can be enabled manually and emulation keys are configurable)
    - Joystick setup (any device with at least two axis can be configured, one
      device only will control all joystick inputs but specific inputs can be
      rearranged)
    - Spaceball setup (same notes as joystick)
    Prefs affect all glut applications and are saved globally.  Defaults can be
    set to go back to initial conditions.  Note, joystick and spaceball
    configuration modification take place immediately while others only
    take affect after pressing OK.

Bug Fixes:
----------

1)  Switching a window to fullscreen mode and back again (glutFullscreen()) now
    works more reliably. I.e. sub-windows with installed glutMotionFunc callbacks
    should no longer stop calling the callback after executing glutFullscreen().
    
2)  GLUT no longer calls a window's mouse callback with GLUT_UP, if the user
    dismissed a context menu by clicking outside the on-screen menu.

3)  Fixes for initial sub-window focus.

4)  Fix for better menu handling

5)  Fix full screen to allow it to be entered more than once

6)  Fix button callbacks to allow destruction of a window

7)  Fix full screen sub-window handling

8)  Fix poor work event and timer interaction


GLUT for Mac OS X (GLUT-3.1) Read Me
===========================

Additions:
----------

*)  Added glutSurfaceTexture  (GLenum target, GLenum internalformat, int surfacewin)
	target: Specifies an allowable 2D OpenGL texture target such as GL_TEXTURE_2D 
		or GL_TEXTURE_RECTANGLE_EXT.
	internalformat: Specifies the internal texture layout, which must be a supported 
		format listed on table 3.15, 3.16, 3.17 or 3.18 of the OpenGL 1.3 Specification.
	surfacewin: Specifies the GLUT window from which to get the texture.

	glutSurfaceTexture allows direct texturing from a window by using the window
	contents as the source data for the texture, behaving much the same way as
	glTexImage2D. The texture target, internal format must be supported the
	renderer of the target context. Additionally, the source window geometry
	must be compatible with the texture target. Thus, if the texture target is
	GL_TEXTURE_2D, the window must conform to power of two dimensions.

	This routine is designed for performance so the graphics driver will attempt
	to provide an optimum data path, keeping the data in VRAM if possible. Also,
	there is no window tracking, thus both target and source windows must be on
	the same virtual screen (renderer) or failure (likely lack of texturing)
	will result.
    
*)  GLUT now supports the UTF8 character encoding. This means that all functions
    which take strings, interpret them in the UTF8 encoding.
    
Bug Fixes:
----------

1)  glutInit() now correctly validates the time interval values given
    to -menuIdleInterval and -fadeInterval.
    
2)  Improved GLUT shutdown. GLUT now guarantees that any atexit() handlers
    installed by the application are called before GLUT starts its own
    cleanup process. The only precondition for this to work is that the
    application installs its atexit() handlers AFTER it has called glutInit().

3)  Made showing of hidden sub-windows, which contain themselves sub-windows,
    more reliable.
    
4)  All keyboard input is now passed to GLUT apps in the UTF8 character encoding.
    One important consequence of this change is that GLUT apps should now better
    work with non-US keyboards (i.e. Alt-5 should now correctly produce a '['
    character with German keyboards).


GLUT for Mac OS X (GLUT-3.0) Read Me
===========================

Additions:
----------

*)  Added -useMacOSCoords command line argument to allow negative coords to be 
    correctly mapped to the Mac OS X desktop space.  If this is not enabled, GLUT
	functions per the spec and maps all negative coords to defaults.  If this option
	is provided all coords supplied after this option will be used as is and will
	be directly mapped the desktop (including moving the window completely off
	screen if the coords are not visible).
	
*)  Added -menuIdleInterval command line argument to set the interval for
    idle events when the menus are shown, default is 0.016 seconds.
	
*)  Added -fadeInterval command line argument to set the length of screen fades into
    and out of gamemode, default is 1.0 second.
	
*)  Added stereo support.  This requires full screen and glutGameMode.  So set 
	the pixel format to stereo and enter gamemode to get stereo contexts. Apps
	will need to draw required sync lines for whatever 3D glasses they are using,
	see developer.apple.com/samplecode for examples. Here is an initialization 
	example:
	
	  glutInit(&argc, (char **)argv);
	  
	  // stereo display mode for glut
      glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGB | GLUT_DEPTH | GLUT_STEREO);
      
      // must now use full screen game mode
	  glutGameModeString("1024x768:32@120");
	   
	  // enter gamemode to get stereo context 
	  //  (may get invalid drawable warnings in console, 
	  //   this is normal and will be fixed in the future)
	  glutEnterGameMode(); 

*)  Added complete joystick support including a configuration dialog and multi-device
    support.  To avoid strange axis and button mappings GLUT looks for devices which
    report themselves as joystick or gamepad.

*)  Added better multi-button mouse support.  Should now use 3 native buttons with mice
    which have 3 buttons or more and emulate (cntl-click = right click, opt-click = 
    middle click) with mice which have 1 or 2 buttons.  The three buttons glut looks for
    are left, right and other in Cocoa or button 1,2 and 3 in HID terms, if a 
    custom mouse driver re-maps these then glut will not see the correct button
    press.

*)  Add -captureSingleDisplay launch parameter to allow the capturing of only one display
    when entering game mode.
	
*) Implemented GLUT_CURSOR_DESTROY selector for glutSetCursor()

*) Implemented GLUT_CURSOR_CYCLE selector for glutSetCursor()

*) Implemented GLUT_CURSOR_SPRAY selector for glutSetCursor()

*) Implemented all sizing cursor selectors for glutSetCursor()

*) Improved GLUT_CURSOR_CROSSHAIR


Bug Fixes:
----------

1)  glutCreateWindow() now correctly sets the window title to the given
    window title string, if any.
   
2)  GLUT now correctly calls any passive motion and/or entry callback for
    sub-windows if the glutPassiveMotionFunc(), glutEntryFunc() are called
    before the sub-window has become visible. Previously, the callback were
    only called after the user resized the top-level window which contained
    the sub-windows at least once.
    
3)  Normally, glut changes the working directory to the resources directory of
    the applications package.  This allows textures and other app resources 
    to be packaged with the application.  GLUT will detect the lack of this 
    directory, such as with a non-packaged command line application and not
    change the working directory.  Additionally, added the ability to specify 
    a working directory option -useWorkingDir as a command line argument which
    will also prevent GLUT from changing the initial working directory.
	
4)  Fixed window miniturization code to not detach surfaces.

5)  Updated event handling to be more responsive and use less CPU, results in modest
    performance gains in some cases.
	
6)  Handle lazy surface creation much better.

7)  Fixed GLUT initialization code to allow command line apps to run in the foreground
    and accept keyboard and menu input.
	
8)  Fixed sub-window visibiloty issues.

9)  Fixed game mode refresh rate handling to use doubles to get values from dictionary
    otherwise many refresh rates will fail to be returned and thus the display mode
    will not be recognized.

10) Numerous other fixes.



GLUT for Mac OS X Read Me
===========================

Additions:
----------

*) Implemented GLUT_CURSOR_CROSSHAIR selector for glutSetCursor()
*) Implemented GLUT_CURSOR_FULL_CROSSHAIR selector for glutSetCursor()
*) Implemented GLUT_CURSOR_HELP selector for glutSetCursor()
*) Implemented GLUT_CURSOR_LEFT_RIGHT selector for glutSetCursor()
*) Implemented GLUT_CURSOR_RIGHT_ARROW selector for glutSetCursor()
*) Implemented GLUT_CURSOR_UP_DOWN selector for glutSetCursor()
*) Implemented GLUT_CURSOR_WAIT selector for glutSetCursor()


Bug Fixes:
----------

1) A timer function set via glutTimerFunc() would be called up to a second too
   early. I.e. requested timeout 500ms -> timer fired instantly.
   
2) Top-level windows destroyed before a call to glutMainLoop() would not be
   immediately freed, rather they would stay around until the main loop was
   entered.
   
3) Clicking in a sub-window now makes it actually the first responder so that it
   is able to receive key down/up events.
   
4) Menus now work like with any other GLUT implementation, which means that they
   are now ALWAYS contextual menus. While this change means that GLUT apps now
   no longer really work like other Aqua apps, it does however mean that this
   GLUT release operates now MUCH more like GLUT implementations on other
   platforms. Thus, the menu status function is now called with the real mouse
   position, the correct window is now made current and the selected menu is now
   also made current prior to calling any menu related callbacks.
   Further, we now also support the ability to assign a menu multiple times to
   different menu items as a submenu.
   Also, we now correctly support menus for sub-windows (the old implementation
   would only allow the creation AND usage of up to three menus and simply ignore
   any additional menus created after that point, so i.e. menus of a sub-window
   were never accessible by the user).
   Accessing menus with a one-button mouse:
      Control + Shift:       GLUT_LEFT_BUTTON menu
      Control + Alternate:   GLUT_MIDDLE_BUTTON menu
      Control:               GLUT_RIGHT_BUTTON  menu
   
5) The menu status function and menu item callback are now called in the correct
   order: menuStatusFunc(GLUT_MENU_NOT_IN_USE) followed by menuItemFunc(item).
   
6) Determination of window & sub-window visibility is now _dramatically_ faster
   than it used to be, especially with many windows (> 20).
   
7) glutWarpPointer() now works as expected.

8) glutInitDisplayString() should now work as documented in its man page. It simply
   ignored any matching criteria in earlier releases. Consequently, if i.e. you
   asked for a stencil buffer with at least 3 bits depth, you couldn't actually be
   sure that you really got 3 bits worth of stencil. You may have ended up with a
   valid OpenGL context with no stencil buffer at all.
   
9) glutInitDisplayMode() is now much stricter in its operation. I.e. it now
   correctly rejects an attempt to create an indexed OpenGL context as MacOS X
   doesn't support indexed pixel formats.
   
10) glutFullScreen() now makes the current window really cover the whole screen.

11) glutGet(GLUT_WINDOW_PARENT) now also works correctly for hidden sub-windows.

12) glutGet(GLUT_DISPLAY_MODE_POSSIBLE) now works as advertised. Previously it
    would return 1 for pixel formats which were actually not supported.
    
13) De-miniaturizing a top-level window with sub-windows would result in a window
    were none of the sub-windows would be visible. Sub-windows now work correctly
    after window de-miniturization.
    
14) The mini-window of a de-miniturized now correctly shows a snapshot of all
    sub-windows of the de- miniturized window. The same is true for window snapshots
    taken by Edit/Copy and for services.

15) Fixed handling of GL commands immediately after window creation but before the
    main loop.  The window is now shown immediately but the events are deferred
    until run main loop is called.

16) fixed pixel format handling to not pass un-needed parameteres to GL.  Should
    result in more reliability in get pixel formats.

17) Cleaned up multi-sample handling.

18) Fixed event handled to use a CFTimer for GLUT events that is separate from the 
	NSEvent queue.


GLUT for Mac OS X Read Me
===========================

Bug Fixes:
----------

1) Creating a menu and destroying it before entering the main event loop via
   glutMainLoop() would crash the application.
   
2) Turning a menu item with an associated submenu into a regular menu item
   would result in a menu item which never invoked its associated callback.
   
3) Top-level windows would be positioned incorrectly.

4) glutGet(GLUT_WINDOW_Y) would always return the wrong position for a top-
   level window.
   
5) No visibility changed events would be generated for visibility changes
   caused by top-level windows.

6) Window visibility calculation code was wrong most of the time which
   resulted in calls to a window's status callback with the wrong visibility
   code or no call at all (especially for sub-windows).

7) Hiding/Unhiding a GLUT application would not update the window status
   of GLUT windows which had the effect that apps continued to consume
   CPU cycles while hidden.
   
7) We now generate 'real' visibility events just like X Windows does which
   means that we have now the same semantics on Mac OS X as under X Windows.
   
8) Complete rewrite of the work event mechansim (deferred updates). The new
   implementation is semantically 99.9% the same as the X Windows implementation
   and much more efficient. I.e. we always only generate at most one Work
   event per AppKit event. Previously, every single glutPostWindowRedisplay()
   would generate two Work events per AppKit event. Now at most one single
   Work event is generated independent of the number of glutPostWindowRedisplay()
   calls per AppKit event.
   
9) The organization of the project sources is now much closer to the original
   distribution which should make it easier to identifier areas where we
   unindentionally differ from the original implementation.
   
10) The mouse coordinates passed to the various mouse related callbacks are now
    correctly rounded to integral pixel locations.
    
11) Key events with more than a single UTF-16 codepoint would only pass on
    the first codepoint to the GLUT application and drop the others on the
    floor.

12) No key events would be accepted by a window after it was deminiaturized.

13) Showing/hiding subwindows wouldn't work correctly. They do now and a hidden
    subwindow will correctly retain its relative position among its siblings
    while hidden even as new siblings are added and others are removed. We do
    this by maintaining a doubly-linked list of subwindows parallel to the
    -subviews array which the AppKit manages. The important difference between
    our list and -subviews is that the former contains all subwindows _including_
    hidden subwindows while the latter _only_ contains shown subwindows.
    
14) Calling glutPostWindowRedisplay() on any subwindow would result in
    superfluous redisplay operations. I.e. invalidating a leave window in
    the window hierarchy would redisplay all ancestors up to the controlling
    top-level window.
    
15) Significantly reduced the overhead of a redisplay operation.

16) glutMouseFunc now supports GLUT_MIDDLE_BUTTON. glutMotionFunc() is now
    correctly called for any mouse button (not only left & right buttons as
    it used to be).
   
17) Displaying the Show Clipboard window would not deactivate the current main
    window. It does so now.
    
18) Determination of a window's or subwindow's damaged status is now much more
    reliable.
    
19) Invoking glutVisibilityFunc() and glutWindowStatusFunc() on the same window
    is now handle the same as it is for the X Windows implementation.
    
20) Newly created windows now have a default reshape & display callback as
    required.
    
21) glutPassiveMotionFunc() is now handled correctly for multiple subwindows.
    Previously if i.e. two subwindows installed a passive motion function, as
    soon as one of them would call glutPassiveMotionFunc(NULL) no further
    passive motion calls would be generated for _any_ subwindow.
    
22) Calling glutWindowStatusFunc(NULL) now correctly resets the current window's
    visibility state to unknown.
    
23) No more superfluous calls to a window's reshape callback are done.

   
GLUT for Mac OS X Read Me
===========================

This is an improved version of the GLUT that Apple ships with MacOS X v10.1.3.
The following table lists all changes relative to Apple's version:

*) Cleaned up project
*) Fully implemented GLUT game mode and related APIs
*) Implemented glutSetKeyRepeat() function
*) Implemented GLUT_DEVICE_KEY_REPEAT selector for glutDeviceGet()
*) Implemented GLUT_DISPLAY_MODE_POSSIBLE selector for glutGet()
*) Implemented GLUT_WINDOW_NUM_SAMPLES selector for glutGet()
*) Implemented GLUT_CURSOR_INHERIT selector for glutSetCursor()
*) Implemented GLUT_CURSOR_INFO selector for glutSetCursor()
*) Added support for GLUT_MULTISAMPLE display mode flag and "samples" display
   string keyword
*) Cleaned up menus
*) Hide and Quit menu items now automatically show the GLUT application name
*) User may now copy the contents of the current front window to the clipboard
   via Edit/Copy
*) User may now invoke a service on the contents of the current front window
*) User may now inspect the contents of the clipboard via Edit/Show Clipboard
*) User may now print the contents of the current front window
*) GLUT application menus are now added to the menu bar according to the Aqua
   Guidelines
*) Got rid of a few memory leaks
*) Miniaturized windows now show a snapshot of the window content area
   (OpenGL graphics)

If you don't want to support services, copying and saving the contents of the current
front window in your GLUT application then you may turn this behavior off by supplying
the "-nograb" option on the command line (or at least the command string you actually
pass to the glutInit() function).

If you don't want to support printing in your GLUT application then you may turn it off
by supplying the "-noprint" option on the CLI.
