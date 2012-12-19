/*
     File: SimpleNodeData.m
 Abstract: Simple object model implementation.
  Version: 1.2
 
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

#import "SimpleNodeData.h"

@implementation SimpleNodeData

#pragma mark -

- (id)init {
    self = [super init];
    self.name = @"Untitled";
    self.expandable = YES;
    self.selectable = YES;
    self.container = YES;
    return self;
}

- (id)initWithName:(NSString *)aName {
    self = [self init];
    self.name = aName;
    return self;
}

- (void)dealloc {
    [name release];
    [image release];
    [super dealloc];
}

+ (SimpleNodeData *)nodeDataWithName:(NSString *)name {
    return [[[SimpleNodeData alloc] initWithName:name] autorelease];
}

@synthesize name, image, expandable, selectable, container;

- (NSComparisonResult)compare:(id)anOther {
    // We want the data to be sorted by name, so we compare [self name] to [other name]
    if ([anOther isKindOfClass:[SimpleNodeData class]]) {
        SimpleNodeData *other = (SimpleNodeData *)anOther;
        return [name compare:[other name]];
    } else {
        return NSOrderedAscending;
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ - '%@' expandable: %d, selectable: %d, container: %d", [super description], self.name, self.expandable, self.selectable, self.container];
}

#pragma mark -
#pragma mark NSPasteboardWriting support

- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pasteboard {
    // These are the types we can write.
    NSArray *ourTypes = [NSArray arrayWithObjects:NSPasteboardTypeString, nil];
    // Also include the images on the pasteboard too!
    NSArray *imageTypes = [self.image writableTypesForPasteboard:pasteboard];
    if (imageTypes) {
        ourTypes = [ourTypes arrayByAddingObjectsFromArray:imageTypes];
    }
    return ourTypes;
}

- (NSPasteboardWritingOptions)writingOptionsForType:(NSString *)type pasteboard:(NSPasteboard *)pasteboard {
    if ([type isEqualToString:NSPasteboardTypeString]) {
        return 0;
    }
    // Everything else is delegated to the image
    if ([self.image respondsToSelector:@selector(writingOptionsForType:pasteboard:)]) {            
        return [self.image writingOptionsForType:type pasteboard:pasteboard];
    }
    
    return 0;
}

- (id)pasteboardPropertyListForType:(NSString *)type {
    if ([type isEqualToString:NSPasteboardTypeString]) {
        return self.name;
    } else {
        return [self.image pasteboardPropertyListForType:type];
    }
}

#pragma mark -
#pragma mark  NSPasteboardReading support

+ (NSArray *)readableTypesForPasteboard:(NSPasteboard *)pasteboard {
    // We allow creation from URLs so Finder items can be dragged to us
    return [NSArray arrayWithObjects:(id)kUTTypeURL, NSPasteboardTypeString, nil];
}

+ (NSPasteboardReadingOptions)readingOptionsForType:(NSString *)type pasteboard:(NSPasteboard *)pasteboard {
    if ([type isEqualToString:NSPasteboardTypeString] || UTTypeConformsTo((CFStringRef)type, kUTTypeURL)) {
	return NSPasteboardReadingAsString;
    } else {
	return NSPasteboardReadingAsData; 
    }
}

- (id)initWithPasteboardPropertyList:(id)propertyList ofType:(NSString *)type {
    // See if an NSURL can be created from this type
    if (UTTypeConformsTo((CFStringRef)type, kUTTypeURL)) {
        // It does, so create a URL and use that to initialize our properties
        NSURL *url = [[[NSURL alloc] initWithPasteboardPropertyList:propertyList ofType:type] autorelease];
        self = [super init];
        self.name = [url lastPathComponent];
        // Make sure we have a name
        if (self.name == nil) {
            self.name = [url path];
            if (self.name == nil) {
                self.name = @"Untitled";
            }
        }
        self.selectable = YES;
        
        // See if the URL was a container; if so, make us marked as a container too
        NSNumber *value;
        if ([url getResourceValue:&value forKey:NSURLIsDirectoryKey error:NULL] && [value boolValue]) {
            self.container = YES;
            self.expandable = YES;
        } else {
            self.container = NO; 
            self.expandable = NO;
        }

        NSImage *localImage;
        if ([url getResourceValue:&localImage forKey:NSURLEffectiveIconKey error:NULL] && localImage) {
            self.image = localImage;
        }
        
    } else if ([type isEqualToString:NSPasteboardTypeString]) {
        self = [super init];
        self.name = propertyList;
        self.selectable = YES;
    } else {
        NSAssert(NO, @"internal error: type not supported");
    }        
    return self;
}



@end

