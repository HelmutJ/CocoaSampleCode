/*
 
  File:gssclient.c
 
  Abstract: Sample GSS-API server.
 
  Version: 1.0
 
  Disclaimer: IMPORTANT:  This Apple software is supplied to you by 
  Apple Inc. ("Apple") in consideration of your agreement to the
  following terms, and your use, installation, modification or
  redistribution of this Apple software constitutes acceptance of these
  terms.  If you do not agree with these terms, please do not use,
  install, modify or redistribute this Apple software.
 
  In consideration of your agreement to abide by the following terms, and
  subject to these terms, Apple grants you a personal, non-exclusive
  license, under Apple's copyrights in this original Apple software (the
  "Apple Software"), to use, reproduce, modify and redistribute the Apple
  Software, with or without modifications, in source and/or binary forms;
  provided that if you redistribute the Apple Software in its entirety and
  without modifications, you must retain this notice and the following
  text and disclaimers in all such redistributions of the Apple Software. 
  Neither the name, trademarks, service marks or logos of Apple Inc. 
  may be used to endorse or promote products derived from the Apple
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
 
  Copyright (C) 2008 Apple Inc. All Rights Reserved.
 
*/ 
#include <sys/types.h>
#include <sys/socket.h>

#include <gssapi.h>
#include <err.h>
#include <netdb.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>

#include "common.h"

extern int optind;
extern char *optarg;

/*
 * Listen to a IPv6 socket and get the v4 connection for free using
 * mapped adresses.
 */

static int
listenSocket(const char *port)
{
    struct sockaddr_in6 sa;
    struct servent * se;
    int res, fd;

    memset(&sa, 0, sizeof(sa));
    sa.sin6_family = AF_INET6;
    
    se = getservbyname(port, "tcp");
    if (se) {
        sa.sin6_port = se->s_port;
    } else {
        sa.sin6_port = htons(atoi(port));
        if (sa.sin6_port == 0)
            errx(1, "unknown port %s", port);
    }

    fd = socket(PF_INET6, SOCK_STREAM, 0);
    if (fd < 0)
        errx(1, "Failed to create a socket");

    /* Allow socket reuse so we don't have to wait between runs */
    {
        int one = 1;
        setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, (void *)&one, sizeof(one));
    }
    
    res = bind(fd, (struct sockaddr *)&sa, sizeof(sa));
    if (res < 0)
        errx(1, "Failed to bind");

    listen(fd, 5);

    return fd;
}

static void
usage(int exit_code)
{
    printf("usage: gssserver [-p port]");

    exit(exit_code);
}


int
main(int argc, char **argv)
{
    OM_uint32 major_status, minor_status, junk, ret_flags;
    gss_buffer_desc inbuffer, outbuffer;
    int sock, fd, ch;
    gss_name_t srcname, targetname;
    gss_cred_id_t cred = GSS_C_NO_CREDENTIAL;
    gss_ctx_id_t ctx;
    const char *port = "4711";
    char *str, *servicename = NULL;

    while ((ch = getopt(argc, argv, "p:s:")) != -1) {
        switch (ch) {
        case 'p':
            port = optarg;
            break;
        case 's':
            servicename = optarg;
            break;
        case '?':
        default:
            usage(0);
        }
    }

     
    /*
     * If an optional service name was specified, used it to find a
     * credential.
     *
     * GSS-API Hostbased service names are on the form
     * service@host.domain.  The corresponding Kerberos name is
     * service/host.domain@REALM, where Kerberos realm is derived from
     * the hostname.
     */
     
    if (servicename) {
        gss_buffer_desc namebuffer;
         
        namebuffer.value = servicename;
        namebuffer.length = strlen(servicename);
         
        major_status = gss_import_name(&minor_status, &namebuffer,
                                       GSS_C_NT_HOSTBASED_SERVICE,
                                       &targetname);
        if (major_status != GSS_S_COMPLETE)
            gss_err(1, major_status, minor_status, "gss_import_name");
         
        print_name("service using name", targetname);

        major_status = gss_acquire_cred(&minor_status,
                                        targetname,
                                        GSS_C_INDEFINITE,
                                        GSS_C_NO_OID_SET,
                                        GSS_C_ACCEPT,
                                        &cred,
                                        NULL,
                                        NULL);
        if (major_status != GSS_S_COMPLETE)
            gss_err(1, major_status, minor_status, "gss_acquire_cred");
         
        gss_release_name(&minor_status, &targetname);
    }


    /*
     * Setup listen()ing sockets, both IPv4 and and IPv6 if available.
     */

    fd = listenSocket(port);

    /*
     * Wait for client to connect
     */

    sock = accept(fd, NULL, NULL);
    if(sock < 0)
        err (1, "accept");

    /*
     * Close the listen() sockets.
     */

    close(fd);

    /*
     * Do the GSS-API context buildin loop.
     */

    ctx = GSS_C_NO_CONTEXT;
    outbuffer.value = NULL;
    outbuffer.length = 0;

    /*
     * If we are hardcoding our name in the configuration of the
     * server, we could get the server credential using
     * gss_acquire_cred(). If if there are several alias for the same
     * that the client might use, then its better to pass ing
     * GSS_C_NO_CREDENTIAL and check after the context is built that
     * name was used to authenticate the service.
     */

    do {
        /* Get message from the client */
        recv_token(sock, &inbuffer);

        /*
         * Process the client message
         */

        major_status = gss_accept_sec_context(&minor_status,
                                              &ctx,
                                              cred,
                                              &inbuffer,
                                              GSS_C_NO_CHANNEL_BINDINGS,
                                              &srcname,
                                              NULL,
                                              &outbuffer,
                                              &ret_flags,
                                              NULL,
                                              NULL);
        /*
         * Even in case of an error, send output buffer if there is one
         * there might be a hint to the client why the transaction failed (time
         * out of sync, etc)
         */
        if (outbuffer.length)
            send_token(sock, &outbuffer);
        gss_release_buffer(&junk, &outbuffer);

        if (inbuffer.value) {
            free(inbuffer.value);
            inbuffer.value = NULL;
            inbuffer.length = 0;
        }

        /*
         * In case of an error in the context building, fail here
         */

        if (GSS_ERROR(major_status)) {
            gss_delete_sec_context(&junk, &ctx, NULL);
            gss_err (1, major_status, minor_status, "gss_accept_sec_context");
        }

    } while(major_status & GSS_S_CONTINUE_NEEDED);
    
    if (major_status != GSS_S_COMPLETE)
        gss_err (1, major_status, minor_status, "gss_accept_sec_context");
  
    if ((ret_flags & GSS_C_CONF_FLAG) == 0)
        errx(1, "Context is missing confidentiality");
    if ((ret_flags & GSS_C_INTEG_FLAG) == 0)
        errx(1, "Context is missing integrity");

    /*
     * Print the client name we got from the context.
     */

    print_name("client name:", srcname);

    /*
     * Get and print the server name, since we didn't specified a
     * credential as the input of function we should check the name is
     * what we expected. This is since the keytab might be shared
     * between diffrent services on the same machine, and we don't
     * want to allow other services then our own to use that name.
     */

    major_status = gss_inquire_context(&minor_status,
                                       ctx,
                                       NULL,
                                       &targetname,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL);
    if (major_status != GSS_S_COMPLETE)
        gss_err(1, major_status, minor_status, "gss_inquire_context");
                                       
    print_name("server name:", targetname);

    /* Free names */

    gss_release_name(&minor_status, &srcname);
    gss_release_name(&minor_status, &targetname);

    /*
     * Receive message from the client.
     */

    printf("waiting for a message\n");
    recv_message(ctx, sock, &str);
    printf("got a message: %s\n", str);

    /*
     * Send responce back to the client
     */

    printf("sending a message\n");
    send_message(ctx, sock, "Hello client");

    /*
     * Release context
     */

    printf("releasing context\n");
    gss_delete_sec_context(&junk, &ctx, NULL);

    /*
     * Close socket to the client
     */

    close(sock);

    return 0;
}
