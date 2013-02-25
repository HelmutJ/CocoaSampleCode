//---------------------------------------------------------------------------
//
//	File: MemObject.m
//
//  Abstract: Class that implements a container for memory allocation.
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

#include "Memory.h"

#import "MemObject.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

struct MemoryAttributes
{
	size_t        size;
	void         *pointer;
	MemAllocType  type;
};

typedef struct MemoryAttributes  MemoryAttributes;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

@implementation MemObject

//---------------------------------------------------------------------------

- (id) initMemoryWithType:(MemAllocType)theMemAllocType  size:(const size_t)theMemSize
{
	self = [super init];
	
	if ( self )
	{
		memory = (MemoryAttributesRef)MemAlloc( sizeof(MemoryAttributes) );
		
		if ( memory != NULL )
		{
			memory->size = theMemSize;
			memory->type = theMemAllocType;
			
			switch ( memory->type )
			{
				case kVMemAlloc:
					memory->pointer = VMemAlloc(memory->size);
					break;
				
				case kMemAlloc:
				default:
					memory->pointer = MemAlloc(memory->size);
					break;
			} // switch
		} // if
	} // if
	
	return  self;
} // initMemoryWithType

//------------------------------------------------------------------------

+ (id) memoryWithType:(MemAllocType)theMemAllocType  size:(const size_t)theMemSize
{
	return  [[[MemObject allocWithZone:[self zone]] 
						initMemoryWithType:theMemAllocType size:theMemSize] autorelease];
} // memoryWithType

//------------------------------------------------------------------------

- (void) dealloc
{
	switch ( memory->type )
	{
		case kVMemAlloc:
			VMemFree(memory->size, memory->pointer);
			break;
		
		case kMemAlloc:
		default:
			MemFree(memory->pointer);
			break;
	} // switch
	
	MemFree( memory );
	
	[super dealloc];
} // dealloc

//------------------------------------------------------------------------

- (void *) pointer
{
	return  memory->pointer;
} // pointer

//------------------------------------------------------------------------

- (BOOL) isPointerValid
{
	BOOL memChecked = NO;
	
	if ( memory->pointer != NULL )
	{
		memChecked = YES;
	} // if

	return  memChecked;
} // isPointerValid

//------------------------------------------------------------------------

@end

//------------------------------------------------------------------------

//------------------------------------------------------------------------


