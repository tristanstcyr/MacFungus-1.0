#import "RandomShapeView.h"
#import "GameGridCell.h"

@implementation RandomShapeView

- (void)drawRect:(NSRect)rect
{
	
	[[NSGraphicsContext currentContext] setShouldAntialias:NO];
	[super drawRect:rect];
	[[NSColor whiteColor] set];
	[[self calculateGridPath] stroke];
	
	NSView *superView = [self superview];
	[superView lockFocus];
		NSRect matrixRect = [superView bounds];
		matrixRect.size.width -= 1;
		matrixRect.size.height -= 1;
		[[NSGraphicsContext currentContext] setShouldAntialias:NO];
		[[NSColor disabledControlTextColor] set];
		[NSBezierPath strokeRect:matrixRect];
	[superView unlockFocus];
}

- (NSBezierPath *)calculateGridPath
{
	NSRect matrixRect = [self frame];
	NSBezierPath *grid;
	NSPoint drawPoint;
	matrixRect.size.width = [self numberOfColumns]*[self cellSize].width 
		+ [self intercellSpacing].width*([self numberOfColumns]-1) -1;
	matrixRect.size.height = [self numberOfRows]*[self cellSize].height 
							 + [self intercellSpacing].height*([self numberOfRows]-1) -1;
	
	matrixRect.origin.y = 1;
	matrixRect.origin.x = 0;
	grid = [NSBezierPath bezierPathWithRect:matrixRect];
	
	// Verticals
	for (drawPoint.x = 0; 
		 matrixRect.size.width > drawPoint.x; 
		 drawPoint.x += [self cellSize].width + [self intercellSpacing].width)
	{
		drawPoint.y = 0;
		[grid moveToPoint:drawPoint];
		drawPoint.y = matrixRect.size.height;
		[grid lineToPoint:drawPoint];
	}
	
	// Horizontals
	for (drawPoint.y = 0; 
		 matrixRect.size.height > drawPoint.y; 
		 drawPoint.y += [self cellSize].height + [self intercellSpacing].height)
	{
		drawPoint.x = 0;
		[grid moveToPoint:drawPoint];
		drawPoint.x = matrixRect.size.width;
		[grid lineToPoint:drawPoint];
	}	
	
	return grid;
}

- (void)clear
{
	NSArray *allCells = [self cells];
	int i;
	for(i=0; i<[allCells count];i++){
		[[allCells objectAtIndex:i] setColor:[NSColor whiteColor]];
		[self setNeedsDisplay:YES];
	}
	
}
- (void)drawShape:(NSArray *)cellArray withColor:(NSColor *)aColor
{
	int i, row, col;
	GameGridCell *cell;
	
	NSRect frame = [[self superview] frame];
	float minimumX = frame.size.width , 
	      maximumX = 0, 
		  minimumY = frame.size.height, 
		  maximumY = 0;
	
	for (i=0; i < [cellArray count]; i++)
	{
		NSRect cellFrame;
		cell = [cellArray  objectAtIndex:i] ;
		[self getRow:&row column:&col ofCell:cell];
		cellFrame = [self cellFrameAtRow:row column:col];
		
		if (cellFrame.origin.x < minimumX)
			minimumX = cellFrame.origin.x;
		if (cellFrame.origin.x + cellFrame.size.width > maximumX)
			maximumX = cellFrame.origin.x + cellFrame.size.width;
		if (cellFrame.origin.y < minimumY)
			minimumY = cellFrame.origin.y;
		if (cellFrame.size.height + cellFrame.origin.y > maximumY)
			maximumY = cellFrame.size.height + cellFrame.origin.y;
	}
	
	NSPoint shapeCenterPoint;
	shapeCenterPoint.x = (minimumX + maximumX)/2;
	shapeCenterPoint.y = (minimumY + maximumY)/2;
	
	NSPoint frameCenterPoint;
	frameCenterPoint.x = frame.size.width/2;
	frameCenterPoint.y = frame.size.height/2;

	[self setFrameOrigin:NSMakePoint(frameCenterPoint.x - shapeCenterPoint.x,
									 shapeCenterPoint.y - frameCenterPoint.y)];
	
	for (i=0; i < [cellArray count]; i++){
		cell = [cellArray  objectAtIndex:i] ;
		[cell setColor:aColor];
		[self drawCell:cell];
	}
	
	[self setNeedsDisplay:YES];
}

@end
