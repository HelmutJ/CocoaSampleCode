//---------------------------------------------------------------------------
//
//	File: OpenCLFile.cpp
//
//  Abstract: A utility class to obtain the contents of a file
// 			 
//  Disclaimer: IMPORTANT:  This Apple software is supplied to you by
//  Inc. ("Apple") in consideration of your agreement to the following terms, 
//  and your use, installation, modification or redistribution of this Apple 
//  software constitutes acceptance of these terms.  If you do not agree with 
//  these terms, please do not use, install, modify or redistribute this 
//  Apple software.
//  
//  In consideration of your agreement to abide by the following terms, and
//  subject to these terms, Apple grants you a personal, non-exclusive
//  license, under Apple's copyrights in this original Apple software (the
//  "Apple Software"), to use, reproduce, modify and redistribute the Apple
//  Software, with or without modifications, in source and/or binary forms;
//  provided that if you redistribute the Apple Software in its entirety and
//  without modifications, you must retain this notice and the following
//  text and disclaimers in all such redistributions of the Apple Software. 
//  Neither the name, trademarks, service marks or logos of Apple Inc. may 
//  be used to endorse or promote products derived from the Apple Software 
//  without specific prior written permission from Apple.  Except as 
//  expressly stated in this notice, no other rights or licenses, express
//  or implied, are granted by Apple herein, including but not limited to
//  any patent rights that may be infringed by your derivative works or by
//  other works in which the Apple Software may be incorporated.
//  
//  The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
//  MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
//  THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
//  FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
//  OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
//  
//  IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
//  OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
//  MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
//  AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
//  STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
// 
//  Copyright (c) 2009 Apple Inc., All rights reserved.
//
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#include <iostream>
#include <fstream>

#include "OpenCLFile.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

using namespace OpenCL;

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Data Structures

//---------------------------------------------------------------------------

class OpenCL::FileStruct
{
	public:
		char    *mpContents;
		size_t   mnContentsSize;
};

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Private - Constructors

//---------------------------------------------------------------------------

static OpenCL::FileStruct *FileCreate( const std::string &rFileName )
{
	OpenCL::FileStruct  *pFile = NULL;
	
	if( rFileName.length() )
	{
		pFile = new OpenCL::FileStruct;
		
		if( pFile != NULL )
		{
			std::ifstream iFile(rFileName.c_str(), std::ios::in|std::ios::binary|std::ios::ate);
			
			if( iFile.is_open() )
			{
				pFile->mnContentsSize = iFile.tellg();
				
				if( pFile->mnContentsSize )
				{
					pFile->mpContents = new char[pFile->mnContentsSize];
					
					if( pFile->mpContents != NULL )
					{
						iFile.seekg(0, std::ios::beg);
						
						iFile.read(pFile->mpContents, pFile->mnContentsSize);
						iFile.close();
					} // if
					else 
					{
						std::cerr << ">> ERROR: OpenCL File - \"" 
						          << rFileName 
						          << "\" failed allocating memory to read the source!" 
						          << std::endl;
					} // else
				} // if
				else 
				{
					std::cerr << ">> ERROR: OpenCL File - \"" 
					          << rFileName 
					          << "\" file has size 0!" 
							  << std::endl;
				} // else
			} // if
			else 
			{
				std::cerr << ">> ERROR: OpenCL File - \"" 
				          << rFileName 
				          << "\" not opened!" 
						  << std::endl;
			} // else
		} // if
	} // if
	else 
	{
		std::cerr << ">> ERROR: OpenCL File - NULL file name!" << std::endl;
	} // else
	
	return( pFile );
} // FileCreate

//---------------------------------------------------------------------------

static void FileRelease( OpenCL::FileStruct *pFile )
{
	if( pFile != NULL )
	{
		if( pFile->mpContents != NULL )
		{
			delete [] pFile->mpContents;
		} // if
		
		delete pFile;
		
		pFile = NULL;
	} // if
} // FileRelease

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Constructors

//---------------------------------------------------------------------------

File::File( const std::string &rFileName )
{
	mpFile = FileCreate( rFileName );
} // Constructor

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Destructor

//---------------------------------------------------------------------------

File::~File()
{
	FileRelease(mpFile);
} // Destructor

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Copy Constructor

//---------------------------------------------------------------------------

File::File( const File &rFile )
{
	if( rFile.mpFile != NULL )
	{
		mpFile = new OpenCL::FileStruct;
		
		if( mpFile != NULL )
		{
			mpFile->mnContentsSize = rFile.mpFile->mnContentsSize;
			
			mpFile->mpContents = new char[mpFile->mnContentsSize];
			
			if( mpFile->mpContents != NULL )
			{
				std::strncpy(mpFile->mpContents,
							 rFile.mpFile->mpContents,
							 rFile.mpFile->mnContentsSize);
			} // if
		} // if
	} // if
} // Copy Constructor

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Assignment Operator

//---------------------------------------------------------------------------

File &File::operator=(const File &rFile)
{
	if( ( this != &rFile ) && ( rFile.mpFile != NULL ) )
	{
		FileRelease(mpFile);
		
		mpFile = new OpenCL::FileStruct;
		
		if( mpFile != NULL )
		{
			mpFile->mnContentsSize = rFile.mpFile->mnContentsSize;
			
			mpFile->mpContents = new char[mpFile->mnContentsSize];
			
			if( mpFile->mpContents != NULL )
			{
				std::strncpy(mpFile->mpContents,
							 rFile.mpFile->mpContents,
							 rFile.mpFile->mnContentsSize);
			} // if
		} // if
	} // if
	
	return( *this );
} // Assignment Operator

//---------------------------------------------------------------------------

#pragma mark -
#pragma mark Public - Accessors

//---------------------------------------------------------------------------

const char *File::GetContents() const
{
	return( mpFile->mpContents );
} // GetContents

//---------------------------------------------------------------------------

const size_t File::GetContentsSize() const
{
	return( mpFile->mnContentsSize );
} // GetContentsSize

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
