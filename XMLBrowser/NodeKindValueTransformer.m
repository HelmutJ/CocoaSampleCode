/*
     File: NodeKindValueTransformer.m
 Abstract: The node types NSXMLElementKind etc are a simple enumeration.
 To create a more pleasing interface we create a value transformer that
 changes from the enemerated type to a string, then bind the enumerated
 values to this transformer in the Bindings palette of Interface Builder.
 A second transformer is added to map from an NSXMLNodeKind to whether
 it can have children.
  Version: 1.1
 
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

#import "NodeKindValueTransformer.h"


@implementation NodeKindValueTransformer

+ (Class)transformedValueClass {
    return [NSString class];
}

/* Only need to transform from enumeration -> string */
+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (id)transformedValue:(id)value {
    switch ([value intValue]) {
        case NSXMLInvalidKind:
            return @"-";
            break;
        case NSXMLDocumentKind:
            return @"Document";
            break;
        case NSXMLElementKind:
            return @"Element";
            break;
        case NSXMLAttributeKind:
            return @"Attribute";
            break;
        case NSXMLNamespaceKind:
            return @"Namespace";
            break;
        case NSXMLProcessingInstructionKind:
            return @"Processing Instruction";
            break;
        case NSXMLCommentKind:
            return @"Comment";
            break;
        case NSXMLTextKind:
            return @"Text";
            break;
        case NSXMLDTDKind:
            return @"DTD";
            break;
        case NSXMLEntityDeclarationKind:
            return @"Entity declaration";
            break;
        case NSXMLAttributeDeclarationKind:
            return @"Attribute declaration";
            break;
        case NSXMLElementDeclarationKind:
            return @"Element declaration";
            break;
        case NSXMLNotationDeclarationKind:
            return @"Notation declaration";
            break;
        default:
            return @"";
            break;
    }                                                                                         
}

@end

@implementation NodeCanHaveChildrenValueTransformer

+ (Class)transformedValueClass {
    return [NSNumber class];
}

/* Only need to transform from childCount -> string */
+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (id)transformedValue:(id)value {
    if ([value intValue] == NSXMLElementKind) {
        return [NSNumber numberWithBool:YES];
    } else {
        return [NSNumber numberWithBool:NO];
    }
}

@end

