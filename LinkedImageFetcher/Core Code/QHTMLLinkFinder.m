/*
    File:       QHTMLLinkFinder.m

    Contains:   Finds links in HTML.

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

#import "QHTMLLinkFinder.h"

#include <libxml/HTMLparser.h>

// If we're building with the 10.5 SDK, define our own version of this symbol.

#if LIBXML_VERSION < 20703
enum {
    HTML_PARSE_RECOVER  = 1<<0, /* Relaxed parsing */
};
#endif

@interface QHTMLLinkFinder ()

// Read/write versions of public properties

@property (copy,   readwrite) NSError *         error;

// Internal properties

@property (retain, readonly ) NSMutableArray *  mutableLinkURLs;
@property (retain, readonly ) NSMutableArray *  mutableImageURLs;

@end

@implementation QHTMLLinkFinder

@synthesize data  = data_;
@synthesize URL   = URL_;
@synthesize useRelaxedParsing = useRelaxedParsing_;

@synthesize error = error_;
@synthesize mutableLinkURLs  = mutableLinkURLs_;
@synthesize mutableImageURLs = mutableImageURLs_;

- (id)initWithData:(NSData *)data fromURL:(NSURL *)url
{
    assert(data != nil);
    assert(url != nil);
    self = [super init];
    if (self != nil) {
        self->data_ = [data copy];
        assert(self->data_ != nil);
        self->URL_ = [url copy];
        assert(self->URL_ != nil);
        self->mutableLinkURLs_ = [[NSMutableArray alloc] init];
        assert(self->mutableLinkURLs_ != nil);
        self->mutableImageURLs_ = [[NSMutableArray alloc] init];
        assert(self->mutableImageURLs_ != nil);
    }
    return self;
}

- (void)dealloc
{
    [self->mutableLinkURLs_ release];
    [self->mutableImageURLs_ release];
    [self->error_ release];
    [self->URL_ release];
    [self->data_ release];
    [super dealloc];
}

- (NSArray *)linkURLs
    // This getter returns a snapshot of the current parser state so that, 
    // if you call it before the parse is done, you don't get a mutable array 
    // that's still being mutated.
{
    return [[self->mutableLinkURLs_ copy] autorelease];
}

- (NSArray *)imageURLs
    // This getter returns a snapshot of the current parser state so that, 
    // if you call it before the parse is done, you don't get a mutable array 
    // that's still being mutated.
{
    return [[self->mutableImageURLs_ copy] autorelease];
}

- (void)addURLForCString:(const char *)cStr toArray:(NSMutableArray *)array
    // Adds a URL to the specified array, handling lots of wacky edge cases.
{
    NSString *  str;
    NSURL *     url;
    
    // cStr should be ASCII but, just to be permissive, we'll accept UTF-8. 
    // Handle the case where cStr is not valid UTF-8.
    
    str = [NSString stringWithUTF8String:cStr];
    if (str == nil) {
        assert(NO);
    } else {
    
        // Construct a relativel URL based on our base URL and the string. 
        // This can and does fail on real world systems (curse those users 
        // and their bogus HTML!).
    
        url = [NSURL URLWithString:str relativeToURL:self.URL];
        if (url == nil) {
            NSLog(@"Could not construct URL from '%@' relative to '%@'.", str, self.URL);
            // assert(NO);
        } else {
            [array addObject:url];
                
            // For testing purposes, we add a bogus link every five links.
            
            if (NO) {
                static int sErrorIndex;
                
                url = [NSURL URLWithString:[str stringByAppendingString:@"-bogus"] relativeToURL:self.URL];
                assert(url != nil);
                
                sErrorIndex += 1;
                if ((sErrorIndex % 5) == 0) {
                    [array addObject:url];
                    sErrorIndex += 1;
                }
            }
        }
    }
}

static void StartElementSAXFunc(
    void *          ctx,
    const xmlChar * name,
    const xmlChar **attrs
)
    // Called by the HTML parser when we encounter the beginning of a 
    // tag.  This looks for "a" and "img" tags and, within those, looks for 
    // "href" and "src" attributes, respectively.  Upon finding such an attribute 
    // it uses the value of the attribute to construct a URL to add to the relevant 
    // mutable results array.
{
    QHTMLLinkFinder *   obj;
    size_t      attrIndex;
    
    obj = (QHTMLLinkFinder *) ctx;
    assert([obj isKindOfClass:[QHTMLLinkFinder class]]);
    
    // libxml2's HTML parser lower cases tag and attribute names, so 
    // strcmp (rather than strcasecmp) is correct here.
    
    // Tags without attributes are not useful to us.
    
    if (attrs != NULL) {
    
        // Check for the tags we care about and, within them, check for 
        // the attributes we care about.
        
        if ( strcmp( (const char *) name, "a") == 0 ) {
            attrIndex = 0;
            while (attrs[attrIndex] != NULL) {
                if ( strcmp( (const char *) attrs[attrIndex], "href") == 0 ) {
                    [obj addURLForCString:(const char *) attrs[attrIndex + 1] toArray:obj.mutableLinkURLs];
                }
                attrIndex += 2;
            }
        } else if ( strcmp( (const char *) name, "img") == 0 ) {
            attrIndex = 0;
            while (attrs[attrIndex] != NULL) {
                if ( strcmp( (const char *) attrs[attrIndex], "src") == 0 ) {
                    [obj addURLForCString:(const char *) attrs[attrIndex + 1] toArray:obj.mutableImageURLs];
                }
                attrIndex += 2;
            }
        }
    }
}

static xmlSAXHandler gSAXHandler = {
    .initialized  = XML_SAX2_MAGIC,
    .startElement = StartElementSAXFunc
};

- (void)main
{
    struct _xmlParserCtxt * context;

    // Create and run a libxml2 HTML parser.
    
    context = htmlCreatePushParserCtxt(
        &gSAXHandler,
        self,
        NULL,
        0,
        nil,
        XML_CHAR_ENCODING_NONE
    );
    if (context == NULL) {
        self.error = [NSError errorWithDomain:NSXMLParserErrorDomain code:XML_ERR_INTERNAL_ERROR userInfo:nil];
    } else {
        int     err;
        
        // If the client has specified relaxed parsing, set that up in the 
        // libxml2 parser.  First try with HTML_PARSE_RECOVER and, if that 
        // fails, retry without it.
        
        if (self.useRelaxedParsing) {
            err = htmlCtxtUseOptions(context, HTML_PARSE_RECOVER | HTML_PARSE_NOERROR | HTML_PARSE_NOWARNING);
            if (err != 0) {
                (void) htmlCtxtUseOptions(context, HTML_PARSE_NOERROR | HTML_PARSE_NOWARNING);
            }
            // We really don't care if this stuff fails.  err gets overwritten by the call 
            // to htmlParseChunk below.
        }

        // htmlParseChunk will only accept an int as the data length. On 64-bit builds, 
        // that's a problem, because [self.data length] is an NSUInteger, which might be greater 
        // than 2 GB.  I could address this properly (by calling htmlParseChunk repeatedly on 
        // 2 GB chunks) but IMO that's not a great solution; if you're parsing data that big, 
        // you really don't want to hold it all in memory even in a 64-bit process.  So, for 
        // the sake of simplicity, I've just added the following assert.
        
        assert( [self.data length] <= (NSUInteger) INT_MAX );
        
        // Parse the data.
        
        err = htmlParseChunk(
            context, 
            [self.data bytes], 
            (int) [self.data length], 
            YES
        );
        
        // Handle the result.
        
        if (err != 0) {
            if (self.error == nil) {
                // The libxml2 HTML parser shares the same errors as the XML parser, so we just 
                // borrow NSXMLParser's error domain.  Keep in mind that you might encounter 
                // errors that aren't explicitly listed in <Foundation/NSXMLParser.h>, such 
                // as XML_HTML_UNKNOWN_TAG.  See xmlParserErrors in <libxml/xmlerror.h> for 
                // the full list.
                self.error = [NSError errorWithDomain:NSXMLParserErrorDomain code:err userInfo:nil];
            }
        }
   
        // Clean up.
        
        htmlFreeParserCtxt(context);
    }
}

@end
