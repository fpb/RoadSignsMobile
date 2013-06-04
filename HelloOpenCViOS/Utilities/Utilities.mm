//
//  Utilities.cpp
//  HelloOpenCViOS
//
//  Created by David on 13/05/13.
//  Copyright (c) 2013 FCT/UNL. All rights reserved.
//

#include "Utilities.h"

#pragma mark -
#pragma mark Math utilities definition

// Creates a projection matrix using the given y-axis field-of-view, aspect ratio, and near and far clipping planes
void createProjectionMatrix(mat4f_t mout, float fovy, float aspect, float zNear, float zFar)
{
	float f = 1.0f / tanf(fovy/2.0f);
	
	mout[0] = f / aspect;
	mout[1] = 0.0f;
	mout[2] = 0.0f;
	mout[3] = 0.0f;
	
	mout[4] = 0.0f;
	mout[5] = f;
	mout[6] = 0.0f;
	mout[7] = 0.0f;
	
	mout[8] = 0.0f;
	mout[9] = 0.0f;
	mout[10] = (zFar+zNear) / (zNear-zFar);
	mout[11] = -1.0f;
	
	mout[12] = 0.0f;
	mout[13] = 0.0f;
	mout[14] = 2 * zFar * zNear /  (zNear-zFar);
	mout[15] = 0.0f;
}

// Matrix-vector and matrix-matricx multiplication routines
void multiplyMatrixAndVector(vec4f_t vout, const mat4f_t m, const vec4f_t v)
{
	vout[0] = m[0]*v[0] + m[4]*v[1] + m[8]*v[2] + m[12]*v[3];
	vout[1] = m[1]*v[0] + m[5]*v[1] + m[9]*v[2] + m[13]*v[3];
	vout[2] = m[2]*v[0] + m[6]*v[1] + m[10]*v[2] + m[14]*v[3];
	vout[3] = m[3]*v[0] + m[7]*v[1] + m[11]*v[2] + m[15]*v[3];
}

void multiplyMatrixAndMatrix(mat4f_t c, const mat4f_t a, const mat4f_t b)
{
	uint8_t col, row, i;
	memset(c, 0, 16*sizeof(float));
	
	for (col = 0; col < 4; col++) {
		for (row = 0; row < 4; row++) {
			for (i = 0; i < 4; i++) {
				c[col*4+row] += a[i*4+row]*b[col*4+i];
			}
		}
	}
}

// Initialize mout to be an affine transform corresponding to the same rotation specified by m
void transformFromCMRotationMatrix(mat4f_t mout, const CMRotationMatrix *m)
{
	mout[0] = (float)m->m11;
	mout[1] = (float)m->m21;
	mout[2] = (float)m->m31;
	mout[3] = 0.0f;
	
	mout[4] = (float)m->m12;
	mout[5] = (float)m->m22;
	mout[6] = (float)m->m32;
	mout[7] = 0.0f;
	
	mout[8] = (float)m->m13;
	mout[9] = (float)m->m23;
	mout[10] = (float)m->m33;
	mout[11] = 0.0f;
	
	mout[12] = 0.0f;
	mout[13] = 0.0f;
	mout[14] = 0.0f;
	mout[15] = 1.0f;
}

// Initialize mout to be an affine transform corresponding to the same rotation specified by m
void transformFromCMRotationMatrix(CATransform3D mout, const CMRotationMatrix *m)
{
	mout = CATransform3DIdentity;
	
	mout.m11 = (float)m->m11;
	mout.m21 = (float)m->m21;
	mout.m31 = (float)m->m31;
	
	mout.m12 = (float)m->m12;
	mout.m22 = (float)m->m22;
	mout.m32 = (float)m->m32;
	
	mout.m13 = (float)m->m13;
	mout.m23 = (float)m->m23;
	mout.m33 = (float)m->m33;
}

#pragma mark -
#pragma mark Geodetic utilities definition

// References to ECEF and ECEF to ENU conversion may be found on the web.

// Converts latitude, longitude to ECEF coordinate system
void latLonToEcef(double lat, double lon, double alt, double *x, double *y, double *z)
{
	double clat = cos(lat * DEGREES_TO_RADIANS);
	double slat = sin(lat * DEGREES_TO_RADIANS);
	double clon = cos(lon * DEGREES_TO_RADIANS);
	double slon = sin(lon * DEGREES_TO_RADIANS);
	
	double N = WGS84_A / sqrt(1.0 - WGS84_E * WGS84_E * slat * slat);
	
	*x = (N + alt) * clat * clon;
	*y = (N + alt) * clat * slon;
	*z = (N * (1.0 - WGS84_E * WGS84_E) + alt) * slat;
}

// Coverts ECEF to ENU coordinates centered at given lat, lon
void ecefToEnu(double lat, double lon, double x, double y, double z, double xr, double yr, double zr, double *e, double *n, double *u)
{
	double clat = cos(lat * DEGREES_TO_RADIANS);
	double slat = sin(lat * DEGREES_TO_RADIANS);
	double clon = cos(lon * DEGREES_TO_RADIANS);
	double slon = sin(lon * DEGREES_TO_RADIANS);
	double dx = x - xr;
	double dy = y - yr;
	double dz = z - zr;
	
	*e = -slon*dx  + clon*dy;
	*n = -slat*clon*dx - slat*slon*dy + clat*dz;
	*u = clat*clon*dx + clat*slon*dy + slat*dz;
}

#pragma mark - Distance between two latitudes and longitudes
double getDistanceFromLatLonInKm(double const &lat1, double const &lon1, double const &lat2, double const &lon2)
{
	const double R = 6371.0; // Radius of the earth in km
	double dLat = DEGREES_TO_RADIANS * (lat2 - lat1);  // deg2rad below
	double dLon = DEGREES_TO_RADIANS * (lon2 - lon1);
	double a =  sin(dLat * 0.5) * sin(dLat * 0.5) +
				cos(DEGREES_TO_RADIANS * lat1) * cos(DEGREES_TO_RADIANS * lat2) *
				sin(dLon * 0.5) * sin(dLon * 0.5);
	
	double c = 2.0 * atan2(sqrt(a), sqrt(1.0 - a));
	double d = R * c; // Distance in km
	return d;
}

// lat1 and lon1 are in degrees
CLLocation* getLatitudeAndLongitudeFromDistanceAndBearing(double const &lat1, double const &lon1, double const &distance, double const &bearing)
{
//	double lat2 = lat1 + (0.1 / 110.54);
//	double lon2 = lon1 + (0.1 / 111.320 * cos(lat2));
	//Latitude: 1 deg = 110.54 km
	//Longitude: 1 deg = 111.320*cos(latitude) km

	// Better formula
	double lat1InRadians = lat1 * DEGREES_TO_RADIANS;
	const double R = 6371.0; // Radius of the earth in km
	double lat2 = asin(sin(lat1InRadians) * cos(distance/R) + cos(lat1InRadians) * sin(distance/R) * cos(bearing)); // Is in radians
	// Get longitude in degrees
	double lon2 = lon1 + atan2(sin(bearing) * sin(distance/R) * cos(lat1InRadians), cos(distance/R) - sin(lat1InRadians) * sin(lat2)) * RADIANS_TO_DEGREES;
	
	CLLocation *l = [[CLLocation alloc] initWithLatitude:lat2 * RADIANS_TO_DEGREES longitude:lon2];
	return l;
}

double getNewLatitudeFromDistance(double const &lat1, double const &distance, double const &bearing)
{
	double lat1InRadians = lat1 * DEGREES_TO_RADIANS;
	const double R = 6371.0; // Radius of the earth in km
	double lat2 = asin(sin(lat1InRadians) * cos(distance/R) + cos(lat1InRadians) * sin(distance/R) * cos(bearing)); // Is in radians

	return lat2 * RADIANS_TO_DEGREES;
}

double getNewLongitudeFromDistance(double const &lat1, double const &lon1, double const &lat2, double const &distance, double const &bearing)
{
	double lat1InRadians = lat1 * DEGREES_TO_RADIANS;
	const double R = 6371.0; // Radius of the earth in km
	// Get longitude in degrees
	double lon2 = lon1 + atan2(sin(bearing) * sin(distance/R) * cos(lat1InRadians), cos(distance/R) - sin(lat1InRadians) * sin(lat2)) * RADIANS_TO_DEGREES;
	
	return lon2;
}

double getDoubleRounded(double number, short scale)
{
	NSNumber *n = [NSNumber numberWithDouble:number];
	NSDecimalNumber *dn = [NSDecimalNumber decimalNumberWithDecimal:[n decimalValue]];
	NSDecimalNumberHandler *handler = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundDown
																							 scale:scale
																				  raiseOnExactness:NO
																				   raiseOnOverflow:NO
																				  raiseOnUnderflow:NO
																			   raiseOnDivideByZero:NO];
	NSDecimalNumber *result = [dn decimalNumberByRoundingAccordingToBehavior:handler];
	return [result doubleValue];
}

int getDecimalPlaces(double number)
{
	NSNumber *numberValue = [NSNumber numberWithDouble:number];
	NSString *doubleString = [numberValue stringValue];
	NSArray *doubleStringComps = [doubleString componentsSeparatedByString:@"."];
	return [[doubleStringComps objectAtIndex:1] length];
}

UIImage* convertImageToGrayScale(UIImage *image)
{
	// Create image rectangle with current image width/height
	CGRect imageRect = CGRectMake(0, 0, image.size.width, image.size.height);
	
	// Grayscale color space
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
	
	// Create bitmap content with current image size and grayscale colorspace
	CGContextRef context = CGBitmapContextCreate(nil, image.size.width, image.size.height, 8, 0, colorSpace, kCGImageAlphaNone);
	
	// Draw image into current context, with specified rectangle
	// using previously defined context (with grayscale colorspace)
	CGContextDrawImage(context, imageRect, [image CGImage]);
	
	// Create bitmap image info from pixel data in current context
	CGImageRef imageRef = CGBitmapContextCreateImage(context);
	
	// Create a new UIImage object
	UIImage *newImage = [UIImage imageWithCGImage:imageRef];
	
	// Release colorspace, context and bitmap information
	CGColorSpaceRelease(colorSpace);
	CGContextRelease(context);
	CFRelease(imageRef);
	
	// Return the new grayscale image
	return newImage;
}