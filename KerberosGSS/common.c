/*

  File:common.c

  Abstract: GSS-API and data transport functions shared between the sample
  client and the server.

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

#include <gssapi.h>
#include <err.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdarg.h>
#include <limits.h>
#include <unistd.h>

#include "common.h"

/*
 * Send data to the peer, wait until all data is sent.
 */

static void
send_data(int fd, const void *data, size_t len)
{
    ssize_t c;

    while (len) {
        c = write(fd, data, len);
        if (c < 0)
            err(1, "Failed writing data");
        else if (c == 0)
            err(1, "Connection closed by peer");
        len -= c;
        data = ((const char *)data) + c;
    }
}

/*
 * Receive data from peer, wait until len amount of data is received.
 */

static void
recv_data(int fd, void *data, size_t len)
{
    ssize_t c;

    while (len) {
        c = read(fd, data, len);
        if (c < 0)
            err(1, "Failed reading data from peer");
        else if (c == 0)
            errx(1, "Connection closed by peer");
        len -= c;
        data = ((char *)data) + c;
    }
}

/*
 * Send a formated token to the peer, first is a length, 32 bit
 * unsigned number and then the data it-self.
 */

void
send_token(int fd, gss_buffer_t buffer)
{
    uint32_t length = htonl(buffer->length);
    send_data(fd, &length, sizeof(length));
    send_data(fd, buffer->value, buffer->length);
}

/*
 * Receive a formated token to the peer, format is described in send_token.
 */

void
recv_token(int fd, gss_buffer_t buffer)
{
    uint32_t length;
  
    recv_data(fd, &length, sizeof(length));
    length = ntohl(length);

    /*
     * Check that the message length is sane.
     */

    if (length > INT_MAX || length == 0)
        errx(1, "Incoming message malformed length");

    buffer->length = length;
    buffer->value = malloc(length);
    if (buffer->value == NULL && length != 0)
        err(1, "malloc: %lu bytes", (unsigned long)length);
    recv_data(fd, buffer->value, buffer->length);
}

/*
 * Send a gss_wraped token the client. Make the message
 * confidentiality protected in addition to the default integrity
 * protection.
 */

void
send_message(gss_ctx_id_t ctx, int fd, const char *msg)
{
    OM_uint32 major_status, minor_status, junk;
    gss_buffer_desc inbuffer, outbuffer;
    int conf_req;

    inbuffer.value = strdup(msg);
    if (inbuffer.value == NULL)
        errx(1, "out of memory");
    inbuffer.length = strlen(msg);
      
    major_status = gss_wrap(&minor_status, ctx, 1 /* request conf */,
                            GSS_C_QOP_DEFAULT,
                            &inbuffer, &conf_req, &outbuffer);
    free(inbuffer.value);
    if (major_status)
        gss_err(1, major_status, minor_status, "gss_wrap");
    if (!conf_req)
        errx(1, "Message out was without confidentiality protection "
             "but confidentiality was requested");
  
    send_token(fd, &outbuffer);
    gss_release_buffer(&junk, &outbuffer);
}

/*
 * Receive and print a gss_wrap()ed message the client. Make sure it
 * confidentiality protected.
 */


void
recv_message(gss_ctx_id_t ctx, int fd, char **msg)
{
    OM_uint32 major_status, minor_status, junk;
    gss_buffer_desc inbuffer, outbuffer;
    int conf_req;

    recv_token(fd, &inbuffer);
    major_status = gss_unwrap(&minor_status, ctx, &inbuffer,
                              &outbuffer, &conf_req, NULL);

    free(inbuffer.value);
    if (major_status)
        gss_err(1, major_status, minor_status, "gss_unwrap");
    if (!conf_req)
        errx(1, "Message without confidentiality protection");

    asprintf(msg, "%.*s", (int)outbuffer.length, (char *)outbuffer.value);
    gss_release_buffer(&junk, &outbuffer);
}

/*
 * Print the name GSS-API name
 */

void
print_name(const char *str, gss_name_t name)
{
    OM_uint32 major_status, minor_status;
    gss_buffer_desc buffer;
    gss_OID nametype;
    
    major_status = gss_display_name(&minor_status, 
                                    name,
                                    &buffer,
                                    &nametype);
    if (major_status != GSS_S_COMPLETE)
        gss_err (1, major_status, minor_status, "gss_display_name");

    printf("%s %.*s\n", str, (int)buffer.length, (char *)buffer.value);

    gss_release_buffer(&minor_status, &buffer);
    /* Doesn't need to free nametype, its a static variable */
}

/*
 *
 */

void
gss_err (int exit_code,
         OM_uint32 maj_stat, OM_uint32 min_stat, 
         const char *fmt, ...)
{
    OM_uint32 maj_junk, min_junk, msg_ctx;
    gss_buffer_desc status_string;
    va_list args;

    va_start(args, fmt);
    vprintf (fmt, args);
    va_end(args);

    printf("\n");

    msg_ctx = 0;
    do {
        maj_junk = gss_display_status (&min_junk,
                                       min_stat,
                                       GSS_C_GSS_CODE,
                                       GSS_C_NO_OID,
                                       &msg_ctx,
                                       &status_string);
        if (!GSS_ERROR(maj_junk)) {
            fprintf (stderr, "major: %.*s\n", (int)status_string.length, 
                     (char *)status_string.value);
            gss_release_buffer (&min_junk, &status_string);
        }
    } while (msg_ctx != 0);

    msg_ctx = 0;
    do {
        maj_junk = gss_display_status (&min_junk,
                                       min_stat,
                                       GSS_C_MECH_CODE,
                                       GSS_C_NO_OID,
                                       &msg_ctx,
                                       &status_string);
        if (!GSS_ERROR(maj_junk)) {
            fprintf (stderr, "minor: %.*s\n", (int)status_string.length, 
                     (char *)status_string.value);
            gss_release_buffer (&min_junk, &status_string);
        }
    } while (msg_ctx != 0);

    exit(exit_code);
}
