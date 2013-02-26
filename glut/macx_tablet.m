
/* Copyright (c) Dietmar Planitzer, 1998, 2002 */

/* This program is freely distributable without licensing fees 
   and is provided without guarantee or warrantee expressed or 
   implied. This program is -not- in the public domain. */

#import "macx_glut.h"
#import "GLUTView.h"


/* CENTRY */
void APIENTRY glutTabletMotionFunc(void (*func)(int x, int y))
{
   GLUTAPI_DECLARATIONS_FAST
   GLUTAPI_BEGIN_FAST
	[__glutCurrentView setTabletMotionCallback: func];
   GLUTAPI_END_FAST
}

void APIENTRY glutTabletButtonFunc(void (*func)(int button, int state, int x, int y))
{
   GLUTAPI_DECLARATIONS_FAST
   GLUTAPI_BEGIN_FAST
	[__glutCurrentView setTabletButtonCallback: func];
   GLUTAPI_END_FAST
}
/* ENDCENTRY */
