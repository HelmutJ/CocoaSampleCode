/*
 <codex>
 <abstract>ComplexNumber.h</abstract>
 <\codex>
*/
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	ComplexNumber.h
//
//		a useful complex number class
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#ifndef __CoreAudio_ComplexNumber
#define __CoreAudio_ComplexNumber

#include <math.h>
#include <stdio.h>

class Complex
{
public:
	Complex()
		: mReal(0.0), mImag(0.0) {};
	
	Complex(double inReal, double inImag )
		: mReal(inReal), mImag(inImag) {};

	Complex(float inReal)				// construct complex from real
		: mReal(inReal), mImag(0) {};
		


	double			GetReal() const {return mReal;};
	double			GetImag() const {return mImag;};
	void			SetReal(double inReal) {mReal = inReal;};
	void			SetImag(double inImag) {mImag = inImag;};
	
	double			Phase() const {return atan2(mImag, mReal);};
	double			GetPhase() const {return atan2(mImag, mReal);};
	double			Magnitude() const {return sqrt(mImag*mImag + mReal*mReal);};
	double			GetMagnitude() const {return sqrt(mImag*mImag + mReal*mReal);};
	
	
	void			SetMagnitudePhase(double inMagnitude, double inPhase)
	{
		mReal = inMagnitude * cos(inPhase);
		mImag = inMagnitude * sin(inPhase);
	};

	
	Complex			Pow(double inPower)
	{
		double mag = GetMagnitude();
		double phase = GetPhase();
		
		Complex result;
		result.SetMagnitudePhase(pow(mag, inPower), phase*inPower );
		
		return result;
	};
	
	Complex			GetConjugate() const {return Complex(mReal, -mImag);};
	
	
	Complex			inline operator += (const Complex &a);
	Complex			inline operator -= (const Complex &a);


	void			Print() {printf("(%f,%f)", mReal, mImag ); };
	void			PrintMagnitudePhase() {printf("(%f,%f)\n", GetMagnitude(), GetPhase() ); };
	
	
	double			mReal;
	double			mImag;
};

Complex			inline operator+ (const Complex &a, const Complex &b )
	{return Complex(a.GetReal() + b.GetReal(), a.GetImag() + b.GetImag() ); };

Complex			inline operator - (const Complex &a, const Complex &b )
	{return Complex(a.GetReal() - b.GetReal(), a.GetImag() - b.GetImag() ); };
	
Complex			inline operator * (const Complex &a, const Complex &b )
	{return Complex(	a.GetReal()*b.GetReal() - a.GetImag()*b.GetImag(),
						a.GetReal()*b.GetImag() + a.GetImag()*b.GetReal() ); };
	
Complex			inline operator * (const Complex &a, double b)
	{return Complex(a.GetReal()*b, a.GetImag()*b );};
	
Complex			inline operator * (double b, const Complex &a )
	{return Complex(a.GetReal()*b, a.GetImag()*b );};
	
Complex			inline operator/(const Complex& a, const Complex& b)
{
	double mag1 = a.GetMagnitude();
	double mag2 = b.GetMagnitude();
	
	double phase1 = a.GetPhase();
	double phase2 = b.GetPhase();
	
	Complex c;
	c.SetMagnitudePhase(mag1/mag2, phase1 - phase2 );
	
	return c;
}

Complex			inline Complex::operator += (const Complex &a)
{
	*this = *this + a;
	return *this;
};

Complex			inline Complex::operator -= (const Complex &a)
{
	*this = *this - a;
	return *this;
};

bool			inline	operator == (const Complex &a, const Complex &b )
{
	return a.GetReal() == b.GetReal() && a.GetImag() == b.GetImag();
}

inline Complex		UnitCircle(double mag, double phase)
{
	return Complex(mag * cos(phase), mag * sin(phase) );
}

#endif // __ComplexNumber

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
