
/* Copyright (c) Dietmar Planitzer, 1998. */

/* This program is freely distributable without licensing fees
   and is provided without guarantee or warrantee expressed or
   implied. This program is -not- in the public domain. */

#import "GLUTClipboardController.h"
#import "macx_glut.h"
#import "GLUTApplication.h"

#if defined(__LP64__)
#import <QTKit/QTMovie.h>
#import <QTKit/QTMovieView.h>
#endif // #if defined(__LP64__)


@interface GLUTUnknownView : NSView
- (void)drawRect: (NSRect)rect;
@end

@implementation GLUTUnknownView

- (void)drawRect: (NSRect)rect
{
   [[NSColor clearColor] set];
   NSRectFill(rect);
}

@end


/////////////////////////////////////////////
#pragma mark -
#pragma mark Pasteboard Controller
#pragma mark -


@implementation GLUTClipboardController

- (id)init
{
   if((self = [self initWithWindowNibName: @"GLUTClipboard"]) != nil) {
      [self setWindowFrameAutosaveName: @""];
      [self setShouldCascadeWindows: NO];
      _lastChangeCount	= 0;
      _firstTime			= YES;
      return self;
   }
	return nil;
}

- (void)dealloc
{
   if(_updateTimer) {
      [_updateTimer invalidate];
      [_updateTimer release];
   }
   [super dealloc];
}

- (void)finalize
{
   if(_updateTimer) {
      [_updateTimer invalidate];
   }
   [super finalize];
}

- (void)_installAutoupdateTimer
{
   _updateTimer = [[NSTimer	scheduledTimerWithTimeInterval: 0.5
                              target: self
                              selector: @selector(_checkPasteboard)
                              userInfo: nil
                              repeats: YES] retain];
}

- (void)_clearAutoupdateTimer
{
   [_updateTimer invalidate];
   [_updateTimer release];
   _updateTimer = nil;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    [[self window] setDelegate: self];
}

	/* ******* Actions ******** */
- (IBAction)toggleWindow: (id)sender
{
	NSWindow *	window = [self window];
	
	if(![self isClipboardWindowVisible]) {
			/* if Pboard contents changed, then update our document view */
		if(_firstTime || (_lastChangeCount != [[NSPasteboard generalPasteboard] changeCount])) {
			[self updateClipboardWindow];
			_firstTime = NO;
		}
		
      /* Install the auto-update timer */
      [self _installAutoupdateTimer];
		[window center];
		[super showWindow: sender];
	} else {
		[window performClose: nil];
	}
}

- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
	if([self isClipboardWindowVisible]) {
		[anItem setTitle: NSLocalizedStringFromTableInBundle(@"Hide Clipboard", @"GLUTUI",
                              __glutGetFrameworkBundle(),
                              @"Hide Clipboard")];
	} else {
		[anItem setTitle: NSLocalizedStringFromTableInBundle(@"Show Clipboard", @"GLUTUI",
                              __glutGetFrameworkBundle(),
                              @"Show Clipboard")];
   }
   
	return YES;
}

- (void)_checkPasteboard
{
   if(_lastChangeCount != [[NSPasteboard generalPasteboard] changeCount])
      [self updateClipboardWindow];
}

- (void)windowWillClose:(NSNotification *)notification
{
   [self _clearAutoupdateTimer];
}

- (void)windowWillMiniaturize:(NSNotification *)notification
{
   [self _clearAutoupdateTimer];
}

- (void)windowDidDeminiaturize:(NSNotification *)notification
{
   [self _installAutoupdateTimer];
}


	/* ******* UI ******* */
- (BOOL)isClipboardWindowVisible
{
	if([self isWindowLoaded]) {
		return ([self window] && [[self window] isVisible]);
	} else {
		return NO;
   }
}

/* Creates and returns an autoreleased view representing the current
   contents on the pasteboard. */
- (void)_getTextView: (NSView **)aTextView description: (NSString **)aDesc
            fromPasteboard: (NSPasteboard *)pboard type: (NSString *)type
{
   NSTextView *	myTextView = [[[NSTextView alloc] initWithFrame: NSMakeRect(0.0, 0.0, 1.0, 1.0)] autorelease];

		[myTextView setHorizontallyResizable: YES];
		[myTextView setVerticallyResizable: YES];
		[myTextView setImportsGraphics: YES];
		[myTextView selectAll: nil];
		[myTextView paste: nil];
		[myTextView setEditable: NO];
		[myTextView setSelectable: NO];
		[myTextView setUsesFontPanel: NO];
		
   *aTextView = myTextView;
   if([type isEqualToString: NSRTFDPboardType] ||
      [type isEqualToString: NSRTFPboardType] ||
      [type isEqualToString: NSHTMLPboardType]) {
         /* RTFD, RTF */
      *aDesc = NSLocalizedStringFromTableInBundle(@"Rich Text", @"GLUTUI",
                              __glutGetFrameworkBundle(),
                              @"Rich Text");
   } else {
         /* Plain text */
      *aDesc = NSLocalizedStringFromTableInBundle(@"Plain Text", @"GLUTUI",
                              __glutGetFrameworkBundle(),
                              @"Plain Text");
   }
}

- (void)_getImageView: (NSView **)anImageView description: (NSString **)aDesc
            fromPasteboard: (NSPasteboard *)pboard type: (NSString *)type
{
   NSImage *		myImage = [[[NSImage alloc] initWithPasteboard: pboard] autorelease];
		NSSize			imageSize = [myImage size];
		NSImageView *	myImageView = nil;
		
   myImageView = [[[NSImageView alloc] initWithFrame: NSMakeRect(0.0, 0.0, imageSize.width, imageSize.height)] autorelease];
		
		[myImageView setImage: myImage];
		[myImageView setEditable: NO];
		[myImageView setImageAlignment: NSImageAlignCenter];
		
   *anImageView = myImageView;
   *aDesc = [NSString stringWithFormat: NSLocalizedStringFromTableInBundle(@"\"%@\" image", @"GLUTUI",
                              __glutGetFrameworkBundle(),
                              @"\"%@\" image"), type];
}

- (void)_getMovieView: (NSView **)aMovieView description: (NSString **)aDesc
            fromPasteboard: (NSPasteboard *)pboard type: (NSString *)type
{
#if defined(__LP64__)
	QTMovie			*myMovie	= [[[QTMovie alloc] movieWithPasteboard: pboard error: nil] autorelease];
	QTMovieView		*myMovieView = nil;

	myMovieView = [[[QTMovieView alloc] initWithFrame: NSMakeRect(0.0, 0.0, 10.0, 10.0)] autorelease];
   
	[myMovieView setMovie: myMovie];
	[myMovieView setEditable: NO];
#else
   NSMovie *		myMovie = [[[NSMovie alloc] initWithPasteboard: pboard] autorelease];
   NSMovieView *	myMovieView = nil;
   
   myMovieView = [[[NSMovieView alloc] initWithFrame: NSMakeRect(0.0, 0.0, 10.0, 10.0)] autorelease];
   
   [myMovieView setMovie: myMovie];
   [myMovieView setEditable: NO];
#endif // #if defined(__LP64__)
   
	*aMovieView = myMovieView;

	*aDesc = NSLocalizedStringFromTableInBundle(@"Movie", @"GLUTUI",
                              __glutGetFrameworkBundle(),
                              @"Movie");
}

- (void)_getUnknownView: (NSView **)aView description: (NSString **)aDesc
            fromPasteboard: (NSPasteboard *)pboard type: (NSString *)type
{
   GLUTUnknownView *	myView = [[[GLUTUnknownView alloc] initWithFrame: NSMakeRect(0.0, 0.0, 10.0, 10.0)] autorelease];
   
   *aView = myView;
   *aDesc = NSLocalizedStringFromTableInBundle(@"Unknown contents", @"GLUTUI",
                              __glutGetFrameworkBundle(),
                              @"Unknown contents");
}

- (void)updateClipboardWindow
{
   NSPasteboard *	pboard = [NSPasteboard generalPasteboard];
   NSString *		type = nil;
   NSString *		pboardDesc = nil;
   NSView *			pboardView = nil;
	NSPoint			pinPoint = NSZeroPoint;
   
   _lastChangeCount = [pboard changeCount];
   
      /* Knock, knock, text there ? */
   type = [pboard availableTypeFromArray: [NSAttributedString textPasteboardTypes]];
   if(type) {
      [self _getTextView: &pboardView description: &pboardDesc fromPasteboard: pboard type: type];
   }

   if(pboardView == nil) {
         /* Knock, knock, QT movie there ? */
#if defined(__LP64__)
      type = [pboard availableTypeFromArray: [QTMovie movieUnfilteredPasteboardTypes]];
#else 
      type = [pboard availableTypeFromArray: [NSMovie movieUnfilteredPasteboardTypes]];
#endif // #if defined(__LP64__)

      if(type) {
         [self _getMovieView: &pboardView description: &pboardDesc fromPasteboard: pboard type: type];
      }
   }
   
   if(pboardView == nil) {
         /* Knock, knock, image there ? */
      type = [pboard availableTypeFromArray: [NSImage imagePasteboardTypes]];
      if(type) {
         [self _getImageView: &pboardView description: &pboardDesc fromPasteboard: pboard type: type];
         pinPoint = NSMakePoint(0.0, NSHeight([pboardView bounds]));
      }
   }
	   
   if(pboardView == nil) {
		/* Knock, knock, stranger there ? */
	if(type) {
         [self _getUnknownView: &pboardView description: &pboardDesc fromPasteboard: pboard type: type];
      } else {
		/* there is nothing on the pasteboard */
         [self _getUnknownView: &pboardView description: &pboardDesc fromPasteboard: pboard type: type];
         pboardDesc = NSLocalizedStringFromTableInBundle(@"Empty", @"GLUTUI",
                              __glutGetFrameworkBundle(),
                              @"Empty");
      }
   }
   
   /* Update window contents */
   [_scrollView setDocumentView: pboardView];
   [pboardView scrollPoint: pinPoint];
   [_infoText setStringValue: [NSString stringWithFormat: NSLocalizedStringFromTableInBundle(@"Clipboard contents: %@.",
                              @"GLUTUI",
                              __glutGetFrameworkBundle(),
                              @"Clipboard contents: %@."), pboardDesc]];
}

@end
