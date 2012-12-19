//
//  Item_Extensions.h
//  DragNDropOLV
//

#import <Foundation/Foundation.h>

@interface NSObject (ItemStuff)
- (void)insertChildItem:(id)item atIndex:(NSInteger)index;
- (void)removeChildItem:(id)item;
- (void)replaceChildAtIndex:(NSUInteger)index withItem:(id)replacment;
- (id)childItemAtIndex:(NSInteger)index;
- (NSInteger)indexOfChildItem:(id)item;
- (NSInteger)numberOfChildItems;
- (id)itemDescription;
- (void)setItemDescription:(NSString*)desc;
- (BOOL)isExpandable;
- (BOOL)isLeaf;
- (NSArray *)itemsByFlattening;
- (id)deepMutableCopy;
+ (id)newGroup;
+ (id)newLeaf;
+ (id)newGroupFromLeaf:(id)leaf;
- (void)sortRecursively: (BOOL) recurse;
@end

