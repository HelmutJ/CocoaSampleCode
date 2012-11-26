
ROT13AuthPlugin
---------------

Overview: This is a very simple example of plugin for the Authorization
API that shows the most basic way to write a plugin. This plugin will
read the password that the user typed in and perform a ROT13 on it. The
password is read from the HINTS.

Warning: You should determine what the ROT13 of your password is before
making these changes. Failure to do so may require you to boot the
system into single user mode.

Use:

1.	Compile the project
2.	Copy the resulting bundle to the auth plugins directory:

	sudo cp -R $BUILDDIR/rot13.bundle /Library/Security/SecurityAgentPlugins
	
3.	Make a copy of the existing /etc/authorization file:

	sudo cp /etc/authorization /etc/authorization-orig
	
4.	Add a line to /etc/authorization to call the bundle. To do this
	for testing, use your favorite editor, e.g.

		sudo pico /etc/authorization
		
	then look for "system.login.console". A few lines below this key,
	you can add the line:
	
		<key>mechanisms</key>
		<array>
				<string>builtin:smartcard-sniffer,privileged</string>
				<string>loginwindow:login</string>
				<string>builtin:reset-password,privileged</string>
+				<string>rot13:rot13</string>
				<string>builtin:auto-login,privileged</string>
				<string>builtin:authenticate,privileged</string>
				<string>loginwindow:success</string>
				...
				
	The new line is marked with a "+" (don't include the "+" sign in the
	file, though). The first occurence of "rot13" is the bundle name,
	the second is the mechanism ID. See the code in "mechanismCreate"
	for where this is used.

5.	If you have fast user switching enabled, you can quickly see
	the results by selecting a different user from the user menu.

Note: The preferred way to modify the /etc/authorization file is to use
the Authorization APIs in <Security/AuthorizationDB.h>. This is always
how it should be done in shipping products, as there may have been other
modifications to the /etc/authorization file. A code snippet to do this
is:

#include <CoreFoundation/CoreFoundation.h>
#include <Security/AuthorizationDB.h>

#define LOGIN_RIGHT "system.login.console"

int main(int argc, char *argv[])
{
    CFDictionaryRef login_dict;
    OSStatus status;
    AuthorizationRef authRef;

    status = AuthorizationCreate(NULL, NULL, 0, &authRef);
    if (status) exit(1);

    status = AuthorizationRightGet(LOGIN_RIGHT, &login_dict);
    if (status) exit(1);

    CFArrayRef arrayRef;
    if (!CFDictionaryGetValueIfPresent(login_dict, CFSTR("mechanisms"),
    	&arrayRef))
        exit(1);

    CFMutableArrayRef newMechanisms = CFArrayCreateMutableCopy(NULL, 0,
    	arrayRef);
    if (!newMechanisms)
        exit(1);

    CFIndex index = CFArrayGetFirstIndexOfValue(newMechanisms,
    	CFRangeMake(0, CFArrayGetCount(newMechanisms)), CFSTR("authinternal"));

    if (index == -1)
        exit(1);

    CFArraySetValueAtIndex(newMechanisms, index, CFSTR("newmech"));

    CFMutableDictionaryRef new_login_dict 
    	= CFDictionaryCreateMutableCopy(NULL, 0, login_dict);

    CFDictionarySetValue(new_login_dict, CFSTR("mechanisms"), newMechanisms);

    status = AuthorizationRightSet(authRef, LOGIN_RIGHT, new_login_dict,
    	NULL, NULL, NULL);

    if (status) exit(1);
}
