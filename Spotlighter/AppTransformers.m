/*
     File: AppTransformers.m
 Abstract: Some simple transformers for the UI to use.
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


#import "AppTransformers.h"

@implementation IsRunningTransformer

+ (Class)transformedValueClass {
    return [NSString class];
}

- (id)transformedValue:(id)value {
    if (value == nil) {
        return nil;
    }
    if (![value respondsToSelector:@selector(integerValue)]) {
        [NSException raise:NSInternalInconsistencyException format:@"Value %@ does not respond to integerValue", [value class]];
    }
    NSInteger val = [value integerValue];
    if (val) {
        return NSLocalizedString(@"Query is alive...", @"String to be shown when the query is alive and maintaining results");
    } else {
        return NSLocalizedString(@"Query is dead...", @"String to be shown when the query is not alive and not maintaining results");
    }    
}
    
@end

@implementation MBTransformer

+ (Class)transformedValueClass {
    return [NSString class];
}

- (id)transformedValue:(id)value {
    if (value == nil) {
        return NSLocalizedString(@"0 Bytes", @"File size shown for 0 byte files");
    }
    if (![value respondsToSelector:@selector(integerValue)]) {
        [NSException raise:NSInternalInconsistencyException format:@"Value %@ does not respond to integerValue", [value class]];
    }
    NSInteger fsSize = [value integerValue];
    // special case for small files
    if (fsSize == 0) {
        return NSLocalizedString(@"0 Bytes", @"File size shown for 0 byte files");
    }
    
    const NSInteger cutOff = 900;
    
    if (fsSize < cutOff) {
        return [NSString stringWithFormat:NSLocalizedString(@"%ld Bytes", @"File size shown formatted as bytes"), (long)fsSize];
    }
    
    double numK = (double)fsSize / 1024;
    if (numK < cutOff) {
        return [NSString stringWithFormat:NSLocalizedString(@"%.2f KB", @"File size shown formatted as kilobytes"), numK];
    }
    
    double numMB = numK / 1024;
    if (numMB < cutOff) {
        return [NSString stringWithFormat:NSLocalizedString(@"%.2f MB", @"File size shown formatted as megabytes"), numMB];
    }
    
    double numGB = numMB / 1024;
    return [NSString stringWithFormat:NSLocalizedString(@"%.2f GB", @"File size shown formatted as gigabytes"), numGB];
}

@end

@implementation MetadataItemIconTransformer

+ (Class)transformedValueClass {
    return [NSImage class];
}

- (id)transformedValue:(id)value {
    if (value == nil) {
        return nil;
    }
    if ([value isMemberOfClass:[NSMetadataItem class]]) {
        NSMetadataItem *item = value;
        NSString *filename = [item valueForAttribute:(id)kMDItemPath];
        return [[NSWorkspace sharedWorkspace] iconForFile:filename];
    } else {
        [NSException raise:NSInvalidArgumentException format:@"Expecting only an NSMetadataitem"];
        return nil;
    }
}

@end

