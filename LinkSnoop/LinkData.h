// ======================================================================================================================
//  LinkData.h
// ======================================================================================================================


#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>


@interface LinkData : NSObject
{
	PDFAnnotation	*_annotation;
	PDFDestination	*_destination;
	NSString		*_text;
}

- (id) initWithAnnotation: (PDFAnnotation *) annotation;
- (PDFAnnotation *) annotation;
- (NSString *) text;
- (PDFDestination *) destination;
- (PDFSelection *) selection;

@end
