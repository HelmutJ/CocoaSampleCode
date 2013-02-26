
/* Copyright (c) Dietmar Planitzer, 2002 */

/* This program is freely distributable without licensing fees 
   and is provided without guarantee or warrantee expressed or 
   implied. This program is -not- in the public domain. */

#import <OpenGL/CGLTypes.h>

#import "macx_glut.h"
#import "GLUTWindow.h"
#import "GLUTView.h"


GLUTView *		__glutCurrentView = nil;
GLUTView **		__glutViewList = NULL;
int				__glutViewListSize = 0;
GLUTWindow *	__glutFullscreenWindows = nil;
BOOL			__glutUseMacOSCoords = kUseMacOSCoords;
BOOL			__glutShouldWindowClose = NO;        /* -windowShouldClose: && glutDestroyWindow */
BOOL			__glutInsideWindowShouldClose = NO;  /* -windowShouldClose: && glutDestroyWindow */
BOOL			__glutUseExtendedDesktop = kUseExtendedDesktop;       /* (0, 0) is upper left */
BOOL			__glutSyncToVBL = kSyncToVBL;


GLUTView *__glutGetWindowByNum(int winnum)
{
   if(winnum < 1 || winnum > __glutViewListSize) {
      return nil;
   }
   return __glutViewList[winnum - 1];
}

void __glutEnableVisibilityUpdates(void)
{
   int	i;
   
   for(i = 0; i < __glutViewListSize; i++) {
      GLUTView *	curView = __glutViewList[i];
      
      if(curView)
         [curView enableVisibilityUpdates];
   }
}

static int __glutGetUnusedWindowSlot(void)
{
   int	i;
   
   /* Look for allocated, unused slot. */
   for(i = 0; i < __glutViewListSize; i++) {
      if(!__glutViewList[i]) {
         return i;
      }
   }
   /* Allocate a new slot. */
   __glutViewListSize++;
   __glutViewList = (GLUTView **) realloc(__glutViewList, __glutViewListSize * sizeof(GLUTView *));
   if(!__glutViewList) {
      __glutFatalError("out of memory.");
   }
   __glutViewList[__glutViewListSize - 1] = NULL;
   return __glutViewListSize - 1;
}


/* CENTRY */
int APIENTRY glutGetWindow(void)
{
   if(__glutCurrentView) {
      return [__glutCurrentView windowID];
   } else {
      return 0;
   }
}
/* ENDCENTRY */

/* A note on __glutSetWindow() and -lockFocus/-unlockFocus:
   GLUT windows are made current/uncurrent via a call to
   __glutSetWindow(). This function updates the internal
   __glutCurrentView var and makes the OpenGL context of the
   corresponding GLUTView current. It, however, does not
   change the AppKit NSView focus. The NSView focus is only
   changed as the result of a display operation which either
   the OS itself caused (window was shown, exposure events)
   or the GLUT app caused by calling glutPostWindowRedisplay().
   This is so because the NSView focus is maintained by a focus
   stack which implies that it can't support out-of-order ops.
   I.e. GLUT app creates window 1, which is made current, then
   creates window 2, which is made current. Then GLUT app
   destroys window 1, which implies that the current focus,
   currently held by window 2, would be removed via -unlockFocus.
   At this point window 2 would have lost focus, although it
   should have kept it...
*/
void __glutSetWindow(GLUTView *view)
{
    if(__glutCurrentView != view) {
	[__glutCurrentView resignCurrentGLUTView];    
		__glutCurrentView = view;
    }
   
   [__glutCurrentView makeCurrentGLUTView];
   
   MAKE_CURRENT_LAYER(__glutCurrentView);
   
   /* If debugging is enabled, we'll want to check this window
      for any OpenGL errors every iteration through the GLUT
      main loop.  To accomplish this, we post the
      GLUT_DEBUG_WORK to be done on this window. */
   if(__glutDebug) {
      GLUTWorkEvent	event;
      
      INIT_WORK_EVENT(&event);
      event.workMask = GLUT_DEBUG_WORK;
      event.windowNum = [view windowID];
      __glutPostWorkEvent(&event);
   }
}

/* CENTRY */
void APIENTRY glutSetWindow(int win)
{
   GLUTView *	view = __glutGetWindowByNum(win);
   
   GLUTAPI_DECLARATIONS
   GLUTAPI_BEGIN
   if(!view) {
      __glutWarning("glutSetWindow attempted on bogus window.");
      GLUTAPI_VOIDRETURN;
   }
   __glutSetWindow(view);
   GLUTAPI_END
}
/* ENDCENTRY */

void __glutDefaultDisplay(void)
{
   /* XXX Remove the warning after GLUT 3.0. */
   __glutWarning("The following is a new check for GLUT 3.0; update your code.");
   __glutFatalError("redisplay needed for window %d, but no display callback.", [__glutCurrentView windowID]);
}

void __glutDefaultReshape(int width, int height)
{
   /* Adjust the viewport of the window (and overlay if one exists). */
   MAKE_CURRENT_WINDOW(__glutCurrentView);
   glViewport(0, 0, (GLsizei) width, (GLsizei) height);
}

void __glutDefaultWMClose()
{
   /* Do nothing by default on MacOS X */
}

static NSOpenGLPixelFormat *createPixelFormatCI(unsigned int mode, BOOL gameMode)
{
   /* GLUT_INDEX not supported on MacOS X */
   return nil;
}

#if 0 /* deprecated */
static UInt32 _dspyMaskFromDevice(GDHandle hDev)
{
    UInt32 	dspyMask = 0;
    if ((hDev != NULL) && (*hDev != NULL)) {
        // Get all the devices represented by this GDev.
        if ((*hDev)->gdFlags & (1 << screenActive)) {
            Rect* pgdRect;
            CGRect cgGDRect;
            unsigned int j;
            CGDirectDisplayID dspys[32];
            CGDisplayCount nDspys;
			// get and match display rect
            pgdRect = &((*hDev)->gdRect);
            cgGDRect.origin.x = pgdRect->left;
            cgGDRect.origin.y = pgdRect->top;
            cgGDRect.size.width = pgdRect->right - pgdRect->left;
            cgGDRect.size.height = pgdRect->bottom - pgdRect->top;
            CGGetDisplaysWithRect(cgGDRect, 32, dspys, &nDspys);
			if (nDspys == 1) // only one display found 
				dspyMask = (UInt32)CGDisplayIDToOpenGLDisplayMask(dspys[0]); // set display mask (only single case)
			else { // more than one found for rect, likely a mirrored case
				CGDirectDisplayID activeDspys[32];
				CGDisplayCount nActiveDspys;
				UInt32 k;
				
				CGGetActiveDisplayList(32, activeDspys, &nActiveDspys);
				for (j = 0; j < nDspys; j++) { // for all displays found
					for (k = 0; k < nActiveDspys; k++) { // for all active displays
						if (activeDspys[k] == dspys[j]) { // if an active display == display found
							dspyMask |= (UInt32)CGDisplayIDToOpenGLDisplayMask(dspys[j]); // OR into display mask for each match
							break; // found active so done
						}
					}
				}
			}
        }
    }
    return dspyMask;
}
#endif //#if !defined(__LP64__)

static BOOL _PFisFullscreenStereo (NSOpenGLPixelFormat *pf)
{
#ifdef MAC_OS_X_VERSION_10_5
	int stereo = 0, fullscreen = 0;
#else
	long stereo = 0, fullscreen = 0;
#endif

	[pf getValues:&stereo forAttribute:NSOpenGLPFAStereo forVirtualScreen:0];
	[pf getValues:&fullscreen forAttribute:NSOpenGLPFAFullScreen forVirtualScreen:0];
	
	if (stereo && fullscreen)
		return true;
	
	return false;
}

unsigned int __glutGetDisplayMaskFromMainDevice(void)
{
	return CGDisplayIDToOpenGLDisplayMask(CGMainDisplayID());
}

static NSOpenGLPixelFormat *createPixelFormatRGB(unsigned int mode, BOOL gameMode)
{
   NSOpenGLPixelFormatAttribute	list[64];
   int							n = 0;
   
  if(gameMode)  {
	  list[n++] = NSOpenGLPFAScreenMask;
      list[n++] = CGDisplayIDToOpenGLDisplayMask(kCGDirectMainDisplay);
      list[n++] = NSOpenGLPFAColorSize;
      list[n++] = __glutGetCurrentDMDepth ();
      list[n++] = NSOpenGLPFAClosestPolicy; // add any time color depth is used
   }
   // needed for software renderer
   if(GLUT_WIND_HAS_ALPHA(mode)) {
      list[n++] = NSOpenGLPFAAlphaSize;
      list[n++] = 1; // Find shallowest alpha buffer.
   }
   if(GLUT_WIND_IS_DOUBLE(mode)) {
      list[n++] = NSOpenGLPFADoubleBuffer;
   }
   if(GLUT_WIND_IS_STEREO(mode)) {
		list[n++] = NSOpenGLPFAStereo;

		// stereo is no longer a fullscreen only format but game mode needs to make it a fullscreen mode
		if (gameMode)
		{
		   list[n++] = NSOpenGLPFAFullScreen; // this will screw up glut so must be used carefully by apps
		   list[n++] = NSOpenGLPFAScreenMask;
		   list[n++] = __glutGetDisplayMaskFromMainDevice();
		}
   }
   if(GLUT_WIND_HAS_DEPTH(mode)) {
      list[n++] = NSOpenGLPFADepthSize;
      list[n++] = 1; // Find shallowest depth buffer.
   }
   if(GLUT_WIND_HAS_STENCIL(mode)) {
      list[n++] = NSOpenGLPFAStencilSize;
      list[n++] = 1; // Find shallowest stencil buffer.
   }
   if(GLUT_WIND_HAS_ACCUM(mode)) {
      list[n++] = NSOpenGLPFAAccumSize;
      list[n++] = 1; // Find shallowest accum buffer.
   }
   if(GLUT_WIND_IS_MULTISAMPLE(mode)) {
     list[n++] = kCGLPFASampleBuffers; /* NSOpenGLPFASampleBuffers */
     list[n++] = 1;
     list[n++] = kCGLPFASamples; /* NSOpenGLPFASamples */
     list[n++] = 2; // default
	 list[n++] = NSOpenGLPFANoRecovery;
   }
   if(GLUT_WIND_IS_NO_RECOVERY(mode)) {
      list[n++] = NSOpenGLPFANoRecovery;
      list[n++] = 1;
   }
   list[n] = 0;
   
#ifdef __GLUT_LOG_PIXELFORMAT
   __glutDumpPixelFormatAttributes(list);
#endif
   return [[[NSOpenGLPixelFormat alloc] initWithAttributes: list] autorelease];
}

static NSOpenGLPixelFormat *createPixelFormat(unsigned int mode, BOOL gameMode)
{
   /* XXX GLUT_LUMINANCE not implemented for GLUT 3.0. */
   if(GLUT_WIND_IS_LUMINANCE(mode))
      return nil;
   
   if(GLUT_WIND_IS_RGB(mode))
      return createPixelFormatRGB(mode, gameMode);
   else
      return createPixelFormatCI(mode, gameMode);
}

NSOpenGLPixelFormat *__glutDeterminePixelFormat(unsigned int displayMode, BOOL *treatAsSingle,
                           BOOL gameMode, NSOpenGLPixelFormat *(getPixelFormat) (unsigned int, BOOL))
{
   NSOpenGLPixelFormat *	pf = nil;
   
   /* Should not be looking at display mode mask if
      __glutDisplayString is non-NULL. */
   assert(!__glutDisplayString);
   
	*treatAsSingle = GLUT_WIND_IS_SINGLE(displayMode);
   pf = getPixelFormat(displayMode, gameMode);
   if(!pf) {
      /* Fallback cases when can't get exactly what was asked
         for... */
      if(GLUT_WIND_IS_SINGLE(displayMode)) {
         /* If we can't find a single buffered visual, try looking
            for a double buffered visual.  We can treat a double
            buffered visual as a single buffer visual by changing
            the draw buffer to GL_FRONT and treating any swap
            buffers as no-ops. */
         displayMode |= GLUT_DOUBLE;
         pf = getPixelFormat(displayMode, gameMode);
         *treatAsSingle = YES;
      }
      if(!pf && GLUT_WIND_IS_MULTISAMPLE(displayMode)) {
         /* If we can't seem to get multisampling (ie, not Reality
            Engine class graphics!), go without multisampling.  It
            is up to the application to query how many multisamples
            were allocated (0 equals no multisampling) if the
            application is going to use multisampling for more than
            just antialiasing. */
         displayMode &= ~GLUT_MULTISAMPLE;
         pf = getPixelFormat(displayMode, gameMode);
      }
   }
   return pf;
}

NSOpenGLPixelFormat *__glutDetermineWindowPixelFormat(BOOL *treatAsSingle, BOOL gameMode)
{
   if(__glutDisplayString) {
      return __glutDeterminePixelFormatFromString(__glutDisplayString, treatAsSingle, gameMode);
   } else {
      return __glutDeterminePixelFormat(__glutDisplayMode, treatAsSingle, gameMode, createPixelFormat);
   }
}

GLUTView *__glutCreateWindow(GLUTView *parent, int x, int y, int width, int height, BOOL gameMode)
{
   NSOpenGLPixelFormat *	pixelFormat = nil;
   GLUTWindow *				win = nil;
   GLUTView *				view = nil;
   int						winnum;
   NSRect					rect;
   BOOL						treatAsSingle = NO;
   
   if(__glutGameModeWindow && !__glutDestoryingGameMode) {
      __glutFatalError("Cannot create windows in game mode.");
   }
   
   winnum = __glutGetUnusedWindowSlot();
   pixelFormat = __glutDetermineWindowPixelFormat(&treatAsSingle, gameMode);
   if(!pixelFormat) {
      __glutFatalError("pixel format with necessary capabilities not found.");
   }
     
   if (NO == __glutUseMacOSCoords) { // if we are using normal glut coords use default behavior for negatives
	 if(x < 0)
		 x = 50;
	 if(y < 0)
		 y = 50;
   }
   rect = NSMakeRect(x, y, ABS(width), ABS(height));
   
   if(!parent) {
      /* Create a top-level window */
      win = [[GLUTWindow alloc]	initWithContentRect: rect
                 pixelFormat: pixelFormat
                 windowID: winnum + 1
                 gameMode: gameMode
                 fullscreenStereo: _PFisFullscreenStereo(pixelFormat)
                 treatAsSingle: treatAsSingle];      
      if(!win) {
         __glutFatalError("out of memory.");
      }
      view = [win contentView];
      
      if (YES == __glutUseMacOSCoords) {
         // if we are using normal glut coords use default behavior for negatives
         // fixes appkit issue with windows on other than main screen
         [win setFrameOrigin: NSMakePoint(x, y)];
      }
      
      /* Force creation of the OGL surface now */
      [view lockFocus];
      [view unlockFocus];
   } else {
      /* Create a subwindow */
      view = [[GLUTView alloc]	initWithFrame: rect
                                 pixelFormat: pixelFormat
                                 windowID: winnum + 1
                                 treatAsSingle: treatAsSingle
								 isSubwindow: YES
								 fullscreenStereo: _PFisFullscreenStereo(pixelFormat)
								 isVBLSynced: __glutSyncToVBL];
      if(!view) {
         __glutFatalError("out of memory.");
      }
      [parent attachSubview: view];
   }
   
   do {
      /* Setup window to be mapped when glutMainLoop starts. */
      GLUTWorkEvent	event;
      
      INIT_WORK_EVENT(&event);
      event.workMask = GLUT_MAP_WORK;
      event.windowNum = [view windowID];
      if(gameMode) {
         /* When mapping a game mode window, we have to
            move it to the shielding window layer or it
            won't be visible. */
         event.desiredMapState = kGameModeState;
      } else {
         if(!parent && __glutIconic) {
            event.desiredMapState = kIconicState;
         } else {
            event.desiredMapState = kNormalState;
         }
      }
      __glutPostWorkEvent(&event);
   } while(0);
   
   /* Add this new window to the window list. */
   __glutViewList[winnum] = view;
   
   /* Make the new window the current window. */
   __glutSetWindow(view);
   
   if (__glutSyncToVBL) {
   }
   
	return view;
}

/* CENTRY */
int APIENTRY glutCreateWindow(const char *name)
{
   GLUTView *	view = nil;
   NSString *	title = nil;
   int			winID = -1;
   
   GLUTAPI_DECLARATIONS
   GLUTAPI_BEGIN
   if(__glutGameModeWindow && !__glutDestoryingGameMode) {
      __glutFatalError("Cannot create windows in game mode.");
   }
   
   if(name) {
      title = [NSString stringWithUTF8String: name];
   } else {
      title = [[NSProcessInfo processInfo] processName];
   }
   if(!title) {
      __glutFatalError("out of memory");
   }
   
   view = __glutCreateWindow(nil,
      __glutInitX, __glutScreenHeight - (__glutInitY + __glutInitHeight),
      __glutInitWidth, __glutInitHeight,
      /* not game mode */ NO);
   
   [[view window] setTitle: title];
   [[view window] setMiniwindowTitle: title];
   winID = [view windowID];
   GLUTAPI_END
   
   return winID;
}

int APIENTRY glutCreateSubWindow(int win, int x, int y, int width, int height)
{
   GLUTView *	parent = nil;
   GLUTView *	view = nil;
   int			winID = -1;
   
   GLUTAPI_DECLARATIONS
   GLUTAPI_BEGIN
   if(__glutGameModeWindow && !__glutDestoryingGameMode) {
      __glutFatalError("Cannot create windows in game mode.");
   }
   
   parent = __glutGetWindowByNum(win);
   if(!parent) {
      __glutWarning("glutCreateSubWindow attempted on bogus window.");
      GLUTAPI_VALUERETURN(int, 0);
   }
   
   view = __glutCreateWindow(parent, x, y, width, height, /* not game mode */ NO);
   winID = [view windowID];
   GLUTAPI_END
   
   return winID;
}
/* ENDCENTRY */

void __glutDestroyWindow(GLUTView *view)
{
   /* Tear down window itself. */
   if(![view isSubwindow]) {
      NSWindow *	glutWin = [view window];
      
      if(!__glutInsideWindowShouldClose) {
         /* A 08/15 window destroy operation */
         [glutWin setReleasedWhenClosed:YES];
		 // delay window destruction to ensure we are not in a sendEvent loop
		 [glutWin performSelector:@selector(close) withObject:nil afterDelay:0.0f];
      } else {
         /* We were called from inside a window close handler.
            Mark the window for destruction and let the AppKit
            take care of the rest. */
         [glutWin setReleasedWhenClosed:YES];
         __glutShouldWindowClose = YES;
      }
   } else {
      [view detachFromSuperview];
      [view release];
   }   
}

/* CENTRY */
void APIENTRY glutDestroyWindow(int win)
{
   GLUTView *	view = __glutGetWindowByNum(win);
   
   GLUTAPI_DECLARATIONS
   GLUTAPI_BEGIN
   if(!view) {
      __glutWarning("glutDestroyWindow attempted on bogus window %d.", win);
      GLUTAPI_VOIDRETURN;
   }
   __glutDestroyWindow(view);
   GLUTAPI_END
}
/* ENDCENTRY */

void __glutChangeWindowEventMask(int eventMask, BOOL add)
{
   int	winEventMask = [__glutCurrentView eventMask];
   
	if(add) {
      /* Add eventMask to window's event mask. */
      if((winEventMask & eventMask) != eventMask) {
         GLUTWorkEvent	event;
         
         [__glutCurrentView setEventMask: (winEventMask | eventMask)];
         INIT_WORK_EVENT(&event);
         event.workMask = GLUT_EVENT_MASK_WORK;
         event.windowNum = [__glutCurrentView windowID];
         __glutPostWorkEvent(&event);
      }
   } else {
      /* Remove eventMask from window's event mask. */
      if(winEventMask & eventMask) {
         GLUTWorkEvent	event;
         
         [__glutCurrentView setEventMask: (winEventMask & ~eventMask)];
         INIT_WORK_EVENT(&event);
         event.workMask = GLUT_EVENT_MASK_WORK;
         event.windowNum = [__glutCurrentView windowID];
         __glutPostWorkEvent(&event);
      }
   }
}

/* CENTRY */
void APIENTRY glutDisplayFunc(void (*func)(void))
{
   GLUTAPI_DECLARATIONS_FAST
   GLUTAPI_BEGIN_FAST
   [__glutCurrentView setDisplayCallback: func];
   GLUTAPI_END_FAST
}

void APIENTRY glutMouseFunc(void (*func)(int button, int state, int x, int y))
{
   GLUTAPI_DECLARATIONS_FAST
   GLUTAPI_BEGIN_FAST
   [__glutCurrentView setMouseCallback: func];
   GLUTAPI_END_FAST
}

void APIENTRY glutMotionFunc(void (*func)(int x, int y))
{
   GLUTAPI_DECLARATIONS_FAST
   GLUTAPI_BEGIN_FAST
   [__glutCurrentView setMotionCallback: func];
   GLUTAPI_END_FAST
}

void APIENTRY glutPassiveMotionFunc(void (*func)(int x, int y))
{
   GLUTAPI_DECLARATIONS_FAST
   GLUTAPI_BEGIN_FAST
   __glutChangeWindowEventMask(kPassiveMotionEvents, func != NULL);
   [__glutCurrentView setPassiveMotionCallback: func];
   GLUTAPI_END_FAST
}

void APIENTRY glutEntryFunc(void (*func)(int state))
{
   GLUTAPI_DECLARATIONS_FAST
   GLUTAPI_BEGIN_FAST
   __glutChangeWindowEventMask(kEntryEvents, func != NULL);
   [__glutCurrentView setEntryCallback: func];
   GLUTAPI_END_FAST
}

void APIENTRY glutWindowStatusFunc(void (*func)(int state))
{
   GLUTAPI_DECLARATIONS_FAST
   GLUTAPI_BEGIN_FAST
   [__glutCurrentView setWindowStatusCallback: func];
   GLUTAPI_END_FAST
}

static void visibilityHelper(int status)
{
   GLUTvisibilityCB	visibility = [__glutCurrentView visibilityCallback];
   
   if(status == GLUT_HIDDEN || status == GLUT_FULLY_COVERED)
      visibility(GLUT_NOT_VISIBLE);
   else
      visibility(GLUT_VISIBLE);
}

void APIENTRY glutVisibilityFunc(GLUTvisibilityCB func)
{
   GLUTAPI_DECLARATIONS_FAST
   GLUTAPI_BEGIN_FAST
   [__glutCurrentView setVisibilityCallback: func];
   if(func)
      glutWindowStatusFunc(visibilityHelper);
   else
      glutWindowStatusFunc(NULL);
   GLUTAPI_END_FAST
}

void APIENTRY glutReshapeFunc(void (*func)(int width, int height))
{
   GLUTAPI_DECLARATIONS_FAST
   GLUTAPI_BEGIN_FAST
   [__glutCurrentView setReshapeCallback: func];
   GLUTAPI_END_FAST
}

void APIENTRY glutWMCloseFunc(void (*func)(void))
{
   GLUTAPI_DECLARATIONS
   GLUTAPI_BEGIN
   if(func) {
      [__glutCurrentView setWMCloseCallback: func];
   } else {
      [__glutCurrentView setWMCloseCallback: __glutDefaultWMClose];
   }
   GLUTAPI_END
}

void APIENTRY glutSetWindowTitle(const char *name)
{
   NSString *	title = nil;
   
   GLUTAPI_DECLARATIONS
   IGNORE_IN_GAME_MODE()
   GLUTAPI_BEGIN
   if(name == NULL)
      name = "";
   title = [NSString stringWithUTF8String: name];
   if(!title) {
      __glutFatalError("out of memory");
   }
   if([__glutCurrentView isSubwindow]) {
      __glutWarning("glutSetWindowTitle attempted on subwindow %d", [__glutCurrentView windowID]);
      GLUTAPI_VOIDRETURN;
   }
   [[__glutCurrentView window] setTitle: title];
   GLUTAPI_END
}

void APIENTRY glutSetIconTitle(const char *name)
{
   NSString *	title = nil;
   
   GLUTAPI_DECLARATIONS
   IGNORE_IN_GAME_MODE()
   GLUTAPI_BEGIN
   if(name == NULL)
      name = "";
   title = [NSString stringWithUTF8String: name];
   if(title == nil) {
      __glutFatalError("out of memory");
   }
   if([__glutCurrentView isSubwindow]) {
      __glutWarning("glutSetIconTitle attempted on subwindow %d", [__glutCurrentView windowID]);
      GLUTAPI_VOIDRETURN;
   }
   [[__glutCurrentView window] setMiniwindowTitle: title];
   GLUTAPI_END
}

void APIENTRY glutPositionWindow(int x, int y)
{
   GLUTWorkEvent	event;
   
   IGNORE_IN_GAME_MODE();
   INIT_WORK_EVENT(&event);
   event.workMask = GLUT_CONFIGURE_WORK;
   event.windowNum = [__glutCurrentView windowID];
   event.desiredX = x;
   event.desiredY = y;
   event.desiredConfMask = (CWX | CWY);
   __glutPostWorkEvent(&event);
}

void APIENTRY glutReshapeWindow(int width, int height)
{
   GLUTWorkEvent	event;
   
   IGNORE_IN_GAME_MODE();
   if(width <= 0 || height <= 0)
      __glutWarning("glutReshapeWindow: non-positive width or height not allowed");
   
   INIT_WORK_EVENT(&event);
   event.workMask = GLUT_CONFIGURE_WORK;
   event.windowNum = [__glutCurrentView windowID];
   event.desiredWidth = ABS(width);
   event.desiredHeight = ABS(height);
   event.desiredConfMask = (CWWidth | CWHeight);
   __glutPostWorkEvent(&event);
}

void APIENTRY glutFullScreen(void)
{
   GLUTWorkEvent	event;
   
   IGNORE_IN_GAME_MODE();
   if([__glutCurrentView isSubwindow]) {
      __glutWarning("glutFullScreen attempted on subwindow %d", [__glutCurrentView windowID]);
      return;
   }
   INIT_WORK_EVENT(&event);
   event.workMask = GLUT_CONFIGURE_WORK;
   event.windowNum = [__glutCurrentView windowID];
   event.desiredConfMask = CWFullScreen;
   __glutPostWorkEvent(&event);
}

void APIENTRY glutPopWindow(void)
{
   GLUTWorkEvent	event;
   
   IGNORE_IN_GAME_MODE();
   INIT_WORK_EVENT(&event);
   event.workMask = GLUT_CONFIGURE_WORK;
   event.windowNum = [__glutCurrentView windowID];
   event.desiredStack = kAbove;
   event.desiredConfMask = CWStackMode;
   __glutPostWorkEvent(&event);
}

void APIENTRY glutPushWindow(void)
{
   GLUTWorkEvent	event;
   
   IGNORE_IN_GAME_MODE();
   INIT_WORK_EVENT(&event);
   event.workMask = GLUT_CONFIGURE_WORK;
   event.windowNum = [__glutCurrentView windowID];
   event.desiredStack = kBelow;
   event.desiredConfMask = CWStackMode;
   __glutPostWorkEvent(&event);
}

void APIENTRY glutIconifyWindow(void)
{
   GLUTWorkEvent	event;
   
   IGNORE_IN_GAME_MODE();
   if([__glutCurrentView isSubwindow]) {
      __glutWarning("glutIconifyWindow attempted on subwindow %d", [__glutCurrentView windowID]);
      return;
   }
   INIT_WORK_EVENT(&event);
   event.workMask = GLUT_MAP_WORK;
   event.windowNum = [__glutCurrentView windowID];
   event.desiredMapState = kIconicState;
   __glutPostWorkEvent(&event);
}

void APIENTRY glutShowWindow(void)
{
   GLUTWorkEvent	event;
   
   IGNORE_IN_GAME_MODE();
   INIT_WORK_EVENT(&event);
   event.workMask = GLUT_MAP_WORK;
   event.windowNum = [__glutCurrentView windowID];
   event.desiredMapState = kNormalState;
   __glutPostWorkEvent(&event);
}

void APIENTRY glutHideWindow(void)
{
   GLUTWorkEvent	event;
   
   IGNORE_IN_GAME_MODE();
   INIT_WORK_EVENT(&event);
   // hide = map work + kWithdrawnState
   event.workMask = GLUT_MAP_WORK;
   event.windowNum = [__glutCurrentView windowID];
   event.desiredMapState = kWithdrawnState;
   __glutPostWorkEvent(&event);
}

void APIENTRY glutSurfaceTexture (GLenum target, GLenum format, int surfacewin)
{
	GLUTView * surfaceView = __glutGetWindowByNum(surfacewin);

   GLUTAPI_DECLARATIONS
   GLUTAPI_BEGIN
   if(!surfaceView) {
      __glutWarning("glutSurfaceTexture attempted on bogus window.");
      GLUTAPI_VOIDRETURN;
   }
	[[__glutCurrentView openGLContext] createTexture:target fromView:surfaceView internalFormat:format];
   GLUTAPI_END
}
/* ENDCENTRY */

