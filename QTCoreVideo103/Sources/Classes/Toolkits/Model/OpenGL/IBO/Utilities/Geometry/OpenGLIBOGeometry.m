//---------------------------------------------------------------------------
//
//	File: OpenGLIBOGeometry.m
//
//  Abstract: Utility class to deserialize a property list that describes
//            a IBO normals, vertices, colors, and texture coordinates.
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

#import "OpenGLIBOGeometry.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Data Structures

//---------------------------------------------------------------------------

struct OpenGLArray
{
	GLsizeiptr   count;
	GLsizeiptr   size;
	GLfloat     *values;
};

typedef struct OpenGLArray   OpenGLArray;
typedef struct OpenGLArray  *OpenGLArrayRef;

//---------------------------------------------------------------------------

struct OpenGLIBOGeometryData
{
	GLsizeiptr      count;
	GLsizeiptr      size;
	OpenGLArrayRef  arrays;
};

typedef struct OpenGLIBOGeometryData   OpenGLIBOGeometryData;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Utilites

//---------------------------------------------------------------------------

static OpenGLIBOGeometryDataRef  OpenGLIBOGeometryCreateFromTable(const GLsizeiptr rowCount,
                                                                  const GLsizeiptr rowSize,
                                                                  NSArray *table)
{
	OpenGLIBOGeometryDataRef pGeometry = NULL;
    
	GLsizeiptr colCount = [table count];
	
	if( colCount > 0 )
	{
		pGeometry = (OpenGLIBOGeometryDataRef)calloc(1, sizeof(OpenGLIBOGeometryData));
		
		if( pGeometry != NULL )
		{
			pGeometry->count  = colCount;
			pGeometry->size   = pGeometry->count * sizeof(OpenGLArray);
			pGeometry->arrays = (OpenGLArrayRef)calloc(1, pGeometry->size);
			
			if( pGeometry->arrays != NULL )
			{
				GLsizeiptr   colIndex;
				GLsizeiptr   rowIndex;
				NSArray     *column;
				NSNumber    *value;
				
				for( colIndex = 0; colIndex < pGeometry->count; ++colIndex )
				{
					pGeometry->arrays[colIndex].count  = rowCount;
					pGeometry->arrays[colIndex].size   = rowSize;
					pGeometry->arrays[colIndex].values = (GLfloat *)calloc(1, rowSize);
					
					if( pGeometry->arrays[colIndex].values != NULL )
					{
						column = [table objectAtIndex:colIndex];
						
						if( column )
						{
							for( rowIndex = 0; rowIndex < rowCount; ++rowIndex )
							{
								value = [column objectAtIndex:rowIndex];
								
								if( value )
								{
									pGeometry->arrays[colIndex].values[rowIndex] = [value floatValue];
								} // if
							} // for
						} // if
					} // if
				} // for
			} // if
		} // if
	} // if
	
	return( pGeometry );
} // OpenGLIBOGeometryCreateFromTable

//---------------------------------------------------------------------------

static OpenGLIBOGeometryDataRef  OpenGLIBOGeometryCreateFromDictionary(NSDictionary *pDictionary)
{
	OpenGLIBOGeometryDataRef pGeometry = NULL;

    if( pDictionary )
    {
        NSDictionary *geometry = [pDictionary objectForKey:@"Geometry"];
        
        if( geometry )
        {
            NSNumber *rows = [geometry objectForKey:@"Rows"]; 
            
            if( rows )
            {
                GLsizeiptr rowCount = [rows integerValue];
                GLsizeiptr rowSize  = rowCount * sizeof(GLfloat);
                
                NSArray *table = [geometry objectForKey:@"Table"];
                
                if( table )
                {
                    pGeometry = OpenGLIBOGeometryCreateFromTable(rowCount,rowSize,table);
                } // if
            } // if
        } // if
    } // if
    
    return( pGeometry );
} // OpenGLIBOGeometryCreateFromDictionary

//---------------------------------------------------------------------------

static void OpenGLIBOGeometryDelete(OpenGLIBOGeometryDataRef pGeometry)
{
	if( pGeometry != NULL )
	{
		if( pGeometry->arrays != NULL )
		{
			GLsizeiptr i;
			
			for( i = 0; i < pGeometry->count; ++i )
			{
				if( pGeometry->arrays[i].values != NULL )
				{
					free( pGeometry->arrays[i].values );
                    
                    pGeometry->arrays[i].values = NULL;
				} // if
			} // for
			
			free( pGeometry->arrays );
            
            pGeometry->arrays = NULL;
		} // if
		
		free( pGeometry );
		
		pGeometry = NULL;
	} // if
} // OpenGLIBOGeometryDelete

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -

//---------------------------------------------------------------------------


@implementation OpenGLIBOGeometry

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

- (id) initGeometryWithDictionary:(NSDictionary *)theDictionary
{
	self = [super init];
	
	if( self )
	{
        mpGeometry = OpenGLIBOGeometryCreateFromDictionary(theDictionary);
	} // if
	
	return( self );
} // initGeometryWithDictionary

//---------------------------------------------------------------------------

- (void) dealloc
{
    OpenGLIBOGeometryDelete(mpGeometry);
    
	[super dealloc];
} // dealloc

//---------------------------------------------------------------------------

- (GLsizeiptr) count
{
	return( mpGeometry->arrays[0].count );
} // count

//---------------------------------------------------------------------------

- (GLsizeiptr) size
{
	return( mpGeometry->arrays[0].size );
} // size

//---------------------------------------------------------------------------

- (GLfloat *) normals
{
	return( mpGeometry->arrays[0].values );
} // normals

//---------------------------------------------------------------------------

- (GLfloat *) vertices
{
	return( mpGeometry->arrays[1].values );
} // vertices

//---------------------------------------------------------------------------

- (GLfloat *) colors
{
	return( mpGeometry->arrays[2].values );
} // vertices

//---------------------------------------------------------------------------

- (GLfloat *) texcoords
{
	return( mpGeometry->arrays[3].values );
} // vertices

//---------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
