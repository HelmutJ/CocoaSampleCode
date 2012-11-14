/*
 <codex>
 <abstract>Biquad.h</abstract>
 <\codex>
*/
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	Biquad.h
//
//		A generic biquad (two zero - two pole) IIR filter:
//
//			lopass
//			hipass
//			parametric peaking
//			low shelving
//			high shelving
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#ifndef __Biquad
#define __Biquad

#include <math.h>
#include <stdio.h>

class Complex;


class Biquad
{
public:
	Biquad();
	
	void			Reset();
	
	static void		GetLopassParams(	float inFreq,
										float &a0,
										float &a1,
										float &a2,
										float &b1,
										float &b2  );

	// version which also has resonance parameter
	static void		GetLopassParams(	float inFreq,
		                                float inResonance,
										float &a0,
										float &a1,
										float &a2,
										float &b1,
										float &b2  );

	static void		GetHipassParams(	float inFreq,
										float &a0,
										float &a1,
										float &a2,
										float &b1,
										float &b2  );

	// version which also has resonance parameter
	static void 	GetHipassParams(	float inFreq,
		                                float inResonance,
										float &a0,
										float &a1,
										float &a2,
										float &b1,
										float &b2  );


	static void		GetLowShelfParams(	float inFreq,
										float inDbGain,			// +/- 40dB
										float &outA0,
										float &outA1,
										float &outA2,
										float &outB1,
										float &outB2);

	static void		GetHighShelfParams(	float inFreq,
										float inDbGain,			// +/- 40dB
										float &outA0,
										float &outA1,
										float &outA2,
										float &outB1,
										float &outB2);


	void			GetLopassParams(	float inFreq );
	void			GetLopassParams(	float inFreq, float inResonance );
	void			GetHipassParams(	float inFreq );
	void			GetHipassParams(	float inFreq, float inResonance );
	
	void			GetLowShelfParams(	float inFreq, float inDbGain );
	void			GetHighShelfParams(	float inFreq, float inDbGain );
	
	
	
	void			GetAllpassParams( const Complex	&inComplexPole );


	void 			GetNotchParams(	float inFreq,
                                	float inQ );
                                	

	static void		PolarToRect(	float	inTheta,
									float	inMag,
									float	&outX,
									float	&outY	);

	static void		ConjugateRootToQuadCoeffs(	float	inTheta,
												float	inMag,
												float	&out0,
												float	&out1,
												float	&out2	);
										
	static void		RealRootsToQuadCoeffs(	float	inRoot1,
											float	inRoot2,
											float	&out0,
											float	&out1,
											float	&out2	);

										
	void			SetZeroConjugateRoot(	float	inZeroTheta,
											float	inZeroMag  );
												
	void			SetPoleConjugateRoot(	float	inPoleTheta,
											float	inPoleMag );
												
	void			SetZeroConjugateRoot(	const Complex	&inComplexZero  );
												
	void			SetPoleConjugateRoot(	const Complex	&inComplexPole );



	void			SetZeroRealRoots(	float	inRoot1,
										float	inRoot2  );
										
	void			SetPoleRealRoots(	float	inRoot1,
										float	inRoot2  );

											
											
										
	void 			Process(	const float	*inSourceP,
								float	*inDestP,
								int		inFramesToProcess,
								int		inInputNumberOfChannels,
								int		inOutputNumberOfChannels
								);

	inline float Process1(	float	x)
	{
		float y = mA0*x + mA1*mX1 + mA2*mX2 - mB1*mY1 - mB2*mY2;

		mX2 = mX1;
		mX1 = x;
		mY2 = mY1;
		mY1 = y;
		
		return y;
	}


private:
	float	mA0;
	float	mA1;
	float	mA2;
	float	mB1;
	float	mB2;
	
	float	mX1;
	float	mX2;
	float	mY1;
	float	mY2;
};

const double kInv1200 = 1.0 / 1200.0;
const double kInv440 = 1.0 / 440.0;
const double kInvLog2 = 1.0 / log(2.0);

inline double	AbsoluteCentsToHertz(double inAbsCents) {return 440.0 * pow(2.0, (inAbsCents - 6900.0) * kInv1200 );};
inline double	HertzToAbsoluteCents(double inHertz) {return 1200.0 * kInvLog2 * log(inHertz * kInv440) + 6900.0;};
#define kMinAbsoluteCents	1200.0 /* 0 is approx 8.175799Hz :: 1200.0 is approx 16Hz */
#define kMaxAbsoluteCents	15023.0 /* approx 48000Hz */



#endif // __Biquad

/*
 *	$Log$
 *	Revision 1.2  2007/10/16 18:39:05  mtrivedi
 *	fix comment block
 *
 *	Revision 1.1  2007/04/20 19:34:30  mtrivedi
 *	first revision
 *	
 *	Revision 1.1  2003/07/08 22:48:46  luke
 *	new file
 *	
 */
