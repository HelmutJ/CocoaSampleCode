
/* Copyright (c) Dietmar Planitzer, 1998, 2002 - 2003 */

/* This program is freely distributable without licensing fees 
   and is provided without guarantee or warrantee expressed or 
   implied. This program is -not- in the public domain. */

#import "GLUTView.h"
#import "GLUTWindow.h"
#import "GLUTMenu.h"


@interface GLUTView(GLUTPrivate)
- (void)_commonReshape;
- (void)_updateTrackingRects: (NSNotification *)notification;
- (NSCursor *)_inheritedNativeCursor;
- (void)_recursiveInvalidateCursorRectsWithWindow: (GLUTWindow *)aWindow;
- (void)_recursiveCopyPixelsTo: (NSBitmapImageRep *)bitmap sourceRect: (NSRect)srcRect baseView: (NSView *)bView;
- (void)_recursiveMarkHidden;
- (void)_updateComputedVisibility;
- (void)evaluateVisibility;
- (NSArray *)_orderedSiblings;
@end

static GLUTView *	__glutVisibilityUpdateList = NULL;
static GLUTView *	__glutVisibilityUpdateTail = NULL;


#pragma mark -


@implementation GLUTView

/* Designated initializer */
- (id)initWithFrame: (NSRect)frameRect pixelFormat: (NSOpenGLPixelFormat *)pixelFormat
         windowID: (int)winid treatAsSingle: (BOOL)treatAsSingle isSubwindow: (BOOL)isSub 
		 fullscreenStereo: (BOOL)pfStereo isVBLSynced: (BOOL)isVBLSync
{	
   if((self = [super initWithFrame: frameRect]) != nil) {
   
      _openGLContext = [[NSOpenGLContext alloc] initWithFormat:pixelFormat shareContext:nil];
      if(!_openGLContext) {
	[self release];
	return nil;
      }
      
      [self setAutoresizingMask: (NSViewHeightSizable | NSViewWidthSizable)];
      [self setAutoresizesSubviews: NO];
      [self setPostsBoundsChangedNotifications: NO];
      [self setPostsFrameChangedNotifications: NO];
      [self allocateGState];	// make -lockFocus 2x faster...
      
      /* This list contains ALL subviews of a GLUTView including
         hidden views - which are NOT part of -subviews. This is
         necessary so that we can re-insert a hidden view at the
         correct place in the sibling list. I.e. the view just
         below us might have been killed while we were hidden.
         We track such changes via this list and are thus able to
         re-display the hidden view in the correct position once
         glutShowWindow is called on the hidden view again. */
      __glutInitList(&_allChildrens);
      _siblings.obj = self;
      _cursorID = GLUT_CURSOR_INHERIT;
      _visState = GLUT_UNKNOWN_VISIBILITY;
      _flags.forceReshape = YES;
      _flags.isVisibilityUpdateAllowed = [NSApp isRunning];
      _flags.isSubwindow = isSub;
      _flags.isShown = NO;
      _flags.treatAsSingle = treatAsSingle;
      _winid = winid;
      _displayFunc = __glutDefaultDisplay;
      _reshapeFunc = __glutDefaultReshape;
      _wmCloseFunc = __glutDefaultWMClose;	
      _quadObj = NULL;
      _newVisState = GLUT_UNKNOWN_VISIBILITY;
      _eventMask = 0;
      _curEventMask = 0;
	  _isFullscreenStereo = pfStereo;
	  if (isVBLSync)
		_isVBLSync = 1;
	  else
		_isVBLSync = 0;

      [[self openGLContext] makeCurrentContext]; 
      if(_flags.treatAsSingle) {
         /* We do this because either the window really is single
            buffered (in which case this is redundant, but harmless,
            because this is the initial single-buffered context
            state); or we are treating a double buffered window as a
            single-buffered window because the system does not appear
            to export any suitable single- buffered visuals (in which
            the following are necessary). */
         glDrawBuffer(GL_FRONT);
         glReadBuffer(GL_FRONT);
      }
	  
	  [[self openGLContext] setValues:&_isVBLSync forParameter:NSOpenGLCPSwapInterval];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_surfaceNeedsUpdate:) name:NSViewGlobalFrameDidChangeNotification object:self];

      return self;
   }
   return nil;
}

- (void)dealloc
{
   int	i, winid = [self windowID];
   GLUTNode *	curChild = _allChildrens.head.succ;
   
   /* Recursively destroy any children. */
   while(curChild) {
      GLUTNode *	tmp = curChild->succ;
      
      [(id)(curChild->obj) release];
      curChild = tmp;
   }
   
   /* Unbind if bound to this window. */
   if(self == __glutCurrentView) {
      UNMAKE_CURRENT();
      __glutCurrentView = nil;
   }
   
   for(i = 0; i < GLUT_MAX_MENUS; i++)
      [_menu[i] release];
   [self releaseGState];
   [_nativeCursor release];
   if(_trackingRectTag)
      [self removeTrackingRect: _trackingRectTag];
   if(_quadObj)
      gluDeleteQuadric(_quadObj);
      
   /* NULLing the __glutWindowList helps detect is a window
      instance has been destroyed, given a window number. */
   __glutViewList[winid - 1] = NULL;
   
   /* Cleanup data structures that might contain window. */
   __glutPurgeWorkEvents(winid);
   
   if(self == __glutGameModeWindow) {
      /* Destroying the game mode window should implicitly
         have GLUT leave game mode. */
      __glutGameModeWindow = nil;
	  __glutDestoryingGameMode = false;
	  [[self openGLContext] clearDrawable];
	  __glutCloseDownGameMode();
   }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewGlobalFrameDidChangeNotification object:self];
    
    // If our context is current, clear it so no one can do anything bad any more.
    if([NSOpenGLContext currentContext] == _openGLContext)
	[NSOpenGLContext clearCurrentContext];
   [_openGLContext release];
	[super dealloc];
}

- (void)finalize
{
   int	i, winid = [self windowID];
   GLUTNode *	curChild = _allChildrens.head.succ;
   /* Recursively destroy any children. */
   while(curChild) {
      GLUTNode *	tmp = curChild->succ;
      [(id)(curChild->obj) release];
      curChild = tmp;
   }
   /* Unbind if bound to this window. */
   if(self == __glutCurrentView) {
      UNMAKE_CURRENT();
      __glutCurrentView = nil;
   }
   for(i = 0; i < GLUT_MAX_MENUS; i++)
      [_menu[i] release];
   [self releaseGState];
   if(_trackingRectTag)
      [self removeTrackingRect: _trackingRectTag];
   if(_quadObj)
      gluDeleteQuadric(_quadObj);
   /* NULLing the __glutWindowList helps detect is a window
      instance has been destroyed, given a window number. */
   __glutViewList[winid - 1] = NULL;
   /* Cleanup data structures that might contain window. */
   __glutPurgeWorkEvents(winid);
   if(self == __glutGameModeWindow) {
      /* Destroying the game mode window should implicitly
         have GLUT leave game mode. */
      __glutGameModeWindow = nil;
	  __glutDestoryingGameMode = false;
	  [[self openGLContext] clearDrawable];
	  __glutCloseDownGameMode();
   }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewGlobalFrameDidChangeNotification object:self];
    if([NSOpenGLContext currentContext] == _openGLContext)
	[NSOpenGLContext clearCurrentContext];
	[super finalize];
}

/////////////////////////////////////////////
#pragma mark - 
#pragma mark NSView overrides
#pragma mark -
- (BOOL)isOpaque
{
    return YES;
}

- (void)lockFocus
{
    NSOpenGLContext* context = _openGLContext;
    
    // make sure we are ready to draw
    //
    [super lockFocus];

    // when we are about to draw, make sure we are linked to the view and
    //
    if (!_isFullscreenStereo && ([context view] != self)) {
        [context setView:self];
    }

    // make us the current OpenGL context
    //
    [context makeCurrentContext];
}

- (void)makeCurrentGLUTView
{
    NSOpenGLContext* context = _openGLContext;

    if(_isFullscreenStereo && (__glutGameModeWindow == self) && !_inFullScreen)
    {
	[context setFullScreen];
	_inFullScreen = YES;
    }
    [context makeCurrentContext];
}

- (void)resignCurrentGLUTView
{
    NSOpenGLContext* context = _openGLContext;

    if(_isFullscreenStereo && (__glutGameModeWindow != self) && _inFullScreen)
    {
	[context clearDrawable];
	_inFullScreen = NO;
    }
    [NSOpenGLContext clearCurrentContext];
}

- (NSOpenGLContext *)openGLContext
{
    return _openGLContext;
}

- (void)update
{
    if ([_openGLContext view] == self) {
        [_openGLContext update];
    }
}

- (void) _surfaceNeedsUpdate:(NSNotification*)notification
{
    [self update];
}

/////////////////////////////////////////////
#pragma mark -
#pragma mark Accessors
#pragma mark -

- (NSPoint)windowPosition
{
   NSPoint 			pt;
   GLUTWindow *	window = (GLUTWindow *) [self window];
   
   if(!_flags.isSubwindow) {
      unsigned int	mask = [window styleMask];
      NSRect			rect = [NSWindow contentRectForFrameRect: [window frame] styleMask: mask];
      
      pt = rect.origin;
      pt.y = __glutScreenHeight - (pt.y + rect.size.height);
   } else {
      pt = [self convertPoint: [self bounds].origin toView: nil];
      pt = [window convertBaseToScreen: pt];
   }
   
   return pt;
}

- (BOOL)isSubwindow
{
   return _flags.isSubwindow;
}

	/* Return window size in local coordinates. */
- (NSSize)windowSize
{
   return [self bounds].size;
}

- (int)visibilityState
{
   return _visState;
}

- (BOOL)isDamaged
{
   return _flags.isDamaged;
}

- (BOOL)isShown
{
   return _flags.isShown;
}

- (void)setShown: (BOOL)flag
{
   _flags.isShown = flag;
}

- (BOOL)isTreatAsSingle
{
   return _flags.treatAsSingle;
}

- (int)windowID
{
   return _winid;
}

- (int)parentWindowID
{
   if(_flags.isSubwindow) {
      GLUTView *	parentWindow = (GLUTView *)[self superview];
      
      if(parentWindow == nil)
         parentWindow = _savedSuperview;
      return [parentWindow windowID];
   }
   return 0;
}

/* Return the real number of childrens including hidden ones */
- (unsigned)numberOfChildrens
{
   GLUTNode *	tail = &_allChildrens.tail;
   GLUTNode *	node = _allChildrens.head.succ;
   unsigned		i = 0;
   
   while(node != tail) {
      i++;
      node = node->succ;
   }
   return i;
}

- (BOOL)ignoreKeyRepeats
{
   return _flags.ignoreKeyRepeats;
}

- (void)setIgnoreKeyRepeats: (BOOL)yesno
{
   _flags.ignoreKeyRepeats = yesno;
}

- (NSTimeInterval)joystickPollInterval
{
   return _pollInterval;
}

- (int)eventMask
{
   return _eventMask;
}

- (void)setEventMask: (int)mask
{
   _eventMask = mask;
}

- (BOOL)isFullscreenStereo
{
   return _isFullscreenStereo;
}

- (BOOL)isVBLSync
{
   return _isVBLSync;
}


/////////////////////////////////////////////
#pragma mark -
#pragma mark Callbacks
#pragma mark -


- (void)setPassiveMotionCallback: (GLUTmotionCB)func { _passiveMotionFunc = func; }
- (void)setEntryCallback: (GLUTentryCB)func { _entryFunc = func; }
- (void)setKeyDownCallback: (GLUTkeyboardCB)func { _keyDownFunc = func; }
- (void)setKeyUpCallback: (GLUTkeyboardCB)func { _keyUpFunc = func; }
- (void)setMouseCallback: (GLUTmouseCB)func { _mouseFunc = func; }
- (void)setMotionCallback: (GLUTpassiveCB)func { _motionFunc = func; }
- (void)setSpecialDownCallback: (GLUTspecialCB)func { _specialFunc = func; }
- (void)setSpecialUpCallback: (GLUTspecialCB)func { _specialUpFunc = func; }

- (void)setDisplayCallback: (GLUTdisplayCB)func
{
   if(!func) {
      __glutFatalError("NULL display callback not allowed in GLUT 3.0; update your code.");
   }
   _displayFunc = func;
}

- (void)setReshapeCallback: (GLUTreshapeCB)func
{
   _reshapeFunc = (func) ? func : __glutDefaultReshape;
}

- (void)setWindowStatusCallback: (GLUTwindowStatusCB)func
{
   _windowStatusFunc = func;
   if(!_windowStatusFunc) {
      /* Make state invalid. */
      _visState = GLUT_UNKNOWN_VISIBILITY;
   }
}

- (void)setSpaceballMotionCallback: (GLUTspaceMotionCB)func	
{ 
	_spaceballMotionFunc = func; 
	if (_spaceballMotionFunc)
		if (!_spaceballTimer)
			_spaceballTimer = [NSTimer scheduledTimerWithTimeInterval: 0.01 
									target: self 
									selector: @selector(processSpaceball:) 
									userInfo: 0 
									repeats: YES];
		else
			[_spaceballTimer setFireDate: [NSDate dateWithTimeIntervalSinceNow:0.01]];
	else if (!_spaceballMotionFunc && !_spaceballRotateFunc && !_spaceballButtonFunc) { // if no spaceball functions turn off timer
		[_spaceballTimer invalidate];
		_spaceballTimer = nil;
	}
}

- (void)setSpaceballRotateCallback: (GLUTspaceRotateCB)func
{ 
	_spaceballRotateFunc = func; 
	if (_spaceballRotateFunc)
		if (!_spaceballTimer)
			_spaceballTimer = [NSTimer scheduledTimerWithTimeInterval: 0.01 
									target: self 
									selector: @selector(processSpaceball:) 
									userInfo: 0 
									repeats: YES];
		else
			[_spaceballTimer setFireDate: [NSDate dateWithTimeIntervalSinceNow:0.01]];
	else if (!_spaceballMotionFunc && !_spaceballRotateFunc && !_spaceballButtonFunc) { // if no spaceball functions turn off timer
		[_spaceballTimer invalidate];
		_spaceballTimer = nil;
	}
}

- (void)setSpaceballButtonCallback: (GLUTspaceButtonCB)func
{ 
	_spaceballButtonFunc = func; 
	if (_spaceballButtonFunc)
		if (!_spaceballTimer)
			_spaceballTimer = [NSTimer scheduledTimerWithTimeInterval: 0.01 
									target: self 
									selector: @selector(processSpaceball:) 
									userInfo: 0 
									repeats: YES];
		else
			[_joyTimer setFireDate: [NSDate dateWithTimeIntervalSinceNow:0.01]];
	else if (!_spaceballMotionFunc && !_spaceballRotateFunc && !_spaceballButtonFunc) { // if no spaceball functions turn off timer
		[_spaceballTimer invalidate];
		_spaceballTimer = nil;
	}
}

- (void)setButtonBoxCallback: (GLUTbuttonBoxCB)func	{ _buttonBoxFunc = func; }
- (void)setDialCallback: (GLUTdialsCB)func	{ _dialFunc = func; }
- (void)setTabletMotionCallback: (GLUTtabletMotionCB)func	{ _tabletMotionFunc = func; }
- (void)setTabletButtonCallback: (GLUTtabletButtonCB)func	{ _tabletButtonFunc = func; }

- (void)setJoystickCallback: (GLUTjoystickCB)func pollInterval: (NSTimeInterval)delay
{
	_joystickFunc = func; // set joystick function always
	if ((delay > 0) && _joystickFunc)
		_pollInterval = delay;
	else
		_pollInterval = 0;
	if (_pollInterval) {
		if (!_joyTimer)
			_joyTimer = [NSTimer scheduledTimerWithTimeInterval: delay 
								 target: self 
								 selector: @selector(processJoystick:) 
								 userInfo: 0 
								 repeats: YES];
		else
			[_joyTimer setFireDate: [NSDate dateWithTimeIntervalSinceNow:_pollInterval]];
	} else {
		[_joyTimer invalidate];
		_joyTimer = nil;
	}
}

- (void)setVisibilityCallback: (GLUTvisibilityCB)func	{ _visibilityFunc = func; }
- (GLUTvisibilityCB)visibilityCallback	 { return _visibilityFunc; }

- (void)setWMCloseCallback: (GLUTwmcloseCB)func
{
   /* WM close func is only relevant for top-level windows on MacOS X */
   if(!_flags.isSubwindow) {
      _wmCloseFunc = func;
      /* Enabled/disable window close button */
      if(_wmCloseFunc == __glutDefaultWMClose)
         [[[self window] standardWindowButton: NSWindowCloseButton] setEnabled: NO];
      else
         [[[self window] standardWindowButton: NSWindowCloseButton] setEnabled: YES];
   }
}

- (GLUTwmcloseCB)wmCloseCallback { return _wmCloseFunc; }

- (void)setFortranCallback: (int)which callback: (void *)func
{
	switch (which) {
		case GLUT_FCB_DISPLAY:
			_fdisplayFunc = (GLUTdisplayFCB) func;
			break;
      case GLUT_FCB_WMCLOSE:
         _fwmcloseFunc = (GLUTwmcloseFCB) func;
         break;
		case GLUT_FCB_RESHAPE:
			_freshapeFunc = (GLUTreshapeFCB) func;
			break;
		case GLUT_FCB_MOUSE:
			_fmouseFunc = (GLUTmouseFCB) func;
			break;
		case GLUT_FCB_MOTION:
			_fmotionFunc = (GLUTmotionFCB) func;
			break;
		case GLUT_FCB_PASSIVE:
			_fpassiveMotionFunc = (GLUTpassiveFCB) func;
			break;
		case GLUT_FCB_ENTRY:
			_fentryFunc = (GLUTentryFCB) func;
			break;
		case GLUT_FCB_KEYBOARD:
			_fkeyDownFunc = (GLUTkeyboardFCB) func;
			break;
		case GLUT_FCB_KEYBOARD_UP:
			_fkeyUpFunc = (GLUTkeyboardFCB) func;
			break;
		case GLUT_FCB_WINDOW_STATUS:
			_fwindowStatusFunc = (GLUTwindowStatusFCB) func;
			break;
		case GLUT_FCB_VISIBILITY:
			_fvisibilityFunc = (GLUTvisibilityFCB) func;
			break;
		case GLUT_FCB_SPECIAL:
			_fspecialFunc = (GLUTspecialFCB) func;
			break;
		case GLUT_FCB_SPECIAL_UP:
			_fspecialUpFunc = (GLUTspecialFCB) func;
			break;
		case GLUT_FCB_BUTTON_BOX:
			_fbuttonBoxFunc = (GLUTbuttonBoxFCB) func;
			break;
		case GLUT_FCB_DIALS:
			_fdialFunc = (GLUTdialsFCB) func;
			break;
		case GLUT_FCB_SPACE_MOTION:
			_fspaceballMotionFunc = (GLUTspaceMotionFCB) func;
			break;
		case GLUT_FCB_SPACE_ROTATE:
			_fspaceballRotateFunc = (GLUTspaceRotateFCB) func;
			break;
		case GLUT_FCB_SPACE_BUTTON:
			_fspaceballButtonFunc = (GLUTspaceButtonFCB) func;
			break;
		case GLUT_FCB_TABLET_MOTION:
			_ftabletMotionFunc = (GLUTtabletMotionFCB) func;
			break;
		case GLUT_FCB_TABLET_BUTTON:
			_ftabletButtonFunc = (GLUTtabletButtonFCB) func;
			break;
		case GLUT_FCB_JOYSTICK:
			_fjoystickFunc = (GLUTjoystickFCB) func;
			break;
	}

}

- (void *)getFortranCallback: (int)which;
{
	switch (which) {
		case GLUT_FCB_DISPLAY:
			return (void*) _fdisplayFunc;
			break;
      case GLUT_FCB_WMCLOSE:
         return (void*) _fwmcloseFunc;
         break;
		case GLUT_FCB_RESHAPE:
			return (void*) _freshapeFunc;
			break;
		case GLUT_FCB_MOUSE:
			return (void*) _fmouseFunc;
			break;
		case GLUT_FCB_MOTION:
			return (void*) _fmotionFunc;
			break;
		case GLUT_FCB_PASSIVE:
			return (void*) _fpassiveMotionFunc;
			break;
		case GLUT_FCB_ENTRY:
			return (void*) _fentryFunc;
			break;
		case GLUT_FCB_KEYBOARD:
			return (void*) _fkeyDownFunc;
			break;
		case GLUT_FCB_KEYBOARD_UP:
			return (void*) _fkeyUpFunc;
			break;
		case GLUT_FCB_WINDOW_STATUS:
			return (void*) _fwindowStatusFunc;
			break;
		case GLUT_FCB_VISIBILITY:
			return (void*) _fvisibilityFunc;
			break;
		case GLUT_FCB_SPECIAL:
			return (void*) _fspecialFunc;
			break;
		case GLUT_FCB_SPECIAL_UP:
			return (void*) _fspecialUpFunc;
			break;
		case GLUT_FCB_BUTTON_BOX:
			return (void*) _fbuttonBoxFunc;
			break;
		case GLUT_FCB_DIALS:
			return (void*) _fdialFunc;
			break;
		case GLUT_FCB_SPACE_MOTION:
			return (void*) _fspaceballMotionFunc;
			break;
		case GLUT_FCB_SPACE_ROTATE:
			return (void*) _fspaceballRotateFunc;
			break;
		case GLUT_FCB_SPACE_BUTTON:
			return (void*) _fspaceballButtonFunc;
			break;
		case GLUT_FCB_TABLET_MOTION:
			return (void*) _ftabletMotionFunc;
			break;
		case GLUT_FCB_TABLET_BUTTON:
			return (void*) _ftabletButtonFunc;
			break;
		case GLUT_FCB_JOYSTICK:
			return (void*) _fjoystickFunc;
			break;
		default:
			return nil;
			break;
	}
}


/////////////////////////////////////////////
#pragma mark -
#pragma mark Cursor
#pragma mark -


- (int)cursor
{
   return _cursorID;
}

- (NSCursor *)_inheritedNativeCursor
{
   if(!_nativeCursor) {
      if(_flags.isSubwindow)
         return [(GLUTView *)[self superview] _inheritedNativeCursor];
      else
         return [NSCursor arrowCursor];
   }
   return _nativeCursor;
}

- (void)resetCursorRects
{
   if(!_nativeCursor) {
      if(_cursorID == GLUT_CURSOR_INHERIT) {
         _nativeCursor = [[self _inheritedNativeCursor] retain];
      } else {
         _nativeCursor = [__glutGetNativeCursor(_cursorID) retain];
      }
   }
   [self addCursorRect: [self visibleRect] cursor: _nativeCursor];
}

- (void)_recursiveInvalidateCursorRectsWithWindow: (GLUTWindow *)aWindow
{
   NSArray *		childrens = [self subviews];
   unsigned int	i, count = [childrens count];
   
   for(i = 0; i < count; i++) {
      GLUTView *	view = (GLUTView *)[childrens objectAtIndex: i];
      
      if(view->_cursorID == GLUT_CURSOR_INHERIT) {
         [view->_nativeCursor release];
         view->_nativeCursor = nil;
         [aWindow invalidateCursorRectsForView: view];
         [view _recursiveInvalidateCursorRectsWithWindow: aWindow];
      }
   }
}

- (void)setCursor: (int)cursor
{
   if(_cursorID != cursor) {
      GLUTWindow *	window = (GLUTWindow *) [self window];
      
      [_nativeCursor release];
      _nativeCursor = nil;
      _cursorID = cursor;
      [window invalidateCursorRectsForView: self];
      [self _recursiveInvalidateCursorRectsWithWindow: window];
      [window performSelector:@selector(resetCursorRects) withObject:nil afterDelay:0.0];
// need the above to work around some AppKit issue with setting cursors while inside cursor rects
//	  [[self window] resetCursorRects];
   }
}

/////////////////////////////////////////////
#pragma mark -
#pragma mark Work Events
#pragma mark -


/**
 * --- Temp fix for current sub-windowing scheme, full logic change for post Panther ---
 * 
 * We need to clear and re-establish the surface of each (sub-)view which acts
 * as a GLUT sub-window, because sub-windows (ONLY those) which are moved from
 * one top-level window to another one fail to draw once they are re-inserted
 * into the new window and told to draw themselves.
 */
- (void)_recursiveKickSurface
{
   NSArray *	subviews = [self subviews];
   int			i, count = [subviews count];
   
   [[self openGLContext] clearDrawable];
   [[self openGLContext] setView: self];
   for(i = 0; i < count; i++)
      [(GLUTView *)[subviews objectAtIndex: i] _recursiveKickSurface];
}

static GLUTWindow *__glutSwitchWindowFullscreenMode(GLUTWindow *window, NSRect frame, BOOL mode)
{
	GLUTWindow *	othWindow = nil;
   GLUTView *		view = (GLUTView *)[window contentView];
   NSDictionary *	args = nil;
   int				op = kGLUTMorphOperationFullscreen;
   
   if(!mode) {
      args = [NSDictionary dictionaryWithObject: [NSValue valueWithRect: frame]
                           forKey: GLUTWindowFrame];
      op = kGLUTMorphOperationRegular;
   }
   
   UNMAKE_CURRENT();
   othWindow = [[GLUTWindow   windowByMorphingWindow: window
                              operation: op
                              arguments: args] retain];

   [view _recursiveKickSurface];
   if([window isVisible])
      [othWindow makeKeyAndOrderFront: nil];
   MAKE_CURRENT_WINDOW(view);
   
   [window setReleasedWhenClosed: YES];
   [window close];
   
   return othWindow;
}

- (void)_updateTrackingRects: (NSNotification *)notification
{
   NSPoint	mouseLoc = [[self window] mouseLocationOutsideOfEventStream];
   NSRect	bounds = [self bounds];
   
   [self removeTrackingRect: _trackingRectTag];
   
   _flags.wasMouseInside = NSMouseInRect([self convertPoint: mouseLoc fromView: nil], bounds, YES);
   _trackingRectTag = [self addTrackingRect: bounds owner: self userData: nil assumeInside: _flags.wasMouseInside];
}

/**
 * Updates the current event mask so that it becomes equivalent to
 * the event mask stored in _eventMask.
 */
- (void)_updateCurrentEventMask
{
   BOOL	forceEntry = NO;
   
   // kPassiveMotionEvents
   if((_curEventMask & kPassiveMotionEvents) ^ (_eventMask & kPassiveMotionEvents)) {
      if((_eventMask & kPassiveMotionEvents) == kPassiveMotionEvents) {
         // turn 'em on
         [(GLUTWindow *) [self window] enableMouseMovedEvents];
      } else {
         // turn 'em off
         [(GLUTWindow *) [self window] disableMouseMovedEvents];
         /* Force recreation of any necessary tracking rectangle because
            the AppKit forgets about them as soon as you enable the
            generation of mouse moved events... */
         if((_curEventMask & kEntryEvents) == kEntryEvents) {
            [self removeTrackingRect: _trackingRectTag];
            [self setPostsFrameChangedNotifications: NO];
            [[NSNotificationCenter defaultCenter] removeObserver: self];
            _trackingRectTag = 0;
            forceEntry = YES;
         }
      }
   }
   
   // kEntryEvents
   if(forceEntry || (_curEventMask & kEntryEvents) ^ (_eventMask & kEntryEvents)) {
      if((_eventMask & kEntryEvents) == kEntryEvents) {
         /* setup our tracking rect */
         NSPoint	mouseLoc = [[self window] mouseLocationOutsideOfEventStream];
         NSRect	bounds = [self bounds];
         
         _flags.wasMouseInside = NSMouseInRect([self convertPoint: mouseLoc fromView: nil], bounds, YES);
         _trackingRectTag = [self	addTrackingRect: bounds
                                    owner: self
                                    userData: nil
                                    assumeInside: _flags.wasMouseInside];
         [self setPostsFrameChangedNotifications: YES];
         [[NSNotificationCenter defaultCenter]	addObserver: self
                                                selector: @selector(_updateTrackingRects:)
                                                name: NSViewFrameDidChangeNotification
                                                object: self];
      }
   } else {	
      if(_trackingRectTag) {
         [self removeTrackingRect: _trackingRectTag];
         [self setPostsFrameChangedNotifications: NO];
         [[NSNotificationCenter defaultCenter] removeObserver: self];
         _trackingRectTag = 0;
      }
   }
   
   _curEventMask = _eventMask;
}

- (void)handleWorkEvent: (GLUTWorkEvent *)event
{
   int	workMask;
   BOOL	isSub = _flags.isSubwindow;
   
#if __GLUT_LOG_WORK_EVENTS
     __glutPrintWorkMask(event, _winid, _eventMask); 	// dump the events to process
#endif
   /* Capture work mask for work that needs to be done to this
      window, then clear the window's work mask (excepting the
      dummy work bit, see below).  Then, process the captured
      work mask.  This allows callbacks in the processing the
      captured work mask to set the window's work mask for
      subsequent processing. */
   
   workMask = event->workMask;
   assert((workMask & GLUT_DUMMY_WORK) == 0);
   
   /* Set the dummy work bit, clearing all other bits, to
      indicate that the window is currently on the window work
      list _and_ that the window's work mask is currently being
      processed.  This convinces __glutPostWorkEvent that this
      window is on the work list still. */
   event->workMask = GLUT_DUMMY_WORK;
   
   /* Optimization: most of the time, the work to do is a
      redisplay and not these other types of work.  Check for
      the following cases as a group to before checking each one
      individually one by one. */
   if(workMask & (GLUT_EVENT_MASK_WORK | GLUT_DEVICE_MASK_WORK | GLUT_CONFIGURE_WORK |
         GLUT_COLORMAP_WORK | GLUT_MAP_WORK)) {
      if(workMask & GLUT_MAP_WORK) {
         /* Show / hide window */
         if(isSub) {
            NSMutableSet *	views = [NSMutableSet set];
            
            if(event->desiredMapState == kWithdrawnState) {
               /* hide */
               [[self superview] setNeedsDisplay: YES];
               /* Remove us from the superview. Doing this is save because
                  the _glutViewList still retains us. */
               _savedSuperview = (GLUTView *)[self superview];
               [views unionSet: [self coveredViews]];
               [views addObject: self];
               [self removeFromSuperview];
               [GLUTView evaluateVisibilityOfViews: views];
               [self setShown: NO];
            } else {
               /* show */
               if(_savedSuperview) {
                  GLUTList *	list = &_savedSuperview->_allChildrens;
                  
                  if(_siblings.pred == &list->head) {
                     /* We're the bottom most of all siblings */
                     [_savedSuperview addSubview: self positioned: NSWindowBelow relativeTo: nil];
                  } else {
                     /* We're somewhere in the middle of the stack or the top-most */
                     GLUTView *	refView = _siblings.pred->obj;
                     
                     [_savedSuperview addSubview: self positioned: NSWindowAbove relativeTo: refView];
                  }
                  _savedSuperview = nil;
                  [views unionSet: [self coveredViews]];
                  [self recursiveCollectViewsIntoSet: views];
                  [GLUTView evaluateVisibilityOfViews: views];
                  [self setShown: YES];
                  [self setNeedsDisplay: YES];
				  // ggs: fix for not initially accepting keyboard events.
				  // set subview to be first responder
				  [[self window] makeFirstResponder: self];
               }
            }
         } else {
            /* Use the persistent window here because [self window] will return
               nil if we're currently miniaturized, but [self persistentWindow]
               always returns our true GLUTWindow miniaturized or not. */
            GLUTWindow *	window = (GLUTWindow *) [self window];
            
            switch(event->desiredMapState) {
               case kWithdrawnState:
                     [window orderOut: nil];
                     break;
               case kNormalState:
                     if([window isAffectedByFullscreenWindow])
                        [window setLevel: GLUT_FULLSCREEN_LEVEL];
                     if([window isMiniaturized])
                        [window deminiaturize: nil];
                     [window makeKeyAndOrderFront: nil];
                     break;
               case kGameModeState:
                     [window setLevel: GLUT_GAMEMODE_LEVEL];
                     if([window isMiniaturized])
                        [window deminiaturize: nil];
                     [window makeKeyAndOrderFront: nil];
                     break;
               case kIconicState:
                     /* Give our GLUTViews a chance to draw themselves so that
                        the miniaturization code is able to pick up a meaningful
                        OGL graphics and not just some randomly set pixels... */
                     [window display];
                     [window miniaturize: nil];
                     break;
            }
         }
      }
      
      if(workMask & GLUT_CONFIGURE_WORK) {
         if(event->desiredConfMask & (CWWidth | CWHeight)) {
            /* resize window */
            NSSize	Xsize = NSMakeSize(event->desiredWidth, event->desiredHeight);
            NSMutableSet *	views = [NSMutableSet set];
            
            [views unionSet: [self coveredViews]];
            if(isSub) {
               NSSize	size = [self frame].size;
               
               if(size.width != Xsize.width || size.height != Xsize.height) {
                  [[self superview] setNeedsDisplayInRect: [self frame]];
                  [self setFrameSize: Xsize];
                  [self _commonReshape];
                  [self setNeedsDisplay: YES];
               }
            } else {
               GLUTWindow *	window = (GLUTWindow *) [self window];
               unsigned int	mask;
               NSRect			frame;
               
               if([window isFullscreen]) {
                  frame = [window frame];
                  frame.origin.y = NSMaxY(frame) - Xsize.height;
                  frame.size = Xsize;
                  window = __glutSwitchWindowFullscreenMode(window, frame, NO);
               } else {
                  mask = [window styleMask];
                  frame = [NSWindow contentRectForFrameRect: [window frame] styleMask: mask];
                  frame.origin.y = NSMaxY(frame) - Xsize.height;
                  frame.size = Xsize;
                  frame = [NSWindow frameRectForContentRect: frame styleMask: mask];
                  [window setFrame: frame display: YES];
               }
            }
            [views unionSet: [self coveredViews]];
            [views addObject: self];
            [GLUTView evaluateVisibilityOfViews: views];
         }
         
         if(event->desiredConfMask & (CWX | CWY)) {
            /* move window */
            NSPoint	Xpos = NSMakePoint(event->desiredX, event->desiredY);
            NSMutableSet *	views = [NSMutableSet set];

            [views unionSet: [self coveredViews]];            
            if(isSub) {
               [[self superview] setNeedsDisplayInRect: [self frame]];
               [self setFrameOrigin: Xpos];
               [self setNeedsDisplay: YES];
            } else {
               GLUTWindow *	window = (GLUTWindow *) [self window];
               unsigned int	mask;
               NSRect			frame;
               
               if([window isFullscreen]) {
                  frame = [window frame];
                  frame.origin.y = __glutScreenHeight - (Xpos.y + NSHeight(frame));
                  frame.origin.x = Xpos.x;
                  window = __glutSwitchWindowFullscreenMode(window, frame, NO);
               } else {
                  mask = [window styleMask];
                  frame = [NSWindow contentRectForFrameRect: [window frame] styleMask: mask];
                  frame.origin.y = __glutScreenHeight - (Xpos.y + NSHeight(frame));
                  frame.origin.x = Xpos.x;
                  frame = [NSWindow frameRectForContentRect: frame styleMask: mask];
                  [window setFrameOrigin: frame.origin];
               }
            }
            [views unionSet: [self coveredViews]];
            [views addObject: self];
            [GLUTView evaluateVisibilityOfViews: views];
         }
                  
         if(event->desiredConfMask & CWStackMode) {
            /* change window stacking order */
            if(isSub) {
               GLUTView *	superview = (GLUTView *) [self superview];
               GLUTList *	list = &superview->_allChildrens;
               NSMutableSet *	views = [NSMutableSet set];
               
               if(event->desiredStack == kAbove) {
                  __glutRemoveNode(list, &_siblings);
                  [self removeFromSuperview];
                  [superview addSubview: self positioned: NSWindowAbove relativeTo: nil];
                  __glutAddTailNode(list, &_siblings);
                  [views unionSet: [self coveredViews]];
                  [self recursiveCollectViewsIntoSet: views];
                  [GLUTView evaluateVisibilityOfViews: views];
                  [self setNeedsDisplay: YES];
               } else {
                  [views unionSet: [self coveredViews]];
                  [self recursiveCollectViewsIntoSet: views];
                  __glutRemoveNode(list, &_siblings);
                  [self removeFromSuperview];
                  [superview addSubview: self positioned: NSWindowBelow relativeTo: nil];
                  __glutAddHeadNode(list, &_siblings);
                  [GLUTView evaluateVisibilityOfViews: views];
                  [[self superview] setNeedsDisplay: YES];
               }
            } else {
               GLUTWindow *	window = (GLUTWindow *) [self window];
               
               if(event->desiredStack == kAbove) {
                  if([window isAffectedByFullscreenWindow])
                     [window setLevel: GLUT_FULLSCREEN_LEVEL];
                  [window makeKeyAndOrderFront: nil];
               } else {
                  if([window isAffectedByFullscreenWindow])
                     [window setLevel: GLUT_NORMAL_LEVEL];
                  [window orderBack: nil];
               }
            }
         }
         
         if(event->desiredConfMask & CWFullScreen) {
            GLUTWindow *	window = (GLUTWindow *) [self window];
            
            if(!isSub && ![window isFullscreen])
               (void) __glutSwitchWindowFullscreenMode(window, NSZeroRect, YES);
         }
         
         /* Zero out the mask. */
         event->desiredConfMask = 0;
      }
      
      if(workMask & GLUT_EVENT_MASK_WORK) {
         [self _updateCurrentEventMask];
      }
   }
   
   if(workMask & (GLUT_REDISPLAY_WORK | GLUT_OVERLAY_REDISPLAY_WORK)) {
      /* Render to normal plane (and possibly overlay). */
      
      /* Note: GLUT window redisplay is NOT recursive. That's why
         we do the -lockFocus, -drawRect and -unlockFocus stuff
         ourselves here (and we get a nice speed-up for free) */
      if([self lockFocusIfCanDraw]) {
         [self drawRect: /* rect is ignored */NSZeroRect];
         [self unlockFocus];
      }
   }
   /* Combine workMask with window->workMask to determine what
      finish and debug work there is. */
   workMask |= event->workMask;
   
   if(workMask & GLUT_DEBUG_WORK) {
      __glutSetWindow(self);
      glutReportErrors();
   }
   /* Strip out dummy, finish, and debug work bits. */
   event->workMask &= ~(GLUT_DUMMY_WORK | GLUT_DEBUG_WORK);
}


/////////////////////////////////////////////
#pragma mark -
#pragma mark Drawing & Misc
#pragma mark -


- (BOOL)isFlipped { return YES; }

- (void)_commonReshape
{
   NSSize	size = [self bounds].size;
   
   __glutSetWindow(self);
   (*_reshapeFunc)(size.width, size.height);
   /* For sake of compatibility with the X Windows implementation... */
   _flags.isDamaged = YES;
   _flags.forceReshape = NO;
}

- (void)drawRect: (NSRect)aRect
{
   [[self window] setDocumentEdited: YES];
   __glutSetWindow(self);

   if(_flags.forceReshape) {
      /* Guarantee that before a display callback is generated
         for a window, a reshape callback must be generated. */
      [self _commonReshape];
   }
   (*_displayFunc)();
   _flags.isDamaged = NO;
}

- (void)resizeWithOldSuperviewSize: (NSSize)oldFrameSize
{
	[super resizeWithOldSuperviewSize: oldFrameSize];
   [self _commonReshape];
}

- (void)viewWillStartLiveResize
{
   if(!_flags.isSubwindow) {
      _viewStorage = [[NSMutableSet alloc] init];
      [_viewStorage unionSet: [self coveredViews]];
      [_viewStorage addObject: self];
   }
}

- (void)viewDidEndLiveResize
{
   if(!_flags.isSubwindow) {
      [_viewStorage unionSet: [self coveredViews]];
      [GLUTView evaluateVisibilityOfViews: _viewStorage];
      [_viewStorage release];
      _viewStorage = nil;
   }
}

static void flipAndfixUpAlphaComponents(NSBitmapImageRep *imageRep)
{
        unsigned char * sp = [imageRep bitmapData];
        int bytesPerRow = [imageRep bytesPerRow];
        int height = [imageRep pixelsHigh];
        int width = [imageRep pixelsWide];
        unsigned int alphaMask = (NS_LittleEndian == NSHostByteOrder()) ? 0xFF000000 : 0x000000FF;
    
        while (height > 1) { // top half mirrored to bottom
            unsigned int * pt = (unsigned int *) sp;
            unsigned int * pb = (unsigned int *) (sp + (height - 1) * bytesPerRow) ;
            int w = width;
            while (w-- > 0) {
                unsigned int tmp = *pt | alphaMask;
                *pt++ = *pb | alphaMask;
                *pb++ = tmp;
            }
            sp += bytesPerRow;
            height -= 2;
        }
        if (height) { // middle row
            int w = width;
			unsigned int * pt = (unsigned int *) sp;
            while (w-- > 0) 
                *pt++ |= alphaMask;
        }
}

- (void)_recursiveCopyPixelsTo: (NSBitmapImageRep *)bitmap sourceRect: (NSRect)srcRect baseView: (NSView *)bView
{
   NSArray *		childs = [self subviews];
   unsigned int	i, count = [childs count];
   GLvoid *			pixels = (GLvoid *) [bitmap bitmapData];
   NSRect			rect = NSIntersectionRect([self bounds], srcRect);
   NSPoint			origin = [self convertPoint: rect.origin toView: bView];
   GLfloat			zero = 0.0f;
   
   [self lockFocus];
      while(glGetError() != GL_NO_ERROR);
      glPushAttrib(GL_ALL_ATTRIB_BITS);
      glPushClientAttrib(GL_CLIENT_PIXEL_STORE_BIT);
         glReadBuffer((_flags.treatAsSingle) ? GL_FRONT : GL_BACK);
         
         glDisable(GL_COLOR_TABLE);
         glDisable(GL_CONVOLUTION_1D);
         glDisable(GL_CONVOLUTION_2D);
         glDisable(GL_HISTOGRAM);
         glDisable(GL_MINMAX);
         glDisable(GL_POST_COLOR_MATRIX_COLOR_TABLE);
         glDisable(GL_POST_CONVOLUTION_COLOR_TABLE);
         glDisable(GL_SEPARABLE_2D);
         
         glPixelMapfv(GL_PIXEL_MAP_R_TO_R, 1, &zero);
         glPixelMapfv(GL_PIXEL_MAP_G_TO_G, 1, &zero);
         glPixelMapfv(GL_PIXEL_MAP_B_TO_B, 1, &zero);
         glPixelMapfv(GL_PIXEL_MAP_A_TO_A, 1, &zero);
         
		if (NS_LittleEndian == NSHostByteOrder())
			glPixelStorei(GL_PACK_SWAP_BYTES, 1);
		else
			glPixelStorei(GL_PACK_SWAP_BYTES, 0);
         glPixelStorei(GL_PACK_LSB_FIRST, 0);
         glPixelStorei(GL_PACK_IMAGE_HEIGHT, 0);
         glPixelStoref(GL_PACK_ROW_LENGTH, NSWidth(srcRect));
         glPixelStoref(GL_PACK_SKIP_PIXELS, origin.x);
         glPixelStoref(GL_PACK_SKIP_ROWS, NSHeight(srcRect) - (origin.y + NSHeight(rect)));
         glPixelStorei(GL_PACK_SKIP_IMAGES, 0);
         
         glPixelTransferi(GL_MAP_COLOR, 0);
         glPixelTransferf(GL_RED_SCALE, 1.0f);
         glPixelTransferf(GL_RED_BIAS, 0.0f);
         glPixelTransferf(GL_GREEN_SCALE, 1.0f);
         glPixelTransferf(GL_GREEN_BIAS, 0.0f);
         glPixelTransferf(GL_BLUE_SCALE, 1.0f);
         glPixelTransferf(GL_BLUE_BIAS, 0.0f);
         glPixelTransferf(GL_ALPHA_SCALE, 1.0f);
         glPixelTransferf(GL_ALPHA_BIAS, 0.0f);
         glPixelTransferf(GL_POST_COLOR_MATRIX_RED_SCALE, 1.0f);
         glPixelTransferf(GL_POST_COLOR_MATRIX_RED_BIAS, 0.0f);
         glPixelTransferf(GL_POST_COLOR_MATRIX_GREEN_SCALE, 1.0f);
         glPixelTransferf(GL_POST_COLOR_MATRIX_GREEN_BIAS, 0.0f);
         glPixelTransferf(GL_POST_COLOR_MATRIX_BLUE_SCALE, 1.0f);
         glPixelTransferf(GL_POST_COLOR_MATRIX_BLUE_BIAS, 0.0f);
         glPixelTransferf(GL_POST_COLOR_MATRIX_ALPHA_SCALE, 1.0f);
         glPixelTransferf(GL_POST_COLOR_MATRIX_ALPHA_BIAS, 0.0f);
         
         glReadPixels((GLint) NSMinX(rect), (GLint) NSMinY(rect),
                        (GLsizei) NSWidth(rect), (GLsizei) NSHeight(rect),
                        GL_RGBA, GL_UNSIGNED_INT_8_8_8_8, pixels);
      glPopClientAttrib();
      glPopAttrib();
	  // Get rid of any error, in order to not mislead GLUT clients...
	  while(glGetError() != GL_NO_ERROR);
   [self unlockFocus];
   
   for(i = 0; i < count; i++) {
      [(GLUTView *)[childs objectAtIndex: i]	_recursiveCopyPixelsTo: bitmap
                                             sourceRect: srcRect
                                             baseView: bView];
   }
}

- (NSBitmapImageRep *)bitmapInsideRect: (NSRect)rect
{
   NSBitmapImageRep *	bitmap = nil;
   
   if(NSIsEmptyRect(rect))
      rect = [self bounds];
   
   if((bitmap = [[[NSBitmapImageRep alloc]	initWithBitmapDataPlanes: NULL
                                             pixelsWide: NSWidth(rect)
                                             pixelsHigh: NSHeight(rect)
                                             bitsPerSample: 8
                                             samplesPerPixel: 4
                                             hasAlpha: YES
                                             isPlanar: NO
                                             colorSpaceName: NSDeviceRGBColorSpace
                                             bytesPerRow: NSWidth(rect) * 4
                                             bitsPerPixel: 32] autorelease]) == nil) {
      return nil;
   }   
      [self _recursiveCopyPixelsTo: bitmap sourceRect: rect baseView: self];
      flipAndfixUpAlphaComponents(bitmap);
   
   return bitmap;
}

- (NSImage *)imageWithTIFFInsideRect: (NSRect)rect
{
   NSBitmapImageRep *	bitmap = nil;
   NSImage *				image = nil;
   
      // Create an NSImage containing the actual window contents as a TIFF graphics
   if((image = [[[NSImage alloc] init] autorelease]) == nil)
      return nil;
   
   if((bitmap = [self bitmapInsideRect: rect]) == nil)
      return nil;
      
      [image addRepresentation: bitmap];
   
   return image;
}

- (void)prepareForMiniaturization
{
   NSBitmapImageRep *	bitmap = [self bitmapInsideRect: NSZeroRect];
   
   if([self lockFocusIfCanDraw]) {
      [bitmap draw];
      [self unlockFocus];
   }
}

- (void)recursiveWillBeginMorph: (int)op
{
   GLUTNode *	curChild = _allChildrens.head.succ;
   
   [self willBeginMorph: op];
   while(curChild) {
      [(id)(curChild->obj) recursiveWillBeginMorph: op];
      curChild = curChild->succ;
   }
}

- (void)recursiveDidEndMorph: (int)op
{
   GLUTNode *	curChild = _allChildrens.head.succ;
   
   while(curChild) {
      [(id)(curChild->obj) recursiveDidEndMorph: op];
      curChild = curChild->succ;
   }
   [self didEndMorph: op];
}

- (void)willBeginMorph: (int)op
{
   if(_trackingRectTag) {
      [self removeTrackingRect: _trackingRectTag];
      _trackingRectTag = 0;
   }
}

- (void)didEndMorph: (int)op
{
   if((_curEventMask & kEntryEvents) == kEntryEvents) {
      NSPoint	mouseLoc = [[self window] mouseLocationOutsideOfEventStream];
      NSRect	bounds = [self bounds];
      
      _flags.wasMouseInside = NSMouseInRect([self convertPoint: mouseLoc fromView: nil], bounds, YES);
      _trackingRectTag = [self addTrackingRect: bounds owner: self userData: nil assumeInside: _flags.wasMouseInside];
   }
}

/* Add a subview in its HIDDEN state. A latter Map work event will then
   put the view into the view hierarchy */
- (void)attachSubview: (GLUTView *)aView
{
   __glutAddTailNode(&_allChildrens, &aView->_siblings);
   aView->_savedSuperview = self;
}

- (void)detachFromSuperview
{
   GLUTView *	parent = (GLUTView *)[self superview];
   NSMutableSet *	views = [NSMutableSet set];
   
   [views unionSet: [self coveredViews]];
   [views addObject: self];
   __glutRemoveNode(&parent->_allChildrens, &_siblings);
   [self removeFromSuperview];
   [GLUTView evaluateVisibilityOfViews: views];
   [self setShown: NO];
}

- (GLUquadricObj *)_getQuadObj
{
    if (_quadObj == NULL)
        _quadObj = gluNewQuadric();
    return _quadObj;
}

// A helper for quadric objects
GLUquadricObj *__glutGetQuadObj(void)
{
    if (__glutViewList == NULL) // This means you never initialized GLUT - BUT you are still allowed to call glutWireShphere()
                                // and such anyway.  Fixes bug #2742838
        return gluNewQuadric();

    return [__glutCurrentView _getQuadObj];
}

- (void)processJoystick: (id)sender
{
   int buttonMask; 
   int x, y, z;
   
   if(_joystickFunc) {
      __glutGetJoystickInput (&buttonMask, &x, &y, &z);
      __glutSetWindow(self);
	  if (buttonMask || x || y || z)
		(*_joystickFunc)(buttonMask, x, y, z);
   }
}

- (void)processSpaceball: (id)sender
{
	static int buttonMask = 0; 
	static int x = 0, y = 0, z = 0, rx = 0, ry = 0, rz = 0;
	int savebuttonMask = 0;
	int savex = 0, savey = 0, savez = 0, saverx = 0, savery = 0, saverz = 0;
	
	if(_spaceballMotionFunc || _spaceballRotateFunc || _spaceballButtonFunc) {
		__glutGetSpaceballInput (&buttonMask, &x, &y, &z, &rx, &ry, &rz);
		__glutSetWindow(self);
		if (_spaceballMotionFunc && ((savex != x) || (savey != y) || (savez != z)))
			(*_spaceballMotionFunc)(x, y, z);
		if (_spaceballRotateFunc && ((saverx != rx)  || (savery != ry) || (saverz != rz)))
			(*_spaceballRotateFunc)(rx, ry, rz);
		if (_spaceballButtonFunc && (savebuttonMask != buttonMask)) {
			short i;
			for (i = 0; i < __glutGetSpaceballNumButtons(); i++) // for every current button
				if (((1 << i) & savebuttonMask) != ((1 << i) & buttonMask)) // if masks at this position are different
					(*_spaceballButtonFunc)(i+1, ((1 << i) & buttonMask)); // 0 is down 1 is up so look at old position as indicator
		}
		// store current values
		savex = x; savey = y; savez = z;
		saverx = rx; savery = ry; saverz = rz;
		savebuttonMask = buttonMask;
	}
}


/////////////////////////////////////////////
#pragma mark -
#pragma mark Menus
#pragma mark -


- (void)attachMenu: (GLUTMenu *)menu toButton: (int)button
{
	
   if ((_menu[button] != menu) && (button < GLUT_MAX_MENUS)) {
      /* Give the GLUT menu object a chance to build the native menu
         now, so that the user won't notice a delay when clicking
         while the GLUTMenu is occupied building the native menu. */
      (void) [menu nativeMenu];
      [_menu[button] release];
      _menu[button] = nil;
      _menu[button] = [menu retain];
   }
}

- (void)detachMenuFromButton: (int)button
{
    if (button < GLUT_MAX_MENUS) {
		[_menu[button] release];
		_menu[button] = nil;
	}
}

- (void)_popUpContextMenu: (GLUTMenu *)aMenu withEvent: (NSEvent *)theEvent
{
   __glutStartMenu(aMenu, self, [theEvent locationInWindow]);
	[NSMenu popUpContextMenu: [aMenu nativeMenu] withEvent: theEvent forView: self];
   if((_curEventMask & kPassiveMotionEvents) == kPassiveMotionEvents) {
      /* Work around a bug in the AppKit whereby a window with mouse moved events
         generation turned on, stops sending any further such events after the
         user has played around with either a menubar menu or a contextual menu.
         Looks like as if the Carbon MenuManager changes the window's event mask
         so that it includes mouse moved events before it enters its internal
         modal event loop. However, it removes the mouse moved events from the
         window's event mask as soon as the modal event loop ended. All this happens
         behind the back of the AppKit so it still thinks mouse moved events are
         generated when in fact they are no longer 'cause the MM turned them off. */
      NSWindow *	window = [self window];
      
      [window setAcceptsMouseMovedEvents: NO];
      [window setAcceptsMouseMovedEvents: YES];
   }
}


/////////////////////////////////////////////
#pragma mark -
#pragma mark Events
#pragma mark -


- (BOOL)acceptsFirstMouse: (NSEvent *)theEvent	{ return YES; }
- (BOOL)acceptsFirstResponder	{ return YES; }

- (BOOL)becomeFirstResponder
{
   __glutSetWindow(self);
   return YES;
}

/* Key up/down & special up/down */
- (void)keyDown: (NSEvent *)theEvent
{
   char		utf8[16];
   int		i, len = 16;
   NSPoint	loc;
   BOOL		isSpecial;
   
   if(_flags.ignoreKeyRepeats && [theEvent isARepeat])
      return;
   
   loc = [self convertPoint: [[self window] mouseLocationOutsideOfEventStream] fromView: nil];
   _iMouseLocX = rint(loc.x);
   _iMouseLocY = rint(loc.y);
   __glutModifierMask = [theEvent modifierFlags];
   
   __glutMapKeyCode(theEvent, utf8, &len, &isSpecial);
   
	__glutSetWindow(self);
   for(i = 0; i < len; i++) {
      if(!isSpecial && _keyDownFunc) {
         (*_keyDownFunc)((unsigned char) utf8[i], _iMouseLocX, _iMouseLocY);
      } else if(_specialFunc) {
         (*_specialFunc)(utf8[i], _iMouseLocX, _iMouseLocY);
      }
   }
   __glutModifierMask = ~0;
}

- (void)keyUp: (NSEvent *)theEvent
{
   char	utf8[16];
   int	i, len = 16;
   BOOL	isSpecial;
   
   if(_flags.ignoreKeyRepeats && [theEvent isARepeat])
      return;
   
   __glutModifierMask = [theEvent modifierFlags];
   __glutMapKeyCode(theEvent, utf8, &len, &isSpecial);   
   
   __glutSetWindow(self);
   for(i = 0; i < len; i++) {      
      if(!isSpecial && _keyUpFunc) {
         (*_keyUpFunc)((unsigned char) utf8[i], _iMouseLocX, _iMouseLocY);
      } else if(_specialUpFunc) {
         (*_specialUpFunc)(utf8[i], _iMouseLocX, _iMouseLocY);
      }
   }
   __glutModifierMask = ~0;
}

- (void)_commonMouseDown: (NSEvent *)theEvent
{
   GLUTMenu * 	menu = nil; // initially no menus
   int			buttonID, buttonPhysID;
   
   __glutMapMouseButton(theEvent, &buttonID, &buttonPhysID, &__glutModifierMask);

   if (buttonID != buttonPhysID)
      _flags.wasMouseEmulated = 1 << (buttonID-1); // let mouse up know later what button was emulated

   if ((buttonID >= 0) && (buttonID < GLUT_MAX_MENUS)) { // ensure we are only accessing menus that exist
      if (!__glutGameModeWindow) // only do menus when not in gamemode
         menu = _menu[buttonID];

      if (menu) {
         [self _popUpContextMenu: menu withEvent: theEvent];
      } else if(_mouseFunc) {
         // Only send in events where this isn't a duplicate mouse down (emulation)
         // This way we can maintain a 1 to 1 up/down ratio
         if( !(_flags.hadMouseDown & (1 << buttonID)) ) {
            NSPoint location = [self convertPoint: [theEvent locationInWindow] fromView: nil];

            __glutSetWindow(self);
            (*_mouseFunc)(buttonID, GLUT_DOWN, rint(location.x), rint(location.y));
            _flags.hadMouseDown |= 1 << buttonID;
         }
         else // catch when the button is down twice via emulation
            _flags.duplicateEmulatedMouseDown = 1;

      }
      __glutModifierMask = ~0;
   }
}

- (void)_commonMouseUp: (NSEvent *)theEvent
{
   /* Only pass the mouse up event to the GLUT application if it belongs
      to a previously seen mouse down. Spurious mouse up events may come
      along if (1) a pop-up menu is assigned to a mouse button, (2) the
      user invoked the menu and (3) the user dismissed the menu by
      clicking *outside* of the pop-up menu. Such mouse up events should
      not be passed to the GLUT app. */
   if(_mouseFunc) {
      NSPoint	location = [self convertPoint: [theEvent locationInWindow] fromView: nil];
      int		buttonID, buttonPhysID;
      
      __glutMapMouseButton(theEvent, &buttonID, &buttonPhysID, &__glutModifierMask);

	  // Check for emulation when looking at button 0 up events
      if(buttonPhysID == 0) {
         if(_flags.wasMouseEmulated) {
            // make mouse up event match emulated mouse down button
            buttonID = 1 << (_flags.wasMouseEmulated-1);
         }
         else buttonID = 0;
      }

      if(buttonID >= 0 && (_flags.hadMouseDown & (1<<buttonID))) {
         if(_flags.duplicateEmulatedMouseDown &&
            ((_flags.wasMouseEmulated<<1) & (1<<buttonID))) {
			 // Emulation caused this button to be down twice at the same time
            _flags.duplicateEmulatedMouseDown = 0;
             // Ignore this mouse up event and wait for a second one
         }
         else {
            __glutSetWindow(self);
            (*_mouseFunc)(buttonID, GLUT_UP, rint(location.x), rint(location.y));
            _flags.hadMouseDown &= ~(1 << buttonID);
         }
      }
      __glutModifierMask = ~0;

      if((buttonPhysID == 0) && _flags.wasMouseEmulated)
         _flags.wasMouseEmulated = 0;
   }
}

- (void)_commonMouseDragged: (NSEvent *)theEvent
{
   if([theEvent buttonNumber] <= 2 && _motionFunc) {
      NSPoint	location  = [self convertPoint: [theEvent locationInWindow] fromView: nil];
      
      __glutSetWindow(self);
      (*_motionFunc)(rint(location.x), rint(location.y));
   }
}

/* Left mouse */
- (void)mouseDown: (NSEvent *)theEvent
{
   [self _commonMouseDown: theEvent];
}

- (void)mouseUp: (NSEvent *)theEvent
{
   [self _commonMouseUp: theEvent];
}

- (void)mouseDragged: (NSEvent *)theEvent
{
   [self _commonMouseDragged: theEvent];
}

- (void)mouseMoved: (NSEvent *)theEvent
{
   NSPoint	location = [self convertPoint: [theEvent locationInWindow] fromView: nil];
   
   if(_entryFunc) {
      /* Generate a facked enter/exit event because the AppKit forgets
         about its tracking rects as soon as you enable the generation
         of mouse moved events... */
      BOOL	isInside = NSMouseInRect(location, [self bounds], YES);
      
      if(isInside ^ _flags.wasMouseInside) {
         _flags.wasMouseInside = isInside;
         __glutSetWindow(self);
         (*_entryFunc)((isInside) ? GLUT_ENTERED : GLUT_LEFT);
      }
   }
   
   if(_passiveMotionFunc) {
      __glutSetWindow(self);
      (*_passiveMotionFunc)(rint(location.x), rint(location.y));
   }
}

/* Right mouse */
- (void)rightMouseDown: (NSEvent *)theEvent
{
   [self _commonMouseDown: theEvent];
}

- (void)rightMouseUp: (NSEvent *)theEvent
{
   [self _commonMouseUp: theEvent];
}

- (void)rightMouseDragged: (NSEvent *)theEvent
{
   [self _commonMouseDragged: theEvent];
}

/* Middle mouse */
- (void)otherMouseDown: (NSEvent *)theEvent
{
   [self _commonMouseDown: theEvent];
}

- (void)otherMouseUp: (NSEvent *)theEvent
{
   [self _commonMouseUp: theEvent];
}

- (void)otherMouseDragged: (NSEvent *)theEvent
{
   [self _commonMouseDragged: theEvent];
}

- (void)mouseEntered: (NSEvent *)theEvent
{
   if(_entryFunc) {
      _flags.wasMouseInside = YES;
      __glutSetWindow(self);
      (*_entryFunc)(GLUT_ENTERED);
   }
}

- (void)mouseExited: (NSEvent *)theEvent
{
   if(_entryFunc) {
      _flags.wasMouseInside = NO;
      __glutSetWindow(self);
      (*_entryFunc)(GLUT_LEFT);
   }
}

- (BOOL)validateMenuItem: (NSMenuItem *)menuItem
{
   /* User is about to start a menu tracking session. We install a special
      timer which will execute the idle function while menu tracking is
      going on because menu tracking happens in its own modal event loop. */
   __glutStartIdleFuncTimer();
   
   if(__glutDisablePrinting) {
      if([menuItem action] == @selector(print:))
         return NO;
   }
   return YES;
}

- (void)print: (id)sender
{
   [[self window] print: sender];
}


/////////////////////////////////////////////
#pragma mark -
#pragma mark Visibility
#pragma mark -


- (BOOL)isVisible
{
   if(_flags.isSubwindow)
      return ([self superview] != nil);
   else
      return [[self window] isVisible];
}

/**
 * Returns an ordered list of all currently visible siblings of the
 * receiver. Views are ordered from front to back.
 */
- (NSArray *)_orderedSiblings
{
   NSMutableArray *	siblings = nil;
   
   if(_flags.isSubwindow) {
      // We're a subwindow
      NSArray *			subviews = [[self superview] subviews];
      NSEnumerator *		enumerator = [subviews reverseObjectEnumerator];
      id						obj;

      siblings = [NSMutableArray arrayWithCapacity: [subviews count]];      
      while((obj = [enumerator nextObject]) != nil)
         [siblings addObject: obj];
   } else {
      // We're a top-level window
   NSArray *		windows = [NSApp orderedWindows];
      unsigned				i, count = [windows count];
      
      siblings = [NSMutableArray arrayWithCapacity: count];
      for(i = 0; i < count; i++) {
         NSWindow *	curWindow = [windows objectAtIndex: i];
         NSView *		contView = [curWindow contentView];
         
         if([curWindow isVisible] &&
            [curWindow isKindOfClass: [GLUTWindow class]] &&
            contView)
            [siblings addObject: contView];
      }
   }
   
   return siblings;
}

/**
 * Puts all siblings of the receiver  into the given mutable set which
 * are at a lower place in the view (window) stack. Further, adds the
 * receiver's parent view to the set if it is a subwindow.
 */
- (NSSet *)coveredViews
{
   NSMutableSet *	aSet = [NSMutableSet setWithCapacity: 13];
   NSWindow *		window = [self window];
   NSArray *		siblings = [self _orderedSiblings];	// front -> back
   unsigned		i, count = [siblings count];
   NSRect			myBounds = [self bounds];
   
   // convert my bounds to screen space
   myBounds = [self convertRect: myBounds toView: nil];
   myBounds.origin = [window convertBaseToScreen: myBounds.origin];
   
   // add parent, if we're a subwindow
   if(_flags.isSubwindow && [self superview]) {
      [aSet addObject: [self superview]];
   }
   
   if(count > 1) {
      // add all siblings which are below us
      for(i = count - ([siblings indexOfObjectIdenticalTo: self] + 1); i < count; i++) {
         NSView *	curView = [siblings objectAtIndex: i];
         NSRect	curBounds = [curView bounds];
         
         curBounds = [curView convertRect: curBounds toView: nil];
         curBounds.origin = [[curView window] convertBaseToScreen: curBounds.origin];
         
         if(!NSIsEmptyRect(NSIntersectionRect(myBounds, curBounds)))
            [aSet addObject: curView];
      }
   }
   
   return aSet;
}

/**
 * Evaluates the receiver's visibility based on the current state
 * of the window or view hierarchy.
 */
- (void)_evaluateVisibility
{
   int	status = GLUT_FULLY_RETAINED;
   
   if([self isVisible]) {
      /* We're visible */
      NSArray *	others;
      NSRect		myBounds = [self bounds];
      double		myArea, myVisibleArea;
      unsigned		i, count;
      
      // compute my screen space bounds
      myBounds = [self convertRect: myBounds toView: nil];
      myBounds.origin = [[self window] convertBaseToScreen: myBounds.origin];
      
      // compute my area in pixels
      myArea = NSWidth(myBounds) * NSHeight(myBounds);
      myVisibleArea = myArea;
      
      // (1) find out what influence all my siblings above me have on my visibility
      others = [self _orderedSiblings];
      count = [others indexOfObjectIdenticalTo: self];
      for(i = 0; (i < count) && (myVisibleArea >= DBL_EPSILON); i++) {
         NSView *	curView = [others objectAtIndex: i];
         NSRect	curBounds = [curView bounds];
         NSRect	iRect;
         
         curBounds = [curView convertRect: curBounds toView: nil];
         curBounds.origin = [[curView window] convertBaseToScreen: curBounds.origin];
         
         iRect = NSIntersectionRect(myBounds, curBounds);
         myVisibleArea -= NSWidth(iRect) * NSHeight(iRect);
      }
      
      if(myVisibleArea >= DBL_EPSILON) {
         // (2) find out what influence all my child views have on my visibility
         others = [self subviews];
         count = [others count];
         for(i = 0; (i < count) && (myVisibleArea >= DBL_EPSILON); i++) {
            NSView *	curView = [others objectAtIndex: i];
            NSRect	curBounds = [curView bounds];
            NSRect	iRect;
            
            curBounds = [curView convertRect: curBounds toView: nil];
            curBounds.origin = [[curView window] convertBaseToScreen: curBounds.origin];
            
            iRect = NSIntersectionRect(myBounds, curBounds);
            myVisibleArea -= NSWidth(iRect) * NSHeight(iRect);
         }
      }
      
      // classify our remaining visible area
      if(myVisibleArea < DBL_EPSILON)
      status = GLUT_FULLY_COVERED;
      else if(myVisibleArea < (myArea - DBL_EPSILON))
               status = GLUT_PARTIALLY_RETAINED;
      else
                  status = GLUT_FULLY_RETAINED;
   } else {
      /* We're hidden */
      status = GLUT_HIDDEN;
   }
   
   /* Remember the newly computed visibility state and put us onto the visibility
      update list, if we're not already there. */
   if(_newVisState == GLUT_UNKNOWN_VISIBILITY) {
      _visibilityNext = NULL;
      
      if(__glutVisibilityUpdateList == NULL) {
         __glutVisibilityUpdateList = self;
         __glutVisibilityUpdateTail = self;
      } else {
         __glutVisibilityUpdateTail->_visibilityNext = self;
         __glutVisibilityUpdateTail = self;
      }
   }
   
   _newVisState = status;
}

- (void)_recursiveMarkHidden
{
   if(_visState != GLUT_HIDDEN) { // if we are not already hidden
      NSArray *		childrens = [self subviews];
      unsigned int	i, count = [childrens count];
      
#if __GLUT_LOG_VISIBILITY
      __glutPrintVisibilityState(GLUT_HIDDEN, _winid);
#endif
	  _visState = GLUT_HIDDEN; // ensure it is really marked hidden
		if(_windowStatusFunc) {
			__glutSetWindow(self);
			(*_windowStatusFunc)(GLUT_HIDDEN);
		}
      
      /* An unmap is only reported on a single window; its
         descendents need to know they are no longer visible. */      
      for(i = 0; i < count; i++) {
         [(GLUTView *)[childrens objectAtIndex: i] _recursiveMarkHidden];
      }
   }
}

- (void)_updateComputedVisibility
{
   if(_flags.isVisibilityUpdateAllowed) {
      int	visState = _newVisState;
      
      _newVisState = GLUT_UNKNOWN_VISIBILITY;
      _visibilityNext = NULL;
      
      if(_visState != GLUT_FULLY_RETAINED &&
         (visState == GLUT_PARTIALLY_RETAINED || visState == GLUT_FULLY_RETAINED)) {
         /* We just became 'more' visible or we have been partially visible
            and somehow a new partial visibility was computed */
         _flags.isDamaged = YES;
      }
      
      if(visState == GLUT_HIDDEN) {
         [self _recursiveMarkHidden];
      } else { 
         if(visState != _visState) {
#if __GLUT_LOG_VISIBILITY
            __glutPrintVisibilityState(visState, _winid);
#endif
            _visState = visState; //ggs: always set vis state
            if(_windowStatusFunc) {
               __glutSetWindow(self);
               (*_windowStatusFunc)(visState);
            }
         }         
      }
   }
}

- (void)enableVisibilityUpdates
{
   _flags.isVisibilityUpdateAllowed = YES;
}

/**
 * Evaluates the visibility of the given set of views. The visibility
 * state of all views is updated after all of them have been evaluated.
 */
+ (void)evaluateVisibilityOfViews: (NSSet *)views
{
   NSEnumerator *	enumerator = [views objectEnumerator];
   GLUTView *		curView;

      /* (1) compute new visibility states */
   while((curView = (GLUTView *) [enumerator nextObject]) != nil) {
      [curView _evaluateVisibility];
   }
      
      /* (2) update visibility states */
      curView = __glutVisibilityUpdateList;
      while(curView) {
         GLUTView *	tmpView = curView->_visibilityNext;
         
         [curView _updateComputedVisibility];
         curView = tmpView;
      }
      __glutVisibilityUpdateList = NULL;
      __glutVisibilityUpdateTail = NULL;
}

- (void)recursiveCollectViewsIntoSet: (NSMutableSet *)views
{
   NSArray *	subviews = [self subviews];
   unsigned		i, count = [subviews count];
   
   [views addObject: self];
   for(i = 0; i < count; i++)
      [(GLUTView *) [subviews objectAtIndex: i] recursiveCollectViewsIntoSet: views];
}

@end
