/*
    File:       ImageDownloadOperation.m

    Contains:   Downloads an image to a directory.

    Written by: DTS

    Copyright:  Copyright (c) 2011 Apple Inc. All Rights Reserved.

    Disclaimer: IMPORTANT: This Apple software is supplied to you by Apple Inc.
                ("Apple") in consideration of your agreement to the following
                terms, and your use, installation, modification or
                redistribution of this Apple software constitutes acceptance of
                these terms.  If you do not agree with these terms, please do
                not use, install, modify or redistribute this Apple software.

                In consideration of your agreement to abide by the following
                terms, and subject to these terms, Apple grants you a personal,
                non-exclusive license, under Apple's copyrights in this
                original Apple software (the "Apple Software"), to use,
                reproduce, modify and redistribute the Apple Software, with or
                without modifications, in source and/or binary forms; provided
                that if you redistribute the Apple Software in its entirety and
                without modifications, you must retain this notice and the
                following text and disclaimers in all such redistributions of
                the Apple Software. Neither the name, trademarks, service marks
                or logos of Apple Inc. may be used to endorse or promote
                products derived from the Apple Software without specific prior
                written permission from Apple.  Except as expressly stated in
                this notice, no other rights or licenses, express or implied,
                are granted by Apple herein, including but not limited to any
                patent rights that may be infringed by your derivative works or
                by other works in which the Apple Software may be incorporated.

                The Apple Software is provided by Apple on an "AS IS" basis. 
                APPLE MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING
                WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT,
                MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING
                THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
                COMBINATION WITH YOUR PRODUCTS.

                IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT,
                INCIDENTAL OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
                TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
                DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY
                OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION
                OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY
                OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR
                OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF
                SUCH DAMAGE.

*/

#import "ImageDownloadOperation.h"

#include <fcntl.h>
#include <unistd.h>

@interface ImageDownloadOperation ()

// Read/write versions of public properties

@property (copy,   readwrite) NSString *    imageFilePath;

@end

@implementation ImageDownloadOperation

@synthesize imagesDirPath = imagesDirPath_;
@synthesize depth         = depth_;

@synthesize imageFilePath = imageFilePath_;

- (id)initWithURL:(NSURL *)url imagesDirPath:(NSString *)imagesDirPath depth:(NSUInteger)depth
    // See comment in header.
{
    assert(imagesDirPath != nil);
    self = [super initWithURL:url];
    if (self != nil) {
        self->imagesDirPath_ = [imagesDirPath copy];
        self->depth_ = depth;
    }
    return self;
}

- (void)dealloc
{
    [self->imageFilePath_ release];
    [self->imagesDirPath_ release];
    [super dealloc];
}

+ (NSString *)defaultExtensionToMIMEType:(NSString *)type
    // See comment in header.
{
    static NSDictionary *   sTypeToExtensionMap;
    
    // This needs to be thread safe because the client could start multiple 
    // download operations with different run loop threads and, if so, 
    // +defaultExtensionToMIMEType: can get call by multiple threads simultaneously.
    
    @synchronized (self) {
        if (sTypeToExtensionMap == nil) {
            sTypeToExtensionMap = [[NSDictionary alloc] initWithObjectsAndKeys:
                @"gif", @"image/gif", 
                @"png", @"image/png", 
                @"jpg", @"image/jpeg", 
                nil
            ];
            assert(sTypeToExtensionMap != nil);
        }
    }
    return (type == nil) ? nil : [sTypeToExtensionMap objectForKey:type];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
    // An NSURLConnect delegate method.  We override this to set up a 
    // destination output stream for the incoming image data.
{
    [super connection:connection didReceiveResponse:response];
    
    // If the response is an error, no need to do anything special here. 
    // We only need to set up an output stream if we're successfully 
    // getting the image.
    
    if (self.isStatusCodeAcceptable) {
        NSString *  extension;
        NSString *  prefix;
        
        assert(self.responseOutputStream == nil);
        
        // Create a unique file for the downloaded image.  Start by getting an appropriate 
        // extension.  If we don't have one, that's bad.
        
        extension = [[self class] defaultExtensionToMIMEType:[self.lastResponse MIMEType]];
        if (extension != nil) {
            NSString *  fileName;
            NSString *  filePath;
            int         counter;
            int         fd;
            
            // Next calculate the file name prefix and extension.
            
            fileName = [self.lastResponse suggestedFilename];
            if (fileName == nil) {
                prefix = @"image";
                assert(extension != nil);       // that is, the default
            } else {
                if ([[fileName pathExtension] length] == 0) {
                    prefix = fileName;
                    assert(extension != nil);   // that is, the default
                } else {
                    prefix    = [fileName stringByDeletingPathExtension];
                    extension = [fileName pathExtension];
                }
            }
            assert(prefix != nil);
            assert(extension != nil);
            
            // Repeatedly try to create a new file with that info, adding a 
            // unique number if we get a conflict.
            
            counter = 0;
            filePath = [self.imagesDirPath stringByAppendingPathComponent:[prefix stringByAppendingPathExtension:extension]];
            do {
                int     err;
                int     junk;
                
                err = 0;
                fd = open([filePath UTF8String], O_CREAT | O_EXCL | O_RDWR, 0666);
                if (fd < 0) {
                    err = errno;
                } else {
                    junk = close(fd);
                    assert(junk == 0);
                }
                
                if (err == 0) {
                    self.imageFilePath = filePath;
                    self.responseOutputStream = [NSOutputStream outputStreamToFileAtPath:filePath append:NO];
                    break;
                } else if (err == EEXIST) {
                    counter += 1;
                    if (counter > 500) {
                        break;
                    }
                    filePath = [self.imagesDirPath stringByAppendingPathComponent:[[NSString stringWithFormat:@"%@-%d", prefix, counter] stringByAppendingPathExtension:extension]];
                } else if (err == EINTR) {
                    // do nothing
                } else {
                    break;
                }
            } while (YES);
        }
        
        // If we've failed to create a valid file, redirect the output to the bit bucket.
        
        if (self.responseOutputStream == nil) {
            self.responseOutputStream = [NSOutputStream outputStreamToFileAtPath:@"/dev/null" append:NO];
        }
    }
}

@end
