//
// File:       macx_fortran.m
//
//
// Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc. ("Apple")
//             in consideration of your agreement to the following terms, and your use,
//             installation, modification or redistribution of this Apple software
//             constitutes acceptance of these terms.  If you do not agree with these
//             terms, please do not use, install, modify or redistribute this Apple
//             software.
//
//             In consideration of your agreement to abide by the following terms, and
//             subject to these terms, Apple grants you a personal, non - exclusive
//             license, under Apple's copyrights in this original Apple software ( the
//             "Apple Software" ), to use, reproduce, modify and redistribute the Apple
//             Software, with or without modifications, in source and / or binary forms;
//             provided that if you redistribute the Apple Software in its entirety and
//             without modifications, you must retain this notice and the following text
//             and disclaimers in all such redistributions of the Apple Software. Neither
//             the name, trademarks, service marks or logos of Apple Inc. may be used to
//             endorse or promote products derived from the Apple Software without specific
//             prior written permission from Apple.  Except as expressly stated in this
//             notice, no other rights or licenses, express or implied, are granted by
//             Apple herein, including but not limited to any patent rights that may be
//             infringed by your derivative works or by other works in which the Apple
//             Software may be incorporated.
//
//             The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
//             WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
//             WARRANTIES OF NON - INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A
//             PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION
//             ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
//
//             IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
//             CONSEQUENTIAL DAMAGES ( INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//             SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//             INTERRUPTION ) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION
//             AND / OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER
//             UNDER THEORY OF CONTRACT, TORT ( INCLUDING NEGLIGENCE ), STRICT LIABILITY OR
//             OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// Copyright ( C ) 2002-2008 Apple Inc. All Rights Reserved.
//

#import "glutf90.h"
#import "macx_glut.h"

#import "GLUTMenu.h"
#import "GLUTApplication.h"
#import "GLUTView.h"


void* APIENTRY __glutGetFCB(int which)
{
	void * retVal = nil;
   GLUTAPI_DECLARATIONS_FAST
	GLUTAPI_BEGIN_FAST
		switch (which) {
			case GLUT_FCB_OVERLAY_DISPLAY:
				/* not implemented currently */
				break;
			case GLUT_FCB_SELECT:
				retVal = (void *) [__glutCurrentMenu getFortranCallback];
				break;
			case GLUT_FCB_TIMER:
				/* will only return the callback for the most recently instantiated timer */
            retVal = (void *) (__glutMostRecentTimer) ? __glutMostRecentTimer->fFunc : NULL;
				break;
#if 0
			case GLUT_FCB_MENU_STATUS: /* enumerant does not exist */
				retVal = (void *) __fglutMenuStatusFunc;
				break;
			case GLUT_FCB_IDLE: /* enumerant does not exist */
				retVal = (void *) __fglutIdleFunc;
				break;
#endif
			default:
				retVal = [__glutCurrentView getFortranCallback:which];
				break;
		}
	GLUTAPI_END_FAST
	return retVal;
}

void APIENTRY __glutSetFCB(int which, void *func)
{
    GLUTAPI_DECLARATIONS_FAST
	GLUTAPI_BEGIN_FAST
		switch (which) {
			case GLUT_FCB_OVERLAY_DISPLAY:
				break; /* not implemented currently */
			case GLUT_FCB_SELECT:
				[__glutCurrentMenu setFortranCallback: (GLUTselectFCB)func];
				break;
			case GLUT_FCB_TIMER:
				/* will only set the callback for the most recently instantiated timer */
            if(__glutMostRecentTimer)
               __glutMostRecentTimer->fFunc = (GLUTtimerFCB) func;
				break;
#if 0  /* enumerants do not exist */
			case GLUT_FCB_MENU_STATUS:
				__fglutMenuStatusFunc = (GLUTmenuStatusFCB)func;
				break;
			case GLUT_FCB_IDLE:
				__fglutIdleFunc = (GLUTidleFCB)func;
				break;
#endif
			default:
				[__glutCurrentView setFortranCallback:which callback:func];
				break;
		}
	GLUTAPI_END_FAST
}
