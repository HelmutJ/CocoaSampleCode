/*
 
 File: PluginAppCategory.h
 
 Abstract: Declarations for the NSApplication category provided
 by the scripting plugin.  This category is used to extend the scripting
 functionality of the host application's application class.
 
 Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by 
 Apple Inc. ("Apple") in consideration of your agreement to the
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
 Neither the name, trademarks, service marks or logos of Apple Inc. 
 may be used to endorse or promote products derived from the Apple
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
 
 Copyright (C) 2009 Apple Inc. All Rights Reserved. 
 
 */

#import <Cocoa/Cocoa.h>
#import "Mattress.h"


@interface NSApplication (ScriptingPlugin)


/* kvc methods for the 'Mattresses' AppleScript element.  Here we implement the methods
 necessary for maintaining the list of Mattresses inside of the application container.
 Note the names. In our scripting definition file we specified that the application container
 class contains an element of type 'mattress', like so:
 <element type="mattress"/>
 Cocoa will use the plural form of the class name when naming the property used by
 AppleScript to access the list of Mattresses, and we should use the property name
 when naming our methods.  So, using the property name, we name our methods as follows:
 - (NSArray *)mattresses;
 - (void)insertInMattresses:(id)mattress;
 - (void)insertInMattresses:(id)mattress atIndex:(unsigned)index;
 - (void)removeFromMattressesAtIndex:(unsigned)index;
 
 */

	/* return the entire list of Mattresses */
- (NSArray *)mattresses;

	/* insert a mattress at the beginning of the list */
- (void)insertInMattresses:(id)mattress;

	/* insert a mattress at some position in the list */
- (void)insertInMattresses:(id)mattress atIndex:(unsigned)index;

	/* remove a mattress from the list */
- (void)removeFromMattressesAtIndex:(unsigned)index;



- (NSNumber *)valuable;


	/* The following methods are called by Cocoa scripting in response
	 to the randomize weight and randomize value AppleScript commands when
	 they are sent to the application object. */

- (void)setRandomWeight:(NSScriptCommand *)command;

- (void)setRandomValue:(NSScriptCommand *)command;
	
@end
