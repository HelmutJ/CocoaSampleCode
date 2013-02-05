/*
     File: zip_service.c 
 Abstract: XPC service that compress a file using zlib.
  Version: 1.0

 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.

 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.

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

 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 */

#include <asl.h>
#include <assert.h>
#include <errno.h>
#include <stdio.h>
#include <zlib.h>

#include <xpc/xpc.h>

#include <fcntl.h>

#define ZIP_BUF_SIZE	16384

// Given an input and output file, compress the input into the output using
// the gzip algorithm (using given compression level and strategy).
//
// Return Z_OK on success.  Otherwise return a zlib error.
static int
zip_compress_file(int infd, int outfd, int level, int strategy, 
                  const char **errmsg)
{
    int err = Z_OK;
    int len;
    uint8_t *buf = NULL;
    gzFile gzoutfp = NULL;
    char mode[5] = "wb  ";

    // Build mode argument for gzdopen().
    if (level < 1 || level > 9)
	    level = 6;
    mode[2] = '0' + level;
    switch (strategy) {
    case Z_FILTERED:
	    mode[3] = 'f';
	    break;
    case Z_HUFFMAN_ONLY:
	    mode[3] = 'h';
	    break;
    case Z_RLE:
	    mode[3] = 'R';
	    break;
    case Z_FIXED:
	    mode[3] = 'F';
	    break;
    default:
	    mode[3] = '\0';
	    break;
    }

    if ((buf = (uint8_t *)malloc(ZIP_BUF_SIZE)) == NULL) {
        err = Z_MEM_ERROR;
        if (errmsg)
            *errmsg = "Out of memory";
        goto errout;
    }
    // Use zlib gzip wrapper functions to do the compression.
    if ((gzoutfp = gzdopen(outfd, mode)) == NULL) {
	    err = Z_ERRNO;
	    if (errmsg)
		    *errmsg = "Can't not gzdopen() output file";
	    goto errout;
    }

    while(1) {
	    if ((len = (int)read(infd, buf, ZIP_BUF_SIZE)) < 0) {
		    err = Z_ERRNO;
            if (errmsg)
                *errmsg = "Can't read input";
		    goto errout;
	    }

	    if (0 == len)
		    break;

	    if (gzwrite(gzoutfp, buf, len) != len) {
		    if (errmsg)
		    	*errmsg = gzerror(gzoutfp, &err);
		    goto errout;
	    }
    }

errout:
    if (buf)
	    free(buf);
    if (gzoutfp)
	    gzclose(gzoutfp);
    return (err);
}


// Process the XPC request, create a temporary file to hold downloaded,
// data, and build/return XPC reply.
static void
zip_process_request(xpc_object_t request, xpc_object_t reply)
{
    // Get the input and output file descriptors from the XPC request
    int infd = xpc_dictionary_dup_fd(request, "infd");
    int outfd = xpc_dictionary_dup_fd(request, "outfd");
    int64_t errcode = 0;
    const char *errmsg = NULL;

    // Check arguments.
    if (infd == -1 || outfd == -1) {
        errcode = Z_ERRNO;
        errmsg = "Invalid file descriptor(s)";
        goto errout;
    }

    // "gzip" file using level 6 compress and default strategy
    errcode = zip_compress_file(infd, outfd, 6, 0, &errmsg);

errout:
    // Clean up and add errcode/errmsg to reply.
    if (infd != -1)
	    close(infd);
    if (outfd != -1)
	    close(outfd);

    xpc_dictionary_set_int64(reply, "errcode", errcode);
    if (errmsg)
        xpc_dictionary_set_string(reply, "errmsg", errmsg);
}

static void
zip_peer_event_handler(xpc_connection_t peer, xpc_object_t event)
{
    // Get the object type.
    xpc_type_t type = xpc_get_type(event);
    if (XPC_TYPE_ERROR == type) {
        // Handle an error.
        if (XPC_ERROR_CONNECTION_INVALID == event) {
            // The client process on the other end of the connection
            // has either crashed or cancelled the connection.
            asl_log(NULL, NULL, ASL_LEVEL_NOTICE, "peer(%d) received "
                "XPC_ERROR_CONNECTION_INVALID",
                xpc_connection_get_pid(peer));
            xpc_connection_cancel(peer);
        } else if (XPC_ERROR_TERMINATION_IMMINENT == event) {
            // Handle per-connection termination cleanup. This
            // service is about to exit.
            asl_log(NULL, NULL, ASL_LEVEL_NOTICE, "peer(%d) received "
                "XPC_ERROR_TERMINATION_IMMINENT",
                xpc_connection_get_pid(peer));
        }
    } else if (XPC_TYPE_DICTIONARY == type) {
        xpc_object_t requestMessage = event;
        char *messageDescription = xpc_copy_description(requestMessage);

        asl_log(NULL, NULL, ASL_LEVEL_NOTICE, "received message from peer(%d)\n:%s",
            xpc_connection_get_pid(peer), messageDescription);
        free(messageDescription);

        xpc_object_t replyMessage = xpc_dictionary_create_reply(requestMessage);
        assert(replyMessage != NULL);

        // Process request and build a reply message.
        zip_process_request(requestMessage, replyMessage);

	messageDescription = xpc_copy_description(replyMessage);
	asl_log(NULL, NULL, ASL_LEVEL_NOTICE, "reply message to peer(%d)\n: %s",
	    xpc_connection_get_pid(peer), messageDescription);
	free(messageDescription);

        xpc_connection_send_message(peer, replyMessage);
        xpc_release(replyMessage);
    }
}

static void
zip_event_handler(xpc_connection_t peer)
{
    // Generate an unique name for the queue to handle messages from
    // this peer and create a new dispatch queue for it.
    char *queue_name = NULL;
    asprintf(&queue_name, "%s-peer-%d", "com.apple.SandboxedFetch.zip",
             xpc_connection_get_pid(peer));
    dispatch_queue_t peer_event_queue =
    dispatch_queue_create(queue_name, DISPATCH_QUEUE_SERIAL);
    assert(peer_event_queue != NULL);
    free(queue_name);
    
    // Set the target queue for connection.
    xpc_connection_set_target_queue(peer, peer_event_queue);
    
    // Set the handler block for connection.
    xpc_connection_set_event_handler(peer, ^(xpc_object_t event) {
        zip_peer_event_handler(peer, event);
    });
    
    // Enable the peer connection to receive messages.
    xpc_connection_resume(peer);
}

int
main(int argc, const char *argv[])
{
    xpc_main(zip_event_handler);
    exit(EXIT_FAILURE);
}

