//     File: ScannedImage.m
// Abstract: n/a
//  Version: 1.2
// 
// Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
// Inc. ("Apple") in consideration of your agreement to the following
// terms, and your use, installation, modification or redistribution of
// this Apple software constitutes acceptance of these terms.  If you do
// not agree with these terms, please do not use, install, modify or
// redistribute this Apple software.
// 
// In consideration of your agreement to abide by the following terms, and
// subject to these terms, Apple grants you a personal, non-exclusive
// license, under Apple's copyrights in this original Apple software (the
// "Apple Software"), to use, reproduce, modify and redistribute the Apple
// Software, with or without modifications, in source and/or binary forms;
// provided that if you redistribute the Apple Software in its entirety and
// without modifications, you must retain this notice and the following
// text and disclaimers in all such redistributions of the Apple Software.
// Neither the name, trademarks, service marks or logos of Apple Inc. may
// be used to endorse or promote products derived from the Apple Software
// without specific prior written permission from Apple.  Except as
// expressly stated in this notice, no other rights or licenses, express or
// implied, are granted by Apple herein, including but not limited to any
// patent rights that may be infringed by your derivative works or by other
// works in which the Apple Software may be incorporated.
// 
// The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
// MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
// THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
// FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
// OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
// 
// IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
// OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
// MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
// AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
// STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
// 
// Copyright (C) 2012 Apple Inc. All Rights Reserved.
// 

#import <sys/stat.h>
#import "ScannedImage.h"

//----------------------------------------------------------------------------------------------------------------------

@implementation ScannedImage

@synthesize filePath    = _filePath;
@synthesize objectInfo  = _objectInfo;

- (id)initWithFilePath:(NSString*)path scannerObject:(void*)scannerObject imageWidth:(UInt32)imageWidth imageHeight:(UInt32)imageHeight
{
    if ( ( self = [super init] ) )
    {
        struct stat status;
        
        _filePath = [path copy];
        
        if ( 0 == lstat( [_filePath UTF8String], &status) )
        {
            memset( &_objectInfo, 0, sizeof( _objectInfo ) );
         
            _objectInfo.privateData                 = scannerObject;
            _objectInfo.icaObjectInfo.objectType    = kICAFile;
            _objectInfo.icaObjectInfo.objectSubtype = kICAFileImage;
            _objectInfo.flags                       = 0;
            _objectInfo.thumbnailSize               = 0;
            _objectInfo.dataWidth                   = imageWidth;
            _objectInfo.dataHeight                  = imageHeight;
            _objectInfo.dataSize                    = status.st_size;
            
            strlcpy( (char*)_objectInfo.name, [[_filePath lastPathComponent] UTF8String], sizeof( _objectInfo.name ) );

            NSDateFormatter*  df  = [[NSDateFormatter alloc] initWithDateFormat:@"%Y:%m:%d %H:%M:%S" allowNaturalLanguage:YES];
            NSDate*           d   = [NSDate date];
            NSString*         ds  = [df stringFromDate:d];

            if ( ds )
                strlcpy( (char*)(_objectInfo.creationDate), [ds UTF8String], sizeof(_objectInfo.creationDate) );
            else
                strlcpy( (char*)(_objectInfo.creationDate), "0000:00:00 00:00:00", sizeof(_objectInfo.creationDate) );
 
            [df release];
        }
        else
        {
            [self release];
            self = NULL;
        }
    }
    
    return self;
}

- (void)dealloc
{
    [_filePath release];
    [super dealloc];
}

-(ICAObject)icaObject
{
    return _objectInfo.icaObject;
}

-(void)setIcaObject:(ICAObject)icaObject
{
    _objectInfo.icaObject = icaObject;
}

@end

//----------------------------------------------------------------------------------------------------------------------
