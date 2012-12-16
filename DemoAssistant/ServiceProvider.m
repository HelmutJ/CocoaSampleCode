/*
     File: ServiceProvider.m
 Abstract: DemoAssistant implements a simple service which copies text from a file a line at a time to the
 service-requesting application. Multiple file names can be remembered and selected via a combo-box UI.
 The names of file names are stored in user's preferences.
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
#import "ServiceProvider.h"

@implementation ServiceProvider

/* When launched, register the service providing object (self) and load the names of previously selected script files.
*/
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    NSArray *previousValues = [[NSUserDefaults standardUserDefaults] objectForKey:@"DemoScriptDocuments"];
    if (previousValues && ([previousValues count] > 0)) {
        [demoScriptFileNameField addItemsWithObjectValues:previousValues];
        [self setDemoScriptFileName:[previousValues objectAtIndex:0]];
    } else {
	if (!demoScriptFileName) demoScriptFileName = [[@"~/Documents/DemoAssistantScript.txt" stringByExpandingTildeInPath] copy];
    }

    // To get service requests to go to the controller...
    [NSApp setServicesProvider:self];
}

/* Deal with a new filename, by fixing up the list of files, making sure the new file appears at top (MRU), and writing it out to preferences.
*/
- (void)recordNewFileName:(NSString *)newFileName {
#define maxItems 10
    NSInteger index = [[demoScriptFileNameField objectValues] indexOfObject:newFileName];

    // If filename is not found in the list, add it to the list. List is
    // limited to a certain number of items, so if there are already that many, remove the
    // last item to make room for the new.

    if (index == NSNotFound) {
        index = [demoScriptFileNameField numberOfItems] - 1;
        if (index > maxItems) [demoScriptFileNameField removeItemAtIndex:index];
    } else {
        [demoScriptFileNameField removeItemAtIndex:index];
    }
    [demoScriptFileNameField insertItemWithObjectValue:newFileName atIndex:0];	// Insert at top
    [demoScriptFileNameField setStringValue:newFileName];

    // Write out to preferences
    
    [[NSUserDefaults standardUserDefaults] setObject:[demoScriptFileNameField objectValues] forKey:@"DemoScriptDocuments"];
}

/* Funnel point for setting the current script file name. If different than previous selection, will rewind to top of file.
*/
- (void)setDemoScriptFileName:(NSString *)newFileName {
    if (![demoScriptFileName isEqual:newFileName]) {
        [demoScriptFileName autorelease];
        demoScriptFileName = [newFileName copy];
    
        [attributedString release];
        attributedString = nil;
    
        [self recordNewFileName:demoScriptFileName];
    }
}

/* Return the currently selected script.
*/
- (NSAttributedString *)demoScriptText {
    if (attributedString == nil) {
        lastShownLineRange = NSMakeRange(0, 0);
        attributedString = [[NSAttributedString alloc] initWithPath:demoScriptFileName documentAttributes:NULL];
        if (attributedString == nil) NSBeep();
    }
    return attributedString;
}

- (void)dealloc {
    [attributedString release];
    [super dealloc];
}

/* Service methods */

/* Get the next line and return it as an attributed string (RTFD). Clients who can't deal with RTFD should still get RTF or plain text. If at end of file, returns nothing.
*/
- (void)getNextLine:(NSPasteboard *)pboard userData:(NSString *)data error:(NSString **)error {
    NSAttributedString *attrStr = [self demoScriptText];

    if (!attrStr) {
        if (error) *error = @"No demo script file";
    } else if (lastShownLineRange.location >= [[attrStr string] length]) {
        if (error) *error = @"File complete";
    } else {
        NSRange lineRange = [[attrStr string] lineRangeForRange:lastShownLineRange];
        NSData *flatRTFD = [attrStr RTFDFromRange:lineRange documentAttributes:nil];
        NSString *string = [[attrStr string] substringWithRange:lineRange];
        if (!flatRTFD || !string) {
            if (error) *error = @"Couldn't get text";
        } else {
            [pboard declareTypes:[NSArray arrayWithObjects:NSRTFDPboardType, NSStringPboardType, nil] owner:nil];
            [pboard setData:flatRTFD forType:NSRTFDPboardType];
            [pboard setString:string forType:NSStringPboardType];
            lastShownLineRange = NSMakeRange(NSMaxRange(lineRange), 0);
        }
    }
}

/* Go back to beginning of file.
*/
- (void)rewind:(NSPasteboard *)pboard userData:(NSString *)data error:(NSString **)error {
    NSAttributedString *attrStr = [self demoScriptText];

    if (attrStr) {
        lastShownLineRange = NSMakeRange(0, 0);
    } else {
        if (error) *error = @"No demo script file";
    }
}

/* Go back a line.
*/
- (void)moveUpOneLine:(NSPasteboard *)pboard userData:(NSString *)data error:(NSString **)error {
    NSAttributedString *attrStr = [self demoScriptText];

    if (attrStr) {
        NSRange lineRange = [[attrStr string] lineRangeForRange:lastShownLineRange];
        if (lineRange.location > 0) lastShownLineRange = NSMakeRange(lineRange.location - 1, 0);
    } else {
        if (error) *error = @"No demo script file";
    }
}

/* Skip a line.
*/
- (void)moveDownOneLine:(NSPasteboard *)pboard userData:(NSString *)data error:(NSString **)error {
    NSAttributedString *attrStr = [self demoScriptText];

    if (attrStr) {
        NSRange lineRange = [[attrStr string] lineRangeForRange:lastShownLineRange];
        if (lineRange.location > 0) lastShownLineRange = NSMakeRange(NSMaxRange(lineRange), 0);
    } else {
        if (error) *error = @"No demo script file";
    }
}

/* Action methods */

/* Called from a text field or combo box. Sets the file name and records it as needed.
*/
- (IBAction)changeDemoScriptFileName:(id)sender {
    [self setDemoScriptFileName:[sender stringValue]];
}

/* Puts up an open sheet to choose a new script file name. The callback below (openPanelDidEnd...) is called when the sheet is dismissed.
*/
- (IBAction)browseForDemoScriptFileName:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setDirectoryURL:[NSURL fileURLWithPath:demoScriptFileName]];
    [panel beginSheetModalForWindow:[sender window] completionHandler:^(NSInteger code) {
        if (code == NSAlertDefaultReturn) [self setDemoScriptFileName:[[panel URL] path]];
    }];
}
                         
@end
