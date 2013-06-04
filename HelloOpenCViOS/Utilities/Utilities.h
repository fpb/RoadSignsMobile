//
//  Utilities.h
//  HelloOpenCViOS
//
//  Created by David on 13/05/13.
//  Copyright (c) 2013 FCT/UNL. All rights reserved.
//

#pragma once

#import <CoreMotion/CoreMotion.h>
#import <CoreLocation/CoreLocation.h>

#pragma mark -
#pragma mark Math utilities declaration

#define DEGREES_TO_RADIANS (M_PI/180.0)
#define RADIANS_TO_DEGREES (180.0/M_PI)

typedef float mat4f_t[16];	// 4x4 matrix in column major order
typedef float vec4f_t[4];	// 4D vector

// Creates a projection matrix using the given y-axis field-of-view, aspect ratio, and near and far clipping planes
void createProjectionMatrix(mat4f_t mout, float fovy, float aspect, float zNear, float zFar);

// Matrix-vector and matrix-matricx multiplication routines
void multiplyMatrixAndVector(vec4f_t vout, const mat4f_t m, const vec4f_t v);
void multiplyMatrixAndMatrix(mat4f_t c, const mat4f_t a, const mat4f_t b);

// Initialize mout to be an affine transform corresponding to the same rotation specified by m
void transformFromCMRotationMatrix(vec4f_t mout, const CMRotationMatrix *m);
void transformFromCMRotationMatrix(CATransform3D mout, const CMRotationMatrix *m);

#pragma mark -
#pragma mark Geodetic utilities declaration

#define WGS84_A	(6378137.0)				// WGS 84 semi-major axis constant in meters
#define WGS84_E (8.1819190842622e-2)	// WGS 84 eccentricity

// Converts latitude, longitude to ECEF coordinate system
void latLonToEcef(double lat, double lon, double alt, double *x, double *y, double *z);

// Coverts ECEF to ENU coordinates centered at given lat, lon
void ecefToEnu(double lat, double lon, double x, double y, double z, double xr, double yr, double zr, double *e, double *n, double *u);

// Get distance in Km between two latitudes and longitudes
double getDistanceFromLatLonInKm(double const &lat1, double const &lon1, double const &lat2, double const &lon2);
CLLocation* getLatitudeAndLongitudeFromDistanceAndBearing(double const &lat1, double const &lon1, double const &distance, double const &bearing);
double getNewLatitudeFromDistance(double const &lat1, double const &distance, double const &bearing = 0);
double getNewLongitudeFromDistance(double const &lat1, double const &lon1, double const &lat2, double const &distance, double const &bearing = M_PI_2);

// Enum class utilities
template<typename E, E first, E head>
void advanceEnum(E& v)
{
	if(v == head)
		v = first;
}

template<typename E, E first, E head, E next, E... tail>
void advanceEnum(E& v)
{
	if(v == head)
		v = next;
	else
		advanceEnum<E,first,next,tail...>(v);
}

template<typename E, E first, E... values>
struct EnumValues
{
	static void advance(E& v)
	{
		advanceEnum<E, first, first, values...>(v);
	}
};

double getDoubleRounded(double number, short scale);
int getDecimalPlaces(double number);
UIImage* convertImageToGrayScale(UIImage *image);
