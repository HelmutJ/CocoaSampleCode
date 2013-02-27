/*
	File:			SampleFilterScheme.h
	
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
			<2>		03/03/2005			Updated disktool instructions for 10.3 and later.
										Added support for filtering the boot volume.
            <1>	 	01/22/2002			New sample.
        
*/

#include <IOKit/storage/IOMedia.h>
#include <IOKit/storage/IOStorage.h>

class com_apple_dts_driver_SampleFilterScheme : public IOStorage {

    OSDeclareDefaultStructors(com_apple_dts_driver_SampleFilterScheme)

protected:
    
    IOMedia*	_childMedia;
    
    /*
     * Free all of this object's outstanding resources.
     */

    virtual void free(void);

    /*!
     * @function handleOpen
     * @discussion
     * The handleOpen method grants or denies permission to access this object
     * to an interested client.  The argument is an IOStorageAccess value that
     * specifies the level of access desired -- reader or reader-writer.
     *
     * This method can be invoked to upgrade or downgrade the access level for
     * an existing client as well.  The previous access level will prevail for
     * upgrades that fail, of course.   A downgrade should never fail.  If the
     * new access level should be the same as the old for a given client, this
     * method will do nothing and return success.  In all cases, one, singular
     * close-per-client is expected for all opens-per-client received.
     *
     * This implementation replaces the IOService definition of handleOpen().
     * @param client
     * Client requesting the open.
     * @param options
     * Options for the open.  Set to zero.
     * @param access
     * Access level for the open.  Set to kIOStorageAccessReader or
     * kIOStorageAccessReaderWriter.
     * @result
     * Returns true if the open was successful, false otherwise.
     */

    virtual bool handleOpen(IOService*   client,
                            IOOptionBits options,
                            void*        access);

    /*!
     * @function handleIsOpen
     * @discussion
     * The handleIsOpen method determines whether the specified client, or any
     * client if none is specificed, presently has an open on this object.
     *
     * This implementation replaces the IOService definition of handleIsOpen().
     * @param client
     * Client to check the open state of.  Set to zero to check the open state
     * of all clients.
     * @result
     * Returns true if the client was (or clients were) open, false otherwise.
     */

    virtual bool handleIsOpen(const IOService* client) const;

    /*!
     * @function handleClose
     * @discussion
     * The handleClose method closes the client's access to this object.
     *
     * This implementation replaces the IOService definition of handleClose().
     * @param client
     * Client requesting the close.
     * @param options
     * Options for the close.  Set to zero.
     */

    virtual void handleClose(IOService* client, IOOptionBits options);
	
#ifdef FILTER_BOOT_VOLUME
	
	/*
     * Attach the given media object to the device tree plane.
     */

    virtual bool attachMediaObjectToDeviceTree(IOMedia* media);

    /*
     * Detach the given media object from the device tree plane.
     */

    virtual void detachMediaObjectFromDeviceTree(IOMedia* media);
	
#endif

public:

    /*
     * Initialize this object's minimal state.
     */

    virtual bool init(OSDictionary* properties = 0);

    /*
     * Publish the new media object which represents our filtered content.
     */

    virtual bool start(IOService* provider);

    /*
     * Clean up after the media object we published before terminating.
     */

    virtual void stop(IOService* provider);

    /*!
     * @function read
     * @discussion
     * Read data from the storage object at the specified byte offset into the
     * specified buffer, asynchronously. When the read completes, the caller
     * will be notified via the specified completion action.
     *
     * The buffer will be retained for the duration of the read.
     *
     * For simple filter schemes, the default behavior is to simply pass the
     * read through to the provider media. More complex filter schemes such
     * as RAID will need to do extra processing here.
     * @param client
     * Client requesting the read.
     * @param byteStart
     * Starting byte offset for the data transfer.
     * @param buffer
     * Buffer for the data transfer. The size of the buffer implies the size of
     * the data transfer.
     * @param completion
     * Completion routine to call once the data transfer is complete.
     */

    virtual void read(IOService*           client,
                      UInt64               byteStart,
                      IOMemoryDescriptor*  buffer,
                      IOStorageCompletion  completion);

    /*!
     * @function write
     * @discussion
     * Write data into the storage object at the specified byte offset from the
     * specified buffer, asynchronously. When the write completes, the caller
     * will be notified via the specified completion action.
     *
     * The buffer will be retained for the duration of the write.
     *
     * For simple filter schemes, the default behavior is to simply pass the
     * write through to the provider media. More complex filter schemes such
     * as RAID will need to do extra processing here.
     * @param client
     * Client requesting the write.
     * @param byteStart
     * Starting byte offset for the data transfer.
     * @param buffer
     * Buffer for the data transfer. The size of the buffer implies the size of
     * the data transfer.
     * @param completion
     * Completion routine to call once the data transfer is complete.
     */

    virtual void write(IOService*           client,
                       UInt64               byteStart,
                       IOMemoryDescriptor*  buffer,
                       IOStorageCompletion  completion);
                       
    /*!
     * @function synchronizeCache
     * @discussion
     * Flush the cached data in the storage object, if any, synchronously.
     * @param client
     * Client requesting the cache synchronization.
     * @result
     * Returns the status of the cache synchronization.
     */
    
    virtual IOReturn synchronizeCache(IOService* client);

    /*
     * Obtain this object's provider. We override the superclass's method
     * to return a more specific subclass of OSObject--an IOMedia. This
     * method serves simply as a convenience to subclass developers.
     */

    virtual IOMedia* getProvider() const;
};

