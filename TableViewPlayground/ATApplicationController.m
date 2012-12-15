/*
     File: ATApplicationController.m 
 Abstract: The main demo application controller. This class is the delegate for the main NSApp instance. This class manages the windows that are open, and allows the user to create a new one with the 'Available Sample Windows' table view. Bindings are used in the 'Available Sample Windows' table for the content. The TableView is bound to the _tableContents, which is an array of NSDictionary objects that contain the information to disply.
  
  Version: 1.3 
  
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

#import "ATApplicationController.h"

#import "ATComplexTableViewController.h"
#import "ATComplexOutlineController.h"
#import "ATBasicTableViewWindowController.h"

@implementation ATApplicationController

// Keys used for bindings

#define ATKeyClass @"class"
#define ATKeyName @"name"
#define ATKeyShortDescription @"shortDescription"
#define ATKeyImagePreview @"imagePreview"

- (void)dealloc {
    [_windowControllers release];
    [_tableContents release];
    [super dealloc];
}

- (void)_newWindowWithControllerClass:(Class)c {
    NSWindowController *controller = [[c alloc] init];
    if (_windowControllers == nil) {
        _windowControllers = [NSMutableArray new];
    }
    [_windowControllers addObject:controller];
    [controller showWindow:self];
    [controller release];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    if (_tableContents == nil) {
        _tableContents = [NSMutableArray new];
        [self willChangeValueForKey:@"_tableContents"];
        [_tableContents addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                   [ATBasicTableViewWindowController class], ATKeyClass,
                                   @"Basic Table View", ATKeyName,
                                   @"A Minimal View Based Implementation", ATKeyShortDescription,
                                   [NSImage imageNamed:@"ATBasicTableViewWindowPreview.png"], ATKeyImagePreview,                                   
                                   nil]];
                                   
                                   
        [_tableContents addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                   [ATComplexTableViewController class], ATKeyClass,
                                   @"Complex Table View", ATKeyName,
                                   @"A Complex Cell Example", ATKeyShortDescription,
                                   [NSImage imageNamed:@"ATComplexTableViewControllerPreview.png"], ATKeyImagePreview,                                   
                                   nil]];
        
        
        [_tableContents addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                   [ATComplexOutlineController class], ATKeyClass,
                                   @"Complex Outline View", ATKeyName,
                                   @"A Complex Bindings Example", ATKeyShortDescription,
                                   [NSImage imageNamed:@"ATComplexOutlineControllerPreview.png"], ATKeyImagePreview,                                   
                                   nil]];
        
        [self didChangeValueForKey:@"_tableContents"];
        
        // Observe all windows closing so we can remove them from our array
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_windowClosed:) name:NSWindowWillCloseNotification object:nil];
    }
}

- (void)_windowClosed:(NSNotification *)note {
    NSWindow *window = [note object];
    for (NSWindowController *winController in _windowControllers) {
        if (winController.window == window) {
            [[winController retain] autorelease]; // Keeps the instance alive a little longer so things can unbind from it
            [_windowControllers removeObject:winController];
            break;
        }
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    // Create something on startup
    [self _newWindowWithControllerClass:[ATBasicTableViewWindowController class]];
    [self _newWindowWithControllerClass:[ATComplexTableViewController class]];
    [self _newWindowWithControllerClass:[ATComplexOutlineController class]];
}

@end
