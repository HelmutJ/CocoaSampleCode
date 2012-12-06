/*
     File: NotificationObserve.c
 Abstract: Implements the code to add and remove observers for the stock price
 change notification, using CFNotificationCenter.
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

#import <CoreFoundation/CoreFoundation.h>


extern void StockPriceChanged(void *observer, CFStringRef stockSymbol, double newPrice);


// Callback for the notification
// This repackages the data and sends it to the observer as a StockPriceChanged() callback.

void myCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    double newPrice = 0.0;
    CFStringRef stockSymbol = NULL;
    
    // We get the new price out of the user info dictionary
    // We also get the stock symbol out of there (true, the object is also
    //   the stock symbol, but that can be NULL, if the registry was made for "all")
    
    if (userInfo) {
        CFNumberRef newPriceNum = CFDictionaryGetValue(userInfo, CFSTR("New Price"));
	if (newPriceNum) CFNumberGetValue(newPriceNum, kCFNumberDoubleType, &newPrice);
        stockSymbol = CFDictionaryGetValue(userInfo, CFSTR("Stock Symbol"));
    }

    StockPriceChanged(observer, stockSymbol, newPrice);
}

// Pass in "all" stockSymbol to register for all stocks; this will cause the notification
// to be registered for with a NULL object, meaning it will be delivered no matter
// what the object.

void AddStockNotificationObserver(const void *observer, CFStringRef stockSymbol) {
    CFNotificationCenterRef center = CFNotificationCenterGetDistributedCenter();
    
    // Register for the notification with the global notification center
    // Arguments are:
    // Caller supplied arbitrary observer (which is used as the callback object)
    // Name of notification, in this case "Stock Price Changed Notification"
    // And the object, in this case the stock symbol (NULL for all)
    // The suspension behavior --- determines when the notification center process
    //   delivers the notifications to this process. For notifications that don't
    //   require non-frontmost apps to react, then you can pass 
    //   CFNotificationSuspensionBehaviorHold or CFNotificationSuspensionBehaviorCoalesce
    
    if (CFEqual(stockSymbol, CFSTR("all"))) stockSymbol = NULL;
    CFNotificationCenterAddObserver(center, observer, myCallback, CFSTR("Stock Price Changed Notification"),  stockSymbol, CFNotificationSuspensionBehaviorDeliverImmediately);
}

void RemoveStockNotificationObserver(const void *observer, CFStringRef stockSymbol) {
    CFNotificationCenterRef center = CFNotificationCenterGetDistributedCenter();
    if (CFEqual(stockSymbol, CFSTR("all"))) stockSymbol = NULL;
    CFNotificationCenterRemoveObserver(center, observer, CFSTR("Stock Price Changed Notification"),  stockSymbol);
}

extern void RemoveObserverForAllStocks(const void *observer) {
    CFNotificationCenterRef center = CFNotificationCenterGetDistributedCenter();
    CFNotificationCenterRemoveEveryObserver(center, observer);
}
