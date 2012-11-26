/*
 
 File: rot13.c
 
 Abstract: A very simple example of plugin for the Authorization
	API that shows the most basic way to write a plugin. This plugin will
	read the password that the user typed in and perform a ROT13 on it.
	The password is read from the authorization hints.
 
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

#include <stdlib.h>
#include <string.h>
#include <syslog.h>

#include <Security/AuthorizationTags.h>
#include <Security/AuthorizationPlugin.h>


typedef struct PluginRef
{
    const AuthorizationCallbacks *callbacks;
} PluginRef;

typedef enum MechanismId
{
    kMechNone,
    kMechRot13
} MechanismId;

typedef struct MechanismRef
{
    const PluginRef *plugin;
    AuthorizationEngineRef engine;
    MechanismId mechanismId;
} MechanismRef;


/* Example transformation code. */

static void do_rot13(void *dest, const void *src, size_t length)
{
    char *d = (char *)dest;
    const char *s  = (const char *)src;
    char *end = d + length;

    for (; d < end; ++d, ++s)
    {
        int ch = *s;
        if (ch >= 'a' && ch <= 'z')
        {
            ch += 13;
            if (ch > 'z')
                ch -= 26;
        }

        *d = ch;
    }
}

/**
 *   A simple non-UI mechanism.
 */
static OSStatus invokeRot13(MechanismRef *mechanism)
{
    AuthorizationContextFlags contextFlags;
    const AuthorizationValue *value;
    AuthorizationValue newValue = {};
    OSStatus status;

    status = mechanism->plugin->callbacks->GetContextValue(mechanism->engine, kAuthorizationEnvironmentPassword,
        &contextFlags, &value);
    if (status)
        return status;

    newValue.length = value->length;
    newValue.data = malloc(newValue.length);
    do_rot13(newValue.data, value->data, newValue.length);

    syslog(LOG_ERR, "old: %*s new: %*s", (int)value->length, (const char *)value->data,
        (int)newValue.length, (const char *)newValue.data);

    status = mechanism->plugin->callbacks->SetContextValue(mechanism->engine, kAuthorizationEnvironmentPassword,
        contextFlags, &newValue);
    if (newValue.data)
        free(newValue.data);

    return status;
}

static OSStatus pluginDestroy(AuthorizationPluginRef inPlugin)
{
    PluginRef *plugin = (PluginRef *)inPlugin;
    free(plugin);
    return 0;
}

static OSStatus mechanismCreate(AuthorizationPluginRef inPlugin,
        AuthorizationEngineRef inEngine,
        AuthorizationMechanismId mechanismId,
        AuthorizationMechanismRef *outMechanism)
{
    const PluginRef *plugin = (const PluginRef *)inPlugin;

    MechanismRef *mechanism = calloc(1, sizeof(MechanismRef));

    mechanism->plugin = plugin;
    mechanism->engine = inEngine;

    if (!strcmp(mechanismId, "none"))
        mechanism->mechanismId = kMechNone;
    else if (!strcmp(mechanismId, "rot13"))
        mechanism->mechanismId = kMechRot13;
    else
        return errAuthorizationInternal;

    *outMechanism = mechanism;

    return 0;
}


/**
 *   Time to perform our part in the authorization.  Either a nop, or we 
 *   put the entered password through a rot13 operation.
 */
static OSStatus mechanismInvoke(AuthorizationMechanismRef inMechanism)
{
    MechanismRef *mechanism = (MechanismRef *)inMechanism;
    OSStatus status;

    switch (mechanism->mechanismId)
    {
		case kMechNone:
			break;
		case kMechRot13:
			status = invokeRot13(mechanism);
			if (status)
				return status;
			break;
		default:
			return errAuthorizationInternal;
    }

    return mechanism->plugin->callbacks->SetResult(mechanism->engine, kAuthorizationResultAllow);
}


/**
 *   Since a authorization result is provided within invoke, we don't have to 
 *   cancel a long(er) term operation that might have been spawned.
 */
static OSStatus mechanismDeactivate(AuthorizationMechanismRef inMechanism)
{
    return 0;
}


/**
 *   Clean up resources.
 */
static OSStatus mechanismDestroy(AuthorizationMechanismRef inMechanism)
{
    MechanismRef *mechanism = (MechanismRef *)inMechanism;
    free(mechanism);

    return 0;
}


/**
 *  The interface our plugin advertises.  Notice that it uses a constant 
 *  to specify which interface version was used.
 */
AuthorizationPluginInterface pluginInterface =
{
    kAuthorizationPluginInterfaceVersion, //UInt32 version;
    pluginDestroy,
    mechanismCreate,
    mechanismInvoke,
    mechanismDeactivate,
    mechanismDestroy
};


/**
 *  Entry point for all plugins.  Plugin and the host loading it exchange interfaces.
 *  Normally you'd allocate resources shared amongst all mechanisms here.
 *  When a plugin is created it may not necessarily be used, so be conservative.
 */
OSStatus AuthorizationPluginCreate(const AuthorizationCallbacks *callbacks,
    AuthorizationPluginRef *outPlugin,
    const AuthorizationPluginInterface **outPluginInterface)
{
    PluginRef *plugin = calloc(1, sizeof(PluginRef));

    plugin->callbacks = callbacks;
    *outPlugin = (AuthorizationPluginRef) plugin;
    *outPluginInterface = &pluginInterface;
    return 0;
}

