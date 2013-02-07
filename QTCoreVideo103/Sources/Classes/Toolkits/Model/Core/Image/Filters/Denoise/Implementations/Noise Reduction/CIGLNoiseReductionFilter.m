//---------------------------------------------------------------------------------
//
//	File: CIGLNoiseReductionFilter.m
//
// Abstract: Utility class for managing Core Image noise reduction filter.
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
//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#import "CIGLNoiseReductionFilter.h"

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Methods

//---------------------------------------------------------------------------------

@interface CIGLNoiseReductionFilter(Private)

- (BOOL) setInputs:(const CGFloat)theInputValue
           atIndex:(const GLuint)theIndex;

@end

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -

//---------------------------------------------------------------------------------

@implementation CIGLNoiseReductionFilter

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Designated Initializers

//---------------------------------------------------------------------------------

- (id) initNoiseReductionFilterFromFile:(NSString *)thePathname
                                context:(NSOpenGLContext *)theContext
                                 format:(NSOpenGLPixelFormat *)theFormat;
{
	self = [super initFilterFromFile:thePathname
                             context:theContext
                              format:theFormat
                              filter:@"CINoiseReduction"];
    
    if( !self )
    {
        NSLog(@">> ERROR: CI GL Noise Reduction Filter - Failed instantiating the base class!");
    } // if
	
	return( self );
} // initNoiseReductionFilterFromFile

//---------------------------------------------------------------------------------

- (id) initNoiseReductionFilterWithData:(NSData *)theData
                                context:(NSOpenGLContext *)theContext
                                 format:(NSOpenGLPixelFormat *)theFormat
{
	self = [super initFilterWithData:theData
                             context:theContext
                              format:theFormat
                              filter:@"CINoiseReduction"];
    
    if( !self )
    {
        NSLog(@">> ERROR: CI GL Noise Reduction Filter - Failed instantiating the base class!");
    } // if
	
	return( self );
} // initNoiseReductionFilterWithData

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Destructor

//---------------------------------------------------------------------------------

- (void) dealloc
{
    if( inputs[0] )
    {
        [inputs[0] release];
        
        inputs[0] = nil;
    } // if
    
    if( inputs[1] )
    {
        [inputs[1] release];
        
        inputs[1] = nil;
    } // if
    
	[super dealloc];
} // dealloc

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Utilities

//---------------------------------------------------------------------------------

- (void) update
{
    // Get the noise reduction filter from the base class
    CIFilter *filter = [self filter];
    
    // Enable render to texture
    [self enable];
    
	// Update values for noise reduction filter's noise level
	[filter setValue:inputs[0]
              forKey:@"inputNoiseLevel"];
    
	// Update values for noise reduction filter's sharpness level
	[filter setValue:inputs[1]
              forKey:@"inputSharpness"];
	
    // Render to texture
	[self render];
    
    // Disable render to texture
    [self disable];
} // update

//---------------------------------------------------------------------------------

- (BOOL) updateWithData:(NSData *)theData
{
    BOOL success = [super updateWithData:theData];
    
    if( success )
    {
        [self update];
    } // if
    
	return( success );
} // updateWithData

//---------------------------------------------------------------------------------

- (BOOL) updateFromFile:(NSString *)thePathname
{
    BOOL success = [super updateFromFile:thePathname];
    
    if( success )
    {
        [self update];
    } // if
    
	return( success );
} // updateFromFile

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Accessors

//---------------------------------------------------------------------------------

- (BOOL) setInputs:(const CGFloat)theInputValue
           atIndex:(const GLuint)theIndex
{
    NSNumber *input = [NSNumber numberWithDouble:theInputValue];
    
    BOOL success = input != nil;
    
    if( success )
    {
        [inputs[theIndex] release];
        
        inputs[theIndex] = [input retain];
        
        [self update];
    } // if
    
    return( success );
} // setInputs

//---------------------------------------------------------------------------------
//
// The input is between 0.0 to 100.0.  Scale the value to 0.0 to 0.10 for Core 
// Image noise reduction filter.
//
//---------------------------------------------------------------------------------

- (BOOL) setNoiseLevel:(const CGFloat)theNoiseLevel
{
	CGFloat noiseLevelScaled = theNoiseLevel * 0.001f;
	
    return( [self setInputs:noiseLevelScaled 
                    atIndex:0] );
} // setNoiseLevel

//---------------------------------------------------------------------------------
//
// The input is between 0.0 to 100.0.  Scale the value to 0.0 to 2.0 for Core 
// Image noise reduction filter.
//
//---------------------------------------------------------------------------------

- (BOOL) setSharpness:(const CGFloat)theSharpness
{
	CGFloat sharpnessScaled = theSharpness * 0.02f;
	
    return( [self setInputs:sharpnessScaled 
                    atIndex:1] );
} // setSharpness

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------

