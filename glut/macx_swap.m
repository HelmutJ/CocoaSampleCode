
/* Copyright (c) Mark J. Kilgard, 1994, 1997.  */

/* This program is freely distributable without licensing fees
   and is provided without guarantee or warrantee expressed or
   implied. This program is -not- in the public domain. */

#import "macx_glut.h"
#import "GLUTView.h"

GLint __glutFPS = 0;
static GLint __glutSwapCount = 0;
static GLint __glutSwapTime = 0;


/* CENTRY */
void APIENTRY glutSwapBuffers(void)
{
   if([__glutCurrentView isTreatAsSingle]) {
      /* Pretend the double buffered window is single buffered,
         so treat glutSwapBuffers as a no-op.
         Well, actually flush any graphic commands queued by
         the hardware accelerator or we won't see anything in
         the GLUT window... */
      glFlush();
      return;
   }

   SWAP_BUFFERS_WINDOW(__glutCurrentView);
   
   if (__glutFPS) {
      GLint t = glutGet(GLUT_ELAPSED_TIME);
      
      __glutSwapCount++;
      if (__glutSwapTime == 0)
         __glutSwapTime = t;
      else if (t - __glutSwapTime > __glutFPS) {
         float currTime = 0.001 * (t - __glutSwapTime);
         float fps = (float) __glutSwapCount / currTime;
         
         fprintf(stderr, "GLUT: %d frames in %.2f seconds = %.2f FPS\n",
                  (int) __glutSwapCount, currTime, fps);
         __glutSwapTime = t;
         __glutSwapCount = 0;
      }
   }
}
/* ENDCENTRY */
