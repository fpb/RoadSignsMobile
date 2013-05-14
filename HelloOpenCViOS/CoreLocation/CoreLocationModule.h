//
//  CoreLocationModule.h
//  HelloOpenCViOS
//
//  Created by David on 13/05/13.
//  Copyright (c) 2013 FCT/UNL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface CoreLocationModule : NSObject <CLLocationManagerDelegate>

@property (readonly, nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLLocation *bestLocation;
@property (nonatomic, strong) CLHeading *currentHeading;

- (void)startLocation;
- (void)stopLocation;

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations;
- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading;

@end
