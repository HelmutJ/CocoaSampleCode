//
// File:       galaxies.mm
//
// Abstract:   This example performs an NBody simulation which calculates a gravity field 
//             and corresponding velocity and acceleration contributions accumulated 
//             by each body in the system from every other body.  This example
//             also shows how to mitigate computation between all available devices
//             including CPU and GPU devices.
//
// Version:    <1.0>
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
// Copyright ( C ) 2008 Apple Inc. All Rights Reserved.
//

////////////////////////////////////////////////////////////////////////////////

#import "nbody.h"
#import "constants.h"
#import "GalaxiesView.h"

@implementation GalaxiesView

- (void) savePrefs
{
    NSDictionary *prefs;

    prefs=[[NSDictionary alloc] initWithObjectsAndKeys:
        [NSNumber numberWithBool:fullscreen],           @"fullScreen",
        [NSNumber numberWithInt:init_mode],             @"initMode",
        [NSNumber numberWithInt:init_demo],             @"initDemo",
        [NSNumber numberWithFloat:star_scale],          @"starScale",
        [NSNumber numberWithBool:show_hud],             @"showHUD",
        [NSNumber numberWithBool:show_updates_meter],   @"showUpdates",
        [NSNumber numberWithBool:show_fps_meter],       @"showFramerate",
        [NSNumber numberWithBool:show_gflops_meter],    @"showGigaflops",
        [NSNumber numberWithBool:show_dock],            @"showDock",
        nil];

    [[NSUserDefaults standardUserDefaults]
        removePersistentDomainForName:kBundleIdentifier];

    [[NSUserDefaults standardUserDefaults] setPersistentDomain:prefs
        forName:kBundleIdentifier];

    [prefs release];
}

- (void)prepareOpenGL
{
    NSDictionary *overrides = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
    NSDictionary *prefs = [[NSUserDefaults standardUserDefaults] persistentDomainForName:kBundleIdentifier];
    id obj = nil;

    if(nil == (obj = [overrides objectForKey:@"fullScreen"]))
        obj = [prefs objectForKey:@"fullScreen"];
    fullscreen = obj ? [obj boolValue] : YES;

    if(nil == (obj = [overrides objectForKey:@"initMode"]))
        obj = [prefs objectForKey:@"initMode"];
    init_mode = obj ? [obj intValue] : 0;

    if(nil == (obj = [overrides objectForKey:@"initDemo"]))
        obj = [prefs objectForKey:@"initDemo"];
    init_demo = obj ? [obj intValue] : 1;

    if(nil == (obj = [overrides objectForKey:@"starScale"]))
        obj = [prefs objectForKey:@"starScale"];
    star_scale = obj ? [obj floatValue] : 1.0f;

    if(nil == (obj = [overrides objectForKey:@"showHUD"]))
        obj = [prefs objectForKey:@"showHUD"];
    show_hud = obj ? [obj boolValue] : YES;

    if(nil == (obj = [overrides objectForKey:@"showUpdates"]))
        obj = [prefs objectForKey:@"showUpdates"];
    show_updates_meter = obj ? [obj boolValue] : NO;

    if(nil == (obj = [overrides objectForKey:@"showFramerate"]))
        obj = [prefs objectForKey:@"showFramerate"];
    show_fps_meter = obj ? [obj boolValue] : NO;

    if(nil == (obj = [overrides objectForKey:@"showGigaflops"]))
        obj = [prefs objectForKey:@"showGigaflops"];
    show_gflops_meter = obj ? [obj boolValue] : YES;

    if(nil == (obj = [overrides objectForKey:@"showDock"]))
        obj = [prefs objectForKey:@"showDock"];
    show_dock = obj ? [obj boolValue] : YES;

    [self savePrefs];

    if(init_mode < 0) init_mode = 0;
    if(init_mode > 6) init_mode = 6;

    if(init_demo < 0) init_demo = 0;
    if(init_demo > 6) init_demo = 6;

    InitDefaults(init_demo, star_scale, show_hud, show_updates_meter, show_fps_meter, show_gflops_meter, show_dock);
    InitGalaxies(init_mode);
    ResizeCallback([self bounds].size.width, [self bounds].size.height);
    
    [NSTimer scheduledTimerWithTimeInterval:0.0
                                     target:self
                                   selector:@selector(idle)
                                   userInfo:nil
                                    repeats:YES];


    GLint vsync = 1;
    [[self openGLContext] setValues:&vsync forParameter:NSOpenGLCPSwapInterval];  
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (BOOL)isOpaque
{
    return YES;
}

- (void)idle
{
    if(!show_dock)
        EnableDock([NSEvent mouseLocation].y <= 120);
        
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)r
{
    if (![self isInFullScreenMode] && fullscreen)
    {
        [self enterFullScreenMode:[NSScreen mainScreen] withOptions:nil];
        ResizeCallback([self bounds].size.width, [self bounds].size.height);
    }
    
    DisplayCallback();
}

- (void)keyDown:(NSEvent *)e
{
    NSString *s = [e charactersIgnoringModifiers];
    if (s != nil)
    {
        unichar c = [s characterAtIndex:0];
        KeyboardCallback(c, 0, 0);
    }
}

- (void)mouseDown:(NSEvent *)e
{
    NSPoint where = [e locationInWindow];
    MouseClickCallback(MOUSE_LEFT_BUTTON, MOUSE_DOWN, where.x, [self bounds].size.height - where.y);
}

- (void)mouseUp:(NSEvent *)e
{
    NSPoint where = [e locationInWindow];
    MouseClickCallback(MOUSE_LEFT_BUTTON, MOUSE_UP, where.x, [self bounds].size.height - where.y);
}

- (void)mouseDragged:(NSEvent *)e
{
    NSPoint where = [e locationInWindow];
    MouseMovementCallback(where.x, 1080 - where.y);
}

- (void)scrollWheel:(NSEvent *)e
{
    ScrollCallback([e deltaY]);
}

@end
