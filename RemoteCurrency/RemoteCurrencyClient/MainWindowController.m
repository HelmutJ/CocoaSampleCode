/*
    File:       MainWindowController.m

    Contains:   A window controller for the main user interface.

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

#import "MainWindowController.h"

#import "RemoteCurrencyConverter.h"

@interface MainWindowController () <QBrowserDelegate>

@property (nonatomic, retain, readwrite) RemoteCurrencyConverter *  remote;

@end

@implementation MainWindowController

@synthesize browser      = browser_;
@synthesize browserArray = browserArray_;

@synthesize remote       = remote_;
@synthesize browserSortDescriptors = browserSortDescriptors_;
@synthesize fromCurrency = fromCurrency_;
@synthesize fromValueObj = fromValueObj_;
@synthesize toCurrency   = toCurrency_;

- (id)init
{
    self = [super initWithWindowNibName:@"MainWindow"];
    if (self != nil) {
        self->browser_ = [[QBrowser alloc] initWithDomain:nil type:@"_x-remotecurrency._tcp"];
        self->browser_.delegate = self;
        [self->browser_ start];
    
        browserSortDescriptors_ = [[NSArray alloc] initWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"domain" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"type" ascending:YES], nil];
        
        self->fromCurrency_ = @"USD";
        self->fromValueObj_ = [[NSNumber alloc] initWithDouble:100.0];
        self->toCurrency_   = @"GBP";
        
        [self addObserver:self forKeyPath:@"fromCurrency" options:0 context:&self->fromCurrency_];
        [self addObserver:self forKeyPath:@"fromValueObj" options:0 context:&self->fromValueObj_];
        [self addObserver:self forKeyPath:@"toCurrency"   options:0 context:&self->toCurrency_  ];
    }
    return self;
}

- (void)dealloc
{
    assert(NO);     // this hasn't actually been tested
    if (self.browserArray != nil) {
        [self.browserArray removeObserver:self forKeyPath:@"selectedObjects"];
    }

    [self removeObserver:self forKeyPath:@"fromCurrency"];
    [self removeObserver:self forKeyPath:@"fromValueObj"];
    [self removeObserver:self forKeyPath:@"toCurrency"];
    [self->remote_ release];
    [self->browserSortDescriptors_ release];
    [self->fromCurrency_ release];
    [self->toCurrency_ release];
    [super dealloc];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    assert(self.browserArray != nil);
    [self.browserArray addObserver:self forKeyPath:@"selectedObjects" options:NSKeyValueObservingOptionInitial context:&self->browserArray_];
}

- (NSArray *)fromCurrencies
{
    static NSArray * sFromCurrencies;
    
    if (sFromCurrencies == nil) {
        sFromCurrencies = [[NSArray alloc] initWithObjects:
            @"USD",
            @"EUR",
            @"GBP",
            @"JPY",
            @"AUD",
            nil
        ];
        assert(sFromCurrencies != nil);
    }
    return sFromCurrencies;
}

- (NSArray *)toCurrencies
{
    return self.fromCurrencies;
}

+ (NSSet *)keyPathsForValuesAffectingToValueObj
{
    return [NSSet setWithObject:@"remote.networkActive"];
}

- (NSNumber *)toValueObj
{
    NSNumber *  result;
    
    result = nil;
    if (self.remote != nil) {
        result = self.remote.result;
    }
    return result;
}

+ (NSSet *)keyPathsForValuesAffectingBusy
{
    return [NSSet setWithObject:@"remote.networkActive"];
}

- (BOOL)busy
{
    return (self.remote != nil) && self.remote.networkActive;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ( (context == &self->fromCurrency_) || (context == &self->fromValueObj_) || (context == &self->toCurrency_) ) {
        assert( [keyPath isEqual:@"fromCurrency"] || [keyPath isEqual:@"fromValueObj"] || [keyPath isEqual:@"toCurrency"] );
        assert(object == self);
        if ( (self.remote != nil) && (self.fromValueObj != nil) ) {
            [self.remote startConvertingValue:[self.fromValueObj doubleValue] fromCurrency:self.fromCurrency toCurrency:self.toCurrency];
        }
    } else if (context == &self->browserArray_) {
        assert( [keyPath isEqual:@"selectedObjects"] );
        assert(object == self.browserArray);

        if (self.remote != nil) {
            [self.remote stopConverting];
            self.remote = nil;
        }

        if ([[self.browserArray selectedObjects] count] != 0) {
            NSNetService *  selectedNetService;
            
            selectedNetService = (NSNetService *) [[self.browserArray selectedObjects] objectAtIndex:0];
            assert([selectedNetService isKindOfClass:[NSNetService class]]);
            self.remote = [[[RemoteCurrencyConverter alloc] initWithNetService:selectedNetService] autorelease];
            assert(self.remote != nil);
            
            if ( (self.fromValueObj != nil) ) {
                [self.remote startConvertingValue:[self.fromValueObj doubleValue] fromCurrency:self.fromCurrency toCurrency:self.toCurrency];
            }
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
