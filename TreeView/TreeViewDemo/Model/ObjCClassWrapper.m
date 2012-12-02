/*
    File: ObjCClassWrapper.m
Abstract: ObjCClassWrapper Implementation
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

#import "ObjCClassWrapper.h"
#import <objc/objc-runtime.h>

/* Keeps track of the ObjCClassWrapper instances we create. 
    We create one unique ObjCClassWrapper for each Objective-C "Class" we're asked to wrap.
*/
static NSMapTable *classToWrapperMapTable = nil;

/* Compares two ObjCClassWrappers by name, and returns an NSComparisonResult.
*/
static NSInteger CompareClassNames(id classA, id classB, void* context) {
    return [[classA description] compare:[classB description]];
}

@implementation ObjCClassWrapper

#pragma mark *** Creating Instances ***

- initWithWrappedClass:(Class)aClass {
    self = [super init];
    if (self) {
        if (aClass != Nil) {
            wrappedClass = aClass;
            if (classToWrapperMapTable == nil) {
                classToWrapperMapTable = [[NSMapTable weakToStrongObjectsMapTable] retain];
            }
            [classToWrapperMapTable setObject:self forKey:wrappedClass];
        } else {
            [self release];
            return nil;
        }
    }
    return self;
}

+ (ObjCClassWrapper *)wrapperForClass:(Class)aClass {
    ObjCClassWrapper *wrapper = [classToWrapperMapTable objectForKey:aClass];
    if (wrapper == nil) {
        wrapper = [[[self alloc] initWithWrappedClass:aClass] autorelease];
    }
    return wrapper;
}

+ (ObjCClassWrapper *)wrapperForClassNamed:(NSString *)aClassName {
    return [self wrapperForClass:NSClassFromString(aClassName)];
}


#pragma mark *** Property Accessors ***

- (NSString *)name {
    return NSStringFromClass(wrappedClass);
}

- (NSString *)description {
    return [self name];
}

- (size_t)wrappedClassInstanceSize {
    return class_getInstanceSize(wrappedClass);
}

- (ObjCClassWrapper *)superclassWrapper {
    return [[self class] wrapperForClass:class_getSuperclass(wrappedClass)];
}

- (NSArray *)subclasses {

    // If we haven't built our array of subclasses yet, do so.
    if (subclassesCache == nil) {

        // Iterate over all classes (as described in objc/objc-runtime.h) to find the subclasses of wrappedClass.
        int i;
        int numClasses = 0;
        int newNumClasses = objc_getClassList(NULL, 0);
        Class* classes = NULL;
        while (numClasses < newNumClasses) {
            numClasses = newNumClasses;
            classes = realloc(classes, sizeof(Class) * numClasses);
            newNumClasses = objc_getClassList(classes, numClasses);
        }

        // Make an array of ObjCClassWrapper instances to represent the classes.
        subclassesCache = [[NSMutableArray alloc] initWithCapacity:numClasses];
        for (i = 0; i < numClasses; i++) {
            if (class_getSuperclass(classes[i]) == wrappedClass) {
                [subclassesCache addObject:[[self class] wrapperForClass:classes[i]]];
            }
        }
        free(classes);

        // Sort subclasses by name.
        [subclassesCache sortUsingFunction:CompareClassNames context:NULL];
    }
    return subclassesCache;
}

#pragma mark *** TreeViewModelNode Protocol Conformance ***

- (id<TreeViewModelNode>)parentModelNode {
    return [self superclassWrapper];
}

- (NSArray *)childModelNodes {
    return [self subclasses];
}


#pragma mark *** Cleanup ***

- (void)dealloc {
    [subclassesCache release];
    [super dealloc];
}

@end
