/*
     File: SearchQuery.m 
 Abstract: Data model for a photo search query.
  
  Version: 1.6 
  
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

#import "SearchQuery.h"

NSString *SearchQueryChildrenDidChangeNotification = @"SearchQueryChildrenDidChangeNotification";

@implementation SearchQuery

@synthesize _searchURL;

- (id)initWithSearchPredicate:(NSPredicate *)searchPredicate title:(NSString *)title scopeURL:(NSURL *)url {
    self = [super init];
    if (self)
    {
        _title = [title retain];
        _query = [[NSMetadataQuery alloc] init];
        _searchURL = [url retain];
        
        // We want the items in the query to automatically be sorted by the file system name;
        // this way, we don't have to do any special sorting
        [_query setSortDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:(id)kMDItemFSName ascending:YES] autorelease]]];
        [_query setPredicate:searchPredicate];
        
        // Use KVO to watch the results of the query
        [_query addObserver:self forKeyPath:@"results" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
        [_query setDelegate:self];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(queryNote:) name:nil object:_query];
        
        // define the scope/where the search will take placce
        [_query setSearchScopes:(url != nil) ? [NSArray arrayWithObject:url] : nil];
        
        [_query startQuery];
    }
    return self;    
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];    
    [_query removeObserver:self forKeyPath:@"results"];
    [_query release];
    [_title release];
    [_searchURL release];
    [_children release];
    
    [super dealloc];
}

- (void)sendChildrenDidChangeNote {
    [[NSNotificationCenter defaultCenter] postNotificationName:SearchQueryChildrenDidChangeNotification object:self];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    // Delegate the KVO notification by sending a children changed note.
    // We could check the keyPath, but there is no need, since we only observe one value.
    //
    [_children release];
    _children = [[_query results] retain];
    [self sendChildrenDidChangeNote];
}

#pragma NSMetadataQuery Delegate

- (id)metadataQuery:(NSMetadataQuery *)query replacementObjectForResultObject:(NSMetadataItem *)result {
    // We keep our own search item for the result in order to maintian state (image, thumbnail, title, etc)
    return [[[SearchItem alloc] initWithItem:result] autorelease];
}

- (void)queryNote:(NSNotification *)note {
    // The NSMetadataQuery will send back a note when updates are happening.
    // By looking at the [note name], we can tell what is happening
    //
    if ([[note name] isEqualToString:NSMetadataQueryDidFinishGatheringNotification]) {
        // At this point, the query will be done. You may recieve an update later on.
        if ([_children count] == 0) {
            [_children release];
            SearchItem *emptyItem = [[[SearchItem alloc] initWithItem:nil] autorelease];
            [emptyItem setTitle:NSLocalizedString(@"No results", @"Text to display when there are no results")];
            _children = [[NSArray alloc] initWithObjects:emptyItem, nil];
            [self sendChildrenDidChangeNote];
        }        
    }
}

#pragma mark -

- (NSString *)title {
    return _title;
}

- (NSArray *)children {
    return _children;
}

@end
