/*
    File: SuggestionsWindowController.h
Abstract: The controller for the suggestions popup window. This class handles creating, displaying, and event tracking of the suggestion popup window.
 Version: 1.4

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

APPKIT_EXTERN NSString *kSuggestionImageURL;
APPKIT_EXTERN NSString *kSuggestionLabel;
APPKIT_EXTERN NSString *kSuggestionDetailedLabel;
APPKIT_EXTERN NSString *kSuggestionGroup;

@interface SuggestionsWindowController : NSWindowController {
@private
    NSTextField *_parentTextField;
    SEL _action;
    id _target;
    
    NSArray *_suggestions;
    NSMutableArray *_viewControllers;
    NSMutableArray *_trackingAreas;
    BOOL _needsLayoutUpdate;
    
    id _localMouseDownEventMonitor;
    id _lostFocusObserver;
    NSView *_selectedView;
}

@property (assign) SEL action;
@property (assign) id target;

// The designated initializer. This window controller creates its own custom suggestions window.
- (id)init;

// -beginForControl: is used to display the suggestions window just underneath the parent control.
- (void)beginForTextField:(NSTextField *)parentTextField;

/* Order out the suggestion window, disconnect the accessibility logical relationship and dismantle any observers for auto cancel.
    Note: It is safe to call this method even if the suggestions window is not currently visible.
*/
- (void)cancelSuggestions;

/* Update the array of suggestions. The array should consist of NSMutableDictionaries each containing the following keys:
    kSuggestionImageURL - The URL to an image file
    kSuggestionLabel - The main suggestion string
    kSuggestionDetailedLabel - A longer string that provides more detail about the suggestion
    kSuggestionImage - [optional] The image to show in the suggestion thumbnail. If this key is not provided, a thumbnail image will be created in a background que and added to the dicionary. Hence, the mutable dicionary requirement.
*/
- (void)setSuggestions:(NSArray*)suggestions;

// Returns the dictionary of the currently selected suggestion.
- (id)selectedSuggestion;

@end
