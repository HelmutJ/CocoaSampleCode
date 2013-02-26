#ifndef _VECTOR3_HPP_
#define _VECTOR3_HPP_

#ifdef __cplusplus

#include <cmath>
#include <iostream>

#include "Vector2.hpp"

//------------------------------------------------------------------------

//------------------------------------------------------------------------

template <typename Type>
	struct Position3 
	{
		union 
		{
			Type V[3];
			
			struct 
			{
				Type x;
				Type y;
				Type z;
			}; // union
		}; // struct
	};

//------------------------------------------------------------------------

template <typename Type>
	class Vector3
	{
		public:
		
			Vector3();
			Vector3(const Type X, const Type Y, const Type Z);
			Vector3(const Type *v);
			Vector3(const Position2<Type> &p);
			Vector3(const Position2<Type> *p);
			Vector3(const Position3<Type> &p);
			Vector3(const Position3<Type> *p);
			Vector3(const Vector2<Type> &v);
			Vector3(const Vector2<Type> *v);

			Vector3(const Vector3 &v);

			Vector3 operator-(Vector3 &v);
			Vector3 operator+(Vector3 &v);
			Type    operator*(Vector3 &v);  // Interior dot product
			Vector3 operator^(Vector3 &v);  // Exterior cross product

			Vector3 operator-(Type t);
			Vector3 operator+(Type t);
			Vector3 operator*(Type s);
			Vector3 operator/(Type s);
			
			Vector3 operator+=(Type t);
			Vector3 operator-=(Type t);
			Vector3 operator*=(Type s);
			Vector3 operator/=(Type s);
			
			Vector3 operator+();
			Vector3 operator-();

			Type magnitude();
			
			Vector3 normalize();
			Vector3 normals(Vector3 &v, Vector3 &w);
			Vector3 normals(Position3<Type> &q, Position3<Type> &r);
			
			Position3<Type> getVector( );
			
		public:
			
			Type x;
			Type y;
			Type z;
	}; // class Vector3

//------------------------------------------------------------------------

template <typename Type>
	inline Vector3<Type>::Vector3()
	{
		x = 0;
		y = 0;
		z = 0;
	} // Default Constructor

//------------------------------------------------------------------------

template <typename Type>
	inline Vector3<Type>::Vector3(const Type X, const Type Y, const Type Z)
	{
		x = X;
		y = Y;
		z = Z;
	}// Constructor

//------------------------------------------------------------------------

template <typename Type>
	inline Vector3<Type>::Vector3(const Vector2<Type> &v)
	{
		x = v.x;
		y = v.y;
		z = 0;
	}// Constructor

//------------------------------------------------------------------------

template <typename Type>
	inline Vector3<Type>::Vector3(const Vector2<Type> *v)
	{
		if( v != NULL )
		{
			x = v->x;
			y = v->y;
		} // if
		else
		{
			x = 0;
			y = 0;
		} // else
		
		z = 0;
	}// Constructor

//------------------------------------------------------------------------

template <typename Type>
	inline Vector3<Type>::Vector3(const Type *v)
	{
		if( v != NULL )
		{
			x = v[0];
			y = v[1];
			z = v[2];
		} // if
		else
		{
			x = 0;
			y = 0;
			z = 0;
		} // else
	}// Constructor

//------------------------------------------------------------------------

template <typename Type>
	inline Vector3<Type>::Vector3(const Position2<Type> &p)
	{
		x = p.x;
		y = p.y;
		z = 0;
	}// Constructor

//------------------------------------------------------------------------

template <typename Type>
	inline Vector3<Type>::Vector3(const Position2<Type> *p)
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

		z = 0;
	}// Constructor

//------------------------------------------------------------------------

template <typename Type>
	inline Vector3<Type>::Vector3(const Position3<Type> &p)
	{
		x = p.x;
		y = p.y;
		z = p.z;
	}// Constructor

//------------------------------------------------------------------------

template <typename Type>
	inline Vector3<Type>::Vector3(const Position3<Type> *p)
	{
		if( p != NULL )
		{
			x = p->x;
			y = p->y;
			z = p->z;
		} // if
		else
		{
			x = 0;
			y = 0;
			z = 0;
		} // else
	}// Constructor

//------------------------------------------------------------------------

template <typename Type>
	inline Vector3<Type>::Vector3(const Vector3 &v)
	{
		x = v.x;
		y = v.y;
		z = v.z;
	}// Copy Constructor

//------------------------------------------------------------------------

template <typename Type>
	inline Vector3<Type> Vector3<Type>::operator+() 
	{ 
		return *this; 
	} // Vector2::operator+()

//------------------------------------------------------------------------

template <typename Type>
	inline Vector3<Type> Vector3<Type>::operator-() 
	{ 
		Vector3 p;

		p.x = -x;
		p.y = -y;
		p.z = -z;

		return p;
	} // Vector2::operator-()

//------------------------------------------------------------------------

template <typename Type>
	inline Vector3<Type> Vector3<Type>::operator-(Type t)
	{
		Vector3 w;

		w.x = x - t;
		w.y = y - t;
		w.z = z - t;

		return w;
	} // Vector3::operator-

//------------------------------------------------------------------------

template <typename Type>
	inline Vector3<Type> Vector3<Type>::operator-(Vector3 &v)
	{
		Vector3 w;

		w.x = x - v.x;
		w.y = y - v.y;
		w.z = z - v.z;

		return w;
	} // Vector3::operator-

//------------------------------------------------------------------------

template <typename Type>
	inline Vector3<Type> Vector3<Type>::operator+(Type t)
	{
		Vector3 w;

		w.x = x + t;
		w.y = y + t;
		w.z = z + t;

		return w;
	} // Vector3::operator+

//------------------------------------------------------------------------

template <typename Type>
	inline Vector3<Type> Vector3<Type>::operator+(Vector3 &v)
	{
		Vector3 w;

		w.x = x + v.x;
		w.y = y + v.y;
		w.z = z + v.z;

		return w;
	} // Vector3::operator+

//------------------------------------------------------------------------

template <typename Type>
	inline Vector3<Type> Vector3<Type>::operator*(Type s)
	{
		Vector3 w;

		w.x = x * s;
		w.y = y * s;
		w.z = z * s;

		return w;
	} // Vector3::operator*

//------------------------------------------------------------------------

template <typename Type>
	inline Vector3<Type> Vector3<Type>::operator/(Type s)
	{
		Vector3 w;

		w.x = x / s;
		w.y = y / s;
		w.z = z / s;

		return w;
	} // Vector3::operator/

//------------------------------------------------------------------------

template <typename Type>
	inline Type Vector3<Type>::operator*(Vector3 &v)
	{
		Type m;

		m = x * v.x + y * v.y + z * v.z;

		return m;
	} // Vector3::operator*

//------------------------------------------------------------------------

template <typename Type>
	inline Vector3<Type> Vector3<Type>::operator^(Vector3<Type> &v)
	{
		Vector3 w;

		w.x = y * v.z - z * v.y;
		w.y = z * v.x - x * v.z;
		w.z = x * v.y - y * v.x;

		return w;
	} // Vector3::operator^

//------------------------------------------------------------------------

template <typename Type>
	inline Vector3<Type> Vector3<Type>::operator-=(Type t)
	{
		x -= t;
		y -= t;
		z -= t;

		return *this;
	} // Vector3::operator*=

//------------------------------------------------------------------------

template <typename Type>
	inline Vector3<Type> Vector3<Type>::operator+=(Type t)
	{
		x += t;
		y += t;
		z += t;

		return *this;
	} // Vector3::operator*=

//------------------------------------------------------------------------

template <typename Type>
	inline Vector3<Type> Vector3<Type>::operator*=(Type s)
	{
		x *= s;
		y *= s;
		z *= s;

		return *this;
	} // Vector3::operator*=

//------------------------------------------------------------------------

template <typename Type>
	inline Vector3<Type> Vector3<Type>::operator/=(Type s)
	{
		if(s != 0)
		{
			x /= s;
			y /= s;
			z /= s;
		} // if
		else 
		{
			x = 0;
			y = 0;
			z = 0;
		} // else

		return *this;
	} // Vector3::operator/=

//------------------------------------------------------------------------

template <typename Type>
	inline Type Vector3<Type>::magnitude()
	{
		Type l = (Type)std::sqrt(x * x + y * y + z * z);

		return l;
	} // Vector3::operator*

//------------------------------------------------------------------------

template <typename Type>
	inline Vector3<Type> Vector3<Type>::normalize()
	{
		Type l = (Type)std::sqrt(x * x + y * y + z * z);
		
		Vector3<Type> w = *this;

		if(l != 0)
		{
			w.x /= l;
			w.y /= l;
			w.z /= l;
		} // if
		else 
		{
			w.x = 0;
			w.y = 0;
			w.z = 0;
		} // else
		
		return w;
	} // Vector3::normalize

//------------------------------------------------------------------------

template <typename Type>
	inline Position3<Type> Vector3<Type>::getVector( )
	{
		Position3<Type> p;
		
		p.x = x;
		p.y = y;
		p.z = z;
		
		return p;
	} // Vector3::getVector

//------------------------------------------------------------------------

template <typename Type>
	inline Vector3<Type> Vector3<Type>::normals(Vector3<Type> &v, Vector3<Type> &w)
	{
		Vector3<Type> u = *this;
		
		Vector3<Type> n;
		Vector3<Type> dv;
		Vector3<Type> dw;

		dv = v - u;
		dv = dv.normalize();
		
		dw = w - u;
		dw = dw.normalize();
		
		n = dv ^ dw;
		n = n.normalize();

		return n;
	} // normals

//------------------------------------------------------------------------

template <typename Type>
	inline Vector3<Type> Vector3<Type>::normals(Position3<Type> &q, Position3<Type> &r)
	{
		Vector3<Type> u = *this;
		Vector3<Type> v(q);
		Vector3<Type> w(r);
		
		Vector3<Type> n;
		Vector3<Type> dv;
		Vector3<Type> dw;

		dv = v - u;
		dv = dv.normalize();
		
		dw = w - u;
		dw = dw.normalize();
		
		n = dv ^ dw;
		n = n.normalize();

		return n;
	} // normals

//------------------------------------------------------------------------

//------------------------------------------------------------------------

typedef Position3<int>     IPosition3;
typedef Position3<long>    LPosition3;
typedef Position3<float>   FPosition3;
typedef Position3<double>  DPosition3;

typedef Position3<long long>    LLPosition3;
typedef Position3<long double>  LDPosition3;

typedef Vector3<int>     IVector3;
typedef Vector3<long>    LVector3;
typedef Vector3<float>   FVector3;
typedef Vector3<double>  DVector3;

typedef Vector3<long long>    LLVector3;
typedef Vector3<long double>  LDVector3;

//------------------------------------------------------------------------

//------------------------------------------------------------------------


#endif

#endif