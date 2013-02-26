//
// File:       GLUTApplication.m
//
// Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc. ("Apple")
//             in consideration of your agreement to the following terms, and your use,
//             installation, modification or redistribution of this Apple software
//             constitutes acceptance of these terms.  If you do not agree with these
//             terms, please do not use, install, modify or redistribute this Apple
//             software.
//
//             In consideration of your agreement to abide by the following terms, and
//             subject to these terms, Apple grants you a personal, non - exclusive
//             license, under Apple's copyrights in this original Apple software ( the
//             "Apple Software" ), to use, reproduce, modify and redistribute the Apple
//             Software, with or without modifications, in source and / or binary forms;
//             provided that if you redistribute the Apple Software in its entirety and
//             without modifications, you must retain this notice and the following text
//             and disclaimers in all such redistributions of the Apple Software. Neither
//             the name, trademarks, service marks or logos of Apple Inc. may be used to
//             endorse or promote products derived from the Apple Software without specific
//             prior written permission from Apple.  Except as expressly stated in this
//             notice, no other rights or licenses, express or implied, are granted by
//             Apple herein, including but not limited to any patent rights that may be
//             infringed by your derivative works or by other works in which the Apple
//             Software may be incorporated.
//
//             The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
//             WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
//             WARRANTIES OF NON - INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A
//             PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION
//             ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
//
//             IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
//             CONSEQUENTIAL DAMAGES ( INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//             SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//             INTERRUPTION ) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION
//             AND / OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER
//             UNDER THEORY OF CONTRACT, TORT ( INCLUDING NEGLIGENCE ), STRICT LIABILITY OR
//             OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// Copyright ( C ) 2000-2008 Apple Inc. All Rights Reserved.
//

#import "macx_glut.h"
#import "GLUTApplication.h"
#import "GLUTView.h"
#import "GLUTWindow.h"
#import "GLUTPreferencesController.h"


// time interval between idle callouts while menu tracking
NSTimeInterval					__glutIdleTimeInterval = GLUT_DEFAULT_IDLE_INTERVAL;
static CFRunLoopTimerRef	__glutIdleFuncTimer = NULL;
static BOOL						__glutIdleFuncCalled = NO;


static void __glutStopIdleFuncTimer(CFRunLoopTimerRef timer)
{
   CFRunLoopTimerInvalidate(timer);
   CFRelease(timer);
   __glutIdleFuncTimer = NULL;
}

static void __glutIdleTimerCallBack(CFRunLoopTimerRef timer, void *context) 
{
   if(!__glutIdleFuncCalled && __glutIdleFunc) {
      __glutProcessWorkEvents();
      __glutIdleFunc();
   } else {
      __glutStopIdleFuncTimer(timer);
   }
}

void __glutStartIdleFuncTimer(void)
{
   /* This is only relevant if the GLUT app has installed an idle function.. */
   if(__glutIdleFunc && __glutIdleFuncTimer == NULL) {
      CFRunLoopTimerContext	timerCtxt;
      
      memset(&timerCtxt, 0, sizeof(CFRunLoopTimerContext));
      
      __glutIdleFuncTimer = CFRunLoopTimerCreate(NULL,
                           CFAbsoluteTimeGetCurrent(),
                           __glutIdleTimeInterval, // interval
                           0,		 // flags
                           0,		 // order
                           (CFRunLoopTimerCallBack)__glutIdleTimerCallBack,
                           &timerCtxt);
      if(__glutIdleFuncTimer) {
         CFRunLoopAddTimer(CFRunLoopGetCurrent(), __glutIdleFuncTimer, kCFRunLoopCommonModes);
         __glutIdleFuncCalled = NO;
      }
   }
}


@implementation GLUTApplication

- (id)init
{
   if((self = [super init]) != nil) {
      _distantFuture = [[NSDate distantFuture] retain];
      _distantPast = [[NSDate distantPast] retain];
      [self setDelegate: self];
      return self;
   }
   return nil;
}

- (void)dealloc
{
   [[NSNotificationCenter defaultCenter] removeObserver: self];
   [_distantPast release];
   [_distantFuture release];
   [super dealloc];
}

- (void)finalize
{
   [[NSNotificationCenter defaultCenter] removeObserver: self];
   [super finalize];
}


- (void)_runMainLoopUntilDate: (NSDate *)limitDate autoreleasePool: (NSAutoreleasePool **)pool
{
   for(;;) {
      NSEvent *	event = [self	nextEventMatchingMask: NSAnyEventMask
                                 untilDate: limitDate
                                 inMode: NSDefaultRunLoopMode
                                 dequeue: YES];
                                 
      if(event == nil)
         break;
         
      [self sendEvent: event];
      if(![self isRunning])
         break;
            
      [*pool release];
      *pool = [[NSAutoreleasePool alloc] init];
      
      /* The first call to -nextEventMatchingMask: above may block until the
         next timer is due or until a user event arrives from the WindowServer.
         All following calls, however, may never block. This is why we switch
         the limitDate to _distantPast. That way we will consume all events
         which have been queued so far and return to the main event loop after
         that. This also guruantees that all queued work events get processed
         as soon as possible. */
      if(limitDate != _distantPast)
         limitDate = _distantPast;
   }
}

- (void)run
{
   NSAutoreleasePool *	pool = [[NSAutoreleasePool alloc] init];
   NSRunLoop *				runLoop = [[NSRunLoop currentRunLoop] retain];
   
   [self finishLaunching];
   __glutEnableVisibilityUpdates();
   /* XXX Argh: We must mark the app as running by hand because
      XXX       -finishLaunching above doesn't automatically do
      XXX       this for us. Neither is there any public API
      XXX       which would give us a way to mark the app as
      XXX       running... */
   _running = 1;
   
   while([self isRunning]) {
      __glutProcessWorkEvents();

      /* Process all pending user events and fire all timers which have
         a fire date before or equal to the current system time. */
      if(__glutIdleFunc || __glutHasWorkEvents()) {
         /* IMPORTANT: This case may _never_ block. */
         [self _runMainLoopUntilDate: _distantPast autoreleasePool: &pool];
         if(__glutIdleFunc) {
            __glutIdleFuncCalled = YES;
            __glutIdleFunc();
         }
      } else {
         /* IMPORTANT: We may either block until the next timer in line is
                       due, or until a new user event arives from the
                       WindowServer. */
         NSDate *	limitDate = [runLoop limitDateForMode: NSDefaultRunLoopMode];
         
         [self _runMainLoopUntilDate: limitDate autoreleasePool: &pool];
      }
      
      [pool drain];
      pool = [[NSAutoreleasePool alloc] init];
   }
   [runLoop release];
   [pool drain];
}

- (void)runOnce
{
   NSAutoreleasePool *	pool = [[NSAutoreleasePool alloc] init];
   NSRunLoop *				runLoop = [[NSRunLoop currentRunLoop] retain];
   
   if(_running != 1) {
      [self finishLaunching];
      __glutEnableVisibilityUpdates();
      _running = 1;
   }
   
   __glutProcessWorkEvents();
   /* Process all pending user events and fire all timers which have
      a fire date before or equal to the current system time. */
   if(__glutIdleFunc || __glutHasWorkEvents()) {
      /* IMPORTANT: This case may _never_ block. */
      [self _runMainLoopUntilDate: _distantPast autoreleasePool: &pool];
      if(__glutIdleFunc) {
         __glutIdleFuncCalled = YES;
         __glutIdleFunc();
      }
   } else {
      /* IMPORTANT: We may either block until the next timer in line is
                     due, or until a new user event arives from the
                     WindowServer. */
      NSDate *	limitDate = [runLoop limitDateForMode: NSDefaultRunLoopMode];
      
      [self _runMainLoopUntilDate: limitDate autoreleasePool: &pool];
   }
   [runLoop release];
   [pool drain];
}

- (void)_readMouseConfiguration
{
//   NSDictionary *	defaults;
//   int				preset;
   unsigned int	middleFlags = NSAlternateKeyMask, rightFlags = NSControlKeyMask;
#if 0 // ggs: fix me   
   defaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName: GLUTPreferencesName];
   if(defaults == nil) {
      defaults = [NSDictionary dictionaryWithObjectsAndKeys:
                     [NSNumber numberWithInt: kGLUTMousePresetLegacy], GLUTMousePresetKey,
                     [NSNumber numberWithUnsignedInt: 0], GLUTMouseCustomMiddleModifiersKey,
                     [NSNumber numberWithUnsignedInt: 0], GLUTMouseCustomRightModifiersKey,
                     nil];
      [[NSUserDefaults standardUserDefaults] setPersistentDomain: defaults
                                             forName: GLUTPreferencesName];
   }
   preset = [[defaults objectForKey: GLUTMousePresetKey] intValue];
   
   switch(preset) {
      case kGLUTMousePresetLegacy:   /* M:Alt, R:Ctrl */
            middleFlags = NSAlternateKeyMask;
            rightFlags = NSControlKeyMask;
            break;
            
      case kGLUTMousePresetControl:  /* M:Ctrl+Alt, R:Ctrl */
            middleFlags = NSControlKeyMask | NSAlternateKeyMask;
            rightFlags = NSControlKeyMask;
            break;
            
      case kGLUTMousePresetCommand:  /* M:Cmd+Alt, R:Cmd */
            middleFlags = NSCommandKeyMask | NSAlternateKeyMask;
            rightFlags = NSCommandKeyMask;
            break;
            
      case kGLUTMousePresetCustom:    /* M:MiddleKey, R:RightKey */
            middleFlags = [[defaults objectForKey: GLUTMouseCustomMiddleModifiersKey] unsignedIntValue];
            rightFlags = [[defaults objectForKey: GLUTMouseCustomRightModifiersKey] unsignedIntValue];
            break;
   }
 #endif  
   __glutSetMouseModifiers(middleFlags, rightFlags);
}

- (void)applicationWillFinishLaunching: (NSNotification *)notification
{
	NSPrintInfo *		printInfo = [NSPrintInfo sharedPrintInfo];
   NSString *			appName = [[NSProcessInfo processInfo] processName];
   NSMutableString *	title = nil;
   
   _isPackaged = __glutIsPackagedApp();
   
      // Update About <x>, Hide <x> and Quit <x> menu items
   title = [[_aboutMenuItem title] mutableCopy];
   [title replaceCharactersInRange: [title rangeOfString: @"X"] withString: appName];
   [_aboutMenuItem setTitle: title];
   [title release];
   
   title = [[_hideMenuItem title] mutableCopy];
   [title replaceCharactersInRange: [title rangeOfString: @"X"] withString: appName];
   [_hideMenuItem setTitle: title];
   [title release];
   
   title = [[_quitMenuItem title] mutableCopy];
   [title replaceCharactersInRange: [title rangeOfString: @"X"] withString: appName];
   [_quitMenuItem setTitle: title];
   [title release];
   
		// Setup shared print info
	[printInfo setHorizontalPagination: NSFitPagination];
	[printInfo setVerticalPagination: NSFitPagination];
   
      // Update mouse modifier flags caches
   [self _readMouseConfiguration];   
}

- (void)applicationWillHide:(NSNotification *)notification
{
   NSArray *		windows = [NSApp windows];
   unsigned			i, count = [windows count];
   
   // gather all currently visible GLUT windows
   _viewStorage = [[NSMutableSet alloc] initWithCapacity: count];
   for(i = 0; i < count; i++) {
      NSWindow *	curWindow = [windows objectAtIndex: i];
      
      if([curWindow isVisible] && [curWindow isKindOfClass: [GLUTWindow class]]) {
         GLUTView *	curView = (GLUTView *) [curWindow contentView];
         
         [curView setShown: NO];
         [_viewStorage addObject: curView];
      }
   }
}

- (void)applicationDidHide: (NSNotification *)notification
{
   [GLUTView evaluateVisibilityOfViews: _viewStorage];
   [_viewStorage release];
   _viewStorage = nil;
}

- (void)applicationWillTerminate: (NSNotification *)notification
{
   glutIdleFunc(NULL);
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
   if((NSMenuItem *)menuItem == _aboutMenuItem && !_isPackaged) {
      return NO;
   }
   return [super validateMenuItem: (NSMenuItem *)menuItem];
}

@end
