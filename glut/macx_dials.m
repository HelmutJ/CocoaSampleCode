
/* Copyright (c) Dietmar Planitzer, 1998, 2002 */

/* This program is freely distributable without licensing fees 
   and is provided without guarantee or warrantee expressed or 
   implied. This program is -not- in the public domain. */

#import "macx_glut.h"
#import "GLUTView.h"




void APIENTRY glutButtonBoxFunc(void (*func)(int button, int state))
{
   GLUTAPI_DECLARATIONS_FAST
   GLUTAPI_BEGIN_FAST
      [__glutCurrentView setButtonBoxCallback: func];
   GLUTAPI_END_FAST
}

void APIENTRY glutDialsFunc(void (*func)(int dial, int value))
{
   GLUTAPI_DECLARATIONS_FAST
   GLUTAPI_BEGIN_FAST
      [__glutCurrentView setDialCallback: func];
   GLUTAPI_END_FAST
}
