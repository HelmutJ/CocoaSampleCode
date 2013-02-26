
/* Copyright (c) Dietmar Planitzer, 1998, 2002 */

/* This program is freely distributable without licensing fees 
   and is provided without guarantee or warrantee expressed or 
   implied. This program is -not- in the public domain. */


#import "macx_glut.h"


@interface GLUTMenu : NSObject
{
@private
	
   NSMutableArray *  _menuItems;
   NSMenu *          _nativeMenu;	/* cached native menu */
   GLUTselectCB      _selectFunc;
   GLUTselectFCB     _fselectFunc;   /* Fortran select  */
   int               _menuid;		/* one-based menu ID */
   GLUTMenu *        _parentMenu;
}

- (id)initWithCallback: (GLUTselectCB)func menuID: (int)menuid;

/* Accessors */
- (int)menuID;
- (int)numberOfItems;
- (NSMenu *)nativeMenu;

/* Menu manipulation */
- (void)addMenuItemWithTitle: (NSString *)title tag: (int)value;
- (void)addSubMenuWithTitle: (NSString *)title menu: (GLUTMenu *)submenu;
- (void)setMenuItemAtIndex: (int)index toTitle: (NSString *)title tag: (int)value;
- (void)setMenuItemAtIndex: (int)index toTitle: (NSString *)title menu: (GLUTMenu *)submenu;
- (void)removeMenuItemAtIndex: (int)index;

- (void)setFortranCallback: (void *)func ;
- (void *)getFortranCallback;

- (void)setParentMenu: (GLUTMenu *)parentMenu;

@end
