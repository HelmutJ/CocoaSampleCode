/*
 <codex>
 <abstract>Biquad.h</abstract>
 <\codex>
*/
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	Biquad.cpp
//
//		A generic biquad (two zero - two pole) IIR filter:
//
//			lopass
//			hipass
//			parametric peaking
//			low shelving
//			high shelving
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#include "Biquad.h"
#include "ComplexNumber.h"
#include <math.h>

#define _PI 3.14159
const float kSquareRootOf2 = sqrt(2.);


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	Biquad::GetK()
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
static void GetK(	float inFreq,		// normalized to 0 -> 1
					float &outK,
					float &outKSquared,
					float &outInvDenom )
{
	float k = tan(_PI*0.5 * inFreq);
	outK = k;
	outKSquared = k*k;
	
	outInvDenom = 1.0 / (1 + kSquareRootOf2*k + outKSquared );
}


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	Biquad::GetLopassParams()
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void Biquad::GetLopassParams(	float inFreq,
								float &a0,
								float &a1,
								float &a2,
								float &b1,
								float &b2  )
{
	float k;
	float k_squared;
	float inv_denom;
	GetK(inFreq, k, k_squared, inv_denom );

	
	a0 = k_squared * inv_denom;
	a1 = 2 * k_squared * inv_denom;
	a2 = k_squared * inv_denom;
	b1 = 2*(k_squared-1) * inv_denom;
	b2 = (1 - kSquareRootOf2*k + k_squared)  * inv_denom;
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	Biquad::GetLopassParams()
//
//		This version accepts a resonance parameter
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void Biquad::GetLopassParams(	float inFreq,
                                float inResonance,
								float &a0,
								float &a1,
								float &a2,
								float &b1,
								float &b2  )
{
    double d = pow(10.0, -inResonance/20.0);
    
    double temp = 0.5 * d * sin(_PI * inFreq);
    double beta = 0.5 * (1.0 - temp) / (1.0 + temp);
    double gamma = (0.5 + beta) * cos(_PI * inFreq);
    double alpha = (0.5 + beta - gamma) * 0.25;
    
    a0 = 2.0 *   alpha;
    a1 = 2.0 *   2.0 * alpha;
    a2 = 2.0 *   alpha;
    b1 = 2.0 *   -gamma;
    b2 = 2.0 *   beta;
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	Biquad::GetNotchParams()
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void Biquad::GetNotchParams(	float inFreq,
                                float inQ )
{
	// restrict Q
	const double kQLimit = inFreq + 0.01;
	
	if(inQ < kQLimit) inQ = kQLimit;
	
	double theta0 = _PI * inFreq;
	double temp = tan(theta0/(2.0*inQ) );
	double beta = 0.5 * (1.0 - temp) / (1.0 + temp);
	
	double gamma = (0.5 + beta) * cos(theta0);
	double alpha = 0.5 * (0.5 + beta);
	
	mA0 = 2.0 *	alpha;
	mA1 = 2.0 *	-gamma;
	mA2 = 2.0 *	alpha;
	mB1 = 2.0 *	-gamma;
	mB2 = 2.0 *	beta; 

}


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	Biquad::GetHipassParams()
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void Biquad::GetHipassParams(	float inFreq,
								float &a0,
								float &a1,
								float &a2,
								float &b1,
								float &b2  )
{
	float k;
	float k_squared;
	float inv_denom;
	GetK(inFreq, k, k_squared, inv_denom );
	
	a0 = inv_denom;
	a1 = -2 * inv_denom;
	a2 = inv_denom;
	b1 = 2*(k_squared-1) * inv_denom;
	b2 = (1 - kSquareRootOf2*k + k_squared)  * inv_denom;
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	Biquad::GetHipassParams()
//
//		This version accepts a resonance parameter
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void Biquad::GetHipassParams(	float inFreq,
                                float inResonance,
								float &a0,
								float &a1,
								float &a2,
								float &b1,
								float &b2  )
{
    double d = pow(10.0, -inResonance/20.0);
    
    double temp = 0.5 * d * sin(_PI * inFreq);
    double beta = 0.5 * (1.0 - temp) / (1.0 + temp);
    double gamma = (0.5 + beta) * cos(_PI * inFreq);
    double alpha = (0.5 + beta + gamma) * 0.25;
    
    a0 = 2.0 *   alpha;
    a1 = 2.0 *   -2.0 * alpha;
    a2 = 2.0 *   alpha;
    b1 = 2.0 *   -gamma;
    b2 = 2.0 *   beta;
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	Biquad::GetLowShelfParams()
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void Biquad::GetLowShelfParams(		float inFreq,
									float inDbGain,			// +/- 40dB
									float &outA0,
									float &outA1,
									float &outA2,
									float &outB1,
									float &outB2)
{
	float freq = inFreq;

	float omega = _PI * freq;
	float gain = inDbGain;


    float sn    = sin(omega);
    float cs    = cos(omega);

	float S = 1.0;
    float A     =  pow(10.0, (gain * 0.025 ) );
	
	float Am = A - 1.0;
	float Ap = A + 1.0;
    float beta  = sqrt( (A*A + 1.0)/S - Am*Am );

    float b0 =    A*( Ap - Am*cs + beta*sn );
    float b1 =  2*A*( Am - Ap*cs           );
    float b2 =    A*( Ap - Am*cs - beta*sn );
    float a0 =        Ap + Am*cs + beta*sn;
    float a1 =   -2*( Am + Ap*cs           );
    float a2 =        Ap + Am*cs - beta*sn;
    
    float a0_inv = 1.0 / a0;
    
	// this looks wrong, but it's OK
    outA0 = b0*a0_inv;
    outA1 = b1*a0_inv;
    outA2 = b2*a0_inv;
    outB1 = a1*a0_inv;
    outB2 = a2*a0_inv; 
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	Biquad::GetHighShelfParams()
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void Biquad::GetHighShelfParams(	float inFreq,
									float inDbGain,			// +/- 40dB
									float &outA0,
									float &outA1,
									float &outA2,
									float &outB1,
									float &outB2)
{
	float freq = inFreq;

	float omega = _PI * freq;
	float gain = inDbGain;


    float sn    = sin(omega);
    float cs    = cos(omega);

	float S = 1.0;
    float A     =  pow(10.0, (gain * 0.025 ) );
	
	float Am = A - 1.0;
	float Ap = A + 1.0;
    float beta  = sqrt( (A*A + 1.0)/S - Am*Am );

    float b0 =    A*( Ap + Am*cs + beta*sn );
    float b1 = -2*A*( Am + Ap*cs           );
    float b2 =    A*( Ap + Am*cs - beta*sn );
    float a0 =        Ap - Am*cs + beta*sn;
    float a1 =    2*( Am - Ap*cs           );
    float a2 =        Ap - Am*cs - beta*sn;
    
    float a0_inv = 1.0 / a0;
    
	// this looks wrong, but it's OK
    outA0 = b0*a0_inv;
    outA1 = b1*a0_inv;
    outA2 = b2*a0_inv;
    outB1 = a1*a0_inv;
    outB2 = a2*a0_inv; 
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	Biquad::Biquad()
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Biquad::Biquad()
{
	mA0 = 1.0;
	mA1 = 0.0;
	mA2 = 0.0;
	mB1 = 0.0;
	mB2 = 0.0;

	Reset();
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	Biquad::Reset()
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void Biquad::Reset()
{	
	mX1 = 0.0;
	mX2 = 0.0;
	mY1 = 0.0;
	mY2 = 0.0;
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	Biquad::GetLopassParams()
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void	Biquad::GetLopassParams(	float inFreq )
{
	GetLopassParams(inFreq, mA0, mA1, mA2, mB1, mB2 );
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	Biquad::GetLopassParams()
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void	Biquad::GetLopassParams(	float inFreq, float inResonance )
{
	GetLopassParams(inFreq, inResonance, mA0, mA1, mA2, mB1, mB2 );
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	Biquad::GetHipassParams()
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void	Biquad::GetHipassParams(	float inFreq )
{
	GetHipassParams(inFreq, mA0, mA1, mA2, mB1, mB2 );
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	Biquad::GetHipassParams()
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void	Biquad::GetHipassParams(	float inFreq, float inResonance )
{
	GetHipassParams(inFreq, inResonance, mA0, mA1, mA2, mB1, mB2 );
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	Biquad::GetLowShelfParams()
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void	Biquad::GetLowShelfParams(	float inFreq, float inDbGain )
{
	GetLowShelfParams(inFreq, inDbGain, mA0, mA1, mA2, mB1, mB2 );
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	Biquad::GetHighShelfParams()
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void	Biquad::GetHighShelfParams(	float inFreq, float inDbGain )
{
	GetHighShelfParams(inFreq, inDbGain, mA0, mA1, mA2, mB1, mB2 );
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	Biquad::GetAllpassParams()
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void	Biquad::GetAllpassParams( const Complex	&inComplexPole )
{
	SetPoleConjugateRoot(inComplexPole);

	mA0 = mB2;
	mA1 = mB1;
	mA2 = 1.0; /* mB0 */
}



//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	Biquad::PolarToRect()
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void	Biquad::PolarToRect(	float	inTheta,
								float	inMag,
								float	&outX,
								float	&outY	)
{
	outX = cos(inTheta) * inMag;
	outY = sin(inTheta) * inMag;
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	Biquad::ConjugateRootToQuadCoeffs()
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void	Biquad::ConjugateRootToQuadCoeffs(	float	inTheta,
											float	inMag,
											float	&out0,
											float	&out1,
											float	&out2	)
{
	float x;
	float y;
	PolarToRect(inTheta, inMag, x, y );
	
	out0 = 1.0;
	out1 = -2.0 * x;
	out2 = x*x + y*y;
}


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	Biquad::RealRootsToQuadCoeffs()
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void	Biquad::RealRootsToQuadCoeffs(	float	inRoot1,
										float	inRoot2,
										float	&out0,
										float	&out1,
										float	&out2	)
{
	// (x - inRoot1) * (x - inRoot2)
	//
	// x^2 + (-inRoot1 -inRoot2)*x + inRoot1*inRoot2
	//
	
	out0 = 1.0;
	out1 = -inRoot1 -inRoot2;
	out2 = inRoot1*inRoot2;
}




//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	Biquad::SetZeroConjugateRoot()
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void	Biquad::SetZeroConjugateRoot(	float	inZeroTheta,
										float	inZeroMag )
{
	
	mA0 = 0.0;
	mA1 = 0.0;
	mA2 = 0.0;
	
	ConjugateRootToQuadCoeffs(inZeroTheta, inZeroMag, mA0, mA1, mA2 );
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	Biquad::SetPoleConjugateRoot()
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void	Biquad::SetPoleConjugateRoot(	float	inPoleTheta,
										float	inPoleMag )
{
	mB1 = 0.0;
	mB2 = 0.0;
	
	float b0;
	
	ConjugateRootToQuadCoeffs(inPoleTheta, inPoleMag, b0, mB1, mB2 );
}


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	Biquad::SetZeroConjugateRoot()
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void	Biquad::SetZeroConjugateRoot(	const Complex	&inComplexZero)
{
	mA0 = 1.0;
	mA1 = -2.0 * inComplexZero.GetReal();
	
	double mag = inComplexZero.GetMagnitude();
	
	mA2 = mag*mag;
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	Biquad::SetPoleConjugateRoot()
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void	Biquad::SetPoleConjugateRoot(	const Complex	&inComplexPole)
{
	mB1 = -2.0 * inComplexPole.GetReal();
	
	double mag = inComplexPole.GetMagnitude();

	mB2 = mag*mag;
}


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	Biquad::SetZeroRealRoots()
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void	Biquad::SetZeroRealRoots(	float	inRoot1,
									float	inRoot2  )
									
{
	RealRootsToQuadCoeffs(	inRoot1,
							inRoot2,
							mA0,
							mA1,
							mA2	);
}


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	Biquad::SetPoleRealRoots()
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void	Biquad::SetPoleRealRoots(	float	inRoot1,
									float	inRoot2  )
									
{
	float b0;

	RealRootsToQuadCoeffs(	inRoot1,
							inRoot2,
							b0,
							mB1,
							mB2	);
}

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	Biquad::Process()
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
void Biquad::Process(	const float	*inSourceP,
                            float	*inDestP,
                            int		inFramesToProcess,
                            int		inInputNumberOfChannels,
                            int		inOutputNumberOfChannels
                            )
{
	int nSampleFrames = inFramesToProcess;
	const float *sourceP = inSourceP;
	float *destP = inDestP;
	register float x1, y1, x2, y2;
	register float a0, a1, a2, b1, b2;
        
        //load class data into register
        x1 = mX1;
        y1 = mY1;
        x2 = mX2;
        y2 = mY2;
        a0 = mA0;
        a1 = mA1;
        a2 = mA2;
        b1 = mB1;
        b2 = mB2;

         
        if( nSampleFrames >= 4 )
        {
            register float xA, xB, xC, xD, xE;
            register float stage1, stage2, stage3, stage4, stage5A, stage5B, temp;
    
        //
        //  In this section we process bulk data in a staggered loop. The calculation
        //  that we do is fairly simply written as:
        //
        //	while(nSampleFrames-- > 0)
	//	{
        //	    float x = *sourceP;
        //	    sourceP += inInputNumberOfChannels;
        //	    
        //	    float y = a0*x + a1*x1 + a2*x2 - b1*y1 - b2*y2;
        //
        //	    x2 = x1;
        //	    x1 = x;
        //	    y2 = y1;
        //	    y1 = y;
        //	    
        //	    *destP = y;
        //	    destP += inOutputNumberOfChannels;
	//	}
        //
        //  In order to pad out all of the serial data stalls with work, the
        //  loop is reorganized as a staggered loop.  The main calculation:
        //
        //	 float y = a0*x + a1*x1 + a2*x2 - b1*y1 - b2*y2;
        //
        //  ...is performed by the compiler as five instructions:
        //
        //	fmulls	stage1, a0, x			#stage 1
        //	fmadds	stage2, a1, x1, stage1		#stage 2
        //	fmadds	stage3, a2, x2, stage2		#stage 3
        //	fnmsubs	stage4, b1, y1, stage3		#stage 4
        //	fnmsubs stage5, b2, y2, stage4		#stage 5
        //
        //  The each calculation depends on the result from the last
        //  so there are a lot of serial data dependencies causing 
        //  pipeline stalls here. In addition, as y1 and y2 depend on
        //  the results of the previous calculation, there is a dependency
        //  there too.
        //
        //  To loosen up all of this dependency so that we can execute
        //  with a minimum of pipeline stalls, we make use of staggered
        //  loops.
        //
        //  A staggered loop is organized such that at any given time, we are
        //  calculating 5 results, and each of the five calculations is 
        //  currently working on a different stage. It is in some ways analogous
        //  to a processor pipeline, with loop iterations in place of clock cycles:
        //
        //		stage 1		stage 2		stage 3		stage 4		stage 5		store result
        //		-------		-------		-------		-------		-------		------------
        //  iter 1:	calc 1  --->
        //  iter 2:	calc 2		calc 1  --->
        //  iter 3:	calc 3		calc 2		calc 1  --->
        //  iter 4:	calc 4		calc 3		calc 2		calc 1  --->
        //  iter 5:	calc 5		calc 4		calc 3		calc 2		calc 1  --->
        //  iter 6:	calc 6		calc 5		calc 4		calc 3		calc 2		calc 1 stored
        //  .
        //  .
        //  .	
        //
        //  In order to achieve this in software, we have to do the first 4 loop iterations
        //  separately to avoid writing out garbage data while we wait for the pipeline to fill.
        //  That is what we do first:
    
        //Build up a staggered loop
            //pseudo loop iteration 1
            xA = sourceP[0]; sourceP += inInputNumberOfChannels;
            stage1 = a0 * xA;
            
            //pseudo loop iteration 2
            xB = sourceP[0]; sourceP += inInputNumberOfChannels;
            stage2 = stage1 + a1 * x1;
            stage1 = a0 * xB;
            
            //pseudo loop iteration 3
            xC = sourceP[0]; sourceP += inInputNumberOfChannels;
            stage3 = stage2 + a2 * x2;
            stage2 = stage1 + a1 * xA;
            stage1 = a0 * xC;
            
            //pseudo loop iteration 4
            xD = sourceP[0]; sourceP += inInputNumberOfChannels;
            stage4 = stage3 - b1 * y1;
            stage3 = stage2 + a2 * x1;
            stage2 = stage1 + a1 * xB;
            stage1 = a0 * xD;
          
            
        //  
        //  Now the pipeline is full, so we can loop as long as we have data
        //  to work on.  Once a piece of data is loaded in from the input array,
        //  it is used three times over a total of 5 loop iterations. For that reason
        //  the loop is unrolled here five fold. If we dont do that then we waste lots 
        //  of time copying registers around. This lets us do each loop iteration 
        //  in only six cycles on PPC 7400 / 7410. It is probably 5 on PPC 7450.
        //
        
            //Set up a little bit of data for entry into the loop
            stage5A = y2;
            stage5B = y1;
            nSampleFrames -= 4;
            
        // Execute a staggered loop until we run out of input samples
            while( nSampleFrames >= 5 )
            {
                //pseudo loop 5
                xE = sourceP[0]; 	sourceP += inInputNumberOfChannels;
                stage5A = stage4 - b2 * stage5A;
                stage4  = stage3 - b1 * stage5A;
                stage3  = stage2 + a2 * xA;
                stage2  = stage1 + a1 * xC;
                stage1  = a0 * xE;
                destP[0] = stage5A;	destP += inOutputNumberOfChannels;
                
                //pseudo loop 6
                xA = sourceP[0]; 	sourceP += inInputNumberOfChannels;
                stage5B = stage4 - b2 * stage5B;
                stage4  = stage3 - b1 * stage5B;
                stage3  = stage2 + a2 * xB;
                stage2  = stage1 + a1 * xD;
                stage1  = a0 * xA;
                destP[0] = stage5B;	destP += inOutputNumberOfChannels;
                
                //pseudo loop 7
                xB = sourceP[0]; 	sourceP += inInputNumberOfChannels;
                stage5A = stage4 - b2 * stage5A;
                stage4  = stage3 - b1 * stage5A;
                stage3  = stage2 + a2 * xC;
                stage2  = stage1 + a1 * xE;
                stage1  = a0 * xB;
                destP[0] = stage5A;	destP += inOutputNumberOfChannels;
                
                //These last two are slightly different. That is because we have
                //five subloops in the loop, which means that our stage5A, stage5B
                //oscillation comes out odd instead of even. 
                //
                //The simple solution is to swap stage5A and stage5B at the end of the large
                //loop:
                //
                //	temp = stage5B;
                //	stage5B = stage5A;
                //	stage5A = temp;
                //
                //However it is more efficient to do the swap as we do the calculation
                //since this means we dont have to call fmr as much. Thus, in this
                //next pseudo loop, temp receives the result of the stage 5 calculation
                //instead of stage5B. 
                
                //pseudo loop 8
                xC = sourceP[0]; 	sourceP += inInputNumberOfChannels;
                temp   = stage4 - b2 * stage5B;	
                stage4 = stage3 - b1 * temp;
                stage3 = stage2 + a2 * xD;
                stage2 = stage1 + a1 * xA;
                stage1 = a0 * xC;
                destP[0] = temp /*stage5B*/;	destP += inOutputNumberOfChannels;
                
                //
                // In this pseudo loop, our swap continues: stage5B receives the 
                // stage5 result, rather than stage5A
                //
                
                //pseudo loop 9
                xD = sourceP[0]; 	sourceP += inInputNumberOfChannels;
                stage5B = stage4 - b2 * stage5A;
                stage4  = stage3 - b1 * stage5B;
                stage3  = stage2 + a2 * xE;
                stage2  = stage1 + a1 * xB;
                stage1  = a0 * xD;
                destP[0] = stage5B /*stage5A*/;	destP += inOutputNumberOfChannels;
            
                //The final step in the swap
                stage5A = temp;
                
                //decrement our loop counter
                nSampleFrames -= 5;
            }
        
        //
        //  Now we have to deal with the problem that we have no input data coming in
        //  so we need more special case code as the pipeline empties. We cant just reuse the
        //  internal loop code because the loads would step off the end of the array on to
        //  possible unmapped memory. 
        //
        //  Here we finish out the last four stages for our four remaining calculations:
        //    
        
            //trailing pseudo loop 1
            stage5A = stage4 - b2 * stage5A;
            stage4 = stage3 - b1 * stage5A;
            stage3 = stage2 + a2 * xA;
            stage2 = stage1 + a1 * xC;
            destP[0] = stage5A;	destP += inOutputNumberOfChannels;
            
            //trailing pseudo loop 2
            stage5B = stage4 - b2 * stage5B;
            stage4 = stage3 - b1 * stage5B;
            stage3 = stage2 + a2 * xB;
            destP[0] = stage5B;	destP += inOutputNumberOfChannels;
            
            //trailing pseudo loop 3
            stage5A = stage4 - b2 * stage5A;
            stage4 = stage3 - b1 * stage5A;
            destP[0] = stage5A;	destP += inOutputNumberOfChannels;
            
            //trailing pseudo loop 4
            stage5B = stage4 - b2 * stage5B;
            destP[0] = stage5B;	destP += inOutputNumberOfChannels;

            //Put our data back into x1, y1, x2 and y2
            x1 = xD;
            x2 = xC;
            y1 = stage5B;
            y2 = stage5A;
        }
        
    //Deal with the last few frames
        //This calculation is the same as the one above, but since
        //we dont have enough data to do anything fancy, 
        //we just do the simple variant here:
	while(nSampleFrames-- > 0)
	{
            float x = *sourceP;
            sourceP += inInputNumberOfChannels;
            
            float y = a0*x + a1*x1 + a2*x2 - b1*y1 - b2*y2;

            x2 = x1;
            x1 = x;
            y2 = y1;
            y1 = y;
            
            *destP = y;
            destP += inOutputNumberOfChannels;
	}
        
        //save our register values for x1, y1, x2, and y2 for posterity
        mX1 = x1;
        mY1 = y1;
        mX2 = x2;
        mY2 = y2;
}

/*
 *	$Log$
 *	Revision 1.2  2007/10/16 19:44:05  mtrivedi
 *	fix comment blocks
 *
 *	Revision 1.1  2007/04/20 19:34:30  mtrivedi
 *	first revision
 *	
 *	Revision 1.1  2003/07/08 22:48:46  luke
 *	new file
 *	
 */
