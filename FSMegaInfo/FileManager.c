/*
    File:       FileManager.c

    Contains:   File Manager command processing.

    Written by: DTS

    Copyright:  Copyright (c) 2008 Apple Inc. All Rights Reserved.

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

#include <netinet/in.h>
#include <netdb.h>
#include <stdint.h>
#include <unistd.h>
#include <inttypes.h>

#include "FieldPrinter.h"
#include "Command.h"

#include "BSD.h"                // for kTextEncodingEnums

/////////////////////////////////////////////////////////////////
#pragma mark ***** Utilities Routines

static void FPAFPString(
    const char *    fieldName, 
    size_t          fieldSize, 
    const void *    fieldPtr, 
    uint32_t        indent, 
    size_t          nameWidth, 
    uint32_t        verbose, 
    const void *    info
)
    // Prints an AFP-style Pascal string field, where the field holds 
    // the offset from the start of the record to the Pascal string data. 
    // info supplies the offset from fieldPtr to the base of the record.
    // The string is assumed to be MacRoman (not my favourite design 
    // decision, but offset is already being used and it was too painful 
    // to add an extra parameter, or break it out into a record).
    //
    // See definition of FPPrinter for a parameter description.
{
    short           fieldValue;
    const UInt8 *   pstrPtr;
    char *          strBuf;
    
    #pragma unused(fieldSize)
    #pragma unused(verbose)
    assert( FPStandardPreCondition() );

    fieldValue = *((const short *) fieldPtr);
    pstrPtr = ((const UInt8 *) fieldPtr) - ((size_t) info) + fieldValue;

    strBuf = FPPStringToUTFCString(pstrPtr, kCFStringEncodingMacRoman);
    assert(strBuf != NULL);

    if (strBuf != NULL) {
        fprintf(stdout, "%*s%-*s = %hd ('%s')\n", (int) indent, "", (int) nameWidth, fieldName, fieldValue, strBuf);
    }
    
    free(strBuf);
}

static void FPFSFileSecurityRef(
    const char *    fieldName, 
    size_t          fieldSize, 
    const void *    fieldPtr, 
    uint32_t        indent, 
    size_t          nameWidth, 
    uint32_t        verbose, 
    const void *    info
)
{
    #pragma unused(fieldSize)
    #pragma unused(info)
    OSStatus            err;
    int                 junk;
    FSFileSecurityRef   fileSec;
    CFUUIDBytes         uuid;
    UInt32              id;
    UInt16              mode;

    assert( FPStandardPreCondition() );
    assert(fieldSize == sizeof(FSFileSecurityRef));
    
    fileSec = *((FSFileSecurityRef *) fieldPtr);
    if (fileSec == NULL) {
        fprintf(stdout, "%*s%-*s = NULL\n", (int) indent, "", (int) nameWidth, fieldName);
    } else {
        acl_t   acl;
        void *  aclBuf;
        size_t  aclBufSize;
        ssize_t aclActualSize;
        
        aclBufSize = 0;         // quieten warning
        aclActualSize = 0;      // quieten warning
        
        acl = NULL;
        aclBuf = NULL;
        
        fprintf(stdout, "%*s%s:\n", (int) indent, "", fieldName);

        err = FSFileSecurityGetOwnerUUID(fileSec, &uuid);
        if (err == noErr) {
            FPGUID("owner UUID", sizeof(uuid), &uuid, indent + kStdIndent, strlen("owner UUID"), verbose, NULL);
        }
        err = FSFileSecurityGetOwner(fileSec, &id);
        if (err == noErr) {
            FPUID("owner UID",  sizeof(id), &id, indent + kStdIndent, strlen("owner UUID"), verbose, NULL);
        }
        err = FSFileSecurityGetGroupUUID(fileSec, &uuid);
        if (err == noErr) {
            FPGUID("group UUID", sizeof(uuid), &uuid, indent + kStdIndent, strlen("owner UUID"), verbose, NULL);
        }
        err = FSFileSecurityGetGroup(fileSec, &id);
        if (err == noErr) {
            FPGID("owning GID", sizeof(id), &id, indent + kStdIndent, strlen("owner UUID"), verbose, NULL);
        }
        err = FSFileSecurityGetMode(fileSec, &mode);
        if (err == noErr) {
            FPModeT("mode",      sizeof(mode), &mode, indent + kStdIndent, strlen("owner UUID"), verbose, NULL);
        }
        
        err = FSFileSecurityCopyAccessControlList(fileSec, &acl);
        if (err == noErr) {
            aclBufSize = acl_size(acl);
            
            aclBuf = malloc(aclBufSize);
            if (aclBuf == NULL) {
                err = memFullErr;
            }
        }
        if (err == noErr) {
            aclActualSize = acl_copy_ext_native(aclBuf, acl, aclBufSize);
            if (aclActualSize < 0) {
                err = errno;
            } else {
                assert( ((size_t) aclActualSize) <= aclBufSize );
            }
        }
        if (err == noErr) {
            FPKauthFileSec("acl", aclActualSize, aclBuf, indent + kStdIndent, strlen("owner UUID"), verbose, NULL);
        }
        
        free(aclBuf);
        if (acl != NULL) {
            junk = acl_free(acl);
            assert(junk == 0);
        }
    }
}

#pragma mark *     FSGetVolumeInfo

// FSVolumeInfoBitmap

static const FPFlagDesc kFSGetVolumeInfoOptions[] = {
    {kFSVolInfoCreateDate,  "kFSVolInfoCreateDate"},
    {kFSVolInfoModDate,     "kFSVolInfoModDate"},
    {kFSVolInfoBackupDate,  "kFSVolInfoBackupDate"},
    {kFSVolInfoCheckedDate, "kFSVolInfoCheckedDate"},
    {kFSVolInfoFileCount,   "kFSVolInfoFileCount"},
    {kFSVolInfoDirCount,    "kFSVolInfoDirCount"},
    {kFSVolInfoSizes,       "kFSVolInfoSizes"},
    {kFSVolInfoBlocks,      "kFSVolInfoBlocks"},
    {kFSVolInfoNextAlloc,   "kFSVolInfoNextAlloc"},
    {kFSVolInfoRsrcClump,   "kFSVolInfoRsrcClump"},
    {kFSVolInfoDataClump,   "kFSVolInfoDataClump"},
    {kFSVolInfoNextID,      "kFSVolInfoNextID"},
    {kFSVolInfoFinderInfo,  "kFSVolInfoFinderInfo"},
    {kFSVolInfoFlags,       "kFSVolInfoFlags"},
    {kFSVolInfoFSInfo,      "kFSVolInfoFSInfo"},
    {kFSVolInfoDriveInfo,   "kFSVolInfoDriveInfo"},
    {0, NULL}
};

// Flags in the flags field of FSVolumeInfo.

static const FPFlagDesc kVolAttrFlags[] = { 
    {kFSVolFlagDefaultVolumeMask,       "kFSVolFlagDefaultVolumeMask"   },
    {kFSVolFlagFilesOpenMask,           "kFSVolFlagFilesOpenMask"       },
    {kFSVolFlagHardwareLockedMask,      "kFSVolFlagHardwareLockedMask"  },
    {kFSVolFlagJournalingActiveMask,    "kFSVolFlagJournalingActiveMask"},
    {kFSVolFlagSoftwareLockedMask,      "kFSVolFlagSoftwareLockedMask"  },
    {0, NULL} 
};

// Size multipliers for fields in the FSVolumeInfo structure.  See 
// FPSize for a description of what this is about.

static const FPSizeMultiplier kFSGetVolumeInfoTotalBlocksMultiplier = {
    offsetof(FSVolumeInfo, blockSize) - offsetof(FSVolumeInfo, totalBlocks),
    sizeof(UInt32)
};

static const FPSizeMultiplier kFSGetVolumeInfoFreeBlocksMultiplier = {
    offsetof(FSVolumeInfo, blockSize) - offsetof(FSVolumeInfo, freeBlocks),
    sizeof(UInt32)
};

static void PrintVolumeInfo(
    const HFSUniStr255 *    volName, 
    FSVolumeInfoBitmap      options,
    const FSVolumeInfo *    volInfo,
    uint32_t                indent,
    uint32_t                verbose
)
    // The core of the FSGetVolumeInfo command.
{
    const size_t kNameSpacer = strlen("nextAllocation");
    
    assert(volName != NULL);
    assert(volInfo != NULL);

    HFSUniStr255FieldPrinter("volumeName", sizeof(*volName), volName, indent, kNameSpacer, verbose, NULL);

    if (options & kFSVolInfoCreateDate) {
        FPUTCDateTime("createDate",  sizeof(volInfo->createDate),  &volInfo->createDate,  indent, kNameSpacer, verbose, NULL);
    }
    if (options & kFSVolInfoModDate) {
        FPUTCDateTime("modifyDate",  sizeof(volInfo->modifyDate),  &volInfo->modifyDate,  indent, kNameSpacer, verbose, NULL);
    }
    if (options & kFSVolInfoBackupDate) {
        FPUTCDateTime("backupDate",  sizeof(volInfo->backupDate),  &volInfo->backupDate,  indent, kNameSpacer, verbose, NULL);
    }
    if (options & kFSVolInfoCheckedDate) {
        FPUTCDateTime("checkedDate", sizeof(volInfo->checkedDate), &volInfo->checkedDate, indent, kNameSpacer, verbose, NULL);
    }

    if (options & kFSVolInfoFileCount) {
        FPUDec("fileCount", sizeof(volInfo->fileCount), &volInfo->fileCount, indent, kNameSpacer, verbose, NULL);
    }
    if (options & kFSVolInfoDirCount) {
        FPUDec("folderCount", sizeof(volInfo->folderCount), &volInfo->folderCount, indent, kNameSpacer, verbose, NULL);
    }
    
    if (options & kFSVolInfoSizes) {
        FPSize("totalBytes", sizeof(volInfo->totalBytes), &volInfo->totalBytes, indent, kNameSpacer, verbose, NULL);
        FPSize("freeBytes",  sizeof(volInfo->freeBytes),  &volInfo->freeBytes,  indent, kNameSpacer, verbose, NULL);
    }

    if (options & kFSVolInfoBlocks) {
        FPSize("blockSize",   sizeof(volInfo->blockSize),   &volInfo->blockSize,   indent, kNameSpacer, verbose, NULL);
        FPSize("totalBlocks", sizeof(volInfo->totalBlocks), &volInfo->totalBlocks, indent, kNameSpacer, verbose, &kFSGetVolumeInfoTotalBlocksMultiplier);
        FPSize("freeBlocks",  sizeof(volInfo->freeBlocks),  &volInfo->freeBlocks,  indent, kNameSpacer, verbose, &kFSGetVolumeInfoFreeBlocksMultiplier);
    }

    if (options & kFSVolInfoNextAlloc) {
        FPUDec("nextAllocation", sizeof(volInfo->nextAllocation), &volInfo->nextAllocation, indent, kNameSpacer, verbose, NULL);
    }
    if (options & kFSVolInfoRsrcClump) {
        FPSize("rsrcClumpSize", sizeof(volInfo->rsrcClumpSize), &volInfo->rsrcClumpSize, indent, kNameSpacer, verbose, NULL);
    }
    if (options & kFSVolInfoDataClump) {
        FPSize("dataClumpSize", sizeof(volInfo->dataClumpSize), &volInfo->dataClumpSize, indent, kNameSpacer, verbose, NULL);
    }
    if (options & kFSVolInfoNextID) {
        FPUDec("nextCatalogID", sizeof(volInfo->nextCatalogID), &volInfo->nextCatalogID, indent, kNameSpacer, verbose, NULL);
    }

    if (options & kFSVolInfoFinderInfo) {
        FPFinderInfo("finderInfo", sizeof(volInfo->finderInfo), &volInfo->finderInfo, indent, kNameSpacer, verbose, (void *) (uintptr_t) kVolumeInfo);
    }
    if (options & kFSVolInfoFlags) {
        FPFlags("flags", sizeof(volInfo->flags), &volInfo->flags, indent, kNameSpacer, verbose, kVolAttrFlags);
    }
    if (options & kFSVolInfoFSInfo) {
        FPSignature("filesystemID", sizeof(volInfo->filesystemID), &volInfo->filesystemID, indent, kNameSpacer, verbose, (const void *) (uintptr_t) kFPValueHostEndian);
        FPSignature("signature",    sizeof(volInfo->signature),    &volInfo->signature,    indent, kNameSpacer, verbose, (const void *) (uintptr_t) kFPValueHostEndian);
    }
    if (options & kFSVolInfoDriveInfo) {
        FPUDec("driveNumber",  sizeof(volInfo->driveNumber),  &volInfo->driveNumber,  indent, kNameSpacer, verbose, NULL);
        FPUDec("driverRefNum", sizeof(volInfo->driverRefNum), &volInfo->driverRefNum, indent, kNameSpacer, verbose, NULL);
    }
}

static CommandError PrintFSGetVolumeInfo(CommandArgsRef args, uint32_t indent, uint32_t verbose)
    // Uses FSGetVolumeInfo to get information about the specified volume and 
    // prints the result.
    //
    // indent and verbose are as per the comments for FPPrinter.
{
    OSStatus        err;
    int             options;
    ItemCount       volIndex;
    FSVolumeRefNum  volRefNum;
    FSVolumeInfo    volInfo;
    HFSUniStr255    volName;

    assert( CommandArgsValid(args) );
    
    volIndex = 0;               // quieten warning

    if (CommandArgsIsOption(args)) {
        err = CommandArgsGetFlagListInt(args, kFSGetVolumeInfoOptions, &options);
    } else {
        options = kFSVolInfoGettableInfo;
        err = noErr;
    }

    if (err == noErr) {
        if ( CommandArgsGetOptionalConstantString(args, "all") ) {
            volIndex  = 1;
            volRefNum = 0;
        } else {
            volIndex = 0;
            err = CommandArgsGetVRefNum(args, &volRefNum);
        }
    }

    if (err == noErr) {
        do {
            FSVolumeRefNum      realVolRefNum;
            
            err = FSGetVolumeInfo(volRefNum, volIndex, &realVolRefNum, options, &volInfo, &volName, NULL);
            if (err == noErr) {
                if (volIndex > 0) {
                    // We're printing all volumes
                    
                    if ( (volIndex > 1) && (options != 0) ) {
                        fprintf(stdout, "\n");
                    }
                    fprintf(stdout, "%*svRefNum = %d\n", (int) indent, "", (int) realVolRefNum);
            
                    PrintVolumeInfo(&volName, options, &volInfo, indent + kStdIndent, verbose);
                } else {
                    // We're printing just one volume
                    PrintVolumeInfo(&volName, options, &volInfo, indent, verbose);
                }
            }

            volIndex += 1;
        } while ( (err == noErr) && (volIndex > 1) );
        
        if ( (volIndex > 1) && (err == nsvErr) ) {
            err = noErr;
        }
    }
    
    return CommandErrorMakeWithOSStatus(err);
}


static const CommandHelpEntry kFSGetVolumeInfoCommandHelp[] = {
    {CommandHelpString, "-options Volume information to get; default is kFSVolInfoGettableInfo"},
    {CommandHelpFlags,  kFSGetVolumeInfoOptions},
    {NULL, NULL}
};

const CommandInfo kFSGetVolumeInfoCommand = {
    PrintFSGetVolumeInfo,
    "FSGetVolumeInfo",
    "[ -options ] ( all | itemPath )",
    "Print information from FSGetVolumeInfo.",
    kFSGetVolumeInfoCommandHelp
};

#pragma mark *     PBHGetVolParmsSync

// Flags for the vMAttrib field of the GetVolParmsInfoBuffer structure.

static const FPFlagDesc kVolParmsFlags[] = {
    {1L << bLimitFCBs, "bLimitFCBs"},
    {1L << bLocalWList, "bLocalWList"},
    {1L << bNoMiniFndr, "bNoMiniFndr"},
    {1L << bNoVNEdit, "bNoVNEdit"},
    {1L << bNoLclSync, "bNoLclSync"},
    {1L << bTrshOffLine, "bTrshOffLine"},
    {1L << bNoSwitchTo, "bNoSwitchTo"},
    {1L << bNoDeskItems, "bNoDeskItems"},
    {1L << bNoBootBlks, "bNoBootBlks"},
    {1L << bAccessCntl, "bAccessCntl"},
    {1L << bNoSysDir, "bNoSysDir"},
    {1L << bHasExtFSVol, "bHasExtFSVol"},
    {1L << bHasOpenDeny, "bHasOpenDeny"},
    {1L << bHasCopyFile, "bHasCopyFile"},
    {1L << bHasMoveRename, "bHasMoveRename"},
    {1L << bHasDesktopMgr, "bHasDesktopMgr"},
    {1L << bHasShortName, "bHasShortName"},
    {1L << bHasFolderLock, "bHasFolderLock"},
    {1L << bHasPersonalAccessPrivileges, "bHasPersonalAccessPrivileges"},
    {1L << bHasUserGroupList, "bHasUserGroupList"},
    {1L << bHasCatSearch, "bHasCatSearch"},
    {1L << bHasFileIDs, "bHasFileIDs"},
    {1L << bHasBTreeMgr, "bHasBTreeMgr"},
    {1L << bHasBlankAccessPrivileges, "bHasBlankAccessPrivileges"},
    {1L << bSupportsAsyncRequests, "bSupportsAsyncRequests"},
    {1L << bSupportsTrashVolumeCache, "bSupportsTrashVolumeCache"},
    {1L << bHasDirectIO, "bHasDirectIO"},
    {0, NULL} 
};

// Flags for the vMExtendedAttributes field of the GetVolParmsInfoBuffer structure.

static const FPFlagDesc kVolParmsExtendedFlags[] = {
    {1L << bSupportsExtendedFileSecurity, "bSupportsExtendedFileSecurity"},
    {1L << bIsOnExternalBus, "bIsOnExternalBus"},
    {1L << bNoRootTimes, "bNoRootTimes"},
    {1L << bIsRemovable, "bIsRemovable"},
    {1L << bDoNotDisplay, "bDoNotDisplay"},
    {1L << bIsCasePreserving, "bIsCasePreserving"},
    {1L << bIsCaseSensitive, "bIsCaseSensitive"},
    {1L << bIsOnInternalBus, "bIsOnInternalBus"},
    {1L << bNoVolumeSizes, "bNoVolumeSizes"},
    {1L << bSupportsJournaling, "bSupportsJournaling"},
    {1L << bSupportsExclusiveLocks, "bSupportsExclusiveLocks"},
    {1L << bAllowCDiDataHandler, "bAllowCDiDataHandler"},
    {1L << bIsAutoMounted, "bIsAutoMounted"},
    {1L << bSupportsSymbolicLinks, "bSupportsSymbolicLinks"},
    {1L << bAncestorModDateChanges, "bAncestorModDateChanges"},
    {1L << bParentModDateChanges, "bParentModDateChanges"},
    {1L << bL2PCanMapFileBlocks, "bL2PCanMapFileBlocks"},
    {1L << bSupportsSubtreeIterators, "bSupportsSubtreeIterators"},
    {1L << bSupportsNamedForks, "bSupportsNamedForks"},
    {1L << bSupportsMultiScriptNames, "bSupportsMultiScriptNames"},
    {1L << bSupportsLongNames, "bSupportsLongNames"},
    {1L << bSupports2TBFiles, "bSupports2TBFiles"},
    {1L << bSupportsFSExchangeObjects, "bSupportsFSExchangeObjects"},
    {1L << bSupportsFSCatalogSearch, "bSupportsFSCatalogSearch"},
    {1L << bSupportsHFSPlusAPIs, "bSupportsHFSPlusAPIs"},
    {1L << bIsEjectable, "bIsEjectable"},
    {0, NULL} 
};

// Constants for the vMForeignPrivID field of the GetVolParmsInfoBuffer structure

static const FPEnumDesc kForeignPrivEnums[] = {
    {0,             "HFS"},
    {fsUnixPriv,    "fsUnixPriv"},
    {0,             NULL}
};

static const char kGetVolParmsInfoBufferFieldSpacer[32] = "vMExtendedAttributes";

// The fields of the GetVolParmsInfoBuffer structure.  These are broken up into five 
// groups to account for the various versions of the structure, which are in turn 
// assembled into the kGetVolParmsInfoBufferFieldDescByVersion array for easy 
// processing by the code.

// The only useful meaning of vMServerAdr in the modern world is a zero/non-zero test 
// to see whether the volume is local or remote.  I didn't feel that justified a custom 
// printer routine.

static const FPFieldDesc kGetVolParmsInfoBufferFieldDescV1[] = { 
    {"vMVersion",               offsetof(GetVolParmsInfoBuffer, vMVersion),             sizeof(SInt16),         FPSDec, NULL},
    {"vMAttrib",                offsetof(GetVolParmsInfoBuffer, vMAttrib),              sizeof(SInt32),         FPFlags, kVolParmsFlags},
    {"vMLocalHand",             offsetof(GetVolParmsInfoBuffer, vMLocalHand),           sizeof(Handle),         FPPtr, NULL},
    {"vMServerAdr",             offsetof(GetVolParmsInfoBuffer, vMServerAdr),           sizeof(SInt32),         FPHex, NULL},
    {kGetVolParmsInfoBufferFieldSpacer, 0,  0, FPNull, NULL},      // present to pad out field widths
    {NULL, 0, 0, NULL, NULL}
};

// While there is a definition for vMVolumeGrade (see DTS Technote 1121 "Mac OS 8.1" 
// <http://developer.apple.com/technotes/tn/tn1121.html>), Core Services File Manager 
// provides no way for a file system to return a value (it always returns 0), so there's 
// no point providing a sophisticated interpretation.

static const FPFieldDesc kGetVolParmsInfoBufferFieldDescV2[] = { 
    {"vMVolumeGrade",           offsetof(GetVolParmsInfoBuffer, vMVolumeGrade),         sizeof(SInt32),         FPSDec, NULL},
    {"vMForeignPrivID",         offsetof(GetVolParmsInfoBuffer, vMForeignPrivID),       sizeof(SInt16),         FPEnum, kForeignPrivEnums},
    {kGetVolParmsInfoBufferFieldSpacer, 0,  0, FPNull, NULL},      // present to pad out field widths
    {NULL, 0, 0, NULL, NULL}
};

static const FPFieldDesc kGetVolParmsInfoBufferFieldDescV3[] = { 
    {"vMExtendedAttributes",    offsetof(GetVolParmsInfoBuffer, vMExtendedAttributes),  sizeof(SInt32),         FPFlags, kVolParmsExtendedFlags},
    {NULL, 0, 0, NULL, NULL}
};

static const FPFieldDesc kGetVolParmsInfoBufferFieldDescV4[] = { 
    {"vMDeviceID",              offsetof(GetVolParmsInfoBuffer, vMDeviceID),            sizeof(void *),         FPCStringPtr, NULL},
    {kGetVolParmsInfoBufferFieldSpacer, 0,  0, FPNull, NULL},      // present to pad out field widths
    {NULL, 0, 0, NULL, NULL}
};

static const FPFieldDesc kGetVolParmsInfoBufferFieldDescV5[] = { 
    {"vMMaxNameLength",         offsetof(GetVolParmsInfoBuffer, vMMaxNameLength),       sizeof(UniCharCount),   FPUDec, NULL},
    {kGetVolParmsInfoBufferFieldSpacer, 0,  0, FPNull, NULL},      // present to pad out field widths
    {NULL, 0, 0, NULL, NULL}
};

static const FPFieldDesc * kGetVolParmsInfoBufferFieldDescByVersion[] = {
    kGetVolParmsInfoBufferFieldDescV1,
    kGetVolParmsInfoBufferFieldDescV2,
    kGetVolParmsInfoBufferFieldDescV3,
    kGetVolParmsInfoBufferFieldDescV4,
    kGetVolParmsInfoBufferFieldDescV5
};

static void PrintVolumeParms(const GetVolParmsInfoBuffer *volParms, uint32_t indent, uint32_t verbose)
    // Code to print a volume parms buffer, common to both the PBHGetVolParms 
    // and FSGetVolumeParms commands.
{
    size_t  versionIndex;
    size_t  versionLimit;

    assert(volParms != NULL);

    if (volParms->vMVersion < 1) {
        fprintf(stdout, "    vMVersion = %hd\n", volParms->vMVersion);
    } else {
        versionIndex = 0;
        
        versionLimit = (sizeof(kGetVolParmsInfoBufferFieldDescByVersion) / sizeof(FPFieldDesc *));
        if (versionLimit > (size_t) volParms->vMVersion) {
            versionLimit = volParms->vMVersion;
        }
        while (versionIndex < versionLimit) {
            FPPrintFields(kGetVolParmsInfoBufferFieldDescByVersion[versionIndex], volParms, sizeof(*volParms), indent, verbose);
            versionIndex += 1;
        }
    }
}

#if ! TARGET_RT_64_BIT

static CommandError PrintPBHGetVolParms(CommandArgsRef args, uint32_t indent, uint32_t verbose)
    // Uses PBHGetVolParmsSync to get information about the specified volume and 
    // prints the result.
    //
    // indent and verbose are as per the comments for FPPrinter.
{
    OSStatus                err;
    FSVolumeRefNum          volRefNum;
    HParamBlockRec          hpb;
    GetVolParmsInfoBuffer   volParms;

    assert( CommandArgsValid(args) );

    err = CommandArgsGetVRefNum(args, &volRefNum);
    if (err == noErr) {
        hpb.ioParam.ioNamePtr = NULL;
        hpb.ioParam.ioVRefNum = volRefNum;
        hpb.ioParam.ioBuffer   = (Ptr) &volParms;
        hpb.ioParam.ioReqCount = sizeof(volParms);
        err = PBHGetVolParmsSync(&hpb);
    }
    if (err == noErr) {
        PrintVolumeParms(&volParms, indent, verbose);
    }
    
    return CommandErrorMakeWithOSStatus(err);
}

const CommandInfo kPBHGetVolParmsCommand = {
    PrintPBHGetVolParms,
    "PBHGetVolParms",
    "itemPath",
    "Print information from PBHGetVolParms.",
    NULL
};

#endif

static CommandError PrintFSGetVolumeParms(CommandArgsRef args, uint32_t indent, uint32_t verbose)
    // Uses FSGetVolumeParms to get information about the specified volume and 
    // prints the result.
    //
    // indent and verbose are as per the comments for FPPrinter.
{
    OSStatus                err;
    FSVolumeRefNum          volRefNum;
    GetVolParmsInfoBuffer   volParms;

    assert( CommandArgsValid(args) );

    if ( FSGetVolumeParms == NULL ) {
        return CommandErrorMakeWithCustom(kUnavailableCustomError);
    }

    err = CommandArgsGetVRefNum(args, &volRefNum);
    if (err == noErr) {
        err = FSGetVolumeParms(volRefNum, &volParms, sizeof(volParms));
    }
    if (err == noErr) {
        PrintVolumeParms(&volParms, indent, verbose);
    }
    
    return CommandErrorMakeWithOSStatus(err);
}

const CommandInfo kFSGetVolumeParmsCommand = {
    PrintFSGetVolumeParms,
    "FSGetVolumeParms",
    "itemPath",
    "Print information from FSGetVolumeParms.",
    NULL
};

#pragma mark *     PBGetVolMountInfo

// Values for the uamType field of the AFPVolMountInfo.

static const FPEnumDesc kVolMountInfoUAMType[] = {
    { 1, "No User Authent" },
    { 2, "Cleartxt Passwrd" },
    { 3, "Randnum Exchange" },
    { 4, "Cleartxt Passwrd (variable length)" },
    { 5, "Randnum Exchange (variable length)" },
    { 6, "2-Way Randnum" },
    { 7, "DHCAST128" },
    { 8, "DHX2" },
    { 9, "Client Krb v2" },
    { 0, NULL }
};

// The following two enums document extra constants that should be in "Files.h" <rdar://problem/5439845>.

enum {
    kAFPTagTypeIPv6         = 0x06,
    kAFPTagTypeIPv6Port     = 0x07
};
enum {
    kAFPTagLengthIPv6       = 0x12,
    kAFPTagLengthIPv6Port   = 0x14
};
  
static void PrintAlternateAddresses(AFPXVolMountInfoPtr afpXVolInfoBuffer, short offset, uint32_t indent)
    // Prints any alternative addresses embedded within the AFPXVolMountInfo structure.
    // 
    // indent is per the comments for FPPrinter.
{
    int                     junk;
    AFPAlternateAddress *   addrList;
    AFPTagData *            thisAddr;
    int                     i;
    UInt8                   thisAddrType;
    size_t                  addrIndex;
    struct sockaddr_in      addr;
    struct sockaddr_in6     addr6;
    Str255                  dns;
    char                    hostStr[NI_MAXHOST];
    char                    servStr[NI_MAXSERV];
    static const char *kAddrTypeNames[] = { 
        "unknown",        "kAFPTagTypeIP", "kAFPTagTypeIPPort", "kAFPTagTypeDDP", 
        "kAFPTagTypeDNS", "unknown",       "kAFPTagTypeIPv6",   "kAFPTagTypeIPv6Port"
    };
    
    assert(offset >= 0);

    addrList = (AFPAlternateAddress *) (((char *) afpXVolInfoBuffer) + offset);
    assert(addrList->fVersion == 0);
    thisAddr = (AFPTagData *) &addrList->fAddressList[0];
    for (i = 0; i < addrList->fAddressCount; i++) {
        Boolean         understood;
        
        thisAddrType = thisAddr->fType;
        if (thisAddrType >= (sizeof(kAddrTypeNames) / sizeof(*kAddrTypeNames))) {
            thisAddrType = 0;
        }
        fprintf(stdout, "%*saddr[%d].fType = %s (%" PRIu8 ")\n", (int) indent, "", i, kAddrTypeNames[thisAddrType], (uint8_t) thisAddr->fType);
        
        memset(&addr, 0, sizeof(addr));
        addr.sin_len = sizeof(addr);
        addr.sin_family = AF_INET;
        
        memset(&addr6, 0, sizeof(addr6));
        addr6.sin6_len = sizeof(addr6);
        addr6.sin6_family = AF_INET6;
        
        // Print the address data based on its type.
        //
        // IMPORTANT: This data is always big endian (because of the PowerPC 
        // heritage of this structure) but that's OK because the data in the 
        // struct sockaddr_in[6] is also big endian (because it is in network 
        // byte order).
        
        understood = false;
        switch (thisAddr->fType) {
            case kAFPTagTypeIP:
                if (thisAddr->fLength == kAFPTagLengthIP) {
                    memcpy(&addr.sin_addr, &thisAddr->fData[0], sizeof(addr.sin_addr));
                    junk = getnameinfo( (struct sockaddr *) &addr, (socklen_t) sizeof(addr), hostStr, (socklen_t) sizeof(hostStr), NULL, 0, NI_NUMERICHOST);
                    assert(junk == 0);
                    fprintf(stdout, "%*saddr[%d].fData = %s\n", (int) indent, "", i, hostStr);
                    understood = true;
                }
                break;
            case kAFPTagTypeIPPort:
                if (thisAddr->fLength == kAFPTagLengthIPPort) {
                    memcpy(&addr.sin_addr, &thisAddr->fData[0], sizeof(addr.sin_addr));
                    memcpy(&addr.sin_port, &thisAddr->fData[sizeof(addr.sin_addr)], sizeof(addr.sin_port));
                    junk = getnameinfo( (struct sockaddr *) &addr, (socklen_t) sizeof(addr), hostStr, (socklen_t) sizeof(hostStr), servStr, (socklen_t) sizeof(servStr), NI_NUMERICHOST | NI_NUMERICSERV);
                    assert(junk == 0);
                    fprintf(stdout, "%*saddr[%d].fData = %s:%s\n", (int) indent, "", i, hostStr, servStr);
                    understood = true;
                }
                break;
            case kAFPTagTypeDNS:
                if (thisAddr->fLength > offsetof(AFPTagData, fLength)) {
                    dns[0] = thisAddr->fLength - offsetof(AFPTagData, fData);
                    memcpy(&dns[1], &thisAddr->fData[0], dns[0]);
                    fprintf(stdout, "%*saddr[%d].fData = %.*s\n", (int) indent, "", i, (int) dns[0], (char *) &dns[1]);
                    understood = true;
                }
                break;
            case kAFPTagTypeIPv6:
                if (thisAddr->fLength == kAFPTagLengthIPv6) {
                    memcpy(&addr6.sin6_addr, &thisAddr->fData[0], sizeof(addr6.sin6_addr));
                    junk = getnameinfo( (struct sockaddr *) &addr6, (socklen_t) sizeof(addr6), hostStr, (socklen_t) sizeof(hostStr), NULL, 0, NI_NUMERICHOST);
                    assert(junk == 0);
                    fprintf(stdout, "%*saddr[%d].fData = %s\n", (int) indent, "", i, hostStr);
                    understood = true;
                }
                break;
            case kAFPTagTypeIPv6Port:
                if (thisAddr->fLength == kAFPTagLengthIPv6Port) {
                    memcpy(&addr6.sin6_addr, &thisAddr->fData[0], sizeof(addr6.sin6_addr));
                    memcpy(&addr6.sin6_port, &thisAddr->fData[sizeof(addr6.sin6_addr)], sizeof(addr6.sin6_port));
                    junk = getnameinfo( (struct sockaddr *) &addr6, (socklen_t) sizeof(addr6), hostStr, (socklen_t) sizeof(hostStr), NULL, 0, NI_NUMERICHOST);
                    assert(junk == 0);
                    fprintf(stdout, "%*saddr[%d].fData = %s\n", (int) indent, "", i, hostStr);
                    understood = true;
                }
                break;
            default:
                break;
        }

        // If we don't recognise the address type, just dump the hex.

        if ( ! understood ) {
            fprintf(stdout, "%*saddr[%d].fData =", (int) indent, "", i);
            for (addrIndex = 0; addrIndex < ((size_t) thisAddr->fLength); addrIndex++) {
                fprintf(stdout, " 0x%02x", thisAddr->fData[addrIndex]);
            }
            fprintf(stdout, "\n");
        }
        
        thisAddr = (AFPTagData *) ( ((char *) thisAddr) + thisAddr->fLength );
    }
}

// Flags for the flags field of the VolumeMountInfoHeader.

static const FPFlagDesc kAFPFlags[] = {
    {volMountExtendedFlagsMask, "volMountExtendedFlagsMask"},
    {0, NULL} 
};

// The fields of the VolumeMountInfoHeader structure.

static const char kVolMountInfoFieldSpacer[32] = "volInfoBuffer";

static const FPFieldDesc kVolMountInfoFieldDesc[] = { 
    {kVolMountInfoFieldSpacer, 0,  0, FPNull, NULL},      // present to pad out field widths
    {"length",          offsetof(VolumeMountInfoHeader, length),            sizeof(short),          FPSDec, NULL},
    {"media",           offsetof(VolumeMountInfoHeader, media),             sizeof(VolumeType),     FPSignature, (const void *) (uintptr_t) kFPValueHostEndian},
    {"flags",           offsetof(VolumeMountInfoHeader, flags),             sizeof(short),          FPFlags, kAFPFlags},
    {NULL, 0, 0, NULL, NULL}
};

// The fields of the AFPVolMountInfo structure.

static const char kAFPVolMountInfoFieldSpacer[32] = "alternateAddressOffset";

static const FPFieldDesc kAFPVolMountInfoFieldDesc[] = { 
    {kAFPVolMountInfoFieldSpacer, 0,  0, FPNull, NULL},      // present to pad out field widths
    {"nbpInterval",         offsetof(AFPVolMountInfo, nbpInterval),             sizeof(SInt8),      FPSDec,      NULL},
    {"nbpCount",            offsetof(AFPVolMountInfo, nbpCount),                sizeof(SInt8),      FPSDec,      NULL},
    {"uamType",             offsetof(AFPVolMountInfo, uamType),                 sizeof(short),      FPEnum,      kVolMountInfoUAMType},
    {"zoneNameOffset",      offsetof(AFPVolMountInfo, zoneNameOffset),          sizeof(short),      FPAFPString, (void *) offsetof(AFPVolMountInfo, zoneNameOffset)},
    {"serverNameOffset",    offsetof(AFPVolMountInfo, serverNameOffset),        sizeof(short),      FPAFPString, (void *) offsetof(AFPVolMountInfo, serverNameOffset)},
    {"volNameOffset",       offsetof(AFPVolMountInfo, volNameOffset),           sizeof(short),      FPAFPString, (void *) offsetof(AFPVolMountInfo, volNameOffset)},
    {"userNameOffset",      offsetof(AFPVolMountInfo, userNameOffset),          sizeof(short),      FPAFPString, (void *) offsetof(AFPVolMountInfo, userNameOffset)},
    {"userPasswordOffset",  offsetof(AFPVolMountInfo, userPasswordOffset),      sizeof(short),      FPAFPString, (void *) offsetof(AFPVolMountInfo, userPasswordOffset)},
    {"volPasswordOffset",   offsetof(AFPVolMountInfo, volPasswordOffset),       sizeof(short),      FPAFPString, (void *) offsetof(AFPVolMountInfo, volPasswordOffset)},
    {NULL, 0, 0, NULL, NULL}
};

// Flags for the extendedFlags field of the AFPXVolMountInfo.

static const FPFlagDesc kAFPExtendedFlags[] = {
    {kAFPExtendedFlagsAlternateAddressMask, "kAFPExtendedFlagsAlternateAddressMask"},
    {0, NULL} 
};

// The fields of the AFPXVolMountInfo structure.  These are broken up into 
// two groups because the second group of fields is only present if 
// kAFPExtendedFlagsAlternateAddressMask is set in extendedFlags.

static const FPFieldDesc kAFPXVolMountInfoFieldDesc[] = { 
    {kAFPVolMountInfoFieldSpacer, 0,  0, FPNull, NULL},      // present to pad out field widths
    {"extendedFlags",   offsetof(AFPXVolMountInfo, extendedFlags),  sizeof(short),  FPFlags, kAFPExtendedFlags},
    {"uamNameOffset",   offsetof(AFPXVolMountInfo, uamNameOffset),  sizeof(short),  FPAFPString, (void *) offsetof(AFPXVolMountInfo, uamNameOffset)},
    {NULL, 0, 0, NULL, NULL}
};

static const FPFieldDesc kAFPXVolMountInfoFieldDesc2[] = { 
    {kAFPVolMountInfoFieldSpacer, 0,  0, FPNull, NULL},      // present to pad out field widths
    {"alternateAddressOffset",  offsetof(AFPXVolMountInfo, alternateAddressOffset),     sizeof(short),      FPSDec, NULL},
    {NULL, 0, 0, NULL, NULL}
};

static void PrintVolumeMountInfo(size_t volInfoSize, VolumeMountInfoHeaderPtr volInfoBuffer, uint32_t indent, uint32_t verbose)
    // Common code used to print a volume mount info buffer.  Called by both 
    // the FSGetVolumeMountInfo and the PBGetVolMountInfo commands.
{
    assert(volInfoBuffer != NULL);
    assert(volInfoSize >= sizeof(*volInfoBuffer));
    
    fprintf(stdout, "%*svolInfoSize   = %zd\n", (int) indent, "", volInfoSize);
    FPPrintFields(kVolMountInfoFieldDesc, volInfoBuffer, sizeof(*volInfoBuffer), indent, verbose);

    // If this is an AFP volume, we know the structure of the mount info 
    // data, and thus we print it.  Otherwise we just dump the data as hex.

    if (volInfoBuffer->media == AppleShareMediaType) {
        AFPVolMountInfoPtr afpVolInfoBuffer;

        afpVolInfoBuffer = (AFPVolMountInfoPtr) volInfoBuffer;
        fprintf(stdout, "%*sAppleShareMediaType\n", (int) indent, "");
        FPPrintFields(kAFPVolMountInfoFieldDesc, afpVolInfoBuffer, sizeof(*afpVolInfoBuffer), indent + kStdIndent, verbose);

        if (afpVolInfoBuffer->flags & volMountExtendedFlagsMask) {
            AFPXVolMountInfoPtr afpXVolInfoBuffer;
            
            afpXVolInfoBuffer = (AFPXVolMountInfoPtr) afpVolInfoBuffer;
            FPPrintFields(kAFPXVolMountInfoFieldDesc, afpVolInfoBuffer, sizeof(*afpVolInfoBuffer), indent + kStdIndent, verbose);

            if (afpXVolInfoBuffer->extendedFlags & kAFPExtendedFlagsAlternateAddressMask) {
                FPPrintFields(kAFPXVolMountInfoFieldDesc2, afpVolInfoBuffer, sizeof(*afpVolInfoBuffer), indent + kStdIndent, verbose);
                PrintAlternateAddresses(afpXVolInfoBuffer, afpXVolInfoBuffer->alternateAddressOffset, indent + 2 * kStdIndent);
            }
        }
    } else {
        if (verbose > 0) {
            FPHex("volInfoBuffer", volInfoSize, volInfoBuffer, 4, strlen(kVolMountInfoFieldSpacer), false, NULL);
        }
    }
}
    
#if ! TARGET_RT_64_BIT

static CommandError PrintPBGetVolMountInfo(CommandArgsRef args, uint32_t indent, uint32_t verbose)
    // Uses PBGetVolMountInfo to get information about the specified volume and 
    // prints the result.
    //
    // indent and verbose are as per the comments for FPPrinter.
{
    OSStatus                    err;
    FSVolumeRefNum              volRefNum;
    ParamBlockRec               pb;
    short                       volInfoSize;
    VolumeMountInfoHeaderPtr    volInfoBuffer;

    assert( CommandArgsValid(args) );

    volInfoBuffer = NULL;
    
    // Get the mount info from the file system.
    
    err = CommandArgsGetVRefNum(args, &volRefNum);
    if (err == noErr) {
        pb.ioParam.ioNamePtr = NULL;
        pb.ioParam.ioVRefNum = volRefNum;
        pb.ioParam.ioBuffer  = (Ptr) &volInfoSize;
        err = PBGetVolMountInfoSize(&pb);
    }
    if (err == noErr) {
        assert(volInfoSize >= 0);
        
        volInfoBuffer = malloc(volInfoSize);
        if (volInfoBuffer == NULL) {
            err = memFullErr;
        }
    }
    if (err == noErr) {
        pb.ioParam.ioBuffer = (Ptr) volInfoBuffer;
        err = PBGetVolMountInfo(&pb);
    }
    
    // Print the info.
    
    if (err == noErr) {
        PrintVolumeMountInfo(volInfoSize, volInfoBuffer, indent, verbose);
    }
    
    free(volInfoBuffer);
    
    return CommandErrorMakeWithOSStatus(err);
}

const CommandInfo kPBGetVolMountInfoCommand = {
    PrintPBGetVolMountInfo,
    "PBGetVolMountInfo",
    "itemPath",
    "Print information from PBGetVolMountInfo.",
    NULL
};

#endif

static CommandError PrintFSGetVolumeMountInfo(CommandArgsRef args, uint32_t indent, uint32_t verbose)
    // Uses PBGetVolMountInfo to get information about the specified volume and 
    // prints the result.
    //
    // indent and verbose are as per the comments for FPPrinter.
{
    OSStatus                    err;
    FSVolumeRefNum              volRefNum;
    size_t                      volInfoSize;
    VolumeMountInfoHeaderPtr    volInfoBuffer;
    size_t                      junkSize;

    assert( CommandArgsValid(args) );
    
    if ( FSGetVolumeMountInfoSize == NULL ) {
        return CommandErrorMakeWithCustom(kUnavailableCustomError);
    }

    volInfoBuffer = NULL;
    
    // Get the mount info from the file system.
    
    err = CommandArgsGetVRefNum(args, &volRefNum);
    if (err == noErr) {
        err = FSGetVolumeMountInfoSize(volRefNum, &volInfoSize);
    }
    if (err == noErr) {
        volInfoBuffer = malloc(volInfoSize);
        if (volInfoBuffer == NULL) {
            err = memFullErr;
        }
    }
    if (err == noErr) {
        err = FSGetVolumeMountInfo(volRefNum, (BytePtr) volInfoBuffer, volInfoSize, &junkSize);
    }
    
    // Print the info.
    
    if (err == noErr) {
        PrintVolumeMountInfo(volInfoSize, volInfoBuffer, indent, verbose);
    }
    
    free(volInfoBuffer);
    
    return CommandErrorMakeWithOSStatus(err);
}

const CommandInfo kFSGetVolumeMountInfoCommand = {
    PrintFSGetVolumeMountInfo,
    "FSGetVolumeMountInfo",
    "itemPath",
    "Print information from FSGetVolumeMountInfo.",
    NULL
};

#pragma mark *     FSCopyDiskIDForVolume

static CommandError PrintFSCopyDiskIDForVolume(CommandArgsRef args, uint32_t indent, uint32_t verbose)
    // Uses FSCopyDiskIDForVolume to get information about the specified volume 
    // and prints the result.
    //
    // indent and verbose are as per the comments for FPPrinter.
{
    OSStatus        err;
    FSVolumeRefNum  volRefNum;
    CFStringRef     idStr;

    assert( CommandArgsValid(args) );

    idStr = NULL;
    
    err = CommandArgsGetVRefNum(args, &volRefNum);
    if (err == noErr) {
        err = FSCopyDiskIDForVolume(volRefNum, &idStr);
    }
    if (err == noErr) {
        fprintf(stdout, "%*sFSCopyDiskIDForVolume(%d)\n", (int) indent, "", (int) volRefNum);
        FPCFString("id", sizeof(idStr), &idStr, indent + kStdIndent, strlen("id"), verbose, NULL);
    }
    
    if (idStr != NULL) {
        CFRelease(idStr);
    }

    return CommandErrorMakeWithOSStatus(err);
}

const CommandInfo kFSCopyDiskIDForVolumeCommand = {
    PrintFSCopyDiskIDForVolume,
    "FSCopyDiskIDForVolume",
    "itemPath",
    "Print information from FSCopyDiskIDForVolume.",
    NULL
};

#pragma mark *     FSCopyURLForVolume

static CommandError PrintFSCopyURLForVolume(CommandArgsRef args, uint32_t indent, uint32_t verbose)
    // Uses FSCopyURLForVolume to get information about the specified volume 
    // and prints the result.
    //
    // indent and verbose are as per the comments for FPPrinter.
{
    OSStatus        err;
    FSVolumeRefNum  volRefNum;
    CFURLRef        url;
    CFStringRef     urlStr;

    assert( CommandArgsValid(args) );

    url = NULL;
    
    err = CommandArgsGetVRefNum(args, &volRefNum);
    if (err == noErr) {
        err = FSCopyURLForVolume(volRefNum, &url);
    }
    if (err == noErr) {
        urlStr = CFURLGetString(url);
        
        fprintf(stdout, "%*sFSCopyURLForVolume(%d)\n", (int) indent, "", (int) volRefNum);
        FPCFString("url", sizeof(urlStr), &urlStr, indent + kStdIndent, strlen("url"), verbose, NULL);
    }
    
    if (url != NULL) {
        CFRelease(url);
    }

    return CommandErrorMakeWithOSStatus(err);
}

const CommandInfo kFSCopyURLForVolumeCommand = {
    PrintFSCopyURLForVolume,
    "FSCopyURLForVolume",
    "itemPath",
    "Print information from FSCopyURLForVolume.",
    NULL
};

#pragma mark *     FSGetCatalogInfo

static const FPFlagDesc kFSGetCatalogInfoOptions[] = {
    {kFSCatInfoTextEncoding, "kFSCatInfoTextEncoding"},
    {kFSCatInfoNodeFlags,    "kFSCatInfoNodeFlags"},
    {kFSCatInfoVolume,       "kFSCatInfoVolume"},
    {kFSCatInfoParentDirID,  "kFSCatInfoParentDirID"},
    {kFSCatInfoNodeID,       "kFSCatInfoNodeID"},
    {kFSCatInfoCreateDate,   "kFSCatInfoCreateDate"},
    {kFSCatInfoContentMod,   "kFSCatInfoContentMod"},
    {kFSCatInfoAttrMod,      "kFSCatInfoAttrMod"},
    {kFSCatInfoAccessDate,   "kFSCatInfoAccessDate"},
    {kFSCatInfoBackupDate,   "kFSCatInfoBackupDate"},
    {kFSCatInfoPermissions,  "kFSCatInfoPermissions"},
    {kFSCatInfoFinderInfo,   "kFSCatInfoFinderInfo"},
    {kFSCatInfoFinderXInfo,  "kFSCatInfoFinderXInfo"},
    {kFSCatInfoValence,      "kFSCatInfoValence"},
    {kFSCatInfoDataSizes,    "kFSCatInfoDataSizes"},
    {kFSCatInfoRsrcSizes,    "kFSCatInfoRsrcSizes"},
    {kFSCatInfoSharingFlags, "kFSCatInfoSharingFlags"},
    {kFSCatInfoUserPrivs,    "kFSCatInfoUserPrivs"},
    {kFSCatInfoUserAccess,   "kFSCatInfoUserAccess"},
    {kFSCatInfoFSFileSecurityRef, "kFSCatInfoFSFileSecurityRef"},
    {0, NULL}
};

static const FPFlagDesc kNodeFlags[] = {
    {kFSNodeLockedMask,      "kFSNodeLockedMask"},
    {kFSNodeResOpenMask,     "kFSNodeResOpenMask"},
    {kFSNodeDataOpenMask,    "kFSNodeDataOpenMask"},
    {kFSNodeIsDirectoryMask, "kFSNodeIsDirectoryMask"},
    {kFSNodeCopyProtectMask, "kFSNodeCopyProtectMask"},
    {kFSNodeForkOpenMask,    "kFSNodeForkOpenMask"},
    {kFSNodeHardLinkMask,    "kFSNodeHardLinkMask"},
    { 0, NULL }
};

// These are the fields you get by asking for kFSCatInfoPermissions.

static const FPFieldDesc kFSPermissionInfoFieldDesc[] = {
    {"userID",      offsetof(FSPermissionInfo, userID),     sizeof(UInt32),             FPUID, NULL},
    {"groupID",     offsetof(FSPermissionInfo, groupID),    sizeof(UInt32),             FPGID, NULL},
    {"reserved1",   offsetof(FSPermissionInfo, reserved1),  sizeof(UInt8),              FPUDec, NULL},
    {"userAccess",  0, 0, FPNull, NULL},                                                                  // pads out nameWidth
    {"mode",        offsetof(FSPermissionInfo, mode),       sizeof(UInt16),             FPModeT, NULL},
    {NULL, 0, 0, NULL, NULL}
};

static const FPFlagDesc kSharingFlags[] = {
    {kioFlAttribMountedMask,    "kioFlAttribMountedMask"},
    {kioFlAttribSharePointMask, "kioFlAttribSharePointMask"},
    { 0, NULL }
};

static const FPFlagDesc kAccessFlags[] = {
    {R_OK, "R_OK"},
    {W_OK, "W_OK"},
    {X_OK, "X_OK"},
    { 0, NULL }
};

#if ! TARGET_RT_64_BIT

static const FPFieldDesc kFSSpecFieldDesc[] = {
    {"vRefNum",         offsetof(FSSpec, vRefNum),      sizeof(SInt16),    FPSDec, NULL},
    {"parID",           offsetof(FSSpec, parID),        sizeof(UInt32),    FPUDec, NULL},
    {"name",            offsetof(FSSpec, name),         sizeof(Str63),     FPPString, NULL},
    {NULL, 0, 0, NULL, NULL}
};

#endif

static void PrintCatalogInfo(const HFSUniStr255 *name, FSCatalogInfoBitmap options, bool didForceNodeFlags, const FSCatalogInfo *catInfo, const FSRef *ref, const FSSpec *spec, const FSRef *parent, uint32_t indent, uint32_t verbose)
    // The core of the FSGetCatalogInfo and FSGetCatalogInfoBulk commands.
{
    assert(name != NULL);
    
    HFSUniStr255FieldPrinter("name", sizeof(HFSUniStr255), name, indent, 7, verbose, NULL);
    
    if (catInfo != NULL) {
        const size_t kNameSpacer = strlen("attributeModDate");
        
        fprintf(stdout, "%*scatalogInfo:\n", (int) indent, "");
        
        indent += kStdIndent;
        if ( (options & kFSCatInfoNodeFlags) && ! didForceNodeFlags) {
            FPFlags("nodeFlags", sizeof(catInfo->nodeFlags), &catInfo->nodeFlags, indent, kNameSpacer, verbose, kNodeFlags);
        }
        if (options & kFSCatInfoVolume) {
            FPSDec("volume", sizeof(catInfo->volume), &catInfo->volume, indent, kNameSpacer, verbose, NULL);
        }
        if (options & kFSCatInfoParentDirID) {
            FPUDec("parentDirID", sizeof(catInfo->parentDirID), &catInfo->parentDirID, indent, kNameSpacer, verbose, NULL);
        }
        if (options & kFSCatInfoNodeID) {
            FPUDec("nodeID", sizeof(catInfo->nodeID), &catInfo->nodeID, indent, kNameSpacer, verbose, NULL);
        }
        if (options & kFSCatInfoSharingFlags) {
            FPFlags("sharingFlags", sizeof(catInfo->sharingFlags), &catInfo->sharingFlags, indent, kNameSpacer, verbose, kSharingFlags);
        }
        if (options & kFSCatInfoUserPrivs) {
            FPHex("userPrivileges", sizeof(catInfo->userPrivileges), &catInfo->userPrivileges, indent, kNameSpacer, verbose, NULL);
        }
        if (options & kFSCatInfoCreateDate) {
            FPUTCDateTime("createDate", sizeof(catInfo->createDate), &catInfo->createDate, indent, kNameSpacer, verbose, NULL);
        }
        if (options & kFSCatInfoContentMod) {
            FPUTCDateTime("contentModDate", sizeof(catInfo->contentModDate), &catInfo->contentModDate, indent, kNameSpacer, verbose, NULL);
        }
        if (options & kFSCatInfoAttrMod) {
            FPUTCDateTime("attributeModDate", sizeof(catInfo->attributeModDate), &catInfo->attributeModDate, indent, kNameSpacer, verbose, NULL);
        }
        if (options & kFSCatInfoAccessDate) {
            FPUTCDateTime("accessDate", sizeof(catInfo->accessDate), &catInfo->accessDate, indent, kNameSpacer, verbose, NULL);
        }
        if (options & kFSCatInfoBackupDate) {
            FPUTCDateTime("backupDate", sizeof(catInfo->backupDate), &catInfo->backupDate, indent, kNameSpacer, verbose, NULL);
        }
        if (options & (kFSCatInfoPermissions | kFSCatInfoUserAccess | kFSCatInfoFSFileSecurityRef)) {
            const FSPermissionInfo *    fsPerms;
            
            #if TARGET_RT_64_BIT
                fsPerms = &catInfo->permissions;
            #else
                fsPerms = (const FSPermissionInfo *) catInfo->permissions;
            #endif
            
            if (verbose == 0) {
                FPHex("permissions", sizeof(*fsPerms), fsPerms, indent, kNameSpacer, verbose, NULL);
            } else {
                fprintf(stdout, "%*spermissions:\n", (int) indent, "");

                if (options & kFSCatInfoPermissions) {
                    FPPrintFields(kFSPermissionInfoFieldDesc, fsPerms, sizeof(*fsPerms), indent + kStdIndent, verbose);
                }
                if (options & kFSCatInfoUserAccess) {
                    FPFlags("userAccess", sizeof(fsPerms->userAccess), &fsPerms->userAccess, indent + kStdIndent, strlen("userAccess"), verbose - 1, kAccessFlags);
                }
                if (options & kFSCatInfoFSFileSecurityRef) {
                    FPFSFileSecurityRef("fileSec", sizeof(fsPerms->fileSec), &fsPerms->fileSec, indent + kStdIndent, strlen("userAccess"), verbose - 1, NULL);
                }
            }
            
            if ( (options & kFSCatInfoFSFileSecurityRef) && (fsPerms->fileSec != NULL) ) {
                CFRelease(fsPerms->fileSec);
            }
        }
        if (options & kFSCatInfoFinderInfo) {
            assert(options & kFSCatInfoNodeFlags);
            if (catInfo->nodeFlags & kFSNodeIsDirectoryMask) {
                FPFinderInfo("finderInfo", sizeof(catInfo->finderInfo), &catInfo->finderInfo, indent, kNameSpacer, verbose, (void *) (uintptr_t) kFolderInfo);
            } else {
                FPFinderInfo("finderInfo", sizeof(catInfo->finderInfo), &catInfo->finderInfo, indent, kNameSpacer, verbose, (void *) (uintptr_t) kFileInfo);
            }
        }
        if (options & kFSCatInfoFinderXInfo) {
            assert(options & kFSCatInfoNodeFlags);
            if (catInfo->nodeFlags & kFSNodeIsDirectoryMask) {
                FPFinderInfo("extFinderInfo", sizeof(catInfo->extFinderInfo), &catInfo->extFinderInfo, indent, kNameSpacer, verbose, (void *) (uintptr_t) kFolderInfoExtended);
            } else {
                FPFinderInfo("extFinderInfo", sizeof(catInfo->extFinderInfo), &catInfo->extFinderInfo, indent, kNameSpacer, verbose, (void *) (uintptr_t) kFileInfoExtended);
            }
        }
        if (options & kFSCatInfoDataSizes) {
            FPSize("dataLogicalSize", sizeof(catInfo->dataPhysicalSize), &catInfo->dataLogicalSize, indent, kNameSpacer, verbose, NULL);
            FPSize("dataPhysicalSize", sizeof(catInfo->dataPhysicalSize), &catInfo->dataPhysicalSize, indent, kNameSpacer, verbose, NULL);
        }
        if (options & kFSCatInfoDataSizes) {
            FPSize("rsrcLogicalSize", sizeof(catInfo->rsrcPhysicalSize), &catInfo->rsrcLogicalSize, indent, kNameSpacer, verbose, NULL);
            FPSize("rsrcPhysicalSize", sizeof(catInfo->rsrcPhysicalSize), &catInfo->rsrcPhysicalSize, indent, kNameSpacer, verbose, NULL);
        }
        if (options & kFSCatInfoValence) {
            FPUDec("valence", sizeof(catInfo->valence), &catInfo->valence, indent, kNameSpacer, verbose, NULL);
        }
        if (options & kFSCatInfoTextEncoding) {
            FPEnum("textEncodingHint", sizeof(catInfo->textEncodingHint), &catInfo->textEncodingHint, indent, kNameSpacer, verbose, kTextEncodingEnums);
        }
        indent -= kStdIndent;
    }
    if (ref != NULL) {
        FPUDec("FSRef", sizeof(*ref), ref, indent, 7, verbose, NULL);
    }
    if (spec != NULL) {
        #if ! TARGET_RT_64_BIT
            fprintf(stdout, "%*sFSSpec:\n", (int) indent, "");
            FPPrintFields(kFSSpecFieldDesc, spec, sizeof(*spec), indent + kStdIndent, verbose);
        #endif
    }
    if (parent != NULL) {
        FPUDec("parent", sizeof(*parent), parent, indent, 7, verbose, NULL);
    }
}

static CommandError PrintFSGetCatalogInfo(CommandArgsRef args, uint32_t indent, uint32_t verbose)
    // The implementation of the FSGetCatalogInfo command.
    //
    // indent and verbose are as per the comments for FPPrinter.
{
    OSStatus        err;
    int             options;
    FSRef           ref;
    FSCatalogInfo * catalogInfo;
    FSCatalogInfo   catalogInfoBuf;
    FSRef *         parent;
    FSRef           parentBuf;
    FSSpec *        spec; 
    #if ! TARGET_RT_64_BIT
        FSSpec          specBuf;
    #endif
    HFSUniStr255 *  name;
    HFSUniStr255    nameBuf;
    Boolean         didForceNodeFlags;

    assert( CommandArgsValid(args) );

    name = NULL;
    catalogInfo = NULL;
    spec = NULL;
    parent = NULL;
    didForceNodeFlags = false;
    
    // Get options from arguments.
    
    #if ! TARGET_RT_64_BIT
        if ( CommandArgsGetOptionalConstantString(args, "-spec") ) {
            spec = &specBuf;
        }
    #endif

    if ( CommandArgsGetOptionalConstantString(args, "-parent") ) {
        parent = &parentBuf;
    }

    err = noErr;
    if (CommandArgsIsOption(args)) {
        if (CommandArgsGetOptionalConstantString(args, "-kFSCatInfoGettableInfo")) {
            options = kFSCatInfoGettableInfo;
        } else {
            err = CommandArgsGetFlagListInt(args, kFSGetCatalogInfoOptions, &options);
        }
    } else {
        options = kFSCatInfoNone;
    }
    
    // To print Finder info correctly, we need to know what type of item we're looking at.  So, 
    // if we're getting Finder info but not getting the node flags, force kFSCatInfoNodeFlags 
    // and set didForceNodeFlags so that we know not to print it.
    
    if ( (err == 0) && (options & (kFSCatInfoFinderInfo | kFSCatInfoFinderXInfo)) && !(options & kFSCatInfoNodeFlags) ) {
        didForceNodeFlags = true;
        options |= kFSCatInfoNodeFlags;
    }
    
    if ( (err == noErr) && (options != kFSCatInfoNone) ) {
        catalogInfo = &catalogInfoBuf;
    }

    if (err == noErr) {
        name = &nameBuf;
    }
    
    if (err == noErr) {
        err = CommandArgsGetFSRef(args, &ref);
    }
    if (err == noErr) {
        err = FSGetCatalogInfo(
            &ref,
            options,
            catalogInfo,
            name,
            spec, 
            parent
        );
    }
    if (err == noErr) {
        PrintCatalogInfo(
            name,
            options, 
            didForceNodeFlags, 
            catalogInfo,
            NULL,
            spec,
            parent,
            indent,
            verbose
        );
    }

    return CommandErrorMakeWithOSStatus(err);
}

static const CommandHelpEntry kFSGetCatalogInfoHelp[] = {
    #if ! TARGET_RT_64_BIT
        {CommandHelpString, "-spec      Ask for FSSpec"},
    #endif
    {CommandHelpString, "-parent    Ask for parent FSRef"},
    {CommandHelpString, "-options   Catalog info to request; default is none"},
    {CommandHelpString, "    kFSCatInfoGettableInfo"},
    {CommandHelpFlags,  kFSGetCatalogInfoOptions},
    {NULL, NULL}
};

const CommandInfo kFSGetCatalogInfoCommand = {
    PrintFSGetCatalogInfo,
    "FSGetCatalogInfo",
    #if TARGET_RT_64_BIT
        "[ -parent ] [ -options ] itemPath",
    #else
        "[ -spec ] [ -parent ] [ -options ] itemPath",
    #endif
    "Print information from FSGetCatalogInfo.",
    kFSGetCatalogInfoHelp
};

#pragma mark *     FSGetCatalogInfoBulk

static CommandError PrintFSGetCatalogInfoBulk(CommandArgsRef args, uint32_t indent, uint32_t verbose)
    // The implementation of the FSGetCatalogInfoBulk command.
    //
    // indent and verbose are as per the comments for FPPrinter.
{
    OSStatus        err;
    OSStatus        junk;
    int             options;
    size_t          itemCount;
    FSRef           ref;
    FSIterator      iter;
    FSCatalogInfo * catalogInfos;
    FSRef *         refs;
    FSSpec *        specs; 
    HFSUniStr255 *  names;
    Boolean         didForceNodeFlags;

    assert( CommandArgsValid(args) );

    iter = NULL;
    catalogInfos = NULL;
    refs = NULL;
    specs = NULL;
    names = NULL;
    didForceNodeFlags = false;
    
    // Get options from arguments.
    
    err = noErr;
    itemCount = 64;
    if (CommandArgsGetOptionalConstantString(args, "-count")) {
        err = CommandArgsGetSizeT(args, &itemCount);
        if (itemCount == 0) {
            err = kCommandUsageErr;
        }
    }
    
    if ( (err == noErr) && CommandArgsGetOptionalConstantString(args, "-refs") ) {
        refs = malloc(sizeof(*refs) * itemCount);
        if (refs == NULL) {
            err = memFullErr;
        }
    }

    #if ! TARGET_RT_64_BIT
        if ( (err == noErr) && CommandArgsGetOptionalConstantString(args, "-specs") ) {
            specs = malloc(sizeof(*specs) * itemCount);
            if (specs == NULL) {
                err = memFullErr;
            }
        }
    #endif

    if (err == noErr) {
        if (CommandArgsIsOption(args)) {
            if (CommandArgsGetOptionalConstantString(args, "-kFSCatInfoGettableInfo")) {
                options = kFSCatInfoGettableInfo;
            } else {
                err = CommandArgsGetFlagListInt(args, kFSGetCatalogInfoOptions, &options);
            }
        } else {
            options = kFSCatInfoNone;
        }
    }
    
    // To print Finder info correctly, we need to know what type of item we're looking at.  So, 
    // if we're getting Finder info but not getting the node flags, force kFSCatInfoNodeFlags 
    // and set didForceNodeFlags so that we know not to print it.
    
    if ( (err == 0) && (options & (kFSCatInfoFinderInfo | kFSCatInfoFinderXInfo)) && !(options & kFSCatInfoNodeFlags) ) {
        didForceNodeFlags = true;
        options |= kFSCatInfoNodeFlags;
    }
    
    if ( (err == noErr) && (options != kFSCatInfoNone) ) {
        catalogInfos = malloc(itemCount * sizeof(*catalogInfos));
        if (catalogInfos == NULL) {
            err = memFullErr;
        }
    }

    if (err == noErr) {
        names = malloc(sizeof(*names) * itemCount);
        if (names == NULL) {
            err = memFullErr;
        }
    }
    
    if (err == noErr) {
        err = CommandArgsGetFSRef(args, &ref);
    }
    if (err == noErr) {
        err = FSOpenIterator(&ref, kFSIterateFlat, &iter);
    }
    if (err == noErr) {
        Boolean         firstItem;
        Boolean         done;
        ItemCount       foundItemCount;
        ItemCount       foundItemIndex;
        Boolean         containerChanged;
        
        firstItem = true;
        done = false;
        do {
            err = FSGetCatalogInfoBulk(
                iter,
                itemCount,
                &foundItemCount,
                &containerChanged, 
                options,
                catalogInfos,
                refs, 
                specs, 
                names
            );
            if (err == errFSNoMoreItems) {
                err = noErr;
                done = true;
            }
            if (err == noErr) {
                if (containerChanged) {
                    fprintf(stdout, "*** Container Changed ***\n");
                    firstItem = false;
                }
                for (foundItemIndex = 0; foundItemIndex < foundItemCount; foundItemIndex++) {
                    if ( ! firstItem ) {
                        if ( (catalogInfos != NULL) || (refs != NULL) || (specs != NULL) ) {
                            fprintf(stdout, "\n");
                        }
                    }
                    firstItem = false;
                    
                    PrintCatalogInfo(
                        (names != NULL) ? &names[foundItemIndex] : NULL,
                        options, 
                        didForceNodeFlags, 
                        (catalogInfos != NULL) ? &catalogInfos[foundItemIndex] : NULL,
                        (refs != NULL) ? &refs[foundItemIndex] : NULL,
                        (specs != NULL) ? &specs[foundItemIndex] : NULL,
                        NULL,
                        indent,
                        verbose
                    );
                }
            }
        } while ( (err == noErr) && ! done );
    }

    free(catalogInfos);
    free(refs);
    free(specs);
    free(names);
    if (iter != NULL) {
        junk = FSCloseIterator(iter);
        assert(junk == noErr);
    }

    return CommandErrorMakeWithOSStatus(err);
}

static const CommandHelpEntry kFSGetCatalogInfoBulkHelp[] = {
    {CommandHelpString, "-count Get N items at a time (default is 64)"},
    {CommandHelpString, "-refs  Ask for FSRefs"},
#if ! TARGET_RT_64_BIT
    {CommandHelpString, "-specs Ask for FSSpecs"},
#endif
    {CommandHelpString, "-opts  Catalog info to request; default is none"},
    {CommandHelpString, "    kFSCatInfoGettableInfo"},
    {CommandHelpFlags,  kFSGetCatalogInfoOptions},
    {NULL, NULL}
};

const CommandInfo kFSGetCatalogInfoBulkCommand = {
    PrintFSGetCatalogInfoBulk,
    "FSGetCatalogInfoBulk",
    "[ -count N ] [ -refs ]"
    #if ! TARGET_RT_64_BIT
        " [ -specs ]"
    #endif
    " [ -opts ] itemPath",
    "Iterates a directory using FSGetCatalogInfoBulk.",
    kFSGetCatalogInfoBulkHelp
};

#pragma mark *     PBDTGetComment

#if ! TARGET_RT_64_BIT

static CommandError PrintPBDTGetComment(CommandArgsRef args, uint32_t indent, uint32_t verbose)
    // The implementation of the PBDTGetComment command.
    //
    // indent and verbose are as per the comments for FPPrinter.
{
    OSStatus        err;
    FSRef           itemRef;
    FSSpec          itemSpec;
    DTPBRec         pb;
    SInt16          dtRef;
    Str255          comment;

    assert( CommandArgsValid(args) );
    
    dtRef = 0;
    
    err = CommandArgsGetFSRef(args, &itemRef);
    if (err == noErr) {
        err = FSGetCatalogInfo(&itemRef, kFSCatInfoNone, NULL, NULL, &itemSpec, NULL);
    }
    if (err == noErr) {
        pb.ioNamePtr = NULL;
        pb.ioVRefNum = itemSpec.vRefNum;
        err = PBDTGetPath(&pb);
        
        if (err == noErr) {
            dtRef = pb.ioDTRefNum;
        }
    }
    if (err == noErr) {
        pb.ioDTRefNum   = dtRef;
        pb.ioDirID      = itemSpec.parID;
        pb.ioNamePtr    = itemSpec.name;
        pb.ioDTBuffer   = (char *) &comment[1];
        pb.ioDTReqCount = sizeof(comment) - 1;

        err = PBDTGetCommentSync(&pb);
        if (err == noErr) {
            comment[0] = (unsigned char)pb.ioDTActCount;
        }
    }
    if (err == noErr) {
        FPPString("comment", sizeof(comment), comment, indent + kStdIndent, strlen("comment"), verbose, NULL);
    }

    return CommandErrorMakeWithOSStatus(err);
}

const CommandInfo kPBDTGetCommentCommand = {
    PrintPBDTGetComment,
    "PBDTGetComment",
    "itemPath",
    "Return desktop comment for item.",
    NULL
};

#endif
