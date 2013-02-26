
Sample GSS-API client and server. Negotiates a security context and
send some integrity and confidentiality protected messages between the
client and the server. The sample is independent of security
mechanism, but commonly Kerberos is used.

This project was built on Mac OS X version 10.5.3 with Xcode version
3.0 and depends on the Kerberos framework.

The example assumes an managed Kerberos enviroment.

- Build the project with command line tool "xcodebuild" in the source
  directory or using Xcode.

- Setup a KDC or use an existing Kerberos realm.

- Get a keytab from the administrator of the Kerberos realm.

  The service should have the FQDN (fully qualified domain name) that
  is the samme as the machines hostname since this simplifies Kerberos
  domain to realm mapping.

  The GSS service name is host@fqdn. In the example below the kerberos
  principal is "host/server.realm.apple.com" the GSS-API name of the
  server "host@server.realm.apple.com" (hostbased name).

- The server is started with "./gssserver" and will exit when done. On
  success the error is zero, on failure the error is non zero.
  The server print the client principal name, and the messages.

- The client is started with "./gssclient servername.domain.name".
  On success the return code is zero, on failure non zero.
  The client prints out the message exchanged in the session.

- Sample output

# ./build/Release/gssserver 
client is: user@REALM.APPLE.COM
server name: host@server.realm.apple.com
waiting for a message
got a message: hello to you server
sending a message
releasing context
#



$ ./build/Release/gssclient server.realm.apple.com
connected to server.realm.apple.com
context built
sending message
waiting for message
got message: foo
release context
$
