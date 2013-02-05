
(*

     File: AttachedScripts.applescript
 Abstract: These are the AppleScripts called by the main program.  This file is compiled
 at build time into the file AttachedScripts.scpt.  We have added two new build
 phases to accomplish this.
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
 
			
*)




(* AttachedScripts.applescript

These are the AppleScripts called by the main program.  This file is compiled
at build time into the file AttachedScripts.scpt.  We have added two new build
phases to accomplish this.


1. The first build phase executes this command:

    osacompile -d -o AttachedScripts.scpt AttachedScripts.applescript

This command compiles this source file 'AttachedScripts.applescript' saving the result
in the data fork of the file 'AttachedScripts.scpt'.


2. The second build phase simply copies both of the files 'AttachedScripts.scpt'
and 'AttachedScripts.applescript' into the final application's resources directory.


IMPORTANT:  I have noticed that you need to 'clean' the build
before it will copy the compiled versions of these files over
to the resources directory.  



Some interesting points to make here are:

(a) if at any time you want to reconfigure your application so that the scripts
do different things you can do so by editing this file and recompiling it to the
.scpt file using this command:
    osacompile -d -o AttachedScripts.scpt AttachedScripts.applescript

(b) everything here is datafork based and does not require any resource forks.  As
such,  it's easily transportable to other file systems.

(c) Recompiling this script file does not require recompilation of your main
program, but it can significantly enhance the configurability of your application.
As well, it can defer some design and interoperability decisions until later in
the development cycle.  Want to swap in a different app for some special task?
Just rewrite the script, your main program doesn't have to know about it...

(d) recompiling this script is even something that daring advanced users
with special requirements may want to do.

(c) because the main program only loads the precompiled
'AttachedScripts.scpt' your application does not bear any of the runtime
compilation costs that are involved.  From the application's point of
view, it's just 'Load and go...'.

*)




(* HookUpToRemoteMachine 
our app calls this script at application startup time.  In this handler
we present the url selection dialog allowing the user to select
a remote machine where the iTunes application we want to control
is running.  We store the remote machine address in the script's
property 'theRemoteURL' that is used by all of the other handlers
to direct commands to the iTunes app.  This handler returns the error
number if an error ocurred or 0 indicating sucess. *)

property theRemoteURL : ""

on HookUpToRemoteMachine()
	try
		set theURL to choose URL showing Remote applications
		using terms from application "iTunes"
			tell application "iTunes" of machine theURL
				set localVariable to sound volume (* try some command to verify the connection *)
			end tell
		end using terms from
		set theRemoteURL to theURL
		return 0
	on error errmsg number errNum
		return errNum
	end try
end HookUpToRemoteMachine


(* ReportRemoteVolume 
This handler calls the remote iTunes application to obtain the current
volume setting - an integer value between 0 and 100.  NOTE:  this
is the volume setting inside of iTunes and it is not the same
as the output volume setting for the entire remote machine. *)
on ReportRemoteVolume()
	set theVolume to 0
	using terms from application "iTunes"
		tell application "iTunes" of machine theRemoteURL
			set theVolume to sound volume
		end tell
	end using terms from
	return theVolume
end ReportRemoteVolume


(* SetRemoteVolume 
This handler calls the remote iTunes application to obtain the current
volume setting - an integer value between 0 and 100.  NOTE:  this
is the volume setting inside of iTunes and it is not the same
as the output volume setting for the entire remote machine. *)
on SetRemoteVolume(newVolume)
	using terms from application "iTunes"
		tell application "iTunes" of machine theRemoteURL
			set sound volume to newVolume
		end tell
	end using terms from
end SetRemoteVolume


(* ReportRemotePlayerState 
This handler calls the remote iTunes application to obtain the current
status of the player - a list of seven elements including
playing (0 or 1), playlist, track, position, duration,
statusstr, and volume .  *)
on ReportRemotePlayerState()
	set theResult to {0, "", "", 0, 0, "Not Playing", 0}
	using terms from application "iTunes"
		tell application "iTunes" of machine theRemoteURL
			if player state is playing then
				-- set up the status string
				set statusStr to "Playing '" & name of current track & "' by '"
				set statusStr to statusStr & artist of current track & "' from playlist '"
				set statusStr to statusStr & name of current playlist & "'"
				-- put together the result list
				set theResult to {1, name of current playlist, name of current track}
				set theResult to theResult & {player position, duration of current track}
				set theResult to theResult & {statusStr, sound volume}
			else
				set theResult to {0, "", "", 0, 0, "Not Playing", sound volume}
			end if
		end tell
	end using terms from
	return theResult
end ReportRemotePlayerState


(* GongCurrentTrack is called when the user clicks on the
gong button.  This handler disables the track that is currently
playing and skips ahead to the next track.  If the player is not
playing, this handler does nothing.  *)
on GongCurrentTrack()
	using terms from application "iTunes"
		tell application "iTunes" of machine theRemoteURL
			if player state is playing then
				set enabled of current track to false
				next track
			end if
		end tell
	end using terms from
end GongCurrentTrack


(* SwitchRemotePlayerState is called when the user clicks on the
play/pause button.  This routine simply turns the remote player on
or off.  *)
on SwitchRemotePlayerState(newState)
	using terms from application "iTunes"
		tell application "iTunes" of machine theRemoteURL
			if (newState is equal to 1) then
				play
			else
				pause
			end if
		end tell
	end using terms from
end SwitchRemotePlayerState


(* GoToNextTrack is called when the user clicks on the
skip ahead button.  This routine advances the player to the
next track.  *)
on GoToNextTrack()
	using terms from application "iTunes"
		tell application "iTunes" of machine theRemoteURL
			next track
		end tell
	end using terms from
end GoToNextTrack


(* GoToPreviousTrack is called when the user clicks on the
skip back button.  This routine asks the player to go back
to the previous track.  *)
on GoToPreviousTrack()
	using terms from application "iTunes"
		tell application "iTunes" of machine theRemoteURL
			previous track
		end tell
	end using terms from
end GoToPreviousTrack


(* GetPlaylistListing is called during program startup to retrieve
a list of the names of all of all of the playlists on the remote machine.  *)
on GetPlaylistListing()
	set nameList to {}
	using terms from application "iTunes"
		tell application "iTunes" of machine theRemoteURL
			set nameList to get name of every playlist
		end tell
	end using terms from
	return nameList
end GetPlaylistListing


(* PlayTrackFromPlaylist is when the user double clicks on a track name
in the track list.  This handler receives a playlist name and the name of
the track and it asks the player to play that track. *)
on PlayTrackFromPlaylist(playlistName, trackName)
	using terms from application "iTunes"
		tell application "iTunes" of machine theRemoteURL
			tell source "Library"
				tell playlist playlistName
					tell track trackName
						play
					end tell
				end tell
			end tell
		end tell
	end using terms from
end PlayTrackFromPlaylist


(* GetPlaylistTracks is called when ever the user clicks on a new playlist
name in the list of displayed playlists.  Here we return a list containing
all of the names of the tracks in the selected playlist. *)
on GetPlaylistTracks(playlistName)
	set theTracks to {}
    try
	using terms from application "iTunes"
		tell application "iTunes" of machine theRemoteURL
			tell source "Library"
				tell playlist playlistName
					set theTracks to get name of every track
				end tell
			end tell
		end tell
	end using terms from
    on error
        return theTracks
    end try
	return theTracks
end GetPlaylistTracks


(* GetPlaylistShuffle returns an integer value (0 or 1) reflecting
the status of the shuffle setting for the named playlist.  *)
on GetPlaylistShuffle(playlistName)
	set shuffleSetting to 0
	using terms from application "iTunes"
		tell application "iTunes" of machine theRemoteURL
			tell source "Library"
				tell playlist playlistName
					if shuffle then
						set shuffleSetting to 1
					else
						set shuffleSetting to 0
					end if
				end tell
			end tell
		end tell
	end using terms from
	return shuffleSetting
end GetPlaylistShuffle


(* SetPlaylistShuffle changes the current shuffle setting for
the named playlist to shuffleSetting.  shuffleSetting should
be an integer value of either 0 (for off) or 1 (for on). *)
on SetPlaylistShuffle(playlistName, shuffleSetting)
	using terms from application "iTunes"
		tell application "iTunes" of machine theRemoteURL
			tell source "Library"
				tell playlist playlistName
					if shuffleSetting is equal to 1 then
						set shuffle to true
					else
						set shuffle to false
					end if
				end tell
			end tell
		end tell
	end using terms from
end SetPlaylistShuffle


(* GetPlaylistRepeat returns an integer value of 0, for repeat off,
1, for repeat all, or 2, for repeat one, reflecting the state of
the repeat setting for the named playlist.   *)
on GetPlaylistRepeat(playlistName)
	set repeatSetting to 0
	using terms from application "iTunes"
		tell application "iTunes" of machine theRemoteURL
			tell source "Library"
				tell playlist playlistName
					if (song repeat is off) then
						set repeatSetting to 0
					else if (song repeat is all) then
						set repeatSetting to 1
					else if (song repeat is one) then
						set repeatSetting to 2
					end if
				end tell
			end tell
		end tell
	end using terms from
	return repeatSetting
end GetPlaylistRepeat


(* SetPlaylistRepeat is called to change the repeat setting
for the named playlist.  repeatSetting should be a either
0, 1 or 2 representing 'repeat off', 'repeat all', or 
'repeat one' respectively.  *)
on SetPlaylistRepeat(playlistName, repeatSetting)
	using terms from application "iTunes"
		tell application "iTunes" of machine theRemoteURL
			tell source "Library"
				tell playlist playlistName
					if (repeatSetting is equal to 0) then
						set song repeat to off
					else if (repeatSetting is equal to 1) then
						set song repeat to all
					else if (repeatSetting is equal to 2) then
						set song repeat to one
					end if
				end tell
			end tell
		end tell
	end using terms from
end SetPlaylistRepeat


