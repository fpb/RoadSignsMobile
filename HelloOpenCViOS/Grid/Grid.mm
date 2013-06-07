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
	float mult = 1.0f / _cellSize;
	int x = getDoubleRounded((newCellId.latitude - previousCellId.latitude) * mult, getDecimalPlaces(_cellSize), NSRoundPlain) ;
	int y = getDoubleRounded((newCellId.longitude - previousCellId.longitude) * mult, getDecimalPlaces(_cellSize), NSRoundPlain);
	
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

- (void)printGridWithUserPath:(VectorGridCoordinates)userPath
{
	NSArray *cells = [[_grid allValues] sortedArrayUsingComparator:(NSComparator)^(Cell *a, Cell *b)
					  {
						  if (a.cellId.latitude < b.cellId.latitude)
							  return NSOrderedAscending;
						  else if (a.cellId.latitude > b.cellId.latitude)
							  return NSOrderedDescending;
						  else if (a.cellId.longitude > b.cellId.longitude)
							  return NSOrderedAscending;
						  else if (a.cellId.longitude < b.cellId.longitude)
							  return NSOrderedDescending;
						  else
							  return NSOrderedSame;
					  }];
	
	CLLocationCoordinate2D maxLocation = ((Cell*)[cells lastObject]).cellId;
	NSMutableArray *latitudeCells = [NSMutableArray new];
	NSMutableArray *arrayOfLatitudeCells = [NSMutableArray new];
	for (Cell *c in [cells reverseObjectEnumerator])
	{
		if ([latitudeCells count] == 0)
		{
			[latitudeCells addObject:c];
		}
		else
		{
			if (Equals(((Cell*)[latitudeCells lastObject]).cellId.latitude, c.cellId.latitude))
			{
				[latitudeCells addObject:c];
			}
			else
			{
				[arrayOfLatitudeCells addObject:[NSArray arrayWithArray:latitudeCells]];
				[latitudeCells removeAllObjects];
				[latitudeCells addObject:c];
			}
		}
		
		if (c == [cells objectAtIndex:0])
		{
			[arrayOfLatitudeCells addObject:[NSArray arrayWithArray:latitudeCells]];
			[latitudeCells removeAllObjects];
			latitudeCells = nil;
		}
	}
	
	CLLocationDegrees stepLatitude = maxLocation.latitude;
	CLLocationCoordinate2D minLocation = ((Cell*)[[[_grid allValues] sortedArrayUsingComparator:(NSComparator)^(Cell *a, Cell *b)
												   {
													   if (a.cellId.longitude < b.cellId.longitude)
														   return NSOrderedAscending;
													   else if (a.cellId.longitude > b.cellId.longitude)
														   return NSOrderedDescending;
													   else
														   return NSOrderedSame;
												   }] objectAtIndex:0]).cellId;
	bool print = false, userPosition = true;
	for (NSArray *a in arrayOfLatitudeCells)
	{
		CLLocationDegrees stepLongitude = minLocation.longitude;
		for (Cell *c in a)
		{
			while (!Equals(c.cellId.latitude, stepLatitude))
			{
				stepLatitude -= _cellSize;
				
				std::cout << std::endl;
			}
			print = false;
			while (!Equals(c.cellId.longitude, stepLongitude))
			{
				stepLongitude += _cellSize;
				if (print) std::cout << "_";
				else print = true;
				
			}
			const CLLocationCoordinate2D location = {stepLatitude, stepLongitude};

			VectorGridCoordinates::reverse_iterator it = std::find_if(userPath.rbegin(), userPath.rend(),
																	  [&location](const CLLocationCoordinate2D &s1) -> bool
																	  {
																		  return (Equals(s1.latitude, location.latitude) &&
																				  Equals(s1.longitude, location.longitude));
																	  } );
			
			if (it != userPath.rend())
			{
				if (it == userPath.rbegin() && userPosition)
				{
					std::cout << "O";
					userPosition = false;
				}
				else
					std::cout << "P";
				
				userPath.erase(--it.base());
			}
			else
				std::cout << "X";
			
		}
		std::cout << std::endl;
	}
	
	std::cout << std::endl << std::endl;
}
@end
