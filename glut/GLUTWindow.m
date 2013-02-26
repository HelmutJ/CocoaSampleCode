
/* Copyright (c) Dietmar Planitzer, 1998, 2002 - 2003 */

/* This program is freely distributable without licensing fees 
   and is provided without guarantee or warrantee expressed or 
   implied. This program is -not- in the public domain. */

#import "macx_glut.h"
#import "GLUTWindow.h"
#import "GLUTView.h"
#import "GLUTApplication.h"


NSString *GLUTWindowFrame = @"GLUTWindowFrame";


@interface GLUTView(GLUTPrivate)
- (void)_commonReshape;
@end


@interface GLUTWindow(GLUTPrivate)
- (id)_initWithContentRect: (NSRect)rect styleMask: (unsigned int)mask contentView: (GLUTView *)aView;
- (id)_initWithWindow: (GLUTWindow *)aWindow operation: (int)op arguments: (NSDictionary *)operands;
- (NSWindow *)_windowWithTIFFInsideRect: (NSRect)rect;
- (NSData *)_dataWithTIFFOfContentView;
- (NSData *)_dataWithRTFDOfContentView;
@end


/////////////////////////////////////////////
#pragma mark -


@implementation GLUTWindow

static BOOL 		gInitialized = NO;
static NSArray *	gServicesTypes = nil;


+ (void)initialize
{	
	if(!gInitialized) {
		gInitialized = YES;
		
		gServicesTypes = [[NSArray arrayWithObjects: NSTIFFPboardType, NSRTFDPboardType, nil] retain];
		[NSApp registerServicesMenuSendTypes: gServicesTypes returnTypes: nil];
	}
}

+ (id)windowByMorphingWindow: (GLUTWindow *)aWindow operation: (int)op arguments: (NSDictionary *)dict
{
   return [[[self alloc] _initWithWindow: aWindow operation: op arguments: dict] autorelease];
}


/* Designated initializer */
- (id)_initWithContentRect: (NSRect)rect styleMask: (unsigned int)mask contentView: (GLUTView *)aView
{
   if((self = [super initWithContentRect: rect styleMask: mask backing: NSBackingStoreBuffered defer: NO]) != nil) {
      [self setReleasedWhenClosed: NO];
      [self setMinSize: NSMakeSize(80.0, 80.0)];
      [self setShowsResizeIndicator:NO]; // turn off the grow box.
      [self setContentView: aView];
      [self makeFirstResponder: aView];
      [self setDelegate: self];
      return self;
   }
   return nil;
}

- (id)initWithContentRect: (NSRect)rect pixelFormat: (NSOpenGLPixelFormat *)pixelFormat
            windowID: (int)winid gameMode: (BOOL)gameMode fullscreenStereo: (BOOL)pfStereo treatAsSingle: (BOOL)treatAsSingle
{
   unsigned int	mask;
   GLUTView *		view = nil;
   
   if(gameMode) { // set to fill screen
      float				offsetY = 0.0f;
      /* XXX NSScreen BUG WORKAROUND
         The purpose of the following code is to workaround a bug in the NSScreen class.
         The problem is that this class doesn't realize that we switched from the original
         screen mode to another mode via the CGDisplaySwitchToMode() function and thus
         keeps on reporting now out-dated screen attributes like screen width & height.
         This however has the unfortunate consequence that our NSWindow would be positioned
         incorrectly if the new mode has a smaller Y resolution than the old one. I.e.
         if the old Y res was 870 and the new is 480 the window would be placed by 390 pixels
         too far below.
      */
      NSScreen *	screen = [[NSScreen screens] objectAtIndex: 0];
      NSSize		screenSize = [screen frame].size;
      
      if(screenSize.height - rect.size.height > 0.0f)
         offsetY = screenSize.height - rect.size.height;
      rect.origin.y = offsetY;
      mask = NSBorderlessWindowMask;
   } else {
      mask = (NSTitledWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask);
   }
   
   /* create and configure content view */
   view = [[[GLUTView alloc]	initWithFrame: rect
                              pixelFormat: pixelFormat
                              windowID: winid
                              treatAsSingle: treatAsSingle
                              isSubwindow: NO
                              fullscreenStereo:pfStereo 
							  isVBLSynced: __glutSyncToVBL] autorelease];
   if(view)
      return [self _initWithContentRect: rect styleMask: mask contentView: view];
   else
      return nil;
}

- (id)_initWithWindow: (GLUTWindow *)aWindow operation: (int)op arguments: (NSDictionary *)dict
{
   GLUTView *		contentView = nil;
   NSResponder *	savedFirstResponder;
   NSRect			rect = {{0.0f, 0.0f}, {0.0f, 0.0f}};
   unsigned int		mask = 0;
   int				level = 0;
   
   switch(op) {
      case kGLUTMorphOperationFullscreen:
            /* Make a fullscreen window */
			if (NO == __glutUseExtendedDesktop) {
				rect = [[aWindow screen] frame];
			} else { // look at all screens
				NSEnumerator *enumerator = [[NSScreen screens] objectEnumerator];
				NSScreen *	screen = nil;
				while (nil != (screen = (NSScreen *)[enumerator nextObject])) {
					if([screen frame].origin.x < rect.origin.x)
						rect.origin.x = [screen frame].origin.x;
					if([screen frame].origin.y < rect.origin.y)
						rect.origin.y = [screen frame].origin.y;
					if(([screen frame].origin.x + [screen frame].size.width - rect.origin.x) > rect.size.width)
						rect.size.width = [screen frame].origin.x + [screen frame].size.width - rect.origin.x;
					if(([screen frame].origin.y + [screen frame].size.height -  rect.origin.y) > rect.size.height)
						rect.size.height = [screen frame].origin.y + [screen frame].size.height -  rect.origin.y;
				}
			}
            mask = NSBorderlessWindowMask;
            level = GLUT_FULLSCREEN_LEVEL;

            break;
            
      case kGLUTMorphOperationRegular:
            /* Make a standard window */
            rect = [[dict objectForKey: GLUTWindowFrame] rectValue];
            mask = (NSTitledWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask);
            level = GLUT_NORMAL_LEVEL;
            break;
   }
   
   savedFirstResponder = [aWindow firstResponder];
   contentView = (GLUTView *) [[aWindow contentView] retain];
   [contentView recursiveWillBeginMorph: op];
   [aWindow setContentView: nil];
   
   if((self = [self _initWithContentRect: rect styleMask: mask contentView: contentView]) != nil) {
      [self setLevel: level];

      switch(op) {
         case kGLUTMorphOperationFullscreen: // new window is full screen
            _isFullscreen = YES;
            /* put window on fullscreen window list */
            _nextFullscreenWindow = __glutFullscreenWindows;
            __glutFullscreenWindows = self;
               break;
         case kGLUTMorphOperationRegular: // new window is not full screen
            _isFullscreen = NO;
               break;
      }
      

      _imagePath = [aWindow->_imagePath copy];
      _enabledMouseMovedEvents = aWindow->_enabledMouseMovedEvents;
      if(_enabledMouseMovedEvents > 0)
         [self setAcceptsMouseMovedEvents: YES];
      [contentView recursiveDidEndMorph: op];
      [self makeFirstResponder: savedFirstResponder];
      // Call _commonReshape on the window's content view in order
      // to simulate a resize event (we don't automatically get one
      // because we just moved the content view from one window to
      // to another one...)
      [contentView _commonReshape];
      [contentView release];
      
      return self;
   }
   return nil;
}

- (void)dealloc
{
	// remove from full screen window list
   if(_isFullscreen) {
      GLUTWindow *	prev = nil;
      GLUTWindow *	cur = __glutFullscreenWindows;
      
      while(cur != nil && cur != self) {
         prev = cur;
         cur = cur->_nextFullscreenWindow;
      }
      
      if(prev)
         prev->_nextFullscreenWindow = _nextFullscreenWindow;
      else
         __glutFullscreenWindows = _nextFullscreenWindow;
   }
   
   [super dealloc];
}

- (void)finalize
{
   if(_isFullscreen) {
      GLUTWindow *	prev = nil;
      GLUTWindow *	cur = __glutFullscreenWindows;
      while(cur != nil && cur != self) {
         prev = cur;
         cur = cur->_nextFullscreenWindow;
      }
      if(prev)
         prev->_nextFullscreenWindow = _nextFullscreenWindow;
      else
         __glutFullscreenWindows = _nextFullscreenWindow;
   }
   [super finalize];
}

- (BOOL)isFullscreen
{
   return _isFullscreen;
}

/* Returns YES if the window 'me' is either above or below the frame rectangle
   of any fullscreen window and NO otherwise */
- (BOOL)isAffectedByFullscreenWindow
{
   NSRect			frame = [self frame];
   GLUTWindow *	cur = __glutFullscreenWindows;
   
   while(cur != nil) {
      NSRect	othFrame = [cur frame];
      
      if(NSContainsRect(othFrame, frame) ||
         NSEqualRects(othFrame, frame) ||
         NSIntersectsRect(othFrame, frame))
         return YES;
         
      cur = cur->_nextFullscreenWindow;
   }
   return NO;
}


/////////////////////////////////////////////
#pragma mark -
#pragma mark Events
#pragma mark -


- (void)enableMouseMovedEvents
{
   _enabledMouseMovedEvents++;
   if(_enabledMouseMovedEvents == 1)
      [self setAcceptsMouseMovedEvents: YES];
}

- (void)disableMouseMovedEvents
{
   NSAssert(_enabledMouseMovedEvents >= 0, @"bogus -disableMouseMovedEvents");
   _enabledMouseMovedEvents--;
   if(_enabledMouseMovedEvents == 0)
      [self setAcceptsMouseMovedEvents: NO];
}

- (BOOL)canBecomeKeyWindow
{
   return (!__glutGameModeWindow && !_isFullscreen) ? [super canBecomeKeyWindow] : YES;
}

- (void)sendEvent: (NSEvent *)event
{
   [super sendEvent: event];
   if(__glutMappedMenu) {
      /* use mapped menu to determine if menu finishing needs to be done, regardless of button */
         __glutFinishMenu([NSEvent mouseLocation]); /* sets mapped menu to nil */
         __glutMenuWindow = nil;
	}
}

- (BOOL)validateMenuItem: (NSMenuItem *)menuItem
{
   SEL	action = [menuItem action];
   
   if(action == @selector(save:) || action == @selector(saveAs:))
      return (!__glutDisableGrabbing) ? [self isDocumentEdited] : NO;
   
   if(action == @selector(copy:))
      return (!__glutDisableGrabbing);
   
   if(__glutDisablePrinting) {
      if(action == @selector(runPageLayout:) || action == @selector(print:))
         return NO;
   }
   return [super validateMenuItem: menuItem];
}

- (IBAction)save: (id)sender
{
   if(_imagePath) {
      NSData *	data = [self contentsAsDataOfType: NSTIFFPboardType];

      if(!data || !__glutWriteDataToFile(data, _imagePath, 'TIFF')) {
         NSBundle *	bdl = __glutGetFrameworkBundle();
         
         NSRunCriticalAlertPanel(NSLocalizedStringFromTableInBundle(@"Save Error", @"GLUTUI",
                              bdl, @"Save Error"),
                              NSLocalizedStringFromTableInBundle(@"Unable to save current window contents.", @"GLUTUI",
                              bdl, @"Unable to save current window contents."),
                              @"OK", nil, nil);
      }
      [self setDocumentEdited: NO];
   } else {
		[self saveAs: sender];
   }
}

   /* Save As */
- (void)savePanelDidEnd: (NSWindow *)sheet returnCode: (int)returnCode contextInfo: (id)savePanel
{
   if(returnCode == NSOKButton) {
      NSData *	data = [self contentsAsDataOfType: NSTIFFPboardType];
      
      [_imagePath release];
      _imagePath = [[savePanel filename] copy];
      
      if(!data || !__glutWriteDataToFile(data, _imagePath, 'TIFF')) {
         NSBundle *	bdl = __glutGetFrameworkBundle();
         
         NSRunCriticalAlertPanel(NSLocalizedStringFromTableInBundle(@"Save Error", @"GLUTUI",
                              bdl, @"Save Error"),
                              NSLocalizedStringFromTableInBundle(@"Unable to save current window contents.", @"GLUTUI",
                              bdl, @"Unable to save current window contents."),
                              @"OK", nil, nil);
      }

      [self setDocumentEdited: NO];
   }
}

- (IBAction)saveAs: (id)sender
{
   NSSavePanel *	savePanel = [NSSavePanel savePanel];
   NSString *		imageDirectory, *imageName;
   
   if(!_imagePath) {
      _imagePath = [[[NSFileManager defaultManager] currentDirectoryPath] copy];
      imageDirectory = _imagePath;
      imageName = @"";
   } else {
      imageDirectory = _imagePath;
      imageName = [[_imagePath lastPathComponent] stringByDeletingPathExtension];
   }
   
   [savePanel setCanSelectHiddenExtension: YES];
   [savePanel setRequiredFileType: @"tiff"];
   [savePanel	beginSheetForDirectory: imageDirectory
               file: imageName
               modalForWindow: self
               modalDelegate: self
               didEndSelector: @selector(savePanelDidEnd:returnCode:contextInfo:)
               contextInfo: savePanel];
}

- (IBAction)copy: (id)sender
{
   NSString *	type = NSTIFFPboardType;
   NSData *		imageData = [self contentsAsDataOfType: type];
	
   if(imageData) {
      NSPasteboard *	generalPboard = [NSPasteboard generalPasteboard];
      
      [generalPboard declareTypes: [NSArray arrayWithObjects: type, nil] owner: nil];
      [generalPboard setData: imageData forType: type];
   }
}

   /* Page Layout */
- (void)pageLayoutDidEnd: (NSPageLayout *)pageLayout returnCode: (int)returnCode contextInfo: (id)printInfo
{
   if(returnCode == NSOKButton) {
      [NSPrintInfo setSharedPrintInfo: printInfo];
   }
}

- (void)runPageLayout: (id)sender
{
   NSPageLayout *	pageLayout = [NSPageLayout pageLayout];
   NSPrintInfo *	printInfo = [NSPrintInfo sharedPrintInfo];
   
   [pageLayout	beginSheetWithPrintInfo: printInfo
               modalForWindow: self
               delegate: self
               didEndSelector: @selector(pageLayoutDidEnd:returnCode:contextInfo:)
               contextInfo: printInfo];
}

   /* Print Panel */
- (void)printOperationDidRun: (NSPrintOperation *)printOperation success: (BOOL)success contextInfo: (id)window
{
   [window release];
}

- (void)print: (id)sender
{
   NSWindow *	window = [[self _windowWithTIFFInsideRect: NSZeroRect] retain];
   
   if(window) {
      NSPrintOperation *	printOperation = [NSPrintOperation printOperationWithView: [window contentView]];
      
      [printOperation	runOperationModalForWindow: self
                        delegate: self
                        didRunSelector: @selector(printOperationDidRun:success:contextInfo:)
                        contextInfo: window];
   } else {
      NSBundle *	bdl = __glutGetFrameworkBundle();
      
      NSRunCriticalAlertPanel(NSLocalizedStringFromTableInBundle(@"Print Error", @"GLUTUI",
                              bdl, @"Print Error"),
                              NSLocalizedStringFromTableInBundle(@"Could not generate PDF data for printing.", @"GLUTUI",
                              bdl, @"Could not generate PDF data for printing."),
                              @"OK", nil, nil);
   }
}

- (void)zoom:(id)sender
{
   NSMutableSet *	views = [NSMutableSet set];
   GLUTView *		view = (GLUTView *) [self contentView];
   
   [views unionSet: [view coveredViews]];
   [views addObject: view];
   
   [super zoom: sender];
   
   [views unionSet: [view coveredViews]];
   [GLUTView evaluateVisibilityOfViews: views];
}


/////////////////////////////////////////////
#pragma mark -
#pragma mark Services
#pragma mark -


- (id)validRequestorForSendType:(NSString *)sendType returnType:(NSString *)returnType
{
   if([gServicesTypes containsObject: sendType])
      return self;
   
   return [super validRequestorForSendType: sendType returnType: returnType];
}

- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pboard types:(NSArray *)types
{
   unsigned	i, count = [types count];
   
   for(i = 0; i < count; i++) {
      NSString *	pboardType = [types objectAtIndex: i];
      NSData *		imageData = [self contentsAsDataOfType: pboardType];
      
      if(imageData) {
         [pboard declareTypes: [NSArray arrayWithObject: pboardType] owner: nil];
         [pboard setData: imageData forType: pboardType];
         return YES;
      }
   }
   
   return NO;
}


/////////////////////////////////////////////
#pragma mark -
#pragma mark Image Data Creation
#pragma mark -


- (NSWindow *)_windowWithTIFFInsideRect: (NSRect)rect
{
   NSImage *		image = nil;
   NSImageView *	imageView = nil;
   NSWindow *		window = nil;
   GLUTView *		view = (GLUTView *) [self contentView];
   
   if(NSIsEmptyRect(rect))
      rect = [view bounds];
   
   if((imageView = [[NSImageView alloc] initWithFrame: rect]) == nil)
      return nil;
   
   if((window = [[NSWindow alloc]	initWithContentRect: rect
												styleMask: NSBorderlessWindowMask
												backing: NSBackingStoreNonretained
												defer: NO]) == nil) {
      [imageView release];
      return nil;
   }
      
   [window setContentView: imageView];
   [imageView release];
   
   if((image = [view imageWithTIFFInsideRect: rect]) == nil) {
      [window release];
      return nil;
   }	
   [imageView setImage: image];
   
   return [window autorelease];
}

- (NSData *)_dataWithTIFFOfContentView
{
   NSImage *	image = [(GLUTView *) [self contentView] imageWithTIFFInsideRect: NSZeroRect];
   NSData *		data = nil;
   
   if(image != nil) {
      data = [image TIFFRepresentation];
   }
   return data;
}

- (NSData *)_dataWithRTFDOfContentView
{
	static int				generationCounter = 1;
	NSAttributedString *	myString = nil;
	NSFileWrapper *		myFileWrapper = nil;
	NSTextAttachment *	myTextAttachment = nil;
	NSData *					tiffData = [self _dataWithTIFFOfContentView];
		
		// create file wrapper
	if((myFileWrapper = [[NSFileWrapper alloc] initRegularFileWithContents: tiffData]) == nil)
      return nil;
	[myFileWrapper setPreferredFilename: [NSString stringWithFormat: @"GLUT Picture No.%d.tiff", generationCounter++]];
	
		// create the text attachment
	if((myTextAttachment = [[NSTextAttachment alloc] initWithFileWrapper: myFileWrapper]) == nil) {
      [myFileWrapper release];
      return nil;
   }
	[myFileWrapper release];
	
		// create the attributed string
	if((myString = [NSAttributedString attributedStringWithAttachment: myTextAttachment]) == nil) {
      [myTextAttachment release];
      return nil;
   }
	[myTextAttachment release];
		
		// return the flattend data
	return [myString RTFDFromRange: NSMakeRange(0, [myString length]) documentAttributes: nil];
}

	/* Returns a data object containing the current contents of the receiving window */
- (NSData *)contentsAsDataOfType: (NSString *)pboardType
{
   NSData *	data = nil;
   
   if([pboardType isEqualToString: NSTIFFPboardType] == YES) {
		data = [self _dataWithTIFFOfContentView];
	} else if([pboardType isEqualToString: NSRTFDPboardType] == YES) {
		data = [self _dataWithRTFDOfContentView];
	}
	
	return data;
}


/////////////////////////////////////////////
#pragma mark -
#pragma mark Delegate 
#pragma mark -


- (BOOL)windowShouldClose: (id)sender
{
   GLUTView *		view = (GLUTView *) [self contentView];
   GLUTwmcloseCB	closeFunc = [view wmCloseCallback];
   
   /* Enable special behavior of glutDestroyWindow() while we're here */
   __glutInsideWindowShouldClose = YES;
   __glutShouldWindowClose = NO;
   __glutSetWindow(view);
   closeFunc();
   __glutInsideWindowShouldClose = NO;
   
   /* Only return with YES, if the application called glutDestroyWindow().
      Return NO otherwise. */
   return __glutShouldWindowClose;
}

	/* Update the window status of the receiver and all of it's sub windows. */
- (void)windowWillMiniaturize:(NSNotification *)notification
{
   GLUTView *	view = (GLUTView *) [self contentView];

   /* Miniaturizing a window with an OpenGL content view in it is a bit tricky,
      because the OpenGL graphics is drawn in its own surface which floats above
      the Quartz window and thus is not directly accessible to the latter.
      In order to get around this, we tell our GLUTView to copy its OpenGL pixels
      from its associated surface into its Quartz context. The copied pixels will
      finally end up in the window's backing store where they can be easily
      grabbed from by the window minaturization engine. */
   [view prepareForMiniaturization];
   _viewStorage = [[NSMutableSet alloc] init];
   [_viewStorage unionSet: [view coveredViews]];
   [_viewStorage addObject: view];
}

- (void)windowDidMiniaturize:(NSNotification *)notification
{
   [GLUTView evaluateVisibilityOfViews: _viewStorage];
   [_viewStorage release];
   _viewStorage = nil;
   [(GLUTView *) [self contentView] setShown: NO];
}

- (void)windowWillMove:(NSNotification *)notification
{
   GLUTView *	view = (GLUTView *) [self contentView];

   _viewStorage = [[NSMutableSet alloc] init];
   [_viewStorage unionSet: [view coveredViews]];
   [_viewStorage addObject: view];
}

- (void)windowDidMove:(NSNotification *)notification
{
   [_viewStorage unionSet: [(GLUTView *) [self contentView] coveredViews]];
   [GLUTView evaluateVisibilityOfViews: _viewStorage];
   [_viewStorage release];
   _viewStorage = nil;
}

- (void)orderWindow:(NSWindowOrderingMode)place relativeTo:(int)otherWin
{
   GLUTView *	view = (GLUTView *) [self contentView];

   if(view != nil) {
      NSMutableSet *	views = [NSMutableSet set];
      
      if(place == NSWindowOut) {
         [views unionSet: [view coveredViews]];
         [views addObject: view];
      }
  
      [view setShown: (place != NSWindowOut)];
      [super orderWindow: place relativeTo: otherWin];
      
      if(place != NSWindowOut) {
         [views unionSet: [view coveredViews]];
         [view recursiveCollectViewsIntoSet: views];
      }
      
      [GLUTView evaluateVisibilityOfViews: views];
   } else {
      [super orderWindow: place relativeTo: otherWin];
   }
}

@end
