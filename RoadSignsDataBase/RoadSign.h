//
//  RoadSign.h
//  RoadSignsCD
//
//  Created by David on 30/05/13.
//  Copyright (c) 2013 David. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Action, Location;

@interface RoadSign : NSManagedObject

@property (nonatomic, retain) NSString * desc;
@property (nonatomic, retain) NSString * imageUrl;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSSet *actions;
@property (nonatomic, retain) NSSet *locations;
@end

@interface RoadSign (CoreDataGeneratedAccessors)

- (void)addActionsObject:(Action *)value;
- (void)removeActionsObject:(Action *)value;
- (void)addActions:(NSSet *)values;
- (void)removeActions:(NSSet *)values;

- (void)addLocationsObject:(Location *)value;
- (void)removeLocationsObject:(Location *)value;
- (void)addLocations:(NSSet *)values;
- (void)removeLocations:(NSSet *)values;

@end
