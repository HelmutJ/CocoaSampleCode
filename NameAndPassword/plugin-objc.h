/*

File: plugin-objc.h

Abstract: Plugin and Mechanism Header

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

*/

#import <Foundation/Foundation.h>
#import <Security/Authorization.h>
#import <Security/AuthorizationTags.h>
#import <Security/AuthorizationPlugin.h>

#ifndef __H_PLUGIN_OBJC__
#define __H_PLUGIN_OBJC__


@interface EXAuthorizationPlugin : NSObject
{
@protected
	AuthorizationCallbacks *mEngineInterface;
@private
	void *_internal;
}

-(id)initWithCallbacks:(const AuthorizationCallbacks *)callbacks pluginInterface:(const AuthorizationPluginInterface **)interface;
-(id)setCallbacks:(const AuthorizationCallbacks *)callbacks pluginInterface:(const AuthorizationPluginInterface **)interface;

-(AuthorizationCallbacks*)engineCallback;

// factory method: create mechanisms for this plugin based on mechanismId
-(id)mechanism:(AuthorizationMechanismId)mechanismId engineRef:(AuthorizationEngineRef)inEngine;

@end


@interface EXAuthorizationMechanism : NSObject
{
@protected
	EXAuthorizationPlugin *mPluginRef; // AuthorizationPluginRef
	AuthorizationEngineRef mEngineRef;
@private
	void *_internal;
}

- (id)init;
- (id)initWithPlugin:(EXAuthorizationPlugin*)plugin engineRef:(AuthorizationEngineRef)engine;

- (OSStatus)invoke;
- (OSStatus)deactivate;

- (OSStatus)requestInterrupt;
- (OSStatus)setResult:(AuthorizationResult)inResult;
- (OSStatus)didDeactivate;

- (OSStatus)getContext:(AuthorizationString)inKey flags:(AuthorizationContextFlags *)outContextFlags value:(const AuthorizationValue **)outValue;
- (OSStatus)setContext:(AuthorizationString)inKey flags:(AuthorizationContextFlags)inContextFlags value:(const AuthorizationValue *)inValue;
- (OSStatus)getHint:(AuthorizationString)inKey value:(const AuthorizationValue **)outValue;
- (OSStatus)setHint:(AuthorizationString)inKey value:(const AuthorizationValue *)inValue;
- (OSStatus)getArguments:(const AuthorizationValueVector **)outArguments;
- (OSStatus)getSession:(AuthorizationSessionId *)outSessionId;

@end 


@interface EXAuthorizationMechanism ( ConvenienceAccessors )

- (NSData *)hintNSData:(const char *)inKey;
- (NSData *)contextNSData:(const char *)inKey;
- (NSString *)contextString:(const char *)inKey;
- (void)setContextString:(NSString *)value withFlags:(AuthorizationFlags)flags forKey:(const char *)inKey;
- (NSString *)hintString:(const char *)inKey;
- (void)setHintString:(NSString *)value forKey:(const char *)inKey;
- (BOOL)hintData:(uint8_t*)data withSize:(size_t)size forKey:(const char *)inKey;
- (BOOL)contextData:(uint8_t*)data withSize:(size_t)size withFlags:(AuthorizationContextFlags*)flags forKey:(const char *)inKey;
- (BOOL)setContextData:(uint8_t*)data withSize:(size_t)size withFlags:(AuthorizationContextFlags)flags forKey:(const char *)inKey;

@end


#endif /* __H_PLUGIN_OBJC__ */
		

