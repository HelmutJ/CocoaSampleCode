/*
 
 File: FortunesAppDelegate.m
 
 Abstract: Fortunes example application delegate
 
 Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by 
 Apple Inc. ("Apple") in consideration of your agreement to the
 following terms, and your use, installation, modification or
 redistribution of this Apple software constitutes acceptance of these
 terms.  If you do not agree with these terms, please do not use,
 install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Inc. 
 may be used to endorse or promote products derived from the Apple
 Software without specific prior written permission from Apple.  Except
 as expressly stated in this notice, no other rights or licenses, express
 or implied, are granted by Apple herein, including but not limited to
 any patent rights that may be infringed by your derivative works or by
 other works in which the Apple Software may be incorporated.
 
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
 
 Copyright (C) 2008 Apple Inc. All Rights Reserved.
 
 */

#import "FortunesAppDelegate.h"

#import <CommonCrypto/CommonDigest.h>


@interface NSString (MD5)

- (NSString *)MD5String;

@end

@implementation FortunesAppDelegate

/*
 
 Allocate and initialize an NSMetadataQuery, and set its sort descriptors,
 but don't start it executing yet. Let the application finish launching
 before we start Spotlight doing work that will compete for I/O cycles.
 
 */
- (id)init;
{
    if ((self = [super init]) != nil) {
        self.query = [[[NSMetadataQuery alloc] init] autorelease];
        // Prepare the query
        [self.query setSortDescriptors:
         [NSArray arrayWithObjects:
          [[[NSSortDescriptor alloc] initWithKey:(id)kMDItemTimestamp
                                       ascending:NO] autorelease],
          [[[NSSortDescriptor alloc] initWithKey:(id)kMDItemDisplayName
                                       ascending:NO] autorelease],
          [[[NSSortDescriptor alloc] initWithKey:@"com_example_fortuneID"
                                       ascending:NO] autorelease],
          nil]];
    }
    return self;
}

- (void)dealloc;
{
    [query release];
    [searchString release];
    [libraryFolder release];
    [super dealloc];
}

/*
 
 Reset the query predicate and then start query execution. If the user has
 provided a search string, use it to build a compound predicate that will
 perform a word prefix match. (This is a simplified version of what the
 Spotlight menu does.)
 
 */
- (void)resetQueryPredicate;
{
    NSPredicate * predicate = [NSPredicate predicateWithFormat:
                               @"kMDItemContentType == 'com.example.fortune-cookie'"];
    if (self.searchString != nil) {
        NSPredicate * subPredicate = [NSPredicate predicateWithFormat:
                                      @"kMDItemTextContent like[cd] %@", 
                                      [self.searchString stringByAppendingString:@"*"]];
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:
                     [NSArray arrayWithObjects:predicate, subPredicate, nil]];
    }
    [self.query setPredicate:predicate];
    [self.query startQuery];
}

/*
 
 Call -resetQueryPredicate whenever the user provides a new search string.
 
 */
- (void)setSearchString:(NSString *)value;
{
    if (![searchString isEqualToString:value]) {
        [searchString release];
        searchString = [value copy];
        [self resetQueryPredicate];
    }
}

#pragma mark Support code

- (void)addToFortunes:(NSPasteboard *)pasteboard
             userData:(NSString *)userData
                error:(NSString **)error;
{
    NSString * text = [pasteboard stringForType:NSStringPboardType];
    if (text != nil) {
        NSString * fortuneID = [text MD5String];
        NSString * fortuneFile = [fortuneID stringByAppendingPathExtension:@"fortune"];
        NSString * fortunePath = [self.libraryFolder stringByAppendingPathComponent:fortuneFile];
        NSDictionary * plist = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSDate date], @"date",
                                fortuneID, @"fortuneID",
                                text, @"text",
                                nil];
        NSData * data = [NSPropertyListSerialization dataFromPropertyList:plist
                                                                   format:NSPropertyListXMLFormat_v1_0
                                                         errorDescription:NULL];
        NSError * error = nil;
        if (![data writeToFile:fortunePath
                       options:0
                         error:&error]) {
            [NSApp presentError:error];
            return;
        }
        NSLog(@"Added: %@", fortunePath);
    }
}

- (void)insertFortune:(NSPasteboard *)pasteboard
             userData:(NSString *)userData
                error:(NSString **)error;
{
    [pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType]
                       owner:nil];
    [pasteboard setString:@"No matter where you go, there you are..."
                  forType:NSStringPboardType];
}

- (NSDragOperation)tableView:(NSTableView *)view
                validateDrop:(id <NSDraggingInfo>)info
                 proposedRow:(NSInteger)row
       proposedDropOperation:(NSTableViewDropOperation)operation;
{
    [tableView setDropRow:0
            dropOperation:NSTableViewDropAbove];
    return NSDragOperationCopy;
}

- (BOOL)tableView:(NSTableView *)view
       acceptDrop:(id <NSDraggingInfo>)info
              row:(NSInteger)row 
    dropOperation:(NSTableViewDropOperation)operation;
{
    NSPasteboard * pasteboard = [info draggingPasteboard];
    [self addToFortunes:pasteboard
               userData:nil
                  error:NULL];
    return YES;
}

- (NSString *)libraryFolder;
{
    if (libraryFolder == nil) {
        NSFileManager * fileManager = [NSFileManager defaultManager];
        NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                              NSUserDomainMask, YES);
        NSString * basePath = (([paths count] > 0)
                               ? [paths objectAtIndex:0]
                               : NSTemporaryDirectory());
        self.libraryFolder = [basePath stringByAppendingPathComponent:@"Fortunes"];
        if (![fileManager fileExistsAtPath:libraryFolder
                               isDirectory:NULL])
            [fileManager createDirectoryAtPath:libraryFolder
                                    attributes:nil];
    }
    return libraryFolder;
}

- (BOOL)application:(NSApplication *)application
           openFile:(NSString *)fortunePath
{
    NSLog(@"Opened: %@", fortunePath);
    return YES;
}

/*
 
 Start an initial Spotlight query to populate the table view when the
 application is launched. Also register for drag-and-drop and as a Services
 provider at this time.
 
 */
- (void)applicationDidFinishLaunching:(NSNotification *)notification;
{
    [self resetQueryPredicate];
    [self.tableView registerForDraggedTypes:[NSArray arrayWithObject:NSStringPboardType]];
    [NSApp setServicesProvider:self];
    NSUpdateDynamicServices();
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender;
{
    return YES;
}

@synthesize query;
@synthesize tableView;
@synthesize searchString;
@synthesize libraryFolder;

@end

@implementation NSString (MD5)

/*
 
 Return the hexadecimal string representation of the MD5 digest of the target
 NSString. In this example, this is used to generate a statistically unique
 ID for each fortune file.
 
 */
- (NSString *)MD5String;
{
    CC_MD5_CTX digestCtx;
    unsigned char digestBytes[CC_MD5_DIGEST_LENGTH];
    char digestChars[CC_MD5_DIGEST_LENGTH * 2 + 1];
    NSRange stringRange = NSMakeRange(0, [self length]);
    unsigned char buffer[128];
    NSUInteger usedBufferCount;
    CC_MD5_Init(&digestCtx);
    while ([self getBytes:buffer
                maxLength:sizeof(buffer)
               usedLength:&usedBufferCount
                 encoding:NSUnicodeStringEncoding
                  options:NSStringEncodingConversionAllowLossy
                    range:stringRange
           remainingRange:&stringRange])
        CC_MD5_Update(&digestCtx, buffer, usedBufferCount);
    CC_MD5_Final(digestBytes, &digestCtx);
    for (int i = 0;
         i < CC_MD5_DIGEST_LENGTH;
         i++)
        sprintf(&digestChars[2 * i], "%02x", digestBytes[i]);
    return [NSString stringWithUTF8String:digestChars];
}

@end

