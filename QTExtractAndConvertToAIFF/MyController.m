/*

File: MyController.m

Author: QuickTime DTS

Change History (most recent first):
        
        <3> 09/12/06 minor changes for QTExtractAndConvertToAIFF sample
        <2> 03/24/06 ensure the movie is fully loaded before extraction can start Q&A 1469
        <1> 11/10/05 initial release for ExtractMovieAudioToAIFF sample

© Copyright 2005 - 2006 Apple Computer, Inc. All rights reserved.

IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc. ("Apple") in
consideration of your agreement to the following terms, and your use, installation,
modification or redistribution of this Apple software constitutes acceptance of these
terms.  If you do not agree with these terms, please do not use, install, modify or
redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and subject to these
terms, Apple grants you a personal, non-exclusive license, under Apple's copyrights in
this original Apple software (the "Apple Software"), to use, reproduce, modify and
redistribute the Apple Software, with or without modifications, in source and/or binary
forms; provided that if you redistribute the Apple Software in its entirety and without
modifications, you must retain this notice and the following text and disclaimers in all
such redistributions of the Apple Software. Neither the name, trademarks, service marks
or logos of Apple Computer, Inc. may be used to endorse or promote products derived from
the Apple Software without specific prior written permission from Apple.  Except as
expressly stated in this notice, no other rights or licenses, express or implied, are
granted by Apple herein, including but not limited to any patent rights that may be
infringed by your derivative works or by other works in which the Apple Software may be
incorporated.

The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO WARRANTIES,
EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF
NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING THE
APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.

IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY OUT OF THE
USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER
CAUSED AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT
LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

*/

#import "MyController.h"
#import "AIFFWriter.h"

@implementation MyController

- (void)awakeFromNib
{
    // make sure our cocoa window has a valid windowRef
    // by calling the windowRef method
    // we need to do this so the StdAudio dialog (which is automatically displayed by the
    // AudioConverter object) will correctly appear in the alert position
    // above our frontmost window -- if we don't do this we get inconsistent behavior with the
    // dialog appearing in different places
    [mWindow windowRef];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
     
	// create the worker object and set the
    // delegate so it will call the progress callback
	mAIFFWriter = [[AIFFWriter alloc] init];
	[mAIFFWriter setDelegate:self];
    
    [mExportButton setEnabled:FALSE];
    
    [nc addObserver:self selector:@selector(movieLoadStateDidChange:) name:@"QTMovieLoadStateDidChangeNotification" object:nil];
}

#pragma mark ---- panel callbacks ----

// movie opening panel
- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
#pragma unused(contextInfo)

    if (NSOKButton == returnCode) {
        NSString *theFilename = [[sheet filenames] objectAtIndex:0];
        [sheet close];
    
        [self openMovie:theFilename];
    }
}

// movie save panel
- (void)savePanelDidEnd:(NSOpenPanel*)sheet returnCode:(int)returnCode contextInfo:(void*)contextInfo
{
#pragma unused(contextInfo)
   
    if (NSOKButton == returnCode) {
    	[sheet close];

        [mAIFFWriter exportFromMovie:mMovie toFile:[sheet filename]];
    }
}

// error alert sheet
- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
#pragma unused(alert, returnCode, contextInfo)

    // if applicationShouldTerminate was called during export we don't quit - we
    // set the isQuitting flag then wait for the extaction to finish
    if (YES == mAppIsQuitting) {
        [[NSApplication sharedApplication] replyToApplicationShouldTerminate:YES];
    }
}

#pragma mark ---- open movie/export ----

// select a file to open
- (IBAction)doOpen:(id)sender
{
#pragma unused(sender)

	[[NSOpenPanel openPanel] beginSheetForDirectory:nil
                             file:nil
                             types:nil
                             modalForWindow:[self window]
                             modalDelegate:self
                             didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
                             contextInfo:nil];
}

// called when the extraction/conversion button is pressed
- (IBAction)doExportToAIFF:(id)sender
{
#pragma unused(sender)

    if (nil == mMovie) return;
    
    NSSavePanel *savePanel = [NSSavePanel savePanel];
	
    [savePanel setRequiredFileType:@"aif"];
	
    // open a save panel to get a target file specification
	[savePanel beginSheetForDirectory:nil
                                file:@"ExtractedConvertedAudio"
                                modalForWindow:[self window]
                                modalDelegate:self
                                didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:)
                                contextInfo:nil];
}

// open the QTMovie and set it in the view replacing the movie that was there
// the AIFFWriter object retains the movie during the operation
- (void)openMovie:(NSString *)inFile
{
    NSAlert *alert = nil;
    NSError *error = nil;
    
	if (mMovie != nil) {
        [mMovieView pause:self];
		[mMovieView setMovie:nil];
	}
    
    if (![mAIFFWriter isConverting] ) {
        [mExportButton setTitle:@"Loading Movie..."];
    }
    
    mMovie = [QTMovie movieWithFile:inFile error:&error];
    
    if (nil == error) {

        [[self window] setTitle:[mMovie attributeForKey:QTMovieDisplayNameAttribute]];
    
        [mMovieView setMovie:mMovie];
        [mMovieView setNeedsDisplay:TRUE];
        
        // if a Movie loads really fast QTKit will not send a LoadStateDidChange notification so we do it here
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"QTMovieLoadStateDidChangeNotification" object:nil]];
    } else {
    	if (error) {
 			alert = [NSAlert alertWithError:error];
        }
        
		[alert runModal];
    }

}

#pragma mark ---- getters ----

- (NSWindow *)window
{
    return mWindow;
}

#pragma mark ---- progress callback delegate ----

// progress callback funtion used to drive the progress indicator, UI and allows
// the client app to get status errors from the AIFFWriter object
- (BOOL)shouldContinueOperationWithProgressInfo:(AIFFWriterProgressInfo *)inProgressInfo
{
    AIFFWriterExportOperationPhase phase = [inProgressInfo phase];
    
	switch (phase) {
    case AIFFWriterExportBegin:
    	[mProgressBar startAnimation:self];
        [mExportButton setTitle:@"Converting..."];
        [mExportButton setEnabled:FALSE];
        
        break;
    case AIFFWriterExportPercent:
    	if ([mProgressBar isIndeterminate]) {
        	[mProgressBar stopAnimation:self];
        	[mProgressBar setIndeterminate:FALSE];
        }
        
    	[mProgressBar setDoubleValue:[[inProgressInfo progressValue] doubleValue]];
        
    	break;
    case AIFFWriterExportEnd:
    {
        NSError *status = [inProgressInfo exportStatus];
        long movieLoadState = [[mMovie attributeForKey:QTMovieLoadStateAttribute] longValue];
        
    	[mProgressBar setIndeterminate:TRUE];
        [mProgressBar setDoubleValue:0];
        [mProgressBar stopAnimation:self];
        
        if (kMovieLoadStateComplete == movieLoadState) {
            [mExportButton setTitle:@"Extract & Convert"];
        }
        
        if (nil == status) {
        
            // if applicationShouldTerminate was called during export we don't quit - we
            // set the isQuitting flag then wait for the extaction to finish
            if (YES == mAppIsQuitting) {
                [[NSApplication sharedApplication] replyToApplicationShouldTerminate:YES];
            }
        } else {
        
            NSAlert *alert = [NSAlert alertWithMessageText:@"AIFFWriter Error!"
                                      defaultButton:@"OK"
                                      alternateButton:nil
                                      otherButton:nil
                                      informativeTextWithFormat:@"Extraction/Conversion failed with %d error.", [status code]];
                                      
        	[alert beginSheetModalForWindow:[self window]
                   modalDelegate:self
                   didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                   contextInfo:NULL];
        }
        
        if (kMovieLoadStateComplete == movieLoadState && (TRUE == [[mMovie attributeForKey:QTMovieHasAudioAttribute] boolValue])) {
            [mExportButton setEnabled:TRUE];
        }
    }
        break;
    default:
    	break;
    }
    
    // return NO if you want to cancel the export
    [inProgressInfo setContinueOperation:YES];
    return YES;
}

#pragma mark ---- notifications ----

// movieLoadStateDidChange is called for QTMovieLoadStateDidChangeNotification notifications.
- (void)movieLoadStateDidChange:(NSNotification *)notification
{
#pragma unused(notification)

    if (kMovieLoadStateComplete == [[mMovie attributeForKey:QTMovieLoadStateAttribute] longValue]) {
        if (TRUE == [[mMovie attributeForKey:QTMovieHasAudioAttribute] boolValue]) {
        	if (![mAIFFWriter isConverting]) {
                [mExportButton setTitle:@"Extract & Convert"];
            	[mExportButton setEnabled:TRUE];
            }
        } else {
            NSAlert *alert = [NSAlert alertWithMessageText:@"No Sound Track!"
                                      defaultButton:@"OK"
                                      alternateButton:nil
                                      otherButton:nil
                                      informativeTextWithFormat:@"Open some media that contains audio if you're planing to perform audio extraction/conversion."];
            
            [mExportButton setTitle:@"Extract & Convert"];
            [mExportButton setEnabled:FALSE];
            [alert runModal];
        }
    } else {
        [mExportButton setEnabled:FALSE];
    }
}

#pragma mark ---- window delegates ----

// don't close the window right in the middle of writing the AIFF file
- (BOOL)windowShouldClose:(id)sender
{
#pragma unused(sender)

    if ([mAIFFWriter isConverting]) return NO;
    
    return YES;
}

#pragma mark ---- application delegates ----

// split when window is closed
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
#pragma unused(sender)

    return YES;
}

// handle the situation when a user may quit the application right in the middle
// of an export operation -- we wait for completion then quit
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender;
{
#pragma unused(sender)

    if ([mAIFFWriter isConverting]) {
        mAppIsQuitting = YES;
        return NSTerminateLater;
    } else {
        return NSTerminateNow;
    }
}

@end