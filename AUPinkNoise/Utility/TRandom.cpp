/*
 <codex>
 <abstract>TRandom.h</abstract>
 <\codex>
*/
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	TRandom.cpp
//
//		a random number generator
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#include "TRandom.h"


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	TRandom::TRandom
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
TRandom::TRandom()
{
	Seed(12345);
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	TRandom::Seed
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void TRandom::Seed(UInt32 j) 
{
    UInt32 k = 1;
    mTable[54] = j;
    long i;
    for (i = 0; i < 54; i++) 
    {
        long ii = 21 * i % 55;
        mTable[ii] = k;
        k = j - k;
        j = mTable[ii];
    }
    for (int loop = 0; loop < 4; loop++) 
    {
        for (i = 0; i < 55; i++)
            mTable[i] = mTable[i] - mTable[(1 + i + 30) % 55];
    }
    mIndex1 = 0;
    mIndex2 = 31;
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#pragma mark ____EasyFunctions

static TRandom *sGenerator = NULL;

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	GetRandomLong
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
UInt32	GetRandomLong(UInt32 inRange)
{
	if (sGenerator == NULL)
		sGenerator = new TRandom(kRandomSeed);
	return (*sGenerator)(inRange);
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	GetRandomLong
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
UInt32	GetRandomLong(UInt32 inLowerLimit, UInt32 inUpperLimit )
{
	UInt32 value = GetRandomLong(inUpperLimit - inLowerLimit );
	
	return value + inLowerLimit;
}

/*
 *	$Log$
 *	Revision 1.2  2007/10/16 19:44:05  mtrivedi
 *	fix comment blocks
 *
 *	Revision 1.1  2007/04/20 19:34:31  mtrivedi
 *	first revision
 *	
 *	Revision 1.1  2005/03/31 18:23:51  luke
 *	TRandom.mm -> TRandom.cpp
 *	
 */
