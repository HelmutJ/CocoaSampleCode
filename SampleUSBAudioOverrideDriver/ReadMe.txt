SampleUSBAudioOverrideDriver

This project is a codeless kext that allows it to override certain properties of the USB audio device. There is only a plist file and localized strings. To specify a specific audio device for this sample code project to use, you will need to modify the project's Info.plist file. Modify the Info.plist entry IOPropertyMatch to match to the hex values of the idVendor and idProduct of your device. Also modify bInterfaceNumber and bConfigurationValue to match to the USB interfaces.

You can discover these values by using developer applications like IORegistryExplorer or USBProber.

Here are list of properties that you might want to change/add:

(a) USB Product Name
- Specified on the USB device (IOUSBDevice). This name is used as the device name (IOAudioDevice::setDeviceName) when the control interface doesn't have a name (USB Interface Name).

(b) USB Interface Name
- Specified at the USB interface (IOUSBInterface) . This control interface name is used as the device name if present, and take precedence over USB Product Name. The stream interface name is used as the engine description (IOAudioEngine::setDescription) when present.

(c) IOAudioDeviceLocalizedBundle
- Can be specified at the control interface or USB device. The localized bundle specified at the control interface take precedence over the one at USB device level. The localization bundle has the localized string for the USB Product Name/USB Interface Names.

(d) IOAudioEngineCoreAudioPlugIn
- Specified at the stream interface level. This is a string specifying the path to the CoreAudio plugin. 

(e) IOAudioEngineSampleOffset, IOAudioEngineInputSampleOffset, IOAudioEngineInputSampleLatency, IOAudioEngineOutputSampleLatency.
- Specified at the stream interface level. These values will override the ones that the AppleUSBAudio calculate based on the sample rate.

(f) idProduct and idVendor
- Change this to match your USB audio device.

(g) bInterfaceNumber and bConfigurationValue
- Change this to match the your USB  audio streaming/control interfaces.

The target produces SampleUSBAudioOverrideDriver.kext which must be copied to the /System/Library/Extensions folder of the boot volume by an administrator using a command like (from the project folder):

sudo cp -rf ./build/SampleUSBAudioOverrideDriver.kext /System/Library/Extensions

Your override kext must have the correct ownership (root , wheel):

sudo chown -R root:wheel SampleUSBAudioOverrideDriver.kext/

Then you must notify the operating system that the contents of the kernel extension directory has changed by "touching the directory":

sudo touch /System/Library/Extensions

Restart the system.
 
After restarting the system, the override kext should automatically load when the device specified in the Info.plist (accessible from the Targets->SampleUSBAudioOverrideDriver ->Get Info -> Properties) is attached. The specified properties will be merged into the USB device & interfaces.