/*
    File:       LinkedImageFetcher.m

    Contains:   Downloads an HTML page and then downloads all of the referenced images.

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

#import "LinkedImageFetcher.h"

#import "ImageDownloadOperation.h"
#import "PageGetOperation.h"
#import "LinkFinder.h"

@interface LinkedImageFetcher ()

// Read/write versions of public properties

@property (nonatomic, copy,   readwrite) NSError *                  error;

// Internal properties

@property (nonatomic, retain, readonly ) QWatchedOperationQueue *   queue;
@property (nonatomic, retain, readonly ) NSMutableSet *             foundPageURLs;
@property (nonatomic, retain, readonly ) NSMutableDictionary *      foundImageURLToPathMap;
@property (nonatomic, assign, readwrite) NSUInteger                 runningOperationCount;

// Forward declarations

- (void)startPageGet:(NSURL *)pageURL depth:(NSUInteger)depth;

@end

@implementation LinkedImageFetcher

@synthesize URL = URL_;

@synthesize maximumDepth = maximumDepth_;
@synthesize imagesDirPath = imagesDirPath_;
@synthesize delegate = delegate_;

@synthesize done = done_;
@synthesize error = error_;

@synthesize foundPageURLs = foundPageURLs_;
@synthesize foundImageURLToPathMap = foundImageURLToPathMap_;
@synthesize runningOperationCount = runningOperationCount_;

+ (BOOL)isSupportedURL:(NSURL *)url
{
    NSString *  scheme;
    
    assert(url != nil);
    scheme = [[url scheme] lowercaseString];
    return [scheme isEqual:@"http"] || [scheme isEqual:@"https"];
}

- (id)initWithURL:(NSURL *)url
    // See comment in header.
{
    assert(url != nil);
    assert([[self class] isSupportedURL:url]);
    self = [super init];
    if (self != nil) {
        self->URL_ = [url copy];
        self->imagesDirPath_ = [[NSTemporaryDirectory() stringByAppendingPathComponent:@"images"] copy];
        assert(self->imagesDirPath_ != nil);
        self->foundPageURLs_ = [[NSMutableSet alloc] init];
        assert(self->foundPageURLs_ != nil);
        self->foundImageURLToPathMap_ = [[NSMutableDictionary alloc] init];
        assert(self->foundImageURLToPathMap_ != nil);
    }
    return self;
}

- (void)dealloc
{
    [self->foundPageURLs_ release];
    [self->foundImageURLToPathMap_ release];
    [self->imagesDirPath_ release];
    [self->queue_ invalidate];
    [self->queue_ cancelAllOperations];
    [self->queue_ release];
    [self->error_ release];
    [self->URL_ release];
    [super dealloc];
}

- (QWatchedOperationQueue *)queue
{
    if (self->queue_ == nil) {
        self->queue_ = [[QWatchedOperationQueue alloc] initWithTarget:self];
        assert(self->queue_ != nil);
    }
    return self->queue_;
}

- (NSDictionary *)imageURLToPathMap
    // This getter returns a snapshot of the current fetcher state so that, 
    // if you call it before the fetcher is done, you don't get a mutable array 
    // that's still being mutated.
{
    return [[self.foundImageURLToPathMap copy] autorelease];
}

- (BOOL)start
    // See comment in header.
{
    BOOL            success;
    NSFileManager * fm;
    
    fm = [NSFileManager defaultManager];
    assert(fm != nil);

    success = [fm createDirectoryAtPath:self.imagesDirPath withIntermediateDirectories:NO attributes:nil error:NULL];
    if ( ! success ) {
        // If the create failed, it could be because the directory already exists. 
        // So let's get a listing and see if that succeeds.
    
        success = [fm contentsOfDirectoryAtPath:self.imagesDirPath error:NULL] != nil;
    }

    // Start the main GET operation, that gets the HTML whose links we want 
    // to download.
    
    if (success) {
        [self startPageGet:self.URL depth:0];
    }
    
    return success;
}

- (void)stopWithError:(NSError *)error
    // An internal method called to stop the fetch and clean things up.
{
    assert(error != nil);
    [self.queue invalidate];
    [self.queue cancelAllOperations];
    self.error = error;
    // When we set done our client's KVO might release us, meaning that we end 
    // up running with an invalid self.  This can cause all sorts of problems, 
    // so we do my standard retain/autorelease technique to avoid it.
    [[self retain] autorelease];
    self.done = YES;
}

- (void)stop
    // See comment in header.
{
    [self stopWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]];
}

- (void)logText:(NSString *)text URL:(NSURL *)url depth:(NSUInteger)depth error:(NSError *)error
    // An internal method called to log information about the fetch. 
    // This either logs to stdout or via a delegate callback.
{
    assert(text != nil);
    assert(url != nil);
    // depth has no constraints
    // error may be nil
    
    if (self.delegate == nil) {
        // If there's no delegate, we just log to stdout 'cause that's what best suits the 
        // command line tool.
        if (error == nil) {
            fprintf(stdout, "%*s%s\n", (int) (depth * 2), "", [[url absoluteString] UTF8String]);
            fprintf(stdout, "%*s  %s\n", (int) (depth * 2), "", [text UTF8String]);
        } else {
            fprintf(stdout, "%*s%s\n", (int) (depth * 2), "", [[url absoluteString] UTF8String]);
            fprintf(stdout, "%*s  %s: %s %d\n", (int) (depth * 2), "", [text UTF8String], [[error domain] UTF8String], (int) [error code]);
        }
    } else if ([self.delegate respondsToSelector:@selector(linkedImageFetcher:logText:URL:depth:error:)]) {
        [self.delegate linkedImageFetcher:self logText:text URL:url depth:depth error:error];
    }    
}

// IMPORTANT: runningOperationCount is only ever modified by the main thread, 
// so we don't have to do any locking.  Also, because the 'done' methods are called 
// on the main thread, we don't have to worry about early completion, that is, 
// -parseDone: kicking off download 1, then getting delayed, then download 1 
// completing, decrementing runningOperationCount, and deciding that we're 
// all done.  The decrement of runningOperationCount is done by -downloadDone: 
// and -downloadDone: can't run until we return back to the run loop.

- (void)operationDidStart
    // Called when an operation has started to increment runningOperationCount. 
{
    self.runningOperationCount += 1;
}

- (void)operationDidFinish
    // Called when an operation has finished to decrement runningOperationCount 
    // and complete the whole fetch if it hits zero.
{
    assert(self.runningOperationCount != 0);
    self.runningOperationCount -= 1;
    if (self.runningOperationCount == 0) {
        // See comment in -stopWithError:.
        [[self retain] autorelease];
        self.done = YES;
    }    
}

- (void)startPageGet:(NSURL *)pageURL depth:(NSUInteger)depth
    // Starts the operation to GET an HTML page.  Called for both the 
    // initial main page, and for any subsequently linked-to pages.
{
    PageGetOperation *  op;
    
    assert([pageURL baseURL] == nil);       // must be an absolute URL
    assert( ! [self.foundPageURLs containsObject:pageURL] );
    
    [self.foundPageURLs addObject:pageURL];
    
    op = [[[PageGetOperation alloc] initWithURL:pageURL depth:depth] autorelease];
    assert(op != nil);
    
    [self.queue addOperation:op finishedAction:@selector(pageGetDone:)];
    [self operationDidStart];
    
    // ... continues in -pageGetDone:
}

- (void)pageGetDone:(PageGetOperation *)op
    // Called when the GET for an HTML page is done.  We start a LinkFinder 
    // operation to parse the HTML.
{
    assert([op isKindOfClass:[PageGetOperation class]]);
    assert([NSThread isMainThread]);
    
    if (op.error != nil) {

        // An error getting the main page is fatal to the entire process; an error 
        // getting any subsequent pages is just logged.

        if (op.depth == 0) {
            [self stopWithError:op.error];
        } else {
            [self logText:@"page get error" URL:op.URL depth:op.depth error:op.error];
        }

    } else {
        LinkFinder *    nextOp;

        [self logText:@"page get done" URL:op.URL depth:op.depth error:nil];
        
        // Don't use op.URL here, but rather [op.lastResponse URL] so that relatives 
        // URLs work in the face of redirection.
        
        nextOp = [[[LinkFinder alloc] initWithData:op.responseBody fromURL:[op.lastResponse URL] depth:op.depth] autorelease];
        assert(nextOp != nil);
        
        nextOp.useRelaxedParsing = YES;
        
        [self.queue addOperation:nextOp finishedAction:@selector(parseDone:)];
        [self operationDidStart];
        
        // ... continues in -parseDone:
    }
    
    [self operationDidFinish];
}

- (void)parseDone:(LinkFinder *)op
    // Called when the link finder operation is done.  We look at the links 
    // and start an appropriate number of page get and image download operations. 
{
    #pragma unused(op)
    assert([op isKindOfClass:[LinkFinder class]]);
    assert([NSThread isMainThread]);

    if (op.error != nil) {

        // An error parsing the main page is fatal to the entire process; an error 
        // parsing any subsequent pages is just logged.

        if (op.depth == 0) {
            [self stopWithError:op.error];
        } else {
            [self logText:@"page parse error" URL:op.URL depth:op.depth error:op.error];
        }

    } else {
        NSURL *     thisURL;
        NSURL *     thisURLAbsolute;

        // We need to use absolute URLs in order to test for membership in 
        // foundPageURLs and foundImageURLToPathMap.
        
        // Process all of the links in the page.  But only if we haven't exceeded 
        // our maximum depth.  And if we haven't already processed that page URL.
        
        if (op.depth != self.maximumDepth) {
            for (thisURL in op.linkURLs) {
                thisURLAbsolute = [thisURL absoluteURL];
                assert(thisURLAbsolute != nil);
                
                if ( [[self class] isSupportedURL:thisURLAbsolute] ) {
                    if ([self.foundPageURLs containsObject:thisURLAbsolute]) {
                        [self logText:@"page is duplicate" URL:thisURLAbsolute depth:op.depth error:nil];
                    } else if ( ([thisURLAbsolute fragment] != nil) || ([thisURLAbsolute parameterString] != nil) || ([thisURLAbsolute query] != nil) ) {
                        [self logText:@"page URL is complex" URL:thisURLAbsolute depth:op.depth error:nil];
                    } else {
                        [self startPageGet:thisURLAbsolute depth:op.depth + 1];
                    }
                } else {
                    [self logText:@"page URL is unsupported" URL:thisURLAbsolute depth:op.depth error:nil];
                }
            }
        }
        
        // Download all of the images in the page, but only if we haven't already 
        // downloaded that image.
        
        for (thisURL in op.imageURLs) {
            thisURLAbsolute = [thisURL absoluteURL];
            assert(thisURLAbsolute != nil);

            if ( [[self class] isSupportedURL:thisURLAbsolute] ) {
                if ([self.foundImageURLToPathMap objectForKey:thisURLAbsolute] != nil) {
                    [self logText:@"image is duplicate" URL:thisURLAbsolute depth:op.depth error:nil];
                } else {
                    ImageDownloadOperation *    downloadOperation;

                    // Put in a placeholder for the download.
                    
                    [self.foundImageURLToPathMap setObject:[NSNull null] forKey:thisURLAbsolute];

                    downloadOperation = [[[ImageDownloadOperation alloc] initWithURL:thisURLAbsolute imagesDirPath:self.imagesDirPath depth:op.depth + 1] autorelease];
                    assert(downloadOperation != nil);

                    [self.queue addOperation:downloadOperation finishedAction:@selector(downloadDone:)];
                    [self operationDidStart];
                    
                    // ... continues in -downloadDone:
                }
            } else {
                [self logText:@"image URL is unsupported" URL:thisURLAbsolute depth:op.depth error:nil];
            }
        }
    }
    
    [self operationDidFinish];
}

- (void)downloadDone:(ImageDownloadOperation *)op
    // Called when an image download operation is done.
{
    #pragma unused(op)
    assert([op isKindOfClass:[ImageDownloadOperation class]]);
    assert([NSThread isMainThread]);

    // Replace the NSNull in the foundImageURLToPathMap with the path to the downloaded 
    // file (on success) or the error.  Note that we use op.URL here, not [op.lastResponse URL], 
    // because this stuff is keyed on the original URL, not the final URL after redirects.
    
    assert([[self.foundImageURLToPathMap objectForKey:op.URL] isEqual:[NSNull null]]);
    if (op.error != nil) {
        [self.foundImageURLToPathMap setObject:op.error forKey:op.URL];
        [self logText:@"image download error" URL:op.URL depth:op.depth error:op.error];
    } else {
        [self.foundImageURLToPathMap setObject:op.imageFilePath forKey:op.URL];
        [self logText:[NSString stringWithFormat:@"image download to: %@", op.imageFilePath] URL:op.URL depth:op.depth error:nil];
    }
    
    [self operationDidFinish];
}

+ (id)fetcherWithURLString:(const char *)urlCStr maximumDepth:(int)maximumDepth
    // See comment in header.
{
    LinkedImageFetcher *    result;
    NSString *              urlStr;
    NSURL *                 url;
    
    assert(urlCStr != NULL);
    
    result = nil;

    // First construct and check the URL.

    url = nil;
    
    urlStr = [NSString stringWithUTF8String:urlCStr];
    if (urlStr != nil) {
        url = [NSURL URLWithString:urlStr];
    }

    if (url == nil) {
        fprintf(stderr, "%s: malformed URL: %s\n", getprogname(), urlCStr);
    } else {
        if ( ! [self isSupportedURL:url] ) {
            fprintf(stderr, "%s: unsupported URL scheme: %s\n", getprogname(), [[[url scheme] lowercaseString] UTF8String]);
            url = nil;
        }
    }
    
    // Then check maximumDepth.  If that passes, create the object to return.
    
    if (url != nil) {
        if (maximumDepth < 0) {
            fprintf(stderr, "%s: maximum depth must be non-negative\n", getprogname());
        } else {
            result = [[[self alloc] initWithURL:url] autorelease];
            if (result != nil) {
                result.maximumDepth = maximumDepth;
            }
        }
    }
    
    return result;
}

@end
