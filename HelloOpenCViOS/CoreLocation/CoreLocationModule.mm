//
//  CoreLocationModule.mm
//  HelloOpenCViOS
//
//  Created by David on 13/05/13.
//  Copyright (c) 2013 FCT/UNL. All rights reserved.
//

#import "CoreLocationModule.h"

@implementation CoreLocationModule

@synthesize locationManager = _locationManager;
@synthesize bestLocation	= _bestLocation;

- (void)startLocation
{
	_locationManager = nil;
	_locationManager = [[CLLocationManager alloc] init];
	_locationManager.delegate = self;
	_locationManager.distanceFilter = kCLDistanceFilterNone; //100.0;
	_locationManager.desiredAccuracy = kCLLocationAccuracyBest; // kCLLocationAccuracyNearestTenMeters ???
	_locationManager.pausesLocationUpdatesAutomatically = NO;
	[_locationManager startUpdatingLocation];
	_locationManager.headingFilter = kCLHeadingFilterNone;
	[_locationManager startUpdatingHeading];
}

- (void)stopLocation
{
	[_locationManager stopUpdatingHeading];
	[_locationManager stopUpdatingLocation];
	_locationManager = nil;
}

#pragma mark - Delegate methods
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
	// Get last update
	CLLocation *newLocation = [locations lastObject];
	
	// check that the location data isn't older than 60 seconds
	if ([newLocation.timestamp timeIntervalSinceReferenceDate] < [NSDate timeIntervalSinceReferenceDate] - 60)
		return;
	
	if (newLocation.horizontalAccuracy < 0.0f)// || newLocation.horizontalAccuracy > 10.0f)
		return;
	
	if (_bestLocation != nil)
	{
		double distance = [newLocation distanceFromLocation:_bestLocation];
		if(distance <= 1)
		{
			if (_bestLocation.horizontalAccuracy < newLocation.horizontalAccuracy)
				return;
		}
	}
	
	// test the measurement to see if it is more accurate than the previous measurement
	//		NSLog(@"%f", newLocation.horizontalAccuracy);
	// store the location as the "best effort"
	_bestLocation = newLocation;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"LocationDataReceived" object:self userInfo:nil];
}

- (void) locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
	if ([newHeading.timestamp timeIntervalSinceReferenceDate] < [NSDate timeIntervalSinceReferenceDate] - 60)
		return;
	
	if (newHeading.headingAccuracy < 0.0f)
		return;
	
	_currentHeading = newHeading;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"HeadingDataReceived" object:self userInfo:nil];
	//	[(ViewController*)[(pARkAppDelegate*)[[UIApplication sharedApplication] delegate] viewController] headingLabel].text =
	//	[NSString stringWithFormat:@"%f", newHeading.trueHeading];
	//	NSLog(@"X: %f, Y: %f", cosf(currentHeading.trueHeading*DEGREES_TO_RADIANS), sinf(currentHeading.trueHeading*DEGREES_TO_RADIANS));
	//	NSLog(@"X: %f, Y: %f, Z: %f", newHeading.x, newHeading.y, newHeading.z);
	//	NSLog(@"Accuracy: %f", newHeading.headingAccuracy);
}

@end
