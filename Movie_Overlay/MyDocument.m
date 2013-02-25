 /*

File: MyDocument.m

Abstract: NSDocument subclass. Displays a QTMovieView with a movie in
		  the main window. Creates an overlay window which will be 
		  attached as a child window to our main window. We will create
		  it directly on top of our main window, so when we draw things
		  they will appear on top of our playing movie.

Version: 1.1

Disclaimer: IMPORTANT:  This Apple software is supplied to you by 
Apple Inc. ("Apple") in consideration of your agreement to the
following terms, and your use, installation, modification or
redistribution of this Apple software constitutes acceptance of these
terms.  If you do not agree with these terms, please do not use,
install, modify or redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and
subject to these terms, Apple grants you a personal, non-exclusive
license, under Apple's copyrights in this original Apple software (the
"Apple Software"), to use, reproduce, modify and redistribute the Apple
Software, with or without modifications, in source and/or binary forms;
provided that if you redistribute the Apple Software in its entirety and
without modifications, you must retain this notice and the following
text and disclaimers in all such redistributions of the Apple Software. 
Neither the name, trademarks, service marks or logos of Apple Inc. 
may be used to endorse or promote products derived from the Apple
Software without specific prior written permission from Apple.  Except
as expressly stated in this notice, no other rights or licenses, express
or implied, are granted by Apple herein, including but not limited to
any patent rights that may be infringed by your derivative works or by
other works in which the Apple Software may be incorporated.

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

Copyright (C) 2003-2008 Apple Inc. All Rights Reserved.

*/

#import "MyDocument.h"

@implementation MyDocument

- (id)init
{
    self = [super init];
    if (self) {
    
        // Add your subclass-specific initialization here.
        // If an error occurs here, send a [self release] message and return nil.
    
    }
    return self;
}

//////////
//
// performAnimation
//
// Called by our timer to keep our animation
// going. We simply mark our animation NSView
// as needing display, which will cause the
// drawRect routine for the view to be called.
//
//////////

- (void)performAnimation:(NSTimer *)aTimer 
{
    // mark our animation NSView as needing display
	[myAnimationView setNeedsDisplay:YES];
}

- (NSString *)windowNibName
{
	// Override returning the nib file name of the document
	// If you need to use a subclass of NSWindowController 
	// or if your document supports multiple NSWindowControllers, 
	// you should remove this method and override -makeWindowControllers 
	// instead.
	return @"MyDocument";
}

//
// windowControllerDidLoadNib
//
// Be notified that a window controller will or did load a nib with this 
// document as the nib file's owner. 
//
// We will use this opportunity to instantiate a document with either
// a default movie or the movie previously set with setFileURL:
//

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];

    // If movie wasn't chosen via File menu then instantiate a default one.
    if (!mMovie)
    {
        // Use the project default movie to instantiate a QTMovie.
        NSString *path = [[NSBundle mainBundle] pathForResource: @"Sample" ofType:@"mov"];
        mMovie = [QTMovie movieWithFile:path error:nil];
        [mMovie retain];
        // Mark the movie as not editable
        [mMovie setAttribute:[NSNumber numberWithBool:NO] forKey:QTMovieEditableAttribute];
    }

    // Set the QTMovie on the View for display.
    [mMovieView setMovie:mMovie];
	
    // Hide the window's resize indicator so it does not
    // interfere with the movie controller.
    [[mMovieView window] setShowsResizeIndicator:NO];

	// NOTE: the following code to move the window to the
	// front of the screen list is necessary on Mac OS X 10.4 
	// Tiger to ensure the overlay window is drawn at the 
	// correct origin when created (see below)
	[[mMovieView window] makeKeyAndOrderFront:self];

	NSPoint baseOrigin, screenOrigin;
	baseOrigin = NSMakePoint([mMovieView frame].origin.x,
								[mMovieView frame].origin.y);

    // convert our QTMovieView coords from local coords to screen coords
    // which we'll use when creating our NSWindow below
	screenOrigin = [[mMovieView window] convertBaseToScreen:baseOrigin];

    // Create an overlay window which will be attached as a child 
    // window to our main window. We will create it directly on top 
    // of our main window, so when we draw things they will appear
    // on top of our playing movie  
    overlayWindow=[[NSWindow alloc] initWithContentRect:NSMakeRect(screenOrigin.x,screenOrigin.y,
		[mMovieView frame].size.width,
		[mMovieView frame].size.height) 
		styleMask:NSBorderlessWindowMask 
		backing:NSBackingStoreBuffered 
		defer:YES];
    [overlayWindow setOpaque:NO];
    [overlayWindow setHasShadow:YES];
    
    // specify we can click through the to
    // the window underneath.
    [overlayWindow setIgnoresMouseEvents:YES];
    [overlayWindow setAlphaValue:0.3];

    NSRect	movieViewBounds, subViewRect;

    movieViewBounds = [mMovieView bounds];
    // our imaging NSView will occupy the upper portion
    // of our underlying QTMovieView space
    subViewRect = NSMakeRect(movieViewBounds.origin.x,
                                movieViewBounds.origin.y + movieViewBounds.size.height/2,
                                movieViewBounds.size.width,
                                movieViewBounds.size.height/2);
    // create a subView for drawing images
	myImageView = [[ImageView alloc] initWithFrame:subViewRect];
    [[overlayWindow contentView] addSubview:myImageView];
    
    // our animation NSView will occupy the lower portion
    // of our underlying QTMovieView space
    subViewRect = NSMakeRect(movieViewBounds.origin.x,
                                movieViewBounds.origin.y,
                                movieViewBounds.size.width,
                                movieViewBounds.size.height/2);
    // create a subview for performing animation
	myAnimationView = [[AnimationView alloc] initWithFrame:subViewRect];
    [[overlayWindow contentView] addSubview:myAnimationView];

    [overlayWindow orderFront:self];
    
    // add our overlay window as a child window of our main window
    [[mMovieView window] addChildWindow:overlayWindow ordered:NSWindowAbove];

    // mark our image NSView as needing display - this will cause its
    // drawRect routine to get invoked
	[myImageView setNeedsDisplay:YES];

    // We schedule a timer with a 0 time interval so that it will be called
    // as often as possible.  In performAnimation: we mark our animation NSView
    // as needing display.
    drawTimer = [[NSTimer scheduledTimerWithTimeInterval:0.0 
		target:self selector:@selector(performAnimation:) 
		userInfo:nil 
		repeats:YES] retain];
}

//
// readFromURL
//
// Sets the contents of this document by reading from a 
// file or file package, of a specified type, located by a URL
// and return YES if successful.
//
- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
    mMovie = [QTMovie movieWithURL:absoluteURL error:NULL];
    if (mMovie)
    {
        [mMovie retain];
        
        // Mark the movie is "editable", so any editing operations, such as like cut, copy, paste will work.
        [mMovie setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieEditableAttribute];

        return YES;
    }
	
    return NO;
}

//
// validateMenuItem
//
// Enable/Disable menu items as appropriate 
// 
// 

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {

    // A few menu item's names change between starting with "Show" and "Hide."
    SEL action = [menuItem action];
    if ((action==@selector(saveDocument:)) || (action==@selector(saveDocumentAs:)) || (action==@selector(printDocument:))
        || (action==@selector(runPageLayout:)) || (action==@selector(revertDocumentToSaved:)) ||
        (action==@selector(cut:)) || (action==@selector(copy:))) 
    {
        return NO;
    }
    else
    {
        return YES;
    }

}



//
// dealloc
//
// Perform cleanup
//

-(void)dealloc
{
    if (mMovie)
    {
        // remove timer
        [drawTimer invalidate];
        // free the movie
        [mMovie release];
    }
		
    [super dealloc];
}


@end
