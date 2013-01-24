Read Me About DNSSDObjects
==========================
1.1

DNSSDObjects shows how to integrate the DNS-SD API into Cocoa code.  The techniques it shows are useful when the existing high-level Bonjour APIs (NSNetService and CFNetService) don't provide enough flexibility to meet your needs.  For example, the high-level Bonjour APIs always register and browse on all network interfaces; if you want to browse or register on a specific interface, you have to use the DNS-SD API, and this sample will make that transition easier.

DNSSDObjects requires Mac OS X 10.7 or later.  The core code should also work on iOS 4.0 or later.

Packing List
------------
The sample contains the following items:

o Read Me About DNSSDObjects.txt -- This file.

o DNSSDObjects.xcodeproj -- An Xcode project for the sample.

o DNSSDObjects -- A directory containing all the code.

o build -- A directory containing a pre-built binary.

Within the DNSSDObjects directory you'll find the following:

o main.m -- Source for a small command line program that exercises the semi-reusable code.

o DNSSDRegistration.[hm] -- A class for registering a Bonjour service.

o DNSSDBrowser.[hm] -- A class for browsing for Bonjour services.

o DNSSDService.[hm] -- A class that represents a found Bonjour service.

Using the Sample
----------------
To register a service, run the program with the "-r" argument and supply it with the service type and port:

$ build/Debug/DNSSDObjects -r _foo._tcp 12345
[...] will register
[...] registered as 'Bruno'

To browse for services, run the program with the "-b" option and the type:

$ build/Debug/DNSSDObjects -b _foo._tcp
[...] will browse
[...]    add service 'Bruno' / '_foo._tcp.' / 'local.'
^C

Once you've found a service, you can resolve it by passing in the "-l" (lookup) option:

$ build/Debug/DNSSDObjects -l 'Bruno' '_foo._tcp' 'local.'
[...] will resolve
[...] did resolve to Bruno.local.:12345
[...] stopped

Building the Sample
-------------------
The sample was built using Xcode 4.2 on Mac OS X 10.7.2 with the Mac OS X 10.7 SDK.  You should be able to just open the project and choose Build from the Product menu.

How it Works
------------
The sample consists of three semi-reusable classes and one file containing the code for a small command line program that lets you exercise these classes.  Each of the semi-reusable classes represents a fundamental Bonjour option:

o DNSSDRegistration for service registration

o DNSSDBrowser for service browsing

o DNSSDService for service resolution

Each of these classes are implemented in the most obvious way.  They pass the default values to most of their parameters, they support very little customization, they run their delegate callbacks on the main thread, and so on.  The goal here is to provide a simple base that you can then customize to meet your needs.

The semi-reusable classes use DNSServiceSetDispatchQueue (the modern, preferred API) to run their callbacks on the main queue, and hence the main thread.  If you need the callbacks to run in some other context, you can change this code to meet your needs.  For example:

o If you want the callbacks to run on a specific dispatch queue, you can change the queue passed to DNSServiceSetDispatchQueue.  Remember that this must be a serial queue.

o If you want the callbacks to run on a specific run loop, you can use DNSServiceRefSockFD to get the DNS-SD socket, wrap that in a CFSocket, and then schedule the CFSocket on the run loop.  The SRVResolver sample code shows an example of this.

<http://developer.apple.com/library/mac/#samplecode/SRVResolver/>

Caveats
-------
The semi-reusable classes support only the basic set of Bonjour features.  If you need support for anything more advanced, you will have to customize these classes.  The things you might want to customize include:

o operating on a specific interface

o enabling support for Bluetooth browsing on iOS 5.0 and later (kDNSServiceFlagsIncludeP2P)

o supporting TXT records

o monitoring record changes

o discovering browsable domains, and browsing within those domains

o resolving to IP addresses

o registering or querying for arbitrary DNS records

o shared connections (kDNSServiceFlagsShareConnection)

Credits and Version History
---------------------------
If you find any problems with this sample, please file a bug against it.

<http://developer.apple.com/bugreporter/>

1.0 (Dec 2011) was the first shipping version.

1.1 (Dec 2011) fixes a bug that disabled auto-rename for service registration objects.

Share and Enjoy

Apple Developer Technical Support
Core OS/Hardware

13 Dec 2011
