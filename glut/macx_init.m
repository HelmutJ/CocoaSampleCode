
/* Copyright (c) Mark J. Kilgard, 1994. */
/* Copyright (c) Dietmar Planitzer, 1998, 2002 - 2003 */

/* This program is freely distributable without licensing fees 
   and is provided without guarantee or warrantee expressed or 
   implied. This program is -not- in the public domain. */

#import <unistd.h>
#import "macx_glut.h"
#import "GLUTApplication.h"
// HID device stuff
#import "HID_Utilities_External.h"
#import <IOKit/hid/IOHIDLib.h>
#import <Kernel/IOKit/hidsystem/IOHIDUsageTables.h>



/* GLUT globals */
int              __glutArgc = 0;
char **          __glutArgv = NULL;
int              __glutScreenHeight;
int              __glutScreenWidth;
BOOL             __glutIconic = kIconic;
BOOL             __glutDebug = kDebug;
unsigned int     __glutDisplayMode = (GLUT_RGB | GLUT_SINGLE | GLUT_DEPTH);
int              __glutInitWidth = kInitWidth;
int              __glutInitHeight = kInitHeight;
int              __glutInitX = kInitX;
int              __glutInitY = kInitY;
BOOL             __glutDisableGrabbing = NO;
BOOL             __glutDisablePrinting = NO;
NSTimeInterval   __glutStartupTime = 0.0;
int              __glutDefaultColorSize = 16; // Default is ARGB1555.
BOOL			 __glutUseInitWD = kUseInitWD;
BOOL             __glutInitWindowSizeCalled = NO;
BOOL             __glutInitWindowPositionCalled = NO;

static void	removeArgs(int *argcp, char **argv, int numToRemove);
static int	ReadInteger(char *string, char **NextString);
static int	XParseGeometry(char *string, int *x, int *y, unsigned int *width, unsigned int *height);


/* 
 * Bitmask returned by XParseGeometry().  Each bit tells if the corresponding
 * value (x, y, width, height) was found in the parsed string.
 */
#define NoValue		0x0000
#define XValue  	0x0001
#define YValue		0x0002
#define WidthValue	0x0004
#define HeightValue	0x0008
#define AllValues 	0x000F
#define XNegative 	0x0010
#define YNegative 	0x0020


/* GLUT's central atexit() handler */
static void __glutShutdown(void)
{
   // the following is needed to ensure auto-release pools work for releasing existing objects
   GLUTAPI_DECLARATIONS
   GLUTAPI_BEGIN

   __glutCloseDownGameMode();
   __glutForgetInputDevices();
   __glutResetKeyboard();

   GLUTAPI_END
}

/* CENTRY */
void APIENTRY glutInit(int *argcp, char **argv)
{
   char *		geometry = NULL;
   int			i;
   int          preserveSuppliedX = 0, preserveSuppliedY = 0;
   int          preserveSuppliedWidth = 0, preserveSuppliedHeight = 0;
   
   GLUTAPI_DECLARATIONS
     
   if (NSApp != nil) {
      __glutWarning("glutInit being called a second time.");
      return;
   }
   
   atexit(__glutShutdown); // set up shutdown routine
   __glutSetForeground ();	
   
   GLUTAPI_BEGIN

      /* Initialize our application instance */
   NSApp = [GLUTApplication sharedApplication];
   if (![NSBundle loadNibNamed:@"GLUT" owner:NSApp]) {
      __glutFatalError("glutInit can't open GLUT.nib"); // will exit
   }

   /* Jump through a couple hoops to preserve any user-specified initial
    * position or size because the call to __glutLoadPrefs will overwrite
    * them.  Although the GLUT spec does not specifically require this, there
    * isn't any reason that we shouldn't support it, as this is the behavior
    * on most other platforms (and it makes sense to try and use the desired
    * size).  Futhermore, note that doing this here still allows the user to
    * override the window size with a -geometry and also doesn't preclude a
    * forced window size if the glutInitWindow*() functions are called after
    * the glutInit() call. */
   if ( __glutInitWindowPositionCalled == YES ) {
       preserveSuppliedX = __glutInitX;
       preserveSuppliedY = __glutInitY;
   }
   if ( __glutInitWindowSizeCalled == YES ) {
       preserveSuppliedWidth = __glutInitWidth;
       preserveSuppliedHeight = __glutInitHeight;
   }
   
   __glutLoadPrefs (); // ensure prefs are loaded from file
      
   /* Light the hoops on fire this time (restore program specified
    * parameters). */
   if ( __glutInitWindowPositionCalled == YES ) {
      __glutInitX = preserveSuppliedX;
      __glutInitY = preserveSuppliedY;
      __glutInitWindowPositionCalled = NO;
   }
   if ( __glutInitWindowSizeCalled == YES ) {
      __glutInitWidth = preserveSuppliedWidth;
      __glutInitHeight = preserveSuppliedHeight;
      __glutInitWindowSizeCalled = NO;
   }
   
      /* Make private copy of command line arguments. */
   __glutArgc = *argcp;
   __glutArgv = (char **) malloc(__glutArgc * sizeof(char *));
   if(!__glutArgv)
      __glutFatalError("out of memory."); // will exit
   for(i = 0; i < __glutArgc; i++) {
		__glutArgv[i] = __glutStrdup(argv[i]);
		if(!__glutArgv[i])
			__glutFatalError("out of memory."); // will exit
	}
	
		/* parse arguments for standard options */
	for(i = 1; i < __glutArgc; i++) {
		if(!strcmp(__glutArgv[i], "-useMacOSCoords")) {
			__glutUseMacOSCoords = YES;
			removeArgs(argcp, &argv[1], 1);
		} else if(!strcmp(__glutArgv[i], "-useWorkingDir")) {
			__glutUseInitWD = YES;
			removeArgs(argcp, &argv[1], 1);
		} else if(!strcmp(__glutArgv[i], "-useExtendedDesktop")) {
			__glutUseExtendedDesktop = YES;
			removeArgs(argcp, &argv[1], 1);
		} else if(!strcmp(__glutArgv[i], "-display")) {
			__glutWarning("-display option invalid for MacOS X glut (X Windows only).");
			if(__glutArgv[i + 1][0] != '-')
				i++;
			removeArgs(argcp, &argv[1], 2);
		} else if(!strcmp(__glutArgv[i], "-geometry")) {
			if(++i >= __glutArgc)
				__glutFatalError("follow -geometry option with geometry parameter.");
			geometry = __glutArgv[i];
			removeArgs(argcp, &argv[1], 2);
		} else if(!strcmp(__glutArgv[i], "-direct")) {
			__glutWarning("-direct option invalid for MacOS X glut.");
			removeArgs(argcp, &argv[1], 1);
		} else if(!strcmp(__glutArgv[i], "-indirect")) {
			__glutWarning("-indirect option invalid for MacOS X glut.");
			removeArgs(argcp, &argv[1], 1);
		} else if(!strcmp(__glutArgv[i], "-iconic")) {
			__glutIconic = YES;
			removeArgs(argcp, &argv[1], 1);
		} else if(!strcmp(__glutArgv[i], "-gldebug")) {
			__glutDebug = GL_TRUE;
			removeArgs(argcp, &argv[1], 1);
		} else if(!strcmp(__glutArgv[i], "-sync")) { // X protocal syncing
			__glutWarning("-sync option invalid for MacOS X glut.");
			removeArgs(argcp, &argv[1], 1);
      } else if(!strcmp(__glutArgv[i], "-nograb")) {
         __glutDisableGrabbing = YES;
         removeArgs(argcp, &argv[1], 1);
      } else if(!strcmp(__glutArgv[i], "-noprint")) {
         __glutDisablePrinting = YES;
         removeArgs(argcp, &argv[1], 1);
      } else if(!strcmp(__glutArgv[i], "-menuIdleInterval")) {
			__glutIdleTimeInterval = strtod(__glutArgv[++i], NULL);
         if(__glutIdleTimeInterval == 0.0) {
            __glutIdleTimeInterval = GLUT_DEFAULT_IDLE_INTERVAL;
         } else if(__glutIdleTimeInterval < 0.001) {
            __glutIdleTimeInterval = 0.001;	// 1000Hz
         } else if(__glutIdleTimeInterval > 1.0) {
            __glutIdleTimeInterval = 1.0;		// 1Hz
         }
			removeArgs(argcp, &argv[1], 2);
      } else if(!strcmp(__glutArgv[i], "-fadeInterval")) {
			__glutGameModeFadeInterval = strtod(__glutArgv[++i], NULL);
         if(__glutGameModeFadeInterval == 0.0) {
            __glutGameModeFadeInterval = GLUT_DEFAULT_FADE_INTERVAL;
         } else if(__glutGameModeFadeInterval < 0.1) {
            __glutGameModeFadeInterval = 0.1;	// 1/4 second
         } else if(__glutGameModeFadeInterval > 5.0) {
            __glutGameModeFadeInterval = 5.0;	// 5 seconds
         }
			removeArgs(argcp, &argv[1], 2);
		} else if(!strcmp(__glutArgv[i], "-captureSingleDisplay")) {
			__glutCaptureAllDisplays = NO;
		} else if(!strcmp(__glutArgv[i], "-syncToVBL")) {
			__glutSyncToVBL = YES;
		} else if (!strncmp(__glutArgv[i], "-psn_", 5)) {
         // Some funky Finder thing.
         removeArgs(argcp, &argv[1], 1);
      } else {
			/* Stop processing args when you hit an unknown one. */
			break;
		}
	}

	// Try and determine if this is an app with a full bundle structure that contains resources.
	// If so, chdir to that resource directory so normal fopen() and the like functions will work
	// without having to find the resource path explicitly.
	if (NO == __glutUseInitWD) {
		NSString * bundlePath = [[NSBundle mainBundle] bundlePath];
		NSArray * bundlePathArray = [[NSFileManager defaultManager] directoryContentsAtPath:bundlePath];
		if ((nil != bundlePathArray) && ([bundlePathArray containsObject:@"Contents"])) {
			NSString * contentsPath = [bundlePath stringByAppendingPathComponent:@"Contents"];
			NSArray * contentsPathArray = [[NSFileManager defaultManager] directoryContentsAtPath:contentsPath];
			if ((nil != contentsPath) && ([contentsPathArray containsObject:@"MacOS"]) && ([contentsPathArray containsObject:@"Resources"])) {
				NSString * finalResourcesPath = [contentsPath stringByAppendingPathComponent:@"Resources"];
				NSArray * finalResourcesPathArray = [[NSFileManager defaultManager] directoryContentsAtPath:finalResourcesPath];
				if ((nil != finalResourcesPath) && (0 < [finalResourcesPathArray count]) && ((1 < [finalResourcesPathArray count]) || (![[finalResourcesPathArray objectAtIndex:0] isEqual:@"English.lproj"]))) {
					chdir([[[NSBundle mainBundle] resourcePath] fileSystemRepresentation]);
				}
			}
		}
	}
   
   /* Force the creation of our input device list now. Doing this at a
      latter time screws up mouse down detection... */
   if (__glutGetNumberOfMouseButtons() < 3) { /* if we have less than a 3 button mouse we should emulate one */
		__glutEmulateMouseButtons = YES;
	}
    
		/* set default window management options */
	if (NO == __glutUseExtendedDesktop) {
		NSScreen * screenWithMenubar = [[NSScreen screens] objectAtIndex: 0];
		__glutScreenWidth = (int) [screenWithMenubar frame].size.width;
		__glutScreenHeight = (int) [screenWithMenubar frame].size.height;
		__glutDefaultColorSize = NSBitsPerPixelFromDepth([screenWithMenubar depth]);
		// Pick the closest depth to 16 or 32.
		if (__glutDefaultColorSize <= 16)
			__glutDefaultColorSize = 16;
		else
			__glutDefaultColorSize = 32;
	} else { // look at all screens
		NSEnumerator *enumerator = [[NSScreen screens] objectEnumerator];
		NSScreen *	screen = nil;
		float left = 0, right = 0, top = 0, bottom = 0, colorSize = 16;
		while (nil != (screen = (NSScreen *)[enumerator nextObject])) {
			if([screen frame].origin.x < left)
				left = [screen frame].origin.x;
			if([screen frame].origin.y < top)
				top = [screen frame].origin.y;
			if(([screen frame].origin.x + [screen frame].size.width) > right)
				right = ([screen frame].origin.x + [screen frame].size.width);
			if(([screen frame].origin.y + [screen frame].size.height) > bottom)
				bottom = ([screen frame].origin.y + [screen frame].size.height);
			if (NSBitsPerPixelFromDepth([screen depth]) > colorSize) // pick deepest depth   ggs: this does not support deep displays currently
				colorSize = 32;
		}
		__glutScreenWidth = right - left;
		__glutScreenHeight = bottom - top;
		__glutDefaultColorSize = colorSize;
	}
	
   if(geometry) {
      int	flags, x = 0, y = 0, width = 0, height = 0;
      
      flags = XParseGeometry(geometry, &x, &y, (unsigned int *) &width, (unsigned int *) &height);
      if(WidthValue & flags) {
				/* Careful because X does not allow zero or negative width windows */
			if(width > 0)
				__glutInitWidth = width;
      }
      if(HeightValue & flags) {
				/* Careful because X does not allow zero or negative height windows */
			if(height > 0)
				__glutInitHeight = height;
      }
      glutInitWindowSize(__glutInitWidth, __glutInitHeight);
      
      if(XValue & flags) {
	     if (NO == __glutUseMacOSCoords) {
			if(XNegative & flags)
				x = __glutScreenWidth + x - __glutInitWidth;
			if(x >= 0)
				__glutInitX = x;
		 } else
			__glutInitX = x;
      }
      if(YValue & flags) {
	     if (NO == __glutUseMacOSCoords) {
			if(YNegative & flags)
				y = __glutScreenHeight + y - __glutInitHeight;
			if(y >= 0)
				__glutInitY = y;
		 } else
			__glutInitY = y;
		 
      }
      glutInitWindowPosition(__glutInitX, __glutInitY);
   }
   __glutStartupTime = [NSDate timeIntervalSinceReferenceDate];
   
   /* check if GLUT_FPS env var is set */
   {
      const char *fps = getenv("GLUT_FPS");
      
      if (fps) {
         sscanf(fps, "%d", (int *) &__glutFPS);
         if (__glutFPS <= 0)
            __glutFPS = 5000;  /* 5000 milliseconds */
      }
   }
   GLUTAPI_END
}

void __glutEngineInit (void) // inits glut engine based on current values
{
	// only thing that needs to be reset
	if (NO == __glutUseInitWD) {
		NSArray * fileArray = [[NSFileManager defaultManager] directoryContentsAtPath:[[NSBundle mainBundle] resourcePath]];
		// if there is a directory and it has more than one item or the only item is NOT named Contents
		if ((nil != fileArray) && (0 < [fileArray count]) && ((1 < [fileArray count]) || (![[fileArray objectAtIndex:0] isEqual:@"Contents"])))
			chdir([[[NSBundle mainBundle] resourcePath] fileSystemRepresentation]);
	}
	// reset screen width height and depth
	if (NO == __glutUseExtendedDesktop) {
		NSScreen * screenWithMenubar = [[NSScreen screens] objectAtIndex: 0];
		__glutScreenWidth = (int) [screenWithMenubar frame].size.width;
		__glutScreenHeight = (int) [screenWithMenubar frame].size.height;
		__glutDefaultColorSize = NSBitsPerPixelFromDepth([screenWithMenubar depth]);
		// Pick the closest depth to 16 or 32.
		if (__glutDefaultColorSize <= 16)
			__glutDefaultColorSize = 16;
		else
			__glutDefaultColorSize = 32;
	} else { // look at all screens
		NSEnumerator *enumerator = [[NSScreen screens] objectEnumerator];
		NSScreen *	screen = nil;
		float left = 0, right = 0, top = 0, bottom = 0, colorSize = 16;
		while (nil != (screen = (NSScreen *)[enumerator nextObject])) {
			if([screen frame].origin.x < left)
				left = [screen frame].origin.x;
			if([screen frame].origin.y < top)
				top = [screen frame].origin.y;
			if(([screen frame].origin.x + [screen frame].size.width) > right)
				right = ([screen frame].origin.x + [screen frame].size.width);
			if(([screen frame].origin.y + [screen frame].size.height) > bottom)
				bottom = ([screen frame].origin.y + [screen frame].size.height);
			if (NSBitsPerPixelFromDepth([screen depth]) > colorSize) // pick deepest depth   ggs: this does not support deep displays currently
				colorSize = 32;
		}
        __glutInitWindowSizeCalled = true;
		__glutScreenWidth = right - left;
		__glutScreenHeight = bottom - top;
		__glutDefaultColorSize = colorSize;
	}
}


void APIENTRY glutInitWindowPosition(int x, int y)
{
   __glutInitX = x;
   __glutInitY = y;
   __glutInitWindowPositionCalled = true;
}

void APIENTRY glutInitWindowSize(int width, int height)
{
   __glutInitWidth = width;
   __glutInitHeight = height;
   
   if(width <= 0)
      __glutInitWidth = 300;
   if(height <= 0)
      __glutInitHeight = 300;
   __glutInitWindowSizeCalled = true;
}

void APIENTRY  glutInitDisplayMode(unsigned int mask)
{
   __glutDisplayMode = mask;
}
/* ENDCENTRY */


static void removeArgs(int *argcp, char **argv, int numToRemove)
{
	int i, j;

	for(i = 0, j = numToRemove; argv[j]; i++, j++)
		argv[i] = argv[j];

	argv[i] = NULL;
	*argcp -= numToRemove;
}


/* the following function was lifted from the X sources as indicated. */

/* Copyright 	Massachusetts Institute of Technology  1985, 1986, 1987 */
/* $XConsortium: XParseGeom.c,v 11.18 91/02/21 17:23:05 rws Exp $ */

/*
Permission to use, copy, modify, distribute, and sell this software and its
documentation for any purpose is hereby granted without fee, provided that
the above copyright notice appear in all copies and that both that
copyright notice and this permission notice appear in supporting
documentation, and that the name of M.I.T. not be used in advertising or
publicity pertaining to distribution of the software without specific,
written prior permission.  M.I.T. makes no representations about the
suitability of this software for any purpose.  It is provided "as is"
without express or implied warranty.
*/

/*
 *    XParseGeometry parses strings of the form
 *   "=<width>x<height>{+-}<xoffset>{+-}<yoffset>", where
 *   width, height, xoffset, and yoffset are unsigned integers.
 *   Example:  "=80x24+300-49"
 *   The equal sign is optional.
 *   It returns a bitmask that indicates which of the four values
 *   were actually found in the string.  For each value found,
 *   the corresponding argument is updated;  for each value
 *   not found, the corresponding argument is left unchanged. 
 */

static int ReadInteger(char *string, char **NextString)
{
    register int Result = 0;
    int Sign = 1;
    
    if (*string == '+')
	string++;
    else if (*string == '-')
    {
	string++;
	Sign = -1;
    }
    for (; (*string >= '0') && (*string <= '9'); string++)
    {
	Result = (Result * 10) + (*string - '0');
    }
    *NextString = string;
    if (Sign >= 0)
	return (Result);
    else
	return (-Result);
}

static int XParseGeometry(char *string, int *x, int *y, unsigned int *width, unsigned int *height)
{
	int					mask = NoValue;
	register char *	strind;
	unsigned int		tempWidth = 0, tempHeight = 0;
	int					tempX = 0, tempY = 0;
	char *				nextCharacter;
	
	if ( (string == NULL) || (*string == '\0')) return(mask);
	if (*string == '=')
		string++;  /* ignore possible '=' at beg of geometry spec */
	
	strind = (char *)string;
	if (*strind != '+' && *strind != '-' && *strind != 'x') {
		tempWidth = ReadInteger(strind, &nextCharacter);
		if (strind == nextCharacter) 
		    return (0);
		strind = nextCharacter;
		mask |= WidthValue;
	}
	
	if (*strind == 'x' || *strind == 'X') {	
		strind++;
		tempHeight = ReadInteger(strind, &nextCharacter);
		if (strind == nextCharacter)
		    return (0);
		strind = nextCharacter;
		mask |= HeightValue;
	}
	
	if ((*strind == '+') || (*strind == '-')) {
		if (*strind == '-') {
  			strind++;
			tempX = -ReadInteger(strind, &nextCharacter);
			if (strind == nextCharacter)
			    return (0);
			strind = nextCharacter;
			mask |= XNegative;
		
		}
		else
		{	strind++;
			tempX = ReadInteger(strind, &nextCharacter);
			if (strind == nextCharacter)
			    return(0);
			strind = nextCharacter;
		}
		mask |= XValue;
		if ((*strind == '+') || (*strind == '-')) {
			if (*strind == '-') {
				strind++;
				tempY = -ReadInteger(strind, &nextCharacter);
				if (strind == nextCharacter)
			    	    return(0);
				strind = nextCharacter;
				mask |= YNegative;
			
			}
			else
			{
				strind++;
				tempY = ReadInteger(strind, &nextCharacter);
				if (strind == nextCharacter)
			    	    return(0);
				strind = nextCharacter;
			}
			mask |= YValue;
		}
	}
	
	/* If strind isn't at the end of the string the it's an invalid
		geometry specification. */

	if (*strind != '\0') return (0);

	if (mask & XValue)
	    *x = tempX;
 	if (mask & YValue)
	    *y = tempY;
	if (mask & WidthValue)
            *width = tempWidth;
	if (mask & HeightValue)
            *height = tempHeight;
	return (mask);
}
