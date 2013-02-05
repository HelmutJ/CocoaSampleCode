/*
     File: fetch_service.c 
 Abstract: XPC service that downloads remote files using libcurl.
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

#include <curl/curl.h>

#include <xpc/xpc.h>

typedef struct {
    xpc_connection_t connection;
    int stop_download;
} fetch_progress_ctx_t;

static size_t
fetch_write_callback(void *ptr, size_t size, size_t nmemb, FILE *stream)
{
    return fwrite(ptr, size, nmemb, stream);
}

static int
fetch_progress_callback(fetch_progress_ctx_t *ctx, double t, double d,
                        __unused double ultotal, __unused double ulnow)
{

    if (ctx->stop_download) {
        // Transfer has been aborted.
        return (TRUE);
    }

    // Compute the precentage transferred and send a message to UI.
    if (t != 0.0) {
        xpc_object_t message = xpc_dictionary_create(NULL, NULL, 0);

        xpc_dictionary_set_double(message, "progressValue", d*100.0/t);
        xpc_connection_send_message(ctx->connection, message);
        xpc_release(message);
    }

    return (FALSE);
}

// Download file using libcurl.
//
// Returns CURLE_OK on success.  Also, returns a pointer to a error message
// with errmsg, if provided.
static int
fetch_download_file(const char *url, int fd, fetch_progress_ctx_t *ctx,
                    const char **errmsg)
{
    CURL *curl = NULL;
    CURLcode err = CURLE_OK;
    FILE *fp = NULL;

    if (errmsg)
        *errmsg = NULL;

    // Convert file descriptor to file pointer
    if ((fp = fdopen(dup(fd), "r+")) == NULL) {
        err = CURLE_WRITE_ERROR;
        if (errmsg)
            *errmsg = strerror(errno);
        goto errout;
    }

    // Initialize libcurl.
    if ((curl = curl_easy_init()) == NULL) {
        err = CURLE_FAILED_INIT;
        goto errout;
    }
    // Set the URI of the remote file to be saved into the file.
    if ((err = curl_easy_setopt(curl, CURLOPT_URL, url)) != CURLE_OK)
        goto errout;
    // Set the file pointer as the output for the HTTP server response.
    if ((err = curl_easy_setopt(curl, CURLOPT_WRITEDATA, fp)) != CURLE_OK)
        goto errout;
    // Set read/write callbacks.
    if ((err = curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, 
                                fetch_write_callback)) != CURLE_OK)
        goto errout;
    if ((err = curl_easy_setopt(curl, CURLOPT_PROGRESSDATA, ctx)) != CURLE_OK)
        goto errout;
    if ((err = curl_easy_setopt(curl, CURLOPT_PROGRESSFUNCTION,
                                fetch_progress_callback)) != CURLE_OK)
        goto errout;
    if ((err = curl_easy_setopt(curl, CURLOPT_NOPROGRESS, 0L)) != CURLE_OK)
        goto errout;

    // Perform file transfer.
    err = curl_easy_perform(curl);

    if (CURLE_ABORTED_BY_CALLBACK == err) {
        if (errmsg)
            *errmsg = "Download Canceled";
    }

errout:
    if (fp)
        fclose(fp);
    if (curl)
        curl_easy_cleanup(curl);
    if (errmsg && *errmsg == NULL) {
        if (err != CURLE_OK)
            *errmsg = curl_easy_strerror(err);
        else
            *errmsg = NULL;
    }
    return (err);
}


// Process the XPC request, create a temporary file to hold downloaded,
// data, and build/return XPC reply.
static void
fetch_process_request(xpc_object_t request, xpc_object_t reply)
{
    // Get the URL and XPC connection from the XPC request
    const char *url = xpc_dictionary_get_string(request, "url");
    xpc_connection_t conn =
        xpc_dictionary_create_connection(request, "connection");
    int ret_fd = -1;
    char *tempname;
    int errcode = 0;
    const char *errmsg = NULL;
    __block fetch_progress_ctx_t ctx = { conn, FALSE };

    // Check URL to make sure it is valid. Only support HTTP.
    if (NULL == url || strncasecmp("http://", url, 7)) {
        errcode = EINVAL;
        errmsg = "Invalid URL";
        goto errout;
    }

    // Check XPC Connection
    if (conn == NULL) {
        errcode = EINVAL;
        errmsg = "Invalid XPC connection";
        goto errout;
    }

    // Set up XPC connection endpoint for sending progress reports and receiving
    // cancel notification.
    xpc_connection_set_event_handler(conn, ^(xpc_object_t event) {
        xpc_type_t type = xpc_get_type(event);

        // If the remote end of this connection has gone away then stop download
        if (XPC_TYPE_ERROR == type &&
            XPC_ERROR_CONNECTION_INTERRUPTED == event) {
            asl_log(NULL, NULL, ASL_LEVEL_NOTICE, "Stopping transfer\n");
            ctx.stop_download = TRUE;
        }
    });
    xpc_connection_resume(conn);

    // Open a temporary file in the temp directory of the container.
    if (asprintf(&tempname, "%sfetch.XXXXXXXX", getenv("TMPDIR")) < 0) {
        errcode = errno;
        errmsg = "Couldn't alloc temp filename";
        goto errout;
    }
    if ((ret_fd = mkstemp(tempname)) < 0) {
        free(tempname);
        errcode = errno;
        errmsg = "Couldn't open temp file";
        goto errout;
    }

    // Unlink the file so it is removed as soon as it is closed.
    (void)unlink(tempname);
    free(tempname);

    // Download file add file descriptor to reply
    if ((errcode = fetch_download_file(url, ret_fd, &ctx, &errmsg)) == 0) {
        (void)lseek(ret_fd, 0, SEEK_SET);
        xpc_dictionary_set_fd(reply, "fd", ret_fd);
    }

errout:
    // Clean up and add errcode/errmsg to reply
    if (conn) {
        xpc_connection_suspend(conn);
        xpc_release(conn);
    }
    if (errcode && ret_fd != -1)
        close(ret_fd);
    xpc_dictionary_set_int64(reply, "errcode", (int64_t)errcode);
    if (errmsg)
        xpc_dictionary_set_string(reply, "errmsg", errmsg);
}

static void
fetch_peer_event_handler(xpc_connection_t peer, xpc_object_t event)
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

        asl_log(NULL, NULL, ASL_LEVEL_NOTICE, "received message from "
            "peer(%d)\n:%s",xpc_connection_get_pid(peer), messageDescription);
        free(messageDescription);

        xpc_object_t replyMessage = xpc_dictionary_create_reply(requestMessage);
        assert(replyMessage != NULL);

        // Process request and build a reply message.
        fetch_process_request(requestMessage, replyMessage);

        messageDescription = xpc_copy_description(replyMessage);
        asl_log(NULL, NULL, ASL_LEVEL_NOTICE, "reply message to peer(%d)\n: %s",
                xpc_connection_get_pid(peer), messageDescription);
        free(messageDescription);

        xpc_connection_send_message(peer, replyMessage);
        xpc_release(replyMessage);
    }
}

static void
fetch_event_handler(xpc_connection_t peer)
{
    // Generate an unique name for the queue to handle messages from
    // this peer and create a new dispatch queue for it.
    char *queue_name = NULL;
    asprintf(&queue_name, "%s-peer-%d", "com.apple.SandboxedFetch.fetch",
             xpc_connection_get_pid(peer));
    dispatch_queue_t peer_event_queue =
        dispatch_queue_create(queue_name, DISPATCH_QUEUE_SERIAL);
    assert(peer_event_queue != NULL);
    free(queue_name);

    // Set the target queue for connection.
    xpc_connection_set_target_queue(peer, peer_event_queue);

    // Set the handler block for connection.
    xpc_connection_set_event_handler(peer, ^(xpc_object_t event) {
        fetch_peer_event_handler(peer, event);
    });

    // Enable the peer connection to receive messages.
    xpc_connection_resume(peer);
}

int
main(int argc, const char *argv[])
{
    xpc_main(fetch_event_handler);
    exit(EXIT_FAILURE);
}

