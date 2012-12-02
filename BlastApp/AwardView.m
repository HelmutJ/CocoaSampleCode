/*
     File: AwardView.m
 Abstract: AwardView. View which creates and draws (just for printing purposes) the BlastApp certificate of completion.
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


#import "AwardView.h"
#import <Cocoa/Cocoa.h>


@implementation AwardView

static NSBitmapImageRep *helicopterBitmap = nil;

- (BOOL)getUserName {
    NSString *name = NSFullUserName();
    if (name == nil || [name isEqual:@""]) name = NSUserName();

    if (nameField == nil) {	// Haven't loaded the nib yet...
        if (![NSBundle loadNibNamed:@"UserName.nib" owner:self]) {
            return NO;
	}
    }

    [nameField setStringValue:name != nil ? name : @""];
    [nameField selectText:nil];

    if ([[NSApplication sharedApplication] runModalForWindow:[nameField window]] == 0) {
        return NO;
    }

    return YES;
}

- (void)nameOK:(id)sender {
    [[NSApplication sharedApplication] stopModalWithCode:1];
    [[nameField window] orderOut:nil];
}

- (void)nameCancel:(id)sender {
    [[NSApplication sharedApplication] stopModalWithCode:0];
    [[nameField window] orderOut:nil];
}

- (void)setLevels:(NSInteger)nLevels score:(NSInteger)sc {
    numLevels = nLevels;
    score = sc;
}

/* This method pretty much assumes the helicopter image is there... (Otherwise the game could not be played at all!)
*/
+ (void)cacheHelicopterBitmap {
    NSImage *helicopter = [[NSImage alloc] initByReferencingFile:[[NSBundle mainBundle] pathForResource:@"helicopter" ofType:@"tiff"]];
    [helicopter setCacheDepthMatchesImageDepth:YES];

    NSArray *reps = [helicopter representations];

    // Assume that the first rep is the color one...
    [helicopter lockFocusOnRepresentation:[reps objectAtIndex:0]];
    helicopterBitmap = [[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect(0.0, 0.0, [helicopter size].width, [helicopter size].height / 4.0)];
    [helicopter unlockFocus];
}

+ (void)makeNewAwardForLevels:(NSInteger)nLevels score:(NSInteger)sc {
    NSRect rect = NSMakeRect(0.0, 0.0, 500, 500);
    AwardView *award = [[AwardView alloc] initWithFrame:rect];

    if (![award getUserName]) return;

    if (helicopterBitmap == nil) [self cacheHelicopterBitmap];	// We do this explicitly as it doesn't work to do it while actually printing...

    NSPrintInfo *printInfo = [NSPrintInfo sharedPrintInfo];
    NSWindow *win = [[NSWindow alloc] initWithContentRect:rect styleMask:NSBorderlessWindowMask backing:NSBackingStoreNonretained defer:NO];
    [[win contentView] addSubview:award];

    [printInfo setVerticallyCentered:YES];
    [printInfo setHorizontallyCentered:YES];
    [printInfo setVerticalPagination:NSFitPagination];
    [printInfo setHorizontalPagination:NSFitPagination];

    [award setLevels:nLevels score:sc];
    [award print:nil];
}

/* Draws a line of text and updates the next valid position to draw at... (the position is kept in "textDrawingLocation")
*/
- (void)drawLineOfText:(NSString *)txt size:(CGFloat)size {
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:txt];
    NSRange range = NSMakeRange(0, [attrStr length]);
    CGFloat viewWidth = [self bounds].size.width;
    CGFloat width;

    /* Find a good size... */
    do {
	/* Attributes that are not set use the well-known defaults (black, no underline, etc) */
	NSFont *font = [NSFont fontWithName:@"Times-Roman" size:size];
	[attrStr addAttribute:NSFontAttributeName value:font range:range];
	width = [attrStr size].width;
        if (width < viewWidth * 0.9) break;
	size = size - 2.0;
    } while (size > 10.0);
	
    [attrStr drawAtPoint:NSMakePoint((viewWidth - width) / 2.0, textDrawingLocation)];
    textDrawingLocation += (size * 1.3 + 4.0);
}

- (void)drawRect:(NSRect)rect {
    NSRect hRect = NSZeroRect;
    NSRect sRect = NSZeroRect;
    NSRect bounds = [self bounds];

    NSAffineTransform *transform = [[NSAffineTransform alloc] init];
    [transform translateXBy:0.0 yBy:bounds.size.height];
    [transform scaleXBy:1.0 yBy:-1.0];
    [transform concat];	// Flip the coord system (so it's unflipped); more convenient for the images

    sRect.size = [helicopterBitmap size];
    hRect.size.width = floor(bounds.size.width * 0.6);
    hRect.size.height = floor((hRect.size.width / sRect.size.width) * sRect.size.height);
    hRect.origin.x = (bounds.size.width - hRect.size.width) / 2.0;
    hRect.origin.y = bounds.size.height - hRect.size.height * 1.5;
    [helicopterBitmap drawInRect:hRect];

    sRect.origin.x = 10.0;
    sRect.origin.y = 10.0;
    [helicopterBitmap drawInRect:sRect];

    sRect.origin.x = NSMaxX(bounds) - 10.0 - sRect.size.width;
    [helicopterBitmap drawInRect:sRect];

    sRect.origin.y = NSMaxY(bounds) - 10.0 - sRect.size.height;
    [helicopterBitmap drawInRect:sRect];

    sRect.origin.x = 10.0; 
    [helicopterBitmap drawInRect:sRect];

    [transform concat];	// Go back to default (flipped) coord system...
	
    textDrawingLocation = bounds.size.height - hRect.origin.y + 28;

    [self drawLineOfText:@"Certificate of Achievement" size:28];
    [self drawLineOfText:@"awarded to" size:20];
    [self drawLineOfText:[nameField stringValue] size:48];
    [self drawLineOfText:[NSString stringWithFormat:@"for valiantly completing the %ld treacherous levels of", (long)numLevels] size:20];
    [self drawLineOfText:@"BlastApp" size:28];
    [self drawLineOfText:[NSString stringWithFormat:@"with a total score of %ld", (long)score] size:24];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [dateFormatter setDateStyle:kCFDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [self drawLineOfText:[dateFormatter stringFromDate:[NSDate date]] size:20];

    NSFrameRect(bounds);
}

// Otherwise the text drawing (with NSGraphics.drawAttributedString() doesn't work quite right...)

- (BOOL)isFlipped {
    return YES;
}
@end

