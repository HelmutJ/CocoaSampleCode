 /*
 
 File: ZipEntry.m
 
 Abstract: ZipEntry is the model class representing a single entry in the zip archive.
 
 Version: 1.1
 
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
 
 Copyright (C) 2008-2009 Apple Inc. All Rights Reserved.
 
 */ 

#import "ZipEntry.h"

@implementation ZipEntry

+ (ZipEntry *)rootEntry {
    return [[self alloc] initWithPath:@"/" headerOffset:0 CRC:0 compressedSize:0 uncompressedSize:0 compressionType:0];
}

- (id)initWithPath:(NSString *)path headerOffset:(uint32_t)headeridx CRC:(uint32_t)crcval compressedSize:(uint32_t)csize uncompressedSize:(uint32_t)usize compressionType:(uint16_t)compression {
    self = [super init];
    if (self) {
        isLeaf = ([path hasSuffix:@"/"] && compressedSize == 0) ? NO : YES;
        path = [@"/" stringByAppendingPathComponent:path];
        name = [[path lastPathComponent] copy];
        leadingPath = [[path stringByDeletingLastPathComponent] copy];
        if (!isLeaf) childEntries = [[NSMutableArray alloc] init];
        headerOffset = headeridx;
        CRC = crcval;
        compressedSize = csize;
        uncompressedSize = usize;
        compressionType = compression;
    }
    return self;
}

- (NSString *)path {
    NSString *path = [leadingPath stringByAppendingPathComponent:name];
    return isLeaf ? path : [path stringByAppendingString:@"/"];
}

- (NSArray *)childEntries {
    return childEntries;
}

@synthesize name;
@synthesize headerOffset;
@synthesize CRC;
@synthesize compressedSize;
@synthesize uncompressedSize;
@synthesize compressionType;
@synthesize isLeaf;

- (NSComparisonResult)compare:(ZipEntry *)other {
    return [[self name] localizedCaseInsensitiveCompare:[other name]];
}

- (BOOL)addChildEntry:(ZipEntry *)entry {
    if (!childEntries) return NO;
    [childEntries addObject:entry];
    [childEntries sortUsingSelector:@selector(compare:)];
    return YES;
}

- (ZipEntry *)childDirectoryEntryWithName:(NSString *)str createIfNotPresent:(BOOL)flag {
    ZipEntry *childEntry = nil;
    for (ZipEntry *entry in childEntries) {
        if ([[entry name] isEqualToString:str] && ![entry isLeaf]) {
            childEntry = (ZipEntry *)entry;
            break;
        }
    }
    if (!childEntry && flag && !isLeaf) {
        childEntry = [[ZipEntry alloc] initWithPath:[[[self path] stringByAppendingPathComponent:str] stringByAppendingString:@"/"] headerOffset:0 CRC:0 compressedSize:0 uncompressedSize:0 compressionType:0];
        [self addChildEntry:childEntry];
    }
    return childEntry;
}

- (BOOL)addToRootEntry:(ZipEntry *)rootEntry {
    ZipEntry *directoryEntry = rootEntry;
    NSArray *components = [leadingPath pathComponents];
    for (NSString *component in components) {
        if (![@"/" isEqualToString:component]) directoryEntry = [directoryEntry childDirectoryEntryWithName:component createIfNotPresent:YES];
    }
    return directoryEntry ? [directoryEntry addChildEntry:self] : NO;
}

@end
