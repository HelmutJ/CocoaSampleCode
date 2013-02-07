//------------------------------------------------------------------------------------------
//
//	File: OpenGLNumberUtilities.m
//
//  Abstract: Some common utility methods for OpenGL.
// 			 
//  Disclaimer: IMPORTANT:  This Apple software is supplied to you by
//  Inc. ("Apple") in consideration of your agreement to the following terms, 
//  and your use, installation, modification or redistribution of this Apple 
//  software constitutes acceptance of these terms.  If you do not agree with 
//  these terms, please do not use, install, modify or redistribute this 
//  Apple software.
//  
//  In consideration of your agreement to abide by the following terms, and
//  subject to these terms, Apple grants you a personal, non-exclusive
//  license, under Apple's copyrights in this original Apple software (the
//  "Apple Software"), to use, reproduce, modify and redistribute the Apple
//  Software, with or without modifications, in source and/or binary forms;
//  provided that if you redistribute the Apple Software in its entirety and
//  without modifications, you must retain this notice and the following
//  text and disclaimers in all such redistributions of the Apple Software. 
//  Neither the name, trademarks, service marks or logos of Apple Inc. may
//  be used to endorse or promote products derived from the Apple Software 
//  without specific prior written permission from Apple.  Except as 
//  expressly stated in this notice, no other rights or licenses, express
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
//  Copyright (c) 2011 Apple Inc., All rights reserved.
//
//-------------------------------------------------------------------------------------------

//-------------------------------------------------------------------------------------------

#import <OpenGL/glu.h>

//-------------------------------------------------------------------------------------------

#import "OpenGLSizes.h"

//-------------------------------------------------------------------------------------------

#import "OpenGLUtilities.h"

//-------------------------------------------------------------------------------------------

//-------------------------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Constants

//-------------------------------------------------------------------------------------------

static const GLubyte *kGLARBTextureNPOT = (const GLubyte *)"GL_ARB_texture_non_power_of_two";

//-------------------------------------------------------------------------------------------

//-------------------------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Utilities

//-------------------------------------------------------------------------------------------

GLuint OpenGLUtilitiesGetSPP(const GLenum nType)
{
    GLuint nSize = 0;
    
    switch( nType )
    {
        case GL_BYTE:
            nSize = kOpenGLSizeSignedByte;
            break;
            
        case GL_UNSIGNED_BYTE:
        case GL_UNSIGNED_BYTE_3_3_2:
        case GL_UNSIGNED_BYTE_2_3_3_REV:
            nSize = kOpenGLSizeUnsignedByte;
            break;
            
        case GL_SHORT:
            nSize = kOpenGLSizeSignedShort;
            break;
        
        case GL_UNSIGNED_SHORT:
        case GL_UNSIGNED_SHORT_4_4_4_4:
        case GL_UNSIGNED_SHORT_5_5_5_1:
        case GL_UNSIGNED_SHORT_5_6_5:
        case GL_UNSIGNED_SHORT_5_6_5_REV:
        case GL_UNSIGNED_SHORT_4_4_4_4_REV:
        case GL_UNSIGNED_SHORT_1_5_5_5_REV:
        case GL_UNSIGNED_SHORT_8_8_APPLE:
        case GL_UNSIGNED_SHORT_8_8_REV_APPLE:
            nSize = kOpenGLSizeUnsignedShort;
            break;
            
        case GL_INT:
            nSize = kOpenGLSizeSignedInt;
            break;
            
        case GL_HALF_FLOAT:
            nSize = kOpenGLSizeHalfFloat;
            break;
            
        case GL_FLOAT:
            nSize = kOpenGLSizeFloat;
            break;
            
        case GL_DOUBLE:
            nSize = kOpenGLSizeDouble;
            break;
            
        case GL_2_BYTES:
            nSize = kOpenGLSize2Bytes;
            break;
            
        case GL_3_BYTES:
            nSize = kOpenGLSize3Bytes;
            break;
            
        case GL_4_BYTES:
            nSize = kOpenGLSize4Bytes;
            break;
            
        case GL_UNSIGNED_INT:
        case GL_UNSIGNED_INT_8_8_8_8:
        case GL_UNSIGNED_INT_10_10_10_2:
        case GL_UNSIGNED_INT_8_8_8_8_REV:
        case GL_UNSIGNED_INT_2_10_10_10_REV:
        default:
            nSize = kOpenGLSizeUnsignedInt;
            break;
    } // switch
    
	return( nSize );
} // OpenGLUtilitiesGetSPP

//-------------------------------------------------------------------------------------------

GLuint OpenGLUtilitiesGetPOT(GLuint nValue)
{
	--nValue;

	nValue |= (nValue >> 1);
	nValue |= (nValue >> 2);
	nValue |= (nValue >> 4);
	nValue |= (nValue >> 8);
	nValue |= (nValue >> 16);
	
	++nValue;
	
	return( nValue );
} // GetPOT

//-------------------------------------------------------------------------------------------

BOOL OpenGLUtilitiesTextureIsNPOT()
{
    const GLubyte *pGLExtString = glGetString(GL_EXTENSIONS);
    
    BOOL  bGLExtIsFound = gluCheckExtension(kGLARBTextureNPOT, pGLExtString);
    
    return( bGLExtIsFound );
} // OpenGLUtilitiesTextureIsNPOT

//-------------------------------------------------------------------------------------------

//-------------------------------------------------------------------------------------------
