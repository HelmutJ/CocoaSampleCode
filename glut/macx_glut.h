
/* Copyright (c) Dietmar Planitzer, 1998, 2002 */
/* Copyright (c) Apple Computer, 2002-2004 */

/* This program is freely distributable without licensing fees 
   and is provided without guarantee or warrantee expressed or 
   implied. This program is -not- in the public domain. */

#import <CoreFoundation/CoreFoundation.h>
#import <ApplicationServices/ApplicationServices.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>

#import "glut.h"
#import "glutf90.h"
#import "macx_utilities.h"
#import "HID_Utilities_External.h"

#ifndef APIENTRY
#define APIENTRY
#endif
#ifndef GLUTCALLBACK
#define GLUTCALLBACK
#endif

#define MACRO_BEGIN do {
#define MACRO_END   } while(0);

/* Debugging macros  begin*/
//#define __GLUT_LOG_PIXELFORMAT	1
//#define __GLUT_LOG_VISIBILITY	1
//#define __GLUT_LOG_WORK_EVENTS 1
/* Debugging macros end */

#define GLUT_UNKNOWN_VISIBILITY		(GLUT_FULLY_COVERED+1)
#define GLUT_NORMAL_LEVEL				NSNormalWindowLevel
#define GLUT_FULLSCREEN_LEVEL			(NSPopUpMenuWindowLevel-1)
#define GLUT_GAMEMODE_LEVEL			CGShieldingWindowLevel()
#define GLUT_DEFAULT_IDLE_INTERVAL	0.016		/* ca. 60Hz */
#define GLUT_DEFAULT_FADE_INTERVAL	0.75     /* 0.75 second */
#define GLUT_MAX_CACHED_WORK_EVENTS	4
#define GLUT_MAX_CACHED_TIMERS		4

#define GLUT_WIND_IS_RGB(x)         (((x) & GLUT_INDEX) == 0)
#define GLUT_WIND_IS_INDEX(x)       (((x) & GLUT_INDEX) != 0)
#define GLUT_WIND_IS_SINGLE(x)      (((x) & GLUT_DOUBLE) == 0)
#define GLUT_WIND_IS_DOUBLE(x)      (((x) & GLUT_DOUBLE) != 0)
#define GLUT_WIND_HAS_ACCUM(x)      (((x) & GLUT_ACCUM) != 0)
#define GLUT_WIND_HAS_ALPHA(x)      (((x) & GLUT_ALPHA) != 0)
#define GLUT_WIND_HAS_DEPTH(x)      (((x) & GLUT_DEPTH) != 0)
#define GLUT_WIND_HAS_STENCIL(x)    (((x) & GLUT_STENCIL) != 0)
#define GLUT_WIND_IS_MULTISAMPLE(x) (((x) & GLUT_MULTISAMPLE) != 0)
#define GLUT_WIND_IS_STEREO(x)      (((x) & GLUT_STEREO) != 0)
#define GLUT_WIND_IS_LUMINANCE(x)   (((x) & GLUT_LUMINANCE) != 0)
#define GLUT_WIND_IS_NO_RECOVERY(x) (((x) & GLUT_NO_RECOVERY) != 0)

/* Work events (not all are currently used...) */
#define GLUT_MAP_WORK               (1 << 0)
#define    kWithdrawnState             1
#define    kNormalState                2
#define    kIconicState                3
#define    kGameModeState              4
#define GLUT_REDISPLAY_WORK            (1 << 1)
#define GLUT_CONFIGURE_WORK            (1 << 2)
#define    CWX                         (1 << 0)
#define    CWY                         (1 << 1)
#define    CWWidth                     (1 << 2)
#define    CWHeight                    (1 << 3)
#define    CWStackMode                 (1 << 4)
#define    CWFullScreen                (1 << 5)
#define    kAbove                      1
#define    kBelow                      2
#define GLUT_EVENT_MASK_WORK           (1 << 3)
#define    kPassiveMotionEvents        (1 << 0)
#define    kEntryEvents                (1 << 1)
#define GLUT_COLORMAP_WORK             (1 << 4)
#define GLUT_DEVICE_MASK_WORK          (1 << 5)
#define GLUT_DEBUG_WORK                (1 << 6)
#define GLUT_DUMMY_WORK                (1 << 7)
#define GLUT_OVERLAY_REDISPLAY_WORK    (1 << 8)

typedef struct _GLUTWorkEvent GLUTWorkEvent;
struct _GLUTWorkEvent
{
   GLUTWorkEvent *	prevWorkEvent;     /* linked list of events to work on */
   unsigned int		workMask;          /* mask of window work to be done */
   int					windowNum;         /* GLUT window number */
   int					desiredMapState;   /* how to map window if on map work list */
   int					desiredConfMask;   /* mask of desired window configuration */
   int					desiredX;          /* desired X location */
   int					desiredY;          /* desired Y location */
   int					desiredWidth;      /* desired window width */
   int					desiredHeight;   	 /* desired window height */
   int					desiredStack;    	 /* desired window stack */
};


/* List (used for subwindow management) */
typedef struct _GLUTNode
{
   struct _GLUTNode *	succ;
   struct _GLUTNode *	pred;
   void *					obj;
} GLUTNode;

typedef struct _GLUTList
{
   GLUTNode		head;
   GLUTNode		tail;
} GLUTList;


/* Frame buffer capability macros and types. */
#define RGBA                    0
#define BUFFER_SIZE             1
#define DOUBLEBUFFER            2
#define STEREO                  3
#define AUX_BUFFERS             4
#define RED_SIZE                5  /* Used as mask bit for
                                      "color selected". */
#define GREEN_SIZE              6
#define BLUE_SIZE               7
#define ALPHA_SIZE              8
#define DEPTH_SIZE              9
#define STENCIL_SIZE            10
#define ACCUM_RED_SIZE          11  /* Used as mask bit for
                                       "acc selected". */
#define ACCUM_GREEN_SIZE        12
#define ACCUM_BLUE_SIZE         13
#define ACCUM_ALPHA_SIZE        14

#define NUM_GLXCAPS             (ACCUM_ALPHA_SIZE + 1)

#define SAMPLES                 (NUM_GLXCAPS + 0)
#define SLOW                    (NUM_GLXCAPS + 1)
#define CONFORMANT              (NUM_GLXCAPS + 2)

#define NO_RECOVERY             (NUM_GLXCAPS + 3)

#define NUM_CAPS                (NUM_GLXCAPS + 4)

/* Frame buffer capablities that don't have a corresponding
   FrameBufferMode entry.  These get used as mask bits. */
#define NUM                     (NUM_CAPS + 0)
#define RGBA_MODE               (NUM_CAPS + 1)
#define CI_MODE                 (NUM_CAPS + 2)
#define LUMINANCE_MODE		     (NUM_CAPS + 3)

#define CMP_NONE	0
#define CMP_EQ		1
#define CMP_NEQ	2
#define CMP_LT		3
#define CMP_GT		4
#define CMP_LTE	5
#define CMP_GTE	6
#define CMP_MIN	7
typedef struct _Criterion
{
   int	capability;
   int	comparison;
   int	value;
} Criterion;


/* DisplayMode capability macros for game mode. */
#define DM_WIDTH			0
#define DM_HEIGHT			1
#define DM_PIXEL_DEPTH	2
#define DM_HERTZ			3
#define DM_NUM				4

#define NUM_DM_CAPS     (DM_NUM+1)

typedef struct _DisplayMode
{
   CFDictionaryRef	cgModeDict;	/* weak ref */
   int					valid;
   int					cap[NUM_DM_CAPS];
} DisplayMode;


/* GLUT  function types */
typedef void (GLUTCALLBACK *GLUTdisplayCB) (void);
typedef void (GLUTCALLBACK *GLUTreshapeCB) (int, int);
typedef void (GLUTCALLBACK *GLUTkeyboardCB) (unsigned char, int, int);
typedef void (GLUTCALLBACK *GLUTmouseCB) (int, int, int, int);
typedef void (GLUTCALLBACK *GLUTmotionCB) (int, int);
typedef void (GLUTCALLBACK *GLUTpassiveCB) (int, int);
typedef void (GLUTCALLBACK *GLUTentryCB) (int);
typedef void (GLUTCALLBACK *GLUTvisibilityCB) (int);
typedef void (GLUTCALLBACK *GLUTwindowStatusCB) (int);
typedef void (GLUTCALLBACK *GLUTidleCB) (void);
typedef void (GLUTCALLBACK *GLUTtimerCB) (int);
typedef void (GLUTCALLBACK *GLUTmenuStateCB) (int);  /* DEPRICATED. */
typedef void (GLUTCALLBACK *GLUTmenuStatusCB) (int, int, int);
typedef void (GLUTCALLBACK *GLUTselectCB) (int);
typedef void (GLUTCALLBACK *GLUTspecialCB) (int, int, int);
typedef void (GLUTCALLBACK *GLUTspaceMotionCB) (int, int, int);
typedef void (GLUTCALLBACK *GLUTspaceRotateCB) (int, int, int);
typedef void (GLUTCALLBACK *GLUTspaceButtonCB) (int, int);
typedef void (GLUTCALLBACK *GLUTdialsCB) (int, int);
typedef void (GLUTCALLBACK *GLUTbuttonBoxCB) (int, int);
typedef void (GLUTCALLBACK *GLUTtabletMotionCB) (int, int);
typedef void (GLUTCALLBACK *GLUTtabletButtonCB) (int, int, int, int);
typedef void (GLUTCALLBACK *GLUTjoystickCB) (unsigned int buttonMask, int x, int y, int z);
typedef void (GLUTCALLBACK *GLUTwmcloseCB) (void);


/* Timer context. */
typedef struct _GLUTTimer {
   CFRunLoopTimerContext		context;
   struct _GLUTTimer *			next;
   CFRunLoopTimerRef			timer;
   GLUTtimerCB					func;
   GLUTtimerFCB					fFunc;
   int							value;
} GLUTTimer;


// HID Input definitions
#define GLUT_MOUSE_DEVICE 0
#define GLUT_KEYBOARD_DEVICE 1
#define GLUT_JOYSTICK_DEVICE 2
#define GLUT_SPACEBALL_DEVICE 3

typedef struct _GLUTDeviceEnumerator
{
   pRecDevice	curDevice;
   UInt32		typeDevice;  // one of above types
//   SInt32		usagePage[2];
//   SInt32		usage[2];
//   UInt32		numTypes;
   BOOL			done;
} GLUTDeviceEnumerator;

enum
{
    kActionXAxis,
    kActionYAxis,
    kActionZAxis,
    kActionButton1,
    kActionButton2,
    kActionButton3,
    kActionButton4,
    kActionButton5,
    kActionButton6,
    kActionButton7,
    kActionButton8,
    kActionButton9,
    kActionButton10,
    kActionButton11,
    kActionButton12,
    kActionButton13,
    kActionButton14,
    kActionButton15,
    kActionButton16,
    kActionButton17,
    kActionButton18,
    kActionButton19,
    kActionButton20,
    kActionButton21,
    kActionButton22,
    kActionButton23,
    kActionButton24,
    kActionButton25,
    kActionButton26,
    kActionButton27,
    kActionButton28,
    kActionButton29,
    kActionButton30,
    kActionButton31,
    kActionButton32,
	kNumJoystickActions
};

enum
{
    kSBActionXAxis,
    kSBActionYAxis,
    kSBActionZAxis,
    kSBActionXRotation,
    kSBActionYRotation,
    kSBActionZRotation,
    kSBActionButton1,
    kSBActionButton2,
    kSBActionButton3,
    kSBActionButton4,
    kSBActionButton5,
    kSBActionButton6,
    kSBActionButton7,
    kSBActionButton8,
    kSBActionButton9,
    kSBActionButton10,
    kSBActionButton11,
    kSBActionButton12,
    kSBActionButton13,
    kSBActionButton14,
    kSBActionButton15,
    kSBActionButton16,
    kSBActionButton17,
    kSBActionButton18,
    kSBActionButton19,
    kSBActionButton20,
    kSBActionButton21,
    kSBActionButton22,
    kSBActionButton23,
    kSBActionButton24,
    kSBActionButton25,
    kSBActionButton26,
    kSBActionButton27,
    kSBActionButton28,
    kSBActionButton29,
    kSBActionButton30,
    kSBActionButton31,
    kSBActionButton32,
	kNumSpaceballActions
};

typedef struct _GLUTinputActionRec
{
    pRecElement pElement;
    pRecDevice pDevice;
	int invertMul;
    int value;
} GLUTinputActionRec;

@class GLUTView, GLUTWindow, GLUTMenu;

enum {
	kUseMacOSCoords = NO,
	kUseInitWD = NO,
	kUseExtendedDesktop = NO,
	kIconic = NO,
	kDebug = NO,
	kInitWidth = 300,
	kInitHeight = 300,
	kInitX = -1,
	kInitY = -1,
	kCaptureAllDisplays = YES,
	kSyncToVBL = NO,
	kEmulateMouseButtons = NO,
	kMouseFirstModifiers = NSControlKeyMask,
	kMouseSecondModifiers = NSAlternateKeyMask
};

extern int						__glutArgc;
extern char **					__glutArgv;
extern int						__glutScreenHeight;
extern int						__glutScreenWidth;
extern BOOL						__glutUseMacOSCoords;
extern BOOL						__glutIconic;
extern BOOL						__glutDebug;
extern unsigned int				__glutDisplayMode;
extern char *					__glutDisplayString;
extern int						__glutInitWidth;
extern int						__glutInitHeight;
extern int						__glutInitX;
extern int						__glutInitY;
extern GLUTView **				__glutViewList;
extern int						__glutViewListSize;
extern GLUTView *				__glutCurrentView;
extern GLUTWindow *				__glutFullscreenWindows;
extern GLUTView *				__glutGameModeWindow;	/* != 0 -> game mode, == 0 -> not in game mode */
extern BOOL                     __glutDestoryingGameMode;
extern GLUTidleCB				__glutIdleFunc;
extern NSTimeInterval			__glutIdleTimeInterval;
extern GLUTMenu *				__glutMappedMenu;
extern GLUTView *				__glutMenuWindow;
extern GLUTmenuStatusCB			__glutMenuStatusFunc;
extern BOOL						__glutDisableGrabbing;
extern BOOL						__glutDisablePrinting;
extern NSTimeInterval			__glutStartupTime;
extern int						__glutDefaultColorSize;
extern unsigned int				__glutModifierMask;
extern GLUTMenu *			    __glutCurrentMenu;
extern BOOL						__glutCaptureAllDisplays;
extern GLint					__glutFPS;
extern BOOL						__glutShouldWindowClose;        /* -windowShouldClose: && glutDestroyWindow */
extern BOOL						__glutInsideWindowShouldClose;  /* -windowShouldClose: && glutDestroyWindow */
extern BOOL						__glutUseExtendedDesktop;  		/* upper left of desktop is (0, 0) */
extern BOOL						__glutUseInitWD;                /* does glut use current WD (from launching app) or not */
extern BOOL						__glutEmulateMouseButtons;      /* are we emulating a three button mouse with keyboard modifiers */
extern unsigned int			 	__glutMouseFirstModifiers;
extern unsigned int				__glutMouseSecondModifiers;
extern BOOL						__glutSyncToVBL;

/* non-window fortran callbacks */
extern GLUTidleFCB			    __fglutIdleFunc;
extern GLUTmenuStatusFCB	    __fglutMenuStatusFunc;
extern GLUTTimer *				__glutMostRecentTimer;
extern CGDisplayFadeInterval	__glutGameModeFadeInterval;

#define IGNORE_IN_GAME_MODE() \
  { if (__glutGameModeWindow && !__glutDestoryingGameMode) return; }
  
#define MAKE_CURRENT_WINDOW(view) \
   MACRO_BEGIN \
      [[(view) openGLContext] makeCurrentContext]; \
   MACRO_END
#define MAKE_CURRENT_LAYER	MAKE_CURRENT_WINDOW
#define UNMAKE_CURRENT() \
   MACRO_BEGIN \
      glFinish(); \
      [NSOpenGLContext clearCurrentContext]; \
   MACRO_END 
#define SWAP_BUFFERS_WINDOW(view) \
   MACRO_BEGIN \
      [[(view) openGLContext] flushBuffer]; \
   MACRO_END
#define SWAP_BUFFERS_LAYER	SWAP_BUFFERS_WINDOW

#define INIT_WORK_EVENT(evp) \
   MACRO_BEGIN \
      (evp)->workMask = 0; \
      (evp)->windowNum = -1; \
      (evp)->desiredConfMask = 0; \
   MACRO_END
  
/**
 * Heavy-weight API macros. They create a temporaray autorelease pool
 * and provide exception handling.
 */
#define GLUTAPI_DECLARATIONS \
   NSAutoreleasePool * glutAPool = [[NSAutoreleasePool alloc] init];
#define GLUTAPI_BEGIN \
   NS_DURING
#define GLUTAPI_VOIDRETURN \
   [glutAPool release]; \
   NS_VOIDRETURN
#define GLUTAPI_VALUERETURN(type, val) \
   [glutAPool release]; \
   NS_VALUERETURN(val, type)
#define GLUTAPI_END \
   NS_HANDLER \
      __glutFatalError("internal error: %s, reason: %s\n", \
         [[localException name] UTF8String], \
         [[localException reason] UTF8String]); \
   NS_ENDHANDLER \
   [glutAPool release];

/**
 * Light-weight API macros. The following set of API macros must only
 * be used if these condition are met:
 *
 * 1) No temporary ObjC objects are created.
 * 2) No ObjC exception is ever raised.
 */
#define GLUTAPI_DECLARATIONS_FAST \
   /* Does nothing for now */
#define GLUTAPI_BEGIN_FAST \
   /* Does nothing for now */
#define GLUTAPI_VOIDRETURN_FAST \
   return;
#define GLUTAPI_VALUERETURN_FAST(type, val) \
   return val;
#define GLUTAPI_END_FAST \
   /* Does nothing for now */


/* macx_cursor.m */
NSCursor *__glutGetNativeCursor(int cid);

/* macx_dstr.m */
NSOpenGLPixelFormat *__glutDeterminePixelFormatFromString(char *string, BOOL *treatAsSingle, BOOL gameMode);

/* macx_event.m */
void __glutPostRedisplay(GLUTView * view, int layerMask);
void __glutPostWorkEvent(GLUTWorkEvent *event);
void __glutProcessWorkEvents(void);
BOOL __glutHasWorkEvents(void);
void __glutPurgeWorkEvents(int win);
void __glutMapKeyCode(NSEvent *theEvent, char *utf8, int *utf8Length, BOOL *isSpecial);
void __glutMapMouseButton(NSEvent *theEvent, int *buttonID, int *buttonPhysID, unsigned int *modifiers);
void __glutSetMouseModifiers(unsigned int middleFlags, unsigned int rightFlags);
void __glutStartIdleFuncTimer(void);

/* macx_game.m */
void __glutCloseDownGameMode(void);

/* macx_menu.m */
void __glutSetMenu(GLUTMenu *menu);
GLUTMenu *__glutGetMenu(void);
void __glutStartMenu(GLUTMenu *menu, GLUTView *window, NSPoint mouseLoc);
void __glutFinishMenu(NSPoint mouseLoc);

/* macx_util.m */
BOOL __glutIsPackagedApp(void);
NSBundle *__glutGetFrameworkBundle(void);
BOOL __glutWriteDataToFile(NSData *data, NSString *path, OSType hfsType);
#if __GLUT_LOG_PIXELFORMAT
void __glutDumpPixelFormatAttributes(NSOpenGLPixelFormatAttribute *pfa);
#endif
#if __GLUT_LOG_WORK_EVENTS
void __glutPrintWorkMask (GLUTWorkEvent * event, int winid, int eventMask);
#endif
#if __GLUT_LOG_VISIBILITY
void __glutPrintVisibilityState(int state, int winid);
#endif
void __glutInitList(GLUTList *list);
void __glutAddTailNode(GLUTList *list, GLUTNode *node);
void __glutAddHeadNode(GLUTList *list, GLUTNode *node);
void __glutRemoveNode(GLUTList *list, GLUTNode *node);

/* macx_win.m */
short __glutGetCurrentDMDepth (void);
unsigned int __glutGetDisplayMaskFromMainDevice(void);
void __glutEnableVisibilityUpdates(void);
GLUTView *__glutGetWindowByNum(int winnum);
void __glutSetWindow(GLUTView *view);
void __glutDefaultDisplay(void);
void __glutDefaultReshape(int width, int height);
void __glutDefaultWMClose(void);
NSOpenGLPixelFormat *__glutDeterminePixelFormat(unsigned int displayMode, BOOL *treatAsSingle,
                           BOOL gameMode, NSOpenGLPixelFormat *(getPixelFormat) (unsigned int, BOOL));
NSOpenGLPixelFormat *__glutDetermineWindowPixelFormat(BOOL *treatAsSingle, BOOL gameMode);
GLUTView *__glutCreateWindow(GLUTView *parent, int x, int y, int width, int height, BOOL gameMode);
void __glutDestroyWindow(GLUTView *view);

/* macx_key.m */
int __glutGetDeviceKeyRepeat(void);
void __glutResetKeyboard(void);

/* macx_input.m */
void __glutForgetInputDevices(void);
void __glutCollectInputDevices(void);
void __glutCollectInputDevicesOnce(void);
void __glutGetInputDeviceEnumeratorOfClass(int cl, GLUTDeviceEnumerator *enumer);
pRecDevice __glutGetNextInputDevice(GLUTDeviceEnumerator *enumerator);
BOOL __glutIsInputDeviceConnected(pRecDevice device);
int __glutGetNumberOfMouseButtons(void);

/* macx_joy.m */
short __glutGetJoystickNumButtons (void);
short __glutGetJoystickNumAxis (void);
struct _GLUTinputActionRec * __glutGetJoystickDeviceElement (short inputNum);   
void __glutInitJoystickInput (pRecDevice pDevice);
pRecDevice __glutGetJoystickDevice (void);
void __glutUpdateJoystickInput (void); 
void __glutGetJoystickInput (int *pButtonMask, int *pX,  int *pY,  int *pZ);
void __glutKillJoystickInput (void);

/* macx_space.m */
short __glutGetSpaceballNumButtons (void);
short __glutGetSpaceballNumAxis (void);
struct _GLUTinputActionRec * __glutGetSpaceballDeviceElement (short inputNum);   
void __glutInitSpaceballInput (pRecDevice pDevice);
void __glutUpdateSpaceballInput (void); 
pRecDevice __glutGetSpaceballDevice (void);
void __glutGetSpaceballInput (int *pButtonMask, int *pX,  int *pY,  int *pZ, int *pRX,  int *pRY,  int *pRZ);
void __glutKillSpaceballInput (void);

/* macx_init.m */
void __glutEngineInit (void); // inits glut engine based on current values

/* GLUTPreferencesController.h */
void __glutLoadPrefs (void);
void __glutMatchHIDPrefsToDevices (void);
