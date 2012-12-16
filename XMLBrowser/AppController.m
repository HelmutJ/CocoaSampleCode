/*
     File: AppController.m
 Abstract: Use Key-Value Bindings to create a simple XML browser/editor.
  Version: 1.1
 
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

#import <WebKit/WebFrame.h>
#import "AppController.h"
#import "NodeKindValueTransformer.h"

// The options available in the fidelityMatrix
enum {
    FidelityNamespace = 0,
    FidelityAttribute,
    FidelityEntities,
    FidelityPrefixes,    
    FidelityEmpty,
    FidelityWhitespace,
    FidelityCDATA,
    FidelityQuotes,
    TidyXML,
    TidyHTML,
    PrettyPrint,
    FidelityCharacters,
    FidelityDTD,
    UseXInclude,
    Validate
};

enum {
    SourceTab = 0,
    EditorTab,
    ResultTab,
    XQueryTab
};

@implementation AppController

- (void)dealloc {
    [url release];
    [self setData:nil encoding:nil];
    [self setDocument:nil];
    [self setCurrent:nil];
    [alertSheet release];
    [super dealloc];
}

- (id)init {
    self = [super init];
    if (self) {
        options = NSXMLNodeOptionsNone;        
        
        // Setup value transformers so interface elements can be bound to enumerations (NSXMLNodeKind)
        // Change from a kind to an NSString (NSXMLElementKind -> "Element")
        {
            NodeKindValueTransformer *kindTransformer = [[NodeKindValueTransformer alloc] init];
            [NSValueTransformer setValueTransformer:kindTransformer forName:@"NodeKindValueTransformer"];
            [kindTransformer release];
        }
        // Change from a kind to a NSNumber boolean (NSXMLElementKind -> YES)
        {
            NodeCanHaveChildrenValueTransformer *kindTransformer = [[NodeCanHaveChildrenValueTransformer alloc] init];
            [NSValueTransformer setValueTransformer:kindTransformer forName:@"NodeCanHaveChildrenValueTransformer"];
            [kindTransformer release];
        }
        
        // Create an alert sheet used to show connection and parse errors
        alertSheet = [[NSAlert alloc] init];
        [alertSheet addButtonWithTitle:@"OK"];
        [alertSheet setAlertStyle:NSWarningAlertStyle];
    }
    return self;
}

// The command keys 1-4 select the four tabs
- (IBAction)setSelectedTab:(id)sender {
    [mainTabView selectTabViewItemAtIndex:[sender tag]];
}


- (BOOL)tabView:(NSTabView *)tabView shouldSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    BOOL shouldSelect = YES;
    int tab = [mainTabView indexOfTabViewItem:[mainTabView selectedTabViewItem]];

    // Trying to switch out of the source view will throw an exception if the document is invalid. By catching it we can prevent the tab switch from happening
NS_DURING
    switch (tab) {
        case SourceTab:
            [self applyNSXML:nil];
            break;

        case EditorTab:
            [self setResult:nil];
            break;

        default:
            break;
    }

NS_HANDLER
    shouldSelect = NO;
NS_ENDHANDLER        

    return shouldSelect;
}

/* There are two ways to enter a URL to display: either use File->Open or type directly in the URL field. Saving could be simply added by bringing up a save panel then using [[document XMLData] writeToURL:sheetURL atomically:YES] */

// Create and show a open sheet.
- (IBAction)openFile:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSInteger code) {
        if (code == NSAlertDefaultReturn) {
            [urlTextField setStringValue:[[openPanel URL] absoluteString]];
            [self fetchAndDisplayURL:nil];
        }
    }];
}

// This is called when the user hits "return" in the URL field, or OKs
//    the open file sheet. We fetch the data from the URL,
//    then display it in the text view 
- (IBAction)fetchAndDisplayURL:(id)sender {
    if ([[urlTextField stringValue] length]) {
        [self setURL:[NSURL URLWithString:[urlTextField stringValue]]];
        // Synchronously grab the data 
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        NSError *error;
        NSURLResponse *response;
        NSData *result = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        [self setData:result encoding:[response textEncodingName]];
        if (!result) {
            // Change the text of the alert sheet to contain the connection error, then display it
            [alertSheet setMessageText:@"Request error"];
            [alertSheet setInformativeText:[error localizedDescription]];
            [alertSheet beginSheetModalForWindow:[NSApp mainWindow] modalDelegate:self didEndSelector:nil contextInfo:nil];            
            // clear out old value
            [self setDocument:nil];
        }
    } else {
        [self setData:nil encoding:nil];
    }
}

// The user has switched away from the Source tab, so parse the source
- (IBAction)applyNSXML:(id)sender {
    NSError *error;
    // Parse the document with NSXMLDocument
    NSXMLDocument *doc = [[NSXMLDocument alloc] initWithData:data options:options error:&error];
    if (doc) {
        [doc setURI:[url absoluteString]];
        // Set both the document and "current". Current is used in the context of the second tab
        //    (editing) to show what node is currently displayed/available to modify
        [self setDocument:doc];
        [self setCurrent:doc];
    } else {
        [self setDocument:nil];
        [self setCurrent:nil];
    
        if (error) {
            // Change the text of the alert sheet to contain the parse error, then display it    
            [alertSheet setMessageText:@"Parse error"];
            [alertSheet setInformativeText:[error localizedDescription]];
            [alertSheet beginSheetModalForWindow:[NSApp mainWindow] modalDelegate:self didEndSelector:nil contextInfo:nil];
            // Don't allow the user to switch from the Source tab
            NSAssert(NO, @"Invalid XML");          
        }
    }
    [doc release];
}

// The user has clicked the Apply button in the XQuery tab
- (IBAction)applyXQuery:(id)sender {
    // Clear out the old result
    [xqueryResultTextView setString:@""];
    if (document) {
        NSError *error;
        // Apply the contents of the XQuery text field to the current document
        NSArray *result = [document objectsForXQuery:[xquerySourceTextView string] constants:nil error:&error];
        if (result) {
            unsigned count = [result count];
            unsigned i;
            NSMutableString *stringResult = [[NSMutableString alloc] init];
            // Format the result array to display the position in the array with its contents enclosed in curly braces 
            // In XQuery arrays are one-based so display them array index + 1
            for (i = 0; i < count; i++) {
                [stringResult appendString:[NSString stringWithFormat:@"%d: {\r", i + 1]];
                [stringResult appendString:[[result objectAtIndex:i] description]];
                [stringResult appendString:@"\r}\r"];
            }
            [xqueryResultTextView setString:stringResult];
            [stringResult release];
        } else if (error) {
            // Change the text of the alert sheet to contain the XQuery parse error, then display it
            [alertSheet setMessageText:@"XQuery error"];
            [alertSheet setInformativeText:[error localizedDescription]];
            [alertSheet beginSheetModalForWindow:[NSApp mainWindow] modalDelegate:self didEndSelector:nil contextInfo:nil];            
        }
    }
}

// The user has clicked on the Results tab
- (IBAction)setResult:(id)sender {
    [self setResultTextViewString: [document XMLStringWithOptions:options]];
}

// The user has checked one of the fidelity checkboxes in the Source tab.
// Keep track of what they've checked/unchecked so we can apply these options when the data is parsed
- (IBAction)setFidelity:(id)sender {
    if ([[fidelityMatrix cellWithTag:FidelityNamespace] state] == NSOnState) {
        options |= NSXMLNodePreserveNamespaceOrder;
    } else {
        options &= ~NSXMLNodePreserveNamespaceOrder;
    }
    if ([[fidelityMatrix cellWithTag:FidelityAttribute] state] == NSOnState) {
        options |= NSXMLNodePreserveAttributeOrder;
    } else {
        options &= ~NSXMLNodePreserveAttributeOrder;    
    }
    if ([[fidelityMatrix cellWithTag:FidelityEmpty] state] == NSOnState) {
        options |= NSXMLNodePreserveEmptyElements;
    } else {
        options &= ~NSXMLNodePreserveEmptyElements;    
    }
    if ([[fidelityMatrix cellWithTag:FidelityWhitespace] state] == NSOnState) {
        options |= NSXMLNodePreserveWhitespace;
    } else {
        options &= ~NSXMLNodePreserveWhitespace;
    }
    if ([[fidelityMatrix cellWithTag:FidelityEntities] state] == NSOnState) {
        options |= NSXMLNodePreserveEntities;
    } else {
        options &= ~NSXMLNodePreserveEntities;
    }
    if ([[fidelityMatrix cellWithTag:FidelityPrefixes] state] == NSOnState) {
        options |= NSXMLNodePreservePrefixes;
    } else {
        options &= ~NSXMLNodePreservePrefixes;    
    }
    if ([[fidelityMatrix cellWithTag:FidelityCDATA] state] == NSOnState) {
        options |= NSXMLNodePreserveCDATA;
    } else {
        options &= ~NSXMLNodePreserveCDATA;
    }
    if ([[fidelityMatrix cellWithTag:FidelityQuotes] state] == NSOnState) {
        options |= NSXMLNodePreserveQuotes;
    } else {
        options &= ~NSXMLNodePreserveQuotes;
    }
    if ([[fidelityMatrix cellWithTag:TidyXML] state] == NSOnState) {
        options |= NSXMLDocumentTidyXML;
    } else {
        options &= ~NSXMLDocumentTidyXML;    
    }
    if ([[fidelityMatrix cellWithTag:TidyHTML] state] == NSOnState) {
        options |= NSXMLDocumentTidyHTML;
    } else {
        options &= ~NSXMLDocumentTidyHTML;    
    }
    if ([[fidelityMatrix cellWithTag:PrettyPrint] state] == NSOnState) {
        options |= NSXMLNodePrettyPrint;
    } else {
        options &= ~NSXMLNodePrettyPrint;    
    }
    if ([[fidelityMatrix cellWithTag:FidelityCharacters] state] == NSOnState) {
        options |= NSXMLNodePreserveCharacterReferences;
    } else {
        options &= ~NSXMLNodePreserveCharacterReferences;    
    }    
    if ([[fidelityMatrix cellWithTag:FidelityDTD] state] == NSOnState) {
        options |= NSXMLNodePreserveDTD;
    } else {
        options &= ~NSXMLNodePreserveDTD;    
    }    
    if ([[fidelityMatrix cellWithTag:UseXInclude] state] == NSOnState) {
        options |= NSXMLDocumentXInclude;
    } else {
        options &= ~NSXMLDocumentXInclude;    
    }    
    if ([[fidelityMatrix cellWithTag:Validate] state] == NSOnState) {
        options |= NSXMLDocumentValidate;
    } else {
        options &= ~NSXMLDocumentValidate;    
    }    
}

// The user has clicked the down button or used the shortcut apple-] to
//    move down the tree. Using KVC we set "current" to the selected child in
//    the table view
- (IBAction)setCurrentToSelectedChildren:(id)sender {
    int selectedRow = [childrenTableView selectedRow];    
    NSXMLNode *node = [current childAtIndex:selectedRow];
    if ([node kind] == NSXMLElementKind || [node kind] == NSXMLDocumentKind) {
        [childrenTableView deselectRow:selectedRow];    
        [self setValue:node forKey:@"current"];
    }
}

// The user has clicked the up button or used the shortcut apple-[ to
//    move up the tree. Using KVC we set "current" to current's parent.
- (IBAction)setCurrentToSelectedParent:(id)sender {
    [childrenTableView deselectRow:[childrenTableView selectedRow]];
    [self setValue:[current parent] forKey:@"current"];
}

// The user has selected a child from the upper right "+" menu on the second tab.
//    Here the sender's tag corresponds to the enum kind we create
- (IBAction)addChildToCurrent:(id)sender {
    NSXMLNode *child = [[NSXMLNode alloc] initWithKind:[[sender selectedItem] tag]];
    [children addObject:child];
    [child release];
}

// In the "Element" subtab of the second tab, the user has clicked "+" above the attributes table
- (IBAction)addAttributeToCurrent:(id)sender {
    if ([[[children selectedObjects] objectAtIndex:0] isKindOfClass:[NSXMLElement class]]) {
        NSXMLNode *attribute = [NSXMLNode attributeWithName:@"name" stringValue:@"value"];
        [attributes addObject:attribute];
    }
}

// In the "Element" subtab of the second tab, the user has clicked "+" above the namespaces table
- (IBAction)addNamespaceToCurrent:(id)sender {
    if ([[[children selectedObjects] objectAtIndex:0] isKindOfClass:[NSXMLElement class]]) {
        NSXMLNode *namespace = [NSXMLNode namespaceWithName:@"prefix" stringValue:@"uri"];
        [namespaces addObject:namespace];
    }
}

#pragma mark --- Getters and setters ---

- (void)setData:(NSData *)theData encoding:(NSString *)encoding {
    if (data != theData) {
        [data release];
        data = [theData retain];
        
        // NSURLResponse's encoding is an IANA string. Use CF utilities to convert it to a CFStringEncoding then a NSStringEncoding
        NSStringEncoding nsEncoding = NSUTF8StringEncoding; // default to UTF-8
        if (encoding) {
            CFStringEncoding cfEncoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)encoding);
            if (cfEncoding != kCFStringEncodingInvalidId) {
                nsEncoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding);
            }
        }
        NSString *displayString = [[NSString alloc] initWithData:data encoding:nsEncoding];
        [self setSourceTextViewString: displayString];
        [displayString release];
    }
}

- (NSData *)data {
    return [[data retain] autorelease];
}

- (void)setURL:(NSURL *)theUrl {
    if (url != theUrl) {
        [url release];
        url = [theUrl retain];
        [urlTextField setStringValue:[url absoluteString]];
    }
}

- (NSURL *)url {
    return [[url retain] autorelease];
}

- (void)setDocument:(NSXMLDocument *)doc {
    if (document != doc) {
        [document release];
        document = [doc retain];
    }
   [self setResultTextViewString: [document XMLStringWithOptions:options]];
}
 
- (NSXMLDocument *)document {
    return [[document retain] autorelease];
}

- (void)setCurrent:(NSXMLNode *)theCurrent {
    if (current != theCurrent) {
        [current release];
        current = [theCurrent retain];    
    }
}

- (NSXMLNode *)current {
    if (!current) {
        NSXMLDocument *doc = [NSXMLNode document];
        [self setDocument:doc];
        current = [doc retain];
    }
    return [[current retain] autorelease];
}

- (void)setSourceTextViewString:(NSString*)string
{
    if (!string) string = @"";
    [sourceTextView setString:string];
}

- (void)setNodeTextViewString:(NSString*)string
{
    if (!string) string = @"";
    [nodeTextView setString:string];
}

- (void)setXQuerySourceTextViewString:(NSString*)string
{
    if (!string) string = @"";
    [xquerySourceTextView setString:string];
}

- (void)setXQueryResultTextViewString:(NSString*)string
{
    if (!string) string = @"";
    [xqueryResultTextView setString:string];
}

- (void)setResultTextViewString:(NSString*)string
{
    if (!string) string = @"";
    [resultTextView setString:string];
}




@end
