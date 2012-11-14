/*
    File: CustomMenusAppDelegate.m
Abstract: This class is responsible for two major activities. It sets up the images in the popup menu (via a custom view) and responds to the menu actions. Also, it supplies the suggestions for the search text field and responds to suggestion selection changes and text field editing.
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

#import "CustomMenusAppDelegate.h"
#import "ImagePickerMenuItemView.h"
#import "SuggestionsWindowController.h"

NSString *DESKTOP_PICTURES_PATH = @"/Library/Desktop Pictures";

@interface CustomMenusAppDelegate ()

/* Declare the skipNextSuggestion property in an anonymous category since it is a private property. See -controlTextDidChange: and -control:textView:doCommandBySelector: in this file for usage.
*/
@property (assign) BOOL skipNextSuggestion;

// private helper methods
- (void)setupImagesMenu;
- (void)updateFieldEditor:(NSText *)fieldEditor withSuggestion:(NSString *)suggestion;

@end

@implementation CustomMenusAppDelegate

@synthesize window;
@synthesize imagePicker;
@synthesize imageView;
@synthesize searchField;
@synthesize skipNextSuggestion = _skipNextSuggestion;

- (void)dealloc {
    [_suggestionsController release];
    [_suggestedURL release];
    [_baseURL release];
    [_imageURLS release];
    
    [super dealloc];
}

/* The popup menu allows selection from image files contained in the directory set here. The suggestion list recursively searches all the sub directories for matching image names starting at the directory set here.
*/
- (void)setBaseURL:(NSURL *)url {
    if (![url isEqual:_baseURL]) {
        [_baseURL autorelease];
        _baseURL = [url retain];
        [_imageURLS release];
        _imageURLS = nil;
    }
}

/* Start off by pointing to Desktop Pictures.
*/
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	[self setBaseURL:[NSURL fileURLWithPath:DESKTOP_PICTURES_PATH]];
    [self setupImagesMenu];
}

#pragma mark -
#pragma mark Custom Menu Item View
/* Set up the custom views in the popup button menu. This method should be called whenever the baseURL changes.
    In MainMenu.xib, the menu for the popup button is defined. There is one menu item with a tag of 1000 that is used as the prototype for the custom menu items. Each ImagePickerMenuItemView can contain 4 images. So we keep duplicating the prototype menu item until we have enough menu items for each image found in the directory specified by _baseURL. Duplicating the prototype menu allows us to reuse the target action wiring done in IB.
    We need to rebuild this menu each time the _baseURL changes. To accomplish this, we set the tag of each dupicated prototype to 1001. This way we can easily find and remove them to start over.
*/
- (void)setupImagesMenu {
	NSMenu *menu = [imagePicker menu];
	NSMenuItem *menuItem;
    
    // Look for existing ImagePickerMenuItemView menu items that are no longer valid and remove them.
	while ((menuItem = [menu itemWithTag:1001])) {
		[menu removeItem:menuItem];
	}
	
    // Find the prototype menu item. We want to keep it as the prototype for future rebuilds so we don't want to actually use it. Instead, make it hidden so the user never sees it.
	NSMenuItem *masterImagesMenuItem = [[imagePicker menu] itemWithTag:1000];
	[masterImagesMenuItem setHidden:YES];
	
	// Find all the entires in the _baseURL directory.
	NSArray *fileURLS = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:_baseURL includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLIsDirectoryKey, NSURLTypeIdentifierKey, nil] options:0 error:nil];
	
    // Only 4 images per menu item are allowed by the view. Use this index to keep track of that
	NSInteger idx = 0;
    
    // ImagePickerMenuItemView uses an array of URLS. This is that array.
    NSMutableArray *imageUrlArray;
    
    // Loop over each entry looking for image files
	for (NSURL *file in fileURLS) {
		NSNumber *isDirectory = nil;
        // directories are obviously not images.
		[file getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
		if (![isDirectory boolValue]) {
			NSString *fileType = nil;
            
            // Is the file an image file? Use UTTypes to find out.
			[file getResourceValue:&fileType forKey:NSURLTypeIdentifierKey error:nil];
			if (UTTypeConformsTo( (CFStringRef)fileType, kUTTypeImage )) {
				if	(idx == 0) {
                    // Starting a new set of 4 images. Setup a new menu item and URL array
                    imageUrlArray = [NSMutableArray arrayWithCapacity:4];
                    
                    // Duplicate the prototype menu item
					NSMenuItem *imagesMenuItem = [masterImagesMenuItem copy];
                    
                    // Load the custom view from its nib
					NSViewController *viewController = [[NSViewController alloc] initWithNibName:@"imagePickerMenuItem" bundle:nil];

                    /* Setup a mutable dictionary as the view controller's represeted object so we can bind the custom view to it.
                    */
                    NSMutableDictionary *pickerMenuData = [NSMutableDictionary dictionaryWithCapacity:2];
                    [pickerMenuData setObject:imageUrlArray forKey:@"imageUrls"];
                    [pickerMenuData setObject:[NSNull null] forKey:@"selectedUrl"]; // need a blank entry to start with
                    viewController.representedObject = pickerMenuData;
                    
                    // Bind the custom view to the image URLs array.
                    [viewController.view bind:@"imageUrls" toObject:viewController withKeyPath:@"representedObject.imageUrls" options:nil];
                    /* selectedImageUrl from the view is read only, so bind the data dictinary to the selectedImageUrl instead of the other way around.
                    */
                    [viewController.representedObject bind:@"selectedUrl" toObject:viewController.view withKeyPath:@"selectedImageUrl" options:nil];
                    
                    // transform the duplicated menu item prototype to a proper custom instance
                    [imagesMenuItem setRepresentedObject:viewController];
                    [imagesMenuItem setView:viewController.view];
                    [imagesMenuItem setTag:1001]; // set the tag to 1001 so we can remove this instance on rebuild (see above)
                    [imagesMenuItem setHidden:NO];
                    
                    // Insert the custom menu item
                    [menu insertItem:imagesMenuItem atIndex:[menu numberOfItems] - 2];
                    
                    // Cleanup memory
                    [imagesMenuItem release];
                    [viewController release];
				}
				
                /* Add the image URL to the mutable array stored in the view controller's representedObject dictionary. Since imageUrlArray is mutable, we can just modify it in place.
                */
                [imageUrlArray addObject:file];
                
                // Update our index. We can only put 4 images per custom menu item. Reset after every fourth image file.
				idx++;
				if (idx > 3) idx = 0; // with a 0 based index, when idx > 3 we'll have completed 4 passes.
			}
		}
	}
}

/* This is the action wired to the prototype custom menu item in IB. In -_setupImagesMenu above, we bound the selected URL to a mutable dictionary that was set as the viewController's representedObject. The viewController was set as the menu item's represented object and the sender is the menu item.
*/
- (IBAction)takeImageFrom:(id)sender {
    NSViewController *viewController = [sender representedObject];
    NSDictionary *menuItemData = [viewController representedObject];
    id imageURL = [menuItemData objectForKey:@"selectedUrl"];
    if (imageURL != [NSNull null]) {
        NSImage *image = [[NSImage alloc] initWithContentsOfURL:imageURL];
        [imageView setImage:image];
        [image release];
    } else {
        [imageView setImage:nil];
    }

}

/* Action method for the "Select Image Folder..." menu item on the popup button. Show Open panel to allow use to select the _baseURL to search for images. 
*/
- (IBAction)selectImageFolder:(id)sender {
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseFiles:NO];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setDirectoryURL:[NSURL fileURLWithPath:DESKTOP_PICTURES_PATH]];
	
	[openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
		if (result == NSFileHandlingPanelOKButton) {
            [self setBaseURL:[openPanel URL]];
			[self setupImagesMenu];
		}
	}];
}

#pragma mark -
#pragma mark Suggestions

/* This method is invoked when the user preses return (or enter) on the search text field. We don't want to use the text from the search field as it is just the image filename without a path. Also, it may not be valid. Instead, use this user action to trigger setting the large image view in the main window to the currently suggested URL, if there is one.
*/
- (IBAction)takeImageFromSuggestedURL:(id)sender {
    NSImage *image = nil;
    if(_suggestedURL) {
        image = [[NSImage alloc] initWithContentsOfURL:_suggestedURL];
    }

    [imageView setImage:image];
    [image release];
}

/* This is the action method for when the user changes the suggestion selection. Note, this action is called continuously as the suggestion selection changes while being tracked and does not denote user committal of the suggestion. For suggestion committal, the text field's action method is used (see above). This method is wired up programatically in the -controlTextDidBeginEditing: method below.
*/
- (IBAction)updateWithSelectedSuggestion:(id)sender {
    NSDictionary *entry = [sender selectedSuggestion];
    if (entry) {
        NSText *fieldEditor = [self.window fieldEditor:NO forObject:self.searchField];
        if (fieldEditor) {
            [self updateFieldEditor:fieldEditor withSuggestion:[entry objectForKey:kSuggestionLabel]];
            _suggestedURL = [entry objectForKey:kSuggestionImageURL];
        }
    }
}

/* Recursively search through all the image files starting at the _baseURL for image file names that begin with the supplied string. It returns an array of NSDictionaries. Each dictionary contains a label, detailed label and an url with keys that match the binding used by each custom suggestion view defined in suggestionprototype.xib.
*/
- (NSArray *)suggestionsForText:(NSString*)text {
    // We don't want to hit the disk every time we need to re-calculate the the suggestion list. So we cache the result from disk. If we really wanted to be fancy, we could listen for changes to the file system at the _baseURL to know when the cache is out of date.
    if (!_imageURLS) {
        _imageURLS = [[NSMutableArray alloc] initWithCapacity:1];
        NSArray *keyProperties = [NSArray arrayWithObjects:NSURLIsDirectoryKey, NSURLTypeIdentifierKey, NSURLLocalizedNameKey, nil];
        NSDirectoryEnumerator *dirItr = [[NSFileManager defaultManager] enumeratorAtURL:_baseURL includingPropertiesForKeys:keyProperties options:NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsHiddenFiles errorHandler:nil];
        
        NSURL *file;
        while ((file = [dirItr nextObject])) {
            NSNumber *isDirectory = nil;
            [file getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
            if (![isDirectory boolValue]) {
                NSString *fileType = nil;
                [file getResourceValue:&fileType forKey:NSURLTypeIdentifierKey error:nil];
                if (UTTypeConformsTo( (CFStringRef)fileType, kUTTypeImage )) {
                    [_imageURLS addObject:file];
                }
            }
        }
    }

    // Search the known image URLs array for matches.
    NSMutableArray *suggestions = [NSMutableArray arrayWithCapacity:1];
    
    for (NSURL *file in _imageURLS) {
        NSString *localizedName;
        [file getResourceValue:&localizedName forKey:NSURLLocalizedNameKey error:nil];
        
        if ([localizedName hasPrefix:text] || [[localizedName uppercaseString] hasPrefix:[text uppercaseString]]) {
            NSDictionary *entry = [NSDictionary dictionaryWithObjectsAndKeys:
                                    localizedName, kSuggestionLabel,
                                    [file path], kSuggestionDetailedLabel,
                                    file, kSuggestionImageURL,
                                    nil];
        
            [suggestions addObject:entry];
        }
    }
    
    return suggestions;
}

/* Update the field editor with a suggested string. The additional suggested characters are auto selected.
*/
- (void)updateFieldEditor:(NSText *)fieldEditor withSuggestion:(NSString *)suggestion {
    NSRange selection = NSMakeRange([fieldEditor selectedRange].location, [suggestion length]);
    [fieldEditor setString:suggestion];
    [fieldEditor setSelectedRange:selection];
}

/* Determines the current list of suggestions, display the suggestions and update the field editor.
*/
- (void)updateSuggestionsFromControl:(NSControl *)control {
    NSText *fieldEditor = [self.window fieldEditor:NO forObject:control];
    if (fieldEditor) {
        // Only use the text up to the caret position
        NSRange selection = [fieldEditor selectedRange];
        NSString *text = [[fieldEditor string] substringToIndex:selection.location];
        
        NSArray *suggestions = [self suggestionsForText:text];
        if ([suggestions count] > 0) {
            // We have at least 1 suggestion. Update the field editor to the first suggestion and show the suggestions window.
            NSDictionary *suggestion = [suggestions objectAtIndex:0];
            _suggestedURL = [suggestion objectForKey:kSuggestionImageURL];
            [self updateFieldEditor:fieldEditor withSuggestion:[suggestion objectForKey:kSuggestionLabel]];
            
            [_suggestionsController setSuggestions:suggestions];
            if (![_suggestionsController.window isVisible]) {
                [_suggestionsController beginForTextField:(NSTextField*)control];
            }
        } else {
            // No suggestions. Cancel the suggestion window and set the _suggestedURL to nil.
            _suggestedURL = nil;
            [_suggestionsController cancelSuggestions];
        }  
    }
}

/* In interface builder, we set this class object as the delegate for the search text field. When the user starts editing the text field, this method is called. This is an opportune time to display the initial suggestions. 
*/
- (void)controlTextDidBeginEditing:(NSNotification *)notification {
    // We keep the suggestionsController around, but lazely allocate it the first time it is needed.
    if (!_suggestionsController) {
        _suggestionsController = [[SuggestionsWindowController alloc] init];
        _suggestionsController.target = self;
        _suggestionsController.action = @selector(updateWithSelectedSuggestion:);
    }
    
    [self updateSuggestionsFromControl:notification.object];
}

/* The field editor's text may have changed for a number of reasons. Generally, we should update the suggestions window with the new suggestions. However, in some cases (the user deletes characters) we cancel the suggestions window.
*/
- (void)controlTextDidChange:(NSNotification *)notification {
    if(!self.skipNextSuggestion) {
        [self updateSuggestionsFromControl:notification.object];
    } else {
        // If we are skipping this suggestion, the set the _suggestedURL to nil and cancel the suggestions window.
        _suggestedURL = nil;
        
        // If the suggestionController is already in a cancelled state, this call does nothing and is therefore always safe to call.
        [_suggestionsController cancelSuggestions]; 
        
        // This suggestion has been skipped, don't skip the next one.
        self.skipNextSuggestion = NO;
    }
}

/* The field editor has ended editing the text. This is not the same as the action from the NSTextField. In the MainMenu.xib, the search text field is setup to only send its action on return / enter. If the user tabs to or clicks on another control, text editing will end and this method is called. We don't consider this committal of the action. Instead, we realy on the text field's action (see -takeImageFromSuggestedURL: above) to commit the suggestion. However, since the action may not occur, we need to cancel the suggestions window here.
*/
- (void)controlTextDidEndEditing:(NSNotification *)obj {
    /* If the suggestionController is already in a cancelled state, this call does nothing and is therefore always safe to call.
    */
    [_suggestionsController cancelSuggestions];
}

/* As the delegate for the NSTextField, this class is given a chance to respond to the key binding commands interpreted by the input manager when the field editor calls -interpretKeyEvents:. This is where we forward some of the keyboard commands to the suggestion window to facilitate keyboard navigation. Also, this is where we can determine when the user deletes and where we can prevent AppKit's auto completion.
*/
- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {

    if (commandSelector == @selector(moveUp:)) {
        // Move up in the suggested selections list
        [_suggestionsController moveUp:textView];
        return YES;
    }
    
    if (commandSelector == @selector(moveDown:)) {
        // Move down in the suggested selections list
        [_suggestionsController moveDown:textView];
        return YES;
    }
    
    if (commandSelector == @selector(deleteForward:) || commandSelector == @selector(deleteBackward:)) {
        /* The user is deleting the highlighted portion of the suggestion or more. Return NO so that the field editor performs the deletion. The field editor will then call -controlTextDidChange:. We don't want to provide a new set of suggestions as that will put back the characters the user just deleted. Instead, set skipNextSuggestion to YES which will cause -controlTextDidChange: to cancel the suggestions window. (see -controlTextDidChange: above)
        */
        self.skipNextSuggestion = YES;
        return NO;
    }
    
    if (commandSelector == @selector(complete:)) {
        // The user has pressed the key combination for auto completion. AppKit has a built in auto completion. By overriding this command we prevent AppKit's auto completion and can respond to the user's intention by showing or cancelling our custom suggestions window.
        if ([_suggestionsController.window isVisible]) {
            [_suggestionsController cancelSuggestions];
        } else {
            [self updateSuggestionsFromControl:control];
        }

        return YES;
    }
    
    // This is a command that we don't specifically handle, let the field editor do the appropriate thing.
    return NO;
}

@end
