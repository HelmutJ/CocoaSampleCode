    File: ReadMe.txt
Abstract: n/a
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

Copyright (C) 2012 Apple Inc. All Rights Reserved.


 * Your app and its login items must all be App Sandboxed.  For your app, this
   is as simple as checking the "Enable Entitlements" and "Enable App
   Sandboxing" checkboxes in the Summary tab of the target.  For login items,
   this means creating your own entitlements plist file and referencing that
   file from the "Code Signing Entitlements" key in the login items' build
   settings.  See iDecideHelper/iDecideHelper.entitlements for an example.

 * The bundle identifier of a login item must start with your Team ID.  For
   example:
   
	XYZABC1234.com.example.iDecideHelper
	-----^----
     Team Id

   Your app's bundle identifier does not need to be prefixed with your Team ID.

 * Login items must have filenames that match their bundle identifiers.
   For example, a login item with the bundle identifier
   "XYZABC1234.com.example.iDecideHelper" would have a filename of 
   "XYZABC1234.com.example.iDecideHelper.app" and live in your app's
   Contents/Library/LoginItems folder.  The actual extension on your login
   item bundle need not be ".app".

 * In order to communicate with each other, your app and its login items must
   declare themselves to be part of the same "application group".  This is
   accomplished by adding an com.apple.security.application-groups entitlement.
   The value of this entitlement is an array of bundle identifier prefixes.
   Add an entry in this array that matches the bundle identifier of your login
   item.  For example:
   
	<key>com.apple.security.application-groups</key>
	<array>
		<string>XYZABC1234.com.example</string>
	</array>

 * Changes to login items will not take effect immediately.  To test changes
   to the login item, you will need to manually stop the job using launchctl
   from a Terminal window.  For example:

	launchctl stop XYZABC1234.com.example.iDecideHelper

