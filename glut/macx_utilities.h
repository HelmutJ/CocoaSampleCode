
/* Copyright (c) Dietmar Planitzer, 1998 */

/* This program is freely distributable without licensing fees 
   and is provided without guarantee or warrantee expressed or 
   implied. This program is -not- in the public domain. */

#ifndef APIENTRY
#define APIENTRY
#endif

void *__glutGetGLProcAddress(const char *name);

char *	__glutStrdup(const char *string);
void	__glutWarning(char *format,...);
void	__glutFatalError(char *format,...);
void	__glutFatalUsage(char *format,...);

// uses static library routines to make this app foreground capable and set to front
void	__glutSetForeground(void);

