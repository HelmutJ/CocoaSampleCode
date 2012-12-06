/* 
     File: StockObserver.m 
 Abstract:  Implements a simple object to get stock symbols from the UI and
 register for notifications of price changes of that stock. 
  Version: 1.2 
  
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
  
 Copyright (C) 2012 Apple Inc. All Rights Reserved. 
  
 */

#import "StockObserver.h"

extern void AddStockNotificationObserver(const void *observer, CFStringRef stockSymbol);
extern void RemoveStockNotificationObserver(const void *observer, CFStringRef stockSymbol);
extern void RemoveObserverForAllStocks(const void *observer);

@implementation StockObserver

// The callback, as an ObjC method. We put the data in the status area

- (void)stockChanged:(NSString *)stockSymbol newPrice:(double)newPrice {
    NSString *newLine = [NSString stringWithFormat:@"%@ new price: $%.2f\n", stockSymbol, newPrice];
    [[[stockNewsField textStorage] mutableString] appendString:newLine];
}


// The action methods for the "Add" / "Remove" buttons

- (void)addStock:(id)sender {
    NSString *stockSymbol = [stockSymbolField stringValue];
    AddStockNotificationObserver((void *)self, (CFStringRef)stockSymbol);
    [[[stockNewsField textStorage] mutableString] appendFormat:@"Now observing %@\n", stockSymbol];
}

- (void)removeStock:(id)sender {
    NSString *stockSymbol = [stockSymbolField stringValue];
    RemoveStockNotificationObserver((void *)self, (CFStringRef)stockSymbol);
    [[[stockNewsField textStorage] mutableString] appendFormat:@"Stopped observing %@\n", stockSymbol];
}

// When this object is deallocated, it should stop observing; thankfully there's a way to
// quickly remove all observe requests for a given observer

- (void)dealloc {
    RemoveObserverForAllStocks((void *)self);
    [super dealloc];
}

// To assure that this object is deallocated when the app is quitting, we
// listen to the applicationWillTerminate delegate method of the app.
// In more sophisticated, multi-doc apps, we would probably listen to the
// document being closed instead.

- (void)applicationWillTerminate:(NSNotification *)notification {
    [self release];
}

@end


// Callback from AddStockNotificationObserver(). We simply convert the callback
// into an ObjC message send to the right StockObserver object

void StockPriceChanged(void *observer, CFStringRef stockSymbol, double newPrice) {
    [(id)observer stockChanged:(NSString *)stockSymbol newPrice:newPrice];
}


