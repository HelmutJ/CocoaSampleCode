AudioDriverExamples

This project has two examples of writing user land audio drivers that conform to the plug-in API in
<CoreAudio/AudioServerPlugIn.h>. Each example is documented with commentary inline with the code.

The first example, NullAudio, creates a driver that supports single audio device. Written in C, this
example shows what it takes to write a drive that achieves the bare minimum of support while still
being fully functional as an AudioDevice.

The second example, SimpleAudio, is a more functional driver. Written in C++, this driver is written
for a dynamic environment where it has to support potentially many instances of the same device 
getting plugged into the system. This example also shows how a user-land driver interacts with
hardware that requires a kernel extension to talk to. As such, it shows dealing with IOKit matching
notifications as well as dealing with calls into the IOKit driver.
