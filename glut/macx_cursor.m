
/* Copyright (c) Dietmar Planitzer, 2002 */

/* This program is freely distributable without licensing fees 
   and is provided without guarantee or warrantee expressed or 
   implied. This program is -not- in the public domain. */

#import "macx_glut.h"
#import "GLUTView.h"


static NSMutableDictionary *	__glutCursorTable = nil;


static NSCursor *__glutMakeCursor(NSString *name, NSPoint hSpot)
{
   NSCursor *	cursor = nil;
   NSImage *	crsrImage = nil;
   NSString *	imagePath = [__glutGetFrameworkBundle() pathForResource: name ofType: @"tiff"];
   
   NSCParameterAssert(name != nil);
   
   /* Do we already know about a cursor named 'name' ? if so, then return it */
   if(__glutCursorTable && (cursor = [__glutCursorTable objectForKey: name]) != nil)
      return cursor;
	
   /* A cursor named 'name' doesn't exist yet, create it */
   if(nil != (crsrImage = [[NSImage alloc] initWithContentsOfFile: imagePath])) {		
      cursor = [[[NSCursor alloc]	initWithImage: crsrImage
                                    hotSpot: hSpot] autorelease];
      [crsrImage release];
      if(cursor) {
         if(__glutCursorTable == nil) {
            __glutCursorTable = [[NSMutableDictionary alloc] init];
            if(!__glutCursorTable) {
               __glutFatalError("out of memory");
            }
         }
         
         [__glutCursorTable setObject: cursor forKey: name];
         return cursor;
      }
   }
   /* Return something reasonable... */
   return [NSCursor arrowCursor];
}

NSCursor *__glutGetNativeCursor(int cid)
{
   NSCursor *	cursor = nil;
   switch(cid) {
         /* Basic arrows. */
      case GLUT_CURSOR_RIGHT_ARROW:
               cursor = __glutMakeCursor(@"rightArrowCursor", NSMakePoint(15, -1));
               break;
      case GLUT_CURSOR_LEFT_ARROW:
               cursor = [NSCursor arrowCursor];
               break;
         /* Symbolic cursor shapes. */
      case GLUT_CURSOR_INFO:
               cursor = __glutMakeCursor(@"fingerCursor", NSMakePoint(5, 1));
               break;
      case GLUT_CURSOR_DESTROY:
               cursor = __glutMakeCursor(@"destroyCursor", NSMakePoint(8, 8));
               break;
      case GLUT_CURSOR_HELP:
               cursor = __glutMakeCursor(@"helpCursor", NSMakePoint(8, 8));
               break;
      case GLUT_CURSOR_CYCLE:
               cursor = __glutMakeCursor(@"cycleCursor", NSMakePoint(8, 8));
               break;
      case GLUT_CURSOR_SPRAY:
               cursor = __glutMakeCursor(@"sprayCursor", NSMakePoint(8, 8));
               break;
      case GLUT_CURSOR_WAIT:
               cursor = __glutMakeCursor(@"waitCursor", NSMakePoint(0, 0));
               break;
      case GLUT_CURSOR_TEXT:
               cursor = [NSCursor IBeamCursor];
               break;
         /* Directional cursors. */
      case GLUT_CURSOR_UP_DOWN:
               cursor = __glutMakeCursor(@"upDownCursor", NSMakePoint(8, 8));
               break;
      case GLUT_CURSOR_LEFT_RIGHT:
               cursor = __glutMakeCursor(@"leftRightCursor", NSMakePoint(8, 8));
               break;
         /* Sizing cursors. */
      case GLUT_CURSOR_TOP_SIDE:
               cursor = __glutMakeCursor(@"topCursor", NSMakePoint(8, 8));
               break;
      case GLUT_CURSOR_BOTTOM_SIDE:
               cursor = __glutMakeCursor(@"bottomCursor", NSMakePoint(13, 8));
               break;
      case GLUT_CURSOR_LEFT_SIDE:
               cursor = __glutMakeCursor(@"leftCursor", NSMakePoint(8, 8));
               break;
      case GLUT_CURSOR_RIGHT_SIDE:
               cursor = __glutMakeCursor(@"rightCursor", NSMakePoint(8, 8));
               break;
      case GLUT_CURSOR_TOP_LEFT_CORNER:
               cursor = __glutMakeCursor(@"topleftCursor", NSMakePoint(8, 8));
               break;
      case GLUT_CURSOR_BOTTOM_LEFT_CORNER:
               cursor = __glutMakeCursor(@"bottomleftCursor", NSMakePoint(8, 8));
               break;
      case GLUT_CURSOR_TOP_RIGHT_CORNER:
               cursor = __glutMakeCursor(@"toprightCursor", NSMakePoint(8, 8));
               break;
      case GLUT_CURSOR_BOTTOM_RIGHT_CORNER:
               cursor = __glutMakeCursor(@"bottomrightCursor", NSMakePoint(8, 8));
               break;
         /* Inherit from parent window. */
      case GLUT_CURSOR_INHERIT:
               break;
         /* Blank cursor. */
      case GLUT_CURSOR_NONE:
               cursor = __glutMakeCursor(@"blankCursor", NSMakePoint(8, -8));
               break; 
         /* Fullscreen crosshair (if available). */
      case GLUT_CURSOR_FULL_CROSSHAIR:
      case GLUT_CURSOR_CROSSHAIR:
               cursor = __glutMakeCursor(@"crossCursor", NSMakePoint(8, 8));
               break;
   }
	
   return cursor;
}

/* CENTRY */
void APIENTRY glutSetCursor(int cursor)
{
   GLUTAPI_DECLARATIONS
   GLUTAPI_BEGIN
      [__glutCurrentView setCursor: cursor];
   GLUTAPI_END
}
/* ENDCENTRY */
