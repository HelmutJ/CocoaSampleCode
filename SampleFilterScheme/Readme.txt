SampleFilterScheme

The I/O Kit IOStorageFamily defines a generic interface to mass storage devices. This family's IOMedia class represents a stream of bytes on a storage medium. Read and write operations on IOMedia objects consist of a data buffer, a location relative to the beginning of the stream, and a count of bytes to transfer. Typical IOMedia objects represent either a partition on a storage device or the device's entire contents.

A filter scheme driver matches on a parent (also known as provider) IOMedia object representing a partition and is loaded onto the mass storage driver stack above that object. The filter scheme driver then creates and publishes a child IOMedia object. Generic read and write requests are passed from the child IOMedia object to the driver, which can then modify or "filter" the requests before passing them on to the parent media object. Because filter scheme drivers are both consumers and producers of IOMedia objects, there can be an arbitrary number of filter schemes in the driver stack.

Note that at this level of the architecture there is no concept of files or directories. Those abstractions are handled by the filesystem plugins that call the mass storage driver stack.

Filter schemes match to the Content Hint property published by IOMedia objects. The Content Hint property on partitioned media is initialized to the partition type found in the partition table. This sample filter scheme is set up to match IOMedia objects with the Content Hint property set to Apple_DTS_Filtered_HFS (see the matching personality in the project's Info.plist). In this sample, all read and write operations are passed through to its provider unchanged.

To test this filter scheme, you can set up a disk image containing a partition of type Apple_DTS_Filtered_HFS using this command in Terminal:

	$ hdiutil create -megabytes 5 -partitionType Apple_DTS_Filtered_HFS ~/Documents/Apple_DTS_Filtered_Example.dmg

Next, attach the disk image without mounting it because it doesn't yet contain a valid filesystem. On Mac OS X 10.2 or later use this command:

	$ hdiutil attach -nomount ~/Documents/Apple_DTS_Filtered_Example.dmg

On Mac OS X 10.1.x use this instead (the -nomount option was added in 10.2):

	$ hdiutil attach ~/Documents/Apple_DTS_Filtered_Example.dmg

hdiutil attach will display the special device name associated with each partition on the disk image:

	/dev/disk1              Apple_partition_scheme
	/dev/disk1s1            Apple_partition_map
	/dev/disk1s2            Apple_DTS_Filtered_HFS

In this example, /dev/disk1 represents the whole disk image while /dev/disk1s1 and /dev/disk1s2 represent the partitions on the media.

Now, write an empty HFS+ filesystem to the Apple_DTS_Filtered_HFS partition on the disk image using newfs_hfs. The parameter to newfs_hfs is the raw disk node equivalent to the node assigned to the Apple_DTS_Filtered_HFS partition. Raw disk node names begin with "r". So, if hdiutil attach shows the Apple_DTS_Filtered_HFS partition mounted on /dev/disk1s2, the newfs_hfs command would be issued on /dev/rdisk1s2.

	$ newfs_hfs -v "DTS_Test" /dev/rdisk1s2

Finally, detach the image. We'll attach it again once the filter scheme driver has been loaded. The hdiutil detach command is issued on the device node representing the whole image:

	$ hdiutil detach /dev/disk1

Now that the disk image has been created, load the filter scheme driver manually using kextload or by installing it in /System/Library/Extensions.

To load the driver manually, build the driver, then issue these commands in Terminal (The idea is to set the driver's ownership and permissions properly. See the Kernel Extensions release note at <http://developer.apple.com/releasenotes/Darwin/KernelExtensions.html> for details.):

	$ sudo rm -rf ~/Documents/SampleFilterScheme.kext
	$ sudo cp -r /path_to/SampleFilterScheme/build/SampleFilterScheme.kext ~/Documents
	$ sudo chown -R root:wheel ~/Documents/SampleFilterScheme.kext
	$ sudo kextload ~/Documents/SampleFilterScheme.kext

IMPORTANT: In the cp command above, be sure not to put a trailing / at the end of the source path. If you use the shell's pathname expansion feature, it will add a / character: be sure to remove it so that the driver will be copied properly.

You now have about a minute to open the disk image before I/O Kit will unload the driver.

NOTE: If the driver hasn't changed since it was last built, you can load it manually with just the kextload command shown above.

To install the driver:

	$ cd /path_to/SampleFilterScheme
	$ sudo xcodebuild -buildstyle Deployment install
	$ sudo touch /System/Library/Extensions	
	$ sudo shutdown -r now

If the filter scheme driver is loaded and working correctly, opening the disk image by double clicking it in the Finder will result in it being mounted as a normal volume called DTS_Test. The image can also be mounted using Disk Utility (Mac OS X 10.2 or later), Disk Copy (prior to 10.2), or hdiutil attach (without specifying the -nomount option).

If the image mounts successfully, it can be unmounted normally from Finder, Disk Utility, or Disk Copy. If the image hasn't been mounted, it can be detached by using the Eject command in Disk Utility or Disk Copy, or by using this command in Terminal:

	$ hdiutil detach /dev/disk1

using the same device name that was returned by the hdiutil attach command (/dev/disk1 in this example).

For more information on filter schemes, see the Reference Library document Writing Drivers for Mass Storage Devices at <http://developer.apple.com/documentation/DeviceDrivers/Conceptual/MassStorage/index.html>.

Notes on building this project:

This project is configured to build a universal binary. 

The PowerPC side of the KEXT is built using the Mac OS X 10.2.8 SDK and gcc version 3.3. This allows this driver to load and run on PowerPC-based Macintosh computers running Mac OS X 10.2 or later. 

The Intel side of the KEXT is built using the Mac OS X 10.4 Universal SDK and gcc version 4.0. This allows this driver to load and run on Intel-based Macintosh computers running Mac OS X 10.4.3 or later.

The above is accomplished using per-architecture build settings supported in Xcode 2.2 and later. 

To convert a PowerPC-only Xcode 2.2 I/O Kit driver project to a universal project, make the following changes to the Project or Target Build settings. (Modify the Project settings if you want the settings to apply to all targets in the project, or the Target settings if you want just a particular target to produce a universal KEXT.) 

1. Set Architectures to "ppc i386".

2. Remove any setting for SDK Path.

3. Add the custom settings SDKROOT_i386 and SDKROOT_ppc. Set the value of each to the path of the SDK to use to build on each architecture. Normally SDKROOT_i386 will be set to /Developer/SDKs/MacOSX10.4u.sdk and SDKROOT_ppc will point to the SDK matching the oldest major Mac OS X release you wish to support.

4. Add the settings GCC_VERSION_i386 and GCC_VERSION_ppc that specify the compiler version to use when building for each architecture. GCC_VERSION_i386 must be set to 4.0 or greater. If you want to support versions of Mac OS X prior to 10.4, GCC_VERSION_ppc must be set to 3.3.

5. Set Mac OS X Deployment Target to Compiler Default.

6. Add the settings MACOSX_DEPLOYMENT_TARGET_i386 and MACOSX_DEPLOYMENT_TARGET_ppc. These settings must have the value of a major Mac OS X release version number such as 10.2 or 10.4. Do not specify software update versions such as 10.3.9. MACOSX_DEPLOYMENT_TARGET_i386 must be set to 10.4 or later, and MACOSX_DEPLOYMENT_TARGET_ppc should be set to the oldest major Mac OS X release you wish to support.

Version: 1.0
01/22/2002

- New sample.

Version: 1.1 
03/03/2005

- Updated hdiutil instructions for 10.3 and later.
- Added support for filtering the boot volume.

Version: 1.2
11/01/2005	

- Updated to produce a universal binary.
- Now requires Xcode 2.2 or later to build.
