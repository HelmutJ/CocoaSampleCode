/*
     File: MyDocument.m
 Abstract: This NSDocument subclass manages the data model for a personal finance application.  It uses bindings to keep the model and view in sync.
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


#import "MyDocument.h"
#import "MyDocument_Pasteboard.h"
#import "Transaction.h"
#import "TransactionsController.h"

// The following values are used as contexts so that we can recognize the KVO notifications that we have requested.
static NSString *SpndTransactionsContext = @"com.apple.iSpend.transactions";
static NSString *SpndAmountContext = @"com.apple.iSpend.amount";
static NSString *SpndTypeContext = @"com.apple.iSpend.type";
static NSString *SpndAccountTypeContext = @"com.apple.iSpend.accountType";

@implementation MyDocument

- (id)init
{
    static BOOL registeredServices = NO;
    self = [super init];
    if (self) {
        // initialize categories and accountTypes with some predefined strings
        [self setCategories:[NSArray arrayWithObjects:@"Meals", @"Utilities", @"Mortgage", @"Gas", @"Insurance", nil]];
        [self setAccountTypes:[NSArray arrayWithObjects:@"Checking", @"Savings", @"Credit Card", @"Brokerage", @"Mutual Fund", @"Money Market", nil]];
        // we need to know when any transaction is added or removed so we can observe any changes to any amounts, again to keep the  balance up to date
        [self addObserver:self forKeyPath:@"transactions" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:SpndTransactionsContext];
        if (!registeredServices) {
            // register as service provider
            [NSApp setServicesProvider:[self class]];
            // register as service consumer
            [NSApp registerServicesMenuSendTypes:[self writablePasteboardTypes] returnTypes:[self readablePasteboardTypes]];
            registeredServices = YES;
        }
    }
    return self;
}

- (void)dealloc {
    [self stopObservingTransactions:_transactions];
    [_transactions release];
    _transactions = nil;
    [_categories release];
    _categories = nil;
    [_accountTypes release];
    _accountTypes = nil;
    [searchFieldOutlet release];
    [super dealloc];
}

- (void)windowControllerDidLoadNib:(NSWindowController *)windowController {
    // the searchField needs to be explicitly retained because it may be moved in and out of view hierarchies during toolbar customization.
    [searchFieldOutlet retain];
    // Set up the toolbar after the document nib has been loaded 
    [self setupToolbarForWindow:[windowController window]];
}

// balance accessors

- (double)balance {
    // current balance is the opening balance plus the sum of all the transaction amounts (which may be negative)
    double balance = _openingBalance;
    
    for (id loopItem in _transactions) {
        balance += [loopItem amount];
    }
    return balance;
}

- (void)setOpeningBalance:(double)balance {
    [[[self undoManager] prepareWithInvocationTarget:self] setOpeningBalance:_openingBalance];
    _openingBalance = balance;
}

// This method is automatically invoked from +keyPathsForValuesAffectingValueForKey:@"balance".  We return a set containing openingBalance and transactions so that the balance accessor (which computes the current balance) will be invoked whenever there is a change to the openingBalance or the transactions array.  This replaces the invocation of the deprecated method +setKeys:triggerChangeNotificationsForDependentKey:.
+ (NSSet *)keyPathsForValuesAffectingBalance {
    return [NSSet setWithObjects:@"openingBalance", @"transactions", nil];
}

// key value observing
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    // we'll be notified whenever there is a change to transactions, whether the array is replaced or an object is added or removed, because of the observing we set up in -init
    if (context == SpndTransactionsContext) {
        // set oldTransactions to the array of transactions that have been removed
        NSArray *oldTransactions = [change objectForKey:NSKeyValueChangeOldKey];
        if ([oldTransactions count] > 0) {
            // this change can be undone by adding oldTransactions back into the arrayController
            [[[self undoManager] prepareWithInvocationTarget:self] insertTransactions:oldTransactions atIndexes:[change objectForKey:NSKeyValueChangeIndexesKey]];
            [self stopObservingTransactions:oldTransactions];
        }
        // set newTransactions to the array of transactions that have been added
        NSArray *newTransactions = [change objectForKey:NSKeyValueChangeNewKey];
        if ([newTransactions count] > 0) {
            // this change can be undone by removing newTransactions from the arrayController
            [[self undoManager]  registerUndoWithTarget:self selector:@selector(removeTransactionsAtIndexes:) object:[change objectForKey:NSKeyValueChangeIndexesKey]];
            // set the document in each transaction so that the transaction can find our undoManager
            [newTransactions makeObjectsPerformSelector:@selector(setDocument:) withObject:self];
            [self startObservingTransactions:newTransactions];
        }
    }
    // observeValueForKeyPath... gets called with one of the below keyPaths ("amount", "type", or "accountType") when the value for that keyPath changes in a transaction, because of the observing we set up above
    else if (context == SpndAmountContext) {
        // the amount has changed in one of the transactions.  Cause balance to get updated
        [self willChangeValueForKey:@"balance"];
        [self didChangeValueForKey:@"balance"];
        
        
    } else if (context == SpndTypeContext) {
        //  the type has changed in one of the transactions.  If this is a type we haven't seen before, add it to _categories
        NSString *category = [object valueForKeyPath:@"type"];
        if (category != nil && ![category isEqualToString:@""] && ![_categories containsObject:category]) {
            [[self mutableArrayValueForKey:@"categories"] addObject:category];
        }
    } else if (context == SpndAccountTypeContext) {
        // the account type has changed in one of the transactions.  If this is an accountType we haven't seen before, add it to _accountTypes
        NSString *accountType = [object valueForKeyPath:@"accountType"];
        if (accountType != nil && ![accountType isEqualToString:@""] && ![_accountTypes containsObject:accountType]) {
            [[self mutableArrayValueForKey:@"accountTypes"] addObject:accountType];
        }
    } else {
        // the notification wasn't recognized, so it was probably meant for someone else.  Invoke super.
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

// -insertTransactions:atIndexes: is a key-value-coding compliant method so observers of _transactions will automatically be notified of the insertion
- (void)insertTransactions:(NSArray *)objects atIndexes:(NSIndexSet *)indexes {
    [_transactions insertObjects:objects atIndexes:indexes];
}

// -removeTransactionsAtIndexes: is a key-value-coding compliant method so observers of _transactions will automatically be notified of the removal
- (void)removeTransactionsAtIndexes:(NSIndexSet *)indexes {
    [_transactions removeObjectsAtIndexes:indexes];
}

- (void)startObservingTransactions:(NSArray *)newTransactions {
    NSIndexSet *allIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [newTransactions count])];
    // start observing "amount" in transactions that have been added so we can know when any amount changes
    // define a context so we can recognize the notification
    [newTransactions addObserver:self toObjectsAtIndexes:allIndexes forKeyPath:@"amount" options:0 context:SpndAmountContext];
    // start observing "type" so we can know when a new type is added
    [newTransactions addObserver:self toObjectsAtIndexes:allIndexes forKeyPath:@"type" options:0 context:SpndTypeContext];
    // start observing "accountType" so we can know when a new accountType is added
    [newTransactions addObserver:self toObjectsAtIndexes:allIndexes forKeyPath:@"accountType" options:0 context:SpndAccountTypeContext];
}

- (void)stopObservingTransactions:(NSArray *)oldTransactions {
    NSIndexSet *allIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [oldTransactions count])];
    // stop observing "amount" in transactions that have been removed
    [oldTransactions removeObserver:self fromObjectsAtIndexes:allIndexes forKeyPath:@"amount"];
    // stop observing "type"
    [oldTransactions removeObserver:self fromObjectsAtIndexes:allIndexes forKeyPath:@"type"];
    // stop observing "accountType"
    [oldTransactions removeObserver:self fromObjectsAtIndexes:allIndexes forKeyPath:@"accountType"];
}

// transaction accessors

- (NSArray *)transactions {
    // always return an array.   Create an empty one if need be, since it is incorrect to return nil from a collection accessor.
    if (!_transactions) {
        _transactions = [[NSMutableArray alloc] init];
    }
    return [[_transactions retain] autorelease];
}

- (void)setTransactions:(NSMutableArray *)transactions
{
    if (_transactions != transactions)
    {
        [_transactions release];
        _transactions = [transactions mutableCopy];
    }
}

// categories accessor
- (void)setCategories:(NSMutableArray *)categories
{
    if (_categories != categories)
    {
        [_categories release];
        _categories = [categories mutableCopy];
    }
}

// accountTypes accessor
- (void)setAccountTypes:(NSMutableArray *)accountTypes
{
    if (_accountTypes != accountTypes)
    {
        [_accountTypes release];
        _accountTypes = [accountTypes mutableCopy];
    }
}

// action methods
/* Note: In a more complicated application there could be more than one window per document.  In that case, these action methods would go in the custom window controller.  Then, this NSDocument subclass would not even need a connection to the array controller.
*/
- (void)add:(id)sender {
    [_transactionController add:sender];    
}

- (void)delete:(id)sender {
    [_transactionController remove:sender];    
}

// saving and opening documents
#define kOpeningBalance @"Opening Balance"
#define kTransactions @"Transactions"
#define kAccountTypes @"AccountTypes"
#define kCategories @"Categories"

- (NSString *)windowNibName
{
    return @"MyDocument";
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    if ([typeName isEqualToString:kSpendDocumentType]) {
        NSData *data;
        NSMutableDictionary *doc = [NSMutableDictionary dictionary];
        NSString *errorString;
        [doc setObject:[NSNumber numberWithDouble:_openingBalance] forKey:kOpeningBalance];
        [doc setObject:[NSKeyedArchiver archivedDataWithRootObject:_transactions] forKey:kTransactions];
        [doc setObject:[NSKeyedArchiver archivedDataWithRootObject:_categories] forKey:kCategories];
        [doc setObject:[NSKeyedArchiver archivedDataWithRootObject:_accountTypes] forKey:kAccountTypes];
        data = [NSPropertyListSerialization dataFromPropertyList:doc format:NSPropertyListXMLFormat_v1_0 errorDescription:&errorString];
        if (!data) {
            if (!outError) {
                NSLog(@"dataFromPropertyList failed with %@", errorString);
            } else {
                NSDictionary *errorUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"iSpend document couldn't be written", NSLocalizedDescriptionKey, (errorString ? errorString : @"An unknown error occured."), NSLocalizedFailureReasonErrorKey, nil];

                // In this simple example we know that no one's going to be paying attention to the domain and code that we use here.
                *outError = [NSError errorWithDomain:@"iSpendErrorDomain" code:-1 userInfo:errorUserInfo];
            }
            [errorString release];

        }
        return data;
    } else {
        if (outError) *outError = [NSError errorWithDomain:@"iSpendErrorDomain" code:-1 userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Unsupported data type: %@", typeName] forKey:NSLocalizedFailureReasonErrorKey]];
    }
    return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    BOOL result = NO;
    // we only recognize one data type.  It is a programming error to call this method with any other typeName
    assert([typeName isEqualToString:kSpendDocumentType]); 
    
    NSString *errorString;
    NSDictionary *documentDictionary = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:&errorString];

    if (documentDictionary) {                                           
        [self setOpeningBalance:[[documentDictionary objectForKey:kOpeningBalance] doubleValue]];
        [self setTransactions:[NSKeyedUnarchiver unarchiveObjectWithData:[documentDictionary objectForKey:kTransactions]]];
        [self setCategories:[NSKeyedUnarchiver unarchiveObjectWithData:[documentDictionary objectForKey:kCategories]]];
        [self setAccountTypes:[NSKeyedUnarchiver unarchiveObjectWithData:[documentDictionary objectForKey:kAccountTypes]]];
        result = YES;
    } else {
        if (!outError) {
            NSLog(@"propertyListFromData failed with %@", errorString);
        } else {
            NSDictionary *errorUserInfo = [NSDictionary dictionaryWithObjectsAndKeys: @"iSpend document couldn't be read", NSLocalizedDescriptionKey, (errorString ? errorString : @"An unknown error occured."), NSLocalizedFailureReasonErrorKey, nil];

            *outError = [NSError errorWithDomain:@"iSpendErrorDomain" code:-1 userInfo:errorUserInfo];
        }
        [errorString release];
        result = NO;
    }
    // we don't want any of the operations involved in loading the new document to mark it as dirty, nor should they be undo-able, so clear the undo stack
    [[self undoManager] removeAllActions];
    return result;
}

@end
