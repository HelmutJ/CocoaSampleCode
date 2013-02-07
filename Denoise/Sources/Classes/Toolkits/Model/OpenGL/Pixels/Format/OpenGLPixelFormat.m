//---------------------------------------------------------------------------
//
//	File: OpenGLPixelFormat.m
//
//  Abstract: Utility class to obtain pixel format for an OpenGL view.
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
//  Copyright (c) 2009 Apple Inc., All rights reserved.
//
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#import "OpenGLPixelFormat.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Methods

//---------------------------------------------------------------------------

@interface OpenGLPixelFormat(Private)

- (void) newPixelFormat;

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -

//---------------------------------------------------------------------------

@implementation OpenGLPixelFormat

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Default Initializer

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

- (id) initPixelAttributesWithPListAtPath:(NSString *)thePListPath
{
	[self doesNotRecognizeSelector:_cmd];
	
	return( nil );
} // initPixelAttributesWithPListAtPath

//---------------------------------------------------------------------------

- (id) initPixelAttributesWithPListInAppBundle:(NSString *)thePListName
{
	[self doesNotRecognizeSelector:_cmd];
	
	return( nil );
} // initPixelAttributesWithPListInAppBundle

//---------------------------------------------------------------------------

- (void) newPixelFormat
{
	// Antialised, hardware accelerated without fallback to the software renderer.
	
	pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:[self attributes:YES]];
	
	if( pixelFormat == nil ) 
	{
		// If we can't get the desired pixel format then fewer attributes 
		// will be rerquested.
		
		pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:[self attributes:NO]];
		
		[[NSAlert alertWithMessageText:@"WARNING" 
						 defaultButton:@"Okay" 
					   alternateButton:nil 
						   otherButton:nil 
			 informativeTextWithFormat:@"Basic pixel format was allocated!"] runModal];
	} // if
} // newPixelFormat

//---------------------------------------------------------------------------

- (id) initPixelFormatWithPListAtPath:(NSString *)thePListPath
{	
	self = [super initPixelAttributesWithPListAtPath:thePListPath];
	
	if( self )
	{
		[self newPixelFormat];
	} // if
	
	return( self );
} // initPixelFormatWithPListAtPath

//---------------------------------------------------------------------------

- (id) initPixelFormatWithPListInAppBundle:(NSString *)thePListName
{
	self = [super initPixelAttributesWithPListInAppBundle:thePListName];
	
	if( self )
	{
		[self newPixelFormat];
	} // if
	
	return( self );
} // initPixelFormatWithPListInAppBundle

//---------------------------------------------------------------------------

+ (id) pixelFormatWithPListAtPath:(NSString *)thePListPath
{
	return( [[[OpenGLPixelFormat allocWithZone:[self zone]] 
			  initPixelFormatWithPListAtPath:thePListPath] autorelease] );
} // pixelFormatWithPListAtPath

//---------------------------------------------------------------------------

+ (id) pixelFormatWithPListInAppBundle:(NSString *)thePListName
{
	return( [[[OpenGLPixelFormat allocWithZone:[self zone]] 
			  initPixelFormatWithPListInAppBundle:thePListName] autorelease] );
} // pixelFormatWithPListInAppBundle

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Destructor

//---------------------------------------------------------------------------

- (void) dealloc 
{
	if( pixelFormat )
	{
		[pixelFormat release];
		
		pixelFormat = nil;
	} // if
	
    [super dealloc];
} // dealloc

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Accessors

//---------------------------------------------------------------------------

- (NSOpenGLPixelFormat *) pixelFormat
{
	return( pixelFormat );
} // pixelFormat

//---------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
