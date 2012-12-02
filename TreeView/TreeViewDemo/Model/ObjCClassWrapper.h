/*
    File: ObjCClassWrapper.h
Abstract: ObjCClassWrapper Interface
 Version: 1.3

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

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "TreeViewModelNode.h"

/* Wraps an Objective-C Class in an NSObject, that we can conveninently query to find related classes (superclass and subclasses) and the instance size.  Conforms to the TreeViewModelNode protocol, so that we can use these as model nodes with a TreeView.
*/
@interface ObjCClassWrapper : NSObject <TreeViewModelNode>
{
    Class wrappedClass;
    NSMutableArray *subclassesCache;
}

#pragma mark *** Creating Instances ***

/* Returns an ObjCClassWrapper for the given Objective-C class.  ObjCClassWrapper maintains a set of unique instances, so this will always return the same ObjCClassWrapper for a given Class.
*/
+ (ObjCClassWrapper *)wrapperForClass:(Class)aClass;

/* Returns an ObjCClassWrapper for the given Objective-C class, by looking the Class up by name and then invoking +wrapperForClass:.
*/
+ (ObjCClassWrapper *)wrapperForClassNamed:(NSString *)aClassName;


#pragma mark *** Property Accessors ***

/* The wrappedClass' name (e.g. @"NSView").
*/
@property(readonly) NSString *name;

/* An ObjCClassWrapper representing the wrappedClass' superclass.
*/
@property(readonly) ObjCClassWrapper *superclassWrapper;

/* An array of ObjCClassWrappers representing the wrappedClass' subclasses.  (For convenience, the subclasses are sorted by name.)
*/
@property(readonly) NSArray *subclasses;

/* The wrappedClass' intrinsic instance size (which doesn't include external/auxiliary storage).
*/
@property(readonly) size_t wrappedClassInstanceSize;

@end
