/*
     File: Controller.m 
 Abstract: The Controller class of the TextLayoutDemo project. 
  Version: 1.1 
  
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

#import "Controller.h"
#import "CircleTextContainer.h"
#import "CircleView.h"

@implementation Controller

- (void)awakeFromNib {
    NSLayoutManager *twoColumnLayoutManager = [[NSLayoutManager alloc] init], *circleLayoutManager = [[NSLayoutManager alloc] init] ;
    NSTextContainer *firstColumnTextContainer = [[NSTextContainer alloc] init], *secondColumnTextContainer = [[NSTextContainer alloc] init], *circleTextContainer = [[CircleTextContainer alloc] init];
    NSTextView *firstColumnTextView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, 240, 360) textContainer:firstColumnTextContainer], *secondColumnTextView = [[NSTextView alloc] initWithFrame:NSMakeRect(240, 0, 240, 360) textContainer:secondColumnTextContainer], *circleTextView = [[NSTextView alloc] initWithFrame:NSMakeRect(40, 40, 400, 400) textContainer:circleTextContainer];
    CircleView *circleView = [[CircleView alloc] initWithFrame:NSMakeRect(0, 0, 480, 480)];
    
    [firstColumnTextContainer setContainerSize:NSMakeSize(240, 360)];
    [firstColumnTextContainer setWidthTracksTextView:YES];
    [firstColumnTextContainer setHeightTracksTextView:YES];
    [secondColumnTextContainer setContainerSize:NSMakeSize(240, 360)];
    [secondColumnTextContainer setWidthTracksTextView:YES];
    [secondColumnTextContainer setHeightTracksTextView:YES];
    [circleTextContainer setContainerSize:NSMakeSize(400, 400)];
    [circleTextContainer setWidthTracksTextView:YES];
    [circleTextContainer setHeightTracksTextView:YES];

    [twoColumnLayoutManager addTextContainer:firstColumnTextContainer];
    [twoColumnLayoutManager addTextContainer:secondColumnTextContainer];
    [twoColumnLayoutManager setUsesScreenFonts:NO];
    [twoColumnLayoutManager replaceTextStorage:[firstTextView textStorage]];
    [circleLayoutManager addTextContainer:circleTextContainer];
    [circleLayoutManager setUsesScreenFonts:NO];
    [circleLayoutManager replaceTextStorage:[firstTextView textStorage]];
    
    [firstColumnTextView setAutoresizingMask:NSViewHeightSizable];
    [[secondWindow contentView] addSubview:firstColumnTextView];
    [secondColumnTextView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [[secondWindow contentView] addSubview:secondColumnTextView];
    [circleView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [circleTextView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [circleTextView setDrawsBackground:NO];
    [[thirdWindow contentView] addSubview:circleView];
    [circleView addSubview:circleTextView];
    
    [firstColumnTextContainer release];
    [secondColumnTextContainer release];
    [twoColumnLayoutManager release];
    [circleTextContainer release];
    [circleTextView release];
    [firstColumnTextView release];
    [secondColumnTextView release];
    [circleLayoutManager release];
    [circleView release];
}

- (void)firstDemo:(id)sender {
    [firstWindow makeKeyAndOrderFront:self];
}

- (void)secondDemo:(id)sender {
    [secondWindow makeKeyAndOrderFront:self];
}

- (void)thirdDemo:(id)sender {
    [thirdWindow makeKeyAndOrderFront:self];
}

- (void)fourthDemo:(id)sender {
    CircleView *circleView = [[[thirdWindow contentView] subviews] objectAtIndex:0];
    if (![circleView layoutManager]) {
        [circleView setLayoutManager:[firstTextView layoutManager]];
        [NSTimer scheduledTimerWithTimeInterval:0.05 target:circleView selector:@selector(incrementStartingAngle:) userInfo:nil repeats:YES];
    }
}

@end
