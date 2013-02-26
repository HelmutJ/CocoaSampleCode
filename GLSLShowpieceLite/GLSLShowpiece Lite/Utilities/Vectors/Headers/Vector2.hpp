#ifndef _VECTOR2_HPP_
#define _VECTOR2_HPP_

#ifdef __cplusplus

#include <cmath>
#include <iostream>

//------------------------------------------------------------------------

//------------------------------------------------------------------------

template <typename Type>
	struct Position2 
	{
		union 
		{
			Type V[2];
			
			struct 
			{
				union { Type x, u, s; };
				union { Type y, v, t; };
			}; // union
		}; // struct
	};

//------------------------------------------------------------------------

template <typename Type>
	class Vector2
	{
		public:
		
			Vector2();
			Vector2(const Type X, const Type Y);
			Vector2(const Type *p);
			Vector2(const Position2<Type> *p);

			Vector2(const Vector2 &r);

			Vector2 operator-(Vector2 &p);
			Vector2 operator+(Vector2 &p);
			Type    operator*(Vector2 &p);  // Interior dot product
			
			Vector2 operator+(Type k);
			Vector2 operator-(Type k);
			Vector2 operator*(Type k);
			Vector2 operator/(Type k);

			Vector2 operator+=(Type k);
			Vector2 operator-=(Type k);
			Vector2 operator*=(Type k);
			Vector2 operator/=(Type k);
			
			Vector2 operator +();
			Vector2 operator -();

			Type magnitude();
			
			Vector2 normalize();
			
			void swap();

			Position2<Type> getVector( );
			
		public:
		
			union { Type x, u, s; };
			union { Type y, v, t; };
	}; // class Vector2

//------------------------------------------------------------------------

template <typename Type>
	inline Vector2<Type>::Vector2()
	{
		x = 0;
		y = 0;
	} // Default Constructor

//------------------------------------------------------------------------

template <typename Type>
	inline Vector2<Type>::Vector2(const Type X, const Type Y)
	{
		x = X;
		y = Y;
	}// Constructor

//------------------------------------------------------------------------

template <typename Type>
	inline Vector2<Type>::Vector2(const Type *p)
	{
		if( p != NULL )
		{
			x = p[0];
			y = p[1];
		} // if
		else
		{
			x = 0;
			y = 0;
		} // else
	}// Constructor

//------------------------------------------------------------------------

template <typename Type>
	inline Vector2<Type>::Vector2(const Position2<Type> *p)
	{
		if( p != NULL )
		{
			x = p->x;
			y = p->y;
		} // if
		else
		{
			x = 0;
			y = 0;
		} // else
	}// Constructor

//------------------------------------------------------------------------

template <typename Type>
	inline Vector2<Type>::Vector2(const Vector2 &p)
	{
		x = p.x;
		y = p.y;
	}// Copy Constructor

//------------------------------------------------------------------------

template <typename Type>
	inline Vector2<Type> Vector2<Type>::operator+() 
	{ 
		return *this; 
	} // Vector2::operator+()

//------------------------------------------------------------------------

template <typename Type>
	inline Vector2<Type> Vector2<Type>::operator-() 
	{ 
		Vector2 p;

		p.x = -x;
		p.y = -y;

		return p;
	} // Vector2::operator-()

//------------------------------------------------------------------------

template <typename Type>
	inline Vector2<Type> Vector2<Type>::operator-(Type k)
	{
		Vector2 p;

		p.x = x - k;
		p.y = y - k;

		return p;
	} // Vector2::operator-

//------------------------------------------------------------------------

template <typename Type>
	inline Vector2<Type> Vector2<Type>::operator-(Vector2 &p)
	{
		Vector2 q;

		q.x = x - p.x;
		q.y = y - p.y;

		return q;
	} // Vector2::operator-

//------------------------------------------------------------------------

template <typename Type>
	inline Vector2<Type> Vector2<Type>::operator+(Type k)
	{
		Vector2 p;

		p.x = x + k;
		p.y = y + k;

		return p;
	} // Vector2::operator+

//------------------------------------------------------------------------

template <typename Type>
	inline Vector2<Type> Vector2<Type>::operator+(Vector2 &p)
	{
		Vector2 q;

		q.x = x + p.x;
		q.y = y + p.y;

		return q;
	} // Vector2::operator+

//------------------------------------------------------------------------

template <typename Type>
	inline Vector2<Type> Vector2<Type>::operator*(Type k)
	{
		Vector2 p;

		p.x = x * k;
		p.y = y * k;

		return p;
	} // Vector3::operator*

//------------------------------------------------------------------------

template <typename Type>
	inline Vector2<Type> Vector2<Type>::operator/(Type k)
	{
		Vector2 p;

		p.x = x / k;
		p.y = y / k;

		return p;
	} // Vector3::operator/

//------------------------------------------------------------------------

template <typename Type>
	inline Type Vector2<Type>::operator*(Vector2 &p)
	{
		Type m;

		m = x * p.x + y * p.y;

		return m;
	} // Vector2::operator*

//------------------------------------------------------------------------

template <typename Type>
	inline Vector2<Type> Vector2<Type>::operator-=(Type k)
	{
		x -= k;
		y -= k;

		return *this;
	} // Vector2::operator*=

//------------------------------------------------------------------------

template <typename Type>
	inline Vector2<Type> Vector2<Type>::operator+=(Type k)
	{
		x += k;
		y += k;

		return *this;
	} // Vector2::operator*=

//------------------------------------------------------------------------

template <typename Type>
	inline Vector2<Type> Vector2<Type>::operator*=(Type k)
	{
		x *= k;
		y *= k;

		return *this;
	} // Vector2::operator*=

//------------------------------------------------------------------------

template <typename Type>
	inline Vector2<Type> Vector2<Type>::operator/=(Type k)
	{
		if(s != 0)
		{
			x /= k;
			y /= k;
		} // if
		else 
		{
			x = 0;
			y = 0;
		} // else

		return *this;
	} // Vector2::operator/=

//------------------------------------------------------------------------

template <typename Type>
	inline Type Vector2<Type>::magnitude()
	{
		Type l = (Type)std::sqrt(x * x + y * y);

		return l;
	} // Vector2::operator*

//------------------------------------------------------------------------

template <typename Type>
	inline Vector2<Type> Vector2<Type>::normalize()
	{
		Type l = (Type)std::sqrt(x * x + y * y);
		
		Vector2<Type> w = *this;

		if(l != 0)
		{
			w.x /= l;
			w.y /= l;
		} // if
		else 
		{
			w.x = 0;
			w.y = 0;
		} // else
		
		return w;
	} // Vector2::normalize

//------------------------------------------------------------------------

template <typename Type>
	inline Position2<Type> Vector2<Type>::getVector( )
	{
		Position2<Type> p;
		
		p.x = x;
		p.y = y;
		
		return p;
	} // Vector2::getVector

//------------------------------------------------------------------------

template <typename Type>
	inline void Vector2<Type>::swap() 
	{ 
		Type temp = x; 
		
		x = y; 
		y = temp; 
	} // Vector2<Type>::swap()

//------------------------------------------------------------------------

//------------------------------------------------------------------------

typedef Position2<int>     IPosition2;
typedef Position2<long>    LPosition2;
typedef Position2<float>   FPosition2;
typedef Position2<double>  DPosition2;

typedef Position2<long long>    LLPosition2;
typedef Position2<long double>  LDPosition2;

typedef Vector2<int>     IVector2;
typedef Vector2<long>    LVector2;
typedef Vector2<float>   FVector2;
typedef Vector2<double>  DVector2;

typedef Vector2<long long>    LLVector2;
typedef Vector2<long double>  LDVector2;

//------------------------------------------------------------------------

//------------------------------------------------------------------------


#endif

#endif
