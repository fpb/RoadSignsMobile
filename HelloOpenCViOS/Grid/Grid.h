//
//  Grid.h
//  HelloOpenCViOS
//
//  Created by David on 21/05/13.
//  Copyright (c) 2013 FCT/UNL. All rights reserved.
//
#import "Utilities.h"

using VectorGridCoordinates = std::vector<CLLocationCoordinate2D>;

const double kMinCellSize = 0.001;

@class Cell;

enum class GridMovements
{
	InitialPosition = 0,
	LeftBottom = InitialPosition,
	Left,
	LeftTop,
	Bottom,
	Center,
	Top,
	RightBottom,
	Right,
	RightTop,
	TotalPositions
};
GridMovements& operator++(GridMovements& g);

using VectorGridMovements = std::vector<GridMovements>;
using GridMovementScores = std::pair<GridMovements, int>;

VectorGridMovements getAdjacentMovementsFromMovement(GridMovements const &movement);

@interface Grid : NSObject

@property (nonatomic, assign, readonly) unsigned int maxCellsInMemory;
@property (nonatomic, assign, readonly) unsigned int numberOfCells;
@property (nonatomic, assign) double cellSize;
@property (nonatomic, strong) NSMutableDictionary *grid;

- (void)setCell:(Cell *)newCell forKey:(NSString*)key;
- (Cell*)getCellFromKey:(NSString*)key;
- (NSArray*)getCenterCellAndCellsAroundFromCellId:(CLLocationCoordinate2D)cellId;
- (CLLocationCoordinate2D)getNewCellIdsFromMovement:(GridMovements const &)movement andCellId:(CLLocationCoordinate2D)cellId;
- (GridMovements)getMovementFromPreviousCellId:(CLLocationCoordinate2D)previousCellId toNewCellId:(CLLocationCoordinate2D)newCellId;
- (NSArray*)getAdjacentCellsFromMovement:(GridMovements)aMovement andCellId:(CLLocationCoordinate2D)cellId;

- (void)printGridWithUserPath:(VectorGridCoordinates)userPath;
@end
