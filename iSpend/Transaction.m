/*
     File: Transaction.m
 Abstract: This class manages the individual transactions in the document. It uses bindings to show transactions in a master-detail view.
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

#import "Transaction.h"

@implementation Transaction

- (id)init {
    if (self = [super init]) {
        self.date = [NSDate date];
    }
    return self;
}

- (id)initWithString:(NSString *)string {
    if(!(self = [super init])) return nil;

    NSArray *stringComponents;
    NSString *substring;
    NSScanner *scanner;
    float substringVal;
    BOOL foundDate = NO, foundAmount = NO, foundDescription = NO, foundType = NO, foundAccountType = NO;
    NSCharacterSet *skipSet = [NSCharacterSet characterSetWithCharactersInString:@" \n\t,\""];
    stringComponents = [string componentsSeparatedByString:@"\n"];
    if ([stringComponents count] < 3) stringComponents = [string componentsSeparatedByString:@"\t"];
    if ([stringComponents count] < 3) stringComponents = [string componentsSeparatedByString:@","];
    for (substring in stringComponents) {
        substring = [substring stringByTrimmingCharactersInSet:skipSet];
        scanner = [NSScanner scannerWithString:substring];
        [scanner scanFloat:&substringVal];
	if (!foundDate && [substring rangeOfString:@"/"].length != 0) {
	    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
	    NSRange range = NSMakeRange(0,[substring length]);
            NSDate *readDate;
	    NSError *error;
	    [dateFormatter getObjectValue:&readDate forString:substring range:&range error:&error];
	    [dateFormatter release];
	    self.date = readDate;
	    foundDate = YES;
	} else if (!foundAmount && [scanner isAtEnd]) {
	    self.amount = substringVal;
	    foundAmount = YES;
	} else if ([substring length] > 1) {
            if (!foundDescription) {
                self.descriptionString = substring;
                foundDescription = YES;
            } else if (!foundType) {
                self.type = substring;
                foundType = YES;
            } else if (!foundAccountType) {
                self.accountType = substring;
                foundAccountType = YES;
            }
        }
    }
    if (!foundDate || !foundAmount) {
        [self release];
        self = nil;
    }
    return self;
}

- (void)dealloc {
    // First, set the "document" property to nil.  Since this is how the undo manager is referenced, setting it to nil will prevent the following from causing spurious undo registrations.  Note that in -dealloc we are manipulating the underying instance variables directly, because invoking setters can cause side-effects, and getters can return copies.
    _document = nil;
    
    [_date release];
    [_purchaseDate release];
    [_type release];
    [_descriptionString release];
    [_accountType release];
    
    [super dealloc];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ %f %@", self.date, self.amount, self.descriptionString ? self.descriptionString : @""];
}

#define kDate @"Date"
#define kPurchaseDate @"PurchaseDate"
#define kAmount @"Amount"
#define kDescription @"Description"
#define kCategory @"Category"
#define kAccountType @"AccountType"
#define kTaxable @"Taxable"
#define kStockTransaction @"StockTransaction"
#define kPurchasePrice @"PurchasePrice"
#define kSalePrice @"SalePrice"
#define kNumberShares @"NumberShares"
#define kCostBasis @"CostBasis"
#define kSaleAmount @"SaleAmount"

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.date forKey:kDate];
    [coder encodeDouble:self.amount forKey:kAmount];
    if (self.descriptionString) {
        [coder encodeObject:self.descriptionString forKey:kDescription];
    } 
    if (self.type) {
        [coder encodeObject:self.type forKey:kCategory];
    }
    if (self.accountType) {
        [coder encodeObject:self.accountType forKey:kAccountType];
    }
    if (self.taxable) {
        [coder encodeBool:self.taxable forKey:kTaxable];
    }
    if (self.stockTransaction) {
        [coder encodeBool:YES forKey:kStockTransaction];
        [coder encodeDouble:self.purchasePrice forKey:kPurchasePrice];
        [coder encodeDouble:self.salePrice forKey:kSalePrice];
        [coder encodeDouble:self.numberShares forKey:kNumberShares];
        [coder encodeObject:self.purchaseDate forKey:kPurchaseDate];
        if (_costBasis) [coder encodeDouble:self.costBasis forKey:kCostBasis];
        if (_saleAmount) [coder encodeDouble:self.saleAmount forKey:kSaleAmount];
    }
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self.date = [aDecoder decodeObjectForKey:kDate];
    self.amount = [aDecoder decodeDoubleForKey:kAmount];
    self.descriptionString = [aDecoder decodeObjectForKey:kDescription];
    self.type = [aDecoder decodeObjectForKey:kCategory];
    self.accountType = [aDecoder decodeObjectForKey:kAccountType];
    self.taxable = [aDecoder decodeBoolForKey:kTaxable];
    if ([aDecoder decodeBoolForKey:kStockTransaction]) {
        self.stockTransaction = YES;
        self.purchasePrice = [aDecoder decodeDoubleForKey:kPurchasePrice];
        self.salePrice = [aDecoder decodeDoubleForKey:kSalePrice];
        self.numberShares = [aDecoder decodeDoubleForKey:kNumberShares];
        self.costBasis = [aDecoder decodeDoubleForKey:kCostBasis];
        self.saleAmount = [aDecoder decodeDoubleForKey:kSaleAmount];
        self.purchaseDate = [aDecoder decodeObjectForKey:kPurchaseDate];
    }
    return self;
}

// Accessor Methods

// amount is computed from purchasePrice, salePrice, numberShares, costBasis, and saleAmount.  This method is invoked automatically from keyPathsForValuesAffectingValueForKey:@"amount".

@synthesize document = _document;

+ (NSSet *)keyPathsForValuesAffectingAmount {
    return [NSSet setWithObjects:@"purchasePrice", @"salePrice", @"numberShares", @"costBasis", @"saleAmount", nil];
}

- (double)amount {
    if (_amount == 0 && self.stockTransaction) {
        return self.saleAmount - self.costBasis;
    }
    return _amount;
}

- (void)setAmount:(double)value {
    [[self.undoManager prepareWithInvocationTarget:self] setAmount:_amount];
    _amount = value;
}

- (void)setDate:(NSDate *)value {
    if (_date != value) {
        [self.undoManager registerUndoWithTarget:self selector:@selector(setDate:) object:_date];
        [_date release];
        _date = [value retain];
    }
}

- (NSDate *)date { 
    return [[_date retain] autorelease]; 
}

- (void)setPurchaseDate:(NSDate *)value {
    if (_purchaseDate != value) {
        [self.undoManager registerUndoWithTarget:self selector:@selector(setPurchaseDate:) object:_purchaseDate];
        [_purchaseDate release];
        _purchaseDate = [value retain];
    }
}

- (NSDate *)purchaseDate { 
    return [[_purchaseDate retain] autorelease]; 
}

- (void)setDescriptionString:(NSString *)value {
    if (_descriptionString != value) {
        [self.undoManager registerUndoWithTarget:self selector:@selector(setDescriptionString:) object:_descriptionString];
        [_descriptionString release];
        _descriptionString = [value copy];
    }
}

- (NSString *)descriptionString { 
    return [[_descriptionString retain] autorelease]; 
}

- (void)setType:(NSString *)value {
    if (_type != value) {
        [self.undoManager registerUndoWithTarget:self selector:@selector(setType:) object:_type];
        [_type release];
        _type = [value copy];
    }
}

- (NSString *)type { 
    return [[_type retain] autorelease]; 
}

- (void)setAccountType:(NSString *)value {
    if (_accountType != value) {
        [self.undoManager registerUndoWithTarget:self selector:@selector(setAccountType:) object:_accountType];
        [_accountType release];
        _accountType = [value copy];
    }
}

- (NSString *)accountType { 
    return [[_accountType retain] autorelease]; 
}

- (void)setTaxable:(BOOL)flag {
    [[self.undoManager prepareWithInvocationTarget:self] setTaxable:_taxable];
    _taxable = flag;
}

- (BOOL)taxable { 
    return _taxable; 
}

- (void)setStockTransaction:(BOOL)flag {
    [[self.undoManager prepareWithInvocationTarget:self] setStockTransaction:_stockTransaction];
    _stockTransaction = flag;
}

- (BOOL)stockTransaction { 
    return _stockTransaction; 
}

- (void)setPurchasePrice:(double)value {
    [[self.undoManager prepareWithInvocationTarget:self] setPurchasePrice:_purchasePrice];
    _purchasePrice = value;
}

- (double)purchasePrice { 
    return _purchasePrice; 
}

- (void)setSalePrice:(double)value {
    [[self.undoManager prepareWithInvocationTarget:self] setSalePrice:_salePrice];
    _salePrice = value;
}

- (double)salePrice { 
    return _salePrice; 
}

- (void)setNumberShares:(double)value {
    [[self.undoManager prepareWithInvocationTarget:self] setNumberShares:_numberShares];
    _numberShares = value;
}

- (double)numberShares { 
    return _numberShares; 
}

// costBasis is computed from purchasePrice and numberShares.  This method is invoked automatically from keyPathsForValuesAffectingValueForKey:@"costBasis".
+ (NSSet *)keyPathsForValuesAffectingCostBasis {
    return [NSSet setWithObjects:@"purchasePrice", @"numberShares", nil];
}

- (double)costBasis {
    if (_costBasis != 0) { 
        return _costBasis;
    } else {
        return self.purchasePrice * self.numberShares;
    }
} 

- (void)setCostBasis:(double)value {
    [[self.undoManager prepareWithInvocationTarget:self] setCostBasis:_costBasis];
    _costBasis = value;
}

// saleAmount is computed from salePrice and numberShares.  This method is invoked automatically from keyPathsForValuesAffectingValueForKey:@"saleAmount".
+ (NSSet *)keyPathsForValuesAffectingSaleAmount {
    return [NSSet setWithObjects:@"salePrice", @"numberShares", nil];
}

- (double)saleAmount {
    if (_saleAmount != 0) {
        return _saleAmount;
    } else {
        return self.salePrice * self.numberShares;
    }
}

- (void)setSaleAmount:(double)value {
    [[self.undoManager prepareWithInvocationTarget:self] setSaleAmount:_saleAmount];
    _saleAmount = value;
}

- (NSUndoManager *)undoManager {
    return [self.document undoManager];
}

@end
