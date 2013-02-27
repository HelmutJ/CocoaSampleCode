BoundButton


This simple application illustrates how you can use Cocoa bindings to bind the target and argument parameters of a button.


In many cases, there is no need to use Cocoa bindings with a button -- the target/action pattern is more appropriate.  Sometimes, however, it may be convenient to use bindings to collect information from your application and pass it to the target using the method arguments.


In this example, the user is presented with two simple table views containing entrees and toppings managed by array controllers.  The user selects one entree and any number of toppings and presses a button to submit an order.

The method to submit the order (orderEntree:withToppings:) takes two arguments, the selected entree and toppings.  These are the 'selection' of the entrees array controller and 'selectedObjects' of the toppings array controller respectively.  The order controller object could retrieve these directly from the array controllers, but this would require it to have outlets to the array controllers and a couple of extra method calls.  Instead, these values can be retrieved using bindings.

The button's Action Invocation bindings are specified as follows:
 
 
* 'target' is bound to [OrderController].self' -- this uses 'self' as a key simply to return the OrderController instance.
 
The selector (specified in the target binding) is orderEntree:withToppings:, identifying the method below.
 

'argument' is a multi-value binding.
 
* argument is [Entrees].selection -- the selection is passed as the first argument to orderEntree:withToppings:.  The selection is a proxy object representing the array controller's selection, but this is OK since it is only accessed using key-value coding methods.
 
* argument2 is [Toppings].selectedObjects -- the objects currently selected.


When the button is pressed, therefore, it sends its target (the OrderController instance) a orderEntree:withToppings: message with the arguments the selection of the entrees array controller and the selectedObjects and toppings array controller.
