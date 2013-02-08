/*
     File: FileSystemNode.m
 Abstract: An abstract wrapper node around the file system.
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
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
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
    NSError *error = nil;
    BOOL success = NO;
    
    success = [_url getResourceValue:&value forKey:NSURLLocalizedNameKey error:&error];
    if (success && !value) { //If we got a nil value for the localized name, we will try the non-localized name
	success = [_url getResourceValue:&value forKey:NSURLNameKey error:&error];
    }
    
    if (success) {
	if (value) {
	    return value;
	} else {
	    return @""; //An empty string is more appropriate than nil
	}
	
    } else {
	return [error localizedDescription];
    }
}

- (NSImage *)icon {
    return [[NSWorkspace sharedWorkspace] iconForFile:[_url path]];
}

- (BOOL)isDirectory {
    id value = nil;
    [_url getResourceValue:&value forKey:NSURLIsDirectoryKey error:NULL];
    return [value boolValue];
}

- (NSColor *)labelColor {
    id value = nil;
    [_url getResourceValue:&value forKey:NSURLLabelColorKey error:NULL];
    return value;
}

- (NSArray *)children {
    if (_children == nil || _childrenDirty) {
        // This logic keeps the same pointers around, if possible.
        NSMutableDictionary *newChildren = [NSMutableDictionary new];
        
        NSString *parentPath = [_url path];
        NSArray *contentsAtPath = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:parentPath error:NULL];
	
	if (contentsAtPath) {	// We don't deal with the error
	    for (NSString *filename in contentsAtPath) {
		// Use the filename as a key and see if it was around and reuse it, if possible
		if (_children != nil) {
		    FileSystemNode *oldChild = [_children objectForKey:filename];
		    if (oldChild != nil) {
			[newChildren setObject:oldChild forKey:filename];
			continue;
		    }
		}
		// We didn't find it, add a new one
		NSString *fullPath = [parentPath stringByAppendingFormat:@"/%@", filename];
		NSURL *childURL = [NSURL fileURLWithPath:fullPath];
		if (childURL != nil) {
		    // Wrap the child url with our node
		    FileSystemNode *node = [[FileSystemNode alloc] initWithURL:childURL];
		    [newChildren setObject:node forKey:filename];
		    [node release];
		}
	    }
	}
        
        [_children release];
        _children = newChildren;
        _childrenDirty = NO;
    }
    
    NSArray *result = [_children allValues];
    // Sort the children by the display name and return it
    result = [result sortedArrayUsingComparator:^(id obj1, id obj2) {
        NSString *objName = [obj1 displayName];
        NSString *obj2Name = [obj2 displayName];
        NSComparisonResult result = [objName compare:obj2Name options:NSNumericSearch | NSCaseInsensitiveSearch | NSWidthInsensitiveSearch | NSForcedOrderingSearch range:NSMakeRange(0, [objName length]) locale:[NSLocale currentLocale]];
        return result;
    }];
    return result;
}

- (void)invalidateChildren {
    _childrenDirty = YES;
    for (FileSystemNode *child in [_children allValues]) {
        [child invalidateChildren];
    }
}

@end
