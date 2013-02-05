/*
     File: TAttachedScripts.m 
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

#import "TAttachedScripts.h"
#import "AEDescUtils.h"


	/* RemotePlayerState is an aggregate of status information returned
	by the getRemotePlayerState method defined in the TAttachedScripts
	class below */
@implementation RemotePlayerState

@synthesize isPlaying;
@synthesize theTrack;
@synthesize thePlaylist;
@synthesize positionInTrack;
@synthesize trackDuration;
@synthesize playerStatusString;
@synthesize playerVolume;

-(id)init {
    self = [super init];
	if (self) {
		
	}
	return self;
}

-(void) dealloc {
	self.theTrack = nil;
    self.thePlaylist = nil;
    self.playerStatusString = nil;
	[super dealloc];
}

@end





@implementation TAttachedScripts


	/* HookUpToRemoteMachine 
	our app calls this script at application startup time.  In this handler
	we present the url selection dialog allowing the user to select
	a remote machine where the iTunes application we want to control
	is running.  We store the remote machine address in the script's
	property 'theRemoteURL' that is used by all of the other handlers
    to direct commands to the iTunes app.  This handler returns the error
    number if an error ocurred or 0 indicating sucess.  */
- (id) init {

    /* create an NSURL to our scripts file */
	NSBundle* bundle = [NSBundle mainBundle];
	NSURL *scriptURL = [[[NSURL alloc] initFileURLWithPath:[bundle pathForResource:@"AttachedScripts" ofType:@"scpt"]] autorelease];
	
    /* attempt to load thes scripts file */
    self = [super initWithURLToCompiledScript:scriptURL];
	if (self) {
		
        /* if we loaded the scripts file, attempt to hook up to the remote host */
        NSInteger result = [[self callHandler:@"HookUpToRemoteMachine" withParameters:nil] int32Value];
		if ( result ) {
            NSString* errorString = [NSString stringWithFormat:@"Failed to Connect to remote machine. (Error %i)", result];
			NSRunAlertPanel(@"AttachAScript Error", errorString, @"ok", nil, nil);
            return nil;
		}
		
	}
	
	return self;
}




	/* ReportRemoteVolume 
	This handler calls the remote iTunes application to obtain the current
	volume setting - an integer value between 0 and 100.  NOTE:  this
	is the volume setting inside of iTunes and it is not the same
	as the output volume setting for the entire remote machine. */
- (int) remoteVolume {

	int theVolume;
	
		/* call the AppleScript handler ReportRemoteVolume to retrieve the current
		volume setting for the named playlist. */
	theVolume = [[self callHandler:@"ReportRemoteVolume" withParameters:nil] int32Value];
	
		/* return the volume setting value */
	return theVolume;
	
}



	/* SetRemoteVolume 
	This handler calls the remote iTunes application to obtain the current
	volume setting - an integer value between 0 and 100.  NOTE:  this
	is the volume setting inside of iTunes and it is not the same
	as the output volume setting for the entire remote machine. */
-(void) setRemoteVolume: (int) newVolume {
	
		/* Call the AppleScript SetRemoteVolume handler to change the volume setting */
	[self callHandler:@"SetRemoteVolume" withParameters:
			[NSNumber numberWithLong:newVolume], nil];
	
}




	/* updatePlayerStatus calls the AppleScript handler ReportRemotePlayerState that
	returns a seven member list of items containing the following information: */
enum {
	kIsPlaying = 1, /* player state (playing=1, not playing = 0) */
	kCurrentPlaylist = 2, /* name of current playlist (only if playing) */
	kCurrentTrack = 3, /* name of current track (only if playing) */
	kPlayerPosition = 4, /* player position (seconds from start of track, only if playing) */
	kTrackDuration = 5, /* duration of current track (total seconds in track, only if playing) */
	kPlayerStatusDescription = 6, /* a text string describing the player's state */
	kSoundVolume = 7 /* sound volume (0 thru 100) */
};



	/* ReportRemotePlayerState 
	This handler calls the remote iTunes application to obtain the current
	status of the player - a list of seven elements including
	playing (0 or 1), playlist, track, position, duration,
	statusstr, and volume . */
- (RemotePlayerState*) getRemotePlayerState {

	RemotePlayerState *statusInfo;
		
		/* call ReportRemotePlayerState to retrieve the remote player's status */
	NSAppleEventDescriptor* playerInfo = [self callHandler:@"ReportRemotePlayerState" withParameters:nil];
	
		/* allocate a new status object */
	statusInfo = [[[RemotePlayerState alloc] init] autorelease];
	
		/* save our remote player state information into the status object */
	statusInfo.isPlaying = ([[playerInfo descriptorAtIndex:kIsPlaying] int32Value] != 0);
		/* track/playlist names */
	statusInfo.theTrack = [[playerInfo descriptorAtIndex:kCurrentTrack] stringValue];
	statusInfo.thePlaylist = [[playerInfo descriptorAtIndex:kCurrentPlaylist] stringValue];
		/* track position information */
	statusInfo.positionInTrack = [[playerInfo descriptorAtIndex:kPlayerPosition] int32Value];
	statusInfo.trackDuration = [[playerInfo descriptorAtIndex:kTrackDuration] int32Value];
		/* overall status description string */
	statusInfo.playerStatusString = [[playerInfo descriptorAtIndex:kPlayerStatusDescription] stringValue];
		/* player volume */
	statusInfo.playerVolume = [[playerInfo descriptorAtIndex:kSoundVolume] int32Value];
	
		/* return the status information */
	return statusInfo;
	
}



	/* GongCurrentTrack is called when the user clicks on the
	gong button.  This handler disables the track that is currently
	playing and skips ahead to the next track.  If the player is not
	playing, this handler does nothing.  */
-(void) gongCurrentTrack {

		/* call the GongCurrentTrack handler */
	[self callHandler:@"GongCurrentTrack" withParameters:nil];
	
}



	/* SwitchRemotePlayerState is called when the user clicks on the
	play/pause button.  This routine simply turns the remote player on
	or off.  */
- (void) setRemotePlayerState:(BOOL) playerState {
	
		/* call the SwitchRemotePlayerState AppleScript handler to set the new player state */
	[self callHandler:@"SwitchRemotePlayerState" withParameters:
		[NSNumber numberWithLong:( playerState ? 1 : 0 )], nil];
		
}



	/* GoToNextTrack is called when the user clicks on the
	skip ahead button.  This routine advances the player to the
	next track.  */
- (void) goToNextTrack {
	
		/* call the GoToNextTrack AppleScript handler */
	[self callHandler:@"GoToNextTrack" withParameters:nil];
	
}



	/* GoToPreviousTrack is called when the user clicks on the
	skip back button.  This routine asks the player to go back
	to the previous track.  */
- (void) goToPreviousTrack {

		/* call the GoToPreviousTrack AppleScript handler */
	[self callHandler:@"GoToPreviousTrack" withParameters:nil];
	
}



	/* getPlaylists is called during program startup to retrieve
	a list of the names of all of all of the playlists on the remote machine.  */
- (NSArray*) getPlaylists {

	return [[self callHandler:@"GetPlaylistListing" withParameters:nil]
			listOfStringsToSortedArray];

}




	/* PlayTrackFromPlaylist is when the user double clicks on a track name
	in the track list.  This handler receives a playlist name and the name of
	the track and it asks the player to play that track. */
- (void) playTrack: (NSString*) trackName fromPlaylist:(NSString*) playlistName {
				
		/* ask the remote iTunes app to play the selected track. */
	[self callHandler:@"PlayTrackFromPlaylist" withParameters: playlistName, trackName, nil];

}



	/* GetPlaylistTracks is called when ever the user clicks on a new playlist
	name in the list of displayed playlists.  Here we return a list containing
	all of the names of the tracks in the selected playlist. */
- (NSArray*) getTracksForPlaylist: (NSString*) playlistName {

	NSArray* theTracks;
		
		/* call the remote host to obtain a list of tracks in the named playlist. */
	theTracks = [[self callHandler:@"GetPlaylistTracks" withParameters:playlistName, nil]
					listOfStringsToSortedArray];
					
		/* return the track names */
	return theTracks;
}




	/* GetPlaylistShuffle returns an integer value (0 or 1) reflecting
	the status of the shuffle setting for the named playlist.  */
- (int) getShuffleForPlaylist: (NSString*) playlistName {

	int shuffleSetting;
		
		/* call the AppleScript handler GetPlaylistShuffle to retrieve the current
		shuffle setting for the named playlist. */
	shuffleSetting = [[self callHandler:@"GetPlaylistShuffle" withParameters:playlistName, nil]
						int32Value];
	
		/* return the shuffle setting value */
	return shuffleSetting;
}




	/* SetPlaylistShuffle changes the current shuffle setting for
	the named playlist to shuffleSetting.  shuffleSetting should
	be an integer value of either 0 (for off) or 1 (for on). */
- (void) setShuffle: (int) shuffleSetting forPlaylist: (NSString*) playlistName {
	
		/* call the AppleScript SetPlaylistShuffle handler to set the new shuffle setting. */
	[self callHandler:@"SetPlaylistShuffle" withParameters:playlistName,
							[NSNumber numberWithLong:shuffleSetting], nil];

}




	/* GetPlaylistRepeat returns an integer value of 0, for repeat off,
	1, for repeat all, or 2, for repeat one, reflecting the state of
	the repeat setting for the named playlist.   */
- (int) getRepeatForPlaylist: (NSString*) playlistName {
	
	int repeatSetting;
	
		/* call the GetPlaylistRepeat handler in the AppleScript to find out the current setting */
	repeatSetting = [[self callHandler:@"GetPlaylistRepeat" withParameters:playlistName, nil] int32Value];
		
		/* return the repeat setting value */
	return repeatSetting;
}




	/* SetPlaylistRepeat is called to change the repeat setting
	for the named playlist.  repeatSetting should be a either
	0, 1 or 2 representing 'repeat off', 'repeat all', or 
	'repeat one' respectively.  */
- (void) setRepeat: (int) repeatSetting forPlaylist: (NSString*) playlistName {
	
		/* call the SetPlaylistRepeat AppleScript handler to set the new repeat setting */
	[self callHandler:@"SetPlaylistRepeat" withParameters:playlistName, 
				[NSNumber numberWithLong:repeatSetting], nil];

}



@end


