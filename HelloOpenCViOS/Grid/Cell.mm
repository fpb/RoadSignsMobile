//
//  Cell.mm
//  HelloOpenCViOS
//
//  Created by David on 21/05/13.
//  Copyright (c) 2013 FCT/UNL. All rights reserved.
//

#import "Cell.h"

#pragma mark Cell element

@implementation CellElement

- (id)initWithSignId:(NSArray*)signIds withLatitude:(double)latitude andLongitude:(double)longitude andFacingTo:(float)facing
{
	self = [super init];
	
	if (self)
	{
		_signIds = signIds;
		_latitude = latitude;
		_longitude = longitude;
		_facing = facing;
	}
	
	return self;
}

@end


#pragma mark - Cell
@implementation Cell

- (id)initWithCellId:(CLLocationCoordinate2D)cellId
{
	self = [super init];
	
	if (self)
	{
		_cellId = cellId;
		_cellElements = [NSMutableArray new];
		_life = 0;
	}
	
	return self;
}

- (void)addElement:(CellElement*)aElement
{
	[_cellElements addObject:aElement];
}

- (void)updateLife:(int)lifeIncrement
{
	_life += lifeIncrement;
}

@end
