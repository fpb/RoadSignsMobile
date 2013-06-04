//
//  Activity.h
//  RoadSignsCD
//
//  Created by David on 10/05/13.
//  Copyright (c) 2013 David. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Location;

@interface Activity : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *locations;
@end

@interface Activity (CoreDataGeneratedAccessors)

- (void)addLocationsObject:(Location *)value;
- (void)removeLocationsObject:(Location *)value;
- (void)addLocations:(NSSet *)values;
- (void)removeLocations:(NSSet *)values;

@end
