//---------------------------------------------------------------------------
//
//	File: NSPropertyList.m
//
//  Abstract: Utility class to desearlize a property list file
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

#import "NSPropertyList.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Data Structures

//---------------------------------------------------------------------------

struct NSPropertyListData
{
    BOOL                   isValid;
    NSString              *error;
    NSDictionary          *dictionary;
    NSPropertyListFormat   format;
};

typedef struct NSPropertyListData  NSPropertyListData;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Utilities

//---------------------------------------------------------------------------

static void NSPropertyListInitParams(NSPropertyListDataRef pPList)
{
    pPList->isValid    = NO;
    pPList->error      = nil;
    pPList->dictionary = nil;
} // NSPropertyListInitParams

//---------------------------------------------------------------------------

static NSPropertyListDataRef NSPropertyListCreateWithFileAtPath(NSString *pPListPath)
{
    NSPropertyListDataRef pPList = NULL;
    
	if( pPListPath )
	{
        pPList = (NSPropertyListDataRef)calloc(1, sizeof(NSPropertyListData));
        
        if( pPList != NULL )
        {
            BOOL isAtPath   = [[NSFileManager defaultManager] fileExistsAtPath:pPListPath];
            BOOL isRedeable = [[NSFileManager defaultManager] isReadableFileAtPath:pPListPath];
            BOOL isValid    = isAtPath && isRedeable;
            
            if( isValid )
            {
                NSData *fileData = [NSData dataWithContentsOfFile:pPListPath];
                
                if( fileData )
                {
                    NSPropertyListInitParams(pPList);
                    
                    pPList->dictionary = [NSPropertyListSerialization propertyListFromData:fileData
                                                                          mutabilityOption:NSPropertyListImmutable
                                                                                    format:&pPList->format
                                                                          errorDescription:&pPList->error];
                    
                    BOOL isSerialized = pPList->error == nil;
                    
                    if( !isSerialized )
                    {
                        NSLog(@">> ERROR: NS Property List - Property List Serialization Failed: \n\t%@\n", 
                              pPList->error);
                    } // if
                    
                    if( pPList->dictionary )
                    {
                        [pPList->dictionary retain];
                    } // if
                    
                    pPList->isValid = isSerialized && isValid;
                } // if
            } // if
            else
            {
                NSLog(@">> ERROR: NS Property List - Failed opening the property list file \"%@\"!", 
                      pPListPath);
            } // else
        } // if
	} // if
    
    return( pPList );
} // NSPropertyListCreateWithFileAtPath

//---------------------------------------------------------------------------

static NSPropertyListDataRef NSPropertyListCreateWithFileInAppBundle(NSString *pPListName)
{
    NSPropertyListDataRef pPList = NULL;
    
    if( pPListName )
    {
        NSBundle  *appBundle = [NSBundle mainBundle];
        
        if( appBundle )
        {
            NSString  *plistPath = [appBundle pathForResource:pPListName
                                                       ofType:@"plist"];
            
            if( plistPath )
            {
                pPList = NSPropertyListCreateWithFileAtPath(plistPath);
            } // if
        } // if
    } // if
    
    return( pPList );
} // NSPropertyListCreateWithFileInAppBundle

//---------------------------------------------------------------------------

static void NSPropertyListDelete(NSPropertyListDataRef pPList)
{
    if( pPList != NULL )
    {
        if( pPList->dictionary )
        {
            [pPList->dictionary release];
            
            pPList->dictionary = nil;
        } // if
        
    	if( pPList->error )
        {
            [pPList->error release];
            
            pPList->error = nil;
        } // if
        
        free( pPList );
        
        pPList = NULL;
    } // if
} // NSPropertyListDelete

//---------------------------------------------------------------------------

static NSDictionary *NSPropertyListGetDictionaryForKey(NSString *pKey,
                                                       NSPropertyListDataRef pPList)
{
	NSDictionary *dictionary = nil;
	
	if( pKey )
	{
		dictionary = [pPList->dictionary objectForKey:pKey];
	} // if
	
	return( dictionary );
} // NSPropertyListGetDictionaryForKey

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

@implementation NSPropertyList

//---------------------------------------------------------------------------

- (id) initPListWithFileAtPath:(NSString *)thePListPath
{
	self = [super init];
    
	if( self )
	{
        mpPList = NSPropertyListCreateWithFileAtPath(thePListPath);
	} // if
	
	return( self );
} // initPListWithFileAtPath

//---------------------------------------------------------------------------

- (id) initPListWithFileInAppBundle:(NSString *)thePListName
{
	self = [super init];
	
	if( self )
	{
        mpPList = NSPropertyListCreateWithFileInAppBundle(thePListName);
	} // if
	
	return( self );
} // initPListWithFileInAppBundle

//---------------------------------------------------------------------------

- (void) dealloc
{
    NSPropertyListDelete(mpPList);
	
	[super dealloc];
} // dealloc

//---------------------------------------------------------------------------

- (NSDictionary *) dictionaryForKey:(NSString *)theKey
{
	return( NSPropertyListGetDictionaryForKey(theKey, mpPList) );
} // dictionaryForKey

//---------------------------------------------------------------------------

- (BOOL) isValid
{
	return( mpPList->isValid );
} // isValid

//---------------------------------------------------------------------------

- (NSString *) error
{
	return( mpPList->error );
} // error

//---------------------------------------------------------------------------

- (NSDictionary *) dictionary
{
	return( mpPList->dictionary );
} // dictionary

//---------------------------------------------------------------------------

- (NSPropertyListFormat) format
{
	return( mpPList->format );
} // format

//---------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

