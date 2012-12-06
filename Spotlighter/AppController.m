/*
     File: AppController.m
 Abstract: This is the main controller for the user interface. Most of the work is done by bindings.
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


#import "AppController.h"
#import "AppTransformers.h"

// Allow us to bind to the icon of a NSMetadataItem by extending it
@implementation NSMetadataItem (ItemExtras)
- (NSImage *)icon {
    NSString *path = [self valueForKey:(id)kMDItemPath];
    return [[NSWorkspace sharedWorkspace] iconForFile:path];
}

@end

@implementation AppController

+ (void)initialize {
    if (self == [AppController class]) {    // We want to do this once
        // Create some transformers used by the UI.
        // To see where these values are, open up MainMenu.nib, look at the Value item on the Bindings tab and notice how some items specify these transformers in the "Value Transformer" field. For example, the NSTextField labled "Query is alive..." has the "Value Transformer" set to "RunningTransformer".
        NSValueTransformer *runTrans = [[IsRunningTransformer alloc] init];
        [NSValueTransformer setValueTransformer:runTrans forName:@"RunningTransformer"];
        [runTrans release];

        // In the "Grouped Results" tab, the final "Size" column uses the "MBTransformer"
        NSValueTransformer *mbTrans = [[MBTransformer alloc] init];
        [NSValueTransformer setValueTransformer:mbTrans forName:@"MBTransformer"];
        [mbTrans release];

        // In the "Grouped Results" tab, the first column in the bottom NSTableView uses the MetadataItemIconTransformer to display an icon
        NSValueTransformer *iconTrans = [[MetadataItemIconTransformer alloc] init];
        [NSValueTransformer setValueTransformer:iconTrans forName:@"MetadataItemIconTransformer"];
        [iconTrans release];
    }
}

- (id)init {
    if (self = [super init]) {
        self.searchKey = @"";
        
        self.query = [[[NSMetadataQuery alloc] init] autorelease];
        // To watch results send by the query, add an observer to the NSNotificationCenter
        NSNotificationCenter *nf = [NSNotificationCenter defaultCenter];
        [nf addObserver:self selector:@selector(queryNote:) name:nil object:self.query];
        
        // We want the items in the query to automatically be sorted by the file system name; this way, we don't have to do any special sorting
        [self.query setSortDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:(id)kMDItemFSName ascending:YES] autorelease]]];
        // For the groups, we want the first grouping by the kind, and the second by the file size. 
        [self.query setGroupingAttributes:[NSArray arrayWithObjects:(id)kMDItemKind, (id)kMDItemFSSize, nil]];
        [self.query setDelegate:self];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [query release];
    [searchKey release];
    [super dealloc];
}

@synthesize query;

- (void)queryNote:(NSNotification *)note {
    // The NSMetadataQuery will send back a note when updates are happening. By looking at the [note name], we can tell what is happening
    if ([[note name] isEqualToString:NSMetadataQueryDidStartGatheringNotification]) {
        // The gathering phase has just started!
        NSLog(@"Started gathering");
    } else if ([[note name] isEqualToString:NSMetadataQueryDidFinishGatheringNotification]) {
        // At this point, the gathering phase will be done. You may recieve an update later on.
        NSLog(@"Finished gathering");
    } else if ([[note name] isEqualToString:NSMetadataQueryGatheringProgressNotification]) {
        // The query is still gatherint results...
        NSLog(@"Progressing...");
    } else if ([[note name] isEqualToString:NSMetadataQueryDidUpdateNotification]) {
        // An update will happen when Spotlight notices that a file as added, removed, or modified that affected the search results.
        NSLog(@"An update happened.");
    }
}

// NSMetadataQuery delegate methods.
// metadataQuery:replacementValueForAttribute:value allows the resulting value retrieved from an NSMetadataItem to be changed. When items are grouped, we want to allow all items of a similar size to be grouped together. This allows this to happen.
- (id)metadataQuery:(NSMetadataQuery *)query replacementValueForAttribute:(NSString *)attrName value:(id)attrValue {
    if ([attrName isEqualToString:(id)kMDItemFSSize]) {
        NSInteger fsSize = [attrValue integerValue];
        // Here is a special case for small files
        if (fsSize == 0) {
            return NSLocalizedString(@"0 Byte Files", @"File size, for empty files and directories");
        }
        const NSInteger cutOff = 1024;
        
        if (fsSize < cutOff) {
            return NSLocalizedString(@"< 1 KB Files", @"File size, for items that are less than 1 kilobyte");
        }
        
        // Figure out how many kb, mb, etc, that we have
        NSInteger numK = fsSize / 1024;
        if (numK < cutOff) {
            return [NSString stringWithFormat:NSLocalizedString(@"%ld KB Files", @"File size, expressed in kilobytes"), (long)numK];
        }
        
        NSInteger numMB = numK / 1024;
        if (numMB < cutOff) {
            return [NSString stringWithFormat:NSLocalizedString(@"%ld MB Files", @"File size, expressed in megabytes"), (long)numMB];
        }
        
        return NSLocalizedString(@"Huge files", @"File size, for really large files");
    } else if ((attrValue == nil) || (attrValue == [NSNull null])) {
        // We don't want to display <null> for the user, so, depending on the category, display something better
        if ([attrName isEqualToString:(id)kMDItemKind]) {
            return NSLocalizedString(@"Other", @"Kind to display for unknown file types");
        } else {
            return NSLocalizedString(@"Unknown", @"Kind to display for other unknown values"); 
        }
    } else {
        return attrValue;
    }
    
}

- (void)createSearchPredicate {
    // This demonstrates a few ways to create a search predicate.
    
    // The user can set the checkbox to include this in the search result, or not.
    NSPredicate *predicateToRun = nil;
    if (self.searchContent) {
        // In the example below, we create a predicate with a given format string that simply replaces %@ with the string that is to be searched for. By using "like", the query will end up doing a regular expression search similar to *foo* when you are searching for the word "foo". By using the [c], the NSCaseInsensitivePredicateOption will be set in the created predicate. The particular item type to search for, kMDItemTextContent, is described in MDItem.h.
        NSString *predicateFormat = @"kMDItemTextContent like[c] %@";
        predicateToRun = [NSPredicate predicateWithFormat:predicateFormat, self.searchKey];
    }
    
    // Create a compound predicate that searches for any keypath which has a value like the search key. This broadens the search results to include things such as the author, title, and other attributes not including the content. This is done in code for two reasons: 1. The predicate parser does not yet support "* = Foo" type of parsing, and 2. It is an example of creating a predicate in code, which is much "safer" than using a search string.
    NSUInteger options = (NSCaseInsensitivePredicateOption|NSDiacriticInsensitivePredicateOption);
    NSPredicate *compPred = [NSComparisonPredicate
                predicateWithLeftExpression:[NSExpression expressionForKeyPath:@"*"]
                            rightExpression:[NSExpression expressionForConstantValue:self.searchKey]
                                   modifier:NSDirectPredicateModifier
                                       type:NSLikePredicateOperatorType
                                    options:options];
    
    // Combine the two predicates with an OR, if we are including the content as searchable
    if (self.searchContent) {
        predicateToRun = [NSCompoundPredicate orPredicateWithSubpredicates:[NSArray arrayWithObjects:compPred, predicateToRun, nil]];
    } else {
        // Since we aren't searching the content, just use the other predicate
        predicateToRun = compPred;
    }
    
    // Now, we don't want to include email messages in the result set, so add in an AND that excludes them
    NSPredicate *emailExclusionPredicate = [NSPredicate predicateWithFormat:@"(kMDItemContentType != 'com.apple.mail.emlx') && (kMDItemContentType != 'public.vcard')"];
    predicateToRun = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:predicateToRun, emailExclusionPredicate, nil]];
    
    // Set it to the query. If the query already is alive, it will update immediately
    [self.query setPredicate:predicateToRun];           
    
    // In case the query hasn't yet started, start it.
    [self.query startQuery]; 
}

- (void)setSearchContent:(BOOL)value {
    if (searchContent != value) {
        searchContent = value;
        [self createSearchPredicate];
    }
}

- (BOOL)searchContent {
    return searchContent;
}

- (void)setSearchKey:(NSString *) value {
    if (searchKey != value) {
        [searchKey release];
        searchKey = [value copy];
        [self createSearchPredicate];
    }
}

- (NSString *)searchKey {
    return [[searchKey retain] autorelease];
}

// Connected via bindings, not target/action
- (void)tableViewDoubleClick:(id)path {
    [[NSWorkspace sharedWorkspace] openFile:path];
}

@end
