//
// File:       AppleSamplePCI.cpp
//
// Abstract:   Sample PCI device driver
//
// Version:    2.0
//
// Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc. ("Apple")
//             in consideration of your agreement to the following terms, and your use,
//             installation, modification or redistribution of this Apple software
//             constitutes acceptance of these terms.  If you do not agree with these
//             terms, please do not use, install, modify or redistribute this Apple
//             software.
//
//             In consideration of your agreement to abide by the following terms, and
//             subject to these terms, Apple grants you a personal, non - exclusive
//             license, under Apple's copyrights in this original Apple software ( the
//             "Apple Software" ), to use, reproduce, modify and redistribute the Apple
//             Software, with or without modifications, in source and / or binary forms;
//             provided that if you redistribute the Apple Software in its entirety and
//             without modifications, you must retain this notice and the following text
//             and disclaimers in all such redistributions of the Apple Software. Neither
//             the name, trademarks, service marks or logos of Apple Inc. may be used to
//             endorse or promote products derived from the Apple Software without specific
//             prior written permission from Apple.  Except as expressly stated in this
//             notice, no other rights or licenses, express or implied, are granted by
//             Apple herein, including but not limited to any patent rights that may be
//             infringed by your derivative works or by other works in which the Apple
//             Software may be incorporated.
//
//             The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
//             WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
//             WARRANTIES OF NON - INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A
//             PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION
//             ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
//
//             IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
//             CONSEQUENTIAL DAMAGES ( INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//             SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//             INTERRUPTION ) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION
//             AND / OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER
//             UNDER THEORY OF CONTRACT, TORT ( INCLUDING NEGLIGENCE ), STRICT LIABILITY OR
//             OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// Copyright ( C ) 2008 Apple Inc. All Rights Reserved.
//
/*
 * This is a tiny driver that attaches to a PCI device and logs information
 * about it. It doesn't alter the device in any way. It also supports a
 * generic IOUserClient subclass that allows driver specific client code to
 * make various kinds of calls into the driver, and map shared memory
 * or portions of hardware memory.
 */

#include <IOKit/IOBufferMemoryDescriptor.h>
#include <IOKit/pci/IOPCIDevice.h>

#if IOMEMORYDESCRIPTOR_SUPPORTS_DMACOMMAND
#include <IOKit/IODMACommand.h>
#endif

#include "AppleSamplePCI.h"
#include <IOKit/IOLib.h>
#include <IOKit/assert.h>

/* 
 * Define the metaclass information that is used for runtime
 * typechecking of IOKit objects. We're a subclass of IOService,
 * but usually we would subclass from a family class.
 */

#define super IOService

/*
 * even though we are defining the convenience macro super for the superclass, you must use the actual class name
 * in the OS*MetaClass macros. Note that the class name is different when supporting PowerPC on 10.4.
 */
#if MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_4
OSDefineMetaClassAndStructors( com_YourCompany_driver_SamplePCI_10_4, IOService )
#else
OSDefineMetaClassAndStructors( com_YourCompany_driver_SamplePCI, IOService )
#endif

// This function will be called when the user process calls IORegistryEntrySetCFProperties on
// this driver. You can add your custom functionality to this function.
IOReturn SamplePCIClassName::setProperties(OSObject* properties)
{
    OSDictionary*	dict;
    OSNumber*		number;
	
    dict = OSDynamicCast(OSDictionary, properties);
    if (!dict) {
		return kIOReturnBadArgument;
    }
    // we're adding the property to the registry here
    number = OSDynamicCast(OSNumber, dict->getObject(kMyDisplayValueKey));
    if (number) {
        uint32_t value = number->unsigned32BitValue();
        
		IOLog("%s[%p]::%s(%p) got value %u\n", getName(), this, __FUNCTION__, properties, value);
		updateRegistry(value);
        return kIOReturnSuccess;
    }
    else {
        return super::setProperties(properties);
	}
	
}

// updateRegistry does the actual I/O Registry update.
// It is important to note that we work on a copy of the section of the I/O Registry
// until the actual reinsertion into the I/O Registry.
// The setProperty call is serialized for us and is the only safe way to 
// handle this.
void SamplePCIClassName::updateRegistry(UInt32 value)
{
	// Directly changing a collection in the I/O Registry is not supported as it is not protected against
	// multiple writers. So expose a copy and work on that instead.
    OSDictionary* dict = OSDynamicCast(OSDictionary, copyProperty(kMyDisplayParametersKey));
	
	OSDictionary* copyDict = (OSDictionary *) dict->copyCollection();
	
    if (copyDict != NULL) {
		OSDictionary* copyBrightnessDict = OSDynamicCast(OSDictionary, copyDict->getObject(kMyDisplayBrightnessKey));
		
		if (copyBrightnessDict != NULL) {
			OSNumber* num = OSDynamicCast(OSNumber, copyBrightnessDict->getObject(kMyDisplayValueKey));
			if (num != NULL) {
				num->setValue(value);
			
				// setProperty correctly serializes I/O Registry updates for our protection.
				setProperty(kMyDisplayParametersKey, copyDict);
			}
		}
	
		copyDict->release();
	}
}


bool SamplePCIClassName::start( IOService* provider )
{
    IOMemoryDescriptor *	mem;
    IOMemoryMap *			map;
	
	IOLog("%s[%p]::%s(%p)\n", getName(), this, __FUNCTION__, provider);
	
    if (!super::start( provider ))
        return false;
	
    /*
     * Our provider class is specified in the driver property table
     * as IOPCIDevice, so the provider must be of that class.
     * The assert is just to make absolutely sure for debugging.
     */
	
    assert( OSDynamicCast( IOPCIDevice, provider ));
    fPCIDevice = (IOPCIDevice *) provider;
	
    /*
     * Enable memory response from the card
     */
    fPCIDevice->setMemoryEnable( true );
	
    /*
     * Log some info about the device
     */
	
    /* Print all the device's memory ranges */
    for ( uint32_t index = 0; index < fPCIDevice->getDeviceMemoryCount(); index++ ) {
		
        mem = fPCIDevice->getDeviceMemoryWithIndex( index );
        assert( mem );
        IOLog("Range[%d] " PhysAddr_FORMAT ":" ByteCount_FORMAT "\n", index,
             mem->getPhysicalAddress(), mem->getLength());
	}
	
    /* look up a range based on its config space base address register */
    mem = fPCIDevice->getDeviceMemoryWithRegister(
												  kIOPCIConfigBaseAddress0 );
    if ( mem ) 
        IOLog("Range@0x%x " PhysAddr_FORMAT ":" ByteCount_FORMAT "\n", kIOPCIConfigBaseAddress0,
			 mem->getPhysicalAddress(), mem->getLength());
	
    /* Map a range based on its config space base address register,
     * This is how the driver gets access to its memory-mapped registers.
     * The getVirtualAddress() method returns a kernel virtual address
     * for the register mapping */
    
    map = fPCIDevice->mapDeviceMemoryWithRegister(
												  kIOPCIConfigBaseAddress0 );
    if ( map ) {
        IOLog("Range@0x%x (" PhysAddr_FORMAT ") mapped to kernel virtual address " VirtAddr_FORMAT "\n",
			  kIOPCIConfigBaseAddress0,
			  map->getPhysicalAddress(),
			  map->getVirtualAddress() 
			  );
        
		/* Release the map object, and the mapping itself */
        map->release();
    }
	
    /* Read a config space register */
    IOLog("Config register@0x%x = " UInt32_FORMAT "\n", kIOPCIConfigCommand,
			fPCIDevice->configRead32(kIOPCIConfigCommand) );
	
    // Construct a memory descriptor for a buffer below the 4Gb physical line &
    // so addressable by 32-bit DMA. This could be used for a 
    // DMA program buffer, for example.
	
    IOBufferMemoryDescriptor * bmd = 
#if defined(__ppc__) && (MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_4)
		IOBufferMemoryDescriptor::withOptions(kIOMemoryPhysicallyContiguous, 64 * 1024, page_size);
#else
		IOBufferMemoryDescriptor::inTaskWithPhysicalMask(
														 // task to hold the memory
														 kernel_task, 
														 // options
														 kIOMemoryPhysicallyContiguous, 
														 // size
														 64*1024, 
														 // physicalMask - 32 bit addressable and page aligned
														 0x00000000FFFFF000ULL);
#endif
	
    if (bmd) {
		generateDMAAddresses(bmd);
    } else {
		IOLog("IOBufferMemoryDescriptor::inTaskWithPhysicalMask failed\n");
    }
    fLowMemory = bmd;
    
    /* Publish ourselves so clients can find us */
    registerService();
	
    return true;
}

/*
 * We'll come here when the device goes away, or the driver is unloaded.
 */

void SamplePCIClassName::stop( IOService* provider )
{
	IOLog("%s[%p]::%s(%p)\n", getName(), this, __FUNCTION__, provider);
    super::stop( provider );
}

/*
 * Method to supply an IOMemoryDescriptor for the user client to map into
 * the client process. This sample just supplies all of the hardware memory
 * associated with the PCI device's Base Address Register 0.
 * In a real driver mapping hardware memory would only ever be used in some
 * limited high performance scenarios where the device range can be safely
 * accessed by client code with compromising system stability.
 */

IOMemoryDescriptor * SamplePCIClassName::copyGlobalMemory( void )
{
    IOMemoryDescriptor* memory;
    
    memory = fPCIDevice->getDeviceMemoryWithRegister( kIOPCIConfigBaseAddress0 );
    if( memory)
        memory->retain();
	
    return memory;
}

#if defined(__ppc__) && (MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_4)
IOReturn SamplePCIClassName::generateDMAAddresses( IOMemoryDescriptor* memDesc )
{
    // Get the physical segment list. These could be used to generate a scatter gather
    // list for hardware.
	
	// This is the old getPhysicalSegment() loop calling IOMemoryDescriptor.
	// It will fail (panic) on systems with physical memory above the 4GiB line.
	
	IOByteCount			offset = 0;
	IOPhysicalAddress	physicalAddr;
	IOPhysicalLength	segmentLength;
	uint32_t			index = 0;
	
	while ((physicalAddr = memDesc->getPhysicalSegment(offset, &segmentLength))) {
		IOLog("Physical segment(%u) " PhysAddr_FORMAT ":" ByteCount_FORMAT "\n", index, physicalAddr, segmentLength);
		offset += segmentLength;
		index++;
	}
	
	return kIOReturnSuccess;
}
#else
IOReturn SamplePCIClassName::generateDMAAddresses( IOMemoryDescriptor* memDesc )
{
    // Get the physical segment list. These could be used to generate a scatter gather
    // list for hardware.
	
    IODMACommand*		cmd;
    IOReturn            err = kIOReturnSuccess;
	
    // 64 bit physical address generation using IODMACommand
    do
    {
		cmd = IODMACommand::withSpecification(
											  // outSegFunc - Host endian since we read the address data with the cpu
											  // and 64 bit wide quantities
											  kIODMACommandOutputHost64, 
											  // numAddressBits
											  64, 
											  // maxSegmentSize - zero for unrestricted physically contiguous chunks
											  0,
											  // mappingOptions - kMapped for DMA addresses
											  IODMACommand::kMapped,
											  // maxTransferSize - no restriction
											  0,
											  // alignment - no restriction
											  1 );
		if (!cmd)
		{
			IOLog("IODMACommand::withSpecification failed\n");
			break;
		}
		
		// Point at the memory descriptor and use the auto prepare option
		// to prepare the entire range
		err = cmd->setMemoryDescriptor(memDesc);
		if (kIOReturnSuccess != err)
		{
			IOLog("setMemoryDescriptor failed (0x%08x)\n", err);
			break;
		}
		
		UInt64 offset = 0;
		while ((kIOReturnSuccess == err) && (offset < memDesc->getLength()))
		{
			// use the 64 bit variant to match outSegFunc
			IODMACommand::Segment64 segments[1];
			UInt32 numSeg = 1;
			
			// use the 64 bit variant to match outSegFunc
			err = cmd->gen64IOVMSegments(&offset, &segments[0], &numSeg);
			IOLog("gen64IOVMSegments(%x) addr 0x%016llx, len %llu, nsegs " UInt32_FORMAT "\n",
				  err, segments[0].fIOVMAddr, segments[0].fLength, numSeg);
		}
		
		// if we had a DMA controller, kick off the DMA here
		
		// when the DMA has completed,
		
		// clear the memory descriptor and use the auto complete option
		// to complete the transaction
		err = cmd->clearMemoryDescriptor();
		if (kIOReturnSuccess != err)
		{
			IOLog("clearMemoryDescriptor failed (0x%08x)\n", err);
		}
    }
    while (false);
    if (cmd)
		cmd->release();
    // end 64 bit loop
	
	
    // 32 bit physical address generation using IODMACommand
    // any memory above 4GiB in the memory descriptor will be bounce-buffered
    // to memory below the 4GiB line on machines without remapping HW support
    do
    {
		cmd = IODMACommand::withSpecification(
											  // outSegFunc - Host endian since we read the address data with the cpu
											  // and 32 bit wide quantities
											  kIODMACommandOutputHost32, 
											  // numAddressBits
											  32, 
											  // maxSegmentSize - zero for unrestricted physically contiguous chunks
											  0,
											  // mappingOptions - kMapped for DMA addresses
											  IODMACommand::kMapped,
											  // maxTransferSize - no restriction
											  0,
											  // alignment - no restriction
											  1 );
		if (!cmd)
		{
			IOLog("IODMACommand::withSpecification failed\n");
			break;
		}
		
		// point at the memory descriptor and use the auto prepare option
		// to prepare the entire range
		err = cmd->setMemoryDescriptor(memDesc);
		if (kIOReturnSuccess != err)
		{
			IOLog("setMemoryDescriptor failed (0x%08x)\n", err);
			break;
		}
		
		UInt64 offset = 0;
		while ((kIOReturnSuccess == err) && (offset < memDesc->getLength()))
		{
			// use the 32 bit variant to match outSegFunc
			IODMACommand::Segment32 segments[1];
			UInt32 numSeg = 1;
			
			// use the 32 bit variant to match outSegFunc
			err = cmd->gen32IOVMSegments(&offset, &segments[0], &numSeg);
			IOLog("gen32IOVMSegments(%x) addr " UInt32_x_FORMAT ", len " UInt32_FORMAT ", nsegs " UInt32_FORMAT "\n",
				  err, segments[0].fIOVMAddr, segments[0].fLength, numSeg);
		}
		
		// if we had a DMA controller, kick off the DMA here
		
		// when the DMA has completed,
		
		// clear the memory descriptor and use the auto complete option
		// to complete the transaction
		err = cmd->clearMemoryDescriptor();
		if (kIOReturnSuccess != err)
		{
			IOLog("clearMemoryDescriptor failed (0x%08x)\n", err);
		}
    }
    while (false);
    if (cmd)
		cmd->release();
    // end 32 bit loop
	
    return (err);
}
#endif