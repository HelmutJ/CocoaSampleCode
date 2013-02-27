/*
	File:			SampleFilterScheme.cpp
	
	Description:	This sample demonstrates a simple filter scheme that matches an HFS+ media object
					with a custom content hint property. This is a null filter scheme which passes all
					operations through to its provider unchanged. 

					The sample also illustrates how such a media object can be created using the command 
					line disk image tool.
	
	Copyright:    	© Copyright 2002-2005 Apple Computer, Inc. All rights reserved.
	
	Disclaimer:		IMPORTANT:  This Apple software is supplied to you by Apple Computer,
					Inc. (“Apple”) in consideration of your agreement to the following
					terms, and your use, installation, modification or redistribution of
					this Apple software constitutes acceptance of these terms.  If you do
					not agree with these terms, please do not use, install, modify or
					redistribute this Apple software.
					
					In consideration of your agreement to abide by the following terms, and
					subject to these terms, Apple grants you a personal, non-exclusive
					license, under Apple’s copyrights in this original Apple software (the
					“Apple Software”), to use, reproduce, modify and redistribute the Apple
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
					
	Change History (most recent first):
        
			<3>		11/01/2005			Updated to produce a universal binary. Now requires
										Xcode 2.2 or later to build.
			<2>		03/03/2005			Updated hdiutil instructions for 10.3 and later.
										Added support for filtering the boot volume.
            <1>	 	01/22/2002			New sample.
        
*/

#include <IOKit/assert.h>
#include <IOKit/IODeviceTreeSupport.h>
#include <IOKit/IOLib.h>
#include "SampleFilterScheme.h"

#ifdef DEBUG
#define DEBUG_LOG IOLog
#else
#define DEBUG_LOG(...)
#endif


//	This filter scheme is set up to match IOMedia objects with the Content Hint
//	property set to "Apple_DTS_Filtered_HFS" (see the matching personality in this project's
//	Info.plist). To test this filter scheme, please see the instructions in the Read Me file
//	that comes with this sample.	

#define super IOStorage
OSDefineMetaClassAndStructors(com_apple_dts_driver_SampleFilterScheme, IOStorage)

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

bool com_apple_dts_driver_SampleFilterScheme::init(OSDictionary* properties)
{    
	//
    // Initialize this object's minimal state.
    //

    // State our assumptions.

    // Ask our superclass' opinion.

    bool initSuccessful = super::init(properties);

	// The DEBUG_LOG call must follow the call to super::init(). Otherwise getName() 
	// will panic because the metaclass info isn't initialized until then.
	
	DEBUG_LOG("%s[%p]::%s(%p)\n", getName(), this, __FUNCTION__, properties);

    if (initSuccessful) {
		// Initialize our state.

		_childMedia = 0;
	}

    return initSuccessful;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

void com_apple_dts_driver_SampleFilterScheme::free(void)
{
    DEBUG_LOG("%s[%p]::%s()\n", getName(), this, __FUNCTION__);
    
	//
    // Free all of this object's outstanding resources.
    //

    if (_childMedia) {
		_childMedia->release();
	}

    super::free();
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

IOMedia* com_apple_dts_driver_SampleFilterScheme::getProvider(void) const
{
    DEBUG_LOG("%s[%p]::%s()\n", getName(), this, __FUNCTION__);
    
	//
    // Obtain this object's provider.  We override the superclass's method
    // to return a more specific subclass of OSObject -- an IOMedia.  This
    // method serves simply as a convenience to subclass developers.
    //

    return (IOMedia*) IOService::getProvider();
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

bool com_apple_dts_driver_SampleFilterScheme::start(IOService* provider)
{    
    DEBUG_LOG("%s[%p]::%s(%p)\n", getName(), this, __FUNCTION__, provider);
    
	//
    // Publish the new media object which represents our filtered content.
    //

    IOMedia* media = OSDynamicCast(IOMedia, provider);
    
    // State our assumptions.

    assert(media);
    
    // Ask our superclass' opinion.

    if (super::start(provider) == false) {
        return false;
	}

    // Attach and register the new media object.

    IOMedia* childMedia = new IOMedia;

    if (childMedia) {
        if (childMedia->init(
                /* base               */ 0,
                /* size               */ media->getSize(),
                /* preferredBlockSize */ media->getPreferredBlockSize(),
                /* isEjectable        */ media->isEjectable(),
                /* isWhole            */ false,
                /* isWritable         */ media->isWritable(),
                /* contentHint        */ "Apple_HFS" )) {
            
			// Set a name for this partition.
            
            UInt32 partitionID = 1;
            
            char name[24];
            sprintf(name, "Apple_DTS_Filtered %ld", partitionID);
            childMedia->setName(name);

            // Set a location value (the partition number) for this partition.

            char location[12];
            sprintf(location, "%ld", partitionID);
            childMedia->setLocation(location);

            // Attach the new media to this driver

            _childMedia = childMedia;
            
            childMedia->attach(this);
			
#ifdef FILTER_BOOT_VOLUME

			/*
				This next call allows this filter scheme to be installed on the boot partition.
				
				First, some background on why this is necessary.
				
				Once Open Firmware (OF) has chosen the volume to boot from, it loads the secondary loader (BootX)  
				from that volume and jumps to it. The secondary loader is responsible for actually loading
				and running the kernel, passing to it various parameters that are inherited from OF
				(primarily the device tree).
				
				Once the kernel comes up, it has to mount the root volume. By this point OF is no
				longer running, so the kernel determines the root volume by interpreting a parameter that  
				OF passed to it. This parameter is the "rootpath" property of the "/chosen" node in the OF
				device tree. The kernel gets this value and looks in the I/O Registry for a node whose
				OF path matches this value. The kernel then uses this node as the root device.
				
				The kernel has no knowledge that a filter scheme was installed on top of that node,
				so it continues booting from the unfiltered media object. Later on the  
				Disk Arbitration server comes up, notices that the filter scheme is  
				publishing a new leaf node that hasn't been mounted on, and mounts the file  
				system on that node. Hence two copies of the boot volume appear on the desktop with
				separate data paths, a recipe for quickly corrupting the contents of the volume.
				
				The solution is for the filter scheme to "move" the last device tree component from its parent
				to its child. That is, it needs to detach the parent from the device tree path, keeping track
				of its name@location value, then attach it to the child. This must be done before publishing the
				new media object via registerService(). The reverse needs to be done in stop().
				
				Note that if you want this filter scheme to be loaded at boot time (so that it can be installed
				on top of the boot volume), this project has a second target called "Filter Boot Volume". Building
				this target will include the code bracketed by #ifdef FILTER_BOOT_VOLUME and will include a
				different Info.plist file containing the property OSBundleRequired = "Local-Root". (Keep this
				detail in mind: if you change something in Info.plist, be sure to make the same change in
				Info-FILTER_BOOT_VOLUME.plist. There's no equivalent to #ifdef for plists.)
				
				Only build the "Filter Boot Volume" target if you really need to filter the boot volume.
				Otherwise, build the default "Don't Filter Boot" target.
			*/

            (void) attachMediaObjectToDeviceTree(childMedia);

#endif
			
			// Now publish the child media object.
			
			childMedia->registerService();

            return true;
        }
        else {
            childMedia->release();
            childMedia = 0;
        }
    }

    return false;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

void com_apple_dts_driver_SampleFilterScheme::stop(IOService* provider)
{
    DEBUG_LOG("%s[%p]::%s(%p)\n", getName(), this, __FUNCTION__, provider);
    
	//
    // Clean up after the media object we published before terminating.
    //

    // State our assumptions.

    assert(_childMedia);

#ifdef FILTER_BOOT_VOLUME

    // Detach the media object we previously attached to the device tree.
	// See start() for an explanation of this call.
	
	if (_childMedia) {
		detachMediaObjectFromDeviceTree(_childMedia);
	}
	
#endif

    super::stop(provider);
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

bool com_apple_dts_driver_SampleFilterScheme::handleOpen(IOService* client,
                                                         IOOptionBits options,
                                                         void* argument)
{
    //
    // The handleOpen method grants or denies permission to access this object
    // to an interested client.  The argument is an IOStorageAccess value that
    // specifies the level of access desired -- reader or reader-writer.
    //
    // This method can be invoked to upgrade or downgrade the access level for
    // an existing client as well.  The previous access level will prevail for
    // upgrades that fail, of course.   A downgrade should never fail.  If the
    // new access level should be the same as the old for a given client, this
    // method will do nothing and return success.  In all cases, one, singular
    // close-per-client is expected for all opens-per-client received.
    //
    // This implementation replaces the IOService definition of handleOpen().
    //
    // We are guaranteed that no other opens or closes will be processed until
    // we make our decision, change our state, and return from this method.
    //

    DEBUG_LOG("%s[%p]::%s(%p, %lu, %p)\n", getName(), this, __FUNCTION__, client, options, argument);

    return getProvider()->open(this, options, (IOStorageAccess) argument);
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

bool com_apple_dts_driver_SampleFilterScheme::handleIsOpen(const IOService* client) const
{
    //
    // The handleIsOpen method determines whether the specified client, or any
    // client if none is specified, presently has an open on this object.
    //
    // This implementation replaces the IOService definition of handleIsOpen().
    //
    // We are guaranteed that no other opens or closes will be processed until
    // we return from this method.
    //

    DEBUG_LOG("%s[%p]::%s(%p)\n", getName(), this, __FUNCTION__, client);

    return getProvider()->isOpen(this);
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

void com_apple_dts_driver_SampleFilterScheme::handleClose(IOService* client, IOOptionBits options)
{
    //
    // The handleClose method closes the client's access to this object.
    //
    // This implementation replaces the IOService definition of handleClose().
    //
    // We are guaranteed that no other opens or closes will be processed until
    // we change our state and return from this method.
    //

    DEBUG_LOG("%s[%p]::%s(%p, %lu)\n", getName(), this, __FUNCTION__, client, options);

    assert(client);

    getProvider()->close(this, options);
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

void com_apple_dts_driver_SampleFilterScheme::read(IOService* __attribute__ ((unused)) client,
                                                   UInt64 byteStart,
                                                   IOMemoryDescriptor* buffer,
                                                   IOStorageCompletion completion)
{
    //
    // Read data from the storage object at the specified byte offset into the
    // specified buffer, asynchronously. When the read completes, the caller
    // will be notified via the specified completion action.
    //
    // The buffer will be retained for the duration of the read.
    //
    // For simple partition schemes, the default behavior is to simply pass the
    // read through to the provider media.  More complex partition schemes such
    // as RAID will need to do extra processing here.
    //

    DEBUG_LOG("%s[%p]::%s(%p, %llu, %p, %p)\n", getName(), this, __FUNCTION__, client, byteStart, buffer, &completion);

    getProvider()->read(this, byteStart, buffer, completion);
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

void com_apple_dts_driver_SampleFilterScheme::write(IOService* __attribute__ ((unused)) client,
                                                    UInt64 byteStart,
                                                    IOMemoryDescriptor* buffer,
                                                    IOStorageCompletion completion)
{
    //
    // Write data into the storage object at the specified byte offset from the
    // specified buffer, asynchronously. When the write completes, the caller
    // will be notified via the specified completion action.
    //
    // The buffer will be retained for the duration of the write.
    //
    // For simple partition schemes, the default behavior is to simply pass the
    // write through to the provider media. More complex partition schemes such
    // as RAID will need to do extra processing here.
    //

    DEBUG_LOG("%s[%p]::%s(%p, %llu, %p, %p)\n", getName(), this, __FUNCTION__, client, byteStart, buffer, &completion);

    getProvider()->write(this, byteStart, buffer, completion);
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

IOReturn com_apple_dts_driver_SampleFilterScheme::synchronizeCache(IOService* client)
{
    //
    // I/O Kit has provisions for data caches at the driver level, but this is
    // rarely needed and is discouraged by Apple. 99+% of the time the following
    // implementation is just fine.
    //
      
    DEBUG_LOG("%s[%p]::%s(%p)\n", getName(), this, __FUNCTION__, client);

    return getProvider()->synchronizeCache(this);
}

#ifdef FILTER_BOOT_VOLUME

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

bool com_apple_dts_driver_SampleFilterScheme::attachMediaObjectToDeviceTree(IOMedia* media)
{
	//
	// Attach the given media object to the device tree plane.
	//

	IORegistryEntry* child;

    DEBUG_LOG("%s[%p]::%s(%p)\n", getName(), this, __FUNCTION__, media);

	if ((child = getParentEntry(gIOServicePlane))) {

		IORegistryEntry* parent;

		if ((parent = child->getParentEntry(gIODTPlane))) {

			const char* location = child->getLocation(gIODTPlane);
			const char* name     = child->getName(gIODTPlane);

			if (media->attachToParent(parent, gIODTPlane)) {
				media->setLocation(location, gIODTPlane);
				media->setName(name, gIODTPlane);

				child->detachFromParent(parent, gIODTPlane);

				return true;
			}
		}
	}

	return false;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

void com_apple_dts_driver_SampleFilterScheme::detachMediaObjectFromDeviceTree(IOMedia* media)
{
	//
	// Detach the given media object from the device tree plane.
	//

	IORegistryEntry* child;

    DEBUG_LOG("%s[%p]::%s(%p)\n", getName(), this, __FUNCTION__, media);

	if ((child = getParentEntry(gIOServicePlane))) {
	 
		IORegistryEntry * parent;

		if ((parent = media->getParentEntry(gIODTPlane))) {

			const char* location = media->getLocation(gIODTPlane);
			const char* name     = media->getName(gIODTPlane);

			if (child->attachToParent(parent, gIODTPlane)) {
				child->setLocation(location, gIODTPlane);
				child->setName(name, gIODTPlane);
			}

			media->detachFromParent(parent, gIODTPlane);
		}
	}
}

#endif