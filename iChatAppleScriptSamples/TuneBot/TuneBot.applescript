(*

File: TuneBot.applescript

Abstract: This script demonstrates an AppleScript "Message Received" handler for iChat. It will parse incoming messages and control iTunes in response.

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
	
	-- Basic "Current track" message to use as a default response message.
	on getCurrentiTunesTrack()
		
		-- start with "not playing," just in case.
		set theCurrentTrackMessage to "Not playing."
		
		tell application "iTunes"
			if player state is playing then
				
				-- response to "status" message is of the form "Now playing "<Song>" by <Artist>"
				set theCurrentTrackMessage to "Now playing \"" & (name of current track) & "\""
				
				-- if artist is missing, use track title only.
				if (artist of the current track) is not missing value then
					set theCurrentTrackMessage to theCurrentTrackMessage & " by " & (artist of the current track)
				end if
				
				-- add a message if the volume is muted
				if mute then
					set theCurrentTrackMessage to theCurrentTrackMessage & " (muted)"
				end if
			end if
		end tell
		
		return theCurrentTrackMessage
		
	end getCurrentiTunesTrack
	
	
	-- handler to respond to all incoming messages.
	on runTuneBot(theMessage)
		
		-- use default "unknown" command, just in case.
		set theResponse to "Unknown command."
		
		if theMessage is "status" then
			
			-- "status" command displays current track
			set theResponse to getCurrentiTunesTrack()
			
		else if theMessage is "next" then
			
			-- "next" command moves to next track.		
			tell application "iTunes"
				next track
			end tell
			
			-- set the response message and add the status.
			set theResponse to "Playing next track. " & getCurrentiTunesTrack()
			
		else if theMessage is "previous" then
			
			-- "previous" track moves to previous track.
			tell application "iTunes"
				previous track
			end tell
			set theResponse to "Playing previous track. " & getCurrentiTunesTrack()
			
		else if theMessage is "mute" then
			
			-- "mute" turns the volume off.
			tell application "iTunes"
				set mute to true
			end tell
			set theResponse to "iTunes muted. " & getCurrentiTunesTrack()
			
		else if theMessage is "unmute" then
			
			-- "unmute" turns the volume on.
			tell application "iTunes"
				set mute to false
			end tell
			set theResponse to "iTunes unmuted. " & getCurrentiTunesTrack()
			
		else if theMessage is "play" then
			
			-- "play" tells iTunes to start playing.
			tell application "iTunes"
				play
			end tell
			set theResponse to getCurrentiTunesTrack()
			
		else if theMessage is "pause" then
			
			-- "pause" pauses the current track.
			tell application "iTunes"
				pause
			end tell
			set theResponse to "Paused. " & getCurrentiTunesTrack()
			
		else if theMessage is "help" then
			
			-- display available commands on "help"
			set theResponse to "Available commands: status, next, previous, mute, unmute, help, play, pause"
			
		end if
		
		return theResponse
	end runTuneBot
	
	-- When first message is received, accept the invitation and send a greeting message from TuneBot.
	on received text invitation theMessage from buddy theBuddy for service theService for chat theChat
		tell theChat
			accept invitation
			post message "Welcome to TuneBot. " & runTuneBot("help")
		end tell
	end received text invitation
	
	-- On subsequent messages, pass the message directly to TuneBot.
	on message received theMessage from buddy theBuddy for service theService for chat theChat
		
		-- run the TuneBot parser.
		set theResponse to runTuneBot(theMessage)
		
		-- send back the response.
		tell theChat
			post message theResponse
		end tell
		
	end message received
	
	-- Sample, so you can test run this through Script Editor.
	display dialog "Send a command to TuneBot:" default answer "status"
	set theMessage to the text returned of the result
	set theResponse to runTuneBot(theMessage)
	display dialog theResponse
	
end using terms from