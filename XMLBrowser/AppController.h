/*
     File: AppController.h
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

#import <Cocoa/Cocoa.h>

@interface AppController : NSObject
{
    IBOutlet NSWindow *mainWindow;

    // The "Source" URL (Source tab)
    IBOutlet NSTextField *urlTextField;

    // A view of the source (Source tab)
    IBOutlet NSTextView *sourceTextView;    

    // A view of the current selected node (Editor tab)
    IBOutlet NSTextView *nodeTextView;    

    // The XML with modifications applied from the Browse tab (Result tab)
    IBOutlet NSTextView *resultTextView;

    // Where the user inputs their XQuery (XQuery tab)
    IBOutlet NSTextView *xquerySourceTextView;

    // The result of applying the XQuery to the current document (XQuery tab)
    IBOutlet NSTextView *xqueryResultTextView;

    // The set of tabs
    IBOutlet NSTabView *mainTabView;

    // The set of input and output options
    IBOutlet NSMatrix *fidelityMatrix;

    // Children of the current selected node
    IBOutlet NSTableView *childrenTableView;

    // Attributes of the current selected element
    IBOutlet NSTableView *attributeTableView;

    // Namespaces of the current selected element
    IBOutlet NSTableView *namespaceTableView;

    // Set of array controllers for the different array we may display
    IBOutlet NSArrayController *children;
    IBOutlet NSArrayController *attributes;
    IBOutlet NSArrayController *namespaces;
    IBOutlet NSArrayController *dtdNodes;
    
    // Sheet to display errors on parse, connect, or XQuery
    NSAlert *alertSheet;
    
    // The URL we read (for files: and write) to
    NSURL *url;
    
    // The data at the URL
    NSData *data;
    
    // Document that results after parsing the data
    NSXMLDocument *document;
    
    // The set of options to use for input from the fidelityMatrix
    unsigned int options;
    
    // The current node (changes as the user moves up and down the tree)
    NSXMLNode *current;
}

- (IBAction)setSelectedTab:(id)sender;

- (IBAction)openFile:(id)sender;
- (IBAction)fetchAndDisplayURL:(id)sender;
- (IBAction)applyNSXML:(id)sender;
- (IBAction)applyXQuery:(id)sender;
- (IBAction)setResult:(id)sender;
- (IBAction)setFidelity:(id)sender;
- (IBAction)setCurrentToSelectedChildren:(id)sender;
- (IBAction)setCurrentToSelectedParent:(id)sender;
- (IBAction)addAttributeToCurrent:(id)sender;
- (IBAction)addNamespaceToCurrent:(id)sender;
- (IBAction)addChildToCurrent:(id)sender;

- (void)setData:(NSData *)theData encoding:(NSString *)encoding;
- (NSData *)data;
- (void)setURL:(NSURL *)theUrl;
- (NSURL *)url;
- (void)setDocument:(NSXMLDocument *)doc;
- (NSXMLDocument *)document;
- (void)setCurrent:(NSXMLNode *)theCurrent;
- (NSXMLNode *)current;

- (void)setSourceTextViewString:(NSString *)string;
- (void)setNodeTextViewString:(NSString *)string;
- (void)setXQuerySourceTextViewString:(NSString *)string;
- (void)setXQueryResultTextViewString:(NSString *)string;
- (void)setResultTextViewString:(NSString *)string;
@end
