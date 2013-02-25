//---------------------------------------------------------------------------
//
//	File: QTCoreVideoController.m
//
//  Abstract: Controller class that includes view animation
// 			 
//  Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
//  Computer, Inc. ("Apple") in consideration of your agreement to the
//  following terms, and your use, installation, modification or
//  redistribution of this Apple software constitutes acceptance of these
//  terms.  If you do not agree with these terms, please do not use,
//  install, modify or redistribute this Apple software.
//  
//  In consideration of your agreement to abide by the following terms, and
//  subject to these terms, Apple grants you a personal, non-exclusive
//  license, under Apple's copyrights in this original Apple software (the
//  "Apple Software"), to use, reproduce, modify and redistribute the Apple
//  Software, with or without modifications, in source and/or binary forms;
//  provided that if you redistribute the Apple Software in its entirety and
//  without modifications, you must retain this notice and the following
//  text and disclaimers in all such redistributions of the Apple Software. 
//  Neither the name, trademarks, service marks or logos of Apple Computer,
//  Inc. may be used to endorse or promote products derived from the Apple
//  Software without specific prior written permission from Apple.  Except
//  as expressly stated in this notice, no other rights or licenses, express
//  or implied, are granted by Apple herein, including but not limited to
//  any patent rights that may be infringed by your derivative works or by
//  other works in which the Apple Software may be incorporated.
//  
//  The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
//  MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
//  THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
//  FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
//  OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
//  
//  IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
//  OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
//  MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
//  AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
//  STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
// 
//  Copyright (c) 2008 Apple Inc., All rights reserved.
//
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#import "GLSLTypes.h"

#import "QTCoreVideoController.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

enum AnimationTypes
{
	kAnimationTopSliderFadeIn = 0,
	kAnimationTopSliderFadeOut,
	kAnimationTopTextFieldFadeIn,
	kAnimationTopTextFieldFadeOut,
	kAnimationTopStaticTextFieldFadeIn,
	kAnimationTopStaticTextFieldFadeOut,
	kAnimationColorWellFadeIn,
	kAnimationColorWellFadeOut,
	kAnimationBottomSliderFadeIn,
	kAnimationBottomSliderFadeOut,
	kAnimationBottomTextFieldFadeIn,
	kAnimationBottomTextFieldFadeOut,
	kAnimationBottomStaticTextFieldFadeIn,
	kAnimationBottomStaticTextFieldFadeOut,
	kAnimationPushButtonFadeIn,
	kAnimationPushButtonFadeOut
};

typedef enum AnimationTypes AnimationTypes;

//---------------------------------------------------------------------------

static const NSUInteger kAnimationSetCount = 8;

//---------------------------------------------------------------------------

static const AnimationTypes gAnimationSet[4][8] = {	{	kAnimationPushButtonFadeOut, 
														kAnimationBottomSliderFadeOut,  
														kAnimationTopSliderFadeIn, 
														kAnimationColorWellFadeOut,
														kAnimationBottomStaticTextFieldFadeOut, 
														kAnimationBottomTextFieldFadeOut, 
														kAnimationTopStaticTextFieldFadeIn, 
														kAnimationTopTextFieldFadeIn },
													{   kAnimationPushButtonFadeIn, 
														kAnimationBottomSliderFadeIn,  
														kAnimationTopSliderFadeIn, 
														kAnimationColorWellFadeOut,
														kAnimationBottomStaticTextFieldFadeIn, 
														kAnimationBottomTextFieldFadeIn, 
														kAnimationTopStaticTextFieldFadeIn, 
														kAnimationTopTextFieldFadeIn },
													{   kAnimationPushButtonFadeOut, 
														kAnimationBottomSliderFadeOut, 
														kAnimationTopSliderFadeOut, 
														kAnimationColorWellFadeIn,
														kAnimationBottomStaticTextFieldFadeOut, 
														kAnimationBottomTextFieldFadeOut, 
														kAnimationTopStaticTextFieldFadeOut, 
														kAnimationTopTextFieldFadeOut },
													{   kAnimationPushButtonFadeOut, 
														kAnimationBottomSliderFadeOut, 
														kAnimationTopSliderFadeOut, 
														kAnimationColorWellFadeOut,
														kAnimationBottomStaticTextFieldFadeOut, 
														kAnimationBottomTextFieldFadeOut, 
														kAnimationTopStaticTextFieldFadeOut, 
														kAnimationTopTextFieldFadeOut   }  };

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

@implementation QTCoreVideoController

//---------------------------------------------------------------------------

#pragma mark -- Did End Selector For Open Sheet --

//---------------------------------------------------------------------------

- (void) openPanelDidEnd:(NSOpenPanel *)sheet 
			  returnCode:(int)returnCode
			 contextInfo:(void *)contextInfo
{
	if ( returnCode ) 
	{
		[qtCVOpenGLView openMovie:[[sheet filenames] objectAtIndex:0]];
    } // if
	
    // Activate the display link
	
	CVDisplayLinkStart( [qtCVOpenGLView displayLink] );
} // openPanelDidEnd

//---------------------------------------------------------------------------

#pragma mark -- Open Sheet Action --

//---------------------------------------------------------------------------

- (IBAction) open:(id)sender
{
	// if the display link is active, stop it
	
	CVDisplayLinkRef displayLinkRef = [qtCVOpenGLView displayLink];
	
	if ( CVDisplayLinkIsRunning( displayLinkRef ) ) 
	{
    	CVDisplayLinkStop( displayLinkRef );
    } // if
	
	[[NSOpenPanel openPanel] beginSheetForDirectory:nil 
											   file:nil 
											  types:[QTMovie movieUnfilteredFileTypes]
									 modalForWindow:[qtCVOpenGLView window] 
									  modalDelegate:self 
									 didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) 
										contextInfo:nil];
} // open

//---------------------------------------------------------------------------

#pragma mark -- View Animation Prep --

//---------------------------------------------------------------------------

- (NSDictionary *) viewAnimationGetDict:(NSView *)theView 
								   type:(NSString *)theAnimationType
{

	NSArray *viewAnimationKeys = [NSArray arrayWithObjects:	NSViewAnimationTargetKey,
															NSViewAnimationEndFrameKey,
															NSViewAnimationEffectKey,
															nil ];

	NSArray *viewAnimationObjects = [NSArray arrayWithObjects:	theView,
																[NSValue valueWithRect:[theView frame]],
																theAnimationType,
																nil ];

	NSDictionary *viewAnimationDict = [[NSDictionary alloc ] initWithObjects:viewAnimationObjects 
																	 forKeys:viewAnimationKeys];
	
	return  viewAnimationDict;
} // viewAnimationGetDict

//---------------------------------------------------------------------------

- (void) viewAnimationAddEffects:(NSMutableArray *)theAnimations
							view:(NSView *)theView 
							type:(NSString *)theAnimationType
{
	NSDictionary  *viewAnimationDict = [self viewAnimationGetDict:theView 
															 type:theAnimationType];
	
	if ( viewAnimationDict )
	{
		[theAnimations addObject:viewAnimationDict];
		[viewAnimationDict release];
	} // if
} // viewAnimationAddEffects

//---------------------------------------------------------------------------

#pragma mark -- Animation Views & Panels --

//---------------------------------------------------------------------------
//
// Given an array of dictionaries (i.e., an animation sequence), animate
// the views.
//
//---------------------------------------------------------------------------

- (void) animateSequence:(NSArray *)theAnimationSequence 
			animationDuration:(NSTimeInterval)theAnimationDuration 
			animationCurve:(NSAnimationCurve)theAnimationCurve
{
	// Create the view animation object.
	
	NSViewAnimation *animationSequence = [[NSViewAnimation alloc] initWithViewAnimations:theAnimationSequence];
	
	if ( animationSequence )
	{
		// Set some additional attributes for the animation.
		
		[animationSequence setDuration:theAnimationDuration];    // how many seconds?
		[animationSequence setAnimationCurve:theAnimationCurve];
		
		// Run the animation.
		
		[animationSequence startAnimation];
		
		// The animation has finished, so go ahead and release it.
		
		[animationSequence release];
	} // if
} // animateSequence

//---------------------------------------------------------------------------
//
// Since all controls are derived from a view, for animation, return a
// view.
//
//---------------------------------------------------------------------------

- (NSView *) animationGetView:(const AppControlTypes)theAppControlType 
{
	switch( theAppControlType )
	{
		case kControlTopSlider:
			return topSlider;
		
		case kControlTopTextField:
			return topTextField;
			
		case kControlTopStaticTextField:
			return topStaticTextField;
		
		case kControlColorWell:
			return colorWell;
			
		case kControlBottomSlider:
			return bottomSlider;
			
		case kControlBottomTextField:
			return bottomTextField;
			
		case kControlBottomStaticTextField:
			return bottomStaticTextField;
			
		case kControlPushButton:
			return pushButton;
	} // switch
	
	return nil;
} // animationGetView

//---------------------------------------------------------------------------
//
// If the requested control is still invisible then make it visible by
// adding a fade-in effect to the animation chain.
//
//---------------------------------------------------------------------------

- (void) animationAddEffectFadeIn:(const AppControlTypes)theAppControlType 
							sequence:(NSMutableArray *)theAnimationSequence
{
	if ( ![qtCVOpenGLView controlIsVisible:theAppControlType] )
	{
		NSView *animationView = [self animationGetView:theAppControlType];
		
		[self viewAnimationAddEffects:theAnimationSequence 
								 view:animationView 
								 type:NSViewAnimationFadeInEffect];
		
		[qtCVOpenGLView setControlIsVisible:YES 
									control:theAppControlType];
	} // if
} // animationAddEffectFadeIn

//---------------------------------------------------------------------------
//
// If the requested control is still visible then make it invisible by
// adding a fade-out effect to the animation chain.
//
//---------------------------------------------------------------------------

- (void) animationAddEffectFadeOut:(const AppControlTypes)theAppControlType 
							sequence:(NSMutableArray *)theAnimationSequence
{
	if ( [qtCVOpenGLView controlIsVisible:theAppControlType] )
	{
		NSView *animationView = [self animationGetView:theAppControlType];
		
		[self viewAnimationAddEffects:theAnimationSequence 
								 view:animationView 
								 type:NSViewAnimationFadeOutEffect];
		
		[qtCVOpenGLView setControlIsVisible:NO 
									control:theAppControlType];
	} // if
} // animationAddEffectFadeOut

//---------------------------------------------------------------------------
//
// Build an animation sequence (i.e., array of dictionaries) from a given
// set.
//
//---------------------------------------------------------------------------

- (NSArray *) animationSequenceFromSet:(const AnimationTypes *)theAnimationSequenceSet 
								 count:(const NSInteger)theAnimationSequenceSetCount
{
	NSInteger        i;
	NSInteger        appControlType    = 0;
	NSMutableArray  *animationSequence = [[NSMutableArray arrayWithCapacity:theAnimationSequenceSetCount] retain];
	
	for( i = 0; i < theAnimationSequenceSetCount; i++ )
	{
		// Fade-in or fade-out request for a control
		// map into (needless to say) a control type
		
		appControlType = theAnimationSequenceSet[i] >> 1;

		// If the result is an odd number we may infer 
		// from it a fade-out effect, and with an even 
		// number, a fade-in effect.
		
		if( theAnimationSequenceSet[i] & 1 )
		{
			// Add fade-out effect for view animation
			
			[self animationAddEffectFadeOut:appControlType 
								   sequence:animationSequence];
		} // if
		else
		{
			// Add fade-in effect for view animation
			
			[self animationAddEffectFadeIn:appControlType 
								  sequence:animationSequence];
		} // else
	} // for
	
	return  animationSequence;
} // animationSequenceFromSet

//---------------------------------------------------------------------------
//
// Using an animation sequence (array of dictionaries), animate the controls
//
//---------------------------------------------------------------------------

- (void) animateViewsUsingSequence:(NSArray *)theAnimationSequence
{
	if ( theAnimationSequence )
	{
		NSTimeInterval    animationDuration = 1.5;
		NSAnimationCurve  animationCurve    = NSAnimationEaseIn;
		
		[self animateSequence:theAnimationSequence 
			animationDuration:animationDuration 
			   animationCurve:animationCurve];
	} // if
} // animateViewsUsingSequence

//---------------------------------------------------------------------------
//
// If the requested sequence is different than the previously requested
// sequence, then genreate an animation sequence (chain), and then animate.
//
// Even though we have a specific set of animation sequences for this 
// application, note that the design pattern utilized for this method 
// permits any combination of views fading in or out for shaders and
// within this application.
//
//---------------------------------------------------------------------------

- (void) animateViewsWithSequenceType:(const AnimationSequenceTypes)theAnimationSequenceType
{
	if ( [qtCVOpenGLView animationSequenceType] != theAnimationSequenceType )
	{
		NSArray *animationSequence = [self animationSequenceFromSet:gAnimationSet[theAnimationSequenceType]
															  count:kAnimationSetCount];
		
		[qtCVOpenGLView setAnimationSequenceType:theAnimationSequenceType];
		
		[self animateViewsUsingSequence:animationSequence];

		[animationSequence release];
	} // if
} // animateViewsWithSequenceType

//---------------------------------------------------------------------------
//
// Based on selected shader, we shall fade in or out the controls associated 
// with a particular shader.
//
//---------------------------------------------------------------------------

- (void) animateViewsBasedOnShaderType:(GLSLTypes)theShaderUnitSelected
{
	switch( theShaderUnitSelected )
	{
		case kShaderBlur:
		case kShaderBrighten:
		case kShaderDilation:
		case kShaderEdgeDection:
		case kShaderErosion:
		case kShaderFog:
		case kShaderSaturation:
		case kShaderSharpen:
		case kShaderSky:
			
			[self animateViewsWithSequenceType:kAnimationDefaultSequence];
			break;

		case kShaderToon:
			
			[self animateViewsWithSequenceType:kAnimationFirstSequence];
			break;

		case kShaderExtractColor:
			
			[self animateViewsWithSequenceType:kAnimationSecondSequence];
			break;
			
		case kShaderDefault:
		case kShaderColorInvert:
		case kShaderGrayInvert:
		case kShaderHeatSig:
		case kShaderSepia:
		default:

			[self animateViewsWithSequenceType:kAnimationThirdSequence];
			break;
	} // switch
} // animateViewsBasedOnShaderType

//---------------------------------------------------------------------------

#pragma mark -- Push Button Action --

//---------------------------------------------------------------------------

- (IBAction) buttonPushed:(id)sender
{
	NSInteger buttonPushed = [sender state];
	
	if ( buttonPushed == NSOffState )
	{
		[qtCVOpenGLView setUniformUsingPushButtonState:NO];
	} // if
	else if ( buttonPushed == NSOnState )
	{
		[qtCVOpenGLView setUniformUsingPushButtonState:YES];
	} // else if
} // buttonPushed

//---------------------------------------------------------------------------

#pragma mark -- Text Field Actions --

//---------------------------------------------------------------------------

- (IBAction) bottomTextFieldChanged:(id)sender
{
	int    uniformIntValue   = [sender intValue];
	float  uniformFloatValue = (float)uniformIntValue / 100.0f;
	
    [qtCVOpenGLView setUniformUsingBottomSliderOrBottomTextField:uniformFloatValue];
	
	[bottomSlider setFloatValue:uniformFloatValue];
} // bottomTextFieldChanged

//---------------------------------------------------------------------------

- (IBAction) topTextFieldChanged:(id)sender
{
	int    uniformIntValue   = [sender intValue];
	float  uniformFloatValue = (float)uniformIntValue / 100.0f;
	
    [qtCVOpenGLView setUniformUsingTopSliderOrTopTextField:uniformFloatValue];
	
	[topSlider setFloatValue:uniformFloatValue];
} // topTextFieldChanged

//---------------------------------------------------------------------------

#pragma mark -- Slider Actions --

//---------------------------------------------------------------------------

- (IBAction) topSliderChanged:(id)sender
{
	float uniformFloatValue = [sender floatValue];
	int   uniformIntValue   = (int)(uniformFloatValue * 100.0f);
	
    [qtCVOpenGLView setUniformUsingTopSliderOrTopTextField:uniformFloatValue];
	
	[topTextField setIntValue:uniformIntValue];
} // topSliderChanged

//---------------------------------------------------------------------------

- (IBAction) bottomSliderChanged:(id)sender
{
	float uniformFloatValue = [sender floatValue];
	int   uniformIntValue   = (int)(uniformFloatValue * 100.0f);
	
    [qtCVOpenGLView setUniformUsingBottomSliderOrBottomTextField:uniformFloatValue];
	
	[bottomTextField setIntValue:uniformIntValue];
} // bottomSliderChanged

//---------------------------------------------------------------------------

#pragma mark -- Color Well Action --

//---------------------------------------------------------------------------

- (IBAction) colorWellChanged:(id)sender
{
	NSColor *color = [sender color];
	
    [qtCVOpenGLView setUniformUsingColorWell:color];
} // colorWellChanged

//---------------------------------------------------------------------------

#pragma mark -- Accessory View Actions --

//---------------------------------------------------------------------------

- (IBAction) colorMatchSliderChanged:(id)sender
{
	float uniformFloatValue = [sender floatValue];
	int   uniformIntValue   = (int)(uniformFloatValue * 100.0f);
	
    [qtCVOpenGLView setUniformUsingColorPanelAccessoryControls:uniformFloatValue];
	
	[colorMatchAccessoryTextField setIntValue:uniformIntValue];
} // colorMatchSliderChanged

//---------------------------------------------------------------------------

- (IBAction) colorMatchTextFieldChanged:(id)sender
{
	int    uniformIntValue   = [sender intValue];
	float  uniformFloatValue = (float)uniformIntValue / 100.0f;
	
    [qtCVOpenGLView setUniformUsingColorPanelAccessoryControls:uniformFloatValue];
	
	[colorMatchAccessorySlider setFloatValue:uniformFloatValue];
} // colorMatchTextFieldChanged

//---------------------------------------------------------------------------

#pragma mark -- PopUp Button Action --

//---------------------------------------------------------------------------
//
// If a shared color panel is open then close it
//
//---------------------------------------------------------------------------

- (void) sharedColorPanelClose
{
	if ( [NSColorPanel sharedColorPanelExists] )
	{
		[[NSColorPanel sharedColorPanel] close];
	} // if
} // sharedColorPanelClose

//---------------------------------------------------------------------------
//
// Add the accessory view to the shared color panel if the selcted
// effect is the color extraction shader.
//
//---------------------------------------------------------------------------

- (void) sharedColorPanelAddAccessoryView:(const GLSLTypes)theShaderUnitSelected
{
	if ( theShaderUnitSelected == kShaderExtractColor )
	{
		[[NSColorPanel sharedColorPanel] setAccessoryView:colorMatchAccessory];
	} // if
} // sharedColorPanelAddAccessoryView

//---------------------------------------------------------------------------
//
// This method is called when the user picks a different effect to 
// receive messages using the pop-up menu
//
//---------------------------------------------------------------------------

- (IBAction) switchEffects:(id)sender
{
	// sender is the NSPopUpMenu containing shader effects' choices.
	// We ask the sender which popup menu item is selected and add
	// one to compensate for counting from zero.
	
	GLSLTypes effectSelected = [sender indexOfSelectedItem] + 1;

	// Based of the selected effect animate the views
	
	[self sharedColorPanelClose];
	[self sharedColorPanelAddAccessoryView:effectSelected];
	[self animateViewsBasedOnShaderType:effectSelected];
	
	// Based on selected shader effect, we set the target to the
	// selected shader.
	
	[qtCVOpenGLView setShaderItem:effectSelected];
} // switchEffects

//---------------------------------------------------------------------------

#pragma mark -- Delagates --

//---------------------------------------------------------------------------

- (void) applicationDidFinishLaunching:(NSNotification *)notification
{
	[self open:self];
} // applicationDidFinishLaunching

//---------------------------------------------------------------------------
//
// It's important to clean up our rendering objects before we terminate -- 
// cocoa will not specifically release everything on application termination, 
// so we explicitly call our clean up routine ourselves
//
//---------------------------------------------------------------------------

- (void) applicationWillTerminate:(NSNotification *)notification
{
	[qtCVOpenGLView cleanUp];
} // applicationWillTerminate

//---------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
