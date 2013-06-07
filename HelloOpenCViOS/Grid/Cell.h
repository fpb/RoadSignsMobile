//
//  Cell.h
//  HelloOpenCViOS
//
//  Created by David on 21/05/13.
//  Copyright (c) 2013 FCT/UNL. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@interface CellElement : NSObject
{
}
@property (nonatomic, strong, readonly) NSArray* signIds; // Sign Identifier -> name of the sign
@property (nonatomic, assign, readonly) double latitude;
@property (nonatomic, assign, readonly) double longitude;
@property (nonatomic, assign, readonly) float facing;

- (id)initWithSignId:(NSArray*)signIds withLatitude:(double)latitude andLongitude:(double)longitude andFacingTo:(float)facing;

@end


@interface Cell : NSObject

@property (nonatomic, assign, readonly) CLLocationCoordinate2D cellId;
@property (nonatomic, assign, readonly) int life;
@property (nonatomic, strong, readonly) NSMutableArray *cellElements;

- (id)initWithCellId:(CLLocationCoordinate2D)cellId;

- (void)addElement:(CellElement*)aElement;

- (void)updateLife:(int)lifeIncrement;
@end
