// ======================================================================================================================
//  MyWindowController.h
// ======================================================================================================================


#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "MyPDFView.h"


@interface MyWindowController : NSWindowController
{
	NSMutableArray					*_linkList;
	int								_scanPageIndex;
	IBOutlet NSSplitView			*_splitView;
	IBOutlet MyPDFView				*_pdfView;
	IBOutlet NSTableView			*_linksTable;
	IBOutlet NSTextField			*_linkCount;
}

- (PDFAnnotation *) activeAnnotation;

@end
