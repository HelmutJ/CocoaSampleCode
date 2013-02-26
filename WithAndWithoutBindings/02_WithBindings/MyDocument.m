/*
 
 File: MyDocument.m
 
 Abstract: Document class that manages a collection of Bookmarks.
 
 Version: 2.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by  Apple Inc. ("Apple") in consideration of your agreement to the following terms, and your use, installation, modification or redistribution of this Apple software constitutes acceptance of these terms.  If you do not agree with these terms, please do not use, install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject to these terms, Apple grants you a personal, non-exclusive license, under Apple's copyrights in this original Apple software (the "Apple Software"), to use, reproduce, modify and redistribute the Apple Software, with or without modifications, in source and/or binary forms; provided that if you redistribute the Apple Software in its entirety and without modifications, you must retain this notice and the following text and disclaimers in all such redistributions of the Apple Software.  Neither the name, trademarks, service marks or logos of Apple Inc.  may be used to endorse or promote products derived from the Apple Software without specific prior written permission from Apple.  Except as expressly stated in this notice, no other rights or licenses, express or implied, are granted by Apple herein, including but not limited to any patent rights that may be infringed by your derivative works or by other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2008 Apple Inc. All Rights Reserved.
 
 */


#import "MyDocument.h"
#import "Bookmark.h"

@implementation MyDocument


@synthesize name;
@synthesize collectionDescription;
@synthesize collection;


- (id)init
{
    self = [super init];
    if (self)
	{
		// create the collection array
        collection = [[NSMutableArray alloc] init];
    }
    return self;
}


- (NSString *)windowNibName
{
    return @"MyDocument";
}




#pragma mark ======== load and save data methods =========
/* 
 ** --------------------------------------------------------
 **    Standard NSDocument load and save data methods
 ** --------------------------------------------------------
 
 These methods create an archive of the collection and unarchive an existing archive to reconstitute the collection.
 
 For more details, see:
 - NSDocument Class Reference
 - Document-Based Applications Overview
 */

- (NSData *)dataRepresentationOfType:(NSString *)aType 
{
	// create an archive of the collection and its attributes
    NSKeyedArchiver *archiver;
    NSMutableData *data = [NSMutableData data];
	
    archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
	
    [archiver encodeObject:self.name forKey:@"name"];
    [archiver encodeObject:self.collectionDescription forKey:@"collectionDescription"];
    [archiver encodeObject:self.collection forKey:@"collection"];
	
    [archiver finishEncoding];
	
    return data;
}


- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)aType 
{
    NSKeyedUnarchiver *unarchiver;
	
	// extract an archive of the collection and its attributes
    unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
	
    self.name = [unarchiver decodeObjectForKey:@"name"];
    self.collectionDescription = [unarchiver decodeObjectForKey:@"collectionDescription"];
    self.collection = [unarchiver decodeObjectForKey:@"collection"];
	
    [unarchiver finishDecoding];
	
    return YES;
}



#pragma mark ======== Accessor methods =========
/* 
 ** --------------------------------------------------------
 **  Standard accessor methods
 ** --------------------------------------------------------
 */

- (void)setCollection:(NSArray *)aCollection
{
    if (collection != aCollection)
	{
        [collection release];
        collection = [aCollection mutableCopy];
    }
}

@end


