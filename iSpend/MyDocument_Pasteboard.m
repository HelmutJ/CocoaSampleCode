/*
     File: MyDocument_Pasteboard.m
 Abstract: This category reads and writes data from the pasteboard to support copy/paste and dragging.
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

#import "MyDocument_Pasteboard.h"
#import "Transaction.h"

@implementation MyDocument(Pasteboard)

/* Formatting methods in support of writing to the pasteboard */

- (NSString *)stringFromTransactions:(NSArray *)transactions {
    // When we are writing out NSStringPboardType, we create a string with one line per transaction and tabs between items in the transaction
    NSMutableString *result = [NSMutableString string];
    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    for (Transaction *transaction in transactions) {
        NSString *descriptionString = transaction.descriptionString, *type = transaction.type, *accountType = transaction.accountType;
        [result appendFormat:@"%@\t%.2f\t%@\t%@\t%@\n", [dateFormatter stringFromDate:transaction.date], transaction.amount, (descriptionString ? descriptionString : @""), (type ? type : @""), (accountType ? accountType : @"")];
    }
    return result;
}

- (void)addCell:(NSString *)contents table:(NSTextTable *)table row:(NSInteger)row column:(NSInteger)col alignment:(NSTextAlignment)alignment toText:(NSMutableAttributedString *)text {
    // This is an auxiliary method to append a new cell to the attributed string we are creating in the following method
    NSUInteger textLength = [text length];
    NSTextTableBlock *block = [[NSTextTableBlock alloc] initWithTable:table startingRow:row rowSpan:1 startingColumn:col columnSpan:1];
    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    
    [block setWidth:1.0f type:NSTextBlockAbsoluteValueType forLayer:NSTextBlockBorder];
    [block setWidth:5.0f type:NSTextBlockAbsoluteValueType forLayer:NSTextBlockPadding edge:NSMinXEdge];
    [block setWidth:5.0f type:NSTextBlockAbsoluteValueType forLayer:NSTextBlockPadding edge:NSMaxXEdge];
    [block setVerticalAlignment:NSTextBlockMiddleAlignment];
    [block setBorderColor:[NSColor colorWithCalibratedWhite:0.75f alpha:1.0f]];
    [style setTextBlocks:[NSArray arrayWithObject:block]];
    [style setAlignment:alignment];
    [text replaceCharactersInRange:NSMakeRange(textLength, 0) withString:[NSString stringWithFormat:@"%@\n", (contents ? contents : @"")]];
    [text addAttribute:NSParagraphStyleAttributeName value:style range:NSMakeRange(textLength, [text length] - textLength)];
    [style release];
    [block release];
}

- (NSAttributedString *)attributedStringFromTransactions:(NSArray *)transactions {
    // When we are writing out NSRTFPboardType, we create a table with one row per transaction and one cell per item in the transaction
    NSMutableAttributedString *result = [[[NSMutableAttributedString alloc] initWithString:@"\n"] autorelease];
    NSAttributedString *returnString = [[[NSAttributedString alloc] initWithString:@"\n"] autorelease];
    NSUInteger i, count = [transactions count];
    Transaction *transaction;
    NSTextTable *table = [[[NSTextTable alloc] init] autorelease];
    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [table setNumberOfColumns:5];
    [table setLayoutAlgorithm:NSTextTableAutomaticLayoutAlgorithm];
    [table setCollapsesBorders:YES];
    [table setHidesEmptyCells:NO];
    for (i = 0; i < count; i++) {
        transaction = [transactions objectAtIndex:i];
        [self addCell:[dateFormatter stringFromDate:transaction.date] table:table row:i column:0 alignment:NSLeftTextAlignment toText:result];
        [self addCell:[NSString stringWithFormat:@"%.2f", transaction.amount] table:table row:i column:1 alignment:NSRightTextAlignment toText:result];
        [self addCell:transaction.descriptionString table:table row:i column:2 alignment:NSLeftTextAlignment toText:result];
        [self addCell:transaction.type table:table row:i column:3 alignment:NSLeftTextAlignment toText:result];
        [self addCell:transaction.accountType table:table row:i column:4 alignment:NSLeftTextAlignment toText:result];
    }
    [result appendAttributedString:returnString];
    return result;
}


/* Methods for writing to the pasteboard */

- (NSArray *)writablePasteboardTypes {
    return [NSArray arrayWithObjects:kSpendDocumentType, NSFilesPromisePboardType, NSFilenamesPboardType, NSRTFPboardType, NSStringPboardType, nil];
}

- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pboard types:(NSArray *)types {
    BOOL result = NO;
    NSMutableArray *typesToDeclare = [NSMutableArray array];
    NSArray *writableTypes = [self writablePasteboardTypes];
    NSString *type;
    
    for (type in writableTypes) {
        if ([types containsObject:type]) [typesToDeclare addObject:type];
    }
    if ([typesToDeclare count] > 0) {
        [pboard declareTypes:typesToDeclare owner:self];
        for (type in typesToDeclare) {
            if ([self writeSelectionToPasteboard:pboard type:type]) result = YES;
        }
    }
    return result;
}
    
- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pboard type:(NSString *)type {
    BOOL result = NO;
    NSArray *transactions = [_transactionController selectedObjects];
    if (transactions && [transactions count] > 0) {
        if ([type isEqualToString:kSpendDocumentType]) {
            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:transactions];
            if (data && [data length] > 0) result = [pboard setData:data forType:kSpendDocumentType];
        } else if ([type isEqualToString:NSFilesPromisePboardType]) {
            result = [pboard setPropertyList:[NSArray arrayWithObject:kSpendExtension] forType:NSFilesPromisePboardType];
        } else if ([type isEqualToString:NSFilenamesPboardType]) {
            // we do not have a file already in existence, so we wish to handle this type lazily to delay file creation until actually requested
            result = YES;
        } else if ([type isEqualToString:NSRTFPboardType]) {
            NSAttributedString *attrStr = [self attributedStringFromTransactions:transactions];
            if (attrStr && [attrStr length] > 0) result = [pboard setData:[attrStr RTFFromRange:NSMakeRange(0, [attrStr length]) documentAttributes:nil] forType:NSRTFPboardType];
        } else if ([type isEqualToString:NSStringPboardType]) {
            NSString *string = [self stringFromTransactions:transactions];
            if (string && [string length] > 0) result = [pboard setString:string forType:NSStringPboardType];
        }
    }
    return result;
}

- (NSURL *)writeSelectionToDestination:(NSURL *)destination {
    // This is the method that we call when our file promise is being redeemed
    // We write out a file to the directory specified, and return the file's URL (or nil in case of failure)
    NSArray *transactions = [_transactionController selectedObjects];
    NSIndexSet *indexSet = [_transactionController selectionIndexes];
    NSString *name = [NSString stringWithFormat:@"iSpend[%ld..%ld].%@", (long)[indexSet firstIndex], (long)[indexSet lastIndex], kSpendExtension], *path = [[destination path] stringByAppendingPathComponent:name];
    NSURL *fileURL = [NSURL fileURLWithPath:path];
    NSDocumentController *controller = [NSDocumentController sharedDocumentController];
    NSError *error = nil;
    MyDocument *newDocument = [controller openUntitledDocumentAndDisplay:NO error:&error];
    BOOL succeeded = NO;
    
    if (newDocument) {
        [newDocument setTransactions:[NSArray arrayWithArray:transactions]];
        if ([newDocument writeToURL:fileURL ofType:kSpendDocumentType error:&error]) succeeded = YES;
        [controller removeDocument:newDocument];
    }
    return (succeeded ? fileURL : nil);
}

- (void)pasteboard:(NSPasteboard *)pboard provideDataForType:(NSString *)type {
    // We expect that -tableView:namesOfPromisedFilesDroppedAtDestination:forDraggedRowsWithIndexes: will usually be called instead,
    // but we implement this method to create a file if NSFilenamesPboardType is ever requested directly
    if ([type isEqualToString:NSFilenamesPboardType]) {
        NSURL *fileURL = [self writeSelectionToDestination:[NSURL fileURLWithPath:NSTemporaryDirectory()]];
        if (fileURL) [pboard setPropertyList:[NSArray arrayWithObject:[fileURL path]] forType:NSFilenamesPboardType];
    }
}

- (void)copy:(id)sender {
    [self writeSelectionToPasteboard:[NSPasteboard generalPasteboard] types:[self writablePasteboardTypes]];
}


/* Parsing methods in support of reading from the pasteboard */

- (BOOL)addTransactionsFromString:(NSString *)string {
    // If we are reading in NSStringPboardType, we parse the string into lines and create a transaction per line
    BOOL result = NO;
    NSUInteger length = [string length], location = 0;
    NSRange lineRange;
    Transaction *transaction;
    
    while (location < length) {
        lineRange = [string lineRangeForRange:NSMakeRange(location, 1)];
        transaction = [[Transaction alloc] initWithString:[string substringWithRange:lineRange]];
        if (transaction) {
            [_transactionController addObject:transaction];
            [transaction release];
            result = YES;
        }
        location = NSMaxRange(lineRange);
    }
    return result;
}

- (BOOL)addTransactionsFromAttributedString:(NSAttributedString *)attributedString {
    // If we are reading in NSRTFPboardType, we parse the string into lines and create a transaction per line,
    // unless there is a table present, in which case we parse the string into table rows and create a transaction per row
    BOOL result = NO;
    NSString *string = [attributedString string];
    NSUInteger length = [string length], location = 0, rowLocation;
    NSRange lineRange, tableRange, blockRange;
    NSArray *textBlocks;
    NSTextTableBlock *block, *nextBlock;
    NSTextTable *table;
    Transaction *transaction;
    
    while (location < length) {
        lineRange = [string lineRangeForRange:NSMakeRange(location, 1)];
        textBlocks = [[attributedString attribute:NSParagraphStyleAttributeName atIndex:location effectiveRange:NULL] textBlocks];
        table = nil;
        if (textBlocks && [textBlocks count] > 0) {
            block = [textBlocks objectAtIndex:0];
            if ([block isKindOfClass:[NSTextTableBlock class]]) table = [block table];
        }
        if (table) {
            // If a table is present, parse it into rows
            tableRange = [attributedString rangeOfTextTable:table atIndex:location];
            rowLocation = location;
            while (location < NSMaxRange(tableRange)) {
                // Go through the table by cells, looking for row boundaries
                block = [[[attributedString attribute:NSParagraphStyleAttributeName atIndex:location effectiveRange:NULL] textBlocks] objectAtIndex:0];
                blockRange = [attributedString rangeOfTextBlock:block atIndex:location];
                nextBlock = (NSMaxRange(blockRange) < NSMaxRange(tableRange)) ? [[[attributedString attribute:NSParagraphStyleAttributeName atIndex:NSMaxRange(blockRange) effectiveRange:NULL] textBlocks] objectAtIndex:0] : nil;
                if (!nextBlock || [nextBlock startingRow] != [block startingRow]) {
                    // This is the last cell in a row
                    transaction = [[Transaction alloc] initWithString:[string substringWithRange:NSMakeRange(rowLocation, NSMaxRange(blockRange) - rowLocation)]];
                    if (transaction) {
                        [_transactionController addObject:transaction];
                        [transaction release];
                        result = YES;
                    }
                    rowLocation = NSMaxRange(blockRange);
                }
                location = NSMaxRange(blockRange);
            }
        } else {
            // If no table is present, create a transaction per line as in the string case
            transaction = [[Transaction alloc] initWithString:[string substringWithRange:lineRange]];
            if (transaction) {
                [_transactionController addObject:transaction];
                [transaction release];
                result = YES;
            }
            location = NSMaxRange(lineRange);
        }
    }
    return result;
}

- (BOOL)addTransactionsFromPasteboardData:(NSData *)data {
    // If we are reading in our custom pasteboard type, we use NSKeyedUnarchiver
    BOOL result = NO;
    NSArray *array = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    if (array && [array isKindOfClass:[NSArray class]]) {
        [_transactionController addObjects:array];
        result = YES;
    }
    return result;
}

- (BOOL)addTransactionsFromFileData:(NSData *)data {
    // If we are reading in our custom file type, we create a new document and extract its transactions
    BOOL result = NO;
    NSDocumentController *controller = [NSDocumentController sharedDocumentController];
    NSError *error = nil;
    MyDocument *newDocument = [controller openUntitledDocumentAndDisplay:NO error:&error];
    
    if (newDocument) {
        if ([newDocument readFromData:data ofType:kSpendDocumentType error:&error]) {
            [_transactionController addObjects:[newDocument transactions]];
            result = YES;
        }
        [controller removeDocument:newDocument];
    }
    return result;
}


/* Methods for reading from the pasteboard */

- (NSArray *)readablePasteboardTypes {
    return [NSArray arrayWithObjects:kSpendDocumentType, NSFilenamesPboardType, NSRTFPboardType, NSStringPboardType, nil];
}

- (BOOL)readSelectionFromPasteboard:(NSPasteboard *)pboard {
    // We go through the available types in our preferred order, and return after the first one that succeeds
    BOOL result = NO;
    NSArray *availableTypes = [pboard types], *readableTypes = [self readablePasteboardTypes];
    NSEnumerator *enumerator = [readableTypes objectEnumerator];
    NSString *type;
    
    while (!result && (type = [enumerator nextObject])) {
        if ([availableTypes containsObject:type]) {
            result = [self readSelectionFromPasteboard:pboard type:type];
        }
    }
    return result;
}

- (BOOL)readSelectionFromPasteboard:(NSPasteboard *)pboard type:(NSString *)type {
    BOOL result = NO;
    if ([type isEqualToString:kSpendDocumentType]) {
        NSData *data = [pboard dataForType:kSpendDocumentType];
        if (data && [data length] > 0) result = [self addTransactionsFromPasteboardData:data];
    } else if ([type isEqualToString:NSFilenamesPboardType]) {
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        for (NSString *filePath in files) { 
            if ([[filePath pathExtension] isEqualToString:kSpendExtension]) {
                // This is a file of our custom type
                NSData *data = [NSData dataWithContentsOfFile:filePath];
                if (data && [data length] > 0 && [self addTransactionsFromFileData:data]) result = YES;
            } else {
                // Treat the file as a text file
                NSAttributedString *attrStr = [[[NSAttributedString alloc] initWithPath:filePath documentAttributes:nil] autorelease];
                if (attrStr && [attrStr length] > 0 && [self addTransactionsFromAttributedString:attrStr]) result = YES;
            }
        }
    } else if ([type isEqualToString:NSRTFPboardType]) {
        NSData *data = [pboard dataForType:NSRTFPboardType];
        NSAttributedString *attrStr = [[[NSAttributedString alloc] initWithRTF:data documentAttributes:NULL] autorelease];
        if (attrStr && [attrStr length] > 0) result = [self addTransactionsFromAttributedString:attrStr];
    } else if ([type isEqualToString:NSStringPboardType]) {
        NSString *string = [pboard stringForType:NSStringPboardType];
        if (string && [string length] > 0) result = [self addTransactionsFromString:string];
    }
    return result;
}

- (void)paste:(id)sender {
    [self readSelectionFromPasteboard:[NSPasteboard generalPasteboard]];
}


/* Method for enabling services use */

- (id)validRequestorForSendType:(NSString *)sendType returnType:(NSString *)returnType {
    if ((!sendType || [[self writablePasteboardTypes] containsObject:sendType]) && (!returnType || [[self readablePasteboardTypes] containsObject:returnType]) && (!sendType || [[_transactionController selectedObjects] count] > 0)) return self;
    // We are not actually a subclass of NSResponder; if we were, we would pass this on to super.
    // In this particular application, we know that no responder above the document level handles copy/paste; if there were one, we would pass this on to it.
    return nil;
}


/* Methods for providing services */

+ (void)importData:(NSPasteboard *)pboard userData:(NSString *)data error:(NSString **)error {
    // -[NSWindowController currentDocument] works only when app is active, so we use this alternative means of finding the front document
    MyDocument *document = [[[NSApp makeWindowsPerform:@selector(windowController) inOrder:YES] windowController] document];
    if (document) [document readSelectionFromPasteboard:pboard];
}

+ (void)exportData:(NSPasteboard *)pboard userData:(NSString *)data error:(NSString **)error {
    MyDocument *document = [[[NSApp makeWindowsPerform:@selector(windowController) inOrder:YES] windowController] document];
    if (document) [document writeSelectionToPasteboard:pboard types:[document writablePasteboardTypes]];
}

@end
