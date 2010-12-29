//
//  GridShapeGenerator.h
//  MacFungus
//
//  Created by tristan on 03/06/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GameGridCell.h"



@interface GridShapeGenerator : NSObject {
	int lastShape;
	
}
- (NSArray *)shapeOneFromCell:(GameGridCell *)cell 
				   rotatedAt:(int)degrees 
			  withController:(id)controller;

- (NSArray *)shapeTwoFromCell:(GameGridCell *)cell 
					rotatedAt:(int)degrees
			   withController:(id)controller;

- (NSArray *)shapeThreeFromCell:(GameGridCell *)cell 
					rotatedAt:(int)degrees
			   withController:(id)controller;

- (NSArray *)shapeFourFromCell:(GameGridCell *)cell 
					  rotatedAt:(int)degrees
				 withController:(id)controller;
				 
- (NSArray *)shapeFiveFromCell:(GameGridCell *)cell 
					  rotatedAt:(int)degrees
				 withController:(id)controller;

- (NSArray *)lastShapeFromCell:(GameGridCell *)cell withController:(id)controller;
- (int)generateRandomShape;
- (NSArray *)generateRandomShapeFromCell:(GameGridCell *)cell
						  withController:(id)controller;
						  

			   
			   
- (NSArray *)lastShapeRotatedFromCell:(GameGridCell *)cell withController:(id)controller;

- (int)shape;
- (void)setShape:(int)anInt;
- (int)currentShapeSquares;
@end
