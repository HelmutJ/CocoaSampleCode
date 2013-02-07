//---------------------------------------------------------------------------
//
//	File: OpenGLIBOIndices.h
//
//  Abstract: Utility class to deserialize a property list that describes
//            a VBO's elements.
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

#import "OpenGLIBOElements.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Data Structures

//---------------------------------------------------------------------------

struct OpenGLIBOElementData
{
	GLsizeiptr   count;
	GLsizeiptr   size;
	GLshort     *array;
};

typedef struct OpenGLIBOElementData   OpenGLIBOElementData;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

@implementation OpenGLIBOElements

//---------------------------------------------------------------------------

- (id) initElementsWithDictionary:(NSDictionary *)theDictionary
{
	self = [super init];
	
	if( self )
	{
		mpElements = (OpenGLIBOElementDataRef)calloc(1, sizeof(OpenGLIBOElementData));
		
		if( mpElements != NULL )
		{
			NSDictionary *elements = [theDictionary objectForKey:@"Elements"];
			
			if( elements )
			{
				NSNumber *count = [elements objectForKey:@"Columns"]; 
				
				mpElements->count = [count integerValue];
				mpElements->size  = mpElements->count * sizeof(GLshort);
				mpElements->array = (GLshort *)calloc(1, mpElements->size); 
				
				if( mpElements->array != NULL )
				{
					NSArray *table = [elements objectForKey:@"Table"];
					
					if( table )
					{
						NSArray   *row = [table objectAtIndex:0];
						NSNumber  *item = nil;
						GLuint     i    = 0;
						
						for( item in row )
						{
							mpElements->array[i] = [item shortValue];
							
							i++;
						} // for
					} // if
				} // if
			} // if
		} // if
	} // if
	
	return( self );
} // initElementsWithDictionary

//---------------------------------------------------------------------------

- (void) dealloc
{
	if( mpElements != NULL )
	{
		if( mpElements->array != NULL )
		{
			free( mpElements->array );
		} // if
        
		free( mpElements );
		
		mpElements = NULL;
	} // if
	
	[super dealloc];
} // dealloc

//---------------------------------------------------------------------------

- (GLsizeiptr) count
{
	return( mpElements->count );
} // count

//---------------------------------------------------------------------------

- (GLsizeiptr) size
{
	return( mpElements->size );
} // size

//---------------------------------------------------------------------------

- (GLshort *) array
{
	return( mpElements->array );
} // array

//---------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
