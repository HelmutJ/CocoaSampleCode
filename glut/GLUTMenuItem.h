
/* Copyright (c) Dietmar Planitzer, 2002 */

/* This program is freely distributable without licensing fees 
   and is provided without guarantee or warrantee expressed or 
   implied. This program is -not- in the public domain. */


#import "macx_glut.h"

@class GLUTMenu;


@interface GLUTMenuItem : NSObject
{
@private
	
   NSString *	_title;
   GLUTMenu *	_submenu;	/* weak ref */
   int			_tag;		/* item tag */
   BOOL			_isTrigger;
}

- (id)initWithTitle: (NSString *)title tag: (int)tag;
- (id)initWithTitle: (NSString *)title menu: (GLUTMenu *)menu;

- (NSString *)title;
- (void)setTitle: (NSString *)title;
- (GLUTMenu *)menu;
- (void)setMenu: (GLUTMenu *)menu;
- (int)tag;
- (void)setTag: (int)tag;
- (BOOL)isTrigger;

@end
