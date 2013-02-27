//
//  Utilities.h
//  Apply Firmware Password
//
//  Created by Apple Customer on 6/8/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSApplication (Utilities)

- (NSMutableArray *)addPackage:(NSString *)pkgPath toInput:(NSMutableArray *)input;

@end
