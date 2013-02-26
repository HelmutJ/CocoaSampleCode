
/* Copyright (c) Dietmar Planitzer, 1998, 2002 - 2003 */

/* This program is freely distributable without licensing fees 
   and is provided without guarantee or warrantee expressed or 
   implied. This program is -not- in the public domain. */


#import "macx_glut.h"

@class GLUTView;


@interface GLUTWindow : NSWindow
{
@private
   
   GLUTWindow *	_nextFullscreenWindow;	/* weak ref */
   NSString *		_imagePath;
   NSMutableSet *	_viewStorage;
   int				_enabledMouseMovedEvents;
   BOOL				_isFullscreen;
}

+ (id)windowByMorphingWindow: (GLUTWindow *)aWindow operation: (int)op arguments: (NSDictionary *)dict;


- (id)initWithContentRect: (NSRect)rect
      pixelFormat: (NSOpenGLPixelFormat *)pixelFormat
      windowID: (int)winid
      gameMode: (BOOL)gameMode
      fullscreenStereo: (BOOL)pfStereo
      treatAsSingle: (BOOL)treatAsSingle;

- (void)enableMouseMovedEvents;
- (void)disableMouseMovedEvents;

- (BOOL)isFullscreen;
- (BOOL)isAffectedByFullscreenWindow;

- (IBAction)save: (id)sender;
- (IBAction)saveAs: (id)sender;
- (IBAction)copy: (id)sender;

- (NSData *)contentsAsDataOfType: (NSString *)pboardType;

@end

// Window morphing operations
enum {
   kGLUTMorphOperationFullscreen,
   kGLUTMorphOperationRegular
};

// Windoww morphing operands
extern NSString *GLUTWindowFrame;   // kGLUTMorphOperationRegular
