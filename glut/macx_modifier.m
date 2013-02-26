
/* Copyright (c) Dietmar Planitzer, 1998, 2002 */

/* This program is freely distributable without licensing fees 
   and is provided without guarantee or warrantee expressed or 
   implied. This program is -not- in the public domain. */

#import "macx_glut.h"
#import "GLUTView.h"


/* Modifier mask of ~0 implies not in core input callback. */
unsigned int __glutModifierMask = (unsigned int) ~0;



/* CENTRY */
int APIENTRY glutGetModifiers(void)
{
   int	modifiers;
   
   if(__glutModifierMask == (unsigned int) ~0) {
      __glutWarning("glutCurrentModifiers: do not call outside core input callback.");
      return 0;
   }
   modifiers = 0;
   
   if(__glutModifierMask & NSShiftKeyMask)
      modifiers |= GLUT_ACTIVE_SHIFT;
   if(__glutModifierMask & NSControlKeyMask)
      modifiers |= GLUT_ACTIVE_CTRL;
   if(__glutModifierMask & NSAlternateKeyMask)
      modifiers |= GLUT_ACTIVE_ALT;
   return modifiers;
}
/* ENDCENTRY */
