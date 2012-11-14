/*
 <codex>
 <abstract>Pink.h</abstract>
 <\codex>
*/
class PinkFilter
{
public:
	PinkFilter() {Reset();};

	void			Reset() {buf0=buf1=buf2=buf3=buf4=buf5=buf6=0.0;};

	void 			Process(	const float	*inSourceP,
								float	*inDestP,
								int		inFramesToProcess,
								int		inInputHop,
								int		inOutputHop
								)
	{
		register int n = inFramesToProcess;
		register const float *sourceP = inSourceP;
		register float *destP = inDestP;
		
		register int inputHop = inInputHop;
		register int outputHop = inOutputHop;
		
		while(n--)
		{
			float white= *sourceP;
			sourceP += inputHop;
			
			// pink noise algorithim courtesy of 
			// http://www.firstpr.com.au/dsp/pink-noise/
			buf0= 0.99886 * buf0 + 0.0555179 * white;
			buf1= 0.99332 * buf1 + 0.0750759 * white;
			buf2= 0.96900 * buf2 + 0.1538520 * white;
			buf3= 0.86650 * buf3 + 0.3104856 * white;
			buf4= 0.55000 * buf4 + 0.5329522 * white;
			buf5= -0.7616 * buf5 + 0.0168980 * white;
			float pink=buf0 + buf1 + buf2 + buf3 + buf4  
				+ buf5 + buf6 + white * .5362;
			buf6= 0.115926 * white;
			
			*destP = pink;
			destP += outputHop;
		}
	};



private:
	float			buf0;
	float			buf1;
	float			buf2;
	float			buf3;
	float			buf4;
	float			buf5;
	float			buf6;
};


/*
Pink filter:
	white=(whichever method you choose);
	buf0=0.997 * buf0 + 0.029591 * white;
	buf1=0.985 * buf1 + 0.032534 * white;
	buf2=0.950 * buf2 + 0.048056 * white;
	buf3=0.850 * buf3 + 0.090579 * white;
	
	buf4=0.620 * buf4 + 0.108990 * white;
	buf5=0.250 * buf5 + 0.255784 * white;
	pink=buf0 + buf1 + buf2 + buf3 + buf4  
		+ buf5;
*/

#include "TRandom.h"
#include "Biquad.h"

class PinkNoiseGenerator
{
public:
	PinkNoiseGenerator(Float32 inSampleRate )
	{
		nyquist = 0.5 * inSampleRate;
		rumbleFilter.GetHipassParams(10.0/*Hertz*/ / nyquist, 0.0 );
	}
	
	void Render(Float32 *inBuffer, UInt32 inNumFrames, Float32 inVolume )
	{
		const Float32 kInv32768 = (1.0 / 32768.0) * 0.5;
		
		Float32 *destP = inBuffer;
		int n = inNumFrames;
		
		while(n--)
		{
			SInt32 r = SInt32(GetRandomLong(65536) ) - 32768;
			Float32 sample = r * kInv32768 * inVolume;
			
			*destP++ = sample;
		}
	
		
		// filter "backwards" since kernel is in reverse order
		filter.Process(	inBuffer,
						inBuffer,
						inNumFrames,
						1,
						1
						);
	
	
		// Hipass rumble filter to remove potential skanky DC offset
		rumbleFilter.Process(	inBuffer,
								inBuffer,
								inNumFrames,
								1,
								1
								);
	}


private:
	float			nyquist;
	Biquad 			rumbleFilter;
	PinkFilter 		filter;
};

/*
 *	$Log$
 *	Revision 1.2  2007/10/16 18:52:49  mtrivedi
 *	fix comment block
 *
 *	Revision 1.1  2007/04/20 19:34:30  mtrivedi
 *	first revision
 *	
 *	Revision 1.2  2005/06/05 19:46:37  luke
 *	add newline at EOF
 *	
 *	Revision 1.1  2003/07/08 22:48:46  luke
 *	new file
 *	
 */
