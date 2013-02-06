/*
     File: MyWindowController.m 
 Abstract: 
 Sample's main NSWindowController.
  
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
  
 Copyright (C) 2011 Apple Inc. All Rights Reserved. 
  
 */

#import "MyWindowController.h"
#import <QuartzCore/CAAnimation.h>  // for kCATransition<xxx> string constants
#import <QuartzCore/CoreImage.h>    // for kCICategoryTransition


@implementation MyWindowController

@synthesize transitionStyle;
@synthesize slideView;
@synthesize transitionChoicePopup;

// -------------------------------------------------------------------------------
//	awakeFromNib:
// -------------------------------------------------------------------------------
- (void)awakeFromNib
{
	[slideView setWantsLayer:YES];	// this can also be set in IB
    
    donPedro1 = [NSImage imageNamed:@"Lake Don Pedro1"];
	donPedro2 = [NSImage imageNamed:@"Lake Don Pedro2"];
    
    // build the popup menu of transitions, the second part of the popup is built dynamically based
    // on what Core Images gives us:
    //
    [transitionChoicePopup removeItemAtIndex: 0];	// remove the first item defined in IB
    
    NSMutableArray *popupChoices = [NSMutableArray arrayWithObjects:
                                         // Core Animation's four built-in transition types
                                         kCATransitionFade,
                                         kCATransitionMoveIn,
                                         kCATransitionPush,
                                         kCATransitionReveal,
                                         nil];
    
    NSArray *transitions = [CIFilter filterNamesInCategories:[NSArray arrayWithObject:kCICategoryTransition]];
    if (transitions.count > 0)
    {
        NSString *transition;
        for (transition in transitions)
            [popupChoices addObject:transition];
    }
        
    [transitionChoicePopup addItemsWithTitles:popupChoices];
     
    // pick the default transition
    NSInteger idx = [transitionChoicePopup indexOfSelectedItem];
    self.transitionStyle = [transitionChoicePopup itemTitleAtIndex:idx];
    [slideView transitionToImage:donPedro1];
    curSlide1 = YES;
}

// -------------------------------------------------------------------------------
//	goTransitionAction:sender
// -------------------------------------------------------------------------------
- (IBAction)goTransitionAction:(id)sender
{
    if (curSlide1)
    {
        [slideView transitionToImage: donPedro2];
        curSlide1 = NO;		// we are not showing slide #1
    }
    else
    {
        [slideView transitionToImage: donPedro1];
        curSlide1 = YES;	// we are showing slide #1
    }
}

// -------------------------------------------------------------------------------
//	setTransitionStyle:newTransitionStyle
// -------------------------------------------------------------------------------
- (void)setTransitionStyle:(NSString *)newTransitionStyle
{
    if (transitionStyle != newTransitionStyle)
	{
        [transitionStyle release];
        transitionStyle = [newTransitionStyle copy];
        
        [slideView updateSubviewsWithTransition:transitionStyle];
    }
}

// -------------------------------------------------------------------------------
//	transitionChoiceAction:sender
// -------------------------------------------------------------------------------
- (IBAction)transitionChoiceAction:(id)sender
{
    NSInteger idx = [transitionChoicePopup indexOfSelectedItem];
    self.transitionStyle = [transitionChoicePopup itemTitleAtIndex:idx];
}

// -------------------------------------------------------------------------------
//	dealloc
// -------------------------------------------------------------------------------
- (void)dealloc
{
    [slideView release];
    slideView = nil;
    [transitionChoicePopup release];
    transitionChoicePopup = nil;
    [transitionStyle release];
    transitionStyle = nil;
    
    [super dealloc];
}

@end
