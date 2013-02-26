
/* Copyright (c) Mark J. Kilgard, 1994. */
/* Copyright (c) Dietmar Planitzer, 2002 */

/* This program is freely distributable without licensing fees 
   and is provided without guarantee or warrantee expressed or 
   implied. This program is -not- in the public domain. */

#import <OpenGL/OpenGL.h>
#import <OpenGL/CGLTypes.h>
#import "macx_glut.h"


char *__glutDisplayString = NULL;

// #define TEST	1
#ifdef TEST
static int verbose = 0;

static char *compstr[] =
{
  "none", "=", "!=", "<=", ">=", ">", "<", "~"
};
static char *capstr[] =
{
  "rgba", "bufsize", "double", "stereo", "auxbufs", "red", "green", "blue", "alpha",
  "depth", "stencil", "acred", "acgreen", "acblue", "acalpha", "level", "xvisual",
  "transparent", "samples", "xstaticgray", "xgrayscale", "xstaticcolor", "xpseudocolor",
  "xtruecolor", "xdirectcolor", "slow", "conformant", "num"
};

static void printCriteria(Criterion *criteria, int ncriteria)
{
   int	i;
   
   printf("Criteria: %d\n", ncriteria);
   for (i = 0; i < ncriteria; i++) {
      printf("  %s %s %d\n",
         capstr[criteria[i].capability],
         compstr[criteria[i].comparison],
         criteria[i].value);
   }
}
#endif /* TEST */

//////////////////////////

static int	gWeightsLoaded = 0;
static int	gMinStencil = INT_MAX, gMaxStencil = 0;
static int	gMinDepth = INT_MAX, gMaxDepth = 0;
static int	gMaxAuxBufs = 0;
static int	gMinSamples = INT_MAX, gMaxSamples = 0;
static int	gMaxColor = 0, gMaxAlpha = 0;
static int	gMaxAccumColor = 0, gMaxAccumAlpha = 0;

#define MAX_BITS 17
static char	gBitTable[MAX_BITS] = {
   0, 1, 2, 3, 4, 5, 6, 8, 10, 12, 16, 24, 32, 48, 64,
   96, 128
};
#define MAX_BITS2 24
#define COLOR_BITS 0
#define ALPHA_BITS 1
static char gBitTable2[MAX_BITS2][2] = {
{0,0}, {0,0}, {0,0}, {0,0}, {0,0}, {0,0}, {4,0}, {4,4},
{4,8}, {5,0}, {5,1}, {5,8}, {6,0}, {6,8}, {8,0}, {8,8},
{8,8}, {10,0}, {10,2}, {10,8}, {12,0}, {12,12}, {16,0},
{16,16}
};

static int maskToMinWeight(int mask)
{
   int	i;
   int				n = INT_MAX;
   
   for(i = 0; i < MAX_BITS; i++) {
      if(mask & (1L << i)) {
         n = MIN(n, (int) gBitTable[i]);
      }
   }
   return n;
}

static int maskToMaxWeight(int mask)
{
   int	i;
   int				n = 0;
   
   for(i = 0; i < MAX_BITS; i++) {
      if(mask & (1L << i)) {
         n = MAX(n, (int) gBitTable[i]);
      }
   }
   return n;
}

static void maskToMaxWeight2(int mask, int *clr, int *alp)
{
   int	i;
   int				n = 0;
   
   for(i = 0; i < MAX_BITS2; i++) {
      if(mask & (1L << i)) {
         n = MAX(n, (int) gBitTable2[i][COLOR_BITS]);
      }
   }
   *clr = n;
   n = 0;
   for(i = 0; i < MAX_BITS2; i++) {
      if(mask & (1L << i)) {
         n = MAX(n, (int) gBitTable2[i][ALPHA_BITS]);
      }
   }
   *alp = n;
}

static void loadMinMaxWeights(void)
{
   int						n, color, alpha;
   CGLError					err;
   CGLRendererInfoObj	rend;
   int						i, nrend, value;
   
   /* get renderer info */
   err = CGLQueryRendererInfo(CGDisplayIDToOpenGLDisplayMask(kCGDirectMainDisplay), &rend, &nrend);
   if(err) {
      __glutFatalError("failed to acquire renderer infos (%d)", err);
   }
   
   /* determine min and max weights for stencil, depth, aux buffers... */
   n = 0;
   for(i = 0; i < nrend; i++) {
      CGLDescribeRenderer(rend, i, kCGLRPWindow, &value);
      
      if(value) {
         CGLDescribeRenderer(rend, i, kCGLRPColorModes, &value);
         maskToMaxWeight2(value, &color, &alpha);
         gMaxColor = MAX(color, gMaxColor);
         gMaxAlpha = MAX(alpha, gMaxAlpha);
         
         CGLDescribeRenderer(rend, i, kCGLRPAccumModes, &value);
         maskToMaxWeight2(value, &color, &alpha);
         gMaxAccumColor = MAX(color, gMaxAccumColor);
         gMaxAccumAlpha = MAX(alpha, gMaxAccumAlpha);
         
         CGLDescribeRenderer(rend, i, kCGLRPDepthModes, &value);
         gMinDepth = MIN(maskToMinWeight(value), gMinDepth);
         gMaxDepth = MAX(maskToMaxWeight(value), gMaxDepth);
         
         CGLDescribeRenderer(rend, i, kCGLRPStencilModes, &value);
         gMinStencil = MIN(maskToMinWeight(value), gMinStencil);
         gMaxStencil = MAX(maskToMaxWeight(value), gMaxStencil);
         
         CGLDescribeRenderer(rend, i, kCGLRPMaxAuxBuffers, &value);
         gMaxAuxBufs = MAX(value, gMaxAuxBufs);
         
         CGLDescribeRenderer(rend, i, kCGLRPMaxSampleBuffers, &value);
         if(value > 0) {
            CGLDescribeRenderer(rend, i, kCGLRPMaxSamples, &value);
            gMinSamples = MIN(value, gMinSamples);
            gMaxSamples = MAX(value, gMaxSamples);
         }
      }
   }   
   
   if(gMinSamples == INT_MAX) {
      gMinSamples = 0;
      gMaxSamples = 0;
   }
      
   /* free renderer info */
   CGLDestroyRendererInfo(rend);
}

//////////////////////////

static BOOL requestsBestFormat(Criterion *criteria)
{
   switch(criteria->comparison) {
      case CMP_EQ:
      case CMP_LTE:
            return (1 == criteria->value);
      case CMP_LT:
            return (2 == criteria->value);
   }
   return NO;
}

static int weightForCriterion(Criterion *criteria, int minWeight, int maxWeight)
{
   switch(criteria->comparison) {
      case CMP_EQ:
            return criteria->value;
      case CMP_NEQ:
            return maxWeight - criteria->value;
      case CMP_LT:
      case CMP_LTE:
            return minWeight;
      case CMP_GT:
      case CMP_GTE:
            return maxWeight;
      case CMP_MIN:
            return criteria->value;
   }
   return 0;
}

static NSOpenGLPixelFormat *findMatch(Criterion *criteria, int ncriteria, int mask, BOOL gameMode)
{
   NSOpenGLPixelFormatAttribute	list[64];
   int							i, n;
   int							redWeight = 0, greenWeight = 0, blueWeight = 0, alphaWeight = 0;
   int							redWeightA = 0, greenWeightA = 0, blueWeightA = 0, alphaWeightA = 0;
   
   if((mask & (1 << CI_MODE)) || (mask & (1 << LUMINANCE_MODE)))
      return nil;
   if(!(mask & (1 << RGBA_MODE)))
      return nil;

   /* Build a pixel format attribute list based on criterion weights */   
   n = 0;
   for(i = 0; i < ncriteria; i++) {
      switch(criteria[i].capability) {
         case DOUBLEBUFFER:
               if(weightForCriterion(&criteria[i], 0, 1) > 0)
                  list[n++] = NSOpenGLPFADoubleBuffer;
               break;
         case STEREO:
               if(weightForCriterion(&criteria[i], 0, 1) > 0)
                  list[n++] = NSOpenGLPFAStereo;
               break;
         case AUX_BUFFERS:
               list[n++] = NSOpenGLPFAAuxBuffers;
               list[n++] = weightForCriterion(&criteria[i], 0, gMaxAuxBufs);
               break;
         case RED_SIZE:
               redWeight = weightForCriterion(&criteria[i], 0, gMaxColor);
               break;
         case GREEN_SIZE:
               greenWeight = weightForCriterion(&criteria[i], 0, gMaxColor);
               break;
         case BLUE_SIZE:
               blueWeight = weightForCriterion(&criteria[i], 0, gMaxColor);
               break;
         case ALPHA_SIZE:
               alphaWeight = weightForCriterion(&criteria[i], 0, gMaxAlpha);
               break;
         case DEPTH_SIZE:
               list[n++] = NSOpenGLPFADepthSize;
               list[n++] = weightForCriterion(&criteria[i], gMinDepth, gMaxDepth);
               break;
         case STENCIL_SIZE:
               list[n++] = NSOpenGLPFAStencilSize;
               list[n++] = weightForCriterion(&criteria[i], gMinStencil, gMaxStencil);
               break;
         case ACCUM_RED_SIZE:
               redWeightA = weightForCriterion(&criteria[i], 0, gMaxAccumColor);
               break;
         case ACCUM_GREEN_SIZE:
               greenWeightA = weightForCriterion(&criteria[i], 0, gMaxAccumColor);
               break;
         case ACCUM_BLUE_SIZE:
               blueWeightA = weightForCriterion(&criteria[i], 0, gMaxAccumColor);
               break;
         case ACCUM_ALPHA_SIZE:
               alphaWeightA = weightForCriterion(&criteria[i], 0, gMaxAccumAlpha);
               break;
         case SAMPLES:
               if(weightForCriterion(&criteria[i], gMinSamples, gMaxSamples) > 0) {
                  list[n++] = kCGLPFASampleBuffers; // since app kit does not export these yet
                  list[n++] = 1;
                  list[n++] = kCGLPFASamples; // since app kit does not export these yet
                  list[n++] = weightForCriterion(&criteria[i], gMinSamples, gMaxSamples);
				  list[n++] = NSOpenGLPFANoRecovery;
               }
               break;
         case SLOW:
               if(weightForCriterion(&criteria[i], 0, 1) == 0)
                  list[n++] = NSOpenGLPFAAccelerated;
               break;
         case CONFORMANT:
               if(weightForCriterion(&criteria[i], 0, 1) > 0)
                  list[n++] = NSOpenGLPFACompliant;
               break;
         case NUM:
               /* We only accept framebuffer config 1 (best) */
               if(!requestsBestFormat(&criteria[i]))
                  return nil;
         case NO_RECOVERY:
               if(weightForCriterion(&criteria[i], 0, 1) > 0)
                  list[n++] = NSOpenGLPFANoRecovery;
               break;
         default:
               /* do nothing */
               break;
      }
   }
   if (redWeight || greenWeight || blueWeight || alphaWeight) { // if they are trying to set any color or alpha size
	  list[n++] = NSOpenGLPFAColorSize;
	  if ((redWeight > 5) || (greenWeight > 5) || (blueWeight> 5) || (alphaWeight > 1)) {
		 list[n++] = 32;
	  } else {
		 list[n++] = 16;	
	  }
	  list[n++] = NSOpenGLPFAClosestPolicy;
   }
   if (redWeightA || greenWeightA || blueWeightA || alphaWeightA) { // if they are trying to set any color or alpha size
	  list[n++] = NSOpenGLPFAAccumSize;
	  if ((redWeightA > 8) || (greenWeightA > 8) || (blueWeightA > 8) || (alphaWeightA > 8)) {
		 list[n++] = 64;
	  } else {
		 list[n++] = 32;	
	  }
   }
   if(gameMode)  {
      list[n++] = NSOpenGLPFAScreenMask;
      list[n++] = CGDisplayIDToOpenGLDisplayMask(kCGDirectMainDisplay);
      list[n++] = NSOpenGLPFAColorSize;
      list[n++] = __glutGetCurrentDMDepth ();
      list[n++] = NSOpenGLPFAClosestPolicy; // add any time color depth is used
   }

   list[n] = 0;
   
#ifdef TEST
   __glutDumpPixelFormatAttributes(list);
#endif
   
   return [[[NSOpenGLPixelFormat alloc] initWithAttributes: list] autorelease];
}

///////////////////////////////////

static int parseCriteria(char *word, Criterion *criterion, int *mask, BOOL *allowDoubleAsSingle)
{
   char *	cstr, *vstr, *response;
   int		comparator, value = 0;
   int		rgb, rgba, acc, acca, count, i;
   
   cstr = strpbrk(word, "=><!~");
   if (cstr) {
      switch (cstr[0]) {
         case '=':
            comparator = CMP_EQ;
            vstr = &cstr[1];
            break;
         case '~':
            comparator = CMP_MIN;
            vstr = &cstr[1];
            break;
         case '>':
            if (cstr[1] == '=') {
               comparator = CMP_GTE;
               vstr = &cstr[2];
            } else {
               comparator = CMP_GT;
               vstr = &cstr[1];
            }
            break;
         case '<':
            if (cstr[1] == '=') {
               comparator = CMP_LTE;
               vstr = &cstr[2];
            } else {
               comparator = CMP_LT;
               vstr = &cstr[1];
            }
            break;
         case '!':
            if (cstr[1] == '=') {
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
      if (response == vstr) {
         /* Not a valid number. */
         return -1;
      }
      *cstr = '\0';
   } else {
      comparator = CMP_NONE;
   }
   switch (word[0]) {
      case 'a':
         if (!strcmp(word, "alpha")) {
            criterion[0].capability = ALPHA_SIZE;
            if (comparator == CMP_NONE) {
               criterion[0].comparison = CMP_GTE;
               criterion[0].value = 1;
            } else {
               criterion[0].comparison = comparator;
               criterion[0].value = value;
            }
            *mask |= (1 << RGBA);
            *mask |= (1 << ALPHA_SIZE);
            *mask |= (1 << RGBA_MODE);
            return 1;
         }
         acca = !strcmp(word, "acca");
         acc = !strcmp(word, "acc");
         if (acc || acca) {
            criterion[0].capability = ACCUM_RED_SIZE;
            criterion[1].capability = ACCUM_GREEN_SIZE;
            criterion[2].capability = ACCUM_BLUE_SIZE;
            criterion[3].capability = ACCUM_ALPHA_SIZE;
            if (acca) {
               count = 4;
            } else {
               count = 3;
               criterion[3].comparison = CMP_MIN;
               criterion[3].value = 0;
            }
            if (comparator == CMP_NONE) {
               comparator = CMP_GTE;
               value = 8;
            }
            for (i = 0; i < count; i++) {
               criterion[i].comparison = comparator;
               criterion[i].value = value;
            }
            *mask |= (1 << ACCUM_RED_SIZE);
            return 4;
         }
         if (!strcmp(word, "auxbufs")) {
            criterion[0].capability = AUX_BUFFERS;
            if (comparator == CMP_NONE) {
               criterion[0].comparison = CMP_MIN;
               criterion[0].value = 1;
            } else {
               criterion[0].comparison = comparator;
               criterion[0].value = value;
            }
            *mask |= (1 << AUX_BUFFERS);
            return 1;
         }
         return -1;
      case 'b':
         if (!strcmp(word, "blue")) {
            criterion[0].capability = BLUE_SIZE;
            if (comparator == CMP_NONE) {
               criterion[0].comparison = CMP_GTE;
               criterion[0].value = 1;
            } else {
               criterion[0].comparison = comparator;
               criterion[0].value = value;
            }
            *mask |= (1 << RGBA);
            *mask |= (1 << RGBA_MODE);
            return 1;
         }
         if (!strcmp(word, "buffer")) {
            criterion[0].capability = BUFFER_SIZE;
            if (comparator == CMP_NONE) {
               criterion[0].comparison = CMP_GTE;
               criterion[0].value = 1;
            } else {
               criterion[0].comparison = comparator;
               criterion[0].value = value;
            }
            return 1;
         }
         return -1;
      case 'c':
         if (!strcmp(word, "conformant")) {
            criterion[0].capability = CONFORMANT;
            if (comparator == CMP_NONE) {
               criterion[0].comparison = CMP_EQ;
               criterion[0].value = 1;
            } else {
               criterion[0].comparison = comparator;
               criterion[0].value = value;
            }
            *mask |= (1 << CONFORMANT);
            return 1;
         }
         return -1;
      case 'd':
         if (!strcmp(word, "depth")) {
            criterion[0].capability = DEPTH_SIZE;
            if (comparator == CMP_NONE) {
               criterion[0].comparison = CMP_GTE;
               criterion[0].value = 12;
            } else {
               criterion[0].comparison = comparator;
               criterion[0].value = value;
            }
            *mask |= (1 << DEPTH_SIZE);
            return 1;
         }
         if (!strcmp(word, "double")) {
            criterion[0].capability = DOUBLEBUFFER;
            if (comparator == CMP_NONE) {
               criterion[0].comparison = CMP_EQ;
               criterion[0].value = 1;
            } else {
               criterion[0].comparison = comparator;
               criterion[0].value = value;
            }
            *mask |= (1 << DOUBLEBUFFER);
            return 1;
         }
         return -1;
      case 'g':
         if (!strcmp(word, "green")) {
            criterion[0].capability = GREEN_SIZE;
            if (comparator == CMP_NONE) {
               criterion[0].comparison = CMP_GTE;
               criterion[0].value = 1;
            } else {
               criterion[0].comparison = comparator;
               criterion[0].value = value;
            }
            *mask |= (1 << RGBA);
            *mask |= (1 << RGBA_MODE);
            return 1;
         }
         return -1;
      case 'i':
         if (!strcmp(word, "index")) {
            criterion[0].capability = RGBA;
            criterion[0].comparison = CMP_EQ;
            criterion[0].value = 0;
            *mask |= (1 << RGBA);
            *mask |= (1 << CI_MODE);
            criterion[1].capability = BUFFER_SIZE;
            if (comparator == CMP_NONE) {
               criterion[1].comparison = CMP_GTE;
               criterion[1].value = 1;
            } else {
               criterion[1].comparison = comparator;
               criterion[1].value = value;
            }
            return 2;
         }
         return -1;
      case 'l':
         if (!strcmp(word, "luminance")) {
            criterion[0].capability = RGBA;
            criterion[0].comparison = CMP_EQ;
            criterion[0].value = 1;
            
            criterion[1].capability = RED_SIZE;
            if (comparator == CMP_NONE) {
               criterion[1].comparison = CMP_GTE;
               criterion[1].value = 1;
            } else {
               criterion[1].comparison = comparator;
               criterion[1].value = value;
            }
            
            criterion[2].capability = GREEN_SIZE;
            criterion[2].comparison = CMP_EQ;
            criterion[2].value = 0;
            
            criterion[3].capability = BLUE_SIZE;
            criterion[3].comparison = CMP_EQ;
            criterion[3].value = 0;
            
            *mask |= (1 << RGBA);
            *mask |= (1 << RGBA_MODE);
            *mask |= (1 << LUMINANCE_MODE);
            return 4;
         }
         return -1;
      case 'n':
         if (!strcmp(word, "num")) {
            criterion[0].capability = NUM;
            if (comparator == CMP_NONE) {
               return -1;
            } else {
               criterion[0].comparison = comparator;
               criterion[0].value = value;
               return 1;
            }
         }
         else if(!strcmp(word, "no_recovery")) {
             criterion[0].capability = NO_RECOVERY;
             if (comparator == CMP_NONE) {
                 criterion[0].comparison = CMP_EQ;
                 criterion[0].value = 1;
                 } else {
                     criterion[0].comparison = comparator;
                     criterion[0].value = value;
                     }
             *mask |= (1 << NO_RECOVERY);
             return 1;
             }
         return -1;
      case 'r':
         if (!strcmp(word, "red")) {
            criterion[0].capability = RED_SIZE;
            if (comparator == CMP_NONE) {
               criterion[0].comparison = CMP_GTE;
               criterion[0].value = 1;
            } else {
               criterion[0].comparison = comparator;
               criterion[0].value = value;
            }
            *mask |= (1 << RGBA);
            *mask |= (1 << RGBA_MODE);
            return 1;
         }
         rgba = !strcmp(word, "rgba");
         rgb = !strcmp(word, "rgb");
         if (rgb || rgba) {
            criterion[0].capability = RGBA;
            criterion[0].comparison = CMP_EQ;
            criterion[0].value = 1;
/*   do not add color sizes         
            criterion[1].capability = RED_SIZE;
            criterion[2].capability = GREEN_SIZE;
            criterion[3].capability = BLUE_SIZE;
            criterion[4].capability = ALPHA_SIZE;
            if (rgba) {
               count = 5;
            } else {
               count = 4;
               criterion[4].comparison = CMP_MIN;
               criterion[4].value = 0;
            }
            if (comparator == CMP_NONE) {
               comparator = CMP_GTE;
               value = 1;
            }
            for (i = 1; i < count; i++) {
               criterion[i].comparison = comparator;
               criterion[i].value = value;
            }
*/
            *mask |= (1 << RGBA);
            *mask |= (1 << RGBA_MODE);
            return 1;
         }
         return -1;
      case 's':
         if (!strcmp(word, "stencil")) {
            criterion[0].capability = STENCIL_SIZE;
            if (comparator == CMP_NONE) {
               criterion[0].comparison = CMP_MIN;
               criterion[0].value = 1;
            } else {
               criterion[0].comparison = comparator;
               criterion[0].value = value;
            }
            *mask |= (1 << STENCIL_SIZE);
            return 1;
         }
         if (!strcmp(word, "single")) {
            criterion[0].capability = DOUBLEBUFFER;
            if (comparator == CMP_NONE) {
               criterion[0].comparison = CMP_EQ;
               criterion[0].value = 0;
               *allowDoubleAsSingle = YES;
               *mask |= (1 << DOUBLEBUFFER);
               return 1;
            } else {
               return -1;
            }
         }
         if (!strcmp(word, "stereo")) {
            criterion[0].capability = STEREO;
            if (comparator == CMP_NONE) {
               criterion[0].comparison = CMP_EQ;
               criterion[0].value = 1;
            } else {
               criterion[0].comparison = comparator;
               criterion[0].value = value;
            }
            *mask |= (1 << STEREO);
            return 1;
         }
         if (!strcmp(word, "samples")) {
            criterion[0].capability = SAMPLES;
            if (comparator == CMP_NONE) {
               criterion[0].comparison = CMP_LTE;
               criterion[0].value = 4;
            } else {
               criterion[0].comparison = comparator;
               criterion[0].value = value;
            }
            *mask |= (1 << SAMPLES);
            return 1;
         }
         if (!strcmp(word, "slow")) {
            criterion[0].capability = SLOW;
            if (comparator == CMP_NONE) {
               /* Just "slow" means permit fast visuals, but accept
                  slow ones in preference. Presumably the slow ones
                  must be higher quality or something else desirable. */
               criterion[0].comparison = CMP_GTE;
               criterion[0].value = 0;
            } else {
               criterion[0].comparison = comparator;
               criterion[0].value = value;
            }
            *mask |= (1 << SLOW);
            return 1;
         }
         return -1;
      default:
         return -1;
   }
}

static Criterion *parseModeString(char *mode, int *ncriteria, BOOL *allowDoubleAsSingle, int *pmask)
{
   Criterion *	criteria = NULL;
   int			n = 0, mask = 0, parsed;
   char *		copy, *word;
   
   *allowDoubleAsSingle = NO;
   copy = __glutStrdup(mode);
   /* Attempt to estimate how many criteria entries should be
      needed. */
   n = 0;
   word = strtok(copy, " \t");
   while (word) {
      n++;
      word = strtok(NULL, " \t");
   }
   /* Overestimate by 4 times ("rgba" might add four criteria
      entries) plus add in possible defaults plus space for
      required criteria. */
   criteria = (Criterion *) malloc((4 * n + 30) * sizeof(Criterion));
   if (!criteria) {
      __glutFatalError("out of memory.");
   }
   
   /* Re-copy the copy of the mode string. */
   strcpy(copy, mode);
   
   n = 0;
   word = strtok(copy, " \t");
   while (word) {
      parsed = parseCriteria(word, &criteria[n], &mask, allowDoubleAsSingle);
      if (parsed >= 0) {
         n += parsed;
      } else {
         __glutWarning("Unrecognized display string word: %s (ignoring)\n", word);
      }
      word = strtok(NULL, " \t");
   }
   /* do not add "default" criteria */
/*
   if (!(mask & (1 << SAMPLES))) {
      criteria[n].capability = SAMPLES;
      criteria[n].comparison = CMP_EQ;
      criteria[n].value = 0;
      n++;
   }
   if (!(mask & (1 << ACCUM_RED_SIZE))) {
      criteria[n].capability = ACCUM_RED_SIZE;
      criteria[n].comparison = CMP_MIN;
      criteria[n].value = 0;
      criteria[n + 1].capability = ACCUM_GREEN_SIZE;
      criteria[n + 1].comparison = CMP_MIN;
      criteria[n + 1].value = 0;
      criteria[n + 2].capability = ACCUM_BLUE_SIZE;
      criteria[n + 2].comparison = CMP_MIN;
      criteria[n + 2].value = 0;
      criteria[n + 3].capability = ACCUM_ALPHA_SIZE;
      criteria[n + 3].comparison = CMP_MIN;
      criteria[n + 3].value = 0;
      n += 4;
   }
   if (!(mask & (1 << AUX_BUFFERS))) {
      criteria[n].capability = AUX_BUFFERS;
      criteria[n].comparison = CMP_MIN;
      criteria[n].value = 0;
      n++;
   }
   if (!(mask & (1 << RGBA))) {
      criteria[n].capability = RGBA;
      criteria[n].comparison = CMP_EQ;
      criteria[n].value = 1;
      criteria[n + 1].capability = RED_SIZE;
      criteria[n + 1].comparison = CMP_GTE;
      criteria[n + 1].value = 1;
      criteria[n + 2].capability = GREEN_SIZE;
      criteria[n + 2].comparison = CMP_GTE;
      criteria[n + 2].value = 1;
      criteria[n + 3].capability = BLUE_SIZE;
      criteria[n + 3].comparison = CMP_GTE;
      criteria[n + 3].value = 1;
      criteria[n + 4].capability = ALPHA_SIZE;
      criteria[n + 4].comparison = CMP_MIN;
      criteria[n + 4].value = 0;
      n += 5;
      mask |= (1 << RGBA_MODE);
   }
   if (!(mask & (1 << STEREO))) {
      criteria[n].capability = STEREO;
      criteria[n].comparison = CMP_EQ;
      criteria[n].value = 0;
      n++;
   }
   if (!(mask & (1 << DOUBLEBUFFER))) {
      criteria[n].capability = DOUBLEBUFFER;
      criteria[n].comparison = CMP_EQ;
      criteria[n].value = 0;
      *allowDoubleAsSingle = YES;
      n++;
   }
   if (!(mask & (1 << DEPTH_SIZE))) {
      criteria[n].capability = DEPTH_SIZE;
      criteria[n].comparison = CMP_MIN;
      criteria[n].value = 0;
      n++;
   }
   if (!(mask & (1 << STENCIL_SIZE))) {
      criteria[n].capability = STENCIL_SIZE;
      criteria[n].comparison = CMP_MIN;
      criteria[n].value = 0;
      n++;
   }
*/
   /* Since over-estimated the size needed; squeeze it down to
      reality. */
   criteria = (Criterion *) realloc(criteria, n * sizeof(Criterion));
   if (!criteria) {
      /* Should never happen since should be shrinking down! */
      __glutFatalError("out of memory.");
   }
   
   free(copy);
   *ncriteria = n;
   *pmask = mask;
   return criteria;
}

NSOpenGLPixelFormat *__glutDeterminePixelFormatFromString(char *string, BOOL *treatAsSingle, BOOL gameMode)
{
   Criterion *				criteria;
   NSOpenGLPixelFormat *	pixFmt = nil;
   BOOL						allowDoubleAsSingle;
   int						ncriteria, i, mask;
   
   if(!gWeightsLoaded) {
      loadMinMaxWeights();
      gWeightsLoaded = 1;
   }
   
   criteria = parseModeString(string, &ncriteria, &allowDoubleAsSingle, &mask);
   if (criteria == NULL) {
      __glutWarning("failed to parse mode string");
      return NULL;
   }
#ifdef TEST
   printCriteria(criteria, ncriteria);
#endif
   pixFmt = findMatch(criteria, ncriteria, mask, gameMode);
   if(pixFmt) {
      *treatAsSingle = NO;
   } else {
      if(allowDoubleAsSingle) {
         /* Rewrite criteria so that we now look for a double
            buffered visual which will then get treated as a
            single buffered visual. */
         for(i = 0; i < ncriteria; i++) {
            if(criteria[i].capability == DOUBLEBUFFER
               && criteria[i].comparison == CMP_EQ
               && criteria[i].value == 0) {
                  criteria[i].value = 1;
            }
         }
         pixFmt = findMatch(criteria, ncriteria, mask, gameMode);
         if(pixFmt) {
            *treatAsSingle = YES;
         }
      }
   }
   free(criteria);
   
   return pixFmt;
}

/* CENTRY */
void APIENTRY glutInitDisplayString(const char *string)
{
   if (__glutDisplayString) {
      free(__glutDisplayString);
   }
   if (string) {
      __glutDisplayString = __glutStrdup(string);
      if (!__glutDisplayString)
         __glutFatalError("out of memory.");
   } else {
      __glutDisplayString = NULL;
   }
}
/* ENDCENTRY */
