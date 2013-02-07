//---------------------------------------------------------------------------
//
//	File: OpenGLPixelAttributes.m
//
//  Abstract: Utility class to parse property list file and obtain the
//            desired pixel format attributes.
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
//  Copyright (c) 2009-2011 Apple Inc., All rights reserved.
//
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#import "OpenGLPixelAttributes.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Data Structures

//---------------------------------------------------------------------------

struct OpenGLPixelFormatAttribute
{
	NSInteger count;
    
	NSOpenGLPixelFormatAttribute  *attribute;
};

typedef struct OpenGLPixelFormatAttribute  OpenGLPixelFormatAttribute;

//---------------------------------------------------------------------------

struct OpenGLPixelAttributesData
{
	OpenGLPixelFormatAttribute  expected;
	OpenGLPixelFormatAttribute  fallback;
};

typedef struct OpenGLPixelAttributesData  OpenGLPixelAttributesData;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Utilities - Strings

//---------------------------------------------------------------------------

static BOOL NSStringOrderedSame(NSString *string1, NSString *string2)
{
	NSComparisonResult result = [string1 compare:string2];
	
	return( result == NSOrderedSame );
} // NSStringOrderedSame

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Utilities - Pixel Format Attribute

//---------------------------------------------------------------------------

static NSOpenGLPixelFormatAttribute *NSOpenGLPixelFormatAttributeCreateWithArray( NSMutableArray *pfMArray )
{
	NSOpenGLPixelFormatAttribute *pfData = NULL;
	
	NSInteger pfDataCount = [pfMArray count];
	
	if( pfDataCount )
	{
		pfData = (NSOpenGLPixelFormatAttribute *)calloc(pfDataCount, sizeof(NSOpenGLPixelFormatAttribute));
		
		if( pfData != NULL )
		{
			NSInteger i = 0;
			
			NSNumber *pfDataNum;
			
			for( pfDataNum in pfMArray )
			{
				pfData[i] = [pfDataNum unsignedIntValue];
				
				i++;
			} // for
		} // if
	} // if
	
	return( pfData );
} // NSOpenGLPixelFormatAttributeCreateWithArray

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Utilities - Pixel Format

//---------------------------------------------------------------------------

static void OpenGLPixelAttributesSetFlags(NSDictionary *pfFlagsDict, 
                                          NSMutableArray *pfMArray)
{
	if( pfFlagsDict )
	{
		NSArray *keys = [NSArray arrayWithObjects:@"Accelerated",
						 @"Accelerated Compute",
						 @"Allow Offline Renderers",
						 @"Aux Depth Stencil",
						 @"Backing Store",
						 @"Closest Color Buffer",
						 @"Color Float",
						 @"Compliant",
						 @"Double Buffer",
						 @"MP Safe",
						 @"Multisample",
						 @"MultiScreen",
						 @"No Recovery",
						 @"Robust",
						 @"Sample Alpha",
						 @"Stereo Buffering",
						 @"Supersample",
						 @"Window",
						 nil];
		
		NSArray *objects = [NSArray arrayWithObjects:[NSNumber numberWithUnsignedInt:NSOpenGLPFAAccelerated],
							[NSNumber numberWithUnsignedInt:NSOpenGLPFAAcceleratedCompute],
							[NSNumber numberWithUnsignedInt:NSOpenGLPFAAllowOfflineRenderers],
							[NSNumber numberWithUnsignedInt:NSOpenGLPFAAuxDepthStencil],
							[NSNumber numberWithUnsignedInt:NSOpenGLPFABackingStore],
							[NSNumber numberWithUnsignedInt:NSOpenGLPFAClosestPolicy],
							[NSNumber numberWithUnsignedInt:NSOpenGLPFAColorFloat],
							[NSNumber numberWithUnsignedInt:NSOpenGLPFACompliant],
							[NSNumber numberWithUnsignedInt:NSOpenGLPFADoubleBuffer],
							[NSNumber numberWithUnsignedInt:NSOpenGLPFAMPSafe],
							[NSNumber numberWithUnsignedInt:NSOpenGLPFAMultisample],
							[NSNumber numberWithUnsignedInt:NSOpenGLPFAMultiScreen],
							[NSNumber numberWithUnsignedInt:NSOpenGLPFANoRecovery],
							[NSNumber numberWithUnsignedInt:NSOpenGLPFARobust],
							[NSNumber numberWithUnsignedInt:NSOpenGLPFASampleAlpha],
							[NSNumber numberWithUnsignedInt:NSOpenGLPFAStereo],
							[NSNumber numberWithUnsignedInt:NSOpenGLPFASupersample],
							[NSNumber numberWithUnsignedInt:NSOpenGLPFAWindow],
							nil];
        
		NSDictionary *pfFlagData = [[NSDictionary alloc] initWithObjects:objects
                                                                 forKeys:keys];
		
		if( pfFlagData )
		{
			NSString *pfFlagsKey;
			NSNumber *pfFlag;
			
			for( pfFlagsKey in pfFlagsDict )
			{
				pfFlag = [pfFlagsDict objectForKey:pfFlagsKey];
				
				if( [pfFlag boolValue] )
				{					
					[pfMArray addObject:[pfFlagData objectForKey:pfFlagsKey]];
				} // if
			} // for
            
			[pfFlagData release];
		} // if
	} // if
} // OpenGLPixelAttributesSetFlags

//---------------------------------------------------------------------------

static void OpenGLPixelAttributesSetMixedData(NSDictionary *pfDict, 
                                              NSSet *pfNumSet,
                                              NSArray *pfObjects,
                                              NSArray *pfKeys,
                                              NSMutableArray *pfMArray)
{
	if( pfDict )
	{
		NSString *pfVal;
		NSString *pfKey;
		NSNumber *pfNum;
		
		NSDictionary *pfData = [[NSDictionary alloc] initWithObjects:pfObjects
                                                             forKeys:pfKeys];
		
		if( pfData )
		{
			for( pfKey in pfDict )
			{
				if( [pfNumSet containsObject:pfKey] )
				{
					pfNum = [pfDict objectForKey:pfKey];
					
					if( pfNum )
					{
						[pfMArray addObject:[pfData objectForKey:pfKey]];
						[pfMArray addObject:pfNum];
					} // if
				} // if
				else
				{
					pfVal = [pfDict objectForKey:pfKey];
					
					if( pfVal )
					{
						[pfMArray addObject:[pfData objectForKey:pfVal]];
					} // if
				} // else if
			} // for
			
			[pfData release];
		} // if
	} // if
} // OpenGLPixelAttributesSetMixedData

//---------------------------------------------------------------------------

static void OpenGLPixelAttributesSetBufferData(NSDictionary *pfBufferDict, 
                                               NSMutableArray *pfMArray)
{
	if( pfBufferDict )
	{
		NSSet *pfBufferNumSet = [NSSet setWithObjects:@"Aux Buffers",
								 @"Sample Buffers",
								 @"Samples Per Buffer",
								 nil];
		
		NSArray *pfBufferKeys = [NSArray arrayWithObjects:@"Aux Buffers",
								 @"Sample Buffers",
								 @"Samples Per Buffer",
								 @"Offline",
								 @"Online",
								 @"Minimum",
								 @"Maximum",
								 nil];
		
		NSArray *pfBufferObjects = [NSArray arrayWithObjects:[NSNumber numberWithUnsignedInt:NSOpenGLPFAAuxBuffers],
									[NSNumber numberWithUnsignedInt:NSOpenGLPFASampleBuffers],
									[NSNumber numberWithUnsignedInt:NSOpenGLPFASamples],
									[NSNumber numberWithUnsignedInt:NSOpenGLPFARemotePixelBuffer],
									[NSNumber numberWithUnsignedInt:NSOpenGLPFAPixelBuffer],
									[NSNumber numberWithUnsignedInt:NSOpenGLPFAMinimumPolicy],
									[NSNumber numberWithUnsignedInt:NSOpenGLPFAMaximumPolicy],
									nil];
		
		OpenGLPixelAttributesSetMixedData(pfBufferDict, 
                                          pfBufferNumSet,
                                          pfBufferObjects,
                                          pfBufferKeys,
                                          pfMArray);
	} // if
} // OpenGLPixelAttributesSetBufferData

//---------------------------------------------------------------------------

static void OpenGLPixelAttributesSetDisplayData(NSDictionary *pfDisplayDict, 
                                                NSMutableArray *pfMArray)
{
	if( pfDisplayDict )
	{
		NSSet *pfDisplayNumSet = [NSSet setWithObjects:@"Renderer ID",
								  @"Screen Mask",
								  @"Virtual Screens",
								  nil];
		
		NSArray *pfDisplayKeys = [NSArray arrayWithObjects:@"All Renderers",
								  @"Off Screen",
								  @"Full Screen",
								  @"Single Renderer",
								  @"Renderer ID",
								  @"Screen Mask",
								  @"Virtual Screens",
								  nil];
		
		NSArray *pfDisplayObjects = [NSArray arrayWithObjects:[NSNumber numberWithUnsignedInt:NSOpenGLPFAAllRenderers],
									 [NSNumber numberWithUnsignedInt:NSOpenGLPFAOffScreen],
									 [NSNumber numberWithUnsignedInt:NSOpenGLPFAFullScreen],
									 [NSNumber numberWithUnsignedInt:NSOpenGLPFASingleRenderer],
									 [NSNumber numberWithUnsignedInt:NSOpenGLPFARendererID],
									 [NSNumber numberWithUnsignedInt:NSOpenGLPFAScreenMask],
									 [NSNumber numberWithUnsignedInt:NSOpenGLPFAVirtualScreenCount],
									 nil];
		
		OpenGLPixelAttributesSetMixedData(pfDisplayDict, 
                                          pfDisplayNumSet,
                                          pfDisplayObjects,
                                          pfDisplayKeys,
                                          pfMArray);
	} // if
} // OpenGLPixelAttributesSetDisplayData

//---------------------------------------------------------------------------

static void OpenGLPixelAttributesSetSizes(NSDictionary *pfSizeDict, 
                                          NSMutableArray *pfMArray)
{
	if( pfSizeDict )
	{
		NSSet *pfSizeNumSet = [NSSet setWithObjects:@"Accum",
							   @"Alpha",
							   @"Color",
							   @"Depth",
							   @"Stencil",
							   nil];
		
		NSArray *pfSizeKeys = [NSArray arrayWithObjects:@"Accum",
							   @"Alpha",
							   @"Color",
							   @"Depth",
							   @"Stencil",
							   nil];
		
		NSArray *pfSizeObjects = [NSArray arrayWithObjects:[NSNumber numberWithUnsignedInt:NSOpenGLPFAAccumSize],
								  [NSNumber numberWithUnsignedInt:NSOpenGLPFAAlphaSize],
								  [NSNumber numberWithUnsignedInt:NSOpenGLPFAColorSize],
								  [NSNumber numberWithUnsignedInt:NSOpenGLPFADepthSize],
								  [NSNumber numberWithUnsignedInt:NSOpenGLPFAStencilSize],
								  nil];
		
		OpenGLPixelAttributesSetMixedData(pfSizeDict, 
                                          pfSizeNumSet,
                                          pfSizeObjects,
                                          pfSizeKeys,
                                          pfMArray);
	} // if
} // OpenGLPixelAttributesSetSizes

//---------------------------------------------------------------------------

static void OpenGLPixelAttributesCreateArray(NSDictionary *pfd,
                                             NSString *pfKey,
                                             NSMutableArray *pfMArray)
{
	if( pfd )
	{	
		NSString      *pfaKey;
		NSDictionary  *pfad;
		
		for( pfaKey in pfd )
		{
			pfad = [pfd objectForKey:pfaKey];
            
			if( NSStringOrderedSame(pfaKey,@"Buffers") )
			{
				OpenGLPixelAttributesSetBufferData( pfad, pfMArray );
			} // if
			else if( NSStringOrderedSame(pfaKey,@"Display") )
			{
				OpenGLPixelAttributesSetDisplayData( pfad, pfMArray );
			} // else if
			else if( NSStringOrderedSame(pfaKey,@"Flags") )
			{
				OpenGLPixelAttributesSetFlags( pfad, pfMArray );
			} // else if
			else if( NSStringOrderedSame(pfaKey,@"Size") )
			{
				OpenGLPixelAttributesSetSizes( pfad, pfMArray );
			} // else if
		} // for
		
		if( pfMArray )
		{
			[pfMArray addObject:[NSNumber numberWithBool:NO]];
		} // if
	} // if
} // OpenGLPixelAttributesCreateArray

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Constructor

//---------------------------------------------------------------------------

static OpenGLPixelAttributesDataRef OpenGLPixelAttributesCreate(NSDictionary *pPList)
{
    OpenGLPixelAttributesDataRef pPixelAttributes = NULL;
    
    if( pPList )
    {
        pPixelAttributes = (OpenGLPixelAttributesDataRef)calloc(1, sizeof(OpenGLPixelAttributesData));
        
        if( pPixelAttributes != NULL )
        {
            NSString       *pPListKey =  nil;
            NSDictionary   *pPADict    = nil;
            NSMutableArray *pPAMArray  = nil;
            
            pPixelAttributes->expected.attribute = NULL;
            pPixelAttributes->expected.count     = 0;
            pPixelAttributes->fallback.attribute = NULL;
            pPixelAttributes->fallback.count     = 0;
            
            for( pPListKey in pPList )
            {
                pPADict = [pPList objectForKey:pPListKey];
                
                if( pPADict )
                {
                    pPAMArray = [NSMutableArray new];
                    
                    if( pPAMArray )
                    {
                        OpenGLPixelAttributesCreateArray(pPADict, pPListKey, pPAMArray);
                        
                        if( NSStringOrderedSame(pPListKey,@"Expected") )
                        {
                            pPixelAttributes->expected.attribute = NSOpenGLPixelFormatAttributeCreateWithArray(pPAMArray);
                            pPixelAttributes->expected.count     = [pPAMArray count];
                        } // if
                        else if( NSStringOrderedSame(pPListKey,@"Fallback") )
                        {
                            pPixelAttributes->fallback.attribute = NSOpenGLPixelFormatAttributeCreateWithArray(pPAMArray);
                            pPixelAttributes->fallback.count     = [pPAMArray count];
                        } // else if
                        
                        [pPAMArray release];
                    } // if
                } // if
            } // for
        } // if
    } // if
    
    return( pPixelAttributes );
} // newPixelAttributesWithPListAtPath

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Destructor

//---------------------------------------------------------------------------

static void OpenGLPixelAttributesDelete(OpenGLPixelAttributesDataRef pPixelAttributes)
{
	if( pPixelAttributes != NULL )
	{
		if( pPixelAttributes->expected.attribute != NULL )
		{
			free(pPixelAttributes->expected.attribute);
            
            pPixelAttributes->expected.attribute = NULL;
		} // if
		
		if( pPixelAttributes->fallback.attribute != NULL )
		{
			free(pPixelAttributes->fallback.attribute);
            
            pPixelAttributes->fallback.attribute = NULL;
		} // if
		
		free(pPixelAttributes);
		
		pPixelAttributes = NULL;
	} // if
} // OpenGLPixelAttributesDelete

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Accessors

//---------------------------------------------------------------------------


static inline NSDictionary *OpenGLPixelAttributesGetDictionary(OpenGLPixelAttributes *pPixelAttribs)
{
    return( [[pPixelAttribs dictionary] objectForKey:@"Pixel Format"] );
} // OpenGLPixelAttributesGetDictionary

//---------------------------------------------------------------------------

static inline NSInteger OpenGLPixelAttributesGetCount(const BOOL selectExp,
                                                      OpenGLPixelAttributesDataRef pPixelAttributes)
{
	NSInteger pfac = 0;
	
	if( selectExp )
	{
		pfac = pPixelAttributes->expected.count;
	} // if
	else 
	{
		pfac = pPixelAttributes->fallback.count;
	} // else
	
	return( pfac );
} // OpenGLPixelAttributesGetCount

//---------------------------------------------------------------------------

static inline NSOpenGLPixelFormatAttribute * OpenGLPixelAttributesGetFormat(const BOOL selectExp,
                                                                            OpenGLPixelAttributesDataRef pPixelAttributes)
{
	NSOpenGLPixelFormatAttribute *pfa = NULL;
	
	if( selectExp )
	{
		pfa = pPixelAttributes->expected.attribute;
	} // if
	else 
	{
		pfa = pPixelAttributes->fallback.attribute;
	} // else
    
	return( pfa );
} // OpenGLPixelAttributesGetFormat

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

@implementation OpenGLPixelAttributes

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Designated Initializers

//---------------------------------------------------------------------------

- (id) initPListWithFileAtPath:(NSString *)thePListPath
{
	[self doesNotRecognizeSelector:_cmd];
	
	return( nil );
} // initPListWithFileAtPath

//---------------------------------------------------------------------------

- (id) initPListWithFileInAppBundle:(NSString *)thePListName
{
	[self doesNotRecognizeSelector:_cmd];
	
	return( nil );
} // initPListWithFileInAppBundle

//---------------------------------------------------------------------------

- (id) initPixelAttributesWithPListAtPath:(NSString *)thePListPath
{
	self = [super initPListWithFileAtPath:thePListPath];
	
	if( self )
	{
		NSDictionary *pPList = OpenGLPixelAttributesGetDictionary(self);
        
		mpPixelAttributes = OpenGLPixelAttributesCreate(pPList);
	} // if
	
	return( self );
} // initPixelAttributesWithPListAtPath

//---------------------------------------------------------------------------

- (id) initPixelAttributesWithPListInAppBundle:(NSString *)thePListName
{
	self = [super initPListWithFileInAppBundle:thePListName];
	
	if( self )
	{
		NSDictionary *pPList = OpenGLPixelAttributesGetDictionary(self);
        
		mpPixelAttributes = OpenGLPixelAttributesCreate(pPList);
	} // if
	
	return( self );
} // initPixelAttributesWithPListInAppBundle

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Destructor

//---------------------------------------------------------------------------

- (void) dealloc
{
    OpenGLPixelAttributesDelete(mpPixelAttributes);
    
	[super dealloc];
} // dealloc

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Utilities

//---------------------------------------------------------------------------

- (NSInteger) count:(const BOOL)theExpectedPFA
{
	return( OpenGLPixelAttributesGetCount(theExpectedPFA, mpPixelAttributes) );
} // count

//---------------------------------------------------------------------------

- (NSOpenGLPixelFormatAttribute *) attributes:(const BOOL)theExpectedPFA
{
	return( OpenGLPixelAttributesGetFormat(theExpectedPFA, mpPixelAttributes) );
} // attributes

//---------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------


