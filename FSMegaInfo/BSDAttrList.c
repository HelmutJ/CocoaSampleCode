/*
    File:       BSDAttrList.c

    Contains:   BSD attribute list command processing (getattrlist and so on).

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

#include "FieldPrinter.h"
#include "Command.h"

/////////////////////////////////////////////////////////////////
#pragma mark *     getattrlist

// Some useful getattrlist-related declarations.

typedef struct attrlist attrlist_t;

enum {
    kAttrRefSize = sizeof(attrreference_t)
};

// FPFlagDesc versions of kCommonAttrDesc and kVolumeAttrDesc. 
// See InitAllAttrFlags for a discussion of why these are 
// necessary.

static FPFlagDesc * gCommonAttrFlags;
static FPFlagDesc * gVolumeAttrFlags;
static FPFlagDesc * gDirAttrFlags;
static FPFlagDesc * gFileAttrFlags;
static FPFlagDesc * gForkAttrFlags;

// AttrDesc describes an attribute, including info like its mask value, its identifier, 
// its size, and a pointer to the routine to print it.

struct AttrDesc {
    attrgroup_t     attrMask;
    const char *    attrName;
    size_t          attrSize;
    FPPrinter       attrPrinter;
    const void *    attrInfo;
};
typedef struct AttrDesc AttrDesc;

static void StringAttrPrinter(
    const char *    fieldName, 
    size_t          fieldSize, 
    const void *    fieldPtr, 
    uint32_t        indent, 
    size_t          nameWidth, 
    uint32_t        verbose, 
    const void *    info
)
    // Prints a string attribute, as referenced by an attrreference_t structure 
    // in the buffer returned by getattrlist.  The encoding is assumed to be UTF-8.
    //
    // See definition of FPPrinter for a parameter description.
{
    attrreference_t *   attrRef;
    
    #pragma unused(fieldSize)
    #pragma unused(verbose)
    #pragma unused(info)
    assert( FPStandardPreCondition() );
    assert(fieldSize == sizeof(attrreference_t));
    attrRef = ( (attrreference_t *) fieldPtr );
    
    fprintf(stdout, "%*s%-*s = '%.*s'\n", (int) indent, "", (int) nameWidth, fieldName, (int) attrRef->attr_length, ((char *) attrRef) + attrRef->attr_dataoffset);
}

static void FPFSObjID(
    const char *    fieldName, 
    size_t          fieldSize, 
    const void *    fieldPtr, 
    uint32_t        indent, 
    size_t          nameWidth, 
    uint32_t        verbose, 
    const void *    info
)
    // Prints an fsobj_id_t field.
    //
    // See definition of FPPrinter for a parameter description.
{
    const fsobj_id_t *  fsobjPtr;
    
    #pragma unused(fieldSize)
    #pragma unused(verbose)
    #pragma unused(info)
    assert( FPStandardPreCondition() );
    assert(fieldSize == sizeof(fsobj_id_t));
    fsobjPtr = (const fsobj_id_t *) fieldPtr;

    fprintf(stdout, "%*s%-*s = (objno = 0x%08" PRIx32 ", generation = 0x%08" PRIx32 ")\n", (int) indent, "", (int) nameWidth, fieldName, fsobjPtr->fid_objno, fsobjPtr->fid_generation);
}

static void FPFSID(
    const char *    fieldName, 
    size_t          fieldSize, 
    const void *    fieldPtr, 
    uint32_t        indent, 
    size_t          nameWidth, 
    uint32_t        verbose, 
    const void *    info
)
    // Prints an fsid_t field.
    //
    // See definition of FPPrinter for a parameter description.
{
    const fsid_t *  fsidPtr;
    
    #pragma unused(fieldSize)
    #pragma unused(verbose)
    #pragma unused(info)
    assert( FPStandardPreCondition() );
    assert(fieldSize == sizeof(fsid_t));
    fsidPtr = (const fsid_t *) fieldPtr;

    fprintf(stdout, "%*s%-*s = [0x%08" PRIx32 ", 0x%08" PRIx32 "]\n", (int) indent, "", (int) nameWidth, fieldName, fsidPtr->val[0], fsidPtr->val[1]);
}

// Flags describing volume format capabilities.

static const char kVolCapFlagSpacer[] = "VOL_CAP_FMT_PERSISTENTOBJECTIDS";

static const FPFlagDesc kVolCapFormatFlags[] = {
    { VOL_CAP_FMT_PERSISTENTOBJECTIDS,  "VOL_CAP_FMT_PERSISTENTOBJECTIDS" },
    { VOL_CAP_FMT_SYMBOLICLINKS,        "VOL_CAP_FMT_SYMBOLICLINKS" },
    { VOL_CAP_FMT_HARDLINKS,            "VOL_CAP_FMT_HARDLINKS" },
    { VOL_CAP_FMT_JOURNAL,              "VOL_CAP_FMT_JOURNAL" },
    { VOL_CAP_FMT_JOURNAL_ACTIVE,       "VOL_CAP_FMT_JOURNAL_ACTIVE" },
    { VOL_CAP_FMT_NO_ROOT_TIMES,        "VOL_CAP_FMT_NO_ROOT_TIMES" },
    { VOL_CAP_FMT_SPARSE_FILES,         "VOL_CAP_FMT_SPARSE_FILES" },
    { VOL_CAP_FMT_ZERO_RUNS,            "VOL_CAP_FMT_ZERO_RUNS" },
    { VOL_CAP_FMT_CASE_SENSITIVE,       "VOL_CAP_FMT_CASE_SENSITIVE" },
    { VOL_CAP_FMT_CASE_PRESERVING,      "VOL_CAP_FMT_CASE_PRESERVING" },
    { VOL_CAP_FMT_FAST_STATFS,          "VOL_CAP_FMT_FAST_STATFS" },
    { VOL_CAP_FMT_2TB_FILESIZE,         "VOL_CAP_FMT_2TB_FILESIZE" },
    { VOL_CAP_FMT_OPENDENYMODES,        "VOL_CAP_FMT_OPENDENYMODES" },
    { VOL_CAP_FMT_HIDDEN_FILES,         "VOL_CAP_FMT_HIDDEN_FILES" },
    { VOL_CAP_FMT_PATH_FROM_ID,         "VOL_CAP_FMT_PATH_FROM_ID" },
    { 0, NULL }
};

// Flags describing volume API capabilities.

static const FPFlagDesc kVolCapInterfacesFlags[] = {
    { VOL_CAP_INT_SEARCHFS,             "VOL_CAP_INT_SEARCHFS" },
    { VOL_CAP_INT_ATTRLIST,             "VOL_CAP_INT_ATTRLIST" },
    { VOL_CAP_INT_NFSEXPORT,            "VOL_CAP_INT_NFSEXPORT" },
    { VOL_CAP_INT_READDIRATTR,          "VOL_CAP_INT_READDIRATTR" },
    { VOL_CAP_INT_EXCHANGEDATA,         "VOL_CAP_INT_EXCHANGEDATA" },
    { VOL_CAP_INT_COPYFILE,             "VOL_CAP_INT_COPYFILE" },
    { VOL_CAP_INT_ALLOCATE,             "VOL_CAP_INT_ALLOCATE" },
    { VOL_CAP_INT_VOL_RENAME,           "VOL_CAP_INT_VOL_RENAME" },
    { VOL_CAP_INT_ADVLOCK,              "VOL_CAP_INT_ADVLOCK" },
    { VOL_CAP_INT_FLOCK,                "VOL_CAP_INT_FLOCK" },
    { VOL_CAP_INT_EXTENDED_SECURITY,    "VOL_CAP_INT_EXTENDED_SECURITY" },
    { VOL_CAP_INT_USERACCESS,           "VOL_CAP_INT_USERACCESS" },
    { VOL_CAP_INT_MANLOCK,              "VOL_CAP_INT_MANLOCK" },
    { VOL_CAP_INT_NAMEDSTREAMS,         "VOL_CAP_INT_NAMEDSTREAMS" },
    { VOL_CAP_INT_EXTENDED_ATTR,        "VOL_CAP_INT_EXTENDED_ATTR" },
    { 0, NULL }
};

static void PrintVolCap(const u_int32_t *capList, uint32_t indent, uint32_t verbose)
    // Prints a vol_capabilities_set_t array which is made up of 5 u_int32_t 
    // elements).  Only two of the elements are currently used 
    // (with indexes VOL_CAPABILITIES_FORMAT and VOL_CAPABILITIES_INTERFACES) 
    // and, for those, we print all the flags.  The remainder are just printed 
    // in hex.
{
    assert(capList != NULL);
    
    fprintf(stdout, "%*sVOL_CAPABILITIES_FORMAT     = 0x%08" PRIx32 "\n", (int) indent, "", capList[VOL_CAPABILITIES_FORMAT]);
    if (verbose > 0) {
        FPPrintFlags(capList[VOL_CAPABILITIES_FORMAT], kVolCapFormatFlags, strlen(kVolCapFlagSpacer), indent + kStdIndent);
    }
    fprintf(stdout, "%*sVOL_CAPABILITIES_INTERFACES = 0x%08" PRIx32 "\n", (int) indent, "", capList[VOL_CAPABILITIES_INTERFACES]);
    if (verbose > 0) {
        FPPrintFlags(capList[VOL_CAPABILITIES_INTERFACES], kVolCapInterfacesFlags, strlen(kVolCapFlagSpacer), indent + kStdIndent);
    }
    fprintf(stdout, "%*sVOL_CAPABILITIES_RESERVED1  = 0x%08" PRIx32 "\n", (int) indent, "", capList[VOL_CAPABILITIES_RESERVED1]);
    fprintf(stdout, "%*sVOL_CAPABILITIES_RESERVED1  = 0x%08" PRIx32 "\n", (int) indent, "", capList[VOL_CAPABILITIES_RESERVED2]);
}

static void FPVolCap(
    const char *    fieldName, 
    size_t          fieldSize, 
    const void *    fieldPtr, 
    uint32_t        indent, 
    size_t          nameWidth, 
    uint32_t        verbose, 
    const void *    info
)
    // Prints a vol_capabilities_attr_t field.
    //
    // See definition of FPPrinter for a parameter description.
{
    const vol_capabilities_attr_t * volCap;
    
    #pragma unused(fieldSize)
    #pragma unused(nameWidth)
    #pragma unused(info)
    assert( FPStandardPreCondition() );
    assert(fieldSize == sizeof(vol_capabilities_attr_t));

    volCap = (const vol_capabilities_attr_t *) fieldPtr;

    fprintf(stdout, "%*s%s\n", (int) indent, "", fieldName);
    
    fprintf(stdout, "%*scapabilities\n", (int) (indent + kStdIndent), "");
    PrintVolCap(volCap->capabilities, (int) (indent + 2 * kStdIndent), verbose);
    
    if (verbose > 1) {
        fprintf(stdout, "%*svalid\n", (int) (indent + kStdIndent), "");
        PrintVolCap(volCap->valid, (int) (indent + 2 * kStdIndent), verbose);
    }
}

static void PrintAttrSet(const attribute_set_t *attrSet, uint32_t indent, uint32_t verbose)
    // Prints an attribute_set_t structure.  If emulated is true, 
    // this just prints the first two elements because those are the 
    // only ones that we calculated as part of the emulation.
    //
    // indent and verbose are as per the comments for FPPrinter.
{
    static const char kVolAttrFlagSpacer[] = "ATTR_VOL_ALLOCATIONCLUMP";

    assert(attrSet != NULL);
    
    // Using strlen(kVolAttrFlagSpacer) for the nameWidth ensures that all of 
    // the flags are printed with a consistent name width.
    
    fprintf(stdout, "%*scommonattr = 0x%08" PRIx32 "\n", (int) indent, "", attrSet->commonattr);
    if (verbose > 0) {
        FPPrintFlags(attrSet->commonattr, gCommonAttrFlags, strlen(kVolAttrFlagSpacer), indent + kStdIndent);
    }
    fprintf(stdout, "%*svolattr    = 0x%08" PRIx32 "\n", (int) indent, "", attrSet->volattr);
    if (verbose > 0) {
        FPPrintFlags(attrSet->volattr, gVolumeAttrFlags, strlen(kVolAttrFlagSpacer), indent + kStdIndent);
    }
    fprintf(stdout, "%*sdirattr    = 0x%08" PRIx32 "\n", (int) indent, "", attrSet->dirattr);
    if (verbose > 0) {
        FPPrintFlags(attrSet->dirattr, gDirAttrFlags, strlen(kVolAttrFlagSpacer), indent + kStdIndent);
    }
    fprintf(stdout, "%*sfileattr   = 0x%08" PRIx32 "\n", (int) indent, "", attrSet->fileattr);
    if (verbose > 0) {
        FPPrintFlags(attrSet->fileattr, gFileAttrFlags, strlen(kVolAttrFlagSpacer), indent + kStdIndent);
    }
    fprintf(stdout, "%*sforkattr   = 0x%08" PRIx32 "\n", (int) indent, "", attrSet->forkattr);
    if (verbose > 0) {
        FPPrintFlags(attrSet->forkattr, gForkAttrFlags, strlen(kVolAttrFlagSpacer), indent + kStdIndent);
    }
}

static void FPVolAttr(
    const char *    fieldName, 
    size_t          fieldSize, 
    const void *    fieldPtr, 
    uint32_t        indent, 
    size_t          nameWidth, 
    uint32_t        verbose, 
    const void *    info
)
    // Prints a vol_attributes_attr_t field.
    //
    // See definition of FPPrinter for a parameter description.
{
    const vol_attributes_attr_t * volAttr;
    
    #pragma unused(fieldSize)
    #pragma unused(nameWidth)
    #pragma unused(info)
    assert( FPStandardPreCondition() );
    assert(fieldSize == sizeof(vol_attributes_attr_t));

    volAttr = (const vol_attributes_attr_t *) fieldPtr;

    fprintf(stdout, "%*s%s\n", (int) indent, "", fieldName);
    
    fprintf(stdout, "%*svalidattr\n", (int) (indent + kStdIndent), "");
    PrintAttrSet(&volAttr->validattr,  indent + 2 * kStdIndent, ((verbose > 0) ? verbose - 1 : 0) );
    fprintf(stdout, "%*snativeattr\n", (int) (indent + kStdIndent), "");
    PrintAttrSet(&volAttr->nativeattr, indent + 2 * kStdIndent, ((verbose > 0) ? verbose - 1 : 0) );
}

static const FPFlagDesc kACLFlags[] = {
    { KAUTH_ACL_DEFER_INHERIT,  "KAUTH_ACL_DEFER_INHERIT" },
    { KAUTH_ACL_NO_INHERIT,     "KAUTH_ACL_NO_INHERIT" },
    { 0, NULL }
};

static const FPEnumDesc kACEKinds[] = {
    { KAUTH_ACE_PERMIT,             "KAUTH_ACE_PERMIT" },
    { KAUTH_ACE_DENY,               "KAUTH_ACE_DENY" },
    { KAUTH_ACE_AUDIT,              "KAUTH_ACE_AUDIT" },
    { KAUTH_ACE_ALARM,              "KAUTH_ACE_ALARM" },
    { 0,                            NULL }
};

static const char kACEFlagsRightsSpacer[] = "KAUTH_VNODE_WRITE_EXTATTRIBUTES";

static const FPFlagDesc kACEFlags[] = {
    { KAUTH_ACE_INHERITED,          "KAUTH_ACE_INHERITED" },
    { KAUTH_ACE_FILE_INHERIT,       "KAUTH_ACE_FILE_INHERIT" },
    { KAUTH_ACE_DIRECTORY_INHERIT,  "KAUTH_ACE_DIRECTORY_INHERIT" },
    { KAUTH_ACE_LIMIT_INHERIT,      "KAUTH_ACE_LIMIT_INHERIT" },
    { KAUTH_ACE_ONLY_INHERIT,       "KAUTH_ACE_ONLY_INHERIT" },
    { KAUTH_ACE_SUCCESS,            "KAUTH_ACE_SUCCESS" },
    { KAUTH_ACE_FAILURE,            "KAUTH_ACE_FAILURE" },
    { 0,                            NULL }
};

static const FPFlagDesc kACERights[] = {
    { KAUTH_VNODE_LIST_DIRECTORY,       "KAUTH_VNODE_LIST_DIRECTORY" },
    { KAUTH_VNODE_ADD_FILE,             "KAUTH_VNODE_ADD_FILE" },
    { KAUTH_VNODE_SEARCH,               "KAUTH_VNODE_SEARCH" },
    { KAUTH_VNODE_DELETE,               "KAUTH_VNODE_DELETE" },
    { KAUTH_VNODE_ADD_SUBDIRECTORY,     "KAUTH_VNODE_ADD_SUBDIRECTORY" },
    { KAUTH_VNODE_DELETE_CHILD,         "KAUTH_VNODE_DELETE_CHILD" },
    { KAUTH_VNODE_READ_ATTRIBUTES,      "KAUTH_VNODE_READ_ATTRIBUTES" },
    { KAUTH_VNODE_WRITE_ATTRIBUTES,     "KAUTH_VNODE_WRITE_ATTRIBUTES" },
    { KAUTH_VNODE_READ_EXTATTRIBUTES,   "KAUTH_VNODE_READ_EXTATTRIBUTES" },
    { KAUTH_VNODE_WRITE_EXTATTRIBUTES,  "KAUTH_VNODE_WRITE_EXTATTRIBUTES" },
    { KAUTH_VNODE_READ_SECURITY,        "KAUTH_VNODE_READ_SECURITY" },
    { KAUTH_VNODE_WRITE_SECURITY,       "KAUTH_VNODE_WRITE_SECURITY" },
    { KAUTH_VNODE_TAKE_OWNERSHIP,       "KAUTH_VNODE_TAKE_OWNERSHIP" },
    { KAUTH_VNODE_SYNCHRONIZE,          "KAUTH_VNODE_SYNCHRONIZE" },
 
    { KAUTH_ACE_GENERIC_ALL,            "KAUTH_ACE_GENERIC_ALL" },
    { KAUTH_ACE_GENERIC_EXECUTE,        "KAUTH_ACE_GENERIC_EXECUTE" },
    { KAUTH_ACE_GENERIC_WRITE,          "KAUTH_ACE_GENERIC_WRITE" },
    { KAUTH_ACE_GENERIC_READ,           "KAUTH_ACE_GENERIC_READ" },
    { 0, NULL }
};

extern void FPKauthFileSec(
    const char *    fieldName, 
    size_t          fieldSize, 
    const void *    fieldPtr, 
    uint32_t        indent, 
    size_t          nameWidth, 
    uint32_t        verbose, 
    const void *    info
)
    // Prints a kauth_filesec_t field.  This routine is exported for the benefit 
    // of the File Manager module.
    //
    // See definition of FPPrinter for a parameter description.
{
    #pragma unused(fieldSize)
    #pragma unused(info)
    kauth_filesec_t     fileSec;
    u_int32_t           aceIndex;
    u_int32_t           aceKind;
    static const char kFSecFieldNameSpacer[] = "fsec_magic";
    static const char kACLFieldNameSpacer[]  = "acl_entrycount";
    static const char kACEFieldNameSpacer[]  = "ace_applicable";

    #pragma unused(fieldSize)
    #pragma unused(info)
    assert( FPStandardPreCondition() );
    assert(fieldSize >= offsetof(struct kauth_filesec, fsec_acl));
    assert(fieldSize <= KAUTH_FILESEC_SIZE(KAUTH_ACL_MAX_ENTRIES));

    // Grab the attribute data and cast it to a kauth_filesec_t.
    
    fileSec = (kauth_filesec_t) fieldPtr;
    assert(fileSec->fsec_magic == KAUTH_FILESEC_MAGIC);

    fprintf(stdout, "%*s%s:\n", (int) indent, "", fieldName);

    // Originally I printed the ACL contents by calling acl_to_text, but I didn't like 
    // the output format so now I do it manually.

    FPHex( "fsec_magic", sizeof(fileSec->fsec_magic), &fileSec->fsec_magic, indent + kStdIndent, strlen(kFSecFieldNameSpacer), verbose, NULL);
    FPGUID("fsec_owner", sizeof(fileSec->fsec_owner), &fileSec->fsec_owner, indent + kStdIndent, strlen(kFSecFieldNameSpacer), verbose, NULL);
    FPGUID("fsec_group", sizeof(fileSec->fsec_group), &fileSec->fsec_group, indent + kStdIndent, strlen(kFSecFieldNameSpacer), verbose, NULL);
    fprintf(stdout, "%*s%-*s\n", (int) (indent + kStdIndent), "", (int) nameWidth, "fsec_acl:");
    FPUDec("acl_entrycount", sizeof(fileSec->fsec_acl.acl_entrycount), &fileSec->fsec_acl.acl_entrycount, indent + 2 * kStdIndent, strlen(kACLFieldNameSpacer), verbose, NULL);
    FPHex( "acl_flags",      sizeof(fileSec->fsec_acl.acl_flags),      &fileSec->fsec_acl.acl_flags,      indent + 2 * kStdIndent, strlen(kACLFieldNameSpacer), verbose, NULL);
    if (verbose > 0) {
        FPPrintFlags(fileSec->fsec_acl.acl_flags, kACLFlags, 0, indent + 3 * kStdIndent);
    }

    if (fileSec->fsec_acl.acl_entrycount != KAUTH_FILESEC_NOACL) {
        // The attribute must be big enough to contain the number of ACL entries.
        assert(fieldSize >= KAUTH_FILESEC_SIZE(fileSec->fsec_acl.acl_entrycount));

        for (aceIndex = 0; aceIndex < fileSec->fsec_acl.acl_entrycount; aceIndex++) {
            kauth_ace_t thisACE;
            thisACE = &fileSec->fsec_acl.acl_ace[aceIndex];

            fprintf(stdout, "%*sacl_ace[%" PRIu32 "]\n", (int) (indent + 2 * kStdIndent), "", aceIndex);
            
            FPGUID("ace_applicable", sizeof(thisACE->ace_applicable), &thisACE->ace_applicable, indent + 3 * kStdIndent, strlen(kACEFieldNameSpacer), verbose, NULL);            
            FPHex( "ace_flags",      sizeof(thisACE->ace_flags),      &thisACE->ace_flags,      indent + 3 * kStdIndent, strlen(kACEFieldNameSpacer), verbose, NULL);            
            if (verbose > 0) {
                aceKind = thisACE->ace_flags & KAUTH_ACE_KINDMASK;
                FPEnum("kind", sizeof(aceKind), &aceKind, indent + 4 * kStdIndent, strlen(kACEFlagsRightsSpacer), verbose, &kACEKinds);
                FPPrintFlags(thisACE->ace_flags & ~KAUTH_ACE_KINDMASK, kACEFlags, strlen(kACEFlagsRightsSpacer), indent + 4 * kStdIndent);
            }
            FPHex( "ace_rights",     sizeof(thisACE->ace_rights),     &thisACE->ace_rights,     indent + 3 * kStdIndent, strlen(kACEFieldNameSpacer), verbose, NULL);            
            if (verbose > 0) {
                FPPrintFlags(thisACE->ace_rights, kACERights, 0, indent + 4 * kStdIndent);
            }
        }
    }
}

static void ACLAttrPrinter(
    const char *    fieldName, 
    size_t          fieldSize, 
    const void *    fieldPtr, 
    uint32_t        indent, 
    size_t          nameWidth, 
    uint32_t        verbose, 
    const void *    info
)
    // Prints an ACL attribute, as referenced by an attrreference_t structure 
    // in the buffer returned by getattrlist.
    //
    // See definition of FPPrinter for a parameter description.
{
    attrreference_t *   attrRef;
    
    #pragma unused(fieldSize)
    #pragma unused(verbose)
    #pragma unused(info)
    assert( FPStandardPreCondition() );
    assert(fieldSize == sizeof(attrreference_t));
    attrRef = ( (attrreference_t *) fieldPtr );

    if (attrRef->attr_length != 0) {
        FPKauthFileSec(fieldName, attrRef->attr_length, ((char *) attrRef) + attrRef->attr_dataoffset, (int) indent, (int) nameWidth, verbose, NULL);
    }
}

// An array of AttrDesc is used to hold information about a set of attributes 
// as returned by getattrlist.  The array is terminated by an entry with a NULL 
// name.

static void PrintAttributes(
    const AttrDesc      attrs[], 
    attrgroup_t         attrMask,
    const char **       cursorPtr,
    uint32_t            indent,
    size_t              nameWidth,
    uint32_t            verbose,
    FinderInfoFlavour   finderFlavour
)
    // Prints an attribute buffer as returned by getattrlist.  
    // attrs is a pointer to an array of AttrDesc that describe 
    // all of the supported attributes.  attrMask is a bitmap 
    // describing which of those attributes are present in the buffer. 
    // cursorPtr is a pointer a cursor pointer, which in turn points 
    // to a buffer containing the attribute data.  *cursorPtr points 
    // to the current place in the buffer.  When the routine is done 
    // it updates *cursorPtr to point to just after the last attribute 
    // that it has printed.  indent, nameWidth and verbose are as 
    // per the comments for FPPrinter.  finderFlavour controls how 
    // Finder info should be printed; it's necessary because Finder 
    // info is object type dependent.
{
    size_t          attrIndex;
    const char *    cursor;
    
    assert(attrs != NULL);
    assert( cursorPtr != NULL);
    assert(*cursorPtr != NULL);

    cursor = *cursorPtr;
    
    attrIndex = 0;
    while (attrs[attrIndex].attrName != NULL) {
        if (attrMask & attrs[attrIndex].attrMask) {
            FPPrinter   printer;
            
            printer = attrs[attrIndex].attrPrinter;
            if (printer == FPFinderInfoBE) {
                printer(attrs[attrIndex].attrName, attrs[attrIndex].attrSize, cursor, indent, nameWidth, verbose, (const void *) (uintptr_t) finderFlavour);
            } else {
                printer(attrs[attrIndex].attrName, attrs[attrIndex].attrSize, cursor, indent, nameWidth, verbose, attrs[attrIndex].attrInfo);
            }
            cursor += attrs[attrIndex].attrSize;
        }
        attrIndex += 1;
    }
    
    *cursorPtr = cursor;
}

// The known constants for fsobj_type_t attributes.

static const FPEnumDesc kFSObjTypeEnums[] = {
    { VNON,  "VNON"  },
    { VREG,  "VREG"  },
    { VDIR,  "VDIR"  },
    { VBLK,  "VBLK"  },
    { VCHR,  "VCHR"  },
    { VLNK,  "VLNK"  },
    { VSOCK, "VSOCK" },
    { VFIFO, "VFIFO" },
    { VBAD,  "VBAD"  },
    { VSTR,  "VSTR"  },
    { VCPLX, "VCPLX" },
    { 0, NULL }
};

// The known constants for fsobj_tag_t attributes.

static const FPEnumDesc kFSObjTagEnums[] = {
    { VT_NON,       "VT_NON"     },
    { VT_UFS,       "VT_UFS"     },
    { VT_NFS,       "VT_NFS"     },
    { VT_MFS,       "VT_MFS"     },
    { VT_MSDOSFS,   "VT_MSDOSFS" },
    { VT_LFS,       "VT_LFS"     },
    { VT_LOFS,      "VT_LOFS"    },
    { VT_FDESC,     "VT_FDESC"   },
    { VT_PORTAL,    "VT_PORTAL"  },
    { VT_NULL,      "VT_NULL"    },
    { VT_UMAP,      "VT_UMAP"    },
    { VT_KERNFS,    "VT_KERNFS"  },
    { VT_PROCFS,    "VT_PROCFS"  },
    { VT_AFS,       "VT_AFS"     },
    { VT_ISOFS,     "VT_ISOFS"   },
    { VT_UNION,     "VT_UNION"   },
    { VT_HFS,       "VT_HFS"     },
    { VT_ZFS,       "VT_ZFS"     },     // was VT_VOLFS prior to 10.5
    { VT_DEVFS,     "VT_DEVFS"   },
    { VT_WEBDAV,    "VT_WEBDAV"  },
    { VT_UDF,       "VT_UDF"     },
    { VT_AFP,       "VT_AFP"     },
    { VT_CDDA,      "VT_CDDA"    },
    { VT_CIFS,      "VT_CIFS"    },
    { VT_OTHER,     "VT_OTHER"   },
    { 0, NULL }
};

// Some well known values for the text_encoding_t type 
// (equivalent to the Carbon TextEncoding type).  Note that this 
// doesn't cover all possible values, just those that you're 
// likely to encounter in a file system.

const FPEnumDesc kTextEncodingEnums[] = {
    { kTextEncodingMacRoman,            "kTextEncodingMacRoman"             },
    { kTextEncodingMacJapanese,         "kTextEncodingMacJapanese"          },
    { kTextEncodingMacChineseTrad,      "kTextEncodingMacChineseTrad"       },
    { kTextEncodingMacKorean,           "kTextEncodingMacKorean"            },
    { kTextEncodingMacArabic,           "kTextEncodingMacArabic"            },
    { kTextEncodingMacHebrew,           "kTextEncodingMacHebrew"            },
    { kTextEncodingMacGreek,            "kTextEncodingMacGreek"             },
    { kTextEncodingMacCyrillic,         "kTextEncodingMacCyrillic"          },
    { kTextEncodingMacDevanagari,       "kTextEncodingMacDevanagari"        },
    { kTextEncodingMacGurmukhi,         "kTextEncodingMacGurmukhi"          },
    { kTextEncodingMacGujarati,         "kTextEncodingMacGujarati"          },
    { kTextEncodingMacOriya,            "kTextEncodingMacOriya"             },
    { kTextEncodingMacBengali,          "kTextEncodingMacBengali"           },
    { kTextEncodingMacTamil,            "kTextEncodingMacTamil"             },
    { kTextEncodingMacTelugu,           "kTextEncodingMacTelugu"            },
    { kTextEncodingMacKannada,          "kTextEncodingMacKannada"           },
    { kTextEncodingMacMalayalam,        "kTextEncodingMacMalayalam"         },
    { kTextEncodingMacSinhalese,        "kTextEncodingMacSinhalese"         },
    { kTextEncodingMacBurmese,          "kTextEncodingMacBurmese"           },
    { kTextEncodingMacKhmer,            "kTextEncodingMacKhmer"             },
    { kTextEncodingMacThai,             "kTextEncodingMacThai"              },
    { kTextEncodingMacLaotian,          "kTextEncodingMacLaotian"           },
    { kTextEncodingMacGeorgian,         "kTextEncodingMacGeorgian"          },
    { kTextEncodingMacArmenian,         "kTextEncodingMacArmenian"          },
    { kTextEncodingMacChineseSimp,      "kTextEncodingMacChineseSimp"       },
    { kTextEncodingMacTibetan,          "kTextEncodingMacTibetan"           },
    { kTextEncodingMacMongolian,        "kTextEncodingMacMongolian"         },
    { kTextEncodingMacEthiopic,         "kTextEncodingMacEthiopic"          },
    { kTextEncodingMacCentralEurRoman,  "kTextEncodingMacCentralEurRoman"   },
    { kTextEncodingMacVietnamese,       "kTextEncodingMacVietnamese"        },
    { kTextEncodingMacExtArabic,        "kTextEncodingMacExtArabic"         },
    { kTextEncodingMacSymbol,           "kTextEncodingMacSymbol"            },
    { kTextEncodingMacDingbats,         "kTextEncodingMacDingbats"          },
    { kTextEncodingMacTurkish,          "kTextEncodingMacTurkish"           },
    { kTextEncodingMacCroatian,         "kTextEncodingMacCroatian"          },
    { kTextEncodingMacIcelandic,        "kTextEncodingMacIcelandic"         },
    { kTextEncodingMacRomanian,         "kTextEncodingMacRomanian"          },
    { kTextEncodingMacCeltic,           "kTextEncodingMacCeltic"            },
    { kTextEncodingMacGaelic,           "kTextEncodingMacGaelic"            },
    { kTextEncodingMacKeyboardGlyphs,   "kTextEncodingMacKeyboardGlyphs"    },
    { kTextEncodingMacRSymbol,          "kTextEncodingMacRSymbol"           },
    { kTextEncodingMacUninterp,         "kTextEncodingMacUninterp"          },
    { kTextEncodingMacUnicode,          "kTextEncodingMacUnicode"           },
    { kTextEncodingMacFarsi,            "kTextEncodingMacFarsi"             },
    { kTextEncodingMacUkrainian,        "kTextEncodingMacUkrainian"         },
    { kTextEncodingMacInuit,            "kTextEncodingMacInuit"             },
    { kTextEncodingMacVT100,            "kTextEncodingMacVT100"             },
    { 0, NULL },
};

// Flags for the ATTR_CMN_USERACCESS attribute.

static const FPFlagDesc kUserAccessFlags[] = {
    { R_OK, "R_OK" },
    { W_OK, "W_OK" },
    { X_OK, "X_OK" },
    { 0, NULL }
};

// Flags for the ATTR_VOL_ENCODINGSUSED attribute. 
// Note the weird values for the last two entries.

static const FPFlagDesc kEncodingsUsedFlags[] = {
    { 1LL << kTextEncodingMacRoman,           "kTextEncodingMacRoman"           },          
    { 1LL << kTextEncodingMacRoman,           "kTextEncodingMacRoman"           },          
    { 1LL << kTextEncodingMacJapanese,        "kTextEncodingMacJapanese"        },       
    { 1LL << kTextEncodingMacChineseTrad,     "kTextEncodingMacChineseTrad"     },    
    { 1LL << kTextEncodingMacKorean,          "kTextEncodingMacKorean"          },         
    { 1LL << kTextEncodingMacArabic,          "kTextEncodingMacArabic"          },         
    { 1LL << kTextEncodingMacHebrew,          "kTextEncodingMacHebrew"          },         
    { 1LL << kTextEncodingMacGreek,           "kTextEncodingMacGreek"           },          
    { 1LL << kTextEncodingMacCyrillic,        "kTextEncodingMacCyrillic"        },       
    { 1LL << kTextEncodingMacRSymbol,         "kTextEncodingMacRSymbol"         },        
    { 1LL << kTextEncodingMacDevanagari,      "kTextEncodingMacDevanagari"      },     
    { 1LL << kTextEncodingMacGurmukhi,        "kTextEncodingMacGurmukhi"        },       
    { 1LL << kTextEncodingMacGujarati,        "kTextEncodingMacGujarati"        },       
    { 1LL << kTextEncodingMacOriya,           "kTextEncodingMacOriya"           },          
    { 1LL << kTextEncodingMacBengali,         "kTextEncodingMacBengali"         },        
    { 1LL << kTextEncodingMacTamil,           "kTextEncodingMacTamil"           },          
    { 1LL << kTextEncodingMacTelugu,          "kTextEncodingMacTelugu"          },         
    { 1LL << kTextEncodingMacKannada,         "kTextEncodingMacKannada"         },        
    { 1LL << kTextEncodingMacMalayalam,       "kTextEncodingMacMalayalam"       },      
    { 1LL << kTextEncodingMacSinhalese,       "kTextEncodingMacSinhalese"       },      
    { 1LL << kTextEncodingMacBurmese,         "kTextEncodingMacBurmese"         },        
    { 1LL << kTextEncodingMacKhmer,           "kTextEncodingMacKhmer"           },          
    { 1LL << kTextEncodingMacThai,            "kTextEncodingMacThai"            },           
    { 1LL << kTextEncodingMacLaotian,         "kTextEncodingMacLaotian"         },        
    { 1LL << kTextEncodingMacGeorgian,        "kTextEncodingMacGeorgian"        },       
    { 1LL << kTextEncodingMacArmenian,        "kTextEncodingMacArmenian"        },       
    { 1LL << kTextEncodingMacChineseSimp,     "kTextEncodingMacChineseSimp"     },    
    { 1LL << kTextEncodingMacTibetan,         "kTextEncodingMacTibetan"         },        
    { 1LL << kTextEncodingMacMongolian,       "kTextEncodingMacMongolian"       },      
    { 1LL << kTextEncodingMacEthiopic,        "kTextEncodingMacEthiopic"        },       
    { 1LL << kTextEncodingMacCentralEurRoman, "kTextEncodingMacCentralEurRoman" },
    { 1LL << kTextEncodingMacVietnamese,      "kTextEncodingMacVietnamese"      },     
    { 1LL << kTextEncodingMacExtArabic,       "kTextEncodingMacExtArabic"       },      
    { 1LL << kTextEncodingMacUninterp,        "kTextEncodingMacUninterp"        },       
    { 1LL << kTextEncodingMacSymbol,          "kTextEncodingMacSymbol"          },         
    { 1LL << kTextEncodingMacDingbats,        "kTextEncodingMacDingbats"        },       
    { 1LL << kTextEncodingMacTurkish,         "kTextEncodingMacTurkish"         },        
    { 1LL << kTextEncodingMacCroatian,        "kTextEncodingMacCroatian"        },       
    { 1LL << kTextEncodingMacIcelandic,       "kTextEncodingMacIcelandic"       },      
    { 1LL << kTextEncodingMacRomanian,        "kTextEncodingMacRomanian"        },       
    { 1LL << kTextEncodingMacCeltic,          "kTextEncodingMacCeltic"          },         
    { 1LL << kTextEncodingMacGaelic,          "kTextEncodingMacGaelic"          },         
    { 1LL << kTextEncodingMacKeyboardGlyphs,  "kTextEncodingMacKeyboardGlyphs"  }, 
    { 1LL << 49,                              "kTextEncodingMacFarsi"           },  // note the special case
    { 1LL << 48,                              "kTextEncodingMacUkrainian"       },  // note the special case
    { 0, NULL }
};

// Common attributes, that is, those that are valid for all file system objects.

static const AttrDesc kCommonAttrDesc[] = { 
    {ATTR_CMN_NAME,             "ATTR_CMN_NAME",                kAttrRefSize,                   StringAttrPrinter, NULL},
    {ATTR_CMN_DEVID,            "ATTR_CMN_DEVID",               sizeof(dev_t),                  FPDevT, NULL},
    {ATTR_CMN_FSID,             "ATTR_CMN_FSID",                sizeof(fsid_t),                 FPFSID, NULL},
    {ATTR_CMN_OBJTYPE,          "ATTR_CMN_OBJTYPE",             sizeof(fsobj_type_t),           FPEnum, kFSObjTypeEnums},
    {ATTR_CMN_OBJTAG,           "ATTR_CMN_OBJTAG",              sizeof(fsobj_tag_t),            FPEnum, kFSObjTagEnums},
    {ATTR_CMN_OBJID,            "ATTR_CMN_OBJID",               sizeof(fsobj_id_t),             FPFSObjID, NULL},
    {ATTR_CMN_OBJPERMANENTID,   "ATTR_CMN_OBJPERMANENTID",      sizeof(fsobj_id_t),             FPFSObjID, NULL},
    {ATTR_CMN_PAROBJID,         "ATTR_CMN_PAROBJID",            sizeof(fsobj_id_t),             FPFSObjID, NULL},
    {ATTR_CMN_SCRIPT,           "ATTR_CMN_SCRIPT",              sizeof(text_encoding_t),        FPEnum, kTextEncodingEnums},
    {ATTR_CMN_CRTIME,           "ATTR_CMN_CRTIME",              sizeof(struct timespec),        FPTimeSpec, NULL},
    {ATTR_CMN_MODTIME,          "ATTR_CMN_MODTIME",             sizeof(struct timespec),        FPTimeSpec, NULL},
    {ATTR_CMN_CHGTIME,          "ATTR_CMN_CHGTIME",             sizeof(struct timespec),        FPTimeSpec, NULL},
    {ATTR_CMN_ACCTIME,          "ATTR_CMN_ACCTIME",             sizeof(struct timespec),        FPTimeSpec, NULL},
    {ATTR_CMN_BKUPTIME,         "ATTR_CMN_BKUPTIME",            sizeof(struct timespec),        FPTimeSpec, NULL},
    {ATTR_CMN_FNDRINFO,         "ATTR_CMN_FNDRINFO",            32,                             FPFinderInfoBE, NULL},
    {ATTR_CMN_OWNERID,          "ATTR_CMN_OWNERID",             sizeof(uid_t),                  FPUID, NULL},
    {ATTR_CMN_GRPID,            "ATTR_CMN_GRPID",               sizeof(gid_t),                  FPGID, NULL},
    {ATTR_CMN_ACCESSMASK,       "ATTR_CMN_ACCESSMASK",          sizeof(uint32_t),               FPModeT, NULL},
    {ATTR_CMN_NAMEDATTRCOUNT,   "ATTR_CMN_NAMEDATTRCOUNT",      sizeof(uint32_t),               FPUDec, NULL},
    {ATTR_CMN_NAMEDATTRLIST,    "ATTR_CMN_NAMEDATTRLIST",       kAttrRefSize,                   FPNull, NULL},
    {ATTR_CMN_FLAGS,            "ATTR_CMN_FLAGS",               sizeof(uint32_t),               FPFlags, kChFlagsFlags},
    {ATTR_CMN_USERACCESS,       "ATTR_CMN_USERACCESS",          sizeof(uint32_t),               FPFlags, kUserAccessFlags},
    {ATTR_CMN_EXTENDED_SECURITY,"ATTR_CMN_EXTENDED_SECURITY",   kAttrRefSize,                   ACLAttrPrinter, NULL},
    {ATTR_CMN_UUID,             "ATTR_CMN_UUID",                sizeof(guid_t),                 FPGUID, NULL},
    {ATTR_CMN_GRPUUID,          "ATTR_CMN_GRPUUID",             sizeof(guid_t),                 FPGUID, NULL},
    {ATTR_CMN_FILEID,           "ATTR_CMN_FILEID",              sizeof(uint64_t),               FPUDec, NULL},
    {ATTR_CMN_PARENTID,         "ATTR_CMN_PARENTID",            sizeof(uint64_t),               FPUDec, NULL},
    {0, NULL, 0, NULL, NULL} 
};

// Volume attributes, valid only for volumes.

static const AttrDesc kVolumeAttrDesc[] = { 
    {ATTR_VOL_INFO,             "ATTR_VOL_INFO",                0,                              FPNull, NULL},
    {ATTR_VOL_FSTYPE,           "ATTR_VOL_FSTYPE",              sizeof(uint32_t),               FPEnum, kFSTypeEnums},
    {ATTR_VOL_SIGNATURE,        "ATTR_VOL_SIGNATURE",           sizeof(uint32_t),               FPSignature, (const void *) (uintptr_t) kFPValueHostEndian},
    {ATTR_VOL_SIZE,             "ATTR_VOL_SIZE",                sizeof(off_t),                  FPSize, NULL},
    {ATTR_VOL_SPACEFREE,        "ATTR_VOL_SPACEFREE",           sizeof(off_t),                  FPSize, NULL},
    {ATTR_VOL_SPACEAVAIL,       "ATTR_VOL_SPACEAVAIL",          sizeof(off_t),                  FPSize, NULL},
    {ATTR_VOL_MINALLOCATION,    "ATTR_VOL_MINALLOCATION",       sizeof(off_t),                  FPSize, NULL},
    {ATTR_VOL_ALLOCATIONCLUMP,  "ATTR_VOL_ALLOCATIONCLUMP",     sizeof(off_t),                  FPSize, NULL},
    {ATTR_VOL_IOBLOCKSIZE,      "ATTR_VOL_IOBLOCKSIZE",         sizeof(uint32_t),               FPSize, NULL},
    {ATTR_VOL_OBJCOUNT,         "ATTR_VOL_OBJCOUNT",            sizeof(uint32_t),               FPUDec, NULL},
    {ATTR_VOL_FILECOUNT,        "ATTR_VOL_FILECOUNT",           sizeof(uint32_t),               FPUDec, NULL},
    {ATTR_VOL_DIRCOUNT,         "ATTR_VOL_DIRCOUNT",            sizeof(uint32_t),               FPUDec, NULL},
    {ATTR_VOL_MAXOBJCOUNT,      "ATTR_VOL_MAXOBJCOUNT",         sizeof(uint32_t),               FPUDec, NULL},
    {ATTR_VOL_MOUNTPOINT,       "ATTR_VOL_MOUNTPOINT",          kAttrRefSize,                   StringAttrPrinter, NULL},
    {ATTR_VOL_NAME,             "ATTR_VOL_NAME",                kAttrRefSize,                   StringAttrPrinter, NULL},
    {ATTR_VOL_MOUNTFLAGS,       "ATTR_VOL_MOUNTFLAGS",          sizeof(uint32_t),               FPFlags, kMountFlags},
    {ATTR_VOL_MOUNTEDDEVICE,    "ATTR_VOL_MOUNTEDDEVICE",       kAttrRefSize,                   StringAttrPrinter, NULL},
    {ATTR_VOL_ENCODINGSUSED,    "ATTR_VOL_ENCODINGSUSED",       sizeof(unsigned long long),     FPVerboseFlags, kEncodingsUsedFlags},
    {ATTR_VOL_CAPABILITIES,     "ATTR_VOL_CAPABILITIES",        sizeof(vol_capabilities_attr_t),FPVolCap, NULL},
    {ATTR_VOL_ATTRIBUTES,       "ATTR_VOL_ATTRIBUTES",          sizeof(vol_attributes_attr_t),  FPVolAttr, NULL},
    {0, NULL, 0, NULL, NULL} 
};

// Directory attributes, valid only for directories.

static const FPFlagDesc kMountStatusFlags[] = { 
    {DIR_MNTSTATUS_MNTPOINT,    "DIR_MNTSTATUS_MNTPOINT"},
    {0, NULL} 
};

static const AttrDesc kDirAttrDesc[] = { 
    {ATTR_DIR_LINKCOUNT,        "ATTR_DIR_LINKCOUNT",           sizeof(uint32_t),               FPUDec, NULL},
    {ATTR_DIR_ENTRYCOUNT,       "ATTR_DIR_ENTRYCOUNT",          sizeof(uint32_t),               FPUDec, NULL},
    {ATTR_DIR_MOUNTSTATUS,      "ATTR_DIR_MOUNTSTATUS",         sizeof(uint32_t),               FPFlags, kMountStatusFlags},
    {0, NULL, 0, NULL, NULL} 
};

// File attributes, valid only for files.

static const AttrDesc kFileAttrDesc[] = { 
    {ATTR_FILE_LINKCOUNT,       "ATTR_FILE_LINKCOUNT",          sizeof(uint32_t),               FPUDec, NULL},
    {ATTR_FILE_TOTALSIZE,       "ATTR_FILE_TOTALSIZE",          sizeof(off_t),                  FPSize, NULL},
    {ATTR_FILE_ALLOCSIZE,       "ATTR_FILE_ALLOCSIZE",          sizeof(off_t),                  FPSize, NULL},
    {ATTR_FILE_IOBLOCKSIZE,     "ATTR_FILE_IOBLOCKSIZE",        sizeof(uint32_t),               FPSize, NULL},
    {ATTR_FILE_CLUMPSIZE,       "ATTR_FILE_CLUMPSIZE",          sizeof(uint32_t),               FPSize, NULL},
    {ATTR_FILE_DEVTYPE,         "ATTR_FILE_DEVTYPE",            sizeof(uint32_t),               FPDevT, NULL},                // *** why does ATTR_FILE_DEVTYPE come back 0 on Tiger
    {ATTR_FILE_FILETYPE,        "ATTR_FILE_FILETYPE",           sizeof(uint32_t),               FPUDec, NULL},
    {ATTR_FILE_FORKCOUNT,       "ATTR_FILE_FORKCOUNT",          sizeof(uint32_t),               FPUDec, NULL},
    {ATTR_FILE_FORKLIST,        "ATTR_FILE_FORKLIST",           kAttrRefSize,                   FPNull, NULL},
    {ATTR_FILE_DATALENGTH,      "ATTR_FILE_DATALENGTH",         sizeof(off_t),                  FPSize, NULL},
    {ATTR_FILE_DATAALLOCSIZE,   "ATTR_FILE_DATAALLOCSIZE",      sizeof(off_t),                  FPSize, NULL},
    {ATTR_FILE_DATAEXTENTS,     "ATTR_FILE_DATAEXTENTS",        sizeof(extentrecord),           FPHex, NULL},
    {ATTR_FILE_RSRCLENGTH,      "ATTR_FILE_RSRCLENGTH",         sizeof(off_t),                  FPSize, NULL},
    {ATTR_FILE_RSRCALLOCSIZE,   "ATTR_FILE_RSRCALLOCSIZE",      sizeof(off_t),                  FPSize, NULL},
    {ATTR_FILE_RSRCEXTENTS,     "ATTR_FILE_RSRCEXTENTS",        sizeof(extentrecord),           FPHex, NULL},
    {0, NULL, 0, NULL, NULL} 
};

// Fork attributes, valid only for forks.  The whole concept of 
// fork attributes is kinda bogus, but we report them anyway.

static const AttrDesc kForkAttrDesc[] = { 
    {ATTR_FORK_TOTALSIZE,       "ATTR_FORK_TOTALSIZE",          sizeof(off_t),                  FPUDec, NULL},
    {ATTR_FORK_ALLOCSIZE,       "ATTR_FORK_ALLOCSIZE",          sizeof(off_t),                  FPUDec, NULL},
    {0, NULL, 0, NULL, NULL} 
};

static void InitAttrFlag(const AttrDesc attrs[], FPFlagDesc ** flagsPtr)
    // Given an AttrDesc array, create the corresponding FPFlagDesc array.
    // See InitAllAttrFlags for a discussion of why this is necessary.
{
    size_t          attrCount;
    size_t          attrIndex;
    FPFlagDesc *    flags;

    assert( attrs    != NULL);
    assert( flagsPtr != NULL);

    // Count the attributes.  Make sure to include the trailing null entry 
    // in that count.
    
    attrCount = 0;
    while (attrs[attrCount].attrName != NULL) {
        attrCount += 1;
    }
    attrCount += 1;
    
    // Allocate space for the flags.
    
    flags = (FPFlagDesc *) (malloc(attrCount * sizeof(FPFlagDesc)));
    assert(flags != NULL);
    
    // Create a flag for each attribute.
    
    for (attrIndex = 0; attrIndex < attrCount; attrIndex++) {
        flags[attrIndex].flagMask = attrs[attrIndex].attrMask;
        flags[attrIndex].flagName = attrs[attrIndex].attrName;
    }
    
    *flagsPtr = flags;
}

static void InitAllAttrFlags(void)
    // We need to have both an AttrDesc array (for printing the attributes in 
    // a buffer) and a FPFlagDesc array (parsing our command line arguments).  
    // Declaring these independently would be a maintenance nightmare, so we 
    // derive the less generic one (FPFlagDesc) from the more generic one 
    // (AttrDesc).
{
    if (gCommonAttrFlags == NULL) {
        InitAttrFlag(kCommonAttrDesc, &gCommonAttrFlags);
        InitAttrFlag(kVolumeAttrDesc, &gVolumeAttrFlags);
        InitAttrFlag(kDirAttrDesc,    &gDirAttrFlags);
        InitAttrFlag(kFileAttrDesc,   &gFileAttrFlags);
        InitAttrFlag(kForkAttrDesc,   &gForkAttrFlags);
    }
}

static void CalculateAttrInfo(
    const AttrDesc  attrs[], 
    attrgroup_t     attrMask, 
    size_t *        attrSizePtr,
    size_t *        nameWidthPtr,
    attrgroup_t *   supportedAttrPtr
)
    // Calculates three pieces of useful information for an attribute set.
    // 
    // o The size of the attributes.
    //
    // o The maximum width of the name of the attributes.
    //
    // o The attributes that we know about.
    //
    // You can ask for any combination of this information by setting the 
    // appropriate parameters to a non-NULL value.
    //
    // IMPORTANT:
    // If you ask for a size (attrSizePtr), this routine increments the 
    // existing value of *attrSizePtr by the size.  You must initialise 
    // the variable pointed to by attrSizePtr to an appropriate value.
    //
    // IMPORTANT:
    // If you ask for the maximum name length (nameWidthPtr), you must in
    // initialise *nameWidthPtr to a useful number (typically 0) before 
    // calling this routine.
    //
    // The available attributes are described by the attrs array.  The 
    // attributes we're specifically concerned about are described by the 
    // attrMask flags word.
{
    size_t      attrIndex;
    size_t      nameLen;
    attrgroup_t attrRemaining;
    
    assert(attrs != NULL);
    assert( (attrSizePtr != NULL) || (nameWidthPtr != NULL) || (supportedAttrPtr != NULL) );  // must ask us to do something!
    
    // For each possible attribute.
        
    attrRemaining = attrMask;
    attrIndex = 0;
    while (attrs[attrIndex].attrName != NULL) {
        if (attrRemaining & attrs[attrIndex].attrMask) {
        
            // If the attribute is selector, process its size and name.
            
            if (attrSizePtr != NULL) {
                *attrSizePtr += attrs[attrIndex].attrSize;
                if (attrs[attrIndex].attrPrinter == StringAttrPrinter) {
                    *attrSizePtr += MAXPATHLEN;
                } else if (attrs[attrIndex].attrPrinter == ACLAttrPrinter) {
                    *attrSizePtr += KAUTH_FILESEC_SIZE(KAUTH_ACL_MAX_ENTRIES);
                }
            }
            if (nameWidthPtr != NULL) {
                nameLen = strlen(attrs[attrIndex].attrName);
                if ( nameLen > *nameWidthPtr ) {
                    *nameWidthPtr = nameLen;
                }
            }
            
            // Clear this attr from attrRemaining, so by the end of this loop 
            // attrRemaining represents any unknown attrs.
            
            attrRemaining &= ~attrs[attrIndex].attrMask;
        }
        attrIndex += 1;
    }
    
    if (supportedAttrPtr != NULL) {
        *supportedAttrPtr = attrMask & ~attrRemaining;
    }
}

static int DoGetAttrListCommand(const char *itemPath, const attrlist_t *attrList, unsigned int opts, uint32_t indent, uint32_t verbose)
    // The core of the "getattrlist" command.  Our caller has already got and parsed 
    // all the necessary arguments; we just need to do the work.
{
    int             err;
    attrlist_t      attrListSupported;
    size_t          attrBufSize;
    size_t          attrNameWidth;
    char *          attrBuf;
    const char *    cursor;
    
    assert(itemPath != NULL);
    assert(attrList != NULL);

    // Work out which attributes we support, and also calculate some information 
    // about those attributes, such as the total size of the required attribute 
    // buffer and the maximum name width.
    
    attrBufSize = sizeof(uint32_t);
    attrNameWidth = 0;

    memset(&attrListSupported, 0, sizeof(attrListSupported));
    attrListSupported.bitmapcount = ATTR_BIT_MAP_COUNT;
    
    CalculateAttrInfo(kCommonAttrDesc,  attrList->commonattr, &attrBufSize, &attrNameWidth, &attrListSupported.commonattr);
    CalculateAttrInfo(kVolumeAttrDesc,  attrList->volattr,    &attrBufSize, &attrNameWidth, &attrListSupported.volattr);
    CalculateAttrInfo(kDirAttrDesc,     attrList->dirattr,    &attrBufSize, &attrNameWidth, &attrListSupported.dirattr);
    CalculateAttrInfo(kFileAttrDesc,    attrList->fileattr,   &attrBufSize, &attrNameWidth, &attrListSupported.fileattr);
    CalculateAttrInfo(kForkAttrDesc,    attrList->forkattr,   &attrBufSize, &attrNameWidth, &attrListSupported.forkattr);

    // Tell the user if we're ignoring certain attributes.
    
    if (attrListSupported.commonattr != attrList->commonattr) {
        fprintf(stderr, "*** Encountered unknown common attribute (0x%08" PRIx32 ").\n", attrList->commonattr & ~attrListSupported.commonattr );
    }
    if (attrListSupported.volattr != attrList->volattr) {
        fprintf(stderr, "*** Encountered unknown volume attribute (0x%08" PRIx32 ").\n", attrList->volattr & ~attrListSupported.volattr );
    }
    if (attrListSupported.dirattr != attrList->dirattr) {
        fprintf(stderr, "*** Encountered unknown directory attribute (0x%08" PRIx32 ").\n", attrList->dirattr & ~attrListSupported.dirattr );
    }
    if (attrListSupported.fileattr != attrList->fileattr) {
        fprintf(stderr, "*** Encountered unknown file attribute (0x%08" PRIx32 ").\n", attrList->fileattr & ~attrListSupported.fileattr );
    }
    if (attrListSupported.forkattr != attrList->forkattr) {
        fprintf(stderr, "*** Encountered unknown fork attribute (0x%08" PRIx32 ").\n", attrList->forkattr & ~attrListSupported.forkattr );
    }

    // Add the ATTR_CMN_OBJTYPE attribute if we need it internally and the user hasn't 
    // already requested it.
    
    if ( ( (attrListSupported.commonattr & ATTR_CMN_FNDRINFO) || (attrListSupported.dirattr != 0) || (attrListSupported.fileattr != 0) ) && ((attrListSupported.commonattr & ATTR_CMN_OBJTYPE) == 0) ) {
        attrListSupported.commonattr |= ATTR_CMN_OBJTYPE;
        attrBufSize += sizeof(fsobj_type_t);
        fprintf(stderr, "*** Added ATTR_CMN_OBJTYPE to allow us to print attributes that vary by file system object type.\n");
    }

    // Allocate an attribute buffer.
    
    err = 0;
    attrBuf = (char *) malloc(attrBufSize);
    if (attrBuf == NULL) {
        err = ENOMEM;
    }
    
    // Call getattrlist to fill it in.
    
    if (err == 0) {
        err = getattrlist(itemPath, &attrListSupported, attrBuf, attrBufSize, opts);
        if (err < 0) {
            err = errno;
        }   
    }
    
    // Print all of the attributes in the buffer.

    if (err == 0) {
        fsobj_type_t        objType;
        size_t              attrIndex;
        FinderInfoFlavour   finderFlavour;

        // If we asked for the object type, work out what that type is.  We need 
        // this to a) determine how to print the Finder info, and b) work out 
        // which attribute group to print.
        
        objType = VNON;
        if (attrListSupported.commonattr & ATTR_CMN_OBJTYPE) {
            cursor = attrBuf + sizeof(uint32_t);
            
            for (attrIndex = 0; (1 << attrIndex) <= ATTR_CMN_OBJTYPE; attrIndex++) {
                if (attrListSupported.commonattr & kCommonAttrDesc[attrIndex].attrMask) {
                    if (kCommonAttrDesc[attrIndex].attrMask == ATTR_CMN_OBJTYPE) {  
                        objType = * (const fsobj_type_t *) cursor;
                    }
                    cursor += kCommonAttrDesc[attrIndex].attrSize;
                }
            }
        }
        
        // Work out the Finder info flavour.
        
        finderFlavour = kVolumeInfo;
        if ( (attrListSupported.commonattr & ATTR_CMN_FNDRINFO) && ! (attrListSupported.volattr & ATTR_VOL_INFO) ) {
            if (objType == VDIR) {
                finderFlavour = kFolderInfoCombined;
            } else {
                finderFlavour = kFileInfoCombined;
            }
        }
        
        // Print the returned attributes.
        
        cursor = attrBuf + sizeof(uint32_t);
        PrintAttributes(kCommonAttrDesc,   attrListSupported.commonattr, &cursor, indent, attrNameWidth, verbose, finderFlavour);
        PrintAttributes(kVolumeAttrDesc,   attrListSupported.volattr,    &cursor, indent, attrNameWidth, verbose, finderFlavour);
        if (objType == VDIR) {
            PrintAttributes(kDirAttrDesc,  attrListSupported.dirattr,    &cursor, indent, attrNameWidth, verbose, finderFlavour);
        } else {
            PrintAttributes(kFileAttrDesc, attrListSupported.fileattr,   &cursor, indent, attrNameWidth, verbose, finderFlavour);
        }
        PrintAttributes(kForkAttrDesc,     attrListSupported.forkattr,   &cursor, indent, attrNameWidth, verbose, finderFlavour);
    }
    
    // Clean up.
    
    free(attrBuf);
    
    return err;
}

static int AttrParseItemTester(const char *item, void *refCon)
    // A callback for CommandParseItemString that a) verifies that the attribute 
    // is one that we support, and b) adds the bit for that attribute to the 
    // attrlist_t pointed to be refCon.
{
    int             err;
    attrlist_t *    attrListPtr;
    size_t          flagIndex;
    
    assert(item != NULL);
    
    attrListPtr = (attrlist_t *) refCon;
    assert(attrListPtr != NULL);
    assert(attrListPtr->bitmapcount == ATTR_BIT_MAP_COUNT);

    err = 0;
    flagIndex = FPFindFlagByName(gCommonAttrFlags, item);
    if (flagIndex != kFPNotFound) {
        attrListPtr->commonattr |= (attrgroup_t) gCommonAttrFlags[flagIndex].flagMask;
    } else {
        flagIndex = FPFindFlagByName(gVolumeAttrFlags, item);
        if (flagIndex != kFPNotFound) {
            attrListPtr->volattr |= (attrgroup_t) gVolumeAttrFlags[flagIndex].flagMask;
        } else {
            flagIndex = FPFindFlagByName(gDirAttrFlags, item);
            if (flagIndex != kFPNotFound) {
                attrListPtr->dirattr |= (attrgroup_t) gDirAttrFlags[flagIndex].flagMask;
            } else {
                flagIndex = FPFindFlagByName(gFileAttrFlags, item);
                if (flagIndex != kFPNotFound) {
                    attrListPtr->fileattr |= (attrgroup_t) gFileAttrFlags[flagIndex].flagMask;
                } else {
                    flagIndex = FPFindFlagByName(gForkAttrFlags, item);
                    if (flagIndex != kFPNotFound) {
                        attrListPtr->forkattr |= (attrgroup_t) gForkAttrFlags[flagIndex].flagMask;
                    } else {
                        err = EUSAGE;
                    }
                }
            }
        }
    }
    
    return err;
}

static CommandError PrintGetAttrListInfo(CommandArgsRef args, uint32_t indent, uint32_t verbose)
    // Implements the "getattrlist" command.
    //
    // indent and verbose are as per the comments for FPPrinter.
{
    int             err;
    unsigned int    opts;
    const char *    attrListStr;
    const char *    itemPath;
    attrlist_t      attrList;

    assert( CommandArgsValid(args) );

    InitAllAttrFlags();
    
    // Collect the arguments.
    
    opts = 0;
    if ( CommandArgsGetOptionalConstantString(args, "-FSOPT_NOFOLLOW") ) {
        opts |= FSOPT_NOFOLLOW;
    }

    if ( CommandArgsGetOptionString(args, &attrListStr) ) {
        // Use attrlist specified by user.
    } else {
        // Use default attrlist, which is just prints the list of supported attributes.
        
        attrListStr = "-ATTR_VOL_ATTRIBUTES";
    }
    
    err = CommandArgsGetString(args, &itemPath);

    // Check that the attrListStr is valid and derive the attrlist_t from it.
    
    if (err == 0) {
        memset(&attrList, 0, sizeof(attrList));
        attrList.bitmapcount = ATTR_BIT_MAP_COUNT;
        
        assert(attrListStr[0] == '-');
        err = CommandParseItemString(&attrListStr[1], ',', AttrParseItemTester, &attrList);
    }

    // Do it!
    
    if (err == 0) {
        fprintf(stdout, "%*sgetattrlist %s%s %s\n", (int) indent, "", ((opts & FSOPT_NOFOLLOW) ? "-FSOPT_NOFOLLOW " : ""), ((attrListStr == NULL ) ? "<default>" : attrListStr), itemPath);
        
        err = DoGetAttrListCommand(itemPath, &attrList, opts, indent + kStdIndent, verbose);
    }
    
    return CommandErrorMakeWithErrno(err);
}

static void AttrDescHelpPrinter(uint32_t indent, uint32_t verbose, const void *param)
    // A CommandHelpProc to print help for a group of attributes.
{
    #pragma unused(verbose)
    const AttrDesc *    attrs;
    size_t              attrIndex;
    
    attrs = (const AttrDesc *) param;
    assert(attrs != NULL);
    
    // The convoluted logic below is because we print the attributes in two columns, 
    // so as to reduce the amount of vertical space consumed.
    
    attrIndex = 0;
    while (attrs[attrIndex].attrName != NULL) {
        if (attrs[attrIndex + 1].attrName == NULL) {
            fprintf(stderr, "%*s%s\n", (int) (indent + strlen("-attrList") + 1), "", attrs[attrIndex].attrName);
            attrIndex += 1;
        } else {
            fprintf(stderr, "%*s%-30s %-30s\n", (int) (indent + strlen("-attrList") + 1), "", attrs[attrIndex].attrName, attrs[attrIndex + 1].attrName);
            attrIndex += 2;
        }
    }
}

static void AttrListHelpPrinter(uint32_t indent, uint32_t verbose, const void *param)
    // A CommandHelpProc to print all of the supportedd attributes.
{
    #pragma unused(param)
    if (verbose == 0) {
        fprintf(stderr, "%*s          Add another -v flag to see a list\n", (int) indent, "");
    } else {
        AttrDescHelpPrinter(indent, verbose, kCommonAttrDesc);
        fprintf(stderr, "\n");
        AttrDescHelpPrinter(indent, verbose, kVolumeAttrDesc);
        fprintf(stderr, "\n");
        AttrDescHelpPrinter(indent, verbose, kDirAttrDesc);
        fprintf(stderr, "\n");
        AttrDescHelpPrinter(indent, verbose, kFileAttrDesc);
        fprintf(stderr, "\n");
        AttrDescHelpPrinter(indent, verbose, kForkAttrDesc);        
    }
}

static const CommandHelpEntry kGetAttrListCommandHelp[] = {
    {CommandHelpString, "-attrList Comma separated attributes; defaults to all ATTR_VOL_ATTRIBUTES"},
    {AttrListHelpPrinter, NULL},
    {NULL, NULL}
};

const CommandInfo kGetAttrListCommand = {
    PrintGetAttrListInfo,
    "getattrlist",
    "[ -FSOPT_NOFOLLOW ] [ -attrList ] itemPath",
    "Print information from getattrlist.",
    kGetAttrListCommandHelp
};
