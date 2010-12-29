//
//  GameGridCell.m
//  MacFungus
//
//  Created by tristan on 02/06/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//s

#import "GameGridCell.h"


@implementation GameGridCell

-(id)init
{
	[super init];
	
	color = [NSColor whiteColor];
	[color retain];
	
	isHighlighted = NO;
	isHead = NO;
	isHotCorner = NO;
	return self;
}

#define EYESDISTANCEFROMTOP 2.5f
#define EYESDISTANCEFROMSIDE 4.5f
#define EYESLENGTH 3.5f

#define MOUTHDISTANCEFROMBORDER 2.5f

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	[[NSGraphicsContext currentContext] setShouldAntialias:NO];
	[color set];
	NSRectFill(cellFrame);
	
	if (isHead)
	{
		[[NSGraphicsContext currentContext] setShouldAntialias:YES];
		[self drawHeadInRect:cellFrame];
	}
		
	if (isHotCorner)
	{
		[[NSGraphicsContext currentContext] setShouldAntialias:YES];
		[self drawHotCornerInRect:cellFrame];
	}
	
	if (isHighlighted) {
		[[NSColor colorWithCalibratedWhite:0.8f alpha:0.4f] set];
		[NSBezierPath fillRect:cellFrame];
	}
}

- (void)setColor:(NSColor *)aColor
{
	[color release];
	color = [aColor retain];
}

- (NSColor *)color
{
	return color;
}

- (void)setIsHead:(BOOL)aBool
{
	isHead = aBool;
}

- (void)setAmazedHead:(BOOL)aBool
{
	isAmazedHead = aBool;
}

- (BOOL)isHead
{
	return isHead;
}

- (void)drawHeadInRect:(NSRect)aRect
{
	NSRect smallerCellFrame = aRect;
	smallerCellFrame.origin.x += 1.5;
	smallerCellFrame.size.width -= 3;
	smallerCellFrame.origin.y += 1.5;
	smallerCellFrame.size.height -= 3;
	
	// Draw the head
	{
		NSBezierPath *head = [NSBezierPath bezierPathWithOvalInRect:smallerCellFrame];
		[[NSColor whiteColor] set];
		[head fill];
		
		[[NSColor blackColor] set];
		[head setLineWidth:1.2];
		[head stroke];
	}
	
	// Draw the eyes
	{
		NSBezierPath *eyes = [[NSBezierPath alloc] init];
		NSPoint drawingPoint = smallerCellFrame.origin;
		drawingPoint.x += EYESDISTANCEFROMSIDE;
		drawingPoint.y += EYESDISTANCEFROMTOP;
		[eyes moveToPoint:drawingPoint];
		drawingPoint.y += EYESLENGTH;
		[eyes lineToPoint:drawingPoint];
		drawingPoint.x = smallerCellFrame.origin.x + smallerCellFrame.size.width - EYESDISTANCEFROMSIDE;
		[eyes moveToPoint:drawingPoint];
		drawingPoint.y -= EYESLENGTH;
		[eyes lineToPoint:drawingPoint];
		[eyes setLineWidth:1.2];
		[eyes stroke];
		[eyes release];
	}
	
	// DrawMouth
	if (isAmazedHead) {
		
		float originX, originY, width, height;
		height = width = 3.5f;
		
		originX = smallerCellFrame.origin.x + smallerCellFrame.size.width/2 - width/2;
		originY = smallerCellFrame.origin.y + smallerCellFrame.size.height - 5.0f;
		
		NSBezierPath *mouthAmazed = [NSBezierPath bezierPathWithOvalInRect:
			NSMakeRect( originX, originY, width, height )];
		[mouthAmazed setLineWidth:1.0f];
		[mouthAmazed stroke];
		
	} else {
		
		NSBezierPath *smile = [[NSBezierPath alloc] init];
		NSPoint drawPoint1, drawPoint2, controlPoint1, controlPoint2;
		
		drawPoint1.x = smallerCellFrame.origin.x + MOUTHDISTANCEFROMBORDER;
		drawPoint1.y = smallerCellFrame.origin.y + smallerCellFrame.size.height / 2;
		
		drawPoint2.y = drawPoint1.y;
		drawPoint2.x = smallerCellFrame.size.width + smallerCellFrame.origin.x - MOUTHDISTANCEFROMBORDER;
		
		controlPoint1.x = drawPoint1.x;
		controlPoint1.y = smallerCellFrame.size.height + smallerCellFrame.origin.y - MOUTHDISTANCEFROMBORDER + 1.0f;
		controlPoint2.x = drawPoint2.x;
		controlPoint2.y = controlPoint1.y;
		
		[smile moveToPoint:drawPoint1];
		[smile curveToPoint:drawPoint2 controlPoint1:controlPoint1 controlPoint2:controlPoint2];
		[smile stroke];
		[smile release];
	}
}

- (void)setHighlighted:(BOOL)aBool
{
	isHighlighted = aBool;
}

- (BOOL)isHighlighted
{
	return isHighlighted;
}

- (void)setIsHotCorner:(BOOL)aBool
{
	isHotCorner = aBool;
}

- (BOOL)isHotCorner
{
	return isHotCorner;
}

#define TRIANGLEDISTANCEFROMSIDES 5.0f
#define TRIANGLEDISTANCEFROMTOPBOTTOM 3.0f

- (void)drawHotCornerInRect:(NSRect)cellFrame
{
	NSPoint point1, point2, point3;
	
	point1.x = cellFrame.origin.x + TRIANGLEDISTANCEFROMSIDES;
	point1.y = cellFrame.origin.y + TRIANGLEDISTANCEFROMTOPBOTTOM;
	
	point2.x = cellFrame.origin.x + cellFrame.size.width - TRIANGLEDISTANCEFROMSIDES;
	point2.y = point1.y;
	
	point3.x = (point2.x + point1.x) / 2;
	point3.y = cellFrame.origin.y + cellFrame.size.height - TRIANGLEDISTANCEFROMTOPBOTTOM;
	
	NSBezierPath *trianglePath = [[NSBezierPath alloc] init];
	
	[trianglePath moveToPoint:point1];
	[trianglePath lineToPoint:point2];
	[trianglePath lineToPoint:point3];
	[[NSColor blackColor] set];
	[trianglePath fill];
	[trianglePath release];
}

- (void)dealloc
{
	[color release];
	[super dealloc];
}

@end
