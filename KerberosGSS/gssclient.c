/*

  File:gssclient.c

  Abstract: Sample GSS-API client.

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
#include <unistd.h>

#include "common.h"

extern int optind;
extern char *optarg;


/*
 * Connect to the server `hostname' on `port'. Returns a socket.  In
 * case of failure and error will be printed and exit() called.
 */

static int
connectHost(const char *hostname, const char *port)
{
    struct addrinfo hints, *ai0, *ai;
    int fd, res;

    memset(&hints, 0, sizeof(hints));

    hints.ai_family = PF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;

    res = getaddrinfo(hostname, port, &hints, &ai0);
    if (res != 0)
        errx(1, "getaddrinfo");
    
    for (ai = ai0; ai != NULL; ai = ai->ai_next) {

        fd = socket(ai->ai_family, SOCK_STREAM, 0);
        if (fd < 0)
            continue;

        res = connect(fd, ai->ai_addr, ai->ai_addrlen);
        if (res) {
            close(fd);
            continue;
        }

        return fd;
    }
    errx(1, "failed to connect to host %s:%s", hostname, port);
}

static void
usage(int exit_code)
{
    printf("usage: gssclient [-s service] [-p port] server-name");

    exit(exit_code);
}


/*
 * Connect to the server, do a GSS-API context build loop and send and
 * receive some messages.
 */

int
main(int argc, char **argv)
{
    const char *server;
    OM_uint32 major_status, minor_status, junk, ret_flags;
    gss_buffer_desc namebuffer;
    gss_buffer_desc inbuffer, outbuffer;
    gss_name_t aname;
    gss_ctx_id_t ctx;
    char *str, *port = "4711";
    int fd, ch;
    const char *service = "host";

     while ((ch = getopt(argc, argv, "s:p:")) != -1) {
         switch (ch) {
         case 's':
             service = optarg;
             break;
         case 'p':
             port = optarg;
             break;
         case '?':
         default:
             usage(0);
         }
     }
     argc -= optind;
     argv += optind;

    if (argc < 1)
        usage(1);

    server = argv[0];

    fd = connectHost(server, port);

    printf("connected to %s\n", server);

    /*
     * Build a GSS-API host service name (service@hostname) and pass
     * it into gss_import_name().
     */

    asprintf(&str, "%s@%s", service, server);
    namebuffer.value = str;
    namebuffer.length = strlen(str);
    
    major_status = gss_import_name(&minor_status, &namebuffer,
                                   GSS_C_NT_HOSTBASED_SERVICE, &aname);
    if (major_status != GSS_S_COMPLETE)
        gss_err(1, major_status, minor_status, "gss_import_name");
    
    free(str);

    /*
     * Do the GSS-API context building loop continue will
     * GSS_S_CONTINUE_NEEDED is set and no error is returned. When
     * done GSS_S_COMPLETE is returned.
     */

    ctx = GSS_C_NO_CONTEXT;
    inbuffer.value = NULL;
    inbuffer.length = 0;
    
    do {

        outbuffer.value = NULL;
        outbuffer.length = 0;

        major_status = gss_init_sec_context(&minor_status,
                                            GSS_C_NO_CREDENTIAL, // use default credential
                                            &ctx,
                                            aname,
                                            GSS_C_NO_OID,
                                            GSS_C_MUTUAL_FLAG|GSS_C_REPLAY_FLAG|
                                            GSS_C_CONF_FLAG|GSS_C_INTEG_FLAG,
                                            GSS_C_INDEFINITE,
                                            GSS_C_NO_CHANNEL_BINDINGS,
                                            &inbuffer,
                                            NULL, // Don't really care about actual mechanism used
                                            &outbuffer,
                                            &ret_flags,
                                            NULL);
        /*
         * Even in case of an error, if there is an output token, send
         * it off to the server. The mechanism might want to tell the
         * acceptor why it failed.
         */
        if (outbuffer.value) {
            send_token(fd, &outbuffer);
            gss_release_buffer(&junk, &outbuffer);
        }

        /*
         * Don't use gss_release_buffer since inbuffer is
         * allocated locally.
         */
        if (inbuffer.value) {
            free(inbuffer.value);
            inbuffer.value = NULL;
            inbuffer.length = 0;
        }

        /* In case of error, print error and fail */
        if (GSS_ERROR(major_status)) {
            gss_delete_sec_context(&junk, &ctx, NULL);
            gss_err(1, major_status, minor_status, "gss_init_sec_context");
        }

        /* If we are not done yet, wait for another token from the server */
        if (major_status & GSS_S_CONTINUE_NEEDED)
            recv_token(fd, &inbuffer);
      
    } while (major_status != GSS_S_COMPLETE);
           
    /* If there was a failure building the context, fail */
    if (major_status != GSS_S_COMPLETE)
        err (1, "gss_accept_sec_context");

    /*
     * check that context flags are what we expect them to be, with
     * confidentiality and integrity protected
     */
    if ((ret_flags & GSS_C_CONF_FLAG) == 0)
        errx(1, "confidentiality missing from context");
    if ((ret_flags & GSS_C_INTEG_FLAG) == 0)
        errx(1, "integrity missing from context");

    printf("context built\n");

    /*
     * Send message to server
     */
    printf("sending message\n");
    send_message(ctx, fd, "hello to you server");

    /*
     * Receive message from server
     */

    printf("waiting for message\n");
    recv_message(ctx, fd, &str);
    printf("got message: %s\n", str);
    free(str);

    /*
     * All done, release context
     */

    printf("release context\n");
    gss_delete_sec_context(&junk, &ctx, NULL);

    /*
     * Close connetion to server
     */

    close(fd);

    return 0;
}
