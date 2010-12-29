//
//  GridShapeGenerator.m
//  MacFungus
//
//  Created by tristan on 03/06/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "GridShapeGenerator.h"
#import "GameGridCell.h"

enum {
	SHAPE_ONE_0 = 1,
	SHAPE_ONE_90,
	SHAPE_TWO,
	SHAPE_THREE,
	SHAPE_FOUR_0,
	SHAPE_FOUR_90,
	SHAPE_FOUR_180,
	SHAPE_FOUR_270,
	SHAPE_FIVE_0,
	SHAPE_FIVE_90
};

@implementation GridShapeGenerator

- (NSArray *)generateRandomShapeFromCell:(GameGridCell *)cell
						  withController:(id)controller
{
	[self generateRandomShape];
	
	if (cell && controller)
		return [self lastShapeFromCell:cell withController:controller];
	else return nil;
	
}

- (int)generateRandomShape
{
	srand(time(NULL));
	
	switch ((rand() % 5) + 1) {
		case 1: lastShape = SHAPE_ONE_0;
			break;
		case 2: lastShape = SHAPE_TWO;
			break;
		case 3: lastShape = SHAPE_THREE;
			break;
		case 4: lastShape = SHAPE_FOUR_0;
			break;
		case 5: lastShape = SHAPE_FIVE_0;
			NSLog(@"shape was 5");
			break;
		default: lastShape = SHAPE_ONE_0;
	}
	
	return lastShape;
}

/* Only returns shapes that can be drawn on white cells*/

- (NSArray *)shapeOneFromCell:(GameGridCell *)cell 
					rotatedAt:(int)degrees
			   withController:(id)controller
{
	int row, column;
	GameGridCell *cell1, *cell2;
	
	NSArray *cellArray;
	
	[controller getRow:&row column:&column ofCell:cell];
	
	if ((degrees == 0 || degrees == 180) && column < [controller numberOfColumns] - 1 ) {
		
		// Make sure the shape doesn't go out of bounds
		if (column+1 > [controller numberOfColumns] || column-1 < 0)
			return nil;
		
		cell1 = [controller cellAtRow:row column:column -1];
		cell2 = [controller cellAtRow:row column:column +1];
		
		cellArray = [[NSArray alloc] initWithObjects:cell, cell1, cell2, nil];
		
		return [cellArray autorelease];
		
	} else if (degrees == 90 || degrees == 270) {
		
		lastShape = SHAPE_ONE_90; //So we remember what was the last shape
		
		// Make sure the shape doesn't go out of bounds
		if (row > [controller numberOfRows]-1 || row-1 < 0)
			return nil;
		
		cell1 = [controller cellAtRow:row -1 column:column];
		cell2 = [controller cellAtRow:row +1 column:column];
		
		cellArray = [[NSArray alloc] initWithObjects:cell, cell1, cell2, nil];
		
		return [cellArray autorelease];
		
	} else {
		return nil;
	}

}

- (NSArray *)shapeTwoFromCell:(GameGridCell *)cell 
					rotatedAt:(int)degrees
			   withController:(id)controller
{
	int row, column;
	GameGridCell *cell1, *cell2, *cell3;
	
	NSArray *cellArray;
	
	[controller getRow:&row column:&column ofCell:cell];
	
	lastShape = SHAPE_TWO; //So we remember what was the last shape
	
	// Make sure the shape doesn't go out of bounds
	if (column-1 < 0 || row-1 < 0)
		return nil;
		
	cell1 = [controller cellAtRow:row column:column-1];
	cell2 = [controller cellAtRow:row-1 column:column-1];
	cell3 = [controller cellAtRow:row-1 column:column];
	
	cellArray = [[NSArray alloc] initWithObjects:cell, cell1, cell2, cell3, nil];
	return [cellArray autorelease];
}

- (NSArray *)shapeThreeFromCell:(GameGridCell *)cell 
					  rotatedAt:(int)degrees
				 withController:(id)controller
{
	NSArray *cellArray;
	
	cellArray = [[NSArray alloc] initWithObjects:cell, nil];
	return [cellArray autorelease];
}

- (NSArray *)shapeFourFromCell:(GameGridCell *)cell 
					  rotatedAt:(int)degrees
				 withController:(id)controller
{
	int row, column;
	GameGridCell *cell1, *cell2;
	
	NSArray *cellArray;
	
	[controller getRow:&row column:&column ofCell:cell];
	
	// Make sure the shape doesn't go out of bounds
	
	
	switch (degrees) {
		
		case 0:
			lastShape = SHAPE_FOUR_0; //So we remember what was the last shape
			
			if (row-1 < 0 || column-1 < 0)
				return nil;
				
			cell1 = [controller cellAtRow:row column:column-1];
			cell2 = [controller cellAtRow:row-1 column:column];
			break;
			
		case 90:
			lastShape = SHAPE_FOUR_90; //So we remember what was the last shape
			
			if (row+1 > [controller numberOfRows]-1 || column-1 < 0)
				return nil;
			
			cell1 = [controller cellAtRow:row column:column-1];
			cell2 = [controller cellAtRow:row+1 column:column-1];
			break;
			
		case 180:
			lastShape = SHAPE_FOUR_180; //So we remember what was the last shape
			
			if (column+1 > [controller numberOfColumns] || row+1 > [controller numberOfRows]-1)
				return nil;
			
			cell1 = [controller cellAtRow:row+1 column:column+1];
			cell2 = [controller cellAtRow:row+1 column:column];
			break;
			
		default:
			lastShape = SHAPE_FOUR_270; //So we remember what was the last shape
			
			if (row-1 < 0 || column-1 < 0)
				return nil;
			
			cell1 = [controller cellAtRow:row-1 column:column];
			cell2 = [controller cellAtRow:row-1 column:column-1];
			break;
	}
	
	cellArray = [[NSArray alloc] initWithObjects:cell, cell1, cell2, nil];
	return [cellArray autorelease];
}

- (NSArray *)shapeFiveFromCell:(GameGridCell *)cell 
					  rotatedAt:(int)degrees
				 withController:(id)controller
{
	int row, column;
	GameGridCell *cell1, *cell2, *cell3;
	
	NSArray *cellArray;
	
	[controller getRow:&row column:&column ofCell:cell];
	
	switch (degrees) 
	{
		case 0:
			lastShape = SHAPE_FIVE_0;
			
			// Make sure the shape doesn't go out of bounds
			if (row-1 < 0 || column-1 < 0 || column+1 > [controller numberOfColumns]-1)
				return nil;
				
			cell1 = [controller cellAtRow:row column:column+1];
			cell2 = [controller cellAtRow:row-1 column:column];
			cell3 = [controller cellAtRow:row-1 column:column-1];
			break;
			
		case 90:
			lastShape = SHAPE_FIVE_90;
			
			// Make sure the shape doesn't go out of bounds
			if (row-1 < 0 || 
				column+1 > [controller numberOfColumns]-1 || 
				row+1 > [controller numberOfRows]-1)
					return nil;
				
			cell1 = [controller cellAtRow:row column:column+1];
			cell2 = [controller cellAtRow:row-1 column:column+1];
			cell3 = [controller cellAtRow:row+1 column:column];
			break;
	}
	
	cellArray = [[NSArray alloc] initWithObjects:cell, cell1, cell2, cell3, nil];
	return [cellArray autorelease];

}

- (NSArray *)lastShapeFromCell:(GameGridCell *)cell withController:(id)controller
{
	switch (lastShape) {
		
		case SHAPE_ONE_0:
			return [self shapeOneFromCell:cell 
								rotatedAt:0
						   withController:controller];
			
		case SHAPE_ONE_90:
			return [self shapeOneFromCell:cell 
								rotatedAt:90
						   withController:controller];
		case SHAPE_TWO:
			return [self shapeTwoFromCell:cell 
								rotatedAt:0 
						   withController:controller];
			
		case SHAPE_THREE:
			return [self shapeThreeFromCell:cell 
								  rotatedAt:0 
							 withController:controller];
		case SHAPE_FOUR_0:
			return [self shapeFourFromCell:cell 
								  rotatedAt:0 
							 withController:controller];
		case SHAPE_FOUR_90:
			return [self shapeFourFromCell:cell 
								  rotatedAt:90 
							 withController:controller];
		case SHAPE_FOUR_180:
			return [self shapeFourFromCell:cell 
								  rotatedAt:180
							 withController:controller];
		case SHAPE_FOUR_270:
			return [self shapeFourFromCell:cell 
								  rotatedAt:270 
							 withController:controller];
							 
		case SHAPE_FIVE_0:
			return [self shapeFiveFromCell:cell 
								  rotatedAt:0 
							 withController:controller];
		case SHAPE_FIVE_90:
			return [self shapeFiveFromCell:cell 
								  rotatedAt:90 
							 withController:controller];
	
		default:
			return nil;
	}
}

- (NSArray *)lastShapeRotatedFromCell:(GameGridCell *)cell withController:(id)controller
{
	switch (lastShape) 
	{
		case SHAPE_ONE_0:
			lastShape = SHAPE_ONE_90;
			break;
		case SHAPE_ONE_90:
			lastShape = SHAPE_ONE_0;
			break;
			
		case SHAPE_TWO:
			lastShape = SHAPE_TWO;
			break;
			
		case SHAPE_THREE:
			lastShape = SHAPE_THREE;
			break;
			
		case SHAPE_FOUR_0:
			lastShape = SHAPE_FOUR_90;
			break;
		case SHAPE_FOUR_90:
			lastShape = SHAPE_FOUR_180;
			break;
		case SHAPE_FOUR_180:
			lastShape = SHAPE_FOUR_270;
			break;
		case SHAPE_FOUR_270:
			lastShape = SHAPE_FOUR_0;
			break;
		
		case SHAPE_FIVE_0:
			lastShape = SHAPE_FIVE_90;
			break;	
		case SHAPE_FIVE_90:
			lastShape = SHAPE_FIVE_0;
			break;
	}
	
	return [self lastShapeFromCell:cell withController:controller];
}

- (int)shape
{
	return lastShape;
}

- (int)currentShapeSquares
{
	switch (lastShape) 
	{
		case SHAPE_ONE_0:
			return 3;
			
		case SHAPE_ONE_90:
			return 3;
			
		case SHAPE_TWO:
			return 4;
			
		case SHAPE_THREE:
			return 1;
		
		case SHAPE_FOUR_0:
			return 3;
		case SHAPE_FOUR_90:
			return 3;
		case SHAPE_FOUR_180:
			return 3;
		case SHAPE_FOUR_270:
			return 3;
		
		case SHAPE_FIVE_0:
			return 4;
		case SHAPE_FIVE_90:
			return 4;
		
		default:
			return 4;
			
	}
}

- (void)setShape:(int)anInt
{
	lastShape = anInt;
}

@end
