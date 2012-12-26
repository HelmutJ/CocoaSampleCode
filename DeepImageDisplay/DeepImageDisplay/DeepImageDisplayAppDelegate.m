/*
     File: DeepImageDisplayAppDelegate.m 
 Abstract: The application delegate class used for installing the navigation controller. 
  Version: 1.0 
  
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple 
 Inc. ("Apple") in consideration of your agreement to the following 
 terms, and your use, installation, modification or redistribution of 
 this Apple software constitutes acceptance of these terms.  If you do 
 not agree with these terms, please do not use, install, modify or 
 redistribute this Apple software. 
  
 In consideration of your agreement to abide by the following terms, and 
 subject to these terms, Apple grants you a personal, non-exclusive 
 license, under Apple's copyrights in this original Apple software (the 
 "Apple Software"), to use, reproduce, modify and redistribute the Apple 
 Software, with or without modifications, in source and/or binary forms; 
 provided that if you redistribute the Apple Software in its entirety and 
 without modifications, you must retain this notice and the following 
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Inc. may 
 be used to endorse or promote products derived from the Apple Software 
 without specific prior written permission from Apple.  Except as 
 expressly stated in this notice, no other rights or licenses, express or 
 implied, are granted by Apple herein, including but not limited to any 
 patent rights that may be infringed by your derivative works or by other 
 works in which the Apple Software may be incorporated. 
  
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE 
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION 
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS 
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND 
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS. 
  
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL 
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, 
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED 
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), 
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE 
 POSSIBILITY OF SUCH DAMAGE. 
  
 Copyright (C) 2012 Apple Inc. All Rights Reserved. 
  
 */

#import "DeepImageDisplayAppDelegate.h"
#import "CustomView.h"

/* Use class extension to hide API that doesn't yet need to be exposed.
 */
@interface DeepImageDisplayAppDelegate() {
    NSWindow *deepWindow;
    NSWindow *standardWindow;
    CustomView *deepView;
    CustomView *standardView;
    NSImage* sourceImage;
}

@property (assign) IBOutlet NSWindow *deepWindow;
@property (assign) IBOutlet NSWindow *standardWindow;
@property (assign) IBOutlet CustomView *deepView;
@property (assign) IBOutlet CustomView *standardView;
@property (retain) NSImage* sourceImage;

@end

@implementation DeepImageDisplayAppDelegate

@synthesize deepWindow, standardWindow, deepView, standardView, sourceImage;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    // set the window depth limit to 64-bit (16-16-16-16 RGBA).
    deepWindow.depthLimit = NSWindowDepthSixtyfourBitRGB;
    
    // load the source image and pass it to our windows/views - 
    self.sourceImage = [NSImage imageNamed:@"16bit_gradient.png"];
    // pass the image to the windows/views
    deepView.image = sourceImage;
    standardView.image = sourceImage;
    // queue the views to redraw on the next iteration of the run loop
    [deepView setNeedsDisplay:YES];
    [standardView setNeedsDisplay:YES];
    
    
    // size and move the windows to fit the screen - 
    NSSize windowSize = NSMakeSize( [NSScreen mainScreen].frame.size.width / 2, [NSScreen mainScreen].frame.size.height * .85 );    
    // move the standard window to the right side of the screen
    [standardWindow setFrame: NSMakeRect( [NSScreen mainScreen].frame.size.width - windowSize.width, [NSScreen mainScreen].frame.size.height - 50.0f, windowSize.width, windowSize.height ) display:YES];
    // move the deep window to the left side of the screen
    [deepWindow setFrame: NSMakeRect( 0.0f, [NSScreen mainScreen].frame.size.height - 50.0f, windowSize.width, windowSize.height ) display:YES];
    
    // for sample code purposes: disable the window close buttons. Keep all windows open until the user Quits.
    [[deepWindow standardWindowButton:NSWindowCloseButton] setEnabled:NO];
    [[standardWindow standardWindowButton:NSWindowCloseButton] setEnabled:NO];
    
    // while debugging thru Xcode make the windows floating. Otherwise, one window is placed behind Xcode. 
#ifdef DEBUG
    [deepWindow setLevel:NSFloatingWindowLevel]; 
    [standardWindow setLevel:NSFloatingWindowLevel]; 
#endif

}

// release ownership
-(void)dealloc {
    [sourceImage release];
    //--
    [super dealloc];
}

@end
