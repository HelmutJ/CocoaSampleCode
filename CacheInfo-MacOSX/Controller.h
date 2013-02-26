/*
 
 File:<Controller.h>
 
 Version: <1.0>
 
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

#import <Cocoa/Cocoa.h>

@interface Controller : NSObject {
@private
	NSMutableData *receivedData;
	NSDate *connectionTime;
	NSMutableString *diskPath;
	NSURLConnection *connection;

	IBOutlet NSButton *loadButton;
	IBOutlet NSButton *clearButton;
	IBOutlet NSImageView *imageView;
	IBOutlet NSTextField *sizeField;
	IBOutlet NSTextField *timeField;
	IBOutlet NSTextField *memoryField;
	IBOutlet NSTextField *diskField;
	IBOutlet NSTextField *memoryUsage;
	IBOutlet NSTextField *diskUsage;
	IBOutlet NSComboBox *comboBox;
	IBOutlet NSSlider *memoryCacheSlider;
	IBOutlet NSSlider *diskCacheSlider;
	IBOutlet NSProgressIndicator *progressIndicator;
}

@property (nonatomic, retain) NSMutableData *receivedData;
@property (nonatomic, retain) NSDate *connectionTime;
@property (nonatomic, assign) NSMutableString *diskPath;
@property (nonatomic, assign) NSURLConnection *connection;

@property (nonatomic, retain, readonly) NSButton *loadButton;
@property (nonatomic, retain, readonly) NSButton *clearButton;
@property (nonatomic, retain) NSComboBox *comboBox;
@property (nonatomic, retain) NSTextField *sizeField;
@property (nonatomic, retain) NSTextField *timeField;
@property (nonatomic, retain) NSTextField *memoryField;
@property (nonatomic, retain) NSTextField *diskField;
@property (nonatomic, retain) NSTextField *memoryUsage;
@property (nonatomic, retain) NSTextField *diskUsage;
@property (nonatomic, retain) NSImageView *imageView;
@property (nonatomic, retain) NSSlider *memoryCacheSlider;
@property (nonatomic, retain) NSSlider *diskCacheSlider;
@property (nonatomic, retain) NSProgressIndicator *progressIndicator;

- (IBAction)onLoadResource:(id)sender;
- (IBAction)onClearCache:(id)sender;
- (IBAction)onMemorySlider:(id)sender;
- (IBAction)onDiskSlider:(id)sender;
- (IBAction)cancel:(id)sender;

@end
