/*
     File: CDInfoDocument.m
 Abstract: Document and Combo Box Controller Object.
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


#import "CDInfoDocument.h"

#define CDINFO_DOCUMENT_TYPE 	@"cdinfo document type"
#define INDEX_CD_TITLE  	0
#define INDEX_BAND_NAME    	1
#define INDEX_MUSIC_GENRE  	2

@implementation CDInfoDocument

- (void)dealloc {
    [initEditString release];
    [genres release];
    [dataFromFile release];
    initEditString = nil;
    genres = nil;
    dataFromFile = nil;
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [super dealloc];
}

// ==========================================================
// Undo related methods
// ==========================================================

- (NSString *)undoActionNameForCell:(NSCell *)cell {
    // Returns the string we want to be displayed in the "Undo"/"Redo" menu item (under Edit->)
    if (cell==cdTitleCell || cell==bandNameCell) return [[cell title] substringToIndex: [[cell title] length] - 1];
    else return @"Genre";
}

- (void)cellTextDidBeginEditing:(NSNotification *)notif {
    // Take a snapshot of the cell being edited so we'll know if it has actually changed when cellTextDidBeginEditing: is received.
    NSText *fieldEditor = [[notif userInfo] objectForKey: @"NSFieldEditor"];
    initEditString = [[fieldEditor string] copy];
}

- (void)cellTextDidEndEditing:(NSNotification *)notif {
    // Check to see if the string valueof the edited cell has changed.  If so add an action to the undo stack (this will dirty the doc.)
    NSText *fieldEditor = [[notif userInfo] objectForKey: @"NSFieldEditor"];
    NSString *endEditString = [fieldEditor string];
    
    // Just in case, do some sanity checks.
    if (!initEditString) initEditString = [@"" retain];
    if (!endEditString) endEditString = @"";
    
    if (initEditString!=endEditString && ![endEditString isEqualToString: initEditString]) {
	NSCell *editedCell = [[notif object] selectedCell]; 	
	NSArray *undoInfo = [NSArray arrayWithObjects: editedCell, initEditString, nil];
	[[self undoManager] registerUndoWithTarget: self selector:@selector(applyCellUndo:) object: undoInfo];
	[[self undoManager] setActionName: [self undoActionNameForCell: editedCell]];
    }
    [initEditString release];
    initEditString = nil;
}

- (void)applyCellUndo:(NSArray *)undoInfo {
    // Apply the specified undo, and register another undo, which will have the effect of resetting us to the current state (ie. redo the undo)
    NSCell 	*affectedCell = [undoInfo objectAtIndex:0];
    NSString 	*newString = [undoInfo objectAtIndex:1];
    [[self undoManager] registerUndoWithTarget: self selector:@selector(applyCellUndo:) object: [NSArray arrayWithObjects:affectedCell,[affectedCell stringValue],nil]];
    [affectedCell setStringValue: newString];
}

// ==========================================================
// Standard NSDocument methods
// ==========================================================

- (NSString *)windowNibName {
    return @"CDInfoDocument";
}

- (void)loadDocumentWithInitialData {
    // Decode data we previously archived.  Format is an array of strings followed by text storage for the text view.
    NSUnarchiver *unarchiver = [[[NSUnarchiver alloc] initForReadingWithData: dataFromFile] autorelease];
    NSArray *archivedFormCellStrings = [unarchiver decodeObject];
    NSTextStorage *archivedTextStorage = [unarchiver decodeObject];
    
    // Populate the text fields, and text view with data that was unarchived.
    if ([archivedTextStorage length]) [infoTextView insertText: archivedTextStorage];
    [self setCDTitle: [archivedFormCellStrings objectAtIndex:INDEX_CD_TITLE]];
    [self setBandName: [archivedFormCellStrings objectAtIndex: INDEX_BAND_NAME]];
    [self setMusicGenre: [archivedFormCellStrings objectAtIndex: INDEX_MUSIC_GENRE]];
    
    // Make sure the document doesn't think it is dirty.  Calling insertText: above could have made the doc think it was dirty.
    [[self undoManager] removeAllActions];
    
    [dataFromFile release];
    dataFromFile = nil;
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController {
    [super windowControllerDidLoadNib:aController];
    
    [[genreComboBox window] setFrameAutosaveName:@"MainWindow"];
    [[genreComboBox window] setFrameUsingName: @"MainWindow"];
    
    // Get a reference to the combo box cell just for uniformity through out (we deal with cells, and not their controls everywhere).
    genreComboBoxCell = [genreComboBox cell];
    
    // Load in some standard genres.  Note a real implementation would probably move "genres" into a object that could be shared
    // to reduce memory usage and provide the ability to share changes or additions to this list (if that were implemented).
    genres = [NSArray arrayWithObjects:  @"Jazz", @"Acid", @"Funk" , @"Classic Rock", @"Rock", @"Pop" , @"R&B" , @"Hip Hop" , @"Trip Hop" , @"Classical" , @"Swing" , @"Metal" , @"Country" , @"Folk", @"Grunge", @"Alternative", nil];
    genres = [[genres sortedArrayUsingSelector:@selector(compare:)] retain];
    
    // Tell NSNotificationCenter we want to know when are cells start and stop editing (So we can set up undo operations for the text fields at an appropriate level).
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(cellTextDidBeginEditing:) name: NSControlTextDidBeginEditingNotification object: infoForm];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(cellTextDidEndEditing:) name: NSControlTextDidEndEditingNotification object: infoForm];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(cellTextDidBeginEditing:) name: NSControlTextDidBeginEditingNotification object: genreComboBox];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(cellTextDidEndEditing:) name: NSControlTextDidEndEditingNotification object: genreComboBox];
    
    // Do the standard thing of loading in data we may have gotten if loadDataRepresentation: was used previously.
    if (dataFromFile) [self loadDocumentWithInitialData];
}

- (NSData *)dataRepresentationOfType:(NSString *)aType {
    // Archive data in the format loadDocumentWithInitialData expects.
    NSMutableData *data = nil;
    if ([aType isEqualToString: CDINFO_DOCUMENT_TYPE]) {
	NSArray *formCellStrings = [NSArray arrayWithObjects: [self cdTitle], [self bandName], [self musicGenre], nil];
	NSArchiver *archiver = [[[NSArchiver alloc] initForWritingWithMutableData: [NSMutableData data]] autorelease];
	[archiver encodeObject: formCellStrings];
	[archiver encodeObject: [infoTextView textStorage]];
	data = [archiver archiverData];
    }
    return data;
}

- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)aType {
    if ([aType isEqualToString: CDINFO_DOCUMENT_TYPE]) {
	dataFromFile = [data retain];
	return YES;
    }
    return NO;
}

// ==========================================================
// Combo box data source methods
// ==========================================================

- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox {
    return [genres count];
}
- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)loc {
    return [genres objectAtIndex:loc];
}
- (NSUInteger)comboBox:(NSComboBox *)aComboBox indexOfItemWithStringValue:(NSString *)string {
    return [genres indexOfObject: string];
}

- (NSString *) firstGenreMatchingPrefix:(NSString *)prefix {
    NSString *string = nil;
    NSString *lowercasePrefix = [prefix lowercaseString];
    NSEnumerator *stringEnum = [genres objectEnumerator];
    while ((string = [stringEnum nextObject])) {
	if ([[string lowercaseString] hasPrefix: lowercasePrefix]) return string;
    }
    return nil;
}

- (NSString *)comboBox:(NSComboBox *)aComboBox completedString:(NSString *)inputString {
    // This method is received after each character typed by the user, because we have checked the "completes" flag for genreComboBox in IB.
    // Given the inputString the user has typed, see if we can find a genre with the prefix, and return it as the suggested complete string.
    NSString *candidate = [self firstGenreMatchingPrefix: inputString];
    return (candidate ? candidate : inputString);
}

// ==========================================================
// Some access methods
// ==========================================================

- (void)setBandName:(NSString *)name { [bandNameCell setStringValue:name]; }
- (NSString *)bandName { return [bandNameCell stringValue]; }

- (void)setCDTitle:(NSString *)title { [cdTitleCell setStringValue:title]; } 
- (NSString *)cdTitle { return [cdTitleCell stringValue]; }

- (void)setMusicGenre:(NSString *)genre { [genreComboBoxCell setStringValue:genre]; }
- (NSString *)musicGenre { return [genreComboBoxCell stringValue]; }

@end
