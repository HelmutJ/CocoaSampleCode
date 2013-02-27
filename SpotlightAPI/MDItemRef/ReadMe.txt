This example is a graphical version of mdls, a file is dragged onto
the window and the tableView will load up with all of the metadata.

the DragView is set as the contentView of the window to accept all
drags to the window. When DragView recieves a file (from finder etc)
it posts a notification which the Controller registers for and then
gathers the metadata for display.