
/* Copyright (c) Dietmar Planitzer, 1998, 2002 */

/* This program is freely distributable without licensing fees 
   and is provided without guarantee or warrantee expressed or 
   implied. This program is -not- in the public domain. */

#import "macx_glut.h"
#import "GLUTMenu.h"
#import "GLUTApplication.h"
#import "GLUTView.h"
#import "GLUTWindow.h"


GLUTView *           __glutMenuWindow = nil;			// Window while menu is active
GLUTMenu *           __glutMappedMenu = nil;
GLUTmenuStatusCB     __glutMenuStatusFunc = NULL;
GLUTmenuStatusFCB	   __fglutMenuStatusFunc = NULL; /* fortran callback */
GLUTMenu *			   __glutCurrentMenu = nil;
static GLUTMenu **   __glutMenuList = NULL;
static int           __glutMenuListSize = 0;



void __glutSetMenu(GLUTMenu *menu)
{
   __glutCurrentMenu = menu;
}

GLUTMenu *__glutGetMenu(void)
{
   return __glutCurrentMenu;
}

void __glutStartMenu(GLUTMenu *menu, GLUTView *window, NSPoint wMouseLoc)
{
   /* User is about to start a menu tracking session. We install a special
      timer which will execute the idle function while menu tracking is
      going on because menu tracking happens in its own modal event loop. */
   __glutStartIdleFuncTimer();
   
   __glutMappedMenu = menu;
   __glutMenuWindow = window;
   if(__glutMenuStatusFunc) {
      __glutSetMenu(menu);
      __glutSetWindow(window);
      
      wMouseLoc = [window convertPoint: wMouseLoc fromView: nil];
      __glutMenuStatusFunc(GLUT_MENU_IN_USE, rint(wMouseLoc.x), rint(wMouseLoc.y));
   }
}

void __glutFinishMenu(NSPoint sMouseLoc)
{
	/* Setting __glutMappedMenu to NULL permits operations that
		change menus or destroy the menu window again. */
   __glutMappedMenu = nil;
   if(__glutMenuStatusFunc) {
      __glutSetWindow(__glutMenuWindow);
      __glutSetMenu(__glutMappedMenu);
      
      sMouseLoc = [[__glutMenuWindow window] convertScreenToBase: sMouseLoc];
      sMouseLoc = [__glutMenuWindow convertPoint: sMouseLoc fromView: nil];
      
      __glutMenuStatusFunc(GLUT_MENU_NOT_IN_USE, rint(sMouseLoc.x), rint(sMouseLoc.y));
  }
}

static int __glutGetUnusedMenuSlot(void)
{
   int	i;
   
   /* Look for allocated, unused slot. */
   for(i = 0; i < __glutMenuListSize; i++) {
      if(!__glutMenuList[i]) {
         return i;
      }
   }
   
   /* Allocate a new slot. */
   __glutMenuListSize++;
   __glutMenuList = (GLUTMenu **) realloc(__glutMenuList, __glutMenuListSize * sizeof(GLUTMenu *));
   if(!__glutMenuList) {
      __glutFatalError("out of memory.");
   }
   __glutMenuList[__glutMenuListSize - 1] = NULL;
   return __glutMenuListSize - 1;
}

static GLUTMenu *__glutGetMenuByNum(int menunum)
{
   if(menunum < 1 || menunum > __glutMenuListSize) {
      return nil;
   }
   return __glutMenuList[menunum - 1];
}

static void __glutMenuModificationError(void)
{
   /* XXX Remove the warning after GLUT 3.0. */
   __glutWarning("The following is a new check for GLUT 3.0; update your code.");
   __glutFatalError("menu manipulation not allowed while menus in use.");
}

/* CENTRY */
int APIENTRY glutCreateMenu(void (*func) (int value))
{
   GLUTMenu *	menu;
   int		menuid = 0;
	
   GLUTAPI_DECLARATIONS
   GLUTAPI_BEGIN
   if(__glutMappedMenu) {
      __glutMenuModificationError();
   }
   
   menuid = __glutGetUnusedMenuSlot();
   menu = [[GLUTMenu alloc] initWithCallback: func menuID: menuid + 1];
	if(menu == nil) {
		__glutFatalError("out of memory."); // will exit
	}
   __glutMenuList[menuid] = menu;
   __glutSetMenu(menu);
   GLUTAPI_END
   return menuid + 1;
}

int APIENTRY glutGetMenu(void)
{
   if(__glutCurrentMenu) {
      return [__glutCurrentMenu menuID];
   } else {
      return 0;
   }
}

void APIENTRY glutSetMenu(int menuid)
{
   GLUTMenu * menu = __glutGetMenuByNum(menuid);
   
   if(!menu) {
      __glutWarning("glutSetMenu attempted on bogus menu.");
      return;
   }
   __glutSetMenu(menu);
}

void APIENTRY glutAddMenuEntry(const char *name, int value)
{
   NSString *	title;
   
   GLUTAPI_DECLARATIONS
   GLUTAPI_BEGIN
   if(name == NULL) {
      __glutFatalError("glutAddMenuEntry called with NULL name.");
   }
   if(__glutMappedMenu) {
      __glutMenuModificationError();
   }
   
   title = [NSString stringWithUTF8String: name];
   if(!title) {
      __glutFatalError("out of memory");
   }
   [__glutCurrentMenu addMenuItemWithTitle: title tag: value];
   GLUTAPI_END
}

void APIENTRY glutAddSubMenu(const char *name, int menu)
{
   GLUTMenu *	submenu;
   NSString *	title;
   
   GLUTAPI_DECLARATIONS
   GLUTAPI_BEGIN
	if(name == NULL) {
		__glutFatalError("glutAddSubMenu called with NULL name.");
   }
   if(__glutMappedMenu) {
      __glutMenuModificationError();
   }
	
   title = [NSString stringWithUTF8String: name];
   if(!title) {
      __glutFatalError("out of memory");
   }
   
   submenu = __glutGetMenuByNum(menu);
   if(!submenu) {
      __glutWarning("glutAddSubMenu attempted on bogus menu.");
      GLUTAPI_VOIDRETURN;
   }
   [__glutCurrentMenu addSubMenuWithTitle: title menu: submenu];
   GLUTAPI_END
}

void APIENTRY glutAttachMenu(int button)
{
   GLUTAPI_DECLARATIONS
   GLUTAPI_BEGIN
   if(__glutMappedMenu) {
      __glutMenuModificationError();
   }
   [__glutCurrentView attachMenu: __glutCurrentMenu toButton: button];
   GLUTAPI_END
}

void APIENTRY glutDetachMenu(int button)
{
   GLUTAPI_DECLARATIONS
   GLUTAPI_BEGIN
   if(__glutMappedMenu) {
      __glutMenuModificationError();
   }
   [__glutCurrentView detachMenuFromButton: button];
   GLUTAPI_END
}

void APIENTRY glutDestroyMenu(int menu)
{
   GLUTMenu *	menuObj;
   
   menuObj = __glutGetMenuByNum(menu);
   if(!menuObj) {
		__glutWarning("glutDestroyMenu attempted on bogus menu %d.", menu);
		return;
	}
   if(__glutMappedMenu) {
      __glutMenuModificationError();
   }
   
   if(menuObj == __glutCurrentMenu) {
      __glutCurrentMenu = nil;
   }
   [menuObj release];
   __glutMenuList[menu - 1] = NULL;
}

void APIENTRY glutChangeToMenuEntry(int entry, const char *name, int value)
{
   NSString *	title;
   
   GLUTAPI_DECLARATIONS
   GLUTAPI_BEGIN
	if(name == NULL) {
		__glutFatalError("glutChangeToMenuEntry called with NULL name.");
   }
   if(__glutMappedMenu) {
      __glutMenuModificationError();
   }
   
   title = [NSString stringWithUTF8String: name];
   if(!title) {
      __glutFatalError("out of memory");
   }
   [__glutCurrentMenu setMenuItemAtIndex: entry - 1 toTitle: title tag: value];
   GLUTAPI_END
}

void APIENTRY glutChangeToSubMenu(int entry, const char *name, int menu)
{
   GLUTMenu *	submenu;
   NSString *	title;
   
   GLUTAPI_DECLARATIONS
   GLUTAPI_BEGIN
	if(name == NULL) {
		__glutFatalError("glutChangeToSubMenu called with NULL name.");
   }
   if(__glutMappedMenu) {
      __glutMenuModificationError();
   }
   
   submenu = __glutGetMenuByNum(menu);
   if(!submenu) {
      __glutWarning("glutChangeToSubMenu attempted on bogus menu.");
      GLUTAPI_VOIDRETURN;
   }
   title = [NSString stringWithUTF8String: name];
   if(!title) {
      __glutFatalError("out of memory");
   }
   [__glutCurrentMenu setMenuItemAtIndex: entry - 1 toTitle: title menu: submenu];
   GLUTAPI_END
}

void APIENTRY glutRemoveMenuItem(int entry)
{
   GLUTAPI_DECLARATIONS
   GLUTAPI_BEGIN
   if(__glutMappedMenu) {
      __glutMenuModificationError();
   }
   
   [__glutCurrentMenu removeMenuItemAtIndex: entry - 1];
   GLUTAPI_END
}

void APIENTRY glutMenuStatusFunc(void (*func)(int status, int x, int y))
{
	__glutMenuStatusFunc = func;
}

void APIENTRY glutMenuStateFunc(void (*func)(int status))
{
	__glutMenuStatusFunc = (GLUTmenuStatusCB) func;
}
/* ENDCENTRY */
