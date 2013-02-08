====================================
Contact
====================================
For more information and/or to provide feedback, contact CoreWLAN-Feedback@group.apple.com

====================================
Requirements
====================================
Minimum compilation environment - Xcode3.2 and Mac OS X 10.6
Minimum runtime environment - Mac OS X 10.6

====================================
CoreWLAN Framework
====================================
* Description:
Objective-C, public API for the Mac OS X IEEE 802.11 wireless interface.  The framework provides developers with a means to query and change the parameters of a given interface, scan for networks, access related system preferences, associate to networks, and create computer-to-computer networks. 
* This framework supports Objective-C garbage collection.  
* This framework is not daemon-safe.
* This framework is not thread-safe.
* Location:
/System/Library/Frameworks/CoreWLAN.framework

====================================
CoreWLANWirelessManager
====================================
* Description:
An example Cocoa application which utilizes the CoreWLAN Framework.

* Interface Popup Button:
The app supports a multiple interface scenario, whereby the machine could have several IEEE 802.11 wireless interfaces.  The popup button on the top left corner of the app allows the user to select which interface should be set as the current interface.  By default, the popup button will select the primary WLAN interface for the system.

* Refresh Button:
In the top right corner of the app, there is a push button entitled "Refresh".  This button provides different functionality depending on which tab is currently selected.  If the Interface Info or Configuration tabs are selected, the button will refresh the information display in the currently selected tab.  If the Scan tab is selected, the button will start a broadcast scan and block until the scan has completed.

* Interface Info Tab:
The tab entitled "Interface Info" contains information describing the static and dynamic state of the currently selected interface.  Additionally, it allows the user to toggle interface power, disconnect from the current network, and change channels.  

You will notice that you will not be able to change channels while connected to a network--this is by design.  Attempting to do this would return a error.  Furthermore, you will notice that when the interface is powered OFF, all the dynamic status information is cleared.

* Scan Tab:
The tab entitled "Scan" allows the user to scan for networks using the current interface.  The scan results are shown in the table view and are automatically ordered by network name.  For each network, there is several pieces of information displayed in the table row that describe that particular network.  

There is a button in the checkbox left corner of the Scan tab which sets/unsets the parameter to merge the scan result with the same SSID.  

And, there is a button in the bottom right corner of the Scan tab which allows the user to join the currently selected network in the table.  A sheet will be presented upon clicking the Join button that will allow the user to provide the appropriate credentials for the given network.
