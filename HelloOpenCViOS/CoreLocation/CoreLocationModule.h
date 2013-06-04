//
//  CoreLocationModule.h
//  HelloOpenCViOS
//
//  Created by David on 13/05/13.
//  Copyright (c) 2013 FCT/UNL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@protocol CoreLocationModuleDelegate <NSObject>
@optional
- (void)locationDataReceived;
- (void)headingDataReceived;
@end

@interface CoreLocationModule : NSObject <CLLocationManagerDelegate>

@property (nonatomic, assign) id<CoreLocationModuleDelegate> delegate;
@property (readonly, nonatomic, strong) CLLocationManager *locationManager;
@property (readonly, nonatomic, strong) CLLocation *bestLocation;
@property (readonly, nonatomic, strong) CLHeading *currentHeading;

- (void)startLocation;
- (void)stopLocation;

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations;
- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading;

@end
