/*
     File: DownloadItem.m
 Abstract: DownloadItem stores information of a downloaded item used by MyDocument.
  Version: 1.0
 
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
 
 Copyright (C) 2009 Apple Inc. All Rights Reserved.
 
 */

#import "DownloadItem.h"

#include <QuickLook/QuickLook.h>

static NSString* originalURLKey = @"downloadURL";
static NSString* bookmarkKey = @"bookmark";
static NSOperationQueue* downloadIconQueue = nil;
static NSDictionary* quickLookOptions = nil;

#define ICON_SIZE 48.0

@implementation DownloadItem

- (id)initWithOriginalURL:(NSURL *)downloadURL fileURL:(NSURL *)onDiskURL
{
    self = [super init];
    if (self) {
        originalURL = [downloadURL copy];
        resolvedFileURL = [onDiskURL copy];
    }
    return self;
}

- (id)initWithSavedPropertyList:(id)propertyList
{
    self = [super init];
    if (self) {
        if (![propertyList isKindOfClass:[NSDictionary class]]) {
            [self release];
            return nil;
        }
        
        NSString* originalURLString = [propertyList objectForKey:originalURLKey];
        if (!originalURLString || ![originalURLString isKindOfClass:[NSString class]]) {
            [self release];
            return nil;
        }
        
        originalURL = [[NSURL alloc] initWithString:originalURLString];
        if (!originalURL) {
            [self release];
            return nil;
        }
        
        NSData* bookmarkData = [propertyList objectForKey:bookmarkKey];
        if (!bookmarkData || ![bookmarkData isKindOfClass:[NSData class]]) {
            [self release];
            return nil;
        }
        
        // test if the file still exists
        resolvedFileURL = [[NSURL URLByResolvingBookmarkData:bookmarkData
                                                     options:(NSURLBookmarkResolutionWithoutUI | NSURLBookmarkResolutionWithoutMounting)
                                               relativeToURL:nil bookmarkDataIsStale:NULL error:NULL] retain];
        if (!resolvedFileURL) {
            [self release];
            return nil;
        }
    }
    
    return self;
}

- (void)dealloc
{
    [originalURL release];
    [resolvedFileURL release];
    [iconImage release];
    [super dealloc];
}

@synthesize originalURL, resolvedFileURL, iconImage;

- (NSImage *)iconImage
{
    if (iconImage == nil) {
        iconImage = [[[NSWorkspace sharedWorkspace] iconForFile:[resolvedFileURL path]] retain];
        [iconImage setSize:NSMakeSize(ICON_SIZE, ICON_SIZE)];
        if (!downloadIconQueue) {
            downloadIconQueue = [[NSOperationQueue alloc] init];
            [downloadIconQueue setMaxConcurrentOperationCount:2];
            quickLookOptions = [[NSDictionary alloc] initWithObjectsAndKeys:
                                (id)kCFBooleanTrue, (id)kQLThumbnailOptionIconModeKey,
                                nil];
        }
        [downloadIconQueue addOperationWithBlock:^{
            CGImageRef quickLookIcon = QLThumbnailImageCreate(NULL, (CFURLRef)resolvedFileURL, CGSizeMake(ICON_SIZE, ICON_SIZE), (CFDictionaryRef)quickLookOptions);
            if (quickLookIcon != NULL) {
                NSImage* betterIcon = [[NSImage alloc] initWithCGImage:quickLookIcon size:NSMakeSize(ICON_SIZE, ICON_SIZE)];
                [self performSelectorOnMainThread:@selector(setIconImage:) withObject:betterIcon waitUntilDone:NO];
                [betterIcon release];
                CFRelease(quickLookIcon);
            }
        }];
    }
    return iconImage;
}

- (NSString *)displayName
{
    return [[resolvedFileURL path] lastPathComponent];
}

- (id)propertyListForSaving
{
    NSData* bookmarkData = [resolvedFileURL bookmarkDataWithOptions:NSURLBookmarkCreationMinimalBookmark includingResourceValuesForKeys:nil relativeToURL:nil error:NULL];
    if (!bookmarkData) {
        return nil;
    }
    return [NSDictionary dictionaryWithObjectsAndKeys:
            [originalURL absoluteString], originalURLKey,
            bookmarkData, bookmarkKey,
            nil];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ %@ (from %@)>", [self class], resolvedFileURL, originalURL];
}

@end
