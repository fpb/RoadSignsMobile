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
@synthesize delegate		= _delegate;

- (id)init
{
	self = [super init];
	if (self)
	{
		if ([CLLocationManager locationServicesEnabled] == NO)
		{
			UIAlertView *servicesDisabledAlert = [[UIAlertView alloc] initWithTitle:@"Location Services Disabled" message:@"You currently have all location services for this device disabled. If you proceed, you will be asked to confirm whether location services should be reenabled." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[servicesDisabledAlert show];
		}
		
		if (![CLLocationManager headingAvailable])
		{
			UIAlertView *servicesDisabledAlert = [[UIAlertView alloc] initWithTitle:@"Heading not available" message:@"Your device does not have the capabilities for generating heading-related events." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[servicesDisabledAlert show];
			return nil;
		}

		_locationManager = [CLLocationManager new];
		_locationManager.distanceFilter = kCLDistanceFilterNone; //100.0;
		_locationManager.desiredAccuracy = kCLLocationAccuracyBest; // kCLLocationAccuracyNearestTenMeters ???
		_locationManager.pausesLocationUpdatesAutomatically = NO;
		_locationManager.headingFilter = kCLHeadingFilterNone;
		_locationManager.delegate = self;
	}
	
	return self;
}

- (void)startLocation
{
	[_locationManager startUpdatingLocation];
	[_locationManager startUpdatingHeading];
}

- (void)stopLocation
{
	[_locationManager stopUpdatingHeading];
	[_locationManager stopUpdatingLocation];
}

#pragma mark Location delegate
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
	
	if ([_delegate respondsToSelector:@selector(locationDataReceived)])
		[_delegate locationDataReceived];
}

- (void) locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
	if ([newHeading.timestamp timeIntervalSinceReferenceDate] < [NSDate timeIntervalSinceReferenceDate] - 60)
		return;
	
	if (newHeading.headingAccuracy < 0.0f)
		return;
	
	_currentHeading = newHeading;
	
	if ([_delegate respondsToSelector:@selector(headingDataReceived)])
		[_delegate headingDataReceived];

	//	[(ViewController*)[(pARkAppDelegate*)[[UIApplication sharedApplication] delegate] viewController] headingLabel].text =
	//	[NSString stringWithFormat:@"%f", newHeading.trueHeading];
	//	NSLog(@"X: %f, Y: %f", cosf(currentHeading.trueHeading*DEGREES_TO_RADIANS), sinf(currentHeading.trueHeading*DEGREES_TO_RADIANS));
	//	NSLog(@"X: %f, Y: %f, Z: %f", newHeading.x, newHeading.y, newHeading.z);
	//	NSLog(@"Accuracy: %f", newHeading.headingAccuracy);
}

@end
