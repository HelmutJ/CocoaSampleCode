/*

File: SpeakingTextWindow.h

Abstract: The main window hosting all the apps speech features.

Version: 1.4

Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
Inc. ("Apple") in consideration of your agreement to the
following terms, and your use, installation, modification or
redistribution of this Apple software constitutes acceptance of these
terms.  If you do not agree with these terms, please do not use,
install, modify or redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and
subject to these terms, Apple grants you a personal, non-exclusive
license, under Apple's copyrights in this original Apple software (the
"Apple Software"), to use, reproduce, modify and redistribute the Apple
Software, with or without modifications, in source and/or binary forms;
provided that if you redistribute the Apple Software in its entirety and
without modifications, you must retain this notice and the following
text and disclaimers in all such redistributions of the Apple Software. 
Neither the name, trademarks, service marks or logos of Apple Inc.
may be used to endorse or promote products derived from the Apple
Software without specific prior written permission from Apple.  Except
as expressly stated in this notice, no other rights or licenses, express
or implied, are granted by Apple herein, including but not limited to
any patent rights that may be infringed by your derivative works or by
other works in which the Apple Software may be incorporated.

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

Copyright © 2000-2007 Apple Inc. All Rights Reserved

*/

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#import <unistd.h>
#import <sys/stat.h>
#import <fcntl.h>

#import "SpeakingCharacterView.h"

@interface SpeakingTextWindow : NSDocument
{
    // Main window outlets
    IBOutlet NSWindow		*fWindow;
    IBOutlet NSTextView 	*fSpokenTextView;
    IBOutlet NSTextField 	*fAPIVersionStaticField;
    IBOutlet NSButton 		*fStartStopButton;
    IBOutlet NSButton 		*fPauseContinueButton;
    IBOutlet NSButton 		*fSaveAsFileButton;

    // Options panel outlets
    IBOutlet NSButton 		*fImmediatelyRadioButton;
    IBOutlet NSButton 		*fAfterWordRadioButton;
    IBOutlet NSButton 		*fAfterSentenceRadioButton;
    IBOutlet NSPopUpButton 	*fVoicesPopUpButton;
    IBOutlet NSButton 		*fCharByCharCheckboxButton;
    IBOutlet NSButton 		*fDigitByDigitCheckboxButton;
    IBOutlet NSButton 		*fPhonemeModeCheckboxButton;
    IBOutlet NSButton 		*fDumpPhonemesButton;
    IBOutlet NSButton 		*fUseDictionaryButton;

    // Parameters panel outlets
    IBOutlet NSTextField 	*fRateDefaultEditableField;
    IBOutlet NSTextField 	*fPitchBaseDefaultEditableField;
    IBOutlet NSTextField 	*fPitchModDefaultEditableField;
    IBOutlet NSTextField 	*fVolumeDefaultEditableField;
    IBOutlet NSTextField 	*fRateCurrentStaticField;
    IBOutlet NSTextField 	*fPitchBaseCurrentStaticField;
    IBOutlet NSTextField 	*fPitchModCurrentStaticField;
    IBOutlet NSTextField 	*fVolumeCurrentStaticField;
    IBOutlet NSButton 		*fResetButton;
	
	// Callbacks panel outlets
    IBOutlet NSButton 		*fHandleWordCallbacksCheckboxButton;
    IBOutlet NSButton 		*fHandlePhonemeCallbacksCheckboxButton;
    IBOutlet NSButton 		*fHandleSyncCallbacksCheckboxButton;
    IBOutlet NSButton 		*fHandleErrorCallbacksCheckboxButton;
    IBOutlet NSButton 		*fHandleSpeechDoneCallbacksCheckboxButton;
    IBOutlet NSButton 		*fHandleTextDoneCallbacksCheckboxButton;
	IBOutlet SpeakingCharacterView *fCharacterView;

    // Misc. instance variables
    NSRange			fOrgSelectionRange;
    long			fSelectedVoiceID;
    long			fSelectedVoiceCreator;
    SpeechChannel		fCurSpeechChannel;
    long			fOffsetToSpokenText;
    unsigned long		fLastErrorCode;
    BOOL			fLastSpeakingValue;
    BOOL			fLastPausedValue;
    BOOL			fCurrentlySpeaking;
    BOOL			fCurrentlyPaused;
    BOOL			fSavingToFile;
    NSData			*fTextData;
    NSString			*fTextDataType;
}

    // Initialization/deallocation
- (id)init;
- (void)dealloc;

    // Getters/Setters
- (void)setTextData:(NSData *)theData;
- (NSData *)textData;
- (void)setTextDataType:(NSString *)theData;
- (NSString *)textDataType;
- (SpeakingCharacterView *)characterView;
- (BOOL)shouldDisplayWordCallbacks;
- (BOOL)shouldDisplayPhonemeCallbacks;
- (BOOL)shouldDisplayErrorCallbacks;
- (BOOL)shouldDisplaySyncCallbacks;
- (BOOL)shouldDisplaySpeechDoneCallbacks;
- (BOOL)shouldDisplayTextDoneCallbacks;

    // UI routines.
- (void)awakeFromNib;
- (void)highlightWordWithParams:(NSDictionary *)params;
- (void)displayErrorAlertWithParams:(NSDictionary *)params;
- (void)displaySyncAlertWithMessage:(NSNumber *)messageNumber;
- (void)speechIsDone;
- (void)displayTextDoneAlert;

    // Main window actions
- (IBAction)startStopButtonPressed:(id)sender;
- (IBAction)saveAsButtonPressed:(id)sender;
- (IBAction)pauseContinueButtonPressed:(id)sender;
- (OSErr)createNewSpeechChannel:(VoiceSpec *)voiceSpec;
- (void)startSpeakingTextViewToURL:(NSURL *)url;

    // Options panel actions
- (IBAction)voicePopupSelected:(id)sender;
- (IBAction)charByCharCheckboxSelected:(id)sender;
- (IBAction)digitByDigitCheckboxSelected:(id)sender;
- (IBAction)phonemeModeCheckboxSelected:(id)sender;
- (IBAction)dumpPhonemesSelected:(id)sender;
- (IBAction)useDictionarySelected:(id)sender;
- (void)enableOptionsForSpeakingState:(BOOL)speakingNow;

    // Parameters panel actions
- (IBAction)rateChanged:(id)sender;
- (IBAction)pitchBaseChanged:(id)sender;
- (IBAction)pitchModChanged:(id)sender;
- (IBAction)volumeChanged:(id)sender;
- (IBAction)resetSelected:(id)sender;
- (void)fillInEditableParameterFields;

	// Callbacks panel actions
- (IBAction)wordCallbacksButtonPressed:(id)sender;
- (IBAction)phonemeCallbacksButtonPressed:(id)sender;
- (void)enableCallbackControlsBasedOnSavingToFileFlag:(BOOL)savingToFile;

@end
