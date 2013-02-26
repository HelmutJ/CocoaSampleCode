//-------------------------------------------------------------------------
//
//	File: UniformData.m
//
//  Abstract: UniformData Utility functions
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
//  Copyright (c) 2007 Apple Inc., All rights reserved.
//
//-------------------------------------------------------------------------

#import "UniformData.h"

static BOOL copyValue( GLfloat *src, GLfloat *dst )
{
	BOOL valueCopied = NO;
	
	if ( src != NULL )
	{
		int i;
		
		for ( i= 0; i < 4; i++ )
		{
			dst[i] = src[i];
		} // for
		
		valueCopied = YES;
	} // if
	
	return valueCopied;
} // copyValue

@implementation UniformData

- (id) init
{
	[super init];
	
	return self;
} // init

- (void) dealloc
{
	[super dealloc];
} // dealloc

- (void) initCurrent:(GLfloat)value
{
	current[0] = value;
} // initCurrent

- (void) initMin:(GLfloat)value
{
	min[0] = value;
} // initMin

- (void) initMax:(GLfloat)value
{
	max[0] = value;
} // initMax

- (void) initDelta:(GLfloat)value
{
	delta[0] = value;
} // initDelta

- (void) initCurrent:(GLfloat)value atIndex:(int)i
{
	current[i] = value;
} // initCurrent

- (void) initMin:(GLfloat)value atIndex:(int)i
{
	min[i] = value;
} // initMin

- (void) initMax:(GLfloat)value atIndex:(int)i
{
	max[i] = value;
} // initMax

- (void) initDelta:(GLfloat)value atIndex:(int)i
{
	delta[i] = value;
} // initDelta

- (void) animate
{
	int i; 
	
	for (i = 0; i < 4; i++ ) 
	{
		current[i] += delta[i];
		
		if ( ( current[i] < min[i] ) || ( current[i] > max[i] ) )
		{
			delta[i] = -delta[i];
		} // if
	} // for
} // animate

- (BOOL) setCurrent:(GLfloat *)theCurrent
{
	return copyValue(theCurrent, current);
} // setCurrent

- (GLfloat *) current
{
	return current;
} // current

- (BOOL) setMin:(GLfloat *)theMin
{
	return copyValue(theMin, min);
} // minSet

- (GLfloat *) min
{
	return min;
} // min

- (BOOL) setMax:(GLfloat *)theMax
{
	return copyValue(theMax, max);
} // minSet

- (GLfloat *) max
{
	return max;
} // max

- (BOOL) setDelta:(GLfloat *)theDelta
{
	return copyValue(theDelta, delta);
} // minSet

- (GLfloat *) delta
{
	return delta;
} // delta

@end
