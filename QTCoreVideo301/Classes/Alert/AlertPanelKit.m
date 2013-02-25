//---------------------------------------------------------------------------
//
//	File: AlertPanelKit.m
//
//  Abstract: Class that implements a utility toolkit for alerts.
//
//  Disclaimer: IMPORTANT:  This Apple software is supplied to you by
//  Apple Inc. ("Apple") in consideration of your agreement to the
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
//  Neither the name, trademarks, service marks or logos of Apple Inc.
//  may be used to endorse or promote products derived from the Apple
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

#include "Alert.h"

#import "AlertPanelKit.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

@implementation AlertPanelKit

//---------------------------------------------------------------------------

- (id) initWithTitle:(NSString *)theAlertTitle
			 message:(NSString *)theAlertMessage 
				exit:(const BOOL)theExitOnError
{
	self = [super init];
	
	if ( self )
	{
		if ( theAlertTitle )
		{
			alertTitle = [[NSString alloc] initWithString:theAlertTitle];
		} // if
		else
		{
			alertTitle = [[NSString alloc] initWithString:@"Alert From the Application or a Toolkit"];
		} // else
		
		if ( theAlertMessage )
		{
			alertMessage = [[NSString alloc] initWithString:theAlertMessage];
		} // if
		else
		{
			alertMessage = [[NSString alloc] initWithString:@"Unkown Condition"];
		} // else
		
		exitOnError = theExitOnError;
	} // if
	
	return  self;
} // initWithTitle

//------------------------------------------------------------------------

+ (id) withTitle:(NSString *)theAlertTitle
		 message:(NSString *)theAlertMessage
			exit:(const BOOL)theExitOnErrorFlag
{
	return  [[[AlertPanelKit allocWithZone:[self zone]] 
								initWithTitle:theAlertTitle 
								message:theAlertMessage 
								exit:theExitOnErrorFlag] autorelease];
} // withTitle

//------------------------------------------------------------------------

- (void) dealloc
{
	if ( alertTitle )
	{
		[alertTitle release];
		
		alertTitle = nil;
	} // if
	
	if ( alertMessage )
	{
		[alertMessage release];
		
		alertMessage = nil;
	} // if
	
	[super dealloc];
} // dealloc

//------------------------------------------------------------------------

//------------------------------------------------------------------------

- (void) setAlertTitle:(NSString *)theAlertTitle
{
	NSComparisonResult  stringCmpResult = [alertTitle compare:theAlertTitle];
	
	if ( stringCmpResult != NSOrderedSame )
	{
		[alertTitle release];
		alertTitle = [theAlertTitle retain];
	}
} // setAlertTitle

//------------------------------------------------------------------------

- (void) setAlertMessage:(NSString *)theAlertMessage
{
	NSComparisonResult  stringCmpResult = [alertMessage compare:theAlertMessage];
	
	if ( stringCmpResult != NSOrderedSame )
	{
		[alertMessage release];
		alertMessage = [theAlertMessage retain];
	}
} // setAlertMessage

//------------------------------------------------------------------------

- (void) setExitOnError:(const BOOL)theExitOnErrorFlag
{
	exitOnError = theExitOnErrorFlag;
} // setExitOnError

//------------------------------------------------------------------------

//------------------------------------------------------------------------

- (void) displayAlertPanel
{
	if ( !exitOnError )
	{
		DisplayAlert( alertTitle, alertMessage );
	} // if
	else
	{
		DisplayAlertAndExit( alertTitle, alertMessage );
	} // else
} // displayAlertPanel

//------------------------------------------------------------------------

- (void) displayAlertPanelWithError:(const NSInteger)theAlertError
{
	if ( !exitOnError )
	{
		DisplayAlertWithError( alertTitle, alertMessage, theAlertError );
	} // if
	else
	{
		DisplayAlertWithErrorAndExit( alertTitle, alertMessage, theAlertError );
	} // else
} // displayAlertPanelWithError

//------------------------------------------------------------------------

@end

//------------------------------------------------------------------------

//------------------------------------------------------------------------


