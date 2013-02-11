/*
    File:       NullAuthPlugin.c

    Contains:   An empty authorization plug-in, for logging and testing.

    Written by: DTS

    Copyright:  Copyright (c) 2010 Apple Inc. All Rights Reserved.

    Disclaimer: IMPORTANT: This Apple software is supplied to you by Apple Inc.
                ("Apple") in consideration of your agreement to the following
                terms, and your use, installation, modification or
                redistribution of this Apple software constitutes acceptance of
                these terms.  If you do not agree with these terms, please do
                not use, install, modify or redistribute this Apple software.

                In consideration of your agreement to abide by the following
                terms, and subject to these terms, Apple grants you a personal,
                non-exclusive license, under Apple's copyrights in this
                original Apple software (the "Apple Software"), to use,
                reproduce, modify and redistribute the Apple Software, with or
                without modifications, in source and/or binary forms; provided
                that if you redistribute the Apple Software in its entirety and
                without modifications, you must retain this notice and the
                following text and disclaimers in all such redistributions of
                the Apple Software. Neither the name, trademarks, service marks
                or logos of Apple Inc. may be used to endorse or promote
                products derived from the Apple Software without specific prior
                written permission from Apple.  Except as expressly stated in
                this notice, no other rights or licenses, express or implied,
                are granted by Apple herein, including but not limited to any
                patent rights that may be infringed by your derivative works or
                by other works in which the Apple Software may be incorporated.

                The Apple Software is provided by Apple on an "AS IS" basis. 
                APPLE MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING
                WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT,
                MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING
                THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
                COMBINATION WITH YOUR PRODUCTS.

                IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT,
                INCIDENTAL OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
                TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
                DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY
                OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION
                OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY
                OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR
                OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF
                SUCH DAMAGE.

*/

/////////////////////////////////////////////////////////////////////

#include <CoreServices/CoreServices.h>
#include <DirectoryService/DirectoryService.h>

#include <Security/AuthorizationPlugin.h>
#include <Security/AuthSession.h>
#include <Security/AuthorizationTags.h>

#include <syslog.h>
#include <unistd.h>

/////////////////////////////////////////////////////////////////////

// During development, you can define DEBUGLOG to call printf, and GCC 
// will type check your arguments for you (GCC is smart enough to 
// interpret printf format strings, but not smart enough to know 
// that syslog format strings are virtually identical).
//
// In the standard configuration, all of my debug output goes to syslog.
// To see this output:
//
// 1. Edit /etc/syslog.conf and insert the following line at beginning.
//
// *.debug     /var/log/debug.log
//
// IMPORTANT:
// In the above line the two fields ("*.debug" and "/var/log/debug.log") must be 
// separated by a tab character.
//
// 2. Send syslogd a SIGHUP.
//
//    $ sudo kill -HUP `cat /var/run/syslog.pid`
//
// 3. Read the system log.
//
//    $ tail -f /var/log/debug.log

#if 1
    #define DEBUGLOG(...) syslog(LOG_DEBUG, __VA_ARGS__);
#else
    #warning Don't forget to reenable syslog.
    #define DEBUGLOG(...) printf(__VA_ARGS__);
#endif

/////////////////////////////////////////////////////////////////////
#pragma mark ***** Core Data Structures

typedef struct PluginRecord PluginRecord;           // forward decl

#pragma mark *     Mechanism

// MechanismRecord is the per-mechanism data structure.  One of these 
// is created for each mechanism that's instantiated, and holds all 
// of the data needed to run that mechanism.  In this trivial example, 
// that data set is very small.
//
// Mechanisms are single threaded; the code does not have to guard 
// against multiple threads running inside the mechanism simultaneously.

enum {
    kMechanismMagic = 'Mchn'
};

struct MechanismRecord {
    OSType                          fMagic;         // must be kMechanismMagic
    AuthorizationEngineRef          fEngine;
    const PluginRecord *            fPlugin;
    Boolean                         fWaitForDebugger;
};
typedef struct MechanismRecord MechanismRecord;

static Boolean MechanismValid(const MechanismRecord *mechanism)
{
    return (mechanism != NULL)
        && (mechanism->fMagic == kMechanismMagic)
        && (mechanism->fEngine != NULL)
        && (mechanism->fPlugin != NULL);
}

#pragma mark *     Plugin

// PluginRecord is the per-plugin data structure.  As the system only 
// instantiates a plugin once per plugin host, this information could 
// just as easily be kept in global variables.  However, just to keep 
// things tidy, I pushed it all into a single record.
//
// As a plugin may host multiple mechanism, and there's no guarantee 
// that these mechanisms won't be running on different threads, data 
// in this record should be protected from multiple concurrent access. 
// In my case, however, all of the data is read-only, so I don't need 
// to do anything special.

enum {
    kPluginMagic = 'PlgN'
};

struct PluginRecord {
    OSType                          fMagic;         // must be kPluginMagic
    const AuthorizationCallbacks *  fCallbacks;
};

static Boolean PluginValid(const PluginRecord *plugin)
{
    return (plugin != NULL)
        && (plugin->fMagic == kPluginMagic)
        && (plugin->fCallbacks != NULL)
        && (plugin->fCallbacks->version >= kAuthorizationCallbacksVersion);
}

/////////////////////////////////////////////////////////////////////
#pragma mark ***** Mechanism Printing Stuff

// The code in this section is used to pretty print the state of the 
// authorization system when the mechanism is invoked.  This is a lot 
// of code, but it's not very relevant to the authorization plugin 
// mechanism itself (except insofar as it allows you to see what 
// data is being passed around in the context and hints).

// As there is no way to enumerate all of the entries in the context/hints, 
// I just hard-code a big table of likely entries.  The KeyInfo structure 
// is used to hold information about each entry.  As the entries in the 
// context/hints are not typed, I store both the name and the type.
// As I have no idea which keys pertain to which context and which pertain 
// to hints, I try each key in both.  Besides, the push_hints_to_context 
// mechanism implies that they share the same namespace.

enum KeyType {
    kUnknown,
    kString,                    // without null terminator
    kString0,                   // with null terminator
    kPID,                       // pid_t
    kUID,                       // uid_t
    kGID,                       // gid_t
    kOSType,
    kUInt32,
    kSInt32,
    kPlist,
    kPlistOrString              // wacky special case for AuthenticationAuthority
};
typedef enum KeyType KeyType;

struct KeyInfo {
    const char *    fKey;
    KeyType         fType;
};
typedef struct KeyInfo KeyInfo;

static const KeyInfo kStateKeys[] = {

    // IMPORTANT:
    // Only the keys documented in public header files are considered to be 
    // part of the defined API for an authorization plug-in.  The keys that 
    // are defined as literal strings are present for debugging and exploration 
    // purposes only.  Do not use these strings in a 'shrink wrap' authorization 
    // plug-in without first discussing the issue with Apple.  You can either 
    // open a Developer Tech Support incident:
    //
    //   <http://developer.apple.com/technicalsupport/index.html>
    //
    // or ask your question on the Apple-CDSA mailing list:
    //
    //   <http://www.lists.apple.com/apple-cdsa>
    
    // hint keys documented in <Security/AuthorizationTags.h>

    { kAuthorizationEnvironmentUsername,    kString0 },
    { kAuthorizationEnvironmentPassword,    kString0 },
    { kAuthorizationEnvironmentIcon,        kUnknown },
    { kAuthorizationEnvironmentPrompt,      kUnknown },

    // context keys from a typical system (found using debugger)
    
    { "uid",                                kUID     },
    { "gid",                                kGID     },
    { "home",                               kString0 },
    { "longname",                           kString0 },
    { "shell",                              kString0 },

    // hint keys from a typical system (found using debugger)
    
    { "authorize-right",                    kString  },
    { "authorize-rule",                     kString  },
    { "client-path",                        kString  },
    { "client-pid",                         kPID     },
    { "client-type",                        kOSType  },
    { "client-uid",                         kUID     },
    { "creator-pid",                        kPID     },
    { "tries",                              kUInt32  },

    // other keys found by grovelling through source code
    
    { "suggested-user",                     kUnknown },
    { "require-user-in-group",              kUnknown },
    { "reason",                             kUnknown },
    { "token-name",                         kUnknown },
    { "afp_dir",                            kString0 },
    { "kerberos-principal",                 kUnknown },
    { "mountpoint",                         kString0 },
    { "new-password",                       kUnknown },
    { "show-add-to-keychain",               kUnknown },
    { "add-to-keychain",                    kUnknown },
    { "Home_Dir_Mount_Result",              kSInt32  },
    { "homeDirType",                        kSInt32  },
    
    // The getuserinfo authentication mechanism copies all of the user's 
    // Open Directory attributes to the hints (?, or context?).  So we 
    // look for the standard OD user attributes.
    //
    // AFAIK all of these are of type kString (because getuserinfo 
    // only copies across string values), but I've only set the type 
    // to string for those that I've seen in the wild.  The remainder 
    // stay as type kUnknown until I see a concrete example.
    
    { kDS1AttrAdminLimits,                  kUnknown },
    { kDS1AttrAdminStatus,                  kUnknown },
    { kDS1AttrAlternateDatastoreLocation,   kUnknown },
    { kDS1AttrAuthenticationHint,           kUnknown },
    { kDS1AttrChange,                       kUnknown },
    { kDS1AttrComment,                      kUnknown },
    { kDS1AttrDistinguishedName,            kString  },
    { kDS1AttrExpire,                       kUnknown },
    { kDS1AttrFirstName,                    kUnknown },
    { kDS1AttrGeneratedUID,                 kString  },
    { kDS1AttrHomeDirectorySoftQuota,       kUnknown },
    { kDS1AttrHomeDirectoryQuota,           kUnknown },
    { kDS1AttrHomeLocOwner,                 kUnknown },
    { kDS1AttrInternetAlias,                kUnknown },
    { kDS1AttrLastName,                     kString  },
    { kDS1AttrMailAttribute,                kUnknown },
    { kDS1AttrMiddleName,                   kUnknown },
    { kDS1AttrNFSHomeDirectory,             kString  },
    { kDS1AttrOriginalNFSHomeDirectory,     kUnknown },
    { kDS1AttrPassword,                     kString  },
    { kDS1AttrPasswordPlus,                 kString  },
    { kDS1AttrPicture,                      kUnknown },
    { kDS1AttrPrimaryGroupID,               kString  },
    { kDS1AttrRealUserID,                   kString  },
    { kDS1AttrUniqueID,                     kString  },
    { kDS1AttrUserShell,                    kString  },
    { kDSNAttrAddressLine1,                 kUnknown },
    { kDS1StandardAttrHomeLocOwner,         kUnknown },
    { kDSNAttrAddressLine2,                 kUnknown },
    { kDSNAttrAddressLine3,                 kUnknown },
    { kDSNAttrAreaCode,                     kUnknown },
    { kDSNAttrAuthenticationAuthority,      kPlistOrString },
    { kDSNAttrBuilding,                     kUnknown },
    { kDSNAttrCity,                         kUnknown },
    { kDSNAttrCountry,                      kUnknown },
    { kDSNAttrDepartment,                   kUnknown },
    { kDSNAttrEMailAddress,                 kUnknown },
    { kDSNAttrFaxNumber,                    kUnknown },
    { kDSNAttrGroupMembers,                 kUnknown },
    { kDSNAttrGroupMembership,              kUnknown },
    { kDSNAttrHomeDirectory,                kString  },
    { kDSNAttrIMHandle,                     kUnknown },
    { kDSNAttrJobTitle,                     kUnknown },
    { kDSNAttrMobileNumber,                 kUnknown },
    { kDSNAttrNamePrefix,                   kUnknown },
    { kDSNAttrNameSuffix,                   kUnknown },
    { kDSNAttrNestedGroups,                 kUnknown },
    { kDSNAttrNetGroups,                    kUnknown },
    { kDSNAttrNickName,                     kUnknown },
    { kDSNAttrOrganizationName,             kUnknown },
    { kDSNAttrOriginalHomeDirectory,        kUnknown },
    { kDSNAttrPagerNumber,                  kUnknown },
    { kDSNAttrPhoneNumber,                  kUnknown },
    { kDSNAttrPostalAddress,                kUnknown },
    { kDSNAttrPostalCode,                   kUnknown },
    { kDSNAttrState,                        kUnknown },
    { kDSNAttrStreet,                       kUnknown }
};

static void PrintHexData(const char *scope, const char *key, const void *buf, size_t bufSize)
    // Prints the specified buffer as hex.
{
    size_t                  outputSize;
    char *                  output;
    const unsigned char *   bufBase;
    size_t                  bufIndex;
    char                    tmp[16];
 
    assert(scope != NULL);
    assert(key   != NULL);
    assert( (bufSize == 0) || (buf != NULL) );

    // Allocate the correct size buffer.
    
    outputSize = bufSize * 3 + 1;
    output = (char *) malloc(outputSize);
    assert(output != NULL);
    
    if (output != NULL) {
        // Fill the buffer with the hex.
        
        *output = 0;
        
        bufBase = (const unsigned char *) buf;
        for (bufIndex = 0; bufIndex < bufSize; bufIndex++) {
            snprintf(tmp, sizeof(tmp), "%02x ", bufBase[bufIndex]);
            
            strlcat(output, tmp, outputSize);
        }
        
        assert(outputSize == (strlen(output) + 1));

        // Print it.
        
        DEBUGLOG("%s key='%s' value=%s", scope, key, output);
    }
    
    free(output);
}

static void PrintPlist(const char *scope, const char *key, const void *buf, size_t bufSize)
{
    CFDataRef           data;
    CFPropertyListRef   propList;
    CFDataRef           textData;
    CFMutableDataRef    mutableTextData;
    char *              dataBuf;
    CFIndex             dataSize;
    CFIndex             i;

    assert(scope != NULL);
    assert(key   != NULL);
    assert( (bufSize == 0) || (buf != NULL) );

    data = NULL;
    propList = NULL;
    textData = NULL;
    mutableTextData = NULL;
    
    dataBuf = NULL;

    // Create a CFData from the buffer, then a CFPropertyList from the data, 
    // then a text form of the CFPropertyList, then a mutable version of that 
    // ('cause I want to strip newline characters).  *phew*
    
    data = CFDataCreate(NULL, buf, bufSize);
    if (data != NULL) {
        propList = CFPropertyListCreateFromXMLData(NULL, data, kCFPropertyListImmutable, NULL);
        if (propList != NULL) {
            textData = CFPropertyListCreateXMLData(NULL, propList);
            if (textData != NULL) {
                mutableTextData = CFDataCreateMutableCopy(NULL, 0, textData);
                if (mutableTextData != NULL) {
                    dataBuf  = (char *) CFDataGetMutableBytePtr(mutableTextData);
                    dataSize = CFDataGetLength(mutableTextData);
                    for (i = 0; i < dataSize; i++) {
                        if ( (dataBuf[i] == '\r') || (dataBuf[i] == '\n') ) {
                            dataBuf[i] = ' ';
                        }
                    }
                }
            }
        }
    }
    
    // If the above mess worked, print the text, otherwise just dump hex.
    
    if (dataBuf != NULL) {
        DEBUGLOG("%s key='%s', value='%.*s'", scope, key, (int) dataSize, (const char *) dataBuf);
    } else {
        PrintHexData(scope, key, buf, bufSize);
        DEBUGLOG("%s key='%s', value='%.*s'", scope, key, (int) bufSize, (const char *) buf);
    }
    
    // Clean up.

    if (mutableTextData != NULL) {
        CFRelease(mutableTextData);
    }
    if (textData != NULL) {
        CFRelease(textData);
    }
    if (propList != NULL) {
        CFRelease(propList);
    }
    if (data != NULL) {
        CFRelease(data);
    }
}

static void PrintPlistOrString(const char *scope, const char *key, const void *buf, size_t bufSize)
    // Sniffs the buffer and prints it as either a binary plist or a string. 
    // The AuthenticationAuthority context value is one of these formats 
    // depending on whether the mechanism runs before or after 
    // "builtin:getuserinfo", so I have to handle both.
{
    static const char kPlistMagic[] = "bplist00";

    assert(scope != NULL);
    assert(key   != NULL);
    assert( (bufSize == 0) || (buf != NULL) );
    
    // See whether the first eight bytes of the buffer are kPlistMagic.

    if ( (bufSize >= strlen(kPlistMagic)) && (memcmp(buf, kPlistMagic, strlen(kPlistMagic)) == 0) ) {
        // If so, go the plist route.  

        PrintPlist(scope, key, buf, bufSize);
    } else {
        // If it doesn't look like a plist, print it as a string.

        DEBUGLOG("%s key='%s', value='%.*s'", scope, key, (int) bufSize, (const char *) buf);
    }
}

static void PrintTypedData(const char *scope, const char *key, KeyType type, const void *buf, size_t bufSize)
    // Given a typed data buffer, pretty print the contents.
{
    assert(scope != NULL);
    assert(key   != NULL);
    assert( (bufSize == 0) || (buf != NULL) );

    switch (type) {
        default:
            assert(false);
            // fall through
        case kUnknown:
            PrintHexData(scope, key, buf, bufSize);
            break;
        case kString:
            if ( (bufSize > 0) && (((const char *) buf)[bufSize - 1] == 0)) {
                PrintHexData(scope, key, buf, bufSize);     // not expecting a null terminator here
            } else {
                DEBUGLOG("%s key='%s', value='%.*s'", scope, key, (int) bufSize, (const char *) buf);
            }
            break;
        case kString0:
            if ( (bufSize > 0) && (((const char *) buf)[bufSize - 1] == 0)) {

                // By default we log your password as "********".  If you want the real 
                // password to show up in the log, change the following to 1.

                #define kIDontCareIfMyPasswordIsLogged 0
                
                if ( (strcmp(key, "password") == 0) && ! kIDontCareIfMyPasswordIsLogged ) {
                    if (strlen(buf) == 0) {
                        DEBUGLOG("%s key='%s', value=''", scope, key);
                    } else {
                        DEBUGLOG("%s key='%s', value='********'", scope, key);
                    }
                } else {
                    DEBUGLOG("%s key='%s', value='%s'", scope, key, (const char *) buf);
                }
            } else {
                PrintHexData(scope, key, buf, bufSize);
            }
            break;
        case kPID:
            if (bufSize == sizeof(pid_t)) {
                DEBUGLOG("%s key='%s', value=%ld", scope, key, (long) *(pid_t *) buf);
            } else {
                PrintHexData(scope, key, buf, bufSize);
            }
            break;
        case kUID:
            if (bufSize == sizeof(uid_t)) {
                DEBUGLOG("%s key='%s', value=%ld", scope, key, (long) *(uid_t *) buf);
            } else {
                PrintHexData(scope, key, buf, bufSize);
            }
            break;
        case kGID:
            if (bufSize == sizeof(gid_t)) {
                DEBUGLOG("%s key='%s', value=%ld", scope, key, (long) *(gid_t *) buf);
            } else {
                PrintHexData(scope, key, buf, bufSize);
            }
            break;
        case kOSType:
            if (bufSize == sizeof(OSType)) {
                OSType tmp;
                
                // Should convert MacRoman to UTF-8 for each character, but that's 
                // quite hard.
                
                tmp = *(OSType *) buf;
                DEBUGLOG("%s key='%s', value='%c%c%c%c'", scope, key, (UInt8) (tmp >> 24), (UInt8) (tmp >> 16), (UInt8) (tmp >> 8), (UInt8) tmp);
            } else {
                PrintHexData(scope, key, buf, bufSize);
            }
            break;
        case kUInt32:
            if (bufSize == sizeof(UInt32)) {
                DEBUGLOG("%s key='%s', value=%lu", scope, key, (unsigned long) *(UInt32 *) buf);
            } else {
                PrintHexData(scope, key, buf, bufSize);
            }
            break;
        case kSInt32:
            if (bufSize == sizeof(SInt32)) {
                DEBUGLOG("%s key='%s', value=%ld", scope, key, (long) *(SInt32 *) buf);
            } else {
                PrintHexData(scope, key, buf, bufSize);
            }
            break;
        case kPlist:
            PrintPlist(scope, key, buf, bufSize);
            break;
        case kPlistOrString:
            PrintPlistOrString(scope, key, buf, bufSize);
            break;
    }
}

static void PrintKeyedAuthState(MechanismRecord *mechanism, const char *key, KeyType type)
    // For a given key, get both the content and hint value and, if successful, print them.
{
    OSStatus                    err;
    const AuthorizationValue *  value;
    AuthorizationContextFlags   flags;
    
    assert(MechanismValid(mechanism));
    assert(key != NULL);

    err = mechanism->fPlugin->fCallbacks->GetContextValue(mechanism->fEngine, key, &flags, &value);
    if (err == noErr) {
        PrintTypedData("GetContextValue", key, type, value->data, (size_t) value->length);
    }
    
    err = mechanism->fPlugin->fCallbacks->GetHintValue(mechanism->fEngine, key, &value);
    if (err == noErr) {
        PrintTypedData("GetHintValue", key, type, value->data, (size_t) value->length);
    }
}

static void PrintAuthState(MechanismRecord *mechanism)
    // Dump the state of the authorization.  I try to print as much information 
    // as possible, but I'm open to suggestions for what also might be useful.
{
    OSStatus                            err;
    SecuritySessionId                   actualSessionID;
    SessionAttributeBits                sessionAttr;
    AuthorizationSessionId              sessionID;
    const AuthorizationValueVector *    arguments;
    UInt32                              argIndex;
    int                                 keyIndex;

    assert(MechanismValid(mechanism));

    // Process information -- This lets you see whether the plugin is running 
    // privileged (in "authorizationhost", with EUID 0) or GUI-capable 
    // (in SecurityAgent, with EUID of "securityagent" (92)).

    DEBUGLOG("NullAuth:PrintAuthState: pid=%ld, ppid=%ld, euid=%ld, ruid=%ld", (long) getpid(), (long) getppid(), (long) geteuid(), (long) getuid() );

    // SessionGetInfo
    
    err = SessionGetInfo(callerSecuritySession, &actualSessionID, &sessionAttr);
    if (err == noErr) {
        DEBUGLOG("NullAuth:PrintAuthState: SessionGetInfo err=%ld, actualSessionID=%lu, sessionAttr=0x%lx", (long) err, (unsigned long) actualSessionID, (unsigned long) sessionAttr);
    } else {
        DEBUGLOG("NullAuth:PrintAuthState: SessionGetInfo err=%ld", (long) err);
    }

    // Session ID
    
    err = mechanism->fPlugin->fCallbacks->GetSessionId(mechanism->fEngine, &sessionID);
    if (err == noErr) {
        DEBUGLOG("NullAuth:PrintAuthState: GetSessionId err=%ld, sessionID=%p", (long) err, sessionID);
    } else {
        DEBUGLOG("NullAuth:PrintAuthState: GetSessionId err=%ld", (long) err);
    }

    // Arguments -- I have yet to find a way to actually pass arguments to my mechanism. 
    // In fact, looking at the source it seems that GetArguments isn't actually 
    // implemented (it always returns errAuthorizationInternal).  Still, I try to dump them 
    // anyway, just in case they get implemented in the future.
    
    err = mechanism->fPlugin->fCallbacks->GetArguments(mechanism->fEngine, &arguments);
    if (err == noErr) {
        DEBUGLOG("NullAuth:PrintAuthState: GetArguments err=%ld, count=%lu", (long) err, (unsigned long) arguments->count);

        for (argIndex = 0; argIndex < arguments->count; argIndex++) {
            DEBUGLOG(
                "NullAuth:PrintAuthState: arg[%lu]='%.*s'", 
                (unsigned long) argIndex, 
                (int) arguments->values[argIndex].length,
                (char *) arguments->values[argIndex].data
            );
        }
    } else {
        DEBUGLOG("NullAuth:PrintAuthState: GetArguments err=%ld", (long) err);
    }
    
    // Context and Hints -- This is where things get complex.  See my notes 
    // at the start of this section.
    
    for (keyIndex = 0; keyIndex < (sizeof(kStateKeys) / sizeof(kStateKeys[0])); keyIndex++) {
        PrintKeyedAuthState(mechanism, kStateKeys[keyIndex].fKey, kStateKeys[keyIndex].fType);
    }
}

/////////////////////////////////////////////////////////////////////
#pragma mark ***** Mechanism Entry Points

static OSStatus MechanismCreate(
    AuthorizationPluginRef      inPlugin,
    AuthorizationEngineRef      inEngine,
    AuthorizationMechanismId    mechanismId,
    AuthorizationMechanismRef * outMechanism
)
    // Called by the plugin host to create a mechanism, that is, a specific 
    // instance of authentication.
    //
    // inPlugin is the plugin reference, that is, the value returned by 
    // AuthorizationPluginCreate.
    //
    // inEngine is a reference to the engine that's running the plugin. 
    // We need to keep it around because it's a parameter to all the 
    // callbacks.
    // 
    // mechanismId is the name of the mechanism.  When you configure your 
    // mechanism in "/etc/authorization", you supply a string of the 
    // form:
    //
    //   plugin:mechanism[,privileged]
    //
    // where:
    // 
    // o plugin is the name of this bundle (without the extension)
    // o mechanism is the string that's passed to mechanismId 
    // o privileged, if present, causes this mechanism to be 
    //   instantiated in the privileged (rather than the GUI-capable) 
    //   plug-in host
    //
    // You can use the mechanismId to support multiple types of 
    // operation within the same plugin code.  For example, your plugin 
    // might have two cooperating mechanisms, one that needs to use the 
    // GUI and one that needs to run privileged.  This allows you to put 
    // both mechanisms in the same plugin.
    //
    // outMechanism is a pointer to a place where you return a reference to 
    // the newly created mechanism.
{
    OSStatus            err;
    PluginRecord *      plugin;
    MechanismRecord *   mechanism;
    
    DEBUGLOG("NullAuth:MechanismCreate: inPlugin=%p, inEngine=%p, mechanismId='%s'", inPlugin, inEngine, mechanismId);
    
    plugin = (PluginRecord *) inPlugin;
    assert(PluginValid(plugin));
    assert(inEngine != NULL);
    assert(mechanismId != NULL);
    assert(outMechanism != NULL);

    // Normally one would test mechanismId to distinguish various mechanisms 
    // supported by the same plugin.  In this case, the only thing we care about 
    // is if the mechanismId is "WaitForDebugger", in which case we set the 
    // fWaitForDebugger flag, which changes the behaviour of MechanismInvoke.
    // All other mechanism IDs are considered equal.
    
    // Allocate the space for the MechanismRecord.
    
    err = noErr;
    mechanism = (MechanismRecord *) malloc(sizeof(*mechanism));
    if (mechanism == NULL) {
        err = memFullErr;
    }
    
    // Fill it in.
    
    if (err == noErr) {
        mechanism->fMagic = kMechanismMagic;
        mechanism->fEngine = inEngine;
        mechanism->fPlugin = plugin;
        mechanism->fWaitForDebugger = (strcmp(mechanismId, "WaitForDebugger") == 0);
    }
    
    *outMechanism = mechanism;
    
    assert( (err == noErr) == (*outMechanism != NULL) );
    
    DEBUGLOG("NullAuth:MechanismCreate: err=%ld, *outMechanism=%p", (long) err, *outMechanism);

    return err;
}

static OSStatus MechanismInvoke(AuthorizationMechanismRef inMechanism)
    // Called by the system to start authentication using this mechanism.
    // In a real plugin, this is where the real work is done.
{
    OSStatus                    err;
    MechanismRecord *           mechanism;
    
    DEBUGLOG("NullAuth:MechanismInvoke: inMechanism=%p", inMechanism);

    mechanism = (MechanismRecord *) inMechanism;
    assert(MechanismValid(mechanism));
    
    // For exploratory purposes, either dump out the authorization state or wait for the 
    // debugger.
    
    if (mechanism->fWaitForDebugger) {
        DEBUGLOG("NullAuth:MechanismInvoke: process %ld waiting for debugger", (long) getpid());
        pause();
        DEBUGLOG("NullAuth:MechanismInvoke: process %ld continuing", (long) getpid());
    } else {
        PrintAuthState(mechanism);
    }
    
    // Tell the system that, as far as we're concerned, authorization was 
    // a success.  This allows you to insert this mechanism anywhere in the 
    // authorization chain, to dump the state without affecting the 
    // authorization result.
    
    err = mechanism->fPlugin->fCallbacks->SetResult(mechanism->fEngine, kAuthorizationResultAllow);

    DEBUGLOG("NullAuth:MechanismInvoke: err=%ld", (long) err);
    
    return err;
}

static OSStatus MechanismDeactivate(AuthorizationMechanismRef inMechanism)
    // Called by the system to deactivate the mechanism, in the traditional 
    // GUI sense of deactivating a window.  After your plugin has deactivated 
    // it's UI, it should call the DidDeactivate callback.
    //
    // In our case, we have no UI, so we just call DidDeactivate immediately.
{
    OSStatus            err;
    MechanismRecord *   mechanism;

    DEBUGLOG("NullAuth:MechanismDeactivate: inMechanism=%p", inMechanism);

    mechanism = (MechanismRecord *) inMechanism;
    assert(MechanismValid(mechanism));
    
    err = mechanism->fPlugin->fCallbacks->DidDeactivate(mechanism->fEngine);

    DEBUGLOG("NullAuth:MechanismDeactivate: err=%ld", (long) err);
    
    return err;
}

static OSStatus MechanismDestroy(AuthorizationMechanismRef inMechanism)
    // Called by the system when it's done with the mechanism.
{
    MechanismRecord *   mechanism;

    DEBUGLOG("NullAuth:MechanismDestroy: inMechanism=%p", inMechanism);

    mechanism = (MechanismRecord *) inMechanism;
    assert(MechanismValid(mechanism));

    free(mechanism);
    
    return noErr;
}

/////////////////////////////////////////////////////////////////////
#pragma mark ***** Plugin Entry Points

static OSStatus PluginDestroy(AuthorizationPluginRef inPlugin)
    // Called by the system when it's done with the plugin. 
    // All of the mechanisms should have been destroyed by this time.
{
    PluginRecord *  plugin;
    
    plugin = (PluginRecord *) inPlugin;
    assert(PluginValid(plugin));
    
    free(plugin);
    
    return noErr;
}

// gPluginInterface is the plugin's dispatch table, a pointer to 
// which you return from AuthorizationPluginCreate.  This is what 
// allows the system to call the various entry points in the plugin.

static AuthorizationPluginInterface gPluginInterface = {
    kAuthorizationPluginInterfaceVersion,
    &PluginDestroy,
    &MechanismCreate,
    &MechanismInvoke,
    &MechanismDeactivate,
    &MechanismDestroy 
};

extern OSStatus AuthorizationPluginCreate(
    const AuthorizationCallbacks *          callbacks,
    AuthorizationPluginRef *                outPlugin,
    const AuthorizationPluginInterface **   outPluginInterface
)
    // The primary entry point of the plugin.  Called by the system 
    // to instantiate the plugin.
    //
    // callbacks is a pointer to a bunch of callbacks that allow 
    // your plugin to ask the system to do operations on your behalf.
    //
    // outPlugin is a pointer to a place where you can return a 
    // reference to the newly created plugin.
    //
    // outPluginInterface is a pointer to a place where you can return 
    // a pointer to your plugin dispatch table.
{
    OSStatus        err;
    PluginRecord *  plugin;
    
    DEBUGLOG("NullAuth:AuthorizationPluginCreate: callbacks=%p", callbacks);

    assert(callbacks != NULL);
    assert(callbacks->version >= kAuthorizationCallbacksVersion);
    assert(outPlugin != NULL);
    assert(outPluginInterface != NULL);
    
    // Create the plugin.
    
    err = noErr;
    plugin = (PluginRecord *) malloc(sizeof(*plugin));
    if (plugin == NULL) {
        err = memFullErr;
    }
    
    // Fill it in.
    
    if (err == noErr) {
        plugin->fMagic     = kPluginMagic;
        plugin->fCallbacks = callbacks;
    }

    *outPlugin = plugin;
    *outPluginInterface = &gPluginInterface;

    assert( (err == noErr) == (*outPlugin != NULL) );

    DEBUGLOG("NullAuth:AuthorizationPluginCreate: err=%ld, *outPlugin=%p, *outPluginInterface=%p", (long) err, *outPlugin, *outPluginInterface);

    return err;
}
