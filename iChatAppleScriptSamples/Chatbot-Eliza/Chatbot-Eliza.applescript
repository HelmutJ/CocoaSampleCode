(*

File: Chatbot-Eliza.applescript

Abstract: The script demonstrates an AppleScript "Message Received" handler for iChat. It takes a message and passes it onto Eliza, a virtual psychotherapist.

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

*)

using terms from application "iChat"
	
	on runChatbotEliza(theMessage)
		
		-- Set this to the path of your Chatbot::Eliza installation.
		-- Set to null if Chatbot-Eliza is installed through CPAN.
		set elizaScriptDir to POSIX path of (((path to desktop) as string) & "Chatbot-Eliza-1.04")
		
		-- Set this to the path to the iChat.pl that uses Chatbot::Eliza.
		set elizaScript to POSIX path of (((path to home folder) as string) & "Library:Scripts:iChat:Chatbot-Eliza.pl")
		
		set theScriptCommand to ""
		
		-- shell script will vary if Chatbot::Eliza is installed through CPAN.
		if elizaScriptDir is null then
			set theScriptCommand to "perl " & elizaScript & " \"" & (theMessage as string) & "\""
		else
			set theScriptCommand to "perl -I" & elizaScriptDir & " " & elizaScript & " \"" & (theMessage as string) & "\""
		end if
		
		-- Run the shell script and grab the output.		
		set theResponse to do shell script theScriptCommand
		
		return theResponse
		
	end runChatbotEliza
	
	-- When first message is received, accept the invitation and send a greeting message from Eliza.
	on received text invitation theMessage from buddy theBuddy for service theService for chat theChat
		tell theChat
			accept invitation
			post message "Hello! What can I help you with today?"
		end tell
	end received text invitation
	
	-- On subsequent messages, pass the message directly to Eliza.
	on message received theMessage from buddy theBuddy for service theService for chat theChat
		set theResponse to runChatbotEliza(theMessage)
		tell theChat
			post message theResponse
		end tell
	end message received
	
	-- Sample, so you can test run this through Script Editor.
	display dialog "Say something to Eliza:" default answer "Hello, Eliza!"
	set theMessage to the text returned of the result
	set theResponse to runChatbotEliza(theMessage)
	display dialog theResponse
	
end using terms from
