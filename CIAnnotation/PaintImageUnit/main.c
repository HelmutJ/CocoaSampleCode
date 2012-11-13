/* This is the default source file for new CIPlugin bundles. */

#include <QuartzCore/CIPlugInInterface.h>

#include <stdio.h>
#include <stdlib.h>

// The layout for an instance of MyType.

typedef struct _MyType {
    CIPlugInFilterInterfaceStruct *_filterPlugInInterface;
    CFUUIDRef _factoryID;
    UInt32 _refCount;
} MyType;

// Forward declaration for the IUnknown implementation.

static void _deallocMyType( MyType *myInstance );

// -------------------------------------------------------------------------------------------
//
//  Implementation of the IUnknown QueryInterface function.
//

static HRESULT myQueryInterface( void *myInstance, REFIID iid, LPVOID *ppv )
{
    //  Create a CoreFoundation UUIDRef for the requested interface.

    CFUUIDRef interfaceID = CFUUIDCreateFromUUIDBytes( NULL, iid );

    // Test the requested ID against the valid interfaces.

    if( CFEqual( interfaceID, kCIPlugInFilterInterfaceID ) ) {

        //  If the TestInterface was requested, bump the ref count, set the ppv parameter
        //  equal to the instance, and return good status.

        ( (MyType *) myInstance )->_filterPlugInInterface->AddRef( myInstance );
        *ppv = myInstance;
        CFRelease( interfaceID );
        return S_OK;
    }
    else if( CFEqual( interfaceID, IUnknownUUID ) ) {

        //  If the IUnknown interface was requested, same as above.

        ( (MyType *) myInstance )->_filterPlugInInterface->AddRef( myInstance );
        *ppv = myInstance;
        CFRelease( interfaceID );
        return S_OK;
    }
    else {

        //  Requested interface unknown, bail with error.

        *ppv = NULL;
        CFRelease( interfaceID );
        return E_NOINTERFACE;
    }
}

// -------------------------------------------------------------------------------------------
//
//  Implementation of reference counting for this type.
//  Whenever an interface is requested, bump the refCount for the instance.
//  NOTE: returning the refcount is a convention but is not required so don't rely on it.
//

static ULONG myAddRef( void *myInstance )
{
    ( (MyType *) myInstance )->_refCount += 1;
    return ( (MyType *) myInstance )->_refCount;
}

// -------------------------------------------------------------------------------------------
//
//  When an interface is released, decrement the refCount.
//  If the refCount goes to zero, deallocate the instance.
//

static ULONG myRelease( void *myInstance )
{
    ( (MyType *) myInstance )->_refCount -= 1;
    if ( ( (MyType *) myInstance )->_refCount == 0 ) {
        _deallocMyType( (MyType *) myInstance );
        return 0;
    }
    else
        return ( (MyType *) myInstance )->_refCount;
}

// -------------------------------------------------------------------------------------------
//
//  The implementation of the custom initialization function.
//

static bool myInitialize(void *theCIPlugInHost, void *myInstance )
{
    printf("plugin initialized\n");
    return true;
}

// -------------------------------------------------------------------------------------------
//
//  The TestInterface function table.
//

static CIPlugInFilterInterfaceStruct filterPlugInInterfaceFtbl = {
		NULL,                    // Required padding for COM
		myQueryInterface,        // These three are the required COM functions
		myAddRef,
		myRelease,
		myInitialize,
		NULL };              // Interface implementation

// -------------------------------------------------------------------------------------------
//
//  Utility function that allocates a new instance.
//

static MyType *_allocMyType( CFUUIDRef factoryID )
{
    //  Allocate memory for the new instance.

    MyType *newOne = (MyType *)malloc( sizeof(MyType) );

    //  Point to the function table

    newOne->_filterPlugInInterface = &filterPlugInInterfaceFtbl;

    //  Retain and keep an open instance refcount for each factory.

    if (factoryID) {
        newOne->_factoryID = (CFUUIDRef)CFRetain( factoryID );
        CFPlugInAddInstanceForFactory( factoryID );
    }

    //  This function returns the IUnknown interface so set the refCount to one.

    newOne->_refCount = 1;
    return newOne;
}

// -------------------------------------------------------------------------------------------
//
//  Utility function that deallocates the instance when the refCount goes to zero.
//

static void _deallocMyType( MyType *myInstance )
{
    CFUUIDRef factoryID = myInstance->_factoryID;
    free( myInstance );
    if ( factoryID ) {
        CFPlugInRemoveInstanceForFactory( factoryID );
        CFRelease( factoryID );
    }
}

// -------------------------------------------------------------------------------------------
//
//  Implementation of the factory function for this type.
//

void *MyFactoryFunction( CFAllocatorRef allocator, CFUUIDRef typeID )
{

    //  If correct type is being requested, allocate an instance of TestType and return
    //  the IUnknown interface.

    if ( CFEqual( typeID, kCIPlugInTypeID ) ) {
        MyType *result = _allocMyType( kCIPlugInFilterInterfaceID );
        return result;
    }
    else {
    
        // If the requested type is incorrect, return NULL.

        return NULL;
    }
}