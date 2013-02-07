//---------------------------------------------------------------------------
//
//	File: OpenGLIBORenderer.m
//
//  Abstract: Class that implements methods for creating an IBO
//            based renderer.
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
//  Copyright (c) 2009-2011 Apple Inc., All rights reserved.
//
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#import "NSPropertyList.h"

#import "OpenGLIBORenderer.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Methods

//---------------------------------------------------------------------------

@interface OpenGLIBORenderer(Private)

- (void) initGeometry:(NSDictionary *)theDictionary;
- (void) initElements:(NSDictionary *)theDictionary;
- (void) initRenderer:(NSDictionary *)theDictionary;

- (void) newRendererWithPListAtPath:(NSString *)thePListPath;

- (void) cleanUp;

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

@implementation OpenGLIBORenderer

//---------------------------------------------------------------------------

- (id) initIBOWithType:(const GLenum)theType
{
	[self doesNotRecognizeSelector:_cmd];
	
	return( nil );
} // initIBOWithType

//---------------------------------------------------------------------------

- (void) initGeometry:(NSDictionary *)theDictionary
{
	geometry = [[OpenGLIBOGeometry alloc] initGeometryWithDictionary:theDictionary];
	
	if( geometry )
	{
		GLsizeiptr size   = [geometry size];
		GLsizeiptr offset = size;
		
		[self setVertices:[geometry vertices]
					 size:size];
		
		[self setNormals:[geometry normals] 
					size:size
				  offset:offset];
	} // if
} // initGeometry

//---------------------------------------------------------------------------

- (void) initElements:(NSDictionary *)theDictionary
{
	elements = [[OpenGLIBOElements alloc] initElementsWithDictionary:theDictionary];
	
	if( elements )
	{
		[self setElements:[elements array]
                     size:[elements size]];
	} // if
} // initElements

//---------------------------------------------------------------------------

- (void) initRenderer:(NSDictionary *)theDictionary
{
	renderer = [OpenGLDrawElements new];
	
	if( renderer )
	{
		[renderer setDictionary:theDictionary];
	} // if
} // initRenderer

//---------------------------------------------------------------------------

- (void) newRendererWithPListAtPath:(NSString *)thePListPath 
{
	NSPropertyList *pList = [[NSPropertyList alloc] initPListWithFileAtPath:thePListPath];
	
	if( pList )
	{
		NSDictionary *dictionary = [pList dictionaryForKey:@"IBO"];
		
		if( dictionary )
		{
			[self initRenderer:dictionary];
			[self initGeometry:dictionary];
			[self initElements:dictionary];
			
			[self acquire];
		} // if
		
		[pList release];
	} // if	
} // newRendererWithPListAtPath

//---------------------------------------------------------------------------

- (id) initIBORendererWithPListAtPath:(NSString *)thePListPath 
								 type:(const GLenum)theType
{
	self = [super initIBOWithType:theType];
	
	if( self )
	{
		[self newRendererWithPListAtPath:thePListPath];
	} // if
	
	return( self );
} // initRendererWithPListAtPath

//---------------------------------------------------------------------------

- (id) initIBORenderertWithPListInAppBundle:(NSString *)thePListName
									   type:(const GLenum)theType
{
	self = [super initIBOWithType:theType];
	
	if( self )
	{
		NSBundle  *appBundle = [NSBundle mainBundle];
		
		if( appBundle )
		{
			NSString  *pListPath = [appBundle pathForResource:thePListName
													   ofType:@"plist"];
			
			if( pListPath )
			{
				[self newRendererWithPListAtPath:pListPath];
			} // if
		} // if
	} // if
	
	return( self );
} // initRenderertWithPListInAppBundle

//---------------------------------------------------------------------------

- (void) cleanUp
{
	if( geometry )
	{
		[geometry release];
		
		geometry = nil;
	} // if
	
	if( elements )
	{
		[elements release];
		
		elements = nil;
	} // if
	
	if( renderer )
	{
		[renderer release];
		
		renderer = nil;
	} // if
} // cleanUpIBORenderer

//---------------------------------------------------------------------------

- (void) dealloc
{
	[self cleanUp];
	
	[super dealloc];
} // dealloc

//---------------------------------------------------------------------------

- (void) render
{
	[self bind];
	
	[renderer drawElements];
	
	[self unbind];
} // render

//---------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------


