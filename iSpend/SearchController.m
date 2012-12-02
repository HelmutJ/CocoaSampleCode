/*
     File: SearchController.m
 Abstract: This class manages a search window, and uses NSMetadataQuery to perform  
 searches specified in the search window.
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


#import "SearchController.h"

@implementation NSMetadataItem (Helper) 

- (id)valueForUndefinedKey:(NSString *)key {
    if ([key isEqualToString:@"com_apple_ispendBalance"]) {
        // For items which do not have the "com_apple_ispendBalance" attribute, we need to return something. This gives a result in that case.
        return [NSNumber numberWithDouble:0];
    }
    return nil;
}

@end

@implementation SearchController

- (id)init {
    if (self = [super init]) {
        _query = [[NSMetadataQuery alloc] init];
        // We want the items in the query to automatically be sorted by the file system name; this way, we don't have to do any special sorting. 
        NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:(id)kMDItemFSName ascending:YES] autorelease];
        NSArray *descriptors = [NSArray arrayWithObject:sortDescriptor];
        [_query setSortDescriptors:descriptors];
    }
    return self;
}

- (void)dealloc {
    [_query release];
    [_searchKey release];
    [super dealloc];
}

- (IBAction)setSearchAllDocuments:(id)sender {
    [_allDocumentsMenuItem setState:1];
    [_iSpendDocumentsMenuItem setState:0];
    [self createSearchPredicate];
}

- (IBAction)setSearchISpendDocuments:(id)sender{
    [_allDocumentsMenuItem setState:0];
    [_iSpendDocumentsMenuItem setState:1];    
    [self createSearchPredicate];
}

// Add bindings code here

// In the nib file, we will bind to "query.reults" in the ArrayControler
- (NSMetadataQuery *)query {
    return _query;
}

// In the nib file, the NSSearchField's value is bound to "searchKey"
- (NSString *)searchKey {
    return [[_searchKey copy] autorelease];
}

- (void)setSearchKey:(NSString *) value {
    if (_searchKey != value) {
        [_searchKey release];
        if (value == nil) value = @"";
        _searchKey = [value copy];
        [self createSearchPredicate];
    }
}

- (void)createSearchPredicate {
    // Create the search predicate, set it, and start the query
    
    // The user can set the checkbox to include this in the search result, or not.
    NSPredicate *predicateToRun = nil;
    // In the example below, we create a predicate with a given format string that simply replaces %@ with the string that is to be searched for. By using "like", the query will end up doing a regular expression search similar to *foo* when you are searching for the word "foo". By using the [c], the NSCaseInsensitivePredicateOption will be set in the created predicate. The particular item type to search for, kMDItemTextContent, is described in MDItem.h.
    NSString *predicateFormat = @"kMDItemTextContent like[c] %@";
    predicateToRun = [NSPredicate predicateWithFormat:predicateFormat, _searchKey];
    
    // Create a compound predicate that searches for any keypath which has a value like the search key. This broadens the search results to include things such as the author, title, and other attributes not including the content. This is done in code for two reasons: 1. The predicate parser does not yet support "* = Foo" type of parsing, and 2. It is an example of creating a predicate in code, which is much "safer" than using a search string.
    NSUInteger options = (NSCaseInsensitivePredicateOption|NSDiacriticInsensitivePredicateOption);
    NSPredicate *compPred = [NSComparisonPredicate
                predicateWithLeftExpression:[NSExpression expressionForKeyPath:@"*"]
                            rightExpression:[NSExpression expressionForConstantValue:_searchKey]
                                   modifier:NSDirectPredicateModifier
                                       type:NSLikePredicateOperatorType
                                    options:options];
    
    // Combine the two predicates with an OR
    predicateToRun = [NSCompoundPredicate orPredicateWithSubpredicates:[NSArray arrayWithObjects:compPred, predicateToRun, nil]];
    
    // Now, we don't want to include email messages in the result set, so add in an AND that excludes them
    NSPredicate *emailExclusionPredicate = [NSPredicate predicateWithFormat:@"(kMDItemContentType != 'com.apple.mail.emlx') && (kMDItemContentType != 'public.vcard')"];
    predicateToRun = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:predicateToRun, emailExclusionPredicate, nil]];
    
    // If we are only searching for our types, be sure to specify that using an AND
    if ([_iSpendDocumentsMenuItem state] == 1) {
        NSPredicate *ourTypesPredicate = [NSPredicate predicateWithFormat:@"kMDItemContentType == 'com.apple.ispend.document'"];
        predicateToRun = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:predicateToRun, ourTypesPredicate, nil]];
    }
    
    // Set it to the query. If the query already is alive, it will update immediately
    [_query setPredicate:predicateToRun];           
    
    // In case the query hasn't yet started, start it.
    [_query startQuery]; 
}

- (void)openFile:(NSString *)path {
    [[NSWorkspace sharedWorkspace] openFile:path];
}

- (void)orderFrontSearchPanel:(id)sender {
    if (!_searchPanel) {
        if (![NSBundle loadNibNamed:@"SearchPanel" owner:self])  {
            NSLog(@"Failed to load SearchPanel.nib");
            NSBeep();
            return;
        }
    }

    [_searchPanel makeKeyAndOrderFront:sender];
}

@end
