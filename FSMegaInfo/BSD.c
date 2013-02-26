/*
    File:       BSD.c

    Contains:   BSD command processing.

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

#include "BSD.h"

#include <sys/stat.h>
#include <sys/mount.h>
#include <sys/vnode.h>
#include <stdint.h>
#include <inttypes.h>
#include <unistd.h>
#include <dirent.h>
#include <sys/xattr.h>
#include <fts.h>

#include "FieldPrinter.h"
#include "Command.h"

/////////////////////////////////////////////////////////////////
#pragma mark ****** Utilities

static int GetFSList(struct statfs **fsList, int *fsCountPtr)
    // If fsBuf is too small to account for all volumes, getfsstat will 
    // silently truncate the returned information.  Worse yet, it returns 
    // the number of volumes it passed back, not the number of volumes present, 
    // so you can't tell if the list was truncated. 
    //
    // So, in order to get an accurate snapshot of the volume list, I call 
    // getfsstat with a NULL fsBuf to get a count (fsCountOrig), then allocate a 
    // buffer that holds (fsCountOrig + 1) items, then call getfsstat again with 
    // that buffer.  If the list was silently truncated, the second count (fsCount)
    // will be (fsCountOrig + 1), and we loop to try again.
{
    int                 err;
    int                 fsCountOrig;
    int                 fsCount;
    struct statfs *     fsBuf;
    bool                done;

    assert( fsList  != NULL);
    assert(*fsList  == NULL);
    assert(fsCountPtr != NULL);

    fsBuf = NULL;
    fsCount = 0;
    
    done = false;
    do {
        // Get the initial count.
        
        err = 0;
        fsCountOrig = getfsstat(NULL, 0, MNT_WAIT);
        if (fsCountOrig < 0) {
            err = errno;
        }
        
        // Allocate a buffer for fsCountOrig + 1 items.
        
        if (err == 0) {
            if (fsBuf != NULL) {
                free(fsBuf);
            }
            fsBuf = malloc((fsCountOrig + 1) * sizeof(*fsBuf));
            if (fsBuf == NULL) {
                err = ENOMEM;
            }
        }
        
        // Get the list.  
        
        if (err == 0) {
            fsCount = getfsstat(fsBuf, (int) ((fsCountOrig + 1) * sizeof(*fsBuf)), MNT_WAIT);
            if (fsCount < 0) {
                err = errno;
            }
        }
        
        // We got the full list if the number of items returned by the kernel 
        // is strictly less than the buffer that we allocated (fsCountOrig + 1).
        
        if (err == 0) {
            if (fsCount <= fsCountOrig) {
                done = true;
            }
        }
    } while ( (err == 0) && ! done );
    
    // Clean up.
    
    if (err != 0) {
        free(fsBuf);
        fsBuf = NULL;
    }
    *fsList     = fsBuf;
    *fsCountPtr = fsCount;
    
    assert( (err == 0) == (*fsList != NULL) );
    
    return err;
}

static int MyLStatFS(const char *itemPath, struct statfs *sfsb)
    // There is no lstatfs <rdar://problem/4154584>, so I have to emulate 
    // this myself.  I do this by calling lstat on the path and 
    // then looking through the volume list calling lstat 
    // on the root directory of each entry; if the st_dev fields 
    // match, we're on the right file volume.
{
    int             err;
    struct statfs * fsList;
    int             fsCount;
    int             fsIndex;
    struct stat     itemInfo;
    struct stat     fsRootInfo;
    bool            found;
    
    assert(itemPath != NULL);
    assert(sfsb != NULL);
    
    fsList = NULL;
    
    err = lstat(itemPath, &itemInfo);
    if (err < 0) {
        err = errno;
    }
    if (err == 0) {
        err = GetFSList(&fsList, &fsCount);
    }
    if (err == 0) {
        found = false;
        
        for (fsIndex = 0; fsIndex < fsCount; fsIndex++) {
            err = lstat(fsList[fsIndex].f_mntonname, &fsRootInfo);
            if ( (err == 0) && (fsRootInfo.st_dev == itemInfo.st_dev) ) {
                *sfsb = fsList[fsIndex];
                found = true;
                break;
            }
        }
        
        // It's possible that one of the volumes in fsList could disappear 
        // while we're looking for a match.  If so, we either swallow the 
        // error (if we did find a match) or return ENOENT (otherwise).  The 
        // latter is what statfs would do if the itemPath was bogus.
        
        if (found) {
            err = 0;
        } else {
            err = ENOENT;
        }
    }
    
    free(fsList);

    return err;
}

/////////////////////////////////////////////////////////////////
#pragma mark ****** Commands

#pragma mark *     stat/lstat

// Flag in st_flags and the ATTR_CMN_FLAGS attribute.

const FPFlagDesc kChFlagsFlags[] = {
    { UF_NODUMP,    "UF_NODUMP"    },
    { UF_IMMUTABLE, "UF_IMMUTABLE" },
    { UF_APPEND,    "UF_APPEND"    },
    { UF_OPAQUE,    "UF_OPAQUE"    },
    { SF_ARCHIVED,  "SF_ARCHIVED"  },
    { SF_IMMUTABLE, "SF_IMMUTABLE" },
    { SF_APPEND,    "SF_APPEND"    },
    { 0, NULL }
};

// Fields of (struct stat).

static const FPFieldDesc kStatFieldDesc[] = { 
    {"st_dev",          offsetof(struct stat, st_dev),      sizeof(dev_t),              FPDevT, NULL},
    {"st_ino",          offsetof(struct stat, st_ino),      sizeof(ino_t),              FPUDec, NULL},
    {"st_mode",         offsetof(struct stat, st_mode),     sizeof(mode_t),             FPModeT, NULL},
    {"st_nlink",        offsetof(struct stat, st_nlink),    sizeof(nlink_t),            FPUDec, NULL},
    {"st_uid",          offsetof(struct stat, st_uid),      sizeof(uid_t),              FPUID, NULL},
    {"st_gid",          offsetof(struct stat, st_gid),      sizeof(gid_t),              FPGID, NULL},
    {"st_rdev",         offsetof(struct stat, st_rdev),     sizeof(dev_t),              FPDevT, NULL},
    {"st_atime",        offsetof(struct stat, st_atime),    sizeof(struct timespec),    FPTimeSpec, NULL},
    {"st_mtime",        offsetof(struct stat, st_mtime),    sizeof(struct timespec),    FPTimeSpec, NULL},
    {"st_ctime",        offsetof(struct stat, st_ctime),    sizeof(struct timespec),    FPTimeSpec, NULL},
    {"st_size",         offsetof(struct stat, st_size),     sizeof(off_t),              FPSize, NULL},
    {"st_blocks",       offsetof(struct stat, st_blocks),   sizeof(blkcnt_t),           FPUDec, NULL},
    {"st_blksize",      offsetof(struct stat, st_blksize),  sizeof(blksize_t),          FPUDec, NULL},
    {"st_flags",        offsetof(struct stat, st_flags),    sizeof(__uint32_t),         FPFlags, kChFlagsFlags},
    {"st_gen",          offsetof(struct stat, st_gen),      sizeof(__uint32_t),         FPUDec, NULL},
    {"st_lspare",       offsetof(struct stat, st_lspare),   sizeof(__int32_t),          FPNull, NULL},
    {"st_qspare",       offsetof(struct stat, st_qspare),   sizeof(__int64_t),          FPNull, NULL},
    {NULL, 0, 0, NULL, NULL}
};

static CommandError PrintStatInfoCommon(CommandArgsRef args, uint32_t indent, uint32_t verbose, bool lStat)
    // Uses lstat to get information about the specified item and 
    // prints the result.
    //
    // indent and verbose are as per the comments for FPPrinter.
{
    int             err;
    struct stat     sb;
    const char *    itemPath;

    assert( CommandArgsValid(args) );

    err = CommandArgsGetString(args, &itemPath);
    if (err == 0) {
        if (lStat) {
            fprintf(stdout, "%*slstat '%s'\n", (int) indent, "", itemPath);

            err = lstat(itemPath, &sb);
        } else {
            fprintf(stdout, "%*sstat '%s'\n", (int) indent, "", itemPath);

            err = stat(itemPath, &sb);
        }
        if (err < 0) {
            err = errno;
        }
    }
    
    if (err == 0) {
        FPPrintFields(kStatFieldDesc, &sb, sizeof(sb), indent + kStdIndent, verbose);
    }
    
    return CommandErrorMakeWithErrno(err);
}

static CommandError PrintStatInfo(CommandArgsRef args, uint32_t indent, uint32_t verbose)
{
    assert( CommandArgsValid(args) );
    return PrintStatInfoCommon(args, indent, verbose, false);
}

static CommandError PrintLStatInfo(CommandArgsRef args, uint32_t indent, uint32_t verbose)
{
    assert( CommandArgsValid(args) );
    return PrintStatInfoCommon(args, indent, verbose, true);
}

const CommandInfo kStatCommand = {
    PrintStatInfo,
    "stat",
    "itemPath",
    "Print information from stat.",
    NULL
};

const CommandInfo kLStatCommand = {
    PrintLStatInfo,
    "lstat",
    "itemPath",
    "Print information from lstat.",
    NULL
};

#pragma mark *     access

static const FPFlagDesc kAccessOptions[] = {
    {R_OK,          "R_OK"},
    {W_OK,          "W_OK"},
    {X_OK,          "X_OK"},
    {_READ_OK,      "_READ_OK"},
    {_WRITE_OK,     "_WRITE_OK"},
    {_EXECUTE_OK,   "_EXECUTE_OK"},
    {_DELETE_OK,    "_DELETE_OK"},
    {_APPEND_OK,    "_APPEND_OK"},
    {_RMFILE_OK,    "_RMFILE_OK"},
    {_RATTR_OK,     "_RATTR_OK"},
    {_WATTR_OK,     "_WATTR_OK"},
    {_REXT_OK,      "_REXT_OK"},
    {_WEXT_OK,      "_WEXT_OK"},
    {_RPERM_OK,     "_RPERM_OK"},
    {_WPERM_OK,     "_WPERM_OK"},
    {_CHOWN_OK,     "_CHOWN_OK"},
    {0, NULL}
};

static CommandError PrintAccessInfo(CommandArgsRef args, uint32_t indent, uint32_t verbose)
{
    #pragma unused(indent)
    #pragma unused(verbose)
    int             err;
    int             options;
    const char *    itemPath;

    assert( CommandArgsValid(args) );
    
    if (CommandArgsIsOption(args)) {
        err = CommandArgsGetFlagListInt(args, kAccessOptions, &options);
    } else {
        options = R_OK | W_OK | X_OK;
        err = 0;
    }
    
    // Get item path argument.
    
    if (err == 0) {
        err = CommandArgsGetString(args, &itemPath);
    }
    
    if (err == 0) {
        // *** command summary should include the access requested
        fprintf(stdout, "%*saccess '%s'\n", (int) indent, "", itemPath);
        err = access(itemPath, options);
        if (err < 0) {
            err = errno;
        }
        if (err == 0) {
            fprintf(stdout, "%*sOK\n", (int) indent, "");
        }
    }
    
    return CommandErrorMakeWithErrno(err);
}

static const CommandHelpEntry kAccessCommandHelp[] = {
    {CommandHelpString, "-options Access options; default is -R_OK,W_OK,X_OK"},
    {CommandHelpFlags,  kAccessOptions},
    {NULL, NULL}
};

const CommandInfo kAccessCommand = {
    PrintAccessInfo,
    "access",
    "[ -options ] itemPath",
    "Print information from lstat.",
    kAccessCommandHelp
};

#pragma mark *     statfs

// Flags for the f_flags field of the statfs structure.

const FPFlagDesc kMountFlags[] = { 
    {MNT_RDONLY,                "MNT_RDONLY"},
    {MNT_SYNCHRONOUS,           "MNT_SYNCHRONOUS"},
    {MNT_NOEXEC,                "MNT_NOEXEC"},
    {MNT_NOSUID,                "MNT_NOSUID"},
    {MNT_NODEV,                 "MNT_NODEV"},
    {MNT_UNION,                 "MNT_UNION"},
    {MNT_ASYNC,                 "MNT_ASYNC"},
    {MNT_DONTBROWSE,            "MNT_DONTBROWSE"},
    {MNT_IGNORE_OWNERSHIP,      "MNT_IGNORE_OWNERSHIP"},
    {MNT_AUTOMOUNTED,           "MNT_AUTOMOUNTED"},
    {MNT_JOURNALED,             "MNT_JOURNALED"},
    {MNT_NOUSERXATTR,           "MNT_NOUSERXATTR"},
    {MNT_DEFWRITE,              "MNT_DEFWRITE"},
    {MNT_MULTILABEL,            "MNT_MULTILABEL"},
    {MNT_NOATIME,               "MNT_NOATIME"},

    {MNT_EXPORTED,              "MNT_EXPORTED"},

    {MNT_LOCAL,                 "MNT_LOCAL"},
    {MNT_QUOTA,                 "MNT_QUOTA"},
    {MNT_ROOTFS,                "MNT_ROOTFS"},
    {MNT_DOVOLFS,               "MNT_DOVOLFS"},
    {0, NULL} 
};

// The following mount flags were removed from the 10.4 headers.  Rather 
// than try to do clever things to display them correctly on old systems, 
// I just decided to remove them.
//
//    {MNT_EXRDONLY,              "MNT_EXRDONLY"},
//    {MNT_DEFEXPORTED,           "MNT_DEFEXPORTED"},
//    {MNT_EXPORTANON,            "MNT_EXPORTANON"},
//    {MNT_EXKERB,                "MNT_EXKERB"},
//    {MNT_FIXEDSCRIPTENCODING,   "MNT_FIXEDSCRIPTENCODING"},


// Size multipliers for fields in the statfs structure.  See 
// FPSize for a description of what this is about.

static const FPSizeMultiplier kStatFSBlocksMultiplier = {
    offsetof(struct statfs, f_bsize) - offsetof(struct statfs, f_blocks),
    sizeof(long)
};

static const FPSizeMultiplier kStatFSFreeBlocksMultiplier = {
    offsetof(struct statfs, f_bsize) - offsetof(struct statfs, f_bfree),
    sizeof(long)
};

static const FPSizeMultiplier kStatFSAvailBlocksMultiplier = {
    offsetof(struct statfs, f_bsize) - offsetof(struct statfs, f_bavail),
    sizeof(long)
};

// Known constants for f_type field of statfs, from Darwin source 
// (xnu/bsd/vfs/vfs_conf.c).

const FPEnumDesc kFSTypeEnums[] = {
    { 17, "HFS/HFS Plus"        },      
    { 1,  "UFS"                 },               
    { 14, "ISO 9660"            },          
    { 3,  "Memory File System"  },
    { 2,  "NFS"                 },               
    { 13, "AndrewFS"            },          
    { 9,  "Loopback (nullfs)"   },            
    { 15, "Union"               },             
    { 7,  "File Descriptor"     },   
    { 18, "Volume ID (volfs)"   },             
    { 19, "Device (devfs)"      },             
    { 0,  NULL                  },                
};

// The fields of the statfs structure.

static const FPFieldDesc kStatFSFieldDesc[] = { 
    {"f_bsize",         offsetof(struct statfs, f_bsize),       sizeof(long),   FPSize, NULL},
    {"f_iosize",        offsetof(struct statfs, f_iosize),      sizeof(long),   FPSize, NULL},
    {"f_blocks",        offsetof(struct statfs, f_blocks),      sizeof(long),   FPSize, &kStatFSBlocksMultiplier},
    {"f_bfree",         offsetof(struct statfs, f_bfree),       sizeof(long),   FPSize, &kStatFSFreeBlocksMultiplier},
    {"f_bavail",        offsetof(struct statfs, f_bavail),      sizeof(long),   FPSize, &kStatFSAvailBlocksMultiplier},
    {"f_files",         offsetof(struct statfs, f_files),       sizeof(long),   FPSDec, NULL},
    {"f_ffree",         offsetof(struct statfs, f_ffree),       sizeof(long),   FPSDec, NULL},
    {"f_fsid.val[0]",   offsetof(struct statfs, f_fsid.val[0]), sizeof(int32_t),FPHex, NULL},
    {"f_fsid.val[1]",   offsetof(struct statfs, f_fsid.val[1]), sizeof(int32_t),FPHex, NULL},
    {"f_owner",         offsetof(struct statfs, f_owner),       sizeof(uid_t),  FPUID, NULL},
    {"f_reserved1",     offsetof(struct statfs, f_reserved1),   sizeof(short),  FPSDec, NULL},        // file system subtype on 10.4 and later
    {"f_type",          offsetof(struct statfs, f_type),        sizeof(short),  FPEnum, kFSTypeEnums},
    {"f_flags",         offsetof(struct statfs, f_flags),       sizeof(long),   FPFlags, kMountFlags},
    {"f_fstypename",    offsetof(struct statfs, f_fstypename),  MFSNAMELEN,     FPCString, NULL},
    {"f_mntonname",     offsetof(struct statfs, f_mntonname),   MNAMELEN,       FPCString, NULL},
    {"f_mntfromname",   offsetof(struct statfs, f_mntfromname), MNAMELEN,       FPCString, NULL},
    {NULL, 0, 0, NULL, NULL}
};

static CommandError PrintStatFSInfoCommon(CommandArgsRef args, uint32_t indent, uint32_t verbose, bool lStat)
    // Uses statfs to get information about the specified volume and 
    // prints the result.
    //
    // indent and verbose are as per the comments for FPPrinter.
{
    int             err;
    struct statfs   sfsb;
    const char *    itemPath;

    assert( CommandArgsValid(args) );
    
    err = CommandArgsGetString(args, &itemPath);
    if (err == 0) {
        if ( lStat ) {
            fprintf(stdout, "%*slstatfs '%s'\n", (int) indent, "", itemPath);

            err = MyLStatFS(itemPath, &sfsb);
        } else {
            fprintf(stdout, "%*sstatfs '%s'\n", (int) indent, "", itemPath);

            err = statfs(itemPath, &sfsb);
            if (err < 0) {
                err = errno;
            }
        }
    }
    if (err == 0) {
        FPPrintFields(kStatFSFieldDesc, &sfsb, sizeof(sfsb), indent + kStdIndent, verbose);
    }
    
    return CommandErrorMakeWithErrno(err);
}

static CommandError PrintStatFSInfo(CommandArgsRef args, uint32_t indent, uint32_t verbose)
{
    assert( CommandArgsValid(args) );
    return PrintStatFSInfoCommon(args, indent, verbose, false);
}

static CommandError PrintLStatFSInfo(CommandArgsRef args, uint32_t indent, uint32_t verbose)
{
    assert( CommandArgsValid(args) );
    return PrintStatFSInfoCommon(args, indent, verbose, true);
}

const CommandInfo kStatFSCommand = {
    PrintStatFSInfo,
    "statfs",
    "itemPath",
    "Print information from statfs.",
    NULL
};

const CommandInfo kLStatFSCommand = {
    PrintLStatFSInfo,
    "lstatfs",
    "itemPath",
    "Print information from lstatfs compatibility code.",
    NULL
};

#pragma mark *     getfsstat

static CommandError PrintGetFSStatInfo(CommandArgsRef args, uint32_t indent, uint32_t verbose)
{
    int                 err;
    int                 fsCount;
    int                 fsIndex;
    struct statfs *     fsBuf;
    bool                raw;

    assert( CommandArgsValid(args) );

    fsBuf = NULL;

    // Get the list of mounted file systems.
    
    raw = CommandArgsGetOptionalConstantString(args, "-r");
    
    if ( raw ) {
        fprintf(stdout, "%*sgetfsstat (single call)\n", (int) indent, "");

        // In raw mode, just call getfsstat once.
        
        fsCount = 64;
        fsBuf = malloc( sizeof(*fsBuf) * fsCount );
        err = 0;
        if (fsBuf == NULL) {
            err = ENOMEM;
        }
        if (err == 0) {
            fsCount = getfsstat(fsBuf, (int) (fsCount * sizeof(*fsBuf)), MNT_WAIT);
            if (fsCount < 0) {
                err = errno;
            }
        }
    } else {
        fprintf(stdout, "%*sgetfsstat\n", (int) indent, "");

        // By default, use complex code to guarantee that we can 
        // a complete snapshot of the file system list.
        
        err = GetFSList(&fsBuf, &fsCount);
    }
    
    // Print information about each file system.
    
    if (err == 0) {
        for (fsIndex = 0; fsIndex < fsCount; fsIndex++) {
            fprintf(stdout, "%*s%s\n", (int) (indent + kStdIndent), "", fsBuf[fsIndex].f_mntonname);
            if (verbose > 0) {
                FPPrintFields(kStatFSFieldDesc, &fsBuf[fsIndex], sizeof(fsBuf[fsIndex]), indent + 2 * kStdIndent, verbose - 1);
            }
        }
    }
    
    // Clean up.
    
    free(fsBuf);
    
    return CommandErrorMakeWithErrno(err);
}

static const CommandHelpEntry kGetFSStatCommandHelp[] = {
    {CommandHelpString, "-r Raw; use a single call to getfsstat"},
    {NULL, NULL}
};

const CommandInfo kGetFSStatCommand = {
    PrintGetFSStatInfo,
    "getfsstat",
    "[ -r ]",
    "Print file system list from getfsstat.",
    kGetFSStatCommandHelp
};

#pragma mark *     getdirentries

static const FPEnumDesc kDirTypes[] = {
    { DT_UNKNOWN, "DT_UNKNOWN" },
    { DT_FIFO,    "DT_FIFO" },
    { DT_CHR,     "DT_CHR" },
    { DT_DIR,     "DT_DIR" },
    { DT_BLK,     "DT_BLK" },
    { DT_REG,     "DT_REG" },
    { DT_LNK,     "DT_LNK" },
    { DT_SOCK,    "DT_SOCK" },
    { DT_WHT,     "DT_WHT" },
    { 0, NULL }
};

static const char kDirEntFieldSpacer[] = "bytesRead";

static const FPFieldDesc kDirEntFieldDesc[] = { 
    {"d_ino",           offsetof(struct dirent, d_ino),         sizeof(ino_t),          FPUDec, NULL},
    {"d_reclen",        offsetof(struct dirent, d_reclen),      sizeof(__uint16_t),     FPUDec, NULL},
    {"d_type",          offsetof(struct dirent, d_type),        sizeof(__uint8_t),      FPEnum, kDirTypes},
    {"d_namlen",        offsetof(struct dirent, d_namlen),      sizeof(__uint8_t),      FPUDec, NULL},
    {"d_name",          offsetof(struct dirent, d_name),        __DARWIN_MAXNAMLEN + 1, FPCString, NULL},
    {kDirEntFieldSpacer, 0,  0, FPNull, NULL},      // present to pad out field widths
    {NULL, 0, 0, NULL, NULL}
};

static void PrintDirEnt(bool firstCall, off_t fileOffset, const char *offsetFieldName, struct dirent *ent, uint32_t indent, uint32_t verbose, bool raw)
    // Prints a (struct dirent).  Can be called by the getdirentries and readdir 
    // commands.
{
    char            tmp[32];
    const char *    typeStr;
    size_t          enumIndex;
    
    assert(offsetFieldName != NULL);
    assert(ent != NULL);
    
    if (verbose == 0) {
        // Print as columns.
        
        if ( raw || (ent->d_ino != 0) ) {
            enumIndex = FPFindEnumByValue(kDirTypes, ent->d_type);
            if (enumIndex == kFPNotFound) {
                snprintf(tmp, sizeof(tmp), "%u", (unsigned int) ent->d_type);
                typeStr = tmp;
            } else {
                typeStr = kDirTypes[enumIndex].enumName;
            }
            fprintf(
                stdout, 
                "%*s%*s %8llu '%s'\n", 
                (int) indent, "", 
                - (int) strlen("DT_UNKNOWN"), typeStr, 
                (unsigned long long) ent->d_ino, 
                ent->d_name
            );
        }
    } else {
        // Print as individual records.

        if ( ! firstCall ) {
            fprintf(stdout, "\n");
        }
        FPUDec(offsetFieldName, sizeof(fileOffset), &fileOffset, indent, strlen(kDirEntFieldSpacer), verbose, NULL);
        FPPrintFields(kDirEntFieldDesc, ent, sizeof(*ent), indent, verbose);
    }
}

static CommandError PrintGetDirEntriesInfo(CommandArgsRef args, uint32_t indent, uint32_t verbose)
    // Implements the getdirentries command.
{
    int                 err;
    int                 junk;
    int                 bufSize;
    const char *        dirPath;
    char *              buf;
    int                 dirFD;
    bool                raw;
    
    assert( CommandArgsValid(args) );

    buf = NULL;
    dirFD = -1;
    
    // Process -r argument.
    
    raw = CommandArgsGetOptionalConstantString(args, "-r");
    
    // Process optional -bufSize argument.
    
    // st_blksize is a blksize_t; getdirentries's nbytes arg is an int;
    // so, I've chosen to use int to represent the buffer size.

    err = 0;
    bufSize = 0;                // indicates to use stat to get the buffer size
    if ( CommandArgsGetOptionalConstantString(args, "-bufSize") ) {
        err = CommandArgsGetInt(args, &bufSize);
        if ( (err == 0) && (bufSize <= 0) ) {
            err = EUSAGE;
        }
    }
    
    // Get directory path.
    
    if (err == 0) {
        err = CommandArgsGetString(args, &dirPath);
    }
    
    // If we're using the default buffer size, get it from stat.
    
    if ( (err == 0) && (bufSize == 0) ) {
        struct stat sb;
        
        err = stat(dirPath, &sb);
        if (err < 0) {
            err = errno;
        }
        if (err == 0) {
            bufSize = (int) sb.st_blksize;
            assert( ((blksize_t) bufSize) == sb.st_blksize);
        }
    }
    
    // Allocate the buffer.
    
    if (err == 0) {
        buf = (char *) malloc(bufSize);
        if (buf == NULL) {
            err = ENOMEM;
        }
    }
    
    // Open the directory.
    
    if (err == 0) {
        dirFD = open(dirPath, O_RDONLY);
        if (dirFD < 0) {
            err = errno;
        }
    }
    
    // Loop until we run out of entries.
    
    if (err == 0) {
        int     bytesRead;
        long    base;
        off_t   fileOffset;
        bool    first;
        
        first = true;
        fileOffset = 0;
        do {
            bytesRead = getdirentries(dirFD, buf, bufSize, &base);
            if (bytesRead < 0) {
                err = errno;
            } else if (bytesRead > 0) {
                char *          cursor;
                char *          limit;
                struct dirent * thisEnt;
                // Print each entry in the buffer.
                
                if (verbose > 1) {
                    if ( ! first ) {
                        fprintf(stdout, "\n");
                    }
                    first = false;
                    FPSDec("bytesRead", sizeof(bytesRead), &bytesRead, indent + kStdIndent, strlen(kDirEntFieldSpacer), verbose, NULL);
                    FPHex("base", sizeof(base), &base, indent + kStdIndent, strlen(kDirEntFieldSpacer), verbose, NULL);
                }
                
                limit  = buf + bytesRead;
                cursor = buf;
                do {
                    // Check for expected termination.
                    
                    if (cursor == limit) {
                        // Exactly at end buffer, end of this block of dirents.
                        // This used to be a >= test, but there's no point doing 
                        // that because a) if this is the first iteration, the 
                        // check can't apply, and b) if this is a subsequent iteration, 
                        // the next check (that the dirent is entirely contained 
                        // within the buffer) would have stopped us on the previous 
                        // iteration.
                        break;
                    }
                    
                    // Check for unexpected termination, that is, running off the 
                    // end of the buffer.  There are two checks here.  The first 
                    // checks that we have enough buffer space to read a meaningful 
                    // thisEnt->d_reclen.  The second checks that, given that record 
                    // length, the entire record fits in the buffer.
                    
                    thisEnt = (struct dirent *) cursor;
                    if (   ((cursor + offsetof(struct dirent, d_reclen) + sizeof(thisEnt->d_reclen)) > limit)
                        || ((cursor + thisEnt->d_reclen) > limit) ) {
                        fprintf(stderr, "dirent not fully contained within buffer\n");
                        err = EINVAL;
                        break;
                    }
                    
                    // readdir checks that each entry starts at a multiple of 
                    // 4 bytes.  We implement roughly the same check by checking that 
                    // each entry is a multiple of 4 bytes long.  
                    
                    if ( (thisEnt->d_reclen & 3) != 0) {
                        static bool sPrinted;
                        
                        if ( ! sPrinted ) {
                            fprintf(stderr, "d_reclen is not a multiple of 4; readdir will be unhappy.\n");
                            sPrinted = true;
                        }
                    }
                    
                    // Print the entry.
                    
                    PrintDirEnt(first, fileOffset, "offset", thisEnt, indent + kStdIndent, verbose, raw);
                    first = false;
                    fileOffset += thisEnt->d_reclen;
                    
                    cursor += thisEnt->d_reclen;
                } while (true);
            }
        } while ( (err == 0) && (bytesRead != 0) );
    }
    
    // Clean up.
    
    if (dirFD != -1) {
        junk = close(dirFD);
        assert(junk == 0);
    }
    free(buf);
    
    return CommandErrorMakeWithErrno(err);
}

static const CommandHelpEntry kGetDirEntriesCommandHelp[] = {
    {CommandHelpString, "-r       Raw; print entries with a 0 inode number"},
    {CommandHelpString, "-bufSize Use a buffer size of N bytes; default is the device block size"},
    {NULL, NULL}
};

const CommandInfo kGetDirEntriesCommand = {
    PrintGetDirEntriesInfo,
    "getdirentries",
    "[ -r ] [ -bufSize N ] dirPath",
    "Lists a directory using getdirentries.",
    kGetDirEntriesCommandHelp
};
// -r implies print directory entries even if they have a 0 inode number

#pragma mark *     readdir

static CommandError PrintReadDirInfo(CommandArgsRef args, uint32_t indent, uint32_t verbose)
    // Implements the readdir command.
{
    int                 err;
    int                 junk;
    const char *        dirPath;
    DIR *               dirp;
    bool                raw;
    
    assert( CommandArgsValid(args) );
    
    dirp = NULL;
    
    // Process -r argument.
    
    raw = CommandArgsGetOptionalConstantString(args, "-r");

    // Get directory path.
    
    err = CommandArgsGetString(args, &dirPath);
    
    // Open directory.

    if (err == 0) {
        errno = 0;
        
        dirp = opendir(dirPath);
        if (dirp == NULL) {
            err = errno;
            if (err == 0) {
                err = ENOTTY;               // no idea
            }
        }
    }
    
    // Loop over contents.
    
    if (err == 0) {
        struct dirent * thisEnt;
        off_t           fileOffset;
        bool            first;

        first = true;
        do {
            fileOffset = telldir(dirp);
            
            thisEnt = readdir(dirp);
            if (thisEnt != NULL) {
                PrintDirEnt(first, fileOffset, "telldir", thisEnt, indent + kStdIndent, verbose, raw);
                first = false;
            }
        } while (thisEnt != NULL);
    }
    
    // Clean up.
    
    if (dirp != NULL) {
        junk = closedir(dirp);
        assert(junk == 0);
    }

    return CommandErrorMakeWithErrno(err);
}

static const CommandHelpEntry kReadDirCommandHelp[] = {
    {CommandHelpString, "-r Raw; print entries with a 0 inode number"},
    {NULL, NULL}
};

const CommandInfo kReadDirCommand = {
    PrintReadDirInfo,
    "readdir",
    "[ -r ] dirPath",
    "Lists a directory using readdir.",
    kReadDirCommandHelp
};

#pragma mark *     listxattr

static CommandError PrintListXAttrInfo(CommandArgsRef args, uint32_t indent, uint32_t verbose)
    // Implements the listxattr command.
{
    #pragma unused(verbose)
    int                 err;
    size_t              bufSize;
    const char *        itemPath;
    int                 options;
    char *              buf;
    ssize_t             listResult;
        
    assert( CommandArgsValid(args) );

    listResult = 0;         // quieten warning
    
    buf = NULL;
    
    // Get XATTR_NOFOLLOW option, if any.
    
    options = 0;
    if ( CommandArgsGetOptionalConstantString(args, "-XATTR_NOFOLLOW") ) {
        options |= XATTR_NOFOLLOW;
    }
    
    // Get optional buffer size argument.
    
    err = 0;
    bufSize = 0;                // indicates to use listxattr itself to get the buffer size
    if ( CommandArgsGetOptionalConstantString(args, "-bufSize") ) {
        err = CommandArgsGetSizeT(args, &bufSize);
        if (bufSize == 0) {
            err = EUSAGE;
        }
    }

    // Get item path.
    
    if (err == 0) {
        err = CommandArgsGetString(args, &itemPath);
    }
    
    // If no buffer size specified, ask listxattr for the correct size.
    
    if ( (err == 0) && (bufSize == 0) ) {
        listResult = listxattr(itemPath, NULL, 0, options);
        if (listResult < 0) {
            err = errno;
        }
        if (err == 0) {
            bufSize = listResult;
        }
    }
    
    // Allocate a buffer.
    
    if (err == 0) {
        buf = (char *) malloc(bufSize);
        if (buf == NULL) {
            err = ENOMEM;
        }
    }
    
    // Get and print the list of attributes.
    
    if (err == 0) {
        fprintf(
            stdout, 
            "%*slistxattr %s%s\n", 
            (int) indent, "", 
            (options & XATTR_NOFOLLOW) ? "XATTR_NOFOLLOW " : "", 
            itemPath
        );
        listResult = listxattr(itemPath, buf, bufSize, options);
        if (listResult < 0) {
            err = errno;
        }
    }
    if (err == 0) {
        char *      cursor;
        char *      limit;
        char *      stringStart;
        
        cursor = buf;
        limit = buf + listResult;
        
        do {
            if (cursor == limit) {
                break;
            }

            stringStart = cursor;
            
            while ( (cursor != limit) && (*cursor != 0) ) {
                cursor += 1;
            }
            if (cursor == limit) {
                fprintf(stderr, "Run off end of buffer.");
                err = EINVAL;
                break;
            }
            assert(*cursor == 0);
            cursor += 1;
            
            fprintf(stdout, "%*s%s\n", (int) (indent + kStdIndent), "", stringStart);
        } while (true);
    }
    
    // Clean up.
    
    free(buf);

    return CommandErrorMakeWithErrno(err);
}

static const CommandHelpEntry kListXAttrCommandHelp[] = {
    {CommandHelpString, "-bufSize Use a buffer size of N bytes; default is to make an  "},
    {CommandHelpString, "         initial call to get the right size"},
    {NULL, NULL}
};

const CommandInfo kListXAttrCommand = {
    PrintListXAttrInfo,
    "listxattr",
    "[ -XATTR_NOFOLLOW ] [ -bufSize N ] itemPath",
    "Lists extended attributes of item.",
    kListXAttrCommandHelp
};

#pragma mark *     getxattr

static CommandError PrintGetXAttrInfo(CommandArgsRef args, uint32_t indent, uint32_t verbose)
    // Implements the getxattr command.
{
    #pragma unused(verbose)
    int                 err;
    size_t              bufSize;
    const char *        itemPath;
    const char *        attrName;
    int                 options;
    char *              buf;
    ssize_t             getResult;
    struct stat         sb;
        
    assert( CommandArgsValid(args) );

    getResult = 0;              // quieten warning
    
    buf = NULL;
    
    // Get XATTR_NOFOLLOW option, if any.
    
    options = 0;
    if ( CommandArgsGetOptionalConstantString(args, "-XATTR_NOFOLLOW") ) {
        options |= XATTR_NOFOLLOW;
    }
    
    // Get optional buffer size argument.
    
    err = 0;
    bufSize = 0;                // indicates to use getxattr itself to get the buffer size
    if ( CommandArgsGetOptionalConstantString(args, "-bufSize") ) {
        err = CommandArgsGetSizeT(args, &bufSize);
        if (bufSize == 0) {
            err = EUSAGE;
        }
    }

    // Get item path.
    
    if (err == 0) {
        err = CommandArgsGetString(args, &itemPath);
    }
    
    // Get the attribute name.
    
    if (err == 0) {
        err = CommandArgsGetString(args, &attrName);
    }
    
    // If no buffer size specified, ask getxattr for the correct size.
    
    if ( (err == 0) && (bufSize == 0) ) {
        getResult = getxattr(itemPath, attrName, NULL, 0, 0, options);
        if (getResult < 0) {
            err = errno;
        }
        if (err == 0) {
            bufSize = getResult;
        }
    }
    
    // Allocate a buffer.
    
    if (err == 0) {
        buf = (char *) malloc(bufSize);
        if (buf == NULL) {
            err = ENOMEM;
        }
    }
    
    // Get and print the attribute.
    
    if (err == 0) {
        err = stat(itemPath, &sb);
        if (err < 0) {
            err = errno;
        }
    }
    if (err == 0) {
        fprintf(
            stdout, 
            "%*sgetxattr %s%s %s\n", 
            (int) indent, "", 
            (options & XATTR_NOFOLLOW) ? "XATTR_NOFOLLOW " : "", 
            itemPath,
            attrName
        );
        getResult = getxattr(itemPath, attrName, buf, bufSize, 0, options);
        if (getResult < 0) {
            err = errno;
        }
    }
    if (err == 0) {
        if ( ( strcmp(attrName, XATTR_FINDERINFO_NAME) == 0) && (getResult == 32) ) {
            if ( S_ISDIR(sb.st_mode) ) {
                FPFinderInfoBE("data", getResult, buf, indent + kStdIndent, strlen("data"), verbose, (void *) (uintptr_t) kFolderInfoCombined);
            } else {
                FPFinderInfoBE("data", getResult, buf, indent + kStdIndent, strlen("data"), verbose, (void *) (uintptr_t) kFileInfoCombined);
            }
        } else {
            // For other attributes, just print the hex.  This includes 
            // XATTR_RESOURCEFORK_NAME.
            FPHex("data", getResult, buf, indent + kStdIndent, strlen("data"), verbose, NULL);
        }
    }
    
    // Clean up.
    
    free(buf);

    return CommandErrorMakeWithErrno(err);
}

static const CommandHelpEntry kGetXAttrCommandHelp[] = {
    {CommandHelpString, "-bufSize Use a buffer size of N bytes; default is to make an  "},
    {CommandHelpString, "         initial call to get the right size"},
    {NULL, NULL}
};

const CommandInfo kGetXAttrCommand = {
    PrintGetXAttrInfo,
    "getxattr",
    "[ -XATTR_NOFOLLOW ] [ -bufSize N ] itemPath attrName",
    "Get extended attribute of item.",
    kGetXAttrCommandHelp
};

#pragma mark *     fts

static const FPFlagDesc kFTSOptions[] = {
    {FTS_COMFOLLOW, "FTS_COMFOLLOW"},
    {FTS_LOGICAL,   "FTS_LOGICAL"},
    {FTS_NOCHDIR,   "FTS_NOCHDIR"},
    {FTS_NOSTAT,    "FTS_NOSTAT"},
    {FTS_PHYSICAL,  "FTS_PHYSICAL"},
    {FTS_SEEDOT,    "FTS_SEEDOT"},
    {FTS_XDEV,      "FTS_XDEV"},
    {FTS_WHITEOUT,  "FTS_WHITEOUT"},
    {0, NULL}
};

static const FPEnumDesc kFTSInfoValues[] = {
    {FTS_D,         "FTS_D"},
    {FTS_DC,        "FTS_DC"},
    {FTS_DEFAULT,   "FTS_DEFAULT"},
    {FTS_DNR,       "FTS_DNR"},
    {FTS_DOT,       "FTS_DOT"},
    {FTS_DP,        "FTS_DP"},
    {FTS_ERR,       "FTS_ERR"},
    {FTS_F,         "FTS_F"},
    {FTS_INIT,      "FTS_INIT"},
    {FTS_NS,        "FTS_NS"},
    {FTS_NSOK,      "FTS_NSOK"},
    {FTS_SL,        "FTS_SL"},
    {FTS_SLNONE,    "FTS_SLNONE"},
    {FTS_W,         "FTS_W"},
    {0, NULL}
};

// Field definitions for FTSENT.

static const FPFieldDesc kFTSEntFieldDesc[] = { 
    {"fts_info",        offsetof(FTSENT, fts_info),             sizeof(u_short),        FPEnum, kFTSInfoValues},
    {"fts_accpath",     offsetof(FTSENT, fts_accpath),          sizeof(char *),         FPCStringPtr, NULL},
    {"fts_path",        offsetof(FTSENT, fts_path),             sizeof(char *),         FPCStringPtr, NULL},
    {"fts_pathlen",     offsetof(FTSENT, fts_pathlen),          sizeof(u_short),        FPUDec, NULL},
    {"fts_name",        offsetof(FTSENT, fts_name),             1,                      FPCString, NULL},
    {"fts_namelen",     offsetof(FTSENT, fts_namelen),          sizeof(u_short),        FPUDec, NULL},
    {"fts_level",       offsetof(FTSENT, fts_level),            sizeof(short),          FPSDec, NULL},
    {"fts_errno",       offsetof(FTSENT, fts_errno),            sizeof(int),            FPSDec, NULL},
    {"fts_cycle",       offsetof(FTSENT, fts_cycle),            sizeof(void *),         FPPtr, NULL},
    {"fts_statp",       offsetof(FTSENT, fts_statp),            sizeof(struct stat *),  FPPtr, NULL},
    {NULL, 0, 0, NULL, NULL}
};

static CommandError PrintFTSInfo(CommandArgsRef args, uint32_t indent, uint32_t verbose)
    // Implements the fts command.
{
    int             err;
    int             junk;
    int             options;
    const char *    itemPath;
    FTS *           fts;

    assert( CommandArgsValid(args) );

    fts = NULL;
    
    // Get options from arguments.
    
    if (CommandArgsIsOption(args)) {
        err = CommandArgsGetFlagListInt(args, kFTSOptions, &options);
    } else {
        options = FTS_PHYSICAL;
        err = 0;
    }
    
    // Get item path argument.
    
    if (err == 0) {
        err = CommandArgsGetString(args, &itemPath);
    }
    
    // Create an FTS.
    
    if (err == 0) {
        const char *    pathArray[2];
        
        pathArray[0] = itemPath;
        pathArray[1] = NULL;
        
        fts = fts_open( (char **) pathArray, options, NULL);
        if (fts == NULL) {
            err = errno;
        }
    }
    
    // Get each result and print it.
    
    if (err == 0) {
        bool    first;
        
        first = true;
        do {
            FTSENT *    ftsEnt;
            
            ftsEnt = fts_read(fts);
            if (ftsEnt == NULL) {
                err = errno;
                break;
            }
            if ( ! first ) {
                fprintf(stdout, "\n");
            }
            FPPrintFields(kFTSEntFieldDesc, ftsEnt, sizeof(*ftsEnt), indent, verbose);    
            first = false;
        } while (true);
    }
    
    // Clean up.
    
    if (fts != NULL) {
        junk = fts_close(fts);
        assert(junk == 0);
    }

    return CommandErrorMakeWithErrno(err);
}

static const CommandHelpEntry kFTSCommandHelp[] = {
    {CommandHelpString, "-options FTS options; default is FTS_PHYSICAL"},
    {CommandHelpFlags,  kFTSOptions},
    {NULL, NULL}
};

const CommandInfo kFTSCommand = {
    PrintFTSInfo,
    "fts",
    "[ -options ] itemPath",
    "Iterate directory hierarchy using fts.",
    kFTSCommandHelp
};

#pragma mark *     pathconf

const FPEnumDesc kPathConfEnums[] = {
    {_PC_LINK_MAX,              "_PC_LINK_MAX"},
    {_PC_MAX_CANON,             "_PC_MAX_CANON"},
    {_PC_MAX_INPUT,             "_PC_MAX_INPUT"},
    {_PC_NAME_MAX,              "_PC_NAME_MAX"},
    {_PC_PATH_MAX,              "_PC_PATH_MAX"},
    {_PC_PIPE_BUF,              "_PC_PIPE_BUF"},
    {_PC_CHOWN_RESTRICTED,      "_PC_CHOWN_RESTRICTED"},
    {_PC_NO_TRUNC,              "_PC_NO_TRUNC"},
    {_PC_VDISABLE,              "_PC_VDISABLE"},
    {_PC_NAME_CHARS_MAX,        "_PC_NAME_CHARS_MAX"},
    {_PC_CASE_SENSITIVE,        "_PC_CASE_SENSITIVE"},
    {_PC_CASE_PRESERVING,       "_PC_CASE_PRESERVING"},
    {_PC_EXTENDED_SECURITY_NP,  "_PC_EXTENDED_SECURITY_NP"},
    {_PC_AUTH_OPAQUE_NP,        "_PC_AUTH_OPAQUE_NP"},
    {_PC_2_SYMLINKS,            "_PC_2_SYMLINKS"},
    {_PC_ALLOC_SIZE_MIN,        "_PC_ALLOC_SIZE_MIN"},
    {_PC_ASYNC_IO,              "_PC_ASYNC_IO"},
    {_PC_FILESIZEBITS,          "_PC_FILESIZEBITS"},
    {_PC_PRIO_IO,               "_PC_PRIO_IO"},
    {_PC_REC_INCR_XFER_SIZE,    "_PC_REC_INCR_XFER_SIZE"},
    {_PC_REC_MAX_XFER_SIZE,     "_PC_REC_MAX_XFER_SIZE"},
    {_PC_REC_MIN_XFER_SIZE,     "_PC_REC_MIN_XFER_SIZE"},
    {_PC_REC_XFER_ALIGN,        "_PC_REC_XFER_ALIGN"},
    {_PC_SYMLINK_MAX,           "_PC_SYMLINK_MAX"},
    {_PC_SYNC_IO,               "_PC_SYNC_IO"},
    { 0, NULL }
};

static CommandError PrintPathConfInfo(CommandArgsRef args, uint32_t indent, uint32_t verbose)
    // Implements the pathconf command.
{
    int             err;
    const char *    selectorStr;
    size_t          enumIndex;
    int             selector;
    const char *    path;
    long            result;

    assert( CommandArgsValid(args) );

    // Get the selector.  Handle selectors that we know about and also allow the 
    // user to specify a number.  If they do specify a number, look up the number 
    // in our list of known selectors so that we can print the appropriate identifier.
    
    err = CommandArgsGetString(args, &selectorStr);
    if (err == 0) {
        enumIndex = FPFindEnumByName(kPathConfEnums, selectorStr);
        if (enumIndex != kFPNotFound) {
            selector = (int) kPathConfEnums[enumIndex].enumValue;
        } else {
            selector = atoi(selectorStr);
            if (selector <= 0) {
                err = EUSAGE;
            } else {
                enumIndex = FPFindEnumByValue(kPathConfEnums, selector);
                if (enumIndex != kFPNotFound) {
                    selectorStr = kPathConfEnums[enumIndex].enumName;
                }
            }
        }
    }
    
    // Get the path argument.
    
    if (err == 0) {
        err = CommandArgsGetString(args, &path);
    }
    
    // Call pathconf and print the results.
    
    if (err == 0) {
        fprintf(stdout, "pathconf(%s, '%s')\n", selectorStr, path);
        result = pathconf(path, selector);
        if (result < 0) {
            err = errno;
        } else {
            FPSDec("result", sizeof(result), &result, indent, strlen("result"), verbose, NULL);
        }
    }

    return CommandErrorMakeWithErrno(err);
}

static const CommandHelpEntry kPathConfCommandHelp[] = {
    {CommandHelpString, "selector   Decimanl number, or one of the following:"},
    {CommandHelpEnum, kPathConfEnums},
    {NULL, NULL}
};

const CommandInfo kPathConfCommand = {
    PrintPathConfInfo,
    "pathconf",
    "selector itemPath",
    "Queries file system parameters using pathconf.",
    kPathConfCommandHelp
};
