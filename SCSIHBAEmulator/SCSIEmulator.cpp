/*

File:SCSIEmulator.cpp

Abstract: Implementation of an emulator for a SCSI target device

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

#include <sys/systm.h>

#include "SCSIEmulator.h"

#include <IOKit/scsi/SCSICommandOperationCodes.h>
#include <IOKit/scsi/SCSICommandDefinitions.h>


#define kNumDiskLUNs		1
#define kDiskBlockLength	512

#ifndef DEBUG_VERBOSE
#define DEBUG_VERBOSE 0
#endif

#define kTempDataLen		256


#if DEBUG_VERBOSE
#define DEBUG_LOG(str, args...) IOLog(str, ##args)
#else
#define DEBUG_LOG(str, args...)
#endif 

#define DEBUG_ERROR(str, args...) IOLog(str, ##args)


SCSI_Sense_Data com_apple_dts_SCSIEmulator::gSense_BadLUN =
	{
		/* VALID_RESPONSE_CODE */				kSENSE_DATA_VALID | kSENSE_RESPONSE_CODE_Current_Errors,
		/* SEGMENT_NUMBER */					0x00, // Obsolete
		/* SENSE_KEY */							0x00 | kSENSE_KEY_ILLEGAL_REQUEST,
		/* INFORMATION_1 */						0x00,
		/* INFORMATION_2 */						0x00,
		/* INFORMATION_3 */						0x00,
		/* INFORMATION_4 */						0x00,
		/* ADDITIONAL_SENSE_LENGTH */			0x00,
		/* COMMAND_SPECIFIC_INFORMATION_1 */	0x00,
		/* COMMAND_SPECIFIC_INFORMATION_2 */	0x00,
		/* COMMAND_SPECIFIC_INFORMATION_3 */	0x00,
		/* COMMAND_SPECIFIC_INFORMATION_4 */	0x00,
		/* ADDITIONAL_SENSE_CODE */				0x25, // LOGICAL UNIT NOT SUPPORTED
		/* ADDITIONAL_SENSE_CODE_QUALIFIER */	0x00,
		/* FIELD_REPLACEABLE_UNIT_CODE */		0x00,
		/* SKSV_SENSE_KEY_SPECIFIC_MSB */		0x00,
		/* SENSE_KEY_SPECIFIC_MID */			0x00,
		/* SENSE_KEY_SPECIFIC_LSB */			0x00
	};

SCSI_Sense_Data com_apple_dts_SCSIEmulator::gSense_InvalidCommand =
	{
		/* VALID_RESPONSE_CODE */				kSENSE_DATA_VALID | kSENSE_RESPONSE_CODE_Current_Errors,
		/* SEGMENT_NUMBER */					0x00, // Obsolete
		/* SENSE_KEY */							0x00 | kSENSE_KEY_ILLEGAL_REQUEST,
		/* INFORMATION_1 */						0x00,
		/* INFORMATION_2 */						0x00,
		/* INFORMATION_3 */						0x00,
		/* INFORMATION_4 */						0x00,
		/* ADDITIONAL_SENSE_LENGTH */			0x00,
		/* COMMAND_SPECIFIC_INFORMATION_1 */	0x00,
		/* COMMAND_SPECIFIC_INFORMATION_2 */	0x00,
		/* COMMAND_SPECIFIC_INFORMATION_3 */	0x00,
		/* COMMAND_SPECIFIC_INFORMATION_4 */	0x00,
		/* ADDITIONAL_SENSE_CODE */				0x20, // Invalid command code
		/* ADDITIONAL_SENSE_CODE_QUALIFIER */	0x00,
		/* FIELD_REPLACEABLE_UNIT_CODE */		0x00,
		/* SKSV_SENSE_KEY_SPECIFIC_MSB */		0x00,
		/* SENSE_KEY_SPECIFIC_MID */			0x00,
		/* SENSE_KEY_SPECIFIC_LSB */			0x00
	};

SCSI_Sense_Data com_apple_dts_SCSIEmulator::gSense_InvalidCDBField =
	{
		/* VALID_RESPONSE_CODE */				kSENSE_DATA_VALID | kSENSE_RESPONSE_CODE_Current_Errors,
		/* SEGMENT_NUMBER */					0x00, // Obsolete
		/* SENSE_KEY */							0x00 | kSENSE_KEY_ILLEGAL_REQUEST,
		/* INFORMATION_1 */						0x00,
		/* INFORMATION_2 */						0x00,
		/* INFORMATION_3 */						0x00,
		/* INFORMATION_4 */						0x00,
		/* ADDITIONAL_SENSE_LENGTH */			0x00,
		/* COMMAND_SPECIFIC_INFORMATION_1 */	0x00,
		/* COMMAND_SPECIFIC_INFORMATION_2 */	0x00,
		/* COMMAND_SPECIFIC_INFORMATION_3 */	0x00,
		/* COMMAND_SPECIFIC_INFORMATION_4 */	0x00,
		/* ADDITIONAL_SENSE_CODE */				0x24, // INVALID FIELD IN CDB
		/* ADDITIONAL_SENSE_CODE_QUALIFIER */	0x00,
		/* FIELD_REPLACEABLE_UNIT_CODE */		0x00,
		/* SKSV_SENSE_KEY_SPECIFIC_MSB */		0x00,
		/* SENSE_KEY_SPECIFIC_MID */			0x00,
		/* SENSE_KEY_SPECIFIC_LSB */			0x00
	};

SCSICmd_INQUIRY_StandardData com_apple_dts_SCSIEmulator::gInquiry_defaultPage =
	{
		/* PERIPHERAL_DEVICE_TYPE */			0,
		/* RMB */								0,
		/* VERSION */							5,
		/* RESPONSE_DATA_FORMAT */				2,
		/* ADDITIONAL_LENGTH */					sizeof ( SCSICmd_INQUIRY_StandardData ) - 5,
		/* SCCSReserved */						0,
		/* flags1 */							0,
		/* flags2 */							0,
		/* T10_VENDOR_IDENTIFICATION */			{'A','p','p','l','e','D','T','S'},	// 8 char string, does not need to be NULL terminated 
		/* PRODUCT_IDENTIFICATION */			"SCSI Emulator  ",					// 16 char string, does not need to be NULL terminated 
		/* PRODUCT_REVISION_LEVEL */			"1.0"								// 4 char string, does not need to be NULL terminated
	};

EmulatorSCSIInquiryPage00 com_apple_dts_SCSIEmulator::gInquiry_page00 =
	{
		/* PERIPHERAL_DEVICE_TYPE */			0,
		/* PAGE_CODE */							kINQUIRY_Page00_PageCode,
		/* RESERVED */							0,
		/* PAGE_LENGTH */						sizeof ( EmulatorSCSIInquiryPage00Data ),
		/* supportedPage1 */					kINQUIRY_Page00_PageCode,
		/* supportedPage2 */					kINQUIRY_Page80_PageCode
	};

EmulatorSCSIInquiryPage80 com_apple_dts_SCSIEmulator::gInquiry_page80 =
	{
		/* PERIPHERAL_DEVICE_TYPE */			0,
		/* PAGE_CODE */							kINQUIRY_Page80_PageCode,
		/* RESERVED */							0,
		/* PAGE_LENGTH */						sizeof ( EmulatorSCSIInquiryPage80Data ) + 1,
		/* serialNumber */						'A','p','p','l','e',' ','V','i','r','t','u','a','l',' ','L','U','N','0',0
	};

// Fill in enough for 3 LUNs even though, by default, we only reporting having one.  There for ease of future expansion
SCSICmd_REPORT_LUNS_Data com_apple_dts_SCSIEmulator::gLunReport =
	{
		/* LUN_LIST_LENGTH */					OSSwapHostToBigInt32(sizeof(SCSICmd_REPORT_LUNS_LUN_ENTRY) * kNumDiskLUNs),
		/* reserved */							0,
		/* 1st LUN: 1st_LEVEL_ADDRESSING */		OSSwapHostToBigInt16 ( 0x00 ),
		/*          2nd_LEVEL_ADDRESSING */		OSSwapHostToBigInt16 ( 0x00 ),
		/*          3rd_LEVEL_ADDRESSING */		OSSwapHostToBigInt16 ( 0x00 ),
		/*          4th_LEVEL_ADDRESSING */		OSSwapHostToBigInt16 ( 0x00 ),

// Currently, the remaining data in this structure is ignored as we only report supporting one LUN per target
		/* 2nd LUN: 1st_LEVEL_ADDRESSING */		OSSwapHostToBigInt16 ( 0x01 ),
		/*          2nd_LEVEL_ADDRESSING */		OSSwapHostToBigInt16 ( 0x00 ),
		/*          3rd_LEVEL_ADDRESSING */		OSSwapHostToBigInt16 ( 0x00 ),
		/*          4th_LEVEL_ADDRESSING */		OSSwapHostToBigInt16 ( 0x00 ),
	
		/* 3rd LUN: 1st_LEVEL_ADDRESSING */		OSSwapHostToBigInt16 ( 0x02 ),
		/*          2nd_LEVEL_ADDRESSING */		OSSwapHostToBigInt16 ( 0x00 ),
		/*          3rd_LEVEL_ADDRESSING */		OSSwapHostToBigInt16 ( 0x00 ),
		/*          4th_LEVEL_ADDRESSING */		OSSwapHostToBigInt16 ( 0x00 ),
	
		/* 4th LUN: 1st_LEVEL_ADDRESSING */		OSSwapHostToBigInt16 ( 0x03 ),
		/*          2nd_LEVEL_ADDRESSING */		OSSwapHostToBigInt16 ( 0x00 ),
		/*          3rd_LEVEL_ADDRESSING */		OSSwapHostToBigInt16 ( 0x00 ),
		/*          4th_LEVEL_ADDRESSING */		OSSwapHostToBigInt16 ( 0x00 )
	};

#define super IOService

// REQUIRED! This macro defines the class's constructors, destructors,
// and several other methods I/O Kit requires. Do NOT use super as the
// second parameter. You must use the literal name of the superclass.
OSDefineMetaClassAndStructors(com_apple_dts_SCSIEmulator, IOService)


bool com_apple_dts_SCSIEmulator::init(vm_size_t capacity, OSDictionary *dictionary)
{
	mMemoryBuffer = NULL;
	mMemoryPtr = NULL;

	bool res = super::init(dictionary);

	if (res) {
		mDiskSize = capacity;
		IOOptionBits options = 0;

		mMemoryBuffer =  IOBufferMemoryDescriptor::inTaskWithOptions(kernel_task, options, mDiskSize, PAGE_SIZE); 

		if (mMemoryBuffer) {
			mMemoryPtr = (UInt8 *)mMemoryBuffer->getBytesNoCopy();

			bzero(mMemoryPtr, mDiskSize);
		}
	}
	
	return res;
}

void com_apple_dts_SCSIEmulator::free()
{
	if (mMemoryBuffer) {
		mMemoryBuffer->release();
	}
	
	super::free();
}

void com_apple_dts_SCSIEmulator::sendCommand(UInt8 *cdb, UInt8 cbdLen, IOMemoryDescriptor *dataDesc, UInt64 *dataLen, UInt32 lun, SCSITaskStatus *scsiStatus, UInt8 *senseBuffer, UInt64 *senseBufferLen)
{
	UInt32 lba;
	UInt16 len;

	unsigned int byte_offset;
	unsigned int num_bytes;

	if (!dataDesc) {
		*dataLen = 0;
	} else {
		IOByteCount length = dataDesc->getLength();
		if (length < *dataLen) {
			*dataLen = length;
		}
	}

	if (!senseBuffer) {
		*senseBufferLen = 0;
	}

	// return no device equivalent for lun request beyond available lun
	if ((lun >= kNumDiskLUNs) && (cdb[0] != kSCSICmd_INQUIRY)) {
		if (*dataLen > cdb[4])
			*dataLen = cdb[4];

		if (*dataLen > 0) {
			UInt8 tempData[kTempDataLen];
			bzero(tempData, kTempDataLen);

			tempData[0] = 0x00;												// no device.  Details:
			tempData[0] |= kINQUIRY_PERIPHERAL_TYPE_UnknownOrNoDeviceType;	//     device type
			tempData[0] |= kINQUIRY_PERIPHERAL_QUALIFIER_NotSupported;		//     peripheral qualifier

			dataDesc->writeBytes(0, tempData, *dataLen);
		}
		
		*scsiStatus = kSCSITaskStatus_CHECK_CONDITION;

		if (senseBuffer) {
			bzero(senseBuffer, *senseBufferLen);
			bcopy(&gSense_BadLUN, senseBuffer, sizeof(SCSI_Sense_Data));

			if (*senseBufferLen > sizeof(SCSI_Sense_Data))
				*senseBufferLen = sizeof(SCSI_Sense_Data);
		}
	} else {
		switch(cdb[0]) {
			case kSCSICmd_TEST_UNIT_READY:
			{
				DEBUG_LOG("SCSI Command: TEST_UNIT_READY\n");

				*scsiStatus = kSCSITaskStatus_GOOD;
				*dataLen = 0;
				*senseBufferLen = 0;
				break;
			}

			case kSCSICmd_INQUIRY:
			{
				bool CmdDT = cdb[1] & 0x02;
				bool EVPD = cdb[1] & 0x01;
				UInt8 pageCode = cdb[2];
#if DEBUG_VERBOSE
				UInt8 allocationLength = cdb[4];
				UInt8 control = cdb[5];
#endif
				DEBUG_LOG("SCSI Command: INQUIRY - CmdDT = 0x%02X, EVPD = 0x%02X, pageCode = 0x%02X, allocationLength = 0x%02X, control = 0x%02X\n", CmdDT, EVPD, pageCode, allocationLength, control);

				if (EVPD == 0) {
					if (CmdDT != 0) {
						// When CmdDT != 0 and EVPD == 0: Error condition!
						*scsiStatus = kSCSITaskStatus_CHECK_CONDITION;
						*dataLen = 0;

						if (senseBuffer) {
							bzero(senseBuffer, *senseBufferLen);
							bcopy(&gSense_InvalidCDBField, senseBuffer, sizeof(SCSI_Sense_Data));

							if (*senseBufferLen > sizeof(SCSI_Sense_Data))
								*senseBufferLen = sizeof(SCSI_Sense_Data);
						}
					} else {
						// When CmdDT == 0 and EVPD == 0: return default inquiry page
						UInt8 tempData[kTempDataLen];
						bzero(tempData, kTempDataLen);

						if (*dataLen > cdb[4])
							*dataLen = cdb[4];
								
						bcopy(&gInquiry_defaultPage, tempData, sizeof(gInquiry_defaultPage));

						dataDesc->writeBytes(0, tempData, *dataLen);

						*scsiStatus = kSCSITaskStatus_GOOD;
						*senseBufferLen = 0;
					}
				} else {
					// When CmdDT == 0 and EVPD != 0: return default inquiry page

					UInt8 tempData[kTempDataLen];
					bzero(tempData, kTempDataLen);

					if (*dataLen > cdb[4])
						*dataLen = cdb[4];

					switch (pageCode) {
						case kINQUIRY_Page00_PageCode:
						{
							bcopy(&gInquiry_page00, tempData, sizeof(gInquiry_page00));
								*dataLen = sizeof(gInquiry_page00);

							dataDesc->writeBytes(0, tempData, *dataLen);

							*scsiStatus = kSCSITaskStatus_GOOD;
							*senseBufferLen = 0;
							break;
						}

						case kINQUIRY_Page80_PageCode:
						{
							bcopy(&gInquiry_page80, tempData, sizeof(gInquiry_page80));
								*dataLen = sizeof(gInquiry_page80);

							dataDesc->writeBytes(0, tempData, *dataLen);

							*scsiStatus = kSCSITaskStatus_GOOD;
							*senseBufferLen = 0;

							break;
						}

						case kINQUIRY_Page83_PageCode:
						default:
						{
							// Code page not implemented.  Return an error
							*scsiStatus = kSCSITaskStatus_CHECK_CONDITION;
							*dataLen = 0;

							if (senseBuffer) {
								bzero(senseBuffer, *senseBufferLen);
								bcopy(&gSense_InvalidCDBField, senseBuffer, sizeof(SCSI_Sense_Data));

								if (*senseBufferLen > sizeof(SCSI_Sense_Data))
									*senseBufferLen = sizeof(SCSI_Sense_Data);
							}

							break;
						}
					}
				}

				break;
			}

			case kSCSICmd_REPORT_LUNS:
			{
				UInt8 selectReport = cdb[2];
#if DEBUG_VERBOSE
				UInt32 allocationLength = OSReadBigInt32(cdb, 6);
				UInt8 control = cdb[11];
#endif

				DEBUG_LOG("SCSI Command: REPORT_LUNS - selectReport = 0x%02X, allocationLength = 0x%08X, control = 0x%02X\n", selectReport, allocationLength, control);

				UInt8 tempData[kTempDataLen];
				bzero(tempData, kTempDataLen);

				switch (selectReport) {
					case 0:
					// Report LUNs available via LUN addressing, peripheral device addressing or flat space addressing
					case 1:
					// Report only well known LUNs
					case 2:
					// Report all known LUNs
					{
						bcopy(&gLunReport, tempData, sizeof(gLunReport));
						*dataLen = sizeof(gLunReport);

						dataDesc->writeBytes(0, tempData, *dataLen);

						*scsiStatus = kSCSITaskStatus_GOOD;
						*senseBufferLen = 0;

						break;
					}
					default:
					{
						*scsiStatus = kSCSITaskStatus_CHECK_CONDITION;
						*dataLen = 0;

						if (senseBuffer) {
							bzero(senseBuffer, *senseBufferLen);
							bcopy(&gSense_InvalidCommand, senseBuffer, sizeof(SCSI_Sense_Data));

							if (*senseBufferLen > sizeof(SCSI_Sense_Data))
								*senseBufferLen = sizeof(SCSI_Sense_Data);
						}

						break;
					}
				}

				break;
			}

			case kSCSICmd_READ_CAPACITY:
			{
				DEBUG_LOG("SCSI Command: READ_CAPACITY\n");

				UInt8 tempData[8];

				OSWriteBigInt32(tempData, 0, (mDiskSize/kDiskBlockLength)-1);	// Max LBA
				OSWriteBigInt32(tempData, 4, kDiskBlockLength);					// Block len

				dataDesc->writeBytes(0, tempData, 8);

				*dataLen = 8;
				*scsiStatus = kSCSITaskStatus_GOOD;
				*senseBufferLen = 0;

				break;
			}

			case kSCSICmd_WRITE_6:
			{
				lba = OSSwapBigToHostConstInt32(*((UInt32 *)cdb))&kSCSICmdFieldMask21Bit;
				len = cdb[4];
				if (!len)
					len = 256; // As specified in the spec, if len == 0, then behave as if it was 256

				byte_offset = lba * kDiskBlockLength;
				num_bytes = len * kDiskBlockLength;

				DEBUG_LOG("SCSI Command: WRITE_6 - %d (0x%02X) bytes at offset 0x%02X\n", num_bytes, num_bytes, byte_offset);

				dataDesc->readBytes(0, &(mMemoryPtr[byte_offset]), num_bytes);

				*scsiStatus = kSCSITaskStatus_GOOD;
				*senseBufferLen = 0;

				break;
			}

			case kSCSICmd_READ_6:
			{
				lba = OSSwapBigToHostConstInt32(*((UInt32 *)cdb))&kSCSICmdFieldMask21Bit;
				len = cdb[4];
				if (!len)
					len = 256; // As specified in the spec, if len == 0, then behave as if it was 256

				byte_offset = lba * kDiskBlockLength;
				num_bytes = len * kDiskBlockLength;

				if (*dataLen > num_bytes)
					*dataLen = num_bytes;

				DEBUG_LOG("SCSI Command: READ_6 - %d (0x%02X) bytes at offset 0x%02X\n", *dataLen, *dataLen, byte_offset);

				dataDesc->writeBytes(0, &(mMemoryPtr[byte_offset]), *dataLen);

				*scsiStatus = kSCSITaskStatus_GOOD;
				*senseBufferLen = 0;

				break;
			}

			case kSCSICmd_WRITE_10:
			{
				lba = OSReadBigInt32(cdb, 2);
				len = OSReadBigInt16(cdb, 7);

				byte_offset = lba * kDiskBlockLength;
				num_bytes = len * kDiskBlockLength;

				DEBUG_LOG("SCSI Command: WRITE_10 - %d (0x%02X) bytes at offset 0x%02X\n", num_bytes, num_bytes, byte_offset);

				dataDesc->readBytes(0, &(mMemoryPtr[byte_offset]), num_bytes);

				*scsiStatus = kSCSITaskStatus_GOOD;
				*senseBufferLen = 0;

				break;
			}

			case kSCSICmd_READ_10:
			{
				lba = OSReadBigInt32(cdb, 2);
				len = OSReadBigInt16(cdb, 7);

				byte_offset = lba * kDiskBlockLength;
				num_bytes = len * kDiskBlockLength;

				if (*dataLen > num_bytes)
					*dataLen = num_bytes;

				DEBUG_LOG("SCSI Command: READ_10 - %d (0x%02X) bytes at offset 0x%02X\n", *dataLen, *dataLen, byte_offset);

				dataDesc->writeBytes(0, &(mMemoryPtr[byte_offset]), *dataLen);

				*scsiStatus = kSCSITaskStatus_GOOD;
				*senseBufferLen = 0;

				break;
			}

			case kSCSICmd_VERIFY_10:
			{
				DEBUG_LOG("SCSI Command: VERIFY_10\n");

				// For now just set the status to success.
				*scsiStatus = kSCSITaskStatus_GOOD;
				*senseBufferLen = 0;

				break;
			}
			
			case kSCSICmd_START_STOP_UNIT:
			{
				DEBUG_LOG("SCSI Command: START_STOP_UNIT\n");

				// For now just set the status to success.
				*scsiStatus = kSCSITaskStatus_GOOD;
				*senseBufferLen = 0;

				break;
			}

			case kSCSICmd_PREVENT_ALLOW_MEDIUM_REMOVAL:
			{
				DEBUG_LOG("SCSI Command: PREVENT_ALLOW_MEDIUM_REMOVAL - prevent = 0x%02X\n", cdb[4] & kSCSICmdFieldMask2Bit);
				
				// We're not a changeable medium... safe to ignore for now
				*scsiStatus = kSCSITaskStatus_GOOD;
				*senseBufferLen = 0;

				break;
			}

			case kSCSICmd_REQUEST_SENSE:
			{
				DEBUG_LOG("SCSI Command: REQUEST_SENSE (desc = %s, allocation length = %d bytes) - returning CHECK CONDITION with INVALID COMMAND\n", (cdb[1] & 0x01) ? "TRUE" : "FALSE", cdb[4]);

				*scsiStatus = kSCSITaskStatus_CHECK_CONDITION;
				*dataLen = 0;

				if (senseBuffer) {
					bzero(senseBuffer, *senseBufferLen);
					bcopy(&gSense_InvalidCommand, senseBuffer, sizeof(SCSI_Sense_Data));

					if (*senseBufferLen > sizeof(SCSI_Sense_Data))
						*senseBufferLen = sizeof(SCSI_Sense_Data);
				}

				break;
			}

			case kSCSICmd_MODE_SENSE_6:
			{
				DEBUG_LOG("SCSI Command: MODE_SENSE_6 - returning CHECK CONDITION with INVALID COMMAND\n");

				*scsiStatus = kSCSITaskStatus_CHECK_CONDITION;
				*dataLen = 0;

				if (senseBuffer) {
					bzero(senseBuffer, *senseBufferLen);
					bcopy(&gSense_InvalidCommand, senseBuffer, sizeof(SCSI_Sense_Data));

					if (*senseBufferLen > sizeof(SCSI_Sense_Data))
						*senseBufferLen = sizeof(SCSI_Sense_Data);
				}

				break;
			}

			case kSCSICmd_MODE_SENSE_10:
			{
				DEBUG_LOG("SCSI Command: MODE_SENSE_10 - returning CHECK CONDITION with INVALID COMMAND\n");

				*scsiStatus = kSCSITaskStatus_CHECK_CONDITION;
				*dataLen = 0;

				if (senseBuffer) {
					bzero(senseBuffer, *senseBufferLen);
					bcopy(&gSense_InvalidCommand, senseBuffer, sizeof(SCSI_Sense_Data));

					if (*senseBufferLen > sizeof(SCSI_Sense_Data))
						*senseBufferLen = sizeof(SCSI_Sense_Data);
				}

				break;
			}

			default:
			{
				DEBUG_ERROR("SCSI Command: Unknown: 0x%02X - returning CHECK CONDITION with INVALID COMMAND\n", cdb[0]);

				*scsiStatus = kSCSITaskStatus_CHECK_CONDITION;
				*dataLen = 0;

				if (senseBuffer) {
					bzero(senseBuffer, *senseBufferLen);
					bcopy(&gSense_InvalidCommand, senseBuffer, sizeof(SCSI_Sense_Data));

					if (*senseBufferLen > sizeof(SCSI_Sense_Data))
						*senseBufferLen = sizeof(SCSI_Sense_Data);
				}

				break;
			}
		}
	}
}
