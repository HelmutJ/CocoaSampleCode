With and Without Bindings
-------------------------

This sample illustrates the adoption of Cocoa Bindings to manage synchronization of values between models and views, and in particular
the role of the NSController object:
(a) How you can consider NSController object as a refactoring of your own code; and 
(b) How you can subclass an NSController class to customise its behaviour.

This is best seen if you compare the two projects using the File Merge application.

First, compare the MyDocument classes. Notice that most of the instance variables "disappear", as does all of the code related simply to updating the user interface in response to selection changes. Detail UI elements are bound to the selection of the array controller, so this is all handled by bindings.

Second, compare the TableViewDataSource files which contain the implementation of the drag and drop methods for the table view (and in the case of the first implementation, also the standard data source methods).

There is a subtle but profound difference between the TableViewDataSource files in the two projects. In the first case, the files contain a category of the MyDocument class. In the second, the files contain a subclass of NSArrayController. That the standard data source methods disappear should not be a surprise. What may be more unexpected, however, is how little code changes in the drag and drop methods.

Here responsibility for drag and drop has been passed to the object with most similar other responsibilities. So in terms of refactoring, you can consider the NSArrayController instance to have absorbed the functionality you would normally have to have implemented yourself (in the table view data source methods) whilst still allowing the extensibility of subclassing to provide additional custom behaviour.

Finally, notice that the WithBindings project includes a simple value transformer.  It takes over responsibility from the MyDocument object in the WithoutBindings version of converting between an URL in the bookmark object and a string in the URL text field in the window. (The 'value' binding for the URL text field has "StringToURLTransformer" as its value transformer option.)
