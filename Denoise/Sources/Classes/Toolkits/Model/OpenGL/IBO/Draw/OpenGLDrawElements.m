//---------------------------------------------------------------------------
//
//	File: OpenGLDrawElements.m
//
//  Abstract: Utility class to deserialize a property list that describes
//            a VBO draw elements parameters and draws an object using
//            the parameters values (cached in an array).
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

#import "OpenGLDrawElements.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Macros

//---------------------------------------------------------------------------

#define BUFFER_OFFSET(i) ((GLushort *)NULL + (i))

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Data Structures

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

struct OpenGLDEParams
{
	GLenum    mode;
	GLsizei   count;
	GLenum    type;
	GLushort  offset;
};

typedef struct OpenGLDEParams   OpenGLDEParams;
typedef struct OpenGLDEParams  *OpenGLDEParamsRef;

//---------------------------------------------------------------------------

struct OpenGLDrawElementsData
{
	GLsizeiptr         count;
	GLsizeiptr         size;
	OpenGLDEParamsRef  params;
};

typedef struct OpenGLDrawElementsData  OpenGLDrawElementsData;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

@implementation OpenGLDrawElements

//---------------------------------------------------------------------------

- (id) init
{
	self = [super init];
	
	if( self )
	{
		mpDrawElements = (OpenGLDrawElementsDataRef)calloc(1, sizeof(OpenGLDrawElementsData));
		
		if( mpDrawElements != NULL )
		{
			mpDrawElements->count  = 0;
			mpDrawElements->size   = 0;
			mpDrawElements->params = NULL; 
		} // if
	} // if
	
	return( self );
} // init

//---------------------------------------------------------------------------

- (void) dealloc
{
	if( mpDrawElements != NULL )
	{
		if( mpDrawElements->params != NULL )
		{
			free( mpDrawElements->params );
		} // if
		
		free( mpDrawElements );
		
		mpDrawElements = NULL;
	} // if
	
	[super dealloc];
} // dealloc

//---------------------------------------------------------------------------

- (void) setDictionary:(NSDictionary *)theDictionary
{
	if( theDictionary )
	{
		if( mpDrawElements->params != NULL )
		{
			free( mpDrawElements->params );
			
			mpDrawElements->count  = 0;
			mpDrawElements->size   = 0;
			mpDrawElements->params = NULL;
		} // if
		
		NSDictionary *elements = [theDictionary objectForKey:@"Parameters"];
		
		if( elements )
		{
			NSNumber *count = [elements objectForKey:@"Rows"]; 
			
			if( count )
			{
				mpDrawElements->count  = [count integerValue];
				mpDrawElements->size   = mpDrawElements->count * sizeof(OpenGLDEParams);
				mpDrawElements->params = (OpenGLDEParamsRef)calloc(1, mpDrawElements->size); 
				
				if( mpDrawElements->params != NULL )
				{
					NSArray *table = [elements objectForKey:@"Table"];
					
					if( table )
					{
						NSArray *element;
						
						GLuint i = 0;
						
						for( element in table )
						{
							mpDrawElements->params[i].mode   = [[element objectAtIndex:0] intValue];
							mpDrawElements->params[i].count  = [[element objectAtIndex:1] intValue];
							mpDrawElements->params[i].type   = [[element objectAtIndex:2] intValue];
							mpDrawElements->params[i].offset = [[element objectAtIndex:3] intValue];
							
							i++;
						} // for
					} // if
				} // if
			} // if
		} // if
	} // if
} // setDictionary

//---------------------------------------------------------------------------

- (void) drawElements
{
	glEnableClientState(GL_NORMAL_ARRAY);
	glEnableClientState(GL_VERTEX_ARRAY);
	{
		GLuint i;
		
		for( i = 0; i < mpDrawElements->count; i++ )
		{
			glDrawElements(mpDrawElements->params[i].mode,
						   mpDrawElements->params[i].count,
						   mpDrawElements->params[i].type,
						   BUFFER_OFFSET(mpDrawElements->params[i].offset));
		} // for
	}
	glDisableClientState(GL_VERTEX_ARRAY);
	glDisableClientState(GL_NORMAL_ARRAY);
} // drawElements

//---------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
