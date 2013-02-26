//---------------------------------------------------------------------------
//
//	File: OpenGLPixelFormatAttribDictUtilityToolkit.m
//
//  Abstract: Utility toolkit for a default dictionary of pixel format
//            attributes
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

//------------------------------------------------------------------------

#import "OpenGLPixelFormatAttributes.h"
#import "OpenGLPixelFormatAttribDictUtilityToolkit.h"

//------------------------------------------------------------------------

//------------------------------------------------------------------------

@implementation OpenGLPixelFormatAttribDictUtilityToolkit

//------------------------------------------------------------------------

- (id) initWithOpenGLPixelFormatAttributesDefaultDictionary
{	
	self = [super init];
			
	// These are the pixel format attribute keys that require a boolean value
	
	NSArray *thePixelFormatAttributeKeysRepBoolValue 
						= [NSArray arrayWithObjects:	kOpenGLPixelFormatAttributeAllRenderers, 
														kOpenGLPixelFormatAttributeDoubleBuffer, 
														kOpenGLPixelFormatAttributeStereo, 
														kOpenGLPixelFormatAttributeMinimumPolicy,
														kOpenGLPixelFormatAttributeMaximumPolicy, 
														kOpenGLPixelFormatAttributeOffScreen, 
														kOpenGLPixelFormatAttributeFullScreen, 
														kOpenGLPixelFormatAttributeSingleRenderer,
														kOpenGLPixelFormatAttributeNoRecovery, 
														kOpenGLPixelFormatAttributeAccelerated, 
														kOpenGLPixelFormatAttributeClosestPolicy, 
														kOpenGLPixelFormatAttributeRobust,
														kOpenGLPixelFormatAttributeBackingStore, 
														kOpenGLPixelFormatAttributeWindow, 
														kOpenGLPixelFormatAttributeMultiScreen, 
														kOpenGLPixelFormatAttributeCompliant,
														kOpenGLPixelFormatAttributePixelBuffer, 
														kOpenGLPixelFormatAttributeMultisample,
														nil];
	
	pixelFormatAttributeKeysBoolValueSet 
			= [[NSMutableSet alloc] initWithArray:thePixelFormatAttributeKeysRepBoolValue];
	
	// These are the pixel format attribute keys that require an integer value

	NSArray *thePixelFormatAttributeKeysRepIntValue 
						= [NSArray arrayWithObjects:	kOpenGLPixelFormatAttributeAuxBuffers, 
														kOpenGLPixelFormatAttributeColorSize, 
														kOpenGLPixelFormatAttributeAlphaSize, 
														kOpenGLPixelFormatAttributeDepthSize,
														kOpenGLPixelFormatAttributeStencilSize, 
														kOpenGLPixelFormatAttributeAccumSize, 
														kOpenGLPixelFormatAttributeRendererID, 
														kOpenGLPixelFormatAttributeScreenMask,
														kOpenGLPixelFormatAttributeSampleBuffers,
														kOpenGLPixelFormatAttributeSamples,
														nil];
	
	pixelFormatAttributeKeysIntValueSet 
			= [[NSMutableSet alloc] initWithArray:thePixelFormatAttributeKeysRepIntValue];

	// Now construct a dictionary that maps pixels format attribute keys 
	// [that require boolean and integer values] into their equivalent 
	// numerical representation
	
	NSInteger thePixelFormatAttributeDefaultKeysCount 
						= [thePixelFormatAttributeKeysRepBoolValue count] + [thePixelFormatAttributeKeysRepIntValue count];
						
	NSMutableArray *thePixelFormatAttributeDefaultKeys 
						= [NSMutableArray arrayWithCapacity:thePixelFormatAttributeDefaultKeysCount];
	
	[thePixelFormatAttributeDefaultKeys addObjectsFromArray:thePixelFormatAttributeKeysRepBoolValue];
	[thePixelFormatAttributeDefaultKeys addObjectsFromArray:thePixelFormatAttributeKeysRepIntValue];
	
	NSArray *thePixelFormatAttributeDefaultKeysIntRep 
						= [NSArray arrayWithObjects:	[NSNumber numberWithInt:NSOpenGLPFAAllRenderers],
														[NSNumber numberWithInt:NSOpenGLPFADoubleBuffer],
														[NSNumber numberWithInt:NSOpenGLPFAStereo],
														[NSNumber numberWithInt:NSOpenGLPFAMinimumPolicy],
														[NSNumber numberWithInt:NSOpenGLPFAMaximumPolicy],
														[NSNumber numberWithInt:NSOpenGLPFAOffScreen],
														[NSNumber numberWithInt:NSOpenGLPFAFullScreen],
														[NSNumber numberWithInt:NSOpenGLPFASingleRenderer],
														[NSNumber numberWithInt:NSOpenGLPFANoRecovery],
														[NSNumber numberWithInt:NSOpenGLPFAAccelerated],
														[NSNumber numberWithInt:NSOpenGLPFAClosestPolicy],
														[NSNumber numberWithInt:NSOpenGLPFARobust],
														[NSNumber numberWithInt:NSOpenGLPFABackingStore],
														[NSNumber numberWithInt:NSOpenGLPFAWindow],
														[NSNumber numberWithInt:NSOpenGLPFAMultiScreen],
														[NSNumber numberWithInt:NSOpenGLPFACompliant],
														[NSNumber numberWithInt:NSOpenGLPFAPixelBuffer],
														[NSNumber numberWithInt:NSOpenGLPFAMultisample],
														[NSNumber numberWithInt:NSOpenGLPFAAuxBuffers],
														[NSNumber numberWithInt:NSOpenGLPFAColorSize],
														[NSNumber numberWithInt:NSOpenGLPFAAlphaSize],
														[NSNumber numberWithInt:NSOpenGLPFADepthSize],
														[NSNumber numberWithInt:NSOpenGLPFAStencilSize],
														[NSNumber numberWithInt:NSOpenGLPFAAccumSize],
														[NSNumber numberWithInt:NSOpenGLPFARendererID],
														[NSNumber numberWithInt:NSOpenGLPFAScreenMask],
														[NSNumber numberWithInt:NSOpenGLPFASampleBuffers],
														[NSNumber numberWithInt:NSOpenGLPFASamples],
														nil];

	pixelFormatAttributesDefaultDictionary 
			= [[NSMutableDictionary alloc ] initWithObjects:thePixelFormatAttributeDefaultKeysIntRep
											forKeys:thePixelFormatAttributeDefaultKeys];

	return self;
} // initWithOpenGLPixelFormatAttributeDictionary

//------------------------------------------------------------------------

+ (id) withOpenGLPixelFormatAttributesDefaultDictionary
{
	return  [[[OpenGLPixelFormatAttribDictUtilityToolkit allocWithZone:[self zone]] 
					initWithOpenGLPixelFormatAttributesDefaultDictionary] autorelease];
} // withOpenGLPixelFormatAttributeDefaultDictionary

//------------------------------------------------------------------------

- (void) dealloc
{
	if ( pixelFormatAttributeKeysBoolValueSet )
	{
		[pixelFormatAttributeKeysBoolValueSet release];
	} // if
	
	if ( pixelFormatAttributeKeysIntValueSet )
	{
		[pixelFormatAttributeKeysIntValueSet release];
	} // if
	
	if ( pixelFormatAttributesDefaultDictionary )
	{
		[pixelFormatAttributesDefaultDictionary release];
	} // if
	
	// Notify the superclass
	
	[super dealloc];
} // dealloc

//------------------------------------------------------------------------

- (BOOL) containsKeyMappingIntoBoolValue:(NSString *)thePixelFormatAttributeKey
{
	return [pixelFormatAttributeKeysBoolValueSet containsObject:thePixelFormatAttributeKey];
} // containsKeyMappingIntoBoolValue

//------------------------------------------------------------------------

- (BOOL) containsKeyMappingIntoIntValue:(NSString *)thePixelFormatAttributeKey
{
	return [pixelFormatAttributeKeysIntValueSet containsObject:thePixelFormatAttributeKey];
} // containsKeyMappingIntoIntValue

//------------------------------------------------------------------------

- (NSInteger) getIntValueForTheKey:(NSString *)thePixelFormatAttributeKey
{
	NSNumber  *thePixelAttributeFormatKeyNumRep 
					= [pixelFormatAttributesDefaultDictionary objectForKey:thePixelFormatAttributeKey];
					
	NSInteger  thePixelAttributeFormatKeyIntRep 
					= [thePixelAttributeFormatKeyNumRep integerValue];
	
	return  thePixelAttributeFormatKeyIntRep;
} // getIntValueForTheKey

//------------------------------------------------------------------------

//------------------------------------------------------------------------

@end

//------------------------------------------------------------------------

//------------------------------------------------------------------------

