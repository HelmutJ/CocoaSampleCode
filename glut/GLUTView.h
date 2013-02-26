
/* Copyright (c) Dietmar Planitzer, 1998, 2002 - 2003 */

/* This program is freely distributable without licensing fees 
   and is provided without guarantee or warrantee expressed or 
   implied. This program is -not- in the public domain. */

#import "macx_glut.h"
#import "glutf90.h"

@class GLUTMenu, GLUTWindow;


@interface GLUTView : NSView
{
@private
    NSOpenGLContext	*_openGLContext;
   GLUTList             _allChildrens;
   GLUTNode             _siblings;
   GLUTView *           _visibilityNext;		/* weak ref */
   GLUTView *           _savedSuperview;		/* weak ref */
	NSCursor *           _nativeCursor;
   GLUquadricObj *      _quadObj;
#define GLUT_MAX_MENUS 3
   GLUTMenu *           _menu[GLUT_MAX_MENUS];
   NSMutableSet *       _viewStorage;
   
   GLUTkeyboardCB       _keyDownFunc;
   GLUTkeyboardCB       _keyUpFunc;
   GLUTmouseCB          _mouseFunc;
   GLUTmotionCB         _motionFunc;
   GLUTpassiveCB        _passiveMotionFunc;
   GLUTentryCB          _entryFunc;
   GLUTspecialCB        _specialFunc;
   GLUTspecialCB        _specialUpFunc;
   GLUTdisplayCB        _displayFunc;
   GLUTreshapeCB        _reshapeFunc;
   GLUTwindowStatusCB	_windowStatusFunc;
   GLUTvisibilityCB     _visibilityFunc;
   GLUTwmcloseCB        _wmCloseFunc;
      
   GLUTspaceMotionCB    _spaceballMotionFunc;
   GLUTspaceRotateCB    _spaceballRotateFunc;
   GLUTspaceButtonCB    _spaceballButtonFunc;
   GLUTbuttonBoxCB      _buttonBoxFunc;
   GLUTdialsCB	        _dialFunc;
   GLUTtabletMotionCB   _tabletMotionFunc;
   GLUTtabletButtonCB   _tabletButtonFunc;
   GLUTjoystickCB       _joystickFunc;

   GLUTdisplayFCB       _fdisplayFunc;  /* Fortran display  */
   GLUTwmcloseFCB       _fwmcloseFunc;  /* Fortran wmclose */
   GLUTkeyboardFCB      _fkeyDownFunc;  /* Fortran keyboard  */
   GLUTkeyboardFCB      _fkeyUpFunc;  /* Fortran keyboard up */
   GLUTmouseFCB         _fmouseFunc;  /* Fortran mouse  */
   GLUTmotionFCB        _fmotionFunc;  /* Fortran motion  */
   GLUTpassiveFCB       _fpassiveMotionFunc;  /* Fortran passive  */
   GLUTentryFCB         _fentryFunc;  /* Fortran entry  */
   GLUTspecialFCB       _fspecialFunc;  /* special key */
   GLUTspecialFCB       _fspecialUpFunc;  /* special key up */
   GLUTreshapeFCB       _freshapeFunc;  /* Fortran reshape  */
   GLUTwindowStatusFCB  _fwindowStatusFunc;  /* Fortran visibility */
   GLUTvisibilityFCB    _fvisibilityFunc;  /* Fortran visibility */
  
   GLUTspaceMotionFCB   _fspaceballMotionFunc;  /* Fortran Spaceball motion */
   GLUTspaceRotateFCB   _fspaceballRotateFunc;  /* Fortran Spaceball rotate */
   GLUTspaceButtonFCB   _fspaceballButtonFunc;  /* Fortran Spaceball button */
   GLUTbuttonBoxFCB     _fbuttonBoxFunc;  /* Fortran button box */
   GLUTdialsFCB         _fdialFunc;  /* Fortran dials */
   GLUTtabletMotionFCB  _ftabletMotionFunc;  /* Fortran tablet motion */
   GLUTtabletButtonFCB  _ftabletButtonFunc;  /* Fortran tablet button */
   GLUTjoystickFCB      _fjoystickFunc;
   
   struct __vFlags {
      unsigned short forceReshape:1;
      unsigned short ignoreKeyRepeats:1;
      unsigned short isVisibilityUpdateAllowed:1;
      unsigned short isDamaged:1;
      unsigned short isShown:1;
      unsigned short isSubwindow:1;
      unsigned short treatAsSingle:1;
      unsigned short wasMouseInside:1;
      unsigned short hadMouseDown:3; // ccn: bit for each button
      unsigned short wasMouseEmulated:2; // ccn: bit for each emulated button
      unsigned short duplicateEmulatedMouseDown:1;
      unsigned short reserved:2;
   }                    _flags;
   char                 _visState;
   char                 _newVisState;
   int                  _cursorID;
   int                  _winid;
   NSTrackingRectTag    _trackingRectTag;
   NSTimeInterval       _pollInterval;
   NSTimer *            _joyTimer;
   NSTimer *            _spaceballTimer;
   int                  _iMouseLocX;
   int                  _iMouseLocY;
   int                  _eventMask;
   int                  _curEventMask;
   BOOL			        _isFullscreenStereo; // ggs: is the view stereo (always displayed fullscreen)
   BOOL				_inFullScreen;	    // Whether we have entered fullscreen mode yet or not.

#ifdef MAC_OS_X_VERSION_10_5
   int			        _isVBLSync; // ggs: is the view stereo (always displayed fullscreen)
#else
   long			        _isVBLSync; // ggs: is the view stereo (always displayed fullscreen)
#endif
}

- (id)initWithFrame: (NSRect)frameRect pixelFormat:(NSOpenGLPixelFormat *)pixelFormat
         windowID: (int)winid treatAsSingle: (BOOL)treatAsSingle isSubwindow: (BOOL)isSub
         fullscreenStereo: (BOOL)pfStereo isVBLSynced: (BOOL)isVBLSync;

/* Accessors */
- (NSOpenGLContext *)openGLContext;
- (NSPoint)windowPosition;
- (NSSize)windowSize;
- (int)visibilityState;
- (BOOL)isDamaged;
- (BOOL)isShown;
- (void)setShown: (BOOL)flag;
- (BOOL)isSubwindow;
- (BOOL)isTreatAsSingle;
- (BOOL)ignoreKeyRepeats;
- (void)setIgnoreKeyRepeats: (BOOL)yesno;
- (NSTimeInterval)joystickPollInterval;
- (int)windowID;
- (int)parentWindowID;
- (unsigned)numberOfChildrens;
- (int)eventMask;
- (void)setEventMask: (int)mask;
- (BOOL)isFullscreenStereo;
- (BOOL)isVBLSync;

/* Callbacks */
- (void)setKeyDownCallback: (GLUTkeyboardCB)func;
- (void)setKeyUpCallback: (GLUTkeyboardCB)func;
- (void)setMouseCallback: (GLUTmouseCB)func;
- (void)setMotionCallback: (GLUTmotionCB)func;
- (void)setPassiveMotionCallback: (GLUTpassiveCB)func;
- (void)setEntryCallback: (GLUTentryCB)func;
- (void)setSpecialDownCallback: (GLUTspecialCB)func;
- (void)setSpecialUpCallback: (GLUTspecialCB)func;
- (void)setDisplayCallback: (GLUTdisplayCB)func;
- (void)setReshapeCallback: (GLUTreshapeCB)func;
- (void)setWindowStatusCallback: (GLUTwindowStatusCB)func;
- (void)setSpaceballMotionCallback: (GLUTspaceMotionCB)func;
- (void)setSpaceballRotateCallback: (GLUTspaceRotateCB)func;
- (void)setSpaceballButtonCallback: (GLUTspaceButtonCB)func;
- (void)setButtonBoxCallback: (GLUTbuttonBoxCB)func;
- (void)setDialCallback: (GLUTdialsCB)func;
- (void)setTabletMotionCallback: (GLUTtabletMotionCB)func;
- (void)setTabletButtonCallback: (GLUTtabletButtonCB)func;
- (void)setJoystickCallback: (GLUTjoystickCB)func pollInterval: (NSTimeInterval)delay;
- (void)setVisibilityCallback: (GLUTvisibilityCB)func;
- (GLUTvisibilityCB)visibilityCallback;
- (void)setWMCloseCallback: (GLUTwmcloseCB)func;
- (GLUTwmcloseCB)wmCloseCallback;

/* Fortran callbacks */
- (void)setFortranCallback: (int)which callback: (void *)func ;
- (void *)getFortranCallback: (int)which;

/* Cursor */
- (void)setCursor: (int)crsrnum;
- (int)cursor;

/* Work events */
- (void)handleWorkEvent: (GLUTWorkEvent *)event;

/* Visibility */
- (BOOL)isVisible;
- (NSSet *)coveredViews;
- (void)enableVisibilityUpdates;
+ (void)evaluateVisibilityOfViews: (NSSet *)views;
- (void)recursiveCollectViewsIntoSet: (NSMutableSet *)views;

/* Misc */
- (NSImage *)imageWithTIFFInsideRect: (NSRect)rect;
- (void)prepareForMiniaturization;
- (void)recursiveWillBeginMorph: (int)op;
- (void)recursiveDidEndMorph: (int)op;
- (void)willBeginMorph: (int)op;
- (void)didEndMorph: (int)op;

- (void)attachSubview: (GLUTView *)aView;
- (void)detachFromSuperview;
- (void)attachMenu: (GLUTMenu *)menu toButton: (int)button;
- (void)detachMenuFromButton: (int)button;

- (void)processJoystick: (id)sender;
- (void)processSpaceball: (id)sender;

- (void)resignCurrentGLUTView;
- (void)makeCurrentGLUTView;

@end
