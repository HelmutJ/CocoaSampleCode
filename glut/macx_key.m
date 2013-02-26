
/* Copyright (c) Dietmar Planitzer, 1998, 2002 */

/* This program is freely distributable without licensing fees 
   and is provided without guarantee or warrantee expressed or 
   implied. This program is -not- in the public domain. */

#import "macx_glut.h"
#import "GLUTView.h"

#import <IOKit/hidsystem/event_status_driver.h>



/* CENTRY */
void APIENTRY glutKeyboardFunc(void (*func)(unsigned char key, int x, int y))
{
   GLUTAPI_DECLARATIONS_FAST
   GLUTAPI_BEGIN_FAST
	[__glutCurrentView setKeyDownCallback: func];
   GLUTAPI_END_FAST
}

void APIENTRY glutSpecialFunc(void (*func)(int key, int x, int y))
{
   GLUTAPI_DECLARATIONS_FAST
   GLUTAPI_BEGIN_FAST
	[__glutCurrentView setSpecialDownCallback: func];
   GLUTAPI_END_FAST
}

void APIENTRY glutKeyboardUpFunc(void (*func)(unsigned char key, int x, int y))
{
   GLUTAPI_DECLARATIONS_FAST
   GLUTAPI_BEGIN_FAST
	[__glutCurrentView setKeyUpCallback: func];
   GLUTAPI_END_FAST
}

void APIENTRY glutSpecialUpFunc(void (*func)(int key, int x, int y))
{
   GLUTAPI_DECLARATIONS_FAST
   GLUTAPI_BEGIN_FAST
	[__glutCurrentView setSpecialUpCallback: func];
   GLUTAPI_END_FAST
}

void APIENTRY glutIgnoreKeyRepeat(int ignore)
{
   GLUTAPI_DECLARATIONS_FAST
   GLUTAPI_BEGIN_FAST
	[__glutCurrentView setIgnoreKeyRepeats: (ignore != 0) ? YES : NO];
   GLUTAPI_END_FAST
}
/* ENDCENTRY */

static double	gDefaultKeyRepeatThreshold = -1;
void __glutResetKeyboard(void)
{
   if(gDefaultKeyRepeatThreshold != -1) {
      NXEventHandle	eventHandle = NXOpenEventStatus();
      
      if(eventHandle) {
         NXSetKeyRepeatThreshold(eventHandle, gDefaultKeyRepeatThreshold);
         NXCloseEventStatus(eventHandle);
      }
   }
}

int __glutGetDeviceKeyRepeat(void)
{
   NXEventHandle	eventHandle = NXOpenEventStatus();
   int				ival = GLUT_KEY_REPEAT_DEFAULT;
   
   if(eventHandle) {
      if(NXKeyRepeatThreshold(eventHandle) > 1000.0)
         ival = GLUT_KEY_REPEAT_OFF;
      else
         ival = GLUT_KEY_REPEAT_ON;
      NXCloseEventStatus(eventHandle);
   }
   
   return ival;
}

/* CENTRY */
void APIENTRY glutSetKeyRepeat(int repeatMode)
{
	NXEventHandle	eventHandle;
   double			threshold;
   
   if(gDefaultKeyRepeatThreshold == -1) {
      // remember current system key repeat threshold
      eventHandle = NXOpenEventStatus();
      if(eventHandle) {
         gDefaultKeyRepeatThreshold = NXKeyRepeatThreshold(eventHandle);
         NXCloseEventStatus(eventHandle);
      }
   }
   
   eventHandle = NXOpenEventStatus();
   if(eventHandle) {
      switch(repeatMode) {
         case GLUT_KEY_REPEAT_OFF:
                  threshold = 4500.0;
                  break;
                  
         case GLUT_KEY_REPEAT_ON:
                  threshold = (gDefaultKeyRepeatThreshold < 1000.0) ? gDefaultKeyRepeatThreshold : 0.03;
                  break;
                  
         case GLUT_KEY_REPEAT_DEFAULT:
                  threshold = gDefaultKeyRepeatThreshold;
                  break;
                  
         default:
                  __glutWarning("invalid glutSetKeyRepeat parameter: %d", repeatMode);
                  NXCloseEventStatus(eventHandle);
                  return;
      }
      NXSetKeyRepeatThreshold(eventHandle, threshold);
      NXCloseEventStatus(eventHandle);
   }
}
/* ENDCENTRY */
