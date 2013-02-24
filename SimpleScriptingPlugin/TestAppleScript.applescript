(*

File: SimpleScriptingObjects.applescript

Abstract: a test applescript for testing the
SimpleScriptingProperties application.

Version: 1.0

© Copyright 2007 Apple Computer, Inc. All rights reserved.

IMPORTANT:  This Apple software is supplied to 
you by Apple Computer, Inc. ("Apple") in 
consideration of your agreement to the following 
terms, and your use, installation, modification 
or redistribution of this Apple software 
constitutes acceptance of these terms.  If you do 
not agree with these terms, please do not use, 
install, modify or redistribute this Apple 
software.

In consideration of your agreement to abide by 
the following terms, and subject to these terms, 
Apple grants you a personal, non-exclusive 
license, under Apple's copyrights in this 
original Apple software (the "Apple Software"), 
to use, reproduce, modify and redistribute the 
Apple Software, with or without modifications, in 
source and/or binary forms; provided that if you 
redistribute the Apple Software in its entirety 
and without modifications, you must retain this 
notice and the following text and disclaimers in 
all such redistributions of the Apple Software. 
Neither the name, trademarks, service marks or 
logos of Apple Computer, Inc. may be used to 
endorse or promote products derived from the 
Apple Software without specific prior written 
permission from Apple.  Except as expressly 
stated in this notice, no other rights or 
licenses, express or implied, are granted by 
Apple herein, including but not limited to any 
patent rights that may be infringed by your 
derivative works or by other works in which the 
Apple Software may be incorporated.

The Apple Software is provided by Apple on an "AS 
IS" basis.  APPLE MAKES NO WARRANTIES, EXPRESS OR 
IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED 
WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY 
AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING 
THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE 
OR IN COMBINATION WITH YOUR PRODUCTS.

IN NO EVENT SHALL APPLE BE LIABLE FOR ANY 
SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL 
DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS 
OF USE, DATA, OR PROFITS; OR BUSINESS 
INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, 
REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF 
THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER 
UNDER THEORY OF CONTRACT, TORT (INCLUDING 
NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN 
IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF 
SUCH DAMAGE.

*)


tell application "SimpleScriptingPlugin"
	
	set theTrinket to make new trinket with properties {name:"my trinket", weight:7}
	tell theTrinket
		randomize weight starting from 10 ranging to 80
	end tell
	--return properties of theTrinket
	
	
	-- create a new treasure object
	set theTreasure to make new treasure with properties {name:"my treasure", weight:20.2, value:13}
	tell theTreasure
		randomize weight starting from 10 ranging to 80
		randomize value starting from 100 ranging to 2000
	end tell
	
	
	-- create a new mattress object
	set theMattress to make new mattress with properties {name:"my mattress"}
	
	-- hide some treasure in it
	tell theMattress
		set theTreasure to make new treasure with properties {name:"my treasure", weight:20.2, value:13}
		set theTreasure to make new treasure with properties {name:"another treasure", weight:20.2, value:13}
		-- randomize the value of the treasures in the mattress
		randomize value starting from 100 ranging to 2000
	end tell
	
	
	
	-- create a new trinket object
	set theTrinket to make new trinket with properties {name:"my trinket", weight:7}
	
	-- create a new light weight trinket object
	set theLightTrinket to make new trinket with properties {name:"my light weight trinket", weight:2}
	
	-- create a new light weight trinket object
	set theFeatherWeightTrinket to make new trinket with properties {name:"my feather weight trinket", weight:1}
	
	-- create a new treasure object
	set theTreasure to make new treasure with properties {name:"my treasure", weight:20.2, value:13}
	
	-- create a new bucket object
	set theBucket to make new bucket with properties {name:"my bucket object"}
	
	-- add some items to our bucket object
	tell theBucket
		make new trinket with properties {name:"my trinket in the bucket", weight:21}
		make new treasure with properties {name:"my treasure in the bucket", weight:21.3, value:7}
	end tell
	
	-- create a strong box
	set theStrongBox to make new strong box with properties {name:"my strong box object"}
	
	-- add some items to the strong box, moving our bucket into the strong box
	tell theStrongBox
		make new trinket with properties {name:"my trinket in the strong box", weight:3}
		make new treasure with properties {name:"my treasure in the strong box", weight:14, value:28}
		set nestedBucket to make new bucket with properties {name:"my bucket in the strong box"}
		tell nestedBucket
			make new trinket with properties {name:"my bucketed trinket", weight:3}
			make new treasure with properties {name:"my bucketed treasure", weight:12, value:5}
		end tell
	end tell
	
	-- comment/uncomment the following lines to try out the objects in our app
	
	-- report the properties of the first bucket in the first strong box
	properties of item 1 of buckets of item 1 of strong boxes
	
	-- report the properties of the first trinket in the first bucket in the first strong box
	properties of item 1 of trinkets of item 1 of buckets of item 1 of strong boxes
	
	-- find name of every trinket whose weight is... well, the script says what we want
	the name of (every trinket whose weight is less than 3)
	(* note: every time we run this script we'll be making some
	new trinkets, so this list will grow as you run the script
	again and again. *)
	
	-- report the properties of the application
	properties
	
	(* report the weight and value of all of the treasures
	and trinkets contained in the app.  note, these properties are calculated
	'on the fly' so they will be up*)
	{weight, value}
	(* note: every time we run this script we'll be making some
	new trinkets, treasures, buckets, and strong boxes, so these values
	will grow every time you run this script. *)
	
	-- the value of the first treasure in the first bucket in the first strong box
	the value of item 1 of treasures of item 1 of buckets of item 1 of strong boxes
end tell



