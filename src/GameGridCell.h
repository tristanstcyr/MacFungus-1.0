//
//  GameGridCell.h
//  MacFungus
//
//  Created by tristan on 02/06/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface GameGridCell : NSCell {
	NSColor *color;
	BOOL isHead;
	BOOL isHighlighted;
	BOOL isAmazedHead;
	BOOL isHotCorner;
}

- (NSColor *)color;
- (void)setColor:(NSColor *)aColor;

- (void)setIsHead:(BOOL)aBool;
- (BOOL)isHead;
- (void)drawHeadInRect:(NSRect)aRect;

- (void)setHighlighted:(BOOL)aBool;
- (BOOL)isHighlighted;

- (void)setAmazedHead:(BOOL)aBool;

- (void)setIsHotCorner:(BOOL)aBool;
- (BOOL)isHotCorner;
- (void)drawHotCornerInRect:(NSRect)cellFrame;
@end
