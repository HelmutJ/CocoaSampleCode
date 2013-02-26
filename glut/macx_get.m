
/* Copyright (c) Dietmar Planitzer, 1998, 2002 */

/* This program is freely distributable without licensing fees 
   and is provided without guarantee or warrantee expressed or 
   implied. This program is -not- in the public domain. */

#import "macx_glut.h"
#import "GLUTMenu.h"
#import "GLUTView.h"


/* CENTRY */
int APIENTRY glutGet(GLenum param)
{
 	GLint			val = 0;
	int			ival = 0;
  	GLboolean	state = GL_FALSE;

   GLUTAPI_DECLARATIONS  	
   GLUTAPI_BEGIN
  	switch(param) {
  		case GLUT_INIT_WINDOW_X:
         ival = __glutInitX;
          break;
  		case GLUT_INIT_WINDOW_Y:
 			ival = __glutInitY;
          break;
  		case GLUT_INIT_WINDOW_WIDTH:
 			ival = __glutInitWidth;
          break;
  		case GLUT_INIT_WINDOW_HEIGHT:
 			ival = __glutInitHeight;
          break;
  		case GLUT_INIT_DISPLAY_MODE:
 			ival = __glutDisplayMode;
          break;
  		case GLUT_WINDOW_X:
 			ival = (int) [__glutCurrentView windowPosition].x;
          break;
  		case GLUT_WINDOW_Y:
 			ival = (int) [__glutCurrentView windowPosition].y;
          break;
  		case GLUT_WINDOW_WIDTH:
 			ival = (int) [__glutCurrentView windowSize].width;
          break;
  		case GLUT_WINDOW_HEIGHT:
 			ival = (int) [__glutCurrentView windowSize].height;
          break;
  		case GLUT_WINDOW_BUFFER_SIZE:
			{
				GLboolean	isIndexed = GL_FALSE;
				int			bpp = 0;
				
				glGetBooleanv(GL_INDEX_MODE, &isIndexed);
				if(isIndexed == GL_FALSE) {
					glGetIntegerv(GL_RED_BITS, &val);
					bpp = (int) val;
					glGetIntegerv(GL_GREEN_BITS, &val);
					bpp += (int) val;
					glGetIntegerv(GL_BLUE_BITS, &val);
					bpp += (int) val;
					glGetIntegerv(GL_ALPHA_BITS, &val);
					bpp += (int) val;
				} else {
					glGetIntegerv(GL_INDEX_BITS, &val);
  					bpp = (int) val;
  				}
  			
 				ival = bpp;
  			}
          break;
  		case GLUT_WINDOW_STENCIL_SIZE:
  			glGetIntegerv(GL_STENCIL_BITS, &val);
 			ival = (int) val;
          break;
  		case GLUT_WINDOW_DEPTH_SIZE:
  			glGetIntegerv(GL_DEPTH_BITS, &val);
 			ival = (int) val;
          break;
  		case GLUT_WINDOW_RED_SIZE:
  			glGetIntegerv(GL_RED_BITS, &val);
 			ival = (int) val;
          break;
  		case GLUT_WINDOW_GREEN_SIZE:
  			glGetIntegerv(GL_GREEN_BITS, &val);
 			ival = (int) val;
          break;
  		case GLUT_WINDOW_BLUE_SIZE:
  			glGetIntegerv(GL_BLUE_BITS, &val);
 			ival = (int) val;
          break;
  		case GLUT_WINDOW_ALPHA_SIZE:
  			glGetIntegerv(GL_ALPHA_BITS, &val);
 			ival = (int) val;
          break;
  		case GLUT_WINDOW_ACCUM_RED_SIZE:
  			glGetIntegerv(GL_ACCUM_RED_BITS, &val);
 			ival = (int) val;
          break;
  		case GLUT_WINDOW_ACCUM_GREEN_SIZE:
  			glGetIntegerv(GL_ACCUM_GREEN_BITS, &val);
 			ival = (int) val;
          break;
  		case GLUT_WINDOW_ACCUM_BLUE_SIZE:
  			glGetIntegerv(GL_ACCUM_BLUE_BITS, &val);
 			ival = (int) val;
          break;
  		case GLUT_WINDOW_ACCUM_ALPHA_SIZE:
  			glGetIntegerv(GL_ACCUM_ALPHA_BITS, &val);
 			ival = (int) val;
          break;
  		case GLUT_WINDOW_DOUBLEBUFFER:
  			glGetBooleanv(GL_DOUBLEBUFFER, &state);
 			ival = (int) state;
          break;
  		case GLUT_WINDOW_RGBA:
  			glGetBooleanv(GL_RGBA_MODE, &state);
 			ival = (int) state;
          break;
  		case GLUT_WINDOW_COLORMAP_SIZE:
 			ival = 0;
          break;
  		case GLUT_WINDOW_PARENT:
         ival = [__glutCurrentView parentWindowID];
          break;
  		case GLUT_WINDOW_NUM_CHILDREN:
 			ival = [__glutCurrentView numberOfChildrens];
          break;
  		case GLUT_WINDOW_NUM_SAMPLES:
           if(glutExtensionSupported("GL_ARB_multisample")) {
              glGetIntegerv(GL_SAMPLES, &val);
             ival = val;
           }
 			break;
  		case GLUT_WINDOW_STEREO:
  			glGetBooleanv(GL_STEREO, &state);
 			ival = (int) state;
          break;
  		case GLUT_WINDOW_CURSOR:
 			ival = [__glutCurrentView cursor];
          break;
  		case GLUT_SCREEN_WIDTH:
 			ival = __glutScreenWidth;
          break;
  		case GLUT_SCREEN_HEIGHT:
 			ival = __glutScreenHeight;
          break;
  		case GLUT_SCREEN_WIDTH_MM:
 			ival = (int) ((float) __glutScreenWidth / 3.53);
          break;
  		case GLUT_SCREEN_HEIGHT_MM:
 			ival = (int) ((float) __glutScreenHeight / 3.53);
          break;
  		case GLUT_MENU_NUM_ITEMS:
 			ival = [__glutGetMenu() numberOfItems];
          break;
  		case GLUT_DISPLAY_MODE_POSSIBLE:
          {
              BOOL	treatAsSingle;
             ival = (__glutDetermineWindowPixelFormat(&treatAsSingle, NO) != nil) ? 1 : 0;
           }
          break;
  		case GLUT_ELAPSED_TIME:
  			{
  				NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
 				ival = (int)((now * 1000.0) - (__glutStartupTime * 1000.0));
  			}
          break;
  		case GLUT_WINDOW_FORMAT_ID:
 			ival = 0;
          break;
  		default:
  			__glutWarning("invalid glutGet parameter: %d", param);
 			ival = -1;
          break;
  	}
   GLUTAPI_END
    
   return ival;
}
/* ENDCENTRY */
