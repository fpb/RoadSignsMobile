//
//  Grid.mm
//  HelloOpenCViOS
//
//  Created by David on 21/05/13.
//  Copyright (c) 2013 FCT/UNL. All rights reserved.
//

#import "Grid.h"

#import "Cell.h"

/// Scalable way, C++11-ish
typedef EnumValues
<
GridMovements,
GridMovements::LeftBottom,
GridMovements::Left,
GridMovements::LeftTop,
GridMovements::Bottom,
GridMovements::Center,
GridMovements::Top,
GridMovements::RightBottom,
GridMovements::Right,
GridMovements::RightTop,
GridMovements::TotalPositions
> GridMovements_values;

GridMovements& operator++(GridMovements& g)
{
	GridMovements_values::advance(g);
	return g;
}

VectorGridMovements getAdjacentMovementsFromMovement(GridMovements const &movement)
{
	VectorGridMovements adjancets;
	adjancets.reserve(2);
	
	if (movement == GridMovements::LeftBottom)
	{
		adjancets.push_back(GridMovements::Left);
		adjancets.push_back(GridMovements::Bottom);
	}
	
	else if (movement == GridMovements::Left)
	{
		adjancets.push_back(GridMovements::LeftBottom);
		adjancets.push_back(GridMovements::LeftTop);
	}

	else if (movement == GridMovements::LeftTop)
	{
		adjancets.push_back(GridMovements::Left);
		adjancets.push_back(GridMovements::Top);
	}

	else if (movement == GridMovements::Bottom)
	{
		adjancets.push_back(GridMovements::LeftBottom);
		adjancets.push_back(GridMovements::RightBottom);
	}

	else if (movement == GridMovements::Top)
	{
		adjancets.push_back(GridMovements::LeftTop);
		adjancets.push_back(GridMovements::RightTop);
	}		
	
	else if (movement == GridMovements::RightBottom)
	{
		adjancets.push_back(GridMovements::Right);
		adjancets.push_back(GridMovements::Bottom);
	}
	
	else if (movement == GridMovements::Right)
	{
		adjancets.push_back(GridMovements::RightBottom);
		adjancets.push_back(GridMovements::RightTop);
	}
	
	else if (movement == GridMovements::RightTop)
	{
		adjancets.push_back(GridMovements::Right);
		adjancets.push_back(GridMovements::Top);
	}
	
	return adjancets;
}

@implementation Grid

- (id)init
{
	self = [super init];
	if (self)
	{
		_maxCellsInMemory = 27;
		_grid = [NSMutableDictionary new];
	}
	
	return self;
}

- (void)setCell:(Cell *)newCell forKey:(NSString*)key
{
	[_grid setObject:newCell forKey:key];
	++_numberOfCells;
}

- (Cell*)getCellFromKey:(NSString*)key
{
	return [_grid objectForKey:key];
}

// Pass the center cell position
- (NSArray*)getCenterCellAndCellsAroundFromCellId:(CLLocationCoordinate2D)cellId
{
	NSMutableArray *cells = [NSMutableArray new];
	
	for (GridMovements i = GridMovements::InitialPosition; i < GridMovements::TotalPositions; ++i)
	{
	 	CLLocationCoordinate2D aCellId = [self getNewCellIdsFromMovement:i andCellId:cellId];
		NSString *key = [NSString stringWithFormat:@"%f,%f", aCellId.latitude, aCellId.longitude];
		Cell* cell = [self getCellFromKey:key];
		if (cell)
			[cells addObject:cell];
		
	}

	NSArray *cellArray = [NSArray arrayWithArray:cells];
	return cellArray;
}

- (CLLocationCoordinate2D)getNewCellIdsFromMovement:(GridMovements const &)movement andCellId:(CLLocationCoordinate2D)cellId
{
	CLLocationCoordinate2D newCellId;
	switch (movement)
	{
		case GridMovements::LeftBottom:
			newCellId = CLLocationCoordinate2DMake(cellId.latitude - _cellSize, cellId.longitude - _cellSize);
			break;
			
		case GridMovements::Left:
			newCellId = CLLocationCoordinate2DMake(cellId.latitude - _cellSize, cellId.longitude);
			break;
			
		case GridMovements::LeftTop:
			newCellId = CLLocationCoordinate2DMake(cellId.latitude - _cellSize, cellId.longitude + _cellSize);
			break;
			
		case GridMovements::Bottom:
			newCellId = CLLocationCoordinate2DMake(cellId.latitude, cellId.longitude - _cellSize);
			break;
			
		case GridMovements::Center:
			newCellId = CLLocationCoordinate2DMake(cellId.latitude, cellId.longitude);
			break;
			
		case GridMovements::Top:
			newCellId = CLLocationCoordinate2DMake(cellId.latitude, cellId.longitude + _cellSize);
			break;
			
		case GridMovements::RightBottom:
			newCellId = CLLocationCoordinate2DMake(cellId.latitude + _cellSize, cellId.longitude - _cellSize);
			break;
			
		case GridMovements::Right:
			newCellId = CLLocationCoordinate2DMake(cellId.latitude + _cellSize, cellId.longitude);
			break;
			
		case GridMovements::RightTop:
			newCellId = CLLocationCoordinate2DMake(cellId.latitude + _cellSize, cellId.longitude + _cellSize);
			break;
			
		default:
			assert(0);
			break;
	}
	
	return newCellId;
}

- (GridMovements)getMovementFromPreviousCellId:(CLLocationCoordinate2D)previousCellId toNewCellId:(CLLocationCoordinate2D)newCellId
{
	int x = newCellId.latitude - previousCellId.latitude;
	int y = newCellId.longitude - previousCellId.longitude;

	if (x == -1)
	{
		switch (y)
		{
			case -1:
				return GridMovements::LeftBottom;
				break;
			case  0:
				return GridMovements::Left;
				break;
			case  1:
				return GridMovements::LeftTop;
				break;
			default:
				assert(0);
				break;
		}
	}
	
	else if (x == 0)
	{
		switch (y)
		{
			case -1:
				return GridMovements::Bottom;
				break;
			case  0:
				return GridMovements::Center;
				break;
			case  1:
				return GridMovements::Top;
				break;
			default:
				assert(0);
				break;
		}
	}
	
	else if (x == 1)
	{
		switch (y)
		{
			case -1:
				return GridMovements::RightBottom;
				break;
			case  0:
				return GridMovements::Right;
				break;
			case  1:
				return GridMovements::RightTop;
				break;
			default:
				assert(0);
				break;
		}
	}
	
	assert(0);
}

- (NSArray*)getAdjacentCellsFromMovement:(GridMovements)aMovement andCellId:(CLLocationCoordinate2D)cellId
{
	VectorGridMovements adjacents = getAdjacentMovementsFromMovement(aMovement);
	NSMutableArray *cells = [NSMutableArray new];
	if (adjacents.size() > 0)
	{
		for (VectorGridMovements::iterator it = adjacents.begin(); it != adjacents.end(); ++it)
		{
			CLLocationCoordinate2D adjacentCellId = [self getNewCellIdsFromMovement:*it andCellId:cellId];
			[cells addObject:[self getCellFromKey:[NSString stringWithFormat:@"%f,%f", adjacentCellId.latitude, adjacentCellId.longitude]]];
		}
		
		
		cells = nil;
	}

	NSArray *cellsResult = [NSArray arrayWithArray:cells];
	return cellsResult;
}

@end
