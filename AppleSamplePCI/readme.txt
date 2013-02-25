AppleSamplePCI is a simple driver example that shows how to build a single deliverable that will function on all Macintosh systems from Mac OS X 10.4 through Snow Leopard. It matches on the IOPCIFamily, specifically on the graphics card(s) found in all Macintosh computers.

It demonstrates the use of I/O Registry Properties to set and retrieve settings properties to your driver. Additionally, it shows how to handle PowerPC applications running on Intel-based systems calling your driver using Rosetta. Finally, it addresses the new 64-bit kernel (K64) world by demonstrating which APIs to use on Leopard and beyond.

The sample produces two kexts and a test tool. One kext targets the i386 and ppc architectures for Mac OS X 10.4 only. This is where you'll encounter the most differences between architectures.

The second kext targets i386 and ppc on Leopard and later, and x86_64 (K64) on Snow Leopard.

During the build process, the first kext is copied into the Contents/PlugIns directory of the second kext. This shows how a single kext bundle can be shipped which contains related sub-kexts. The kext loading daemon (kextd) searches one level deep inside kext bundles for sub-kexts.

The test tool is built four-way universal for i386, x86_64, ppc, and ppc64 architectures. The 64-bit architectures are supported only on Leopard and beyond as that is where user client support for 64-bit processes was added.

The project also builds the test tool as four separate single-architecture binaries. This is only to make it easier to test running binaries for specific architectures to see the results.