/*

File: AnnotationPanel.h

Abstract: <Description, Points of interest, Algorithm approach>

Version: 1.0

Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
Computer, Inc. ("Apple") in consideration of your agreement to the
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
Neither the name, trademarks, service marks or logos of Apple Computer,
Inc. may be used to endorse or promote products derived from the Apple
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

Copyright © 2006 Apple Computer, Inc., All Rights Reserved

*/ 

// ======================================================================================================================
//  AnnotationPanel.h
// ======================================================================================================================


#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>


// Notification.
extern NSString *AnnotationPanelAnnotationDidChangeNotification;


@interface AnnotationPanel : NSPanel
{
	PDFAnnotation			*_annotation;
	BOOL					_ignoreTextEnter;
	
	IBOutlet NSPanel		*_annotationPanel;
	IBOutlet NSTextField	*_subtypeLabel;
	IBOutlet NSTabView		*_attributesView;
	
	IBOutlet NSTextField	*_buttonFieldName;		// Widget (Button)
	IBOutlet NSMatrix		*_controlType;
	IBOutlet NSTextField	*_onValue;
	IBOutlet NSButton		*_buttonHasBGColor;
	IBOutlet NSColorWell	*_buttonBGColor;
	IBOutlet NSButton		*_buttonHasColor;
	IBOutlet NSColorWell	*_buttonColor;
	
	IBOutlet NSTextField	*_choiceFieldName;		// Widget (Choice)
	
	IBOutlet NSTextField	*_circleContents;		// Circle, Square
	IBOutlet NSColorWell	*_circleColor;
	IBOutlet NSButton		*_circleHasInteriorColor;
	IBOutlet NSColorWell	*_circleInteriorColor;
	
	IBOutlet NSTextField	*_freeTextContents;		// Free Text
	IBOutlet NSColorWell	*_freeTextColor;
	IBOutlet NSColorWell	*_freeTextFontColor;

	IBOutlet NSTextField	*_inkContents;			// Ink
	IBOutlet NSColorWell	*_inkColor;
	
	IBOutlet NSTextField	*_lineContents;			// Line
	IBOutlet NSColorWell	*_lineColor;
	IBOutlet NSButton		*_lineHasInteriorColor;
	IBOutlet NSColorWell	*_lineInteriorColor;
	IBOutlet NSPopUpButton	*_startStyle;
	IBOutlet NSPopUpButton	*_endStyle;
	
	IBOutlet NSButton		*_linkHasDestination;	// Link
	IBOutlet NSTextField	*_linkPage;
	IBOutlet NSTextField	*_linkPointX;
	IBOutlet NSTextField	*_linkPointY;
	IBOutlet NSButton		*_linkHasColor;
	IBOutlet NSColorWell	*_linkColor;
	
	IBOutlet NSTextField	*_markupContents;		// Markup
	IBOutlet NSColorWell	*_markupColor;
	IBOutlet NSPopUpButton	*_markupType;
	
	IBOutlet NSTextField	*_stampContents;		// Stamp
	IBOutlet NSTextField	*_stampName;
	
	IBOutlet NSTextField	*_textContents;			// Text
	IBOutlet NSColorWell	*_textColor;
	IBOutlet NSPopUpButton	*_textIcon;
	IBOutlet NSButton		*_textIsOpen;
	
	IBOutlet NSTextField	*_textFieldName;		// Widget (Text)
	IBOutlet NSTextField	*_maxLen;
	IBOutlet NSPopUpButton	*_textAlignment;
	IBOutlet NSButton		*_textHasBGColor;
	IBOutlet NSColorWell	*_textBGColor;
	
	IBOutlet NSButton		*_displayFlag;			// Flags
	IBOutlet NSButton		*_printFlag;
	
	IBOutlet NSPopUpButton	*_actionType;			// Actions
	IBOutlet NSTabView		*_actionView;
	
	IBOutlet NSTextField	*_gotoPage;				// Go To Action
	IBOutlet NSButton		*_hasGotoPointX;
	IBOutlet NSButton		*_hasGotoPointY;
	IBOutlet NSTextField	*_gotoPointX;
	IBOutlet NSTextField	*_gotoPointY;
	
	IBOutlet NSPopUpButton	*_actionName;			// Named Action
	
	IBOutlet NSButton		*_resetExclude;			// Reset Form Action
	IBOutlet NSTextField	*_resetText;
	
	IBOutlet NSTextField	*_actionURL;			// URL Action
	
	IBOutlet NSButton		*_hasBorder;			// Border
	IBOutlet NSTextField	*_thickness;
	IBOutlet NSButton		*_dashed;
}

+ (AnnotationPanel *) sharedAnnotationPanel;
- (void) setAnnotation: (PDFAnnotation *) annotation;

- (void) setFieldName: (id) sender;
- (void) setButtonType: (id) sender;
- (void) setOnValue: (id) sender;
- (void) setHasBackgroundColor: (id) sender;
- (void) setBGColor: (id) sender;
- (void) setContents: (id) sender;
- (void) setHasColor: (id) sender;
- (void) setColor: (id) sender;
- (void) setHasInteriorColor: (id) sender;
- (void) setInteriorColor: (id) sender;
- (void) setFontColor: (id) sender;
- (void) setStartStyle: (id) sender;
- (void) setEndStyle: (id) sender;
- (void) setLinkHasDestination: (id) sender;
- (void) setLinkPage: (id) sender;
- (void) setLinkPointX: (id) sender;
- (void) setLinkPointY: (id) sender;
- (void) setMarkupType: (id) sender;
- (void) setStampName: (id) sender;
- (void) setTextIcon: (id) sender;
- (void) setIsOpen: (id) sender;
- (void) setMaxLen: (id) sender;
- (void) setAlignment: (id) sender;

- (void) setPrint: (id) sender;
- (void) setDisplay: (id) sender;

- (void) setActionType: (id) sender;
- (void) setActionPage: (id) sender;
- (void) setHasActionPointX: (id) sender;
- (void) setHasActionPointY: (id) sender;
- (void) setActionPointX: (id) sender;
- (void) setActionPointY: (id) sender;
- (void) setActionName: (id) sender;
- (void) setResetExclude: (id) sender;
- (void) setResetFields: (id) sender;
- (void) setActionURL: (id) sender;

- (void) setHasBorder: (id) sender;
- (void) setThickness: (id) sender;
- (void) setDashed: (id) sender;

@end