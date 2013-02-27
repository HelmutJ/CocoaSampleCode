/*
 
 File: OrderController.m
 
 Abstract: Controller object that manages a collection of entrees and toppings.
 
 Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by  Apple Inc. ("Apple") in consideration of your agreement to the following terms, and your use, installation, modification or redistribution of this Apple software constitutes acceptance of these terms.  If you do not agree with these terms, please do not use, install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject to these terms, Apple grants you a personal, non-exclusive license, under Apple's copyrights in this original Apple software (the "Apple Software"), to use, reproduce, modify and redistribute the Apple Software, with or without modifications, in source and/or binary forms; provided that if you redistribute the Apple Software in its entirety and without modifications, you must retain this notice and the following text and disclaimers in all such redistributions of the Apple Software.  Neither the name, trademarks, service marks or logos of Apple Inc.  may be used to endorse or promote products derived from the Apple Software without specific prior written permission from Apple.  Except as expressly stated in this notice, no other rights or licenses, express or implied, are granted by Apple herein, including but not limited to any patent rights that may be infringed by your derivative works or by other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2007 Apple Inc. All Rights Reserved.
 
 */



#import "OrderController.h"


// keys used by the Entree and Topping dictionaries

NSString *NAME_KEY = @"name";
NSString *PRICE_KEY = @"price";


@implementation OrderController


/*
 orderEntree:withToppings: is the method invoked by the "Place your order" button -- it is set up using bindings.
 The task is to "print out" to the text view the components and total price of the current order.
 
 
 The button's binding are as follows:
 
 * 'target' is bound to [OrderController].self -- this uses 'self' as a key simply to return the OrderController instance.
 
 The selector (specified in the 'target' binding) is orderEntree:withToppings:, identifying this method.
 
 
 * 'argument' is a multi-value binding:
 
 'argument' is [Entrees].selection -- a proxy object representing the array controller's selection.  This object is passed as the first argument to orderEntree:withToppings:.  The method only sends the selection key-value coding messages.
 
 'argument2' is [Toppings].selectedObjects -- the objects currently selected in the toppings table view.  This array is passed as the second argument to orderEntree:withToppings:.
 
 */


- (void)orderEntree:(id)selectedEntree withToppings:(NSArray *)selectedToppings
{
	/*
	 Check that there was an entree selection (the table view should disallow empty selections, but this is a useful example).
	 */
	if ([selectedEntree valueForKey:@"self"] == NSNoSelectionMarker)
	{
		[self appendToTextView:@"No entree selected.\n\n"];
		return;
	}
	
	
	/*
	 The total price starts with the price of the entree.
	 */
	float total = [(NSNumber *)[selectedEntree valueForKey:PRICE_KEY] floatValue];
	
	
	/*
	 If there are no toppings, end here by adding just the plain entree to the order.
	 */
	if ([selectedToppings count] == 0)
	{
		NSString *orderSummaryString = [NSString stringWithFormat:@"Plain %@\nCost: %1.2f\n\n",
										[selectedEntree valueForKey:NAME_KEY], total];
		
		[self appendToTextView:orderSummaryString];
		return;
	}
	
	
	/*
	 Build an array comprising the names of each of the selected toppings (this is used later to generate the string of components) and update the total.
	 */
	NSEnumerator *enumerator = [selectedToppings objectEnumerator];
	NSMutableArray *toppingNames = [NSMutableArray array];
	NSDictionary * aTopping;
	
	while (aTopping = [enumerator nextObject])
	{
		[toppingNames addObject:[aTopping valueForKey:NAME_KEY]];
		total += [(NSNumber *)[aTopping valueForKey:PRICE_KEY] floatValue];
	}
	
	
	/*
	 Create a string for the order summary and append that to the text view.
	 */	
	NSString *toppingsString = [toppingNames componentsJoinedByString:@", "];
	NSString *orderSummaryString = [NSString stringWithFormat:@"%@ with %@\nCost: %1.2f\n\n",
									[selectedEntree valueForKey:NAME_KEY], toppingsString, total];
	
	[self appendToTextView:orderSummaryString];
}



/*
 Simple method to append a string to the text view and ccroll the text view to make the latest order visible.
 */

- (void)appendToTextView:(NSString *)stringToAppend
{
	int textLength = [[textView textStorage] length];
	NSRange range = NSMakeRange(textLength, 0);
	
	[textView replaceCharactersInRange:range withString:stringToAppend];
	
	textLength = [[textView textStorage] length];
	range = NSMakeRange(textLength, 0);
	[textView scrollRangeToVisible:range];
}




/*
 Accessor methods to return the arrays of entrees and toppings.
 
 The array contents are created on demand.
 For this example, there's no need for custom behavior for the model objects, so just use dictionaries.
 */

- (NSArray *)entrees
{
	
	if (entrees == nil)
	{
		entrees = [[NSMutableArray alloc] init];
		NSDictionary *entree;
		
		entree = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"Pizza", NAME_KEY, [NSNumber numberWithFloat:5.50], PRICE_KEY, nil];
		[entrees addObject:entree];
		
		entree = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"Calzone", NAME_KEY, [NSNumber numberWithFloat:6.75], PRICE_KEY, nil];
		[entrees addObject:entree];
	}
	
	return entrees;
}



- (NSArray *)toppings
{
	if (toppings == nil)
	{
		toppings = [[NSMutableArray alloc] init];
		NSDictionary *topping;		
		
		topping = [NSDictionary dictionaryWithObjectsAndKeys:@"Tomato", NAME_KEY, [NSNumber numberWithFloat:1.50], PRICE_KEY, nil];
		[toppings addObject:topping];
		
		topping = [NSDictionary dictionaryWithObjectsAndKeys:@"Cheese", NAME_KEY, [NSNumber numberWithFloat:1.75], PRICE_KEY, nil];
		[toppings addObject:topping];
		
		topping = [NSDictionary dictionaryWithObjectsAndKeys:@"Pepperoni", NAME_KEY, [NSNumber numberWithFloat:2.75], PRICE_KEY, nil];
		[toppings addObject:topping];
		
		topping = [NSDictionary dictionaryWithObjectsAndKeys:@"Sausage", NAME_KEY, [NSNumber numberWithFloat:2.25], PRICE_KEY, nil];
		[toppings addObject:topping];
	}
	
	return toppings;
}




/*
 Standard dealloc method.
 */

- (void)dealloc
{
	[entrees release];
	[toppings release];
    [super dealloc];
}


@end

