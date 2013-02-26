
/* Copyright (c) Mark J. Kilgard, 1994. */
/* Copyright (c) Dietmar Planitzer, 1998, 2002 */

/* This program is freely distributable without licensing fees 
   and is provided without guarantee or warrantee expressed or 
   implied. This program is -not- in the public domain. */

#import <dlfcn.h>
#import <stdlib.h>
#import <string.h>

#import "macx_glut.h"
#import "GLUTApplication.h"


void *__glutGetGLProcAddress(const char *name)
{
   static void *glHandle   = NULL,
               *glutHandle = NULL;
   void **handlePtr;
   void *addr = NULL;

   if(name[0] == 'g' &&
      name[1] == 'l')
   {
      if(name[2] == 'u' &&
         name[3] == 't')
      {
         // This is a 'glut*' function
         handlePtr = &glutHandle;
         if( NULL == *handlePtr )
            *handlePtr = dlopen("/System/Library/Frameworks/GLUT.framework/GLUT", RTLD_LAZY | RTLD_GLOBAL);
      } else {
         // This is a 'gl*' function
         handlePtr = &glHandle;
         if( NULL == *handlePtr )
            *handlePtr = dlopen("/System/Library/Frameworks/OpenGL.framework/OpenGL", RTLD_LAZY | RTLD_GLOBAL);
	  }

      if( NULL != *handlePtr )
         addr = dlsym( *handlePtr, name );
   }

   return addr;
}

/** 
 * Returns YES if the current application is a packaged app. Otherwise
 * NO is returned (i.e. an unpackaged CLI/tool style app).
 */
BOOL __glutIsPackagedApp(void)
{
   NSDictionary *	dict = [[NSBundle mainBundle] infoDictionary];
   
   if(dict) {
      return ([dict objectForKey: @"CFBundlePackageType"] != nil);
   } else {
      return NO;
   }
}

/**
 * Returns the framework's bundle.
 */
NSBundle *__glutGetFrameworkBundle(void)
{
   static NSBundle *	__glutFrameworkBundle = nil;
   
   if(!__glutFrameworkBundle) {
      __glutFrameworkBundle = [[NSBundle bundleForClass: [GLUTApplication class]] retain];
      if(!__glutFrameworkBundle) {
         __glutFatalError("Can't find GLUT.framework");
      }
   }
   return __glutFrameworkBundle;
}

BOOL __glutWriteDataToFile(NSData *data, NSString *path, OSType hfsType)
{
	if([data writeToFile: path atomically: YES] == YES) {
      NSFileManager *			fileManager = [NSFileManager defaultManager];
      NSMutableDictionary *	attribs = [NSMutableDictionary dictionaryWithCapacity: 1];
      
      [attribs setObject: [NSNumber numberWithUnsignedLong: hfsType] forKey: NSFileHFSTypeCode];
      [fileManager changeFileAttributes: attribs atPath: path];
      return YES;
   }
   return NO;
}

#ifdef __GLUT_LOG_PIXELFORMAT
void __glutDumpPixelFormatAttributes(NSOpenGLPixelFormatAttribute *pfa)
{
   int	i = 0;
   
   while(pfa[i] != 0) {
      switch(pfa[i]) {
         case NSOpenGLPFAAllRenderers:
               NSLog(@"NSOpenGLPFAAllRenderers");
               break;
         case NSOpenGLPFADoubleBuffer:
               NSLog(@"NSOpenGLPFADoubleBuffer");
               break;
         case NSOpenGLPFAStereo:
               NSLog(@"NSOpenGLPFAStereo");
               break;
         case NSOpenGLPFAAuxBuffers:
               NSLog(@"NSOpenGLPFAAuxBuffers %d", pfa[++i]);
               break;
         case NSOpenGLPFAColorSize:
               NSLog(@"NSOpenGLPFAColorSize %d", pfa[++i]);
               break;
         case NSOpenGLPFAAlphaSize:
               NSLog(@"NSOpenGLPFAAlphaSize %d", pfa[++i]);
               break;
         case NSOpenGLPFADepthSize:
               NSLog(@"NSOpenGLPFADepthSize %d", pfa[++i]);
               break;
         case NSOpenGLPFAStencilSize:
               NSLog(@"NSOpenGLPFAStencilSize %d", pfa[++i]);
               break;
         case NSOpenGLPFAAccumSize:
               NSLog(@"NSOpenGLPFAAccumSize %d", pfa[++i]);
               break;
         case NSOpenGLPFAMinimumPolicy:
               NSLog(@"NSOpenGLPFAMinimumPolicy");
               break;
         case NSOpenGLPFAMaximumPolicy:
               NSLog(@"NSOpenGLPFAMaximumPolicy");
               break;
         case NSOpenGLPFAOffScreen:
               NSLog(@"NSOpenGLPFAOffScreen");
               break;
         case NSOpenGLPFAFullScreen:
               NSLog(@"NSOpenGLPFAFullScreen");
               break;
         case NSOpenGLPFARendererID:
               NSLog(@"NSOpenGLPFARendererID %d", pfa[++i]);
               break;
         case NSOpenGLPFASingleRenderer:
               NSLog(@"NSOpenGLPFASingleRenderer");
               break;
         case NSOpenGLPFANoRecovery:
               NSLog(@"NSOpenGLPFANoRecovery");
               break;
         case NSOpenGLPFAAccelerated:
               NSLog(@"NSOpenGLPFAAccelerated");
               break;
         case NSOpenGLPFAClosestPolicy:
               NSLog(@"NSOpenGLPFAClosestPolicy");
               break;
         case NSOpenGLPFARobust:
               NSLog(@"NSOpenGLPFARobust");
               break;
         case NSOpenGLPFABackingStore:
               NSLog(@"NSOpenGLPFABackingStore");
               break;
         case NSOpenGLPFAMPSafe:
               NSLog(@"NSOpenGLPFAMPSafe");
               break;
         case NSOpenGLPFAWindow:
               NSLog(@"NSOpenGLPFAWindow");
               break;
         case NSOpenGLPFAMultiScreen:
               NSLog(@"NSOpenGLPFAMultiScreen");
               break;
         case NSOpenGLPFACompliant:
               NSLog(@"NSOpenGLPFACompliant");
               break;
         case NSOpenGLPFAScreenMask:
               NSLog(@"NSOpenGLPFAScreenMask %d", pfa[++i]);
               break;
         case 55:
               NSLog(@"NSOpenGLPFASampleBuffers %d", pfa[++i]);
               break;
         case 56:
               NSLog(@"NSOpenGLPFASamples %d", pfa[++i]);
               break;
         default:
               NSLog(@"<unknown> <%d>", pfa[i]);
               break;
      }
      i++;
   }
}
#endif

#if __GLUT_LOG_WORK_EVENTS
void __glutPrintWorkMask(GLUTWorkEvent * event, int winid, int eventMask)
{
	int workMask = event->workMask;
	
	char str [255] = "";
	if(workMask & GLUT_MAP_WORK) {
		sprintf (str, "%s GLUT_MAP_WORK", str);
		if(event->desiredMapState == kWithdrawnState)
			sprintf (str, "%s  (kWithdrawnState)", str);
		if(event->desiredMapState == kNormalState)
			sprintf (str, "%s (kNormalState)", str);
		if(event->desiredMapState == kIconicState)
			sprintf (str, "%s (kIconicState)", str);
		if(event->desiredMapState == kGameModeState)
			sprintf (str, "%s (kGameModeState)", str);
	}
	if(workMask & GLUT_REDISPLAY_WORK)
	sprintf (str, "%s GLUT_REDISPLAY_WORK", str);
	
	if(workMask & GLUT_CONFIGURE_WORK) {
		sprintf (str, "%s GLUT_CONFIGURE_WORK", str);
		if(event->desiredConfMask & CWX)
			sprintf (str, "%s  (CWX)", str);
		if(event->desiredConfMask & CWY)
			sprintf (str, "%s (CWY)", str);
		if(event->desiredConfMask & CWWidth)
			sprintf (str, "%s (CWWidth)", str);
		if(event->desiredConfMask & CWHeight)
			sprintf (str, "%s (CWHeight)", str);
		if(event->desiredConfMask & CWStackMode) {
			sprintf (str, "%s (CWStackMode:", str);
			if(event->desiredStack == kAbove)
				sprintf (str, "%s kAbove)", str);
			else if(event->desiredStack == kBelow)
				sprintf (str, "%s kBelow)", str);
		}
		if(event->desiredConfMask & CWFullScreen)
			sprintf (str, "%s (CWFullScreen)", str);
	}
	
	if(workMask & GLUT_EVENT_MASK_WORK) {
		sprintf (str, "%s GLUT_EVENT_MASK_WORK", str);
		if(eventMask & kPassiveMotionEvents)
			sprintf (str, "%s (kPassiveMotionEvents)", str);
		if(eventMask & kEntryEvents)
			sprintf (str, "%s (kEntryEvents)", str);
	}
	
	if(workMask & GLUT_COLORMAP_WORK) 
		sprintf (str, "%s GLUT_COLORMAP_WORK", str);

	if(workMask & GLUT_DEVICE_MASK_WORK) 
		sprintf (str, "%s GLUT_DEVICE_MASK_WORK", str);

	if(workMask & GLUT_DEBUG_WORK) 
		sprintf (str, "%s GLUT_DEBUG_WORK", str);

	if(workMask & GLUT_DUMMY_WORK) 
		sprintf (str, "%s GLUT_DUMMY_WORK", str);

	if(workMask & GLUT_OVERLAY_REDISPLAY_WORK) 
		sprintf (str, "%s GLUT_OVERLAY_REDISPLAY_WORK", str);

	printf("    >> Work Event for Window %d: %s <<\n", winid, str);
}
#endif

#if __GLUT_LOG_VISIBILITY
void __glutPrintVisibilityState(int state, int winid)
{
   char *	str = NULL;
   
   switch(state) {
      case GLUT_FULLY_RETAINED:
            str = "GLUT_FULLY_RETAINED";
            break;
      case GLUT_PARTIALLY_RETAINED:
            str = "GLUT_PARTIALLY_RETAINED";
            break;
      case GLUT_FULLY_COVERED:
            str = "GLUT_FULLY_COVERED";
            break;
      case GLUT_HIDDEN:
            str = "GLUT_HIDDEN";
            break;
   }
   printf("      (Window %d State: %s)\n", winid, str);
}
#endif


/////////////////////////////////


/* CENTRY */
void APIENTRY glutReportErrors(void)
{
	GLenum	error;
	
	while((error = glGetError()) != GL_NO_ERROR)
		__glutWarning("GL error: %s", gluErrorString(error));
}
/* ENDCENTRY */

/* strdup is actually not a standard ANSI C or POSIX routine
   so implement a private one for GLUT.  OpenVMS does not have a
   strdup; Linux's standard libc doesn't declare strdup by default
   (unless BSD or SVID interfaces are requested). */
char *__glutStrdup(const char *string)
{
	char *copy;
	
	copy = malloc(strlen(string) + 1);
	if(copy == NULL)
		return NULL;
	strcpy(copy, string);	
	return copy;
}

void __glutInitList(GLUTList *list)
{
   list->head.pred = NULL;
   list->head.succ = &list->tail;
   list->tail.pred = &list->head;
   list->tail.succ = NULL;
}

/* Add node at end of list */
void __glutAddTailNode(GLUTList *list, GLUTNode *node)
{
   GLUTNode *	tail = &list->tail;
   
   (tail->pred)->succ = node;
   node->succ = &list->tail;
   node->pred = tail->pred;
   tail->pred = node;
}

/* Add node at list beginning */
void __glutAddHeadNode(GLUTList *list, GLUTNode *node)
{
   GLUTNode *	head = &list->head;
   
   (head->succ)->pred = node;
   node->pred = &list->head;
   node->succ = head->succ;
   head->succ = node;
}

/* Remove given node from list */
void __glutRemoveNode(GLUTList *list, GLUTNode *node)
{
   (node->succ)->pred = node->pred;
   (node->pred)->succ = node->succ;
}

#define GLUT_MAX_FORMAT_LENGTH	1024
void __glutWarning(char *format,...)
{
	va_list	args;
   char		fmtresult[GLUT_MAX_FORMAT_LENGTH];
	
	va_start(args, format);
		vsprintf(fmtresult, format, args);
	va_end(args);
	
	NSLog([NSString stringWithFormat: @"GLUT Warning: %s\n", fmtresult]);
}

void __glutFatalError(char *format,...) /* will exit */
{
	va_list	args;
   char		fmtresult[GLUT_MAX_FORMAT_LENGTH];
	
	va_start(args, format);
		vsprintf(fmtresult, format, args);
	va_end(args);
	
	NSLog([NSString stringWithFormat: @"GLUT Fatal Error: %s\n", fmtresult]);
	exit(1);
}

void __glutFatalUsage(char *format,...) /* will exit */
{
	va_list	args;
   char		fmtresult[GLUT_MAX_FORMAT_LENGTH];
	
	va_start(args, format);
		vsprintf(fmtresult, format, args);
	va_end(args);
	
	NSLog([NSString stringWithFormat: @"GLUT Fatal API Usage: %s\n", fmtresult]);
	abort();
}
