//
//  Item_Extensions.m
//  DragNDropOLV
//

#import "Item_Extensions.h"

#define KEY_GROUPNAME	@"Group"
#define KEY_ENTRIES	@"Entries"

@implementation NSObject (ItemStuff)
- (void)insertChildItem:(id)item atIndex:(NSInteger)index { return; }
- (void)removeChildItem:(id)item { return; }
- (void)replaceChildAtIndex:(NSUInteger)index withItem:(id)replacment { return; }
- (id)childItemAtIndex:(NSInteger)index { return nil; }
- (NSInteger)indexOfChildItem:(id)item { return NSNotFound; }
- (NSInteger)numberOfChildItems { return 0; }
- (id)itemDescription { return self; }
- (BOOL)isExpandable { return NO; }
- (BOOL)isLeaf { return YES; }
- (NSArray *)itemsByFlattening { return [NSArray arrayWithObject:self]; }
- (NSString*)className { return [[self class] description]; }
+ (id)newGroup { return [NSDictionary dictionaryWithObjectsAndKeys: @"New Group", KEY_GROUPNAME, [NSMutableArray array], KEY_ENTRIES, nil]; }
+ (id)newLeaf { return [NSMutableString stringWithCString: "New Leaf"]; }
+ (id)newGroupFromLeaf:(id)leaf { return [NSDictionary dictionaryWithObjectsAndKeys: [leaf itemDescription], KEY_GROUPNAME, [NSMutableArray array], KEY_ENTRIES, nil]; }
- (void) sortRecursively: (BOOL) recurse { return; }
- (id)deepMutableCopy { return [self mutableCopy]; }
- (void)setItemDescription:(NSString *)desc { return; }
@end

@implementation NSMutableString (ItemStuff)
- (void)setItemDescription:(NSString*)desc { [self setString: desc]; }
@end

@implementation NSArray (ItemStuff)
- (NSArray *)itemsByFlattening { 
    NSObject *entry = nil;
    NSEnumerator *entries = [self objectEnumerator];
    NSMutableArray *flatItems = [NSMutableArray array];
    while ((entry=[entries nextObject])) {
        [flatItems addObjectsFromArray: [entry itemsByFlattening]];
    }
    return [NSArray arrayWithArray: flatItems]; 
}
@end

static NSInteger _compareEntries(id item1, id item2, void *context) { return [(NSString*)[item1 itemDescription] compare: [item2 itemDescription]]; }

@implementation NSMutableDictionary (ItemStuff) 
- (void)removeChildItem:(id)item { [[self objectForKey: KEY_ENTRIES] removeObjectIdenticalTo: item]; }
- (void)replaceChildAtIndex:(NSUInteger)index withItem:(id)item { [[self objectForKey:KEY_ENTRIES] replaceObjectAtIndex:index withObject:item]; }
- (void)insertChildItem:(id)item atIndex:(NSInteger)index { [[self objectForKey: KEY_ENTRIES] insertObject: item atIndex: index]; }
- (id)childItemAtIndex:(NSInteger)index { return [[self objectForKey: KEY_ENTRIES] objectAtIndex: index]; }
- (NSInteger)indexOfChildItem:(id)item { return [[self objectForKey: KEY_ENTRIES] indexOfObjectIdenticalTo: item]; }
- (NSInteger)numberOfChildItems { return [[self objectForKey: KEY_ENTRIES] count]; }
- (id)itemDescription { return [self objectForKey: KEY_GROUPNAME]; }
- (BOOL)isExpandable { return YES; }
- (BOOL)isLeaf { return NO; }
- (NSArray *)itemsByFlattening { 
    NSObject *entry = nil;
    NSMutableArray *results = [NSMutableArray arrayWithObject:[self objectForKey: KEY_GROUPNAME]];
    NSEnumerator *entries = [[self objectForKey: KEY_ENTRIES] objectEnumerator];
    NSMutableArray *flatItems = [NSMutableArray array];
    while ((entry=[entries nextObject])) {
        [flatItems addObjectsFromArray: [entry itemsByFlattening]];
    }
    [results addObjectsFromArray: flatItems];
    return results;
}

- (void)setItemDescription:(NSString*)desc { [self setObject: [desc mutableCopy] forKey: KEY_GROUPNAME]; }
- (void) sortRecursively: (BOOL) recurse {
    [[self objectForKey: KEY_ENTRIES] sortUsingFunction: _compareEntries context: NULL];
    if (recurse) {
        id entry = nil;
        NSEnumerator *entries = [[self objectForKey: KEY_ENTRIES] objectEnumerator];
        while ( (entry=[entries nextObject]) ) {
            if ([entry isKindOfClass: [NSDictionary class]]) [entry sortRecursively: recurse];
        }
    }
}
@end

