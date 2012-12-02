/*
     File: TransactionsController_Sorting.m
 Abstract: This category implements automatic re-sorting for entries in the transactions table.  We use Key value observing to observe when a transaction is added, or when a sorted value in a transaction changes. In either case, we schedule a call to rearrangeObjects to re-sort the table.
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

#import "TransactionsController.h"

static NSString *TransactionsContext = @"TransactionsController.transactions";
static NSString *SortContext = @"TransactionsController.sort";

@implementation TransactionsController(Sorting)

// -bind:toObject:withKeyPath:options: is invoked because we have bound the contentArray of this arrayController to transactions in the document.  Use this as a hook to set up an observation of the transactions array, which we will use for sorting.
- (void)bind:(NSString *)binding toObject:(id)observable withKeyPath:(NSString *)keyPath options:(NSDictionary *)options {
    [super bind:binding toObject:observable withKeyPath:keyPath options:options];
    // set this controller as an observer of the object and keyPath to which its contentArray is bound (should be MyDocument.transactions)
    if ([binding isEqualToString:@"contentArray"]) {
        [observable addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:TransactionsContext];
        _observedKeyPath = keyPath;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    // Note that we use pointer comparison for the context argument.  If this observation was set up by super, we can't be sure context will be an object, so we shouldn't use isEqual:. 
    if (context == TransactionsContext) {
        // observeValueForKeyPath:ofObject:change:context: is invoked with the context we specified above whenever an entry is added or removed from the transactions array
        NSKeyValueChange changeKind = [[change objectForKey:NSKeyValueChangeKindKey] integerValue];
        if (changeKind != NSKeyValueChangeRemoval) {
            // schedule a call to rearrangeObjects at the end of this iteration through the runloop
            [self scheduleRearrangeObjects];
        }
        // in order to update sort order when a value is changed within a transaction, we also need to observe these key paths
        [self updateObservationForOldTransactions:[change objectForKey:NSKeyValueChangeOldKey] newTransactions:[change objectForKey:NSKeyValueChangeNewKey]];
    } 
    else if (context == SortContext) {
        // a key path for a sort descriptor has been changed in a transaction
        [self scheduleRearrangeObjects];
    } 
    else {
        // be sure to call super.  Since we didn't recognize this context, this observation was probably set up by super.
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)scheduleRearrangeObjects {
    // if there is already a call to rearrangeObjects scheduled, we don't need to schedule another one
    if (!_pendingArrangement) {
        _pendingArrangement = YES;
        [self performSelector:@selector(rearrangeObjects) withObject:nil afterDelay:0.0];
    }
}

- (void)rearrangeObjects {
    [super rearrangeObjects];
    _pendingArrangement = NO;
}

- (void)setSortDescriptors:(NSArray *)sortDescriptors {
    // if the sort descriptors change, we need to update our observation of the key paths in the transactions
    [self removeSortObserversForTransactions:[self arrangedObjects] sortDescriptors:[self sortDescriptors]];
    [super setSortDescriptors:sortDescriptors];
    [self addSortObserversForTransactions:[self arrangedObjects] sortDescriptors:[self sortDescriptors]];
}

- (void)updateObservationForOldTransactions:(NSArray *)oldTransactions newTransactions:(NSArray *)newTransactions {
    if ([oldTransactions count] > 0) {
        // stop observing key paths for sort descriptors in transactions that have been removed
        [self removeSortObserversForTransactions:oldTransactions sortDescriptors:[self sortDescriptors]];
    }
    if ([newTransactions count] > 0) {
        // stop observing key paths for sort descriptors in transactions that have been removed
        [self addSortObserversForTransactions:newTransactions sortDescriptors:[self sortDescriptors]];
    }
}
    
- (void)addSortObserversForTransactions:(NSArray *)transactions sortDescriptors:(NSArray *)sortDescriptors {
    
    NSSortDescriptor *sortDescriptor;
    NSIndexSet *allIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [transactions count])]; 
    for (sortDescriptor in sortDescriptors) {
        [transactions addObserver:self toObjectsAtIndexes:allIndexes forKeyPath:[sortDescriptor key] options:0 context:SortContext];
    }
}

- (void)removeSortObserversForTransactions:(NSArray *)transactions sortDescriptors:(NSArray *)sortDescriptors {
    
    NSSortDescriptor *sortDescriptor;
    NSIndexSet *allIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [transactions count])]; 
    for (sortDescriptor in sortDescriptors) {
        [transactions removeObserver:self fromObjectsAtIndexes:allIndexes forKeyPath:[sortDescriptor key]];
    }
}

- (void)unbind:(NSString *)binding {
    if ([binding isEqualToString:@"contentArray"] && _observedKeyPath != nil) {
        [_document removeObserver:self forKeyPath:_observedKeyPath];
        _observedKeyPath = nil;
    }
    [super unbind:binding];
}

- (void)dealloc {
    if (_observedKeyPath != nil) {
        [_document removeObserver:self forKeyPath:_observedKeyPath];
    }
    [self removeSortObserversForTransactions:[self arrangedObjects] sortDescriptors:[self sortDescriptors]];
    _document = nil;
    _observedKeyPath = nil;
    [super dealloc];
}

@end
