/*
     File: FileSystemNode.m
 Abstract: An abstract wrapper node around the file system.
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

#import "FileSystemNode.h"

@implementation FileSystemNode

- (id)initWithURL:(NSURL *)url {
    if (self = [super init]) {
        _url = [url retain];
    }
    return self;
}

- (void)dealloc {
    // We have to release the underlying ivars associated with our properties
    [_url release];
    [_children release];
    [super dealloc];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ - %@", super.description, _url];
}

@synthesize URL = _url;
@dynamic displayName, children, isDirectory, icon, labelColor;

- (NSString *)displayName {
    id value = nil;
    NSError *error;
    if ([_url getResourceValue:&value forKey:NSURLLocalizedNameKey error:&error]) {
        return [value retain]; // hack work around the crash
    } else {
        return [error localizedDescription];
    }
}

- (NSImage *)icon {
    return [[NSWorkspace sharedWorkspace] iconForFile:[_url path]];
}

- (BOOL)isDirectory {
    id value = nil;
    [_url getResourceValue:&value forKey:NSURLIsDirectoryKey error:nil];
    return [value boolValue];
}

- (NSColor *)labelColor {
    id value = nil;
    [_url getResourceValue:&value forKey:NSURLLabelColorKey error:nil];
    return value;
}

// We are equal if we represent the same URL. This allows children to reuse the same instances.

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[FileSystemNode class]]) {
        FileSystemNode *other = (FileSystemNode *)object;
        return [other.URL isEqual:self.URL];
    } else {
        return NO;
    }
}

- (NSUInteger)hash {
    return self.URL.hash;
}

- (NSArray *)children {
    if (_children == nil || _childrenDirty) {
        // This logic keeps the same pointers around, if possible.
        NSMutableArray *newChildren = [NSMutableArray array];
        
        CFURLEnumeratorRef enumerator = CFURLEnumeratorCreateForDirectoryURL(NULL, (CFURLRef)_url, kCFURLEnumeratorSkipInvisibles, (CFArrayRef)[NSArray array]);
        NSURL *childURL = nil;
	CFURLEnumeratorResult enumeratorResult;
	do {
            enumeratorResult = CFURLEnumeratorGetNextURL(enumerator, (CFURLRef *)&childURL, NULL);
            if (enumeratorResult == kCFURLEnumeratorSuccess) {
                FileSystemNode *node = [[[FileSystemNode alloc] initWithURL:childURL] autorelease];
                if (_children != nil) {
                    NSInteger oldIndex = [_children indexOfObject:childURL];
                    if (oldIndex != NSNotFound) {
                        // Use the same pointer value, if possible
                        node = [_children objectAtIndex:oldIndex];
                    }
                }
                [newChildren addObject:node];
            } else if (enumeratorResult == kCFURLEnumeratorError) {
                // A possible enhancement would be to present error-based items to the user.
            }
	} while (enumeratorResult != kCFURLEnumeratorEnd);
        
        CFRelease(enumerator);
        [_children release];
        _childrenDirty = NO;
        // Now sort them
        _children = [[newChildren sortedArrayUsingComparator:^(id obj1, id obj2) {
            NSString *objName = [obj1 displayName];
            NSString *obj2Name = [obj2 displayName];
            NSComparisonResult result = [objName compare:obj2Name options:NSNumericSearch | NSCaseInsensitiveSearch | NSWidthInsensitiveSearch | NSForcedOrderingSearch range:NSMakeRange(0, [objName length]) locale:[NSLocale currentLocale]];
            return result;
        }] retain];
    }
    
    return _children;
}

- (void)invalidateChildren {
    _childrenDirty = YES;
    for (FileSystemNode *child in _children) {
        [child invalidateChildren];
    }
}

@end
