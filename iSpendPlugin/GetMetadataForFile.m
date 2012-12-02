/*
     File: GetMetadataForFile.m
 Abstract: This files contains an implementation of GetMetadataForFile, which reads metadata from our custom file format and returns it in a dictionary, suitable for use by Spotlight.
  Version: 1.1
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2012 Apple Inc. All Rights Reserved.
 
 */


#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h> 
#include <Foundation/Foundation.h>
#include "Transaction.h"

/* -----------------------------------------------------------------------------
Step 1
Set the UTI types the importer supports

Modify the CFBundleDocumentTypes entry in Info.plist to contain
an array of Uniform Type Identifiers (UTI) for the LSItemContentTypes 
that your importer can handle

----------------------------------------------------------------------------- */

/* -----------------------------------------------------------------------------
Step 2 
Implement the GetMetadataForFile function

Implement the GetMetadataForFile function below to scrape the relevant
metadata from your document and return it as a CFDictionary using standard keys
(defined in MDItem.h) whenever possible.
----------------------------------------------------------------------------- */

/* -----------------------------------------------------------------------------
Step 3 (optional) 
If you have defined new attributes, update the schema.xml file

Edit the schema.xml file to include the metadata keys that your importer returns.
Add them to the <allattrs> and <displayattrs> elements.

Add any custom types that your importer requires to the <attributes> element

<attribute name="com_mycompany_metadatakey" type="CFString" multivalued="true"/>

----------------------------------------------------------------------------- */



/* -----------------------------------------------------------------------------
Get metadata attributes from file

This function's job is to extract useful information your file format supports
and return it as a dictionary
----------------------------------------------------------------------------- */

Boolean GetMetadataForFile(void *thisInterface, 
			   CFMutableDictionaryRef cfAttributes, 
			   CFStringRef contentTypeUTI,
			   CFStringRef pathToFile)
{
    // saving and opening documents
#define kSpendDocumentType @"iSpend Data Format"
#define kOpeningBalance @"Opening Balance"
#define kTransactions @"Transactions"
    
    Boolean result = NO;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSData *data = [NSData dataWithContentsOfFile:(NSString *)pathToFile];
    if (data != nil) {
        NSString *errorString;
        NSDictionary *documentDictionary = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:&errorString];
        
        if (documentDictionary != nil) {
            // We are going to figure out the metadata information that users can search on
            NSMutableString *allDescriptions = [NSMutableString string];
            NSMutableArray *categories = [NSMutableArray array];
            NSMutableArray *dates = [NSMutableArray array];
            NSArray *transactions = [NSKeyedUnarchiver unarchiveObjectWithData:[documentDictionary objectForKey:kTransactions]];
            if (transactions != nil) {
                int i;
                double openingBalance = [[documentDictionary objectForKey:kOpeningBalance] doubleValue];
                double endingBalance = openingBalance;
                for (i = 0; i < [transactions count]; i++) {
                    Transaction *trans = [transactions objectAtIndex:i];
                    // Keep track of the ending balance
                    endingBalance += [trans amount];
                    // Keep track of all the descriptions combined together for this document
                    NSString *desc = [trans descriptionString];
                    if (desc != nil) {
                        [allDescriptions appendString:desc];
                        [allDescriptions appendString:@"\n"];
                    }
                    // Keep track of each category
                    NSString *category = [trans type];
                    if ((category != nil) && ![categories containsObject:category]) {
                        [categories addObject:category];                        
                    }
                    // And the dates for each item
                    [dates addObject:[trans date]];                    
                }                
                // Toll-free bridging allows us to access the the CFMutableDictionaryRef as an NSMutableDictionary:
                NSMutableDictionary *attributes = (NSMutableDictionary *)cfAttributes;
                // Fill in the values for the keys.
                [attributes setObject:[NSNumber numberWithDouble:endingBalance] forKey:@"com_apple_ispendBalance"];
                [attributes setObject:categories forKey:@"com_apple_ispendCategories"];
                [attributes setObject:dates forKey:@"com_apple_ispendDates"];
                [attributes setObject:allDescriptions forKey:(id)kMDItemTextContent];
            }
            
            result = YES;
        } else {
            NSLog(@"Failed to import %@ because %@", pathToFile, errorString);
        }
    } else {
        NSLog(@"Failed to import %@", pathToFile);
    }    
    
    [pool release];
    
    return result;
    
}
