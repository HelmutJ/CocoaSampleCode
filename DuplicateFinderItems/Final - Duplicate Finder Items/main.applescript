(*

File: main.applescript

Abstract: Implementation for Duplicate Finder Items Automator action

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

Copyright © 2005 Apple Computer, Inc., All Rights Reserved

*)

on run {input, parameters}
	
	-- read settings from user interface
	set to_location to (|toLocation| of parameters)
	set return_duplicate_items to (|returnDuplicateItems| of parameters) as boolean
	
	-- convert POSIX path possibly containing a ~ to an AppleScript alias
	if to_location is not "" then -- AMPathPopUpButton returns an empty string for placeholder selection 
		try
			set target_folder to call method "stringByExpandingTildeInPath" of to_location
			set target_folder to (POSIX file target_folder)
			set target_folder to target_folder as alias
		on error
			error number -43 from the target_folder
		end try
	end if
	
	set duplicate_Finder_items to {}
	
	if to_location is "" then -- if the user left the To: popup set to 'Same folder'
		tell application "Finder" to duplicate input
	else
		tell application "Finder" to duplicate input to target_folder
	end if
	
	set duplicate_Finder_items to the result
	
	if return_duplicate_items then
		-- convert the Finder reference for each duplicate item to an AppleScript alias
		set duplicate_item_aliases to {}
		if class of duplicate_Finder_items is list then
			tell application "System Events"
				repeat with i from 1 to number of items of duplicate_Finder_items
					set the end of duplicate_item_aliases to (item i of duplicate_Finder_items) as alias
				end repeat
			end tell
			return duplicate_item_aliases
		else -- result was a single Finder item, not a list
			-- but this action promises in its Output (AMProvides) Container setting to provide a list to the next action
			return {duplicate_Finder_items as alias}
		end if
	end if
	
	return input
end run