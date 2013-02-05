/*
     File: TAttachedScripts.h
 Abstract: A subclass of the TCallScript class providing
 an Objective-C interface to the handlers defined in the
 AttachedScripts.scpt file.
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

#import <Cocoa/Cocoa.h>
#import "TCallScript.h"



enum {
	kRepeatOff = 0,
	kRepeatAll = 1,
	kRepeatOne = 2
};


	/* RemotePlayerState is an aggregate of status information returned
	by the getRemotePlayerState method defined in the TAttachedScripts
	class below */
@interface RemotePlayerState : NSObject {
	BOOL isPlaying;  /* true if the remote player is playing */
	NSString* theTrack;  /* name of the track being played, only if isPlaying is true */
	NSString* thePlaylist;  /* name of the track's playlist, only if isPlaying is true */
	int positionInTrack;  /* seconds, only if isPlaying is true */
	int trackDuration;  /* seconds, only if isPlaying is true */
	NSString* playerStatusString;
	int playerVolume; /* 0 - 100 */
}
- (id) init;
- (void) dealloc;

@property (readwrite) BOOL isPlaying;
@property (copy) NSString *theTrack;
@property (copy) NSString *thePlaylist;
@property (readwrite) int positionInTrack;
@property (readwrite) int trackDuration;
@property (copy) NSString *playerStatusString;
@property (readwrite) int playerVolume;

@end





@interface TAttachedScripts : TCallScript {
	/* no additional slots required for this subclass */
}


	/* init 
	our app calls this script at application startup time.  In this handler
	we present the url selection dialog allowing the user to select
	a remote machine where the iTunes application we want to control
	is running.  We store the remote machine address in the script's
	property 'theRemoteURL' that is used by all of the other handlers
	to direct commands to the iTunes app.  This handler returns an
	integer value (1 or 0) indicating success or failure.  */
- (id) init;



	/* remoteVolume 
	This handler calls the remote iTunes application to obtain the current
	volume setting - an integer value between 0 and 100.  NOTE:  this
	is the volume setting inside of iTunes and it is not the same
	as the output volume setting for the entire remote machine. */
- (int) remoteVolume;


	/* setRemoteVolume: 
	This handler calls the remote iTunes application to obtain the current
	volume setting - an integer value between 0 and 100.  NOTE:  this
	is the volume setting inside of iTunes and it is not the same
	as the output volume setting for the entire remote machine. */
-(void) setRemoteVolume: (int) newVolume;


	/* getRemotePlayerState 
	This handler calls the remote iTunes application to obtain the current
	status of the player - a list of seven elements including
	playing (0 or 1), playlist, track, position, duration,
	statusstr, and volume . */
- (RemotePlayerState*) getRemotePlayerState;


	/* gongCurrentTrack is called when the user clicks on the
	gong button.  This handler disables the track that is currently
	playing and skips ahead to the next track.  If the player is not
	playing, this handler does nothing.  */
-(void) gongCurrentTrack;


	/* setRemotePlayerState is called when the user clicks on the
	play/pause button.  This routine simply turns the remote player on
	or off.  */
- (void) setRemotePlayerState:(BOOL) newState;


	/* goToNextTrack is called when the user clicks on the
	skip ahead button.  This routine advances the player to the
	next track.  */
- (void) goToNextTrack;


	/* goToPreviousTrack is called when the user clicks on the
	skip back button.  This routine asks the player to go back
	to the previous track.  */
- (void) goToPreviousTrack;


	/* getPlaylists is called during program startup to retrieve
	a list of the names of all of all of the playlists on the remote machine.  */
- (NSArray*) getPlaylists;


	/* playTrack:fromPlaylist: is when the user double clicks on a track name
	in the track list.  This handler receives a playlist name and the name of
	the track and it asks the player to play that track. */
- (void) playTrack: (NSString*) trackName fromPlaylist:(NSString*) playlistName;


	/* getTracksForPlaylist: is called when ever the user clicks on a new playlist
	name in the list of displayed playlists.  Here we return a list containing
	all of the names of the tracks in the selected playlist. */
- (NSArray*) getTracksForPlaylist: (NSString*) playlistName;


	/* getShuffleForPlaylist: returns an integer value (0 or 1) reflecting
	the status of the shuffle setting for the named playlist.  */
- (int) getShuffleForPlaylist: (NSString*) playlistName;


	/* setShuffle:forPlaylist: changes the current shuffle setting for
	the named playlist to shuffleSetting.  shuffleSetting should
	be an integer value of either 0 (for off) or 1 (for on). */
- (void) setShuffle: (int) shuffleSetting forPlaylist: (NSString*) playlistName;


	/* getRepeatForPlaylist: returns an integer value of 0, for repeat off,
	1, for repeat all, or 2, for repeat one, reflecting the state of
	the repeat setting for the named playlist.   */
- (int) getRepeatForPlaylist: (NSString*) playlistName;


	/* setRepeat:forPlaylist: is called to change the repeat setting
	for the named playlist.  repeatSetting should be a either
	0, 1 or 2 representing 'repeat off', 'repeat all', or 
	'repeat one' respectively.  */
- (void) setRepeat: (int) repeatSetting forPlaylist: (NSString*) playlistName;



@end
