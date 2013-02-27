/*
  
  File: MyView.m
  
  Abstract: MyView subclass implementation.
  
  Version: <1.0>
  
  Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
  Computer, Inc. ("Apple") in consideration of your agreement to the
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
  Neither the name, trademarks, service marks or logos of Apple Computer,
  Inc. may be used to endorse or promote products derived from the Apple
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
  
  Copyright © 2006 Apple Computer, Inc., All Rights Reserved
  
*/   
 
#import "MyView.h"
#import "AppDrawing.h"

@implementation MyView

DrawingCommand _drawingCommand = kCommandStrokedAndFilledRects;

CGPDFDocumentRef _pdfDocument;

- (id)initWithFrame:(NSRect)frameRect
{
    if ((self = [super initWithFrame:frameRect]) != nil) {
	    // Add initialization code here.
    }
    return self;
}


- (void)drawRect:(NSRect)rect
{
	// Obtain the Quartz context from the current NSGraphicsContext at the time the view's
	// drawRect method is called. This context is only appropriate for drawing in this invocation
	// of the drawRect method.
	CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
		
	myDispatchDrawing(context, _drawingCommand);
}

- (IBAction)setDrawCommand:(id)sender
{
    DrawingCommand newCommand = [ sender tag ];
    if(_drawingCommand != newCommand){
	    _drawingCommand = newCommand;
	    // The view needs to be redisplayed since there is a new drawing command.
	    [self setNeedsDisplay:YES];

	    // Disable previous menu item.
	    [currentMenuItem setState:NSOffState];

	    // Update the current item.
	    currentMenuItem = sender;

	    // Enable new menu item.
	    [currentMenuItem setState:NSOnState];
	    
	    // If we were showing a pasted document, let's get rid of it.
    }
}

- (int)currentPrintableCommand
{
    // The best representation for printing or exporting
    // when the current command caches using a bitmap context
    // or a layer is to not do any caching.
    if(	_drawingCommand == kCommandDoCGLayer )
	return kCommandDoUncachedDrawing;
    
    return _drawingCommand;
}


- (IBAction)print:(id)sender {
    int savedDrawingCommand = _drawingCommand;
    // Set the drawing command to be one that is printable.
    _drawingCommand = [self currentPrintableCommand];
    // Do the printing operation on the view.
    [[NSPrintOperation printOperationWithView:self] runOperation];
    // Restore that before the printing operation. 
    _drawingCommand = savedDrawingCommand;
}


// Return the number of pages available for printing. For this
// application it is always 1.
- (BOOL)knowsPageRange:(NSRangePointer)range {
    range->location = 1;
    range->length = 1;
    return YES;
}

// Return the drawing rectangle for a particular page number.
// For this application it is always the page width and height.
- (NSRect)rectForPage:(int)page {
    NSPrintInfo *pi = [[NSPrintOperation currentOperation] printInfo];
    // Calculate the page height in points.
    NSSize paperSize = [pi paperSize];
    return NSMakeRect( 0, 0, paperSize.width, paperSize.height );
}

- (BOOL)validateMenuItem: (id <NSMenuItem>)menuItem
{
    if ([menuItem tag] == _drawingCommand){
		currentMenuItem = menuItem;
		[menuItem setState: YES];
	}else
		[menuItem setState: NO];
	
	return YES;
}

@end
