/*
     File: Controller.m 
 Abstract: Main controller for the SBSendEmail sample. 
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
  
 Copyright (C) 2011 Apple Inc. All Rights Reserved. 
  
 */

#import <CoreServices/CoreServices.h>
#import "Controller.h"
#import "Mail.h"


@interface Controller (delegate) <SBApplicationDelegate>
@end

@implementation Controller


@synthesize toField, fromField, subjectField, messageContent, fileAttachmentField;


- (void)awakeFromNib {
	
    [self.messageContent setFont:[NSFont fontWithName:@"Courier" size:12]];

}


- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
	return YES;
}


/* Part of the SBApplicationDelegate protocol.  Called when an error occurs in
 Scripting Bridge method. */
- (id)eventDidFail:(const AppleEvent *)event withError:(NSError *)error
{
    [[NSAlert alertWithMessageText:@"Error" defaultButton:@"OK" alternateButton:nil otherButton:nil
         informativeTextWithFormat: @"%@", [error localizedDescription]] runModal];
    return nil;
}


- (IBAction)chooseFileAttachment:(id)sender {
	NSOpenPanel *op = [NSOpenPanel openPanel];
	
		/* allow directories */
	[op setCanChooseDirectories:YES];
	
		/* single file selections */
	[op setAllowsMultipleSelection:NO];
	[op setCanChooseFiles: YES];
    
    [op setAllowedFileTypes:[NSArray arrayWithObjects: @"gif", @"jpg", @"pdf", @"png", @"rtf", @"txt", @"zip", nil]];
	
		/* run the open panel */
	NSInteger openResult = [op runModal];
	
		/* save the selection, if a file/directory was chosen */
	if ( NSOKButton == openResult ) {
		[self.fileAttachmentField setStringValue: [[op URLs] objectAtIndex:0]];
	}
}




- (IBAction)sendEmailMessage:(id)sender {

		/* create a Scripting Bridge object for talking to the Mail application */
	MailApplication *mail = [SBApplication applicationWithBundleIdentifier:@"com.apple.Mail"];
    
        /* set ourself as the delegate to receive any errors */
    mail.delegate = self;
	
		/* create a new outgoing message object */
	MailOutgoingMessage *emailMessage = [[[mail classForScriptingClass:@"outgoing message"] alloc] initWithProperties:
                                                [NSDictionary dictionaryWithObjectsAndKeys:
                                                    [self.subjectField stringValue], @"subject",
                                                    [[self.messageContent textStorage] string], @"content",
                                                    nil]];
				
		/* add the object to the mail app  */
	[[mail outgoingMessages] addObject: emailMessage];

		/* set the sender, show the message */
	emailMessage.sender = [self.fromField stringValue];
	emailMessage.visible = YES;
    
        /* Test for errors */
    if ( [mail lastError] != nil )
        return;
				
		/* create a new recipient and add it to the recipients list */
	MailToRecipient *theRecipient = [[[mail classForScriptingClass:@"to recipient"] alloc] initWithProperties:
                                        [NSDictionary dictionaryWithObjectsAndKeys:
                                            [self.toField stringValue], @"address",
                                            nil]];
	[emailMessage.toRecipients addObject: theRecipient];
    [theRecipient release];
    
        /* Test for errors */
    if ( [mail lastError] != nil )
        return;
	
		/* add an attachment, if one was specified */
	NSString *attachmentFilePath = [self.fileAttachmentField stringValue];
	if ( [attachmentFilePath length] > 0 ) {
        MailAttachment *theAttachment;
        
            /* In Snow Leopard, the fileName property requires an NSString representing the path to the 
             * attachment.  In Lion, the property has been changed to require an NSURL.   */
        SInt32 osxMinorVersion;
        Gestalt(gestaltSystemVersionMinor, &osxMinorVersion);
        
            /* create an attachment object */
        if ( osxMinorVersion >= 7 )
            theAttachment = [[[mail classForScriptingClass:@"attachment"] alloc] initWithProperties:
                                    [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSURL URLWithString:attachmentFilePath], @"fileName",
                                        nil]];
        else
            /* The string we read from the text field is a URL so we must create an NSURL instance with it
             * and retrieve the old style file path from the NSURL instance. */
            theAttachment = [[[mail classForScriptingClass:@"attachment"] alloc] initWithProperties:
                                    [NSDictionary dictionaryWithObjectsAndKeys:
                                            [[NSURL URLWithString:attachmentFilePath] path], @"fileName",
                                            nil]];
						
			/* add it to the list of attachments */
		[[emailMessage.content attachments] addObject: theAttachment];
        
        [theAttachment release];
        
            /* Test for errors */
        if ( [mail lastError] != nil )
            return;
	}
		/* send the message */
	[emailMessage send];
    
    [emailMessage release];
}

@end
