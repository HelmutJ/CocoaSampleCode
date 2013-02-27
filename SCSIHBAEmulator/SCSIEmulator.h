/*

File:SCSIEmulator.h

Abstract: Header for an emulator for a SCSI target device

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

Copyright (C) 2007 Apple Inc. All Rights Reserved.

*/

#ifndef _SCSIEMULATOR_H
#define _SCSIEMULATOR_H

#include <IOKit/IOLib.h>
#include <IOKit/IOBufferMemoryDescriptor.h>
#include <IOKit/IOMemoryCursor.h>

// SCSI Architecture Model Family includes
#include <IOKit/scsi/SCSITask.h>
#include <IOKit/scsi/IOSCSIProtocolInterface.h>
#include <IOKit/scsi/SCSICmds_REQUEST_SENSE_Defs.h>
#include <IOKit/scsi/SCSICmds_INQUIRY_Definitions.h>
#include <IOKit/scsi/SCSICmds_REPORT_LUNS_Definitions.h>

#define kTwentyMegs	(20 * 1024 * 1024)

#pragma pack(1)
typedef struct EmulatorSCSIInquiryPage00Data
{
	UInt8							page00;
	UInt8							page80;
} EmulatorSCSIInquiryPage00Data;

typedef struct EmulatorSCSIInquiryPage80Data
{
	UInt8							serialBytes[31];
} EmulatorSCSIInquiryPage80Data;

typedef struct EmulatorSCSIInquiryPage00
{
	SCSICmd_INQUIRY_Page00_Header	header;
	EmulatorSCSIInquiryPage00Data	data;
} EmulatorSCSIInquiryPage00;

typedef struct EmulatorSCSIInquiryPage80
{
	SCSICmd_INQUIRY_Page80_Header	header;
	EmulatorSCSIInquiryPage80Data	data;
} EmulatorSCSIInquiryPage80;

typedef struct SCSICmd_REPORT_LUNS_Data
{
	SCSICmd_REPORT_LUNS_Header		header;
	SCSICmd_REPORT_LUNS_LUN_ENTRY	lun1;
	SCSICmd_REPORT_LUNS_LUN_ENTRY	lun2;
	SCSICmd_REPORT_LUNS_LUN_ENTRY	lun3;
} SCSICmd_REPORT_LUNS_Data;

#pragma options align=reset


class com_apple_dts_SCSIEmulator : public IOService {

OSDeclareDefaultStructors(com_apple_dts_SCSIEmulator)

public:
	virtual bool init(vm_size_t capacity = kTwentyMegs, OSDictionary *dictionary = 0);
	virtual void free();

	void sendCommand(
				UInt8 *cdb, UInt8 cbdLen, IOMemoryDescriptor *dataDesc, UInt64 *dataLen,
				UInt32 lun, SCSITaskStatus *scsiStatus, UInt8 *senseBuffer, UInt64 *senseBufferLen);

private:
	vm_size_t								mDiskSize;
	IOBufferMemoryDescriptor				*mMemoryBuffer;
	UInt8									*mMemoryPtr;
	
	static SCSI_Sense_Data					gSense_BadLUN;
	static SCSI_Sense_Data					gSense_InvalidCommand;
	static SCSI_Sense_Data					gSense_InvalidCDBField;
	
	static SCSICmd_INQUIRY_StandardData		gInquiry_defaultPage;
	static EmulatorSCSIInquiryPage00		gInquiry_page00;
	static EmulatorSCSIInquiryPage80		gInquiry_page80;
	static SCSICmd_REPORT_LUNS_Data			gLunReport;
};

#endif