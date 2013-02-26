
/* Copyright (c) Dietmar Planitzer, 1998, 2002 */

/* This program is freely distributable without licensing fees 
   and is provided without guarantee or warrantee expressed or 
   implied. This program is -not- in the public domain. */

#import "macx_glut.h"
#import "GLUTView.h"


/* CENTRY */
void APIENTRY glutEstablishOverlay(void)
{
	/* not implemented */
   
   /* If you want to know why we don't support overlays,
      then read this: */
   
  /* XXX For now, transparent RGBA overlays are not supported
     by GLUT.  RGBA overlays raise difficult questions about
     what the transparent pixel (really color) value should be.

     Color index overlay transparency is "easy" because the
     transparent pixel value does not affect displayable colors
     (except for stealing one color cell) since colors are
     determined by indirection through a colormap, and because
     it is uncommon for arbitrary pixel values in color index to
     be "calculated" (as can occur with a host of RGBA operations
     like lighting, blending, etc) so it is easy to avoid the
     transparent pixel value.

     Since it is typically easy to avoid the transparent pixel
     value in color index mode, if GLUT tells the programmer what
     pixel is transparent, then most program can easily avoid
     generating that pixel value except when they intend
     transparency.  GLUT returns whatever transparent pixel value
     is provided by the system through glutGet(
     GLUT_TRANSPARENT_INDEX).

     Theory versus practice for RGBA overlay transparency: In
     theory, the reasonable thing is enabling overlay transparency
     when an overlay pixel's destination alpha is 0 because this
     allows overlay transparency to be controlled via alpha and all
     visibile colors are permited, but no hardware I am aware of
     supports this practice (and it requires destination alpha which
     is typically optional and quite uncommon for overlay windows!). 

     In practice, the choice of  transparent pixel value is typically
     "hardwired" into most graphics hardware to a single pixel value.
     SGI hardware uses true black (0,0,0) without regard for the
     destination alpha.  This is far from ideal because true black (a
     common color that is easy to accidently generate) can not be
     generated in an RGBA overlay. I am not sure what other vendors
     do.

     Pragmatically, most of the typical things you want to do in the
     overlays can be done in color index (rubber banding, pop-up
     menus, etc.).  One solution for GLUT would be to simply
     "advertise" what RGB triple (or possibly RGBA quadruple or simply 
     A alone) generates transparency.  The problem with this approach
     is that it forces programmers to avoid whatever arbitrary color
     various systems decide is transparent.  This is a difficult
     burden to place on programmers that want to portably make use of
     overlays.

     To actually support transparent RGBA overlays, there are really
     two reaonsable options.  ONE: Simply mandate that true black is
     the RGBA overlay transparent color (what IRIS GL did).  This is
     nice for programmers since only one option, nice for existing SGI 
     hardware, bad for anyone (including SGI) who wants to improve
     upon "true black" RGB transparency. 

     Or TWO: Provide a set of queriable "transparency types" (like
     "true black" or "alpha == 0" or "true white" or even a queriable
     transparent color).  This is harder for programmers, OK for
     existing SGI hardware, and it leaves open the issue of what other 
     modes are reasonable.

     Option TWO seems the more general approach, but since hardware
     designers will likely only implement a single mode (this is a
     scan out issue where bandwidth is pressing issue), codifying
     multiple speculative approaches nobody may ever implement seems
     silly.  And option ONE fiats a suboptimal solution.

     Therefore, I defer any decision of how GLUT should support RGBA
     overlay transparency and leave support for it unimplemented.
     Nobody has been pressing me for RGBA overlay transparency (though 
     people have requested color index overlay transparency
     repeatedly).  Geez, if you read this far you are either really
     bored or maybe actually  interested in this topic.  Anyway, if
     you have ideas (particularly if you plan on implementing a
     hardware scheme for RGBA overlay transparency), I'd be
     interested.

     For the record, SGI's expiremental Framebufer Configuration
     experimental GLX extension uses option TWO.  Transparency modes
     for "none" and "RGB" are defined (others could be defined later). 
     What RGB value is the transparent one must be queried. 

     I was hoping GLUT could have something that required less work
     from the programmer to use portably. -mjk */

  __glutWarning("Overlays are not supported by Mac OS X GLUT (for now).");
}

void APIENTRY glutUseLayer(GLenum layer)
{
	if(layer != GLUT_NORMAL || layer != GLUT_OVERLAY)
		__glutWarning("glutUseLayer: unknown layer, %d.", layer);
	/* not implemented */
}

void APIENTRY glutRemoveOverlay(void)
{
	/* not implemented */
}

void APIENTRY glutPostOverlayRedisplay(void)
{
	/* not implemented */
}

void APIENTRY glutPostWindowOverlayRedisplay(int win)
{
	/* not implemented */
}

void APIENTRY glutShowOverlay(void)
{
	/* not implemented */
}

void APIENTRY glutHideOverlay(void)
{
	/* not implemented */
}

void APIENTRY glutOverlayDisplayFunc(void (*func)(void))
{
	/* not implemented */
}

int APIENTRY glutLayerGet(GLenum param)
{
	switch(param) {
		case GLUT_OVERLAY_POSSIBLE:
			return 0;
		case GLUT_LAYER_IN_USE:
			return GLUT_NORMAL;
		case GLUT_HAS_OVERLAY:
			return 0;
		case GLUT_TRANSPARENT_INDEX:
			return -1;
		case GLUT_NORMAL_DAMAGED:
			return [__glutCurrentView isDamaged];
		case GLUT_OVERLAY_DAMAGED:
			return -1;
		default:
			__glutWarning("invalid glutLayerGet parameter: %d", param);
			return -1;		
	}
}
/* ENDCENTRY */
