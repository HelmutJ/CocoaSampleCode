
/* Copyright (c) Dietmar Planitzer, 1998, 2002 */

/* This program is freely distributable without licensing fees 
   and is provided without guarantee or warrantee expressed or 
   implied. This program is -not- in the public domain. */

#import "GLUTMenu.h"
#import "GLUTMenuItem.h"


@interface GLUTMenu(GLUTPrivate)
- (NSMenu *)_buildMenu;
- (void)_invalidateMenuCache;
- (void)_removeSubmenu: (GLUTMenu *)submenu;
- (IBAction)menuItemAction: (id)sender;
@end



@implementation GLUTMenu

- (id)initWithCallback: (GLUTselectCB)func menuID: (int)menuid
{
   if((self = [self init]) != nil) {
      _menuItems = [[NSMutableArray alloc] init];
      _selectFunc = func;
      _menuid = menuid;
      
      return self;
   }
   return nil;
}

- (void)dealloc
{
   [_menuItems release];
   [_nativeMenu release];

   if (_parentMenu) {
      [_parentMenu _removeSubmenu:self];
   }
   
   [super dealloc];
}

- (void)finalize
{
   if (_parentMenu) {
      [_parentMenu _removeSubmenu:self];
   }
   [super finalize];
}


- (int)menuID
{
   return _menuid;
}

- (int)numberOfItems
{
   return [_menuItems count];
}

- (NSMenu *)_buildMenu
{
   NSMenu *	menu = nil;
   NSZone *	mZone = [NSMenu menuZone];
   unsigned	i, count = [_menuItems count];
   
   /* (1) Allocate menu */
   menu = [[NSMenu allocWithZone: mZone] initWithTitle: @""];
   if(!menu) {
      __glutFatalError("out of memory");
   }
   [menu setAutoenablesItems: NO];
   
   /* (2) Add items */
   for(i = 0; i < count; i++) {
      GLUTMenuItem *	item = (GLUTMenuItem *) [_menuItems objectAtIndex: i];
      NSMenuItem *		menuItem = nil;
      
      menuItem = [[NSMenuItem allocWithZone: mZone]	initWithTitle: [item title]
                                                      action: @selector(menuItemAction:)
                                                      keyEquivalent: @""];
      if(menuItem == nil) {
         __glutFatalError("out of memory");
      }
      
      if(![item isTrigger]) {
         /* A standard menu item */
         [menuItem setTag: [item tag]];
         [menuItem setTarget: self];
      } else {
         /* An item with a submenu */
         [menuItem setSubmenu: [[item menu] _buildMenu]];
      }
      [menuItem setEnabled: YES];
      [menu addItem: menuItem];
      [menuItem release];
   }
   return menu;
}

- (NSMenu *)nativeMenu
{
   /* Build and cache native menu, if necessary */
   if(!_nativeMenu) {
      _nativeMenu = [self _buildMenu];
   }
   return _nativeMenu;
}

- (void)_invalidateMenuCache
{
   if(_parentMenu) {
      [_parentMenu _invalidateMenuCache];
   }
   
   if(_nativeMenu) {
      [_nativeMenu release];
      _nativeMenu = nil;
   }
}

- (void)_removeSubmenu: (GLUTMenu *)submenu
{
   unsigned	i, count;
   
   count = [_menuItems count];

   if (submenu) {
      for (i = 0; i < count; i++) {
         GLUTMenuItem *	item = (GLUTMenuItem *) [_menuItems objectAtIndex: i];
         if (item && [item menu] == submenu) {
    	    [_menuItems removeObjectAtIndex:i];
    		break;
         }
      }
   }
   
   [self _invalidateMenuCache];
}

- (IBAction)menuItemAction: (id)sender
{
   __glutFinishMenu([NSEvent mouseLocation]);
   
   /* If an item is selected and it is not a submenu trigger,
      generate menu callback. */
   __glutSetWindow(__glutMenuWindow);
   
      /* When menu callback is triggered, current menu should be
         set to the callback menu. */
   __glutSetMenu(self);
   (*_selectFunc)([(GLUTMenuItem *)sender tag]);
   
   __glutMenuWindow = nil;
}

/* Adds a new menu item to the end of the receiver. "value" is stored as the menu item's tag value. */
- (void)addMenuItemWithTitle: (NSString *)title tag: (int)value
{
   GLUTMenuItem *	menuItem = nil;
   
   menuItem = [[GLUTMenuItem alloc] initWithTitle: title tag: value];
   if(menuItem == nil) {
      __glutFatalError("out of memory");
   }
   [_menuItems addObject: menuItem];
   [menuItem release];
   [self _invalidateMenuCache];
}

/* Adds the given menu as a submenu to the receiver. */
- (void)addSubMenuWithTitle: (NSString *)title menu: (GLUTMenu *)submenu
{
   GLUTMenuItem *	menuItem = nil;
   
   menuItem = [[GLUTMenuItem alloc] initWithTitle: title menu: submenu];
   if(menuItem == nil) {
      __glutFatalError("out of memory");
   }
   [_menuItems addObject: menuItem];
   [menuItem release];
   [submenu setParentMenu:self];
   [self _invalidateMenuCache];   
}

/* Changes the given menu item's title and tag to the given values. */
- (void)setMenuItemAtIndex: (int)menuIndex toTitle: (NSString *)title tag: (int)value
{
   GLUTMenuItem *	menuItem = nil;
   
   if(menuIndex < 0 || menuIndex >= (int) [_menuItems count]) {
      __glutWarning("Current menu has no %d item.", menuIndex);
      return;
   }
   menuItem = (GLUTMenuItem *)[_menuItems objectAtIndex: menuIndex];
   
   [menuItem setTitle: title];
   [menuItem setTag: value];
   [menuItem setMenu: nil];
   [self _invalidateMenuCache];
}

/* Changes the given menu item to a submenu. */
- (void)setMenuItemAtIndex: (int)menuIndex toTitle: (NSString *)title menu: (GLUTMenu *)submenu
{
   GLUTMenuItem *	menuItem = nil;
	
   if(menuIndex < 0 || menuIndex >= (int) [_menuItems count]) {
      __glutWarning("Current menu has no %d item.", menuIndex);
      return;
   }
   menuItem = (GLUTMenuItem *)[_menuItems objectAtIndex: menuIndex];
   
   [menuItem setTitle: title];
   [menuItem setMenu: submenu];
   [self _invalidateMenuCache];
}

/* Removes the given menu item */
- (void)removeMenuItemAtIndex: (int)menuIndex
{
   if(menuIndex < 0 || menuIndex >= (int) [_menuItems count]) {
      __glutWarning("Current menu has no %d item.", menuIndex);
      return;
   }
   [_menuItems removeObjectAtIndex: menuIndex];
   [self _invalidateMenuCache];
}

- (void)setFortranCallback: (void *)func
{
	_fselectFunc = (GLUTselectFCB)func;
}

- (void *)getFortranCallback
{
	return (void *)_fselectFunc;
}

- (void)setParentMenu: (GLUTMenu *)parentMenu
{
	_parentMenu = parentMenu;
}

@end
