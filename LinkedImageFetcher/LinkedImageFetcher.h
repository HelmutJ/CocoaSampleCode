/*
    File:       LinkedImageFetcher.h

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

#import <Foundation/Foundation.h>

#import "QWatchedOperationQueue.h"

@protocol LinkedImageFetcherDelegate;

@interface LinkedImageFetcher : NSObject
{
    NSURL *                         URL_;
    NSUInteger                      maximumDepth_;
    NSString *                      imagesDirPath_;
    id<LinkedImageFetcherDelegate>  delegate_;
    QWatchedOperationQueue *        queue_;
    BOOL                            done_;
    NSError *                       error_;
    NSMutableSet *                  foundPageURLs_;
    NSMutableDictionary *           foundImageURLToPathMap_;
    NSUInteger                      runningOperationCount_;
}

+ (BOOL)isSupportedURL:(NSURL *)url;

- (id)initWithURL:(NSURL *)url;
    // Initialises the object to start by downloading the HTML at the 
    // specified URL.

// Things that are configured by the init method and can't be changed.

@property (nonatomic, copy,   readonly ) NSURL *        URL;

// Things you can change before calling -start.

@property (nonatomic, assign, readwrite) NSUInteger     maximumDepth;       // defaults to 0
@property (nonatomic, copy,   readwrite) NSString *     imagesDirPath;      // defaults to the "images" directory within the temporary directory
                                                                            // don't change this after calling -startWithURLString:
@property (nonatomic, assign, readwrite) id<LinkedImageFetcherDelegate> delegate;

// Things that are meaningful after you've called -start.

@property (nonatomic, assign, readwrite) BOOL           done;               // observable
@property (nonatomic, copy,   readonly ) NSError *      error;              // nil if no error

@property (nonatomic, copy,   readonly ) NSDictionary * imageURLToPathMap;  // NSURL -> NSNull (in progress), NSError (failed), NSString (downloaded)

// Methods to start and stop the fetch.  Note that this is a one-shot thing; 
// you can't call -stop and then call -start again.

- (BOOL)start;
- (void)stop;

+ (id)fetcherWithURLString:(const char *)urlCStr maximumDepth:(int)maximumDepth;
    // Convenience method for the command line test program.
    // Handles urlStr being nil.  Handles the URL scheme being unsupported.  
    // Handles maximum depth being negative.

@end

@protocol LinkedImageFetcherDelegate <NSObject>

@optional

- (void)linkedImageFetcher:(LinkedImageFetcher *)fetcher logText:(NSString *)text URL:(NSURL *)url depth:(NSUInteger)depth error:(NSError *)error;
    // You can implement this delegate method to do your own logging.
    // You're called with some text, the URL that the text relates to, 
    // the depth of that URL (0 if the it relates to the main page, 1 
    // if it relates to resource directly linked to from the main page, 
    // and so on) and an optional error.

@end
