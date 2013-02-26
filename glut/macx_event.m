/* Copyright (c) Dietmar Planitzer, 2002 - 2003 */

/* This program is freely distributable without licensing fees 
   and is provided without guarantee or warrantee expressed or 
   implied. This program is -not- in the public domain. */

#import "macx_glut.h"
#import "GLUTApplication.h"
#import "GLUTView.h"
#import "GLUTWindow.h"

GLUTidleCB				__glutIdleFunc = NULL;
GLUTidleFCB			     __fglutIdleFunc = NULL; /* fortran callback */
GLUTTimer *				__glutMostRecentTimer = NULL;
static GLUTTimer *		__glutCachedTimers = NULL;
static int				__glutNumCachedTimers = 0;
static GLUTWorkEvent *	__glutWindowWorkList = NULL;
static GLUTWorkEvent *	__glutCachedWorkEvents = NULL;
static int				__glutNumCachedWorkEvents = 0;
unsigned int			__glutMouseFirstModifiers = kMouseFirstModifiers; /* initial values */
static int				__glutMouseFirstButton = GLUT_RIGHT_BUTTON;
unsigned int			__glutMouseSecondModifiers = kMouseSecondModifiers;
static int				__glutMouseSecondButton = GLUT_MIDDLE_BUTTON;
static unsigned int		__glutMouseMiddleModifiers = 0;
BOOL					__glutEmulateMouseButtons = kEmulateMouseButtons;


/* CENTRY */
void APIENTRY glutIdleFunc(void (*func)(void))
{
   __glutIdleFunc = func;
}
/* ENDCENTRY */


static void __glutTimerCallBack(CFRunLoopTimerRef timer, GLUTTimer* context)
{
   GLUTtimerCB	func = context->func;
   int			value = context->value;

   __glutProcessWorkEvents();
   void __glutFreeTimer(GLUTTimer *);
   __glutFreeTimer(context);

   if(func)
      func(value);
      
   if(__glutMostRecentTimer == context) {
      /* Set __glutMostRecentTimer to NULL, if we're the most recent timer.
         If another timer has been created in the meantime, __glutMostRecentTimer
         would now point to that timer and consequently we would not change it. */
      __glutMostRecentTimer = NULL;
   }
   __glutProcessWorkEvents(); // ensure we do not miss glut work events
}

void __glutFreeTimer(GLUTTimer *timer)
{
   CFRunLoopRemoveTimer(CFRunLoopGetCurrent(), timer->timer, kCFRunLoopCommonModes);
   
   if(__glutNumCachedTimers < GLUT_MAX_CACHED_TIMERS) {
      timer->next = __glutCachedTimers;
      __glutCachedTimers = timer;
      __glutNumCachedTimers++;
   } else {
      CFRelease(timer->timer);
      free(timer);
   }
}

static GLUTTimer *__glutAllocateTimer(unsigned int msecs)
{
   GLUTTimer *		timer;
   CFAbsoluteTime	fireTime;
   
   // Compute first/next fire time
   if (msecs) // ensure timers of zero delay fire
      fireTime = CFAbsoluteTimeGetCurrent() + ((CFAbsoluteTime) msecs) / 1000.0;
   else
      fireTime = CFAbsoluteTimeGetCurrent() + 0.00001;
   
   if(__glutNumCachedTimers > 0) {
      /* Recycle one of the cached timers */
      timer = __glutCachedTimers;
      __glutCachedTimers = timer->next;
      __glutNumCachedTimers--;
      if(__glutNumCachedTimers == 0)
         __glutCachedTimers = NULL;
      CFRunLoopTimerSetNextFireDate(timer->timer, fireTime);
   } else {
      /* Our cache is empty - allocate a new timer */
      timer = (GLUTTimer *) calloc(1, sizeof(GLUTTimer));
      if(!timer) {
         __glutFatalError("out of memory");
      }
      timer->context.info = timer;
      timer->timer = CFRunLoopTimerCreate(NULL,
                           fireTime,
                           1.0,	 // interval
                           0,		 // flags
                           0,		 // order
                           (CFRunLoopTimerCallBack) __glutTimerCallBack,
                           (CFRunLoopTimerContext *) timer);
      if(!timer->timer) {
         free(timer);
         __glutFatalError("out of memory");
      }
   }
   
   return timer;
}

/* CENTRY */
void APIENTRY glutTimerFunc(unsigned int msecs, void (*func)(int value), int value)
{
   GLUTTimer *		timer = __glutAllocateTimer(msecs);
   timer->func = func;
   timer->value = value;
   CFRunLoopAddTimer(CFRunLoopGetCurrent(), timer->timer, kCFRunLoopCommonModes);
   
   __glutMostRecentTimer = timer;
}
/* ENDCENTRY */

static inline GLUTWorkEvent *__glutFindEventForWindow(int win)
{
   register GLUTWorkEvent *	evp = __glutWindowWorkList;
   
   while(evp) {
      if(evp->windowNum == win)
         break;
      evp = evp->prevWorkEvent;
   }
   return evp;
}

static GLUTWorkEvent *__glutAllocateWorkEvent(void)
{
   register GLUTWorkEvent *	evp;
   
   if(__glutNumCachedWorkEvents > 0) {
      /* Recycle one of the cached work events */
      evp = __glutCachedWorkEvents;
      __glutCachedWorkEvents = evp->prevWorkEvent;
      __glutNumCachedWorkEvents--;
      if(__glutNumCachedWorkEvents == 0)
         __glutCachedWorkEvents = NULL;
   } else {
      /* Our cache is empty - allocate a new work event */
      evp = (GLUTWorkEvent *) malloc(sizeof(GLUTWorkEvent));
   }
   
   if(!evp) {
      __glutFatalError("out of memory");
   }
   
   return evp;
}

static void __glutFreeWorkEvent(GLUTWorkEvent *evt)
{
   if(__glutNumCachedWorkEvents < GLUT_MAX_CACHED_WORK_EVENTS) {
      /* We abuse the prevWorkEvent ptr as a nextWorkEvent ptr... */
      evt->prevWorkEvent = __glutCachedWorkEvents;
      __glutCachedWorkEvents = evt;
      __glutNumCachedWorkEvents++;
   } else {
      free(evt);
   }
}

void __glutPostWorkEvent(GLUTWorkEvent *event)
{
   register GLUTWorkEvent *	evp;
   
   /* Find out if there is already another event destinated
      for the same window as the event we're supposed to
      send. If so merge both together. */
   evp = __glutFindEventForWindow(event->windowNum);
   
   if(evp) {
      /* Another event for an already known window - merge
         new event into already existing one */
      evp->workMask |= event->workMask;
      if(event->workMask & (GLUT_MAP_WORK | GLUT_CONFIGURE_WORK)) {
         if(event->workMask & GLUT_MAP_WORK)
            evp->desiredMapState = event->desiredMapState;
         
         if(event->workMask & GLUT_CONFIGURE_WORK) {
            evp->desiredConfMask |= event->desiredConfMask;
            if(event->desiredConfMask & (CWX | CWY)) {
               evp->desiredX = event->desiredX;
               evp->desiredY = event->desiredY;
            }
            if(event->desiredConfMask & (CWWidth | CWHeight)) {
               evp->desiredWidth = event->desiredWidth;
               evp->desiredHeight = event->desiredHeight;
            }
            if(event->desiredConfMask & CWStackMode) {
               evp->desiredStack = event->desiredStack;
            }
         }
      }
   } else {
      /* An event for an unknown window - allocate a new
         event record and enqueue it */
      evp = __glutAllocateWorkEvent();
      *evp = *event;
      evp->prevWorkEvent = __glutWindowWorkList;
      __glutWindowWorkList = evp;
   }
   
#if __GLUT_LOG_WORK_EVENTS
   printf("__glutPostWorkEvent() {\n");
   __glutPrintWorkMask(evp, event->windowNum, 0);
   printf("}\n");
#endif
}

void __glutPurgeWorkEvents(int win)
{
   GLUTWorkEvent **	pEntry = &__glutWindowWorkList;
   GLUTWorkEvent *	entry = __glutWindowWorkList;
   
   /* Traverse singly-linked work list and look for the window. */
   while(entry) {
      if(entry->windowNum == win) {
         /* Found it; delete it. */
         *pEntry = entry->prevWorkEvent;
         __glutFreeWorkEvent(entry);
         return;
      }
      pEntry = &entry->prevWorkEvent;
      entry = *pEntry;
   }
}

void __glutPostRedisplay(GLUTView * view, int layerMask)
{
   int	shown = [view isShown];
   int	visState = [view visibilityState];
   
   /* Post a redisplay if the window is visible (or the
      visibility of the window is unknown, ie. window->visState
      == -1) _and_ the layer is known to be shown. */
   if(visState != GLUT_HIDDEN && visState != GLUT_FULLY_COVERED && shown) {
      GLUTWorkEvent	event;
      
      INIT_WORK_EVENT(&event);
      event.workMask = layerMask;
      event.windowNum = [view windowID];
      __glutPostWorkEvent(&event);
   }
}

/* CENTRY */
void APIENTRY glutPostRedisplay(void)
{
   GLUTAPI_DECLARATIONS_FAST
   GLUTAPI_BEGIN_FAST
   __glutPostRedisplay(__glutCurrentView, GLUT_REDISPLAY_WORK);
   GLUTAPI_END_FAST
}

/* The advantage of this routine is that it saves the cost of a
   glutSetWindow call (entailing an expensive OpenGL context switch),
   particularly useful when multiple windows need redisplays posted at
   the same times.  See also glutPostWindowOverlayRedisplay. */
void APIENTRY glutPostWindowRedisplay(int win)
{
	GLUTView * view = __glutGetWindowByNum(win);
   
   GLUTAPI_DECLARATIONS_FAST
   GLUTAPI_BEGIN_FAST
 	if(view)
		__glutPostRedisplay(view, GLUT_REDISPLAY_WORK);
	else
		__glutWarning("glutPostWindowRedisplay attempted on bogus window.");
   GLUTAPI_END_FAST
}
/* ENDCENTRY */


static GLUTWorkEvent **beforeEnd;

static GLUTWorkEvent *processWindowWorkList(GLUTWorkEvent *event)
{
   GLUTView *			view = nil;
   GLUTWorkEvent *	tmpEvt;
   
   if(event->prevWorkEvent) {
      event->prevWorkEvent = processWindowWorkList(event->prevWorkEvent);
   } else {
      beforeEnd = &event->prevWorkEvent;
   }
   
   view = __glutGetWindowByNum(event->windowNum);
   if(!view) {
      /* GLUT window died in the meantime - just ignore event */
      tmpEvt = event->prevWorkEvent;
      __glutFreeWorkEvent(event);
      return tmpEvt;
   }
   
   [view handleWorkEvent: event];
   
   if (event->workMask) {
      /* Leave on work list. */
      return event;
   } else {
      /* Remove current window from work list. */
      tmpEvt = event->prevWorkEvent;
      __glutFreeWorkEvent(event);
      return tmpEvt;
   }
}

void __glutProcessWorkEvents(void)
{
   if(__glutWindowWorkList) {
      GLUTWorkEvent *	workRemainder, *work;
      
      work = __glutWindowWorkList;
      __glutWindowWorkList = NULL;
      if(work) {
         workRemainder = processWindowWorkList(work);
         if(workRemainder) {
            *beforeEnd = __glutWindowWorkList;
            __glutWindowWorkList = workRemainder;
         }
      }
   }
}

BOOL __glutHasWorkEvents(void)
{
   return (__glutWindowWorkList != NULL);
}

static int __glutCountWindows(void)
{
   NSArray *		windows = [NSApp windows];
   unsigned int	i, count = [windows count];
   int				num = 0;
   
   for(i = 0; i < count; i++) {
      id	win = [windows objectAtIndex: i];
      
      if([win isKindOfClass: [GLUTWindow class]])
         num++;
   }
   return num;
}

/* CENTRY */
void APIENTRY  glutCheckLoop(void)
{
   GLUTAPI_DECLARATIONS
	GLUTAPI_BEGIN
	if(NSApp == nil) {
		__glutFatalUsage("main loop entered without proper initialization."); // will exit
	}

   [NSApp runOnce];
	GLUTAPI_END
}

void APIENTRY glutMainLoop(void)
{
   GLUTAPI_DECLARATIONS
	GLUTAPI_BEGIN 
	if(NSApp == nil) {
		__glutFatalUsage("main loop entered without proper initialization."); // will exit
	}
	if(__glutCountWindows() == 0)
		__glutFatalUsage("main loop entered with no windows created."); // will exit

    [NSApp run];
	GLUTAPI_END
}
/* ENDCENTRY */

void __glutMapKeyCode(NSEvent *theEvent, char *utf8, int *utf8Length, BOOL *isSpecial)
{
   NSString *		utf16 = [theEvent characters];
   const char *	ptr;
   int				i;
   
   if(*utf8Length < 1)
      return;
   
   *isSpecial = NO;
   if([utf16 length] == 1) {
      /* A single UTF16 character. Do one of the following:
         a) Is it in the range [0, 127] ? -> simply return it as a single UTF8 character.
         b) Is it a special character ? -> simply return it as a special character.
         c) Else -> convert the UTF16 string to a UTF8 string and return it. */
      unichar	ukey = [utf16 characterAtIndex: 0];
      int		savedLength = *utf8Length;

      *utf8Length = 1;
      if(ukey <= 127) {
         utf8[0] = (ukey & 0xFF);
         return;
      }
      
      *isSpecial = YES;
      switch(ukey) {
         case NSF1FunctionKey:
                  utf8[0] = GLUT_KEY_F1;
                  return;
         case NSF2FunctionKey:
                  utf8[0] = GLUT_KEY_F2;
                  return;
         case NSF3FunctionKey:
                  utf8[0] = GLUT_KEY_F3;
                  return;
         case NSF4FunctionKey:
                  utf8[0] = GLUT_KEY_F4;
                  return;
         case NSF5FunctionKey:
                  utf8[0] = GLUT_KEY_F5;
                  return;
         case NSF6FunctionKey:
                  utf8[0] = GLUT_KEY_F6;
                  return;
         case NSF7FunctionKey:
                  utf8[0] = GLUT_KEY_F7;
                  return;
         case NSF8FunctionKey:
                  utf8[0] = GLUT_KEY_F8;
                  return;
         case NSF9FunctionKey:
                  utf8[0] = GLUT_KEY_F9;
                  return;
         case NSF10FunctionKey:
                  utf8[0] = GLUT_KEY_F10;
                  return;
         case NSF11FunctionKey:
                  utf8[0] = GLUT_KEY_F11;
                  return;
         case NSF12FunctionKey:
                  utf8[0] = GLUT_KEY_F12;
                  return;
         case NSUpArrowFunctionKey:
                  utf8[0] = GLUT_KEY_UP;
                  return;
         case NSDownArrowFunctionKey:
                  utf8[0] = GLUT_KEY_DOWN;
                  return;
         case NSLeftArrowFunctionKey:
                  utf8[0] = GLUT_KEY_LEFT;
                  return;
         case NSRightArrowFunctionKey:
                  utf8[0] = GLUT_KEY_RIGHT;
                  return;
         case NSPageUpFunctionKey:
                  utf8[0] = GLUT_KEY_PAGE_UP;
                  return;
         case NSPageDownFunctionKey:
                  utf8[0] = GLUT_KEY_PAGE_DOWN;
                  return;
         case NSHomeFunctionKey:
                  utf8[0] = GLUT_KEY_HOME;
                  return;
         case NSEndFunctionKey:
                  utf8[0] = GLUT_KEY_END;
                  return;
         case NSInsertFunctionKey:
         case NSInsertCharFunctionKey:
                  utf8[0] = GLUT_KEY_INSERT;
                  return;
         case NSDeleteFunctionKey:
         case NSDeleteCharFunctionKey:
                  /* This is actually Backspace */
                  *isSpecial = NO;
                  utf8[0] = 0x08;
                  return;
      }
      *utf8Length = savedLength;
   }

   *isSpecial = NO;
   /* Special handling for non-US keyboards: Some valid ASCII characters
      are generated with the ALT modifier. I.e. on German keyboards,
      the '[' character is generated by entering Alt-5. However,
      generically, we want to ignore the effect which the ALT key
      has on the characters.*/
   utf16 = [theEvent charactersIgnoringModifiers];
   
   /* Still here ? Then either 'utf16' contains more than one UTF16 character
      and thus is most likely a composite character sequence or 'utf16' 
      contains a single 'real' Unicode character. */
   ptr = [utf16 UTF8String];
   i = 0;
   while(i < *utf8Length && ptr[i] != '\0') {
      utf8[i] = ptr[i];
      i++;
   }
   *utf8Length = i;
}

/**
 * Analyzes the given mouse up/down event and returns in 'buttonID' what mouse
 * button the given event corresponds to. 'modifiers' is set to the modifier
 * flags which should be passed on to the GLUT application.
 */
void __glutMapMouseButton(NSEvent *theEvent, int *buttonID, int *buttonPhysID, unsigned int *modifiers)
{
	unsigned int	mflags = [theEvent modifierFlags];
	if ((__glutEmulateMouseButtons) && ([theEvent buttonNumber] == 0)) {
		*buttonPhysID = 0; // main mouse button (left) is physically pressed
		if((mflags & __glutMouseFirstModifiers) == __glutMouseFirstModifiers) { // right
			*buttonID = __glutMouseFirstButton;
			*modifiers = mflags & ~__glutMouseFirstModifiers;
		} else if((mflags & __glutMouseSecondModifiers) == __glutMouseSecondModifiers) { // middle
			*buttonID = __glutMouseSecondButton;
			*modifiers = mflags & ~__glutMouseSecondModifiers;
		} else {
			*buttonID = GLUT_LEFT_BUTTON;
			*modifiers = mflags;
		}
	} else { // handle non-emulated button 0 and all other buttons
		switch([theEvent buttonNumber]) {
			case 0:
				*buttonID = GLUT_LEFT_BUTTON;
				break;
			case 1:
				*buttonID = GLUT_RIGHT_BUTTON;
				break;
			case 2:
				*buttonID = GLUT_MIDDLE_BUTTON;
				break;
			default:
				*buttonID = -1;
				break;
		}
		*buttonPhysID = *buttonID;
		*modifiers = mflags;   
	}
}

/**
 * Sorts the given middle & right modifiers so that __glutMapMouseButton() will
 * always prefer the mouse button that has the most modifier flags set.
 */
void __glutSetMouseModifiers(unsigned int middleFlags, unsigned int rightFlags)
{
   int	middleRank = 0, rightRank = 0;
   
   /* Compute ranks for middle & right flags */
   if((middleFlags & NSAlternateKeyMask) == NSAlternateKeyMask)
      middleRank++;
   if((middleFlags & NSControlKeyMask) == NSControlKeyMask)
      middleRank++;
   if((middleFlags & NSShiftKeyMask) == NSShiftKeyMask)
      middleRank++;
   if((middleFlags & NSCommandKeyMask) == NSCommandKeyMask)
      middleRank++;
      
   if((rightFlags & NSAlternateKeyMask) == NSAlternateKeyMask)
      rightRank++;
   if((rightFlags & NSControlKeyMask) == NSControlKeyMask)
      rightRank++;
   if((rightFlags & NSShiftKeyMask) == NSShiftKeyMask)
      rightRank++;
   if((rightFlags & NSCommandKeyMask) == NSCommandKeyMask)
      rightRank++;
      
   if(middleRank == rightRank) {
      /* Always prefer right mouse clicks over middle ones, if both have equal ranks */
      __glutMouseFirstModifiers = rightFlags;
      __glutMouseFirstButton = GLUT_RIGHT_BUTTON;
      __glutMouseSecondModifiers = middleFlags;
      __glutMouseSecondButton = GLUT_MIDDLE_BUTTON;
   } else if(middleRank > rightRank) {
      /* Middle mouse button requires more modifiers, __glutMapMouseButton() should check it first */
      __glutMouseFirstModifiers = middleFlags;
      __glutMouseFirstButton = GLUT_MIDDLE_BUTTON;
      __glutMouseSecondModifiers = rightFlags;
      __glutMouseSecondButton = GLUT_RIGHT_BUTTON;
   } else {
      /* Right mouse button requires more modifiers, __glutMapMouseButton() should check it first */
      __glutMouseFirstModifiers = rightFlags;
      __glutMouseFirstButton = GLUT_RIGHT_BUTTON;
      __glutMouseSecondModifiers = middleFlags;
      __glutMouseSecondButton = GLUT_MIDDLE_BUTTON;
   }
   
   /* Remember middle flags explicitly for two button mices */
   __glutMouseMiddleModifiers = middleFlags;
}
