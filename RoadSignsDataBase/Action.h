//
//  Action.h
//  RoadSignsCD
//
//  Created by David on 10/05/13.
//  Copyright (c) 2013 David. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RoadSign;

@interface Action : NSManagedObject

@property (nonatomic, retain) NSString * desc;
@property (nonatomic, retain) NSSet *roadsigns;
@end

@interface Action (CoreDataGeneratedAccessors)

- (void)addRoadsignsObject:(RoadSign *)value;
- (void)removeRoadsignsObject:(RoadSign *)value;
- (void)addRoadsigns:(NSSet *)values;
- (void)removeRoadsigns:(NSSet *)values;

@end
