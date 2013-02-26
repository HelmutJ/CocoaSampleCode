
/* Copyright (c) Dietmar Planitzer, 2002 */

/* This program is freely distributable without licensing fees
   and is provided without guarantee or warrantee expressed or
   implied. This program is -not- in the public domain. */

#import "macx_glut.h"
#import "GLUTView.h"


/* CENTRY */
void APIENTRY glutWarpPointer(int x, int y)
{
   NSPoint	mouseLoc = NSMakePoint(x, y);
   
   GLUTAPI_DECLARATIONS
   GLUTAPI_BEGIN
   if(__glutCurrentView) {
      mouseLoc = [__glutCurrentView convertPoint: mouseLoc toView: nil];
      mouseLoc = [[__glutCurrentView window] convertBaseToScreen: mouseLoc];
   }
   mouseLoc.y = __glutScreenHeight - mouseLoc.y;
   
   /* Use CGPostMouseEvent() because we're supposed to generate
      mouse events (X Window's XWarpPointer() does this) */
   CGPostMouseEvent(CGPointMake(mouseLoc.x, mouseLoc.y), TRUE, 1, FALSE, 0);
   GLUTAPI_END
}
/* ENDCENTRY */
