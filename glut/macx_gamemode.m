
/* Copyright (c) Mark J. Kilgard, 1994. */
/* Copyright (c) Dietmar Planitzer, 1998, 2002 */

/* This program is freely distributable without licensing fees 
   and is provided without guarantee or warrantee expressed or 
   implied. This program is -not- in the public domain. */

#import "macx_glut.h"
#import "GLUTView.h"

BOOL						__glutCaptureAllDisplays = kCaptureAllDisplays;

/* The following code is based on similiar code in glut_gamemode.c */
GLUTView *					__glutGameModeWindow = nil;
BOOL                        __glutDestoryingGameMode = false;
CGDisplayFadeInterval		__glutGameModeFadeInterval = GLUT_DEFAULT_FADE_INTERVAL;
static int					__glutDisplaySettingsChanged = 0;
static DisplayMode *		dmodes, *currentDm = NULL;
static int					ndmodes = -1;
static CFDictionaryRef		gOriginalMode = NULL;
static BOOL					gIsLimitedMode = NO;
static int					gSavedDefaultColorSize;



#ifdef TEST
static char *compstr[] =
{
  "none", "=", "!=", "<=", ">=", ">", "<", "~"
};
static char *capstr[] =
{
  "width", "height", "bpp", "hertz", "num"
};
#endif

short __glutGetCurrentDMDepth (void)
{
	if (currentDm)
		return currentDm->cap[DM_PIXEL_DEPTH];
	else
		return __glutDefaultColorSize;
}

void __glutCloseDownGameMode(void)
{
   if(__glutGameModeWindow == nil && !__glutDisplaySettingsChanged)
      return;
   
    CGDisplayFadeReservationToken fadeToken;

   if(__glutGameModeFadeInterval > 0.0) {
      CGAcquireDisplayFadeReservation(kCGMaxDisplayReservationInterval, &fadeToken);
      /* Fade all displays to black */
      CGDisplayFade(fadeToken,
			__glutGameModeFadeInterval,			// 2 seconds
			kCGDisplayBlendNormal,	// Starting state
			kCGDisplayBlendSolidColor, // Ending state
			0.0, 0.0, 0.0,		// black
			true);			// Wait for completion
   }
   
   if(__glutGameModeWindow) {
      GLUTView * tempView = __glutGameModeWindow;
      __glutGameModeWindow = nil; // ensure close is not called recursively
      __glutDestroyWindow(tempView);
   }
   
   if(__glutDisplaySettingsChanged) {
   	CGDisplaySwitchToMode(kCGDirectMainDisplay, gOriginalMode);
      gOriginalMode = NULL;
		if (NO == __glutCaptureAllDisplays)
			CGDisplayRelease (kCGDirectMainDisplay);
		else
			CGReleaseAllDisplays();
      __glutDisplaySettingsChanged = 0;
      __glutDefaultColorSize = gSavedDefaultColorSize;
   }
   
   if(__glutGameModeFadeInterval > 0.0) {
      /* Fade all displays back in */
      CGDisplayFade(fadeToken,
                __glutGameModeFadeInterval,			// 2 seconds
                kCGDisplayBlendSolidColor, // Starting state
                kCGDisplayBlendNormal,	// Ending state
                0.0, 0.0, 0.0,		// black
                false);			// Don't wait for completion
      CGReleaseDisplayFadeReservation(fadeToken);
   }
}

static int _getDictInt (CFDictionaryRef refDict, CFStringRef key)
{
	int int_value;
	CFNumberRef number_value = (CFNumberRef) CFDictionaryGetValue(refDict, key);
	if (!number_value) // if can't get a number for the dictionary
		return -1;  // fail
	if (!CFNumberGetValue(number_value, kCFNumberIntType, &int_value)) // or if cant convert it
		return -1; // fail
	return int_value; // otherwise return the int value
}

static double _getDictDouble (CFDictionaryRef refDict, CFStringRef key)
{
	double double_value;
	CFNumberRef number_value = (CFNumberRef) CFDictionaryGetValue(refDict, key);
	if (!number_value) // if can't get a number for the dictionary
		return -1;  // fail
	if (!CFNumberGetValue(number_value, kCFNumberDoubleType, &double_value)) // or if cant convert it
		return -1; // fail
	return double_value; // otherwise return the int value
}

#define MIN_WIDTH 640
#define MIN_HEIGHT 480
#define MIN_FREQUENCY 0 /* account for flat panels */
#define MIN_PIXEL_DEPTH	16

static void initGameModeSupport(void)
{
   CFArrayRef	displayModes = NULL;
   CFIndex		i, j, count;

   if(ndmodes >= 0) {
      /* ndmodes is initially -1 to indicate no dmodes allocated yet. */
      if(!gIsLimitedMode) {
         return;
      } else {
         /* let's promote to all modes */
         free(dmodes);
         dmodes = NULL;
         ndmodes = -1;
         currentDm = NULL;
      }
   }
   
   /* Determine how many display modes there are. */
   displayModes = CGDisplayAvailableModes(kCGDirectMainDisplay);
   count = CFArrayGetCount(displayModes);
   ndmodes = 0; // must set to zero otherwise allocate too little storage
   for(i = 0; i < count; i++) {
      CFDictionaryRef	modeDict = CFArrayGetValueAtIndex(displayModes, i);      
      long width = _getDictInt (modeDict, kCGDisplayWidth);
      long height = _getDictInt (modeDict, kCGDisplayHeight);
      long freq = (int)(_getDictDouble (modeDict, kCGDisplayRefreshRate) + 0.5);
      long depth = _getDictInt (modeDict, kCGDisplayBitsPerPixel);
      
      if ((width >= MIN_WIDTH) && (height >= MIN_HEIGHT) && (freq >= MIN_FREQUENCY) && (depth >= MIN_PIXEL_DEPTH))
         ndmodes++;
   }
   
   /* Allocate memory for a list of all the display modes. */
   dmodes = (DisplayMode *) malloc(ndmodes * sizeof(DisplayMode));
   
   /* Now that we know how many display modes to expect,
      enumerate them again and save the information in
      the list we allocated above. */
   for(i = 0, j = 0; i < count; i++) {
      CFDictionaryRef	modeDict = CFArrayGetValueAtIndex(displayModes, i);
      int displayWidth = _getDictInt (modeDict, kCGDisplayWidth);
      int displayHeight = _getDictInt (modeDict, kCGDisplayHeight);
      int displayFreq = (int)(_getDictDouble (modeDict, kCGDisplayRefreshRate) + 0.5);
      int bitsPerPixel = _getDictInt (modeDict, kCGDisplayBitsPerPixel);
      
      /* Try to reject any display settings that seem unplausible. */
      if(displayWidth >= MIN_WIDTH &&
         displayHeight >= MIN_HEIGHT &&
         displayFreq >= MIN_FREQUENCY &&
         bitsPerPixel >= MIN_PIXEL_DEPTH) {
         dmodes[j].cgModeDict = modeDict;
         dmodes[j].valid = 1;  /* XXX Not used for now. */
         dmodes[j].cap[DM_WIDTH] = displayWidth;
         dmodes[j].cap[DM_HEIGHT] = displayHeight;
         dmodes[j].cap[DM_PIXEL_DEPTH] = bitsPerPixel;
         dmodes[j].cap[DM_HERTZ] = displayFreq;
         j++;
      }
   }
   gIsLimitedMode = NO;
}

/* Same as above but creates only a single DisplayMode for the current
   CG display mode */
static void initLimitedGameModeSupport(void)
{
   CFDictionaryRef	modeDict = CGDisplayCurrentMode(kCGDirectMainDisplay);
   
   if(ndmodes >= 0) {
      /* ndmodes is initially -1 to indicate no dmodes allocated yet. */
      return;
   }
   
   /* Allocate memory for a single display mode. */
   dmodes = (DisplayMode *) malloc(sizeof(DisplayMode));
   
   dmodes[0].cgModeDict = modeDict;
	dmodes[0].valid = 1;  /* XXX Not used for now. */
   dmodes[0].cap[DM_WIDTH] = _getDictInt(modeDict, kCGDisplayWidth);
   dmodes[0].cap[DM_HEIGHT] = _getDictInt(modeDict, kCGDisplayHeight);
   dmodes[0].cap[DM_PIXEL_DEPTH] = (int)(_getDictDouble (modeDict, kCGDisplayRefreshRate) + 0.5);
   dmodes[0].cap[DM_HERTZ] = _getDictInt(modeDict, kCGDisplayRefreshRate);
   gIsLimitedMode = YES;
}

/* This routine is based on similiar code in glut_dstr.c */
static DisplayMode *findMatch(DisplayMode *localdmodes, int localndmodes, Criterion *criteria, int ncriteria)
{
#if USE_GLUT_DSPY_MATCH_SCHEME
   DisplayMode *found;
   int *bestScore, *thisScore;
   int i, j, numok, result, worse, better;
   
   found = NULL;
   numok = 1;		/* "num" capability is indexed from 1, not 0. */
   
   /* XXX alloca canidate. */
   bestScore = (int *) malloc(ncriteria * sizeof(int));
   if(!bestScore) {
      __glutFatalError("out of memory.");
   }
   for (j = 0; j < ncriteria; j++) {
      /* Very negative number. */
      bestScore[j] = -32768;
   }
   
   /* XXX alloca canidate. */
   thisScore = (int *) malloc(ncriteria * sizeof(int));
   if (!thisScore) {
      __glutFatalError("out of memory.");
   }
   
   for(i = 0; i < localndmodes; i++) {
      if(localdmodes[i].valid) {
         worse = 0;
         better = 0;
         
         for(j = 0; j < ncriteria; j++) {
            int cap, cvalue, dvalue;
            
            cap = criteria[j].capability;
            cvalue = criteria[j].value;
            if(cap == NUM) {
               dvalue = numok;
            } else {
               dvalue = localdmodes[i].cap[cap];
            }
#ifdef TEST
            if(verbose)
               NSLog(@"  %s %s %d to %d\n", capstr[cap], compstr[criteria[j].comparison], cvalue, dvalue);
#endif
            switch(criteria[j].comparison) {
               case CMP_EQ:
                  result = cvalue == dvalue;
                  thisScore[j] = 1;
                  break;
               case CMP_NEQ:
                  result = cvalue != dvalue;
                  thisScore[j] = 1;
                  break;
               case CMP_LT:
                  result = dvalue < cvalue;
                  thisScore[j] = dvalue - cvalue;
                  break;
               case CMP_GT:
                  result = dvalue > cvalue;
                  thisScore[j] = dvalue - cvalue;
                  break;
               case CMP_LTE:
                  result = dvalue <= cvalue;
                  thisScore[j] = dvalue - cvalue;
                  break;
               case CMP_GTE:
                  result = (dvalue >= cvalue);
                  thisScore[j] = dvalue - cvalue;
                  break;
               case CMP_MIN:
                  result = dvalue >= cvalue;
                  thisScore[j] = cvalue - dvalue;
                  break;
            }

#ifdef TEST
            if(verbose)
               NSLog(@"       result=%d   score=%d   bestScore=%d\n", result, thisScore[j], bestScore[j]);
#endif

            if(result) {
               if(better || thisScore[j] > bestScore[j]) {
                  better = 1;
               } else if(thisScore[j] == bestScore[j]) {
                  /* Keep looking. */
               } else {
                  goto nextDM;
               }
            } else {
               if(cap == NUM) {
                  worse = 1;
            } else {
                  goto nextDM;
            }
         }
      }

      if(better && !worse) {
         found = &localdmodes[i];
         for(j = 0; j < ncriteria; j++) {
            bestScore[j] = thisScore[j];
         }
      }
      numok++;

nextDM:;

      }
   }
   free(bestScore);
   free(thisScore);
   return found;
#else
    DisplayMode *found;
    CFDictionaryRef bestMode = NULL;
    boolean_t bExactMatch;
    int width = MIN_WIDTH, height = MIN_HEIGHT, bpp = MIN_PIXEL_DEPTH, freq = MIN_FREQUENCY;
    int i;
    
    for (i = 0; i < ncriteria; i++) {
	switch (criteria[i].capability) {
	case DM_WIDTH:        width = criteria[i].value; break;
	case DM_HEIGHT:       height = criteria[i].value; break;
	case DM_PIXEL_DEPTH:  bpp = criteria[i].value; break;
	case DM_HERTZ:        freq = criteria[i].value; break;
	}
    }

    bestMode = CGDisplayBestModeForParametersAndRefreshRate(
        kCGDirectMainDisplay, bpp, width, height, freq,  &bExactMatch);

    found = NULL;
    for(i = 0; i < localndmodes; i++) {
		if (localdmodes[i].cgModeDict == bestMode) {
			found = &(localdmodes[i]);
			break;
		}
    }
	if (NULL == found) { /* could not find mode, try with 0 freq for flat panels */
		bestMode = CGDisplayBestModeForParametersAndRefreshRate(
			kCGDirectMainDisplay, bpp, width, height, 0,  &bExactMatch);
	
		found = NULL;
		for(i = 0; i < localndmodes; i++) {
			if (localdmodes[i].cgModeDict == bestMode) {
				found = &(localdmodes[i]);
				break;
			}
		}
	}
    return found;
#endif
}

/**
 * Parses strings in the form of:
 *  800x600
 *  800x600:16
 *  800x600@60
 *  800x600:16@60
 *  @60
 *  :16
 *  :16@60
 * NOTE that @ before : is not parsed.
 */
static int specialCaseParse(char *word, Criterion *criterion, int mask)
{
   char *xstr, *response;
   int got;
   int width, height, bpp, hertz;
   
   switch(word[0]) {
      case '0':
      case '1':
      case '2':
      case '3':
      case '4':
      case '5':
      case '6':
      case '7':
      case '8':
      case '9':
         /* The WWWxHHH case. */
         if(mask & (1 << DM_WIDTH)) {
            return -1;
         }
         xstr = strpbrk(&word[1], "x");
         if(xstr) {
            width = (int) strtol(word, &response, 0);
            if(response == word || response[0] != 'x') {
               /* Not a valid number OR needs to be followed by 'x'. */
               return -1;
            }
            height = (int) strtol(&xstr[1], &response, 0);
            if(response == &xstr[1]) {
               /* Not a valid number. */
               return -1;
            }
            criterion[0].capability = DM_WIDTH;
            criterion[0].comparison = CMP_EQ;
            criterion[0].value = width;
            criterion[1].capability = DM_HEIGHT;
            criterion[1].comparison = CMP_EQ;
            criterion[1].value = height;
            got = specialCaseParse(response, &criterion[2], 1 << DM_WIDTH);
            if(got >= 0) {
               return got + 2;
            } else {
               return -1;
            }
         }	
         return -1;
         
      case ':':
         /* The :BPP case. */
         if(mask & (1 << DM_PIXEL_DEPTH)) {
            return -1;
         }
         bpp = (int) strtol(&word[1], &response, 0);
         if(response == &word[1]) {
            /* Not a valid number. */
            return -1;
         }
         criterion[0].capability = DM_PIXEL_DEPTH;
         criterion[0].comparison = CMP_EQ;
         criterion[0].value = bpp;
         got = specialCaseParse(response, &criterion[1], 1 << DM_WIDTH | 1 << DM_PIXEL_DEPTH);
         if(got >= 0) {
            return got + 1;
         } else {
            return -1;
         }
         
      case '@':
         /* The @HZ case. */
         if(mask & (1 << DM_HERTZ)) {
            return -1;
         }
         hertz = (int) strtol(&word[1], &response, 0);
         if(response == &word[1]) {
            /* Not a valid number. */
            return -1;
         }
         criterion[0].capability = DM_HERTZ;
         criterion[0].comparison = CMP_EQ;
         criterion[0].value = hertz;
         got = specialCaseParse(response, &criterion[1], ~DM_HERTZ);
         if(got >= 0) {
            return got + 1;
         } else {
            return -1;
         }
         
      case '\0':
         return 0;
   }
   return -1;
}

/* This routine is based on similiar code in glut_dstr.c */
static int parseCriteria(char *word, Criterion *criterion)
{
   char *cstr, *vstr, *response;
   int comparator, value = 0;
   
   cstr = strpbrk(word, "=><!~");
   if(cstr) {
      switch(cstr[0]) {
         case '=':
            comparator = CMP_EQ;
            vstr = &cstr[1];
            break;
            
         case '~':
            comparator = CMP_MIN;
            vstr = &cstr[1];
            break;
            
         case '>':
            if(cstr[1] == '=') {
               comparator = CMP_GTE;
               vstr = &cstr[2];
            } else {
               comparator = CMP_GT;
               vstr = &cstr[1];
            }
            break;
            
         case '<':
            if(cstr[1] == '=') {
               comparator = CMP_LTE;
               vstr = &cstr[2];
            } else {
               comparator = CMP_LT;
               vstr = &cstr[1];
            }
            break;
            
         case '!':
            if(cstr[1] == '=') {
               comparator = CMP_NEQ;
               vstr = &cstr[2];
            } else {
               return -1;
            }
            break;
            
         default:
            return -1;
      }
      value = (int) strtol(vstr, &response, 0);
      if(response == vstr) {
         /* Not a valid number. */
         return -1;
      }
      *cstr = '\0';
   } else {
      comparator = CMP_NONE;
   }
   
   switch (word[0]) {
      case 'b':
         if(!strcmp(word, "bpp")) {
            criterion[0].capability = DM_PIXEL_DEPTH;
            if(comparator == CMP_NONE) {
               return -1;
            } else {
               criterion[0].comparison = comparator;
               criterion[0].value = value;
               return 1;
            }
         }
         return -1;
         
      case 'h':
         if(!strcmp(word, "height")) {
            criterion[0].capability = DM_HEIGHT;
            if(comparator == CMP_NONE) {
               return -1;
            } else {
               criterion[0].comparison = comparator;
               criterion[0].value = value;
               return 1;
            }
         }
         if(!strcmp(word, "hertz")) {
            criterion[0].capability = DM_HERTZ;
            if(comparator == CMP_NONE) {
               return -1;
            } else {
               criterion[0].comparison = comparator;
               criterion[0].value = value;
               return 1;
            }
         }
         return -1;
         
      case 'n':
         if(!strcmp(word, "num")) {
            criterion[0].capability = DM_NUM;
            if(comparator == CMP_NONE) {
               return -1;
            } else {
               criterion[0].comparison = comparator;
               criterion[0].value = value;
               return 1;
            }
         }
         return -1;
         
      case 'w':
         if(!strcmp(word, "width")) {
            criterion[0].capability = DM_WIDTH;
            if(comparator == CMP_NONE) {
               return -1;
            } else {
               criterion[0].comparison = comparator;
               criterion[0].value = value;
               return 1;
            }
         }
         return -1;
         
   }
   if(comparator == CMP_NONE) {
      return specialCaseParse(word, criterion, 0);
   }
   return -1;
}

/* This routine is based on similiar code in glut_dstr.c */
static Criterion *parseDisplayString(const char *display, int *ncriteria)
{
   Criterion *criteria = NULL;
   int n, parsed;
   char *copy, *word;
   
   copy = __glutStrdup(display);
   /* Attempt to estimate how many criteria entries should be needed. */
   n = 0;
   word = strtok(copy, " \t");
   while(word) {
      n++;
      word = strtok(NULL, " \t");
   }
   /* Allocate number of words of criteria.  A word
      could contain as many as four criteria in the
      worst case.  Example: 800x600:16@60 */
   criteria = (Criterion *) malloc(4 * n * sizeof(Criterion));
   if(!criteria) {
      __glutFatalError("out of memory.");
   }
   
   /* Re-copy the copy of the display string. */
   strcpy(copy, display);
   
   n = 0;
   word = strtok(copy, " \t");
   while(word) {
      parsed = parseCriteria(word, &criteria[n]);
      if(parsed >= 0) {
         n += parsed;
      } else {
         __glutWarning("Unrecognized game mode string word: %s (ignoring)\n", word);
      }
      word = strtok(NULL, " \t");
   }
   
   free(copy);
   *ncriteria = n;
   return criteria;
}

/* CENTRY */
void APIENTRY glutGameModeString(const char *string)
{
   Criterion *	criteria;
   int			ncriteria;
   
   initGameModeSupport();
   criteria = parseDisplayString(string, &ncriteria);
   currentDm = findMatch(dmodes, ndmodes, criteria, ncriteria);
   free(criteria);
}

int APIENTRY glutEnterGameMode(void)
{
   int			width, height;
   CGDisplayErr	status = kCGErrorSuccess;
   CGDisplayFadeReservationToken fadeToken;
   int			winID = -1;

   GLUTAPI_DECLARATIONS
   GLUTAPI_BEGIN   
   
    if(__glutMappedMenu) {
            __glutFatalUsage("Entering game mode not allowed while menus in use");
    }

   if(__glutGameModeFadeInterval > 0.0) {
      CGAcquireDisplayFadeReservation(kCGMaxDisplayReservationInterval, &fadeToken);
      /* Fade all displays to black */
      CGDisplayFade(fadeToken,
         __glutGameModeFadeInterval,			// 2 seconds
         kCGDisplayBlendNormal,	// Starting state
         kCGDisplayBlendSolidColor, // Ending state
         0.0, 0.0, 0.0,		// black
         true);			// Wait for completion
   }

   if(__glutGameModeWindow) {
      /* Already in game mode, so blow away game mode
         window so apps can change resolutions. */
      GLUTView *	window = __glutGameModeWindow;
      /* Setting the game mode window to NULL tricks
         the window destroy code into not undoing the
         screen display change since we plan on immediately
         doing another mode change. */
      __glutGameModeWindow = nil;
      __glutDestroyWindow(window);
   }

   /* Assume default screen size until we find out if we
      can actually change the display settings. */
   width = __glutScreenWidth;
   height = __glutScreenHeight;
   gSavedDefaultColorSize = __glutDefaultColorSize;
   
   if(currentDm == NULL) {
      /* No game mode string specified. We simply capture the current
         display mode */
      initLimitedGameModeSupport();
      currentDm = &dmodes[0];
   }

	if(!CGDisplayIsCaptured(kCGDirectMainDisplay)) {
		if (NO == __glutCaptureAllDisplays)
			status = CGDisplayCapture (kCGDirectMainDisplay);
		else
			status = CGCaptureAllDisplays ();
	}

	if(status == kCGErrorSuccess) {
		if(gOriginalMode == NULL) {
			gOriginalMode = CGDisplayCurrentMode(kCGDirectMainDisplay);
		}
      
		status = CGDisplaySwitchToMode(kCGDirectMainDisplay, currentDm->cgModeDict);
		if(status == kCGErrorSuccess) {
			__glutDisplaySettingsChanged = 1;
			width = currentDm->cap[DM_WIDTH];
			height = currentDm->cap[DM_HEIGHT];
		} else {
			/* Switch back to default resolution. */
			__glutWarning("Could not enter game mode (%d)", status);
			CGDisplaySwitchToMode(kCGDirectMainDisplay, gOriginalMode);
			gOriginalMode = NULL;
			if (NO == __glutCaptureAllDisplays)
				CGDisplayRelease (kCGDirectMainDisplay);
			else
				CGReleaseAllDisplays();
		}
	}
	else
		__glutWarning ("glutEnterGameMode: Could not capture display");

   __glutDefaultColorSize = currentDm->cap[DM_PIXEL_DEPTH];
	/* Create a new window */
	__glutGameModeWindow = __glutCreateWindow(nil, 0, 0, width, height, /* game mode */ YES);
   if(__glutGameModeFadeInterval > 0.0) {
      /* Fade all displays back in */
      CGDisplayFade(fadeToken,
                __glutGameModeFadeInterval,			// 2 seconds
                kCGDisplayBlendSolidColor, // Starting state
                kCGDisplayBlendNormal,	// Ending state
                0.0, 0.0, 0.0,		// black
                false);			// Don't wait for completion
      CGReleaseDisplayFadeReservation(fadeToken);
   }
   winID = [__glutGameModeWindow windowID];
   GLUTAPI_END
   return winID;
}

void APIENTRY glutLeaveGameMode(void)
{
   GLUTAPI_DECLARATIONS
	GLUTAPI_BEGIN
	if(__glutGameModeWindow) {
		__glutDestoryingGameMode = true;
		__glutDestroyWindow(__glutGameModeWindow);
		// do not set game mode window to NULL here as the view dealloc is not called until this function exits
		// it is set to null in view dealloc
	} else
      __glutWarning("not in game mode so cannot leave game mode");
	GLUTAPI_END
}

int APIENTRY glutGameModeGet(GLenum mode)
{
   switch(mode) {
      case GLUT_GAME_MODE_ACTIVE:
            return __glutGameModeWindow != nil;
      case GLUT_GAME_MODE_POSSIBLE:
            return currentDm != NULL;
      case GLUT_GAME_MODE_WIDTH:
            return currentDm ? currentDm->cap[DM_WIDTH] : -1;
      case GLUT_GAME_MODE_HEIGHT:
            return currentDm ? currentDm->cap[DM_HEIGHT] : -1;
      case GLUT_GAME_MODE_PIXEL_DEPTH:
            return currentDm ? currentDm->cap[DM_PIXEL_DEPTH] : -1;
      case GLUT_GAME_MODE_REFRESH_RATE:
            return currentDm ? currentDm->cap[DM_HERTZ] : -1;
      case GLUT_GAME_MODE_DISPLAY_CHANGED:
            return __glutDisplaySettingsChanged;
      default:
			__glutWarning("invalid glutGameModeGet parameter: %d", mode);
         return -1;
   }
}
/* ENDCENTRY */
