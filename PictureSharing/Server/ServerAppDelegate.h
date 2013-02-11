/*
    File:       AppDelegate.h

    Contains:   Core server application logic.

    Written by: DTS

    Copyright:  Copyright (c) 2010 Apple Inc. All Rights Reserved.

    Disclaimer: IMPORTANT: This Apple software is supplied to you by Apple Inc.
                ("Apple") in consideration of your agreement to the following
                terms, and your use, installation, modification or
                redistribution of this Apple software constitutes acceptance of
                these terms.  If you do not agree with these terms, please do
                not use, install, modify or redistribute this Apple software.

                In consideration of your agreement to abide by the following
                terms, and subject to these terms, Apple grants you a personal,
                non-exclusive license, under Apple's copyrights in this
                original Apple software (the "Apple Software"), to use,
                reproduce, modify and redistribute the Apple Software, with or
                without modifications, in source and/or binary forms; provided
                that if you redistribute the Apple Software in its entirety and
                without modifications, you must retain this notice and the
                following text and disclaimers in all such redistributions of
                the Apple Software. Neither the name, trademarks, service marks
                or logos of Apple Inc. may be used to endorse or promote
                products derived from the Apple Software without specific prior
                written permission from Apple.  Except as expressly stated in
                this notice, no other rights or licenses, express or implied,
                are granted by Apple herein, including but not limited to any
                patent rights that may be infringed by your derivative works or
                by other works in which the Apple Software may be incorporated.

                The Apple Software is provided by Apple on an "AS IS" basis. 
                APPLE MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING
                WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT,
                MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING
                THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
                COMBINATION WITH YOUR PRODUCTS.

                IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT,
                INCIDENTAL OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
                TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
                DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY
                OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION
                OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY
                OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR
                OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF
                SUCH DAMAGE.

*/

#import <Cocoa/Cocoa.h>

@interface ServerAppDelegate : NSObject {
    BOOL                _running;
    NSUInteger          _selectedPictureIndex;
    NSString *          _longStatus;
    NSString *          _serviceName;
    NSUInteger          _inProgressSendCount;
    NSUInteger          _successfulSendCount;
    NSUInteger          _failedSendCount;

    CFSocketRef         _listeningSocket;
    NSNetService *      _netService;
    NSOperationQueue *  _queue;
    NSUInteger          _debugOptions;
}

// Actions

- (IBAction)startStopAction:(id)sender;

enum {
    kDebugMenuTag = 'dbg '          // == 0x64626720 == 1684170528
};

enum {
    kDebugOptionMaskStallSend        = 0x01,
    kDebugOptionMaskSendBadChecksum  = 0x02,
    kDebugOptionMaskForceIPv4        = 0x04,
    kDebugOptionMaskAutoAdvanceImage = 0x08
};

- (IBAction)toggleDebugOptionAction:(id)sender;

// The user interface uses Cocoa bindings to set itself up based on the following 
// KVC/KVO compatible properties.

@property (nonatomic, assign, readonly,  getter=isRunning) BOOL running;
@property (nonatomic, copy,   readonly ) NSArray *          pictureNames;
@property (nonatomic, assign, readwrite) NSUInteger         selectedPictureIndex;
@property (nonatomic, copy,   readonly ) NSString *         selectedImagePath;
@property (nonatomic, copy,   readonly ) NSString *         startStopButtonTitle;
@property (nonatomic, copy,   readonly ) NSString *         shortStatus;
@property (nonatomic, copy,   readonly ) NSString *         longStatus;
@property (nonatomic, copy,   readonly ) NSString *         serviceName;
@property (nonatomic, assign, readonly, getter=isSending)  BOOL sending;
@property (nonatomic, assign, readonly ) NSUInteger         inProgressSendCount;
@property (nonatomic, assign, readonly ) NSUInteger         successfulSendCount;
@property (nonatomic, assign, readonly ) NSUInteger         failedSendCount;

@end
