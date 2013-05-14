/*
     File: ARView.m
 Abstract: Augmented reality view. Displays a live camera feed with specified places-of-interest overlayed in the correct position based on the direction the user is looking. Uses Core Location to determine the user's location relative the places-of-interest and Core Motion to determine the direction the user is looking.
  Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2012 Apple Inc. All Rights Reserved.
 
 */

#import "ARView.h"
#import "PlaceOfInterest.h"
#import "MyCamera.h"
#import "Utilities.h"
#import "CoreLocationModule.h"
#import "CoreMotionModule.h"
#include "FPS.h"

#pragma mark -
#pragma mark ARView extension

const BOOL showFPS = YES;
const BOOL showDistance = YES;
const BOOL showHeading = YES;

@interface ARView ()
{
	FramesPerSecond fps;
	CoreLocationModule *locationManager;
	CoreMotionModule *motionManager;
	MyCamera *camera;
	CADisplayLink *displayLink;
	NSArray *placesOfInterest;
	mat4f_t projectionTransform;
	mat4f_t cameraTransform;	
	vec4f_t *placesOfInterestCoordinates;
}

- (void)initialize;

- (void)startDisplayLink;
- (void)stopDisplayLink;

- (void)updatePlacesOfInterestCoordinates;

- (void)onDisplayLink:(id)sender;

@end


#pragma mark -
#pragma mark ARView implementation

@implementation ARView

@dynamic placesOfInterest;

- (void)dealloc
{
	[self stop];
	if (placesOfInterestCoordinates != NULL)
	{
		free(placesOfInterestCoordinates);
	}
}

- (void)start
{
	// watch for received data from the accessory
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_locationDataReceived:) name:@"LocationDataReceived" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_headingDataReceived:) name:@"HeadingDataReceived" object:nil];
	
	if (showFPS)
	{
		self.fpsLabel.hidden = NO;
		self.fpsLabel2.hidden = NO;
	}
	if (showDistance)
	{
		self.distanceLabel.hidden = NO;
		self.distanceLabel2.hidden = NO;
	}
	if (showHeading)
	{
		self.headingLabel.hidden = NO;
		self.headingLabel2.hidden = NO;
	}

	[camera startCameraPreview];
	[locationManager startLocation];
	[motionManager startDeviceMotion];
	[self startDisplayLink];
	
	fps.initFPS();
}

- (void)stop
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"LocationDataReceived" object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"HeadingDataReceived" object:nil];
	
	self.fpsLabel.hidden = YES;
	self.distanceLabel.hidden = YES;
	self.headingLabel.hidden = YES;
	self.fpsLabel2.hidden = YES;
	self.distanceLabel2.hidden = YES;
	self.headingLabel2.hidden = YES;
	
	[camera stopCameraPreview];
	[locationManager stopLocation];
	[motionManager stopDeviceMotion];
	[self stopDisplayLink];
}

- (void)setPlacesOfInterest:(NSArray *)pois
{
	for (PlaceOfInterest *poi in [placesOfInterest objectEnumerator])
		[poi.view removeFromSuperview];
	
	placesOfInterest = nil;
	
	placesOfInterest = pois;
	if (locationManager.bestLocation != nil)
	{
		[self updatePlacesOfInterestCoordinates];
	}
}

- (NSArray *)placesOfInterest
{
	return placesOfInterest;
}

- (void)initialize
{
	camera = [[MyCamera alloc] initWithFrame:self.bounds];
	[self addSubview:camera.captureView];
	[self sendSubviewToBack:camera.captureView];

	locationManager = [[CoreLocationModule alloc] init];
	motionManager = [[CoreMotionModule alloc] init];

	// Initialize projection matrix	
	createProjectionMatrix(projectionTransform, 60.8f * DEGREES_TO_RADIANS, self.bounds.size.width * 1.0f / self.bounds.size.height, 0.25f, 1000.0f);
}

- (void)startDisplayLink
{
	displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(onDisplayLink:)];
	[displayLink setFrameInterval:1];
	[displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)stopDisplayLink
{
	[displayLink invalidate];
	displayLink = nil;		
}

- (void)updatePlacesOfInterestCoordinates
{
	if (placesOfInterest == nil)
		return;
	
	if (placesOfInterestCoordinates != NULL)
		free(placesOfInterestCoordinates);
	
	placesOfInterestCoordinates = (vec4f_t *)malloc(sizeof(vec4f_t)*placesOfInterest.count);
			
	int i = 0;
	
	double myX, myY, myZ;
	latLonToEcef(locationManager.bestLocation.coordinate.latitude, locationManager.bestLocation.coordinate.longitude, 0.0, &myX, &myY, &myZ);

	// Array of NSData instances, each of which contains a struct with the distance to a POI and the
	// POI's index into placesOfInterest
	// Will be used to ensure proper Z-ordering of UIViews
	typedef struct {
		float distance;
		int index;
	} DistanceAndIndex;
	NSMutableArray *orderedDistances = [NSMutableArray arrayWithCapacity:placesOfInterest.count];

	// Compute the world coordinates of each place-of-interest
	for (PlaceOfInterest *poi in [[self placesOfInterest] objectEnumerator]) {
		double poiX, poiY, poiZ, e, n, u;
		
		latLonToEcef(poi.location.coordinate.latitude, poi.location.coordinate.longitude, 0.0, &poiX, &poiY, &poiZ);
		ecefToEnu(locationManager.bestLocation.coordinate.latitude, locationManager.bestLocation.coordinate.longitude, myX, myY, myZ, poiX, poiY, poiZ, &e, &n, &u);
		
		placesOfInterestCoordinates[i][0] = (float)n;
		placesOfInterestCoordinates[i][1]= -(float)e;
		placesOfInterestCoordinates[i][2] = 0.0f;
		placesOfInterestCoordinates[i][3] = 1.0f;
		
		// Add struct containing distance and index to orderedDistances
		DistanceAndIndex distanceAndIndex;
		distanceAndIndex.distance = sqrtf(n*n + e*e);
		distanceAndIndex.index = i;
		[orderedDistances insertObject:[NSData dataWithBytes:&distanceAndIndex length:sizeof(distanceAndIndex)] atIndex:i++];
//		NSLog(@"Distance2: %f", sqrtf(n*n + e*e));
	}
	
	// Sort orderedDistances in ascending order based on distance from the user
	[orderedDistances sortUsingComparator:(NSComparator)^(NSData *a, NSData *b) {
		const DistanceAndIndex *aData = (const DistanceAndIndex *)a.bytes;
		const DistanceAndIndex *bData = (const DistanceAndIndex *)b.bytes;
		if (aData->distance < bData->distance) {
			return NSOrderedAscending;
		} else if (aData->distance > bData->distance) {
			return NSOrderedDescending;
		} else {
			return NSOrderedSame;
		}
	}];
	
	// Add subviews in descending Z-order so they overlap properly
	for (NSData *d in [orderedDistances reverseObjectEnumerator]) {
		const DistanceAndIndex *distanceAndIndex = (const DistanceAndIndex *)d.bytes;
		PlaceOfInterest *poi = (PlaceOfInterest *)[placesOfInterest objectAtIndex:distanceAndIndex->index];		
		[self addSubview:poi.view];
	}	
}

- (void)onDisplayLink:(id)sender
{
	CMDeviceMotion *d = motionManager.motionManager.deviceMotion;
	if (d != nil) {
//		NSLog(@"Yaw: %f\tPitch: %f\tRoll: %f", d.attitude.yaw*RADIANS_TO_DEGREES, d.attitude.pitch*RADIANS_TO_DEGREES, d.attitude.roll*RADIANS_TO_DEGREES);
		CMRotationMatrix r = d.attitude.rotationMatrix;
		transformFromCMRotationMatrix(cameraTransform, &r);
					
		[self setNeedsDisplay];
	}
	
	if (!self.fpsLabel.hidden)
		self.fpsLabel.text = [NSString stringWithFormat:@"%.2f fps", fps.CalculateFPS()];
}

- (void)drawRect:(CGRect)rect
{
	if (placesOfInterestCoordinates == nil) {
		return;
	}
	
	mat4f_t projectionCameraTransform;
	multiplyMatrixAndMatrix(projectionCameraTransform, projectionTransform, cameraTransform);
	
	int i = 0;
	float distance = MAXFLOAT;
	for (PlaceOfInterest *poi in [placesOfInterest objectEnumerator])
	{
		vec4f_t v;
		multiplyMatrixAndVector(v, projectionCameraTransform, placesOfInterestCoordinates[i]);
		
		float x = (v[0] / v[3] + 1.0f) * 0.5f;
		float y = (v[1] / v[3] + 1.0f) * 0.5f;
		if (v[2] < 0.0f)
		{
			poi.view.backgroundColor = [UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:0.5f];
			poi.view.center = CGPointMake(x*self.bounds.size.width, self.bounds.size.height-y*self.bounds.size.height);
			poi.view.hidden = NO;

			float temp = sqrtf(placesOfInterestCoordinates[i][0]*placesOfInterestCoordinates[i][0] +
							   placesOfInterestCoordinates[i][1]*placesOfInterestCoordinates[i][1]);
			
			if (distance > temp)
				distance = temp;
			
			if (locationManager.currentHeading.trueHeading < (poi.face - 90.0) && locationManager.currentHeading.trueHeading > (poi.face + 90.0))
				poi.view.backgroundColor = [UIColor colorWithRed:0.0f green:1.0f blue:0.0f alpha:0.5f];
			if (x < 0.0f || x > 1.0f)
				poi.view.backgroundColor = [UIColor colorWithRed:1.0f green:0.0f blue:0.0f alpha:0.5f];
			if (y < 0.0f || y > 1.0f)
				poi.view.backgroundColor = [UIColor colorWithRed:1.0f green:0.0f blue:0.0f alpha:0.5f];
		} else {
			poi.view.hidden = YES;
		}
		++i;
	}

	// Distance to closest sign
	if (!self.distanceLabel.hidden)
		self.distanceLabel.text = [NSString stringWithFormat:@"%f", distance];
}

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		[self initialize];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self) {
		[self initialize];
	}
	return self;
}

#pragma mark - Notification
- (void)_locationDataReceived:(NSNotification *)notification
{
	if (placesOfInterest != nil)
	{
		[self updatePlacesOfInterestCoordinates];
		//		NSLog(@"Distance4: %f",[location distanceFromLocation:[(PlaceOfInterest*)[placesOfInterest objectAtIndex:0] location]]);
		//			NSLog(@"Altitude: %f", bestLocation.altitude);
	}
}

- (void)_headingDataReceived:(NSNotification *)notification
{
	if (!self.headingLabel.hidden)
		self.headingLabel.text = [NSString stringWithFormat:@"%f", locationManager.currentHeading.trueHeading];
}

@end
