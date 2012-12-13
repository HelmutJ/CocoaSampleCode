/*
     File: Controller.m
 Abstract: Main controller for the application.
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


#import "Controller.h"

#import "TextViewAspect.h"
#import "VerticalScrollAspect.h"
#import "NoWrapScrollAspect.h"
#import "FixedSizeAspect.h"
#import "TwoColumnsAspect.h"
#import "FieldAspect.h"

@interface Controller ()
- (void)setUpTextStorage;
- (void)setUpAspects;
@end

@implementation Controller
@synthesize textStorage, aspects, selectedAspectIndex;

- (id)init {
    self = [super init];
    if (self) {
        [self setUpTextStorage];
        [self setUpAspects];
        
        self.selectedAspectIndex = 0;
    }
    return self;
}

/* Sets up an instance of NSTextStorage with the data in README.rtf. This will be the backing of most of the different text views we create.
 */
- (void)setUpTextStorage {
    NSError *error;
    textStorage = [[NSTextStorage alloc] initWithURL:[[NSBundle mainBundle] URLForResource:@"README" withExtension:@"rtf"] options:nil documentAttributes:NULL error:&error];
    
    if (!textStorage) {
        [NSApp presentError:error];
        [NSApp terminate:self];
    }
}

/* Creates all of the controllers for displaying the various aspects of the Cocoa text system. This method assumes that self.textStorage has already been initialized.
 */
- (void)setUpAspects {
    TextViewAspect *nextAspect;
    NSMutableArray *newAspects = [[NSMutableArray alloc] init];
    
    nextAspect = [[VerticalScrollAspect alloc] initWithTextStorage:self.textStorage];
    [newAspects addObject:nextAspect];
    [nextAspect release];
    
    nextAspect = [[NoWrapScrollAspect alloc] initWithTextStorage:self.textStorage];
    [newAspects addObject:nextAspect];
    [nextAspect release];

    nextAspect = [[FixedSizeAspect alloc] initWithTextStorage:self.textStorage];
    [newAspects addObject:nextAspect];
    [nextAspect release];

    nextAspect = [[TwoColumnsAspect alloc] initWithTextStorage:self.textStorage];
    [newAspects addObject:nextAspect];
    [nextAspect release];
 
    nextAspect = [[FieldAspect alloc] initWithTextStorage:nil]; // ignored anyway for the fields
    [newAspects addObject:nextAspect];
    [nextAspect release];
   
    aspects = newAspects;
}

- (void)dealloc {
    [aspects release];
    [textStorage release];
    [super dealloc];
}

/* Called when the nib file has finished loading and any documents have been opened. We use this to set up the tabless tab view with our various aspect controllers.
 */
- (void)applicationDidFinishLaunching:(NSNotification *)note {
    NSTabViewItem *nextTab;
    for (TextViewAspect *aspect in self.aspects) {
        nextTab = [[NSTabViewItem alloc] initWithIdentifier:aspect.title];
        [nextTab setView:aspect.containerView];
        [nextTab setInitialFirstResponder:aspect.textView];
        [aspectsTabView addTabViewItem:nextTab];
        [nextTab release];
    }
    
    [aspectsTabView removeTabViewItem:[aspectsTabView tabViewItemAtIndex:0]];
    self.selectedAspectIndex = 0;
}

#pragma mark -

/* Put up an open sheet to replace the data in the view.
 */
- (IBAction)openDocument:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setTreatsFilePackagesAsDirectories:NO];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel beginSheetModalForWindow:[aspectsTabView window] completionHandler:^(NSInteger result) {
        if (result == NSOKButton) {
            [openPanel orderOut:self]; // close panel before we might present an error
            NSURL *url = [openPanel URL];
            NSString *path;
            if ([url isFileURL] && (path = [url path])) {
                [self application:NSApp openFile:[url path]];
            } else {
                NSBeep();
            }
        }
    }];
}

/* An NSApplication delegate method, also called from openPanelDidEnd:returnCode:contextInfo:. If the file's UTI is one that NSAttributedString can handle, we load it as an attributed string. Otherwise we treat the file as plain text and load it using NSString.
 */
- (BOOL)application:(NSApplication *)app openFile:(NSString *)filename {
    NSURL *fileURL = [NSURL fileURLWithPath:filename]; // make it easier to migrate to a future application:openURL:
    
    NSString *fileUTI = nil;
    BOOL isRichText = NO;
    
    // Get the UTI
    // We ignore the error because we'll just fall back to plain text otherwise
    [fileURL getResourceValue:&fileUTI forKey:NSURLTypeIdentifierKey error:NULL];
    
    // Figure out if the type of the file is a rich text type
    if (fileUTI) {
        NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
        for (NSString *nextRichUTI in [NSAttributedString textTypes]) {
            // attributed strings can handle plain text, but we'd just as soon handle that separately
            if (![nextRichUTI isEqual:(NSString *)kUTTypePlainText]) {
                if ([workspace type:fileUTI conformsToType:nextRichUTI]) {
                    isRichText = YES;
                    break;
                }
            }
        }
    }
    
    if (isRichText) {
        // Load the file's data into an attributed string, then into the text storage.
        NSError *error;
        NSAttributedString *newContents = [[NSAttributedString alloc] initWithURL:fileURL options:nil documentAttributes:NULL error:&error];
        
        if (newContents) { 
            [textStorage setAttributedString:newContents];
            [newContents release];
        } else {
            [app presentError:error];
            return NO; 
        }
    } else {
        // Load the file's data into a regular string, then into the text storage.
        NSError *error;
        NSString *newContents = [[NSString alloc] initWithContentsOfURL:fileURL usedEncoding:NULL error:&error];
        if (newContents) {
            [[textStorage mutableString] setString:newContents];
            [textStorage addAttribute:NSFontAttributeName value:[NSFont userFixedPitchFontOfSize:0.0] range:NSMakeRange(0, [newContents length])];
            [newContents release];
        } else {
            [app presentError:error];
            return NO; 
        }
    }
        
    return YES;
}

@end
