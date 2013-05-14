//
//  Location.h
//  RoadSignsCD
//
//  Created by David on 10/05/13.
//  Copyright (c) 2013 David. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Activity, RoadSign;

@interface Location : NSManagedObject

@property (nonatomic, retain) NSNumber * face;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSSet *activities;
@property (nonatomic, retain) NSSet *roadsigns;
@end

@interface Location (CoreDataGeneratedAccessors)

- (void)addActivitiesObject:(Activity *)value;
- (void)removeActivitiesObject:(Activity *)value;
- (void)addActivities:(NSSet *)values;
- (void)removeActivities:(NSSet *)values;

- (void)addRoadsignsObject:(RoadSign *)value;
- (void)removeRoadsignsObject:(RoadSign *)value;
- (void)addRoadsigns:(NSSet *)values;
- (void)removeRoadsigns:(NSSet *)values;

@end
