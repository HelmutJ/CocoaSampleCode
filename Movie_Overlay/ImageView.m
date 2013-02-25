 /*

File: ImageView.m

Abstract: Our ImageView class. This NSView is a subView of our overlay 
			window which we use to draw an image.

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


#import "ImageView.h"

@implementation ImageView


//////////
//
// imageInit
//
// Locate our image file and create an NSImage for it. Also, create
// a string which we'll use to draw in our view.
//
//////////

-(void) imageInit
{
    // create an NSImage for our image file
	NSString *filePath = [[NSBundle mainBundle] pathForResource:@"USA" ofType:@"gif"];
	drawImage = [[NSImage alloc] initWithContentsOfFile:filePath];
    
    // Set up attributed text which we will draw into our view
    NSFont *font = [NSFont fontWithName:@"Helvetica" size:36.0];
    NSMutableDictionary *attrs = [NSMutableDictionary dictionary];

    [attrs setObject:font forKey:NSFontAttributeName];
    [attrs setObject:[NSColor greenColor]
           forKey:NSForegroundColorAttributeName];

    textString = [ [NSMutableAttributedString alloc]
              initWithString:@"Text Here"
                  attributes:attrs];

}


//////////
//
// initWithFrame
//
// Initialize our NSView with frameRect
//
//////////

- (id)initWithFrame:(NSRect)frameRect
{
	id view = [super initWithFrame:frameRect];

	[self imageInit];

	return view;
}

//////////
//
// initWithCoder
//
// Initializes a newly allocated NSView instance from data in aDecoder.
//
//////////

- (id)initWithCoder:(NSCoder *)aDecoder
{
	id view = [super initWithCoder:aDecoder];

	[self imageInit];

	return view;
}


//////////
//
// drawRect
//
// Draw our image & text string to the view
//
//////////

- (void)drawRect:(NSRect)rect
{
	[[NSColor whiteColor] set];
	NSRectFill([self bounds]);

	[drawImage compositeToPoint:NSMakePoint(60,30) operation:NSCompositeSourceOver];

	[textString drawAtPoint:NSMakePoint(50,5)];
}

//////////
//
// dealloc
//
// cleanup
//
//////////

- (void)dealloc
{
    [textString release];
    [drawImage release];
    
    [super dealloc];
}

@end
