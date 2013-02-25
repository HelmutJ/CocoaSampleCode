/*
 
 File: GetMetadataForFile.m
 
 Abstract: Spotlight importer for com.example.fortune-cookie UTI
 
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
 
 Copyright (C) 2008 Apple Inc. All Rights Reserved.
 
 */

#import <Foundation/Foundation.h>


/*
 
 IMPORTANT: Do NOT create a Spotlight importer project of your own by copying
 and modifying this project! Use Xcode's Spotlight Plug-In template instead.
 The template will generate a unique PLUGIN_ID (UUID) for your importer.
 Launch Services and Spotlight use this UUID to identify your plug-in, and to
 maintian its UTI associations. The results of different importers sharing
 the same PLUGIN_ID are undefined.
 
 */

Boolean GetMetadataForFile(void* thisInterface, 
			   CFMutableDictionaryRef attributes, 
			   CFStringRef contentTypeUTI,
			   CFStringRef pathToFile)

{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    Boolean status = FALSE;
    NSDictionary * plist = [NSDictionary dictionaryWithContentsOfFile:(id)pathToFile];
    if (plist != nil) {
        [(id)attributes setObject:[plist objectForKey:@"fortuneID"]
                           forKey:@"com_example_fortuneID"];
        [(id)attributes setObject:[plist objectForKey:@"date"]
                           forKey:(id)kMDItemTimestamp];
        [(id)attributes setObject:[plist objectForKey:@"text"]
                           forKey:(id)kMDItemDisplayName];
        [(id)attributes setObject:[plist objectForKey:@"text"]
                           forKey:(id)kMDItemTextContent];
        status = TRUE;
    }
    [pool release];
    return status;
}
