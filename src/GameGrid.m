#import "GameGrid.h"
#import "GameGridCell.h"
#import "RandomShapeView.h"
#import "GridShapeGenerator.h"
#import "PlayerCell.h"
#import "NSColor_Compare.h"

#import <objc/objc-runtime.h>; // for objc_msgSend()

#define COLOR_FOR_PLAYER(p) [[playersArray objectAtIndex:p] objectForKey:@"color"]
#define NAME_FOR_PLAYER(p) [[playersArray objectAtIndex:p] objectForKey:@"name"]
#define HEAD_FOR_PLAYER(p) [[playersArray objectAtIndex:p] objectForKey:@"head"]
#define CELL_COUNT_FOR_PLAYER(p) [[[playersArray objectAtIndex:p] objectForKey:@"cells"] count]
#define CELLS_FOR_PLAYER(p) [[playersArray objectAtIndex:p] objectForKey:@"cells"]
#define TIMED_ERASE(shape) [self drawShape:shape withColor:[NSColor whiteColor] animate:YES]
#define ERASE(shape) [self drawShape:shape withColor:[NSColor whiteColor] animate:NO]
#define BITES_FOR_HOTCORNER ([self numberOfRows]+[self numberOfColumns])/8

#define DEFAULTANIMATIONSPEED 0.2f

@implementation GameGrid

// Alloc/AwakeFromNib/Dealloc methods
// -------------------------------------------------------------------
- (void)awakeFromNib
{
	isResizingGrid = NO;
	mouseOverArray = nil;
	stopThread = NO;
	trackingRectTag = modifierKeysFlag = 0;
	
	animationSpeed = DEFAULTANIMATIONSPEED;
	GameGridCell *cell = [GameGridCell new];
	shapeGenerator = [GridShapeGenerator new];
	playersArray = [[NSMutableArray alloc] init];
	deadPlayers = [[NSMutableArray alloc] init];
	
	[self setAllowInput:NO];
	
	[statusTextField setStringValue:@"Go in the File menu to start a new game"];
	
	// Configuring grid
	
	[self initWithFrame:[self frame]
				   mode:NSRadioModeMatrix 
			  prototype:cell
		   numberOfRows:20
		numberOfColumns:20];
	
	[self setAllowsEmptySelection:NO];
	[self setIntercellSpacing:NSMakeSize(0.0f, 0.0f)];
	[self setCellSize:NSMakeSize(15.0f, 15.0f)];
	[self sizeToCells];
	[self setNeedsDisplay:YES];
	
	randomShapeView = [RandomShapeView alloc];
	[randomShapeView initWithFrame:NSMakeRect(0.0f, 0.0f, 0.0f, 0.0f)
							  mode:NSRadioModeMatrix 
						 prototype:cell
					  numberOfRows:5
				   numberOfColumns:5];
	
	[randomShapeView setAllowsEmptySelection:NO];
	[randomShapeView setIntercellSpacing:NSMakeSize(0.0f, 0.0f)];
	[randomShapeView setCellSize:NSMakeSize(15.0f, 15.0f)];
	[randomShapeView sizeToCells];
	[randomShapeViewBox addSubview:randomShapeView];
	[randomShapeView setNeedsDisplay:YES];
	
	//Set up players table
	PlayerCell *playerCell = [PlayerCell new];
	[[[playersTableView tableColumns] objectAtIndex:0] setDataCell:playerCell];
	float headerCellHeight = [[[[playersTableView tableColumns] objectAtIndex:0] headerCell] cellSize].height;
	float rowHeight = ([playersTableView frame].size.height - headerCellHeight) / 4 + 4.3f;
	[playersTableView setRowHeight:rowHeight];
	
	[[[playersTableView tableColumns] objectAtIndex:0] setWidth:[playersTableView frame].size.width];
	[playersTableView setIntercellSpacing:NSMakeSize(0,0)];
	
	//Configuring inputs
	[[self window] makeFirstResponder:self];
	
	NSPoint mouseLocation = [[self window] mouseLocationOutsideOfEventStream];
	trackingRectTag = [self addTrackingRect:[self bounds] 
									  owner:self
								   userData:nil 
							   assumeInside:[self mouse:mouseLocation inRect:[self frame]]];
	
	gridView = [[NSView alloc] initWithFrame:[self frame]];
	[gridView setNextResponder:self];
	[[self superview] addSubview:gridView];
	[self createGridPath];
}

- (void)dealloc
{
	if (mouseOverArray)
		[mouseOverArray release];
	if (playersArray)
		[playersArray release];
	if (deadPlayers)
		[deadPlayers release];
	[super dealloc];
}
@end
@implementation GameGrid(GameEvents)

- (void)startNewGameWithPlayers:(NSArray *)players 
					 controller:(id)aController 
					   gridSize:(int)gridSize
					 hotCorners:(BOOL)hotCorners
				 animationSpeed:(float)anAnimationSpeed
{
	int i;
	[self clear];
	stopThread = NO;
	controller = aController;
	currentPlayer = 0;
	modifierKeysFlag = 0;
	animationSpeed = anAnimationSpeed;
	
	[playersArray removeAllObjects];
	[deadPlayers removeAllObjects];
	
	
	[statusTextField setStringValue:@"Press space bar to rotate the shape"];
	
	 //Contains player information

	[self resizeGridAndWindowToGridSize:gridSize withPlayers:[players count]];
	
	NSArray *startPattern = [self startPatternWithPlayerQuantity:[players count]];
	
	for(i=0; i < [players count]; i++) 
	{ 
		GameGridCell *cell;
		NSMutableDictionary *player = [NSMutableDictionary new];
		NSColor *aColor = [[players objectAtIndex:i] objectForKey:@"color"];
		NSString *aName = [[players objectAtIndex:i] objectForKey:@"name"];
		[player setObject:aColor forKey:@"color"];
		[player setObject:aName forKey:@"name"];
		
		NSMutableArray *playerCells = [NSMutableArray new];
		
		// Find the next emplacement for the next player
		[player setObject:[NSNumber numberWithInt:3] forKey:@"bites"];
		cell = [startPattern objectAtIndex:i];
		
		//Configure head
		[cell setColor:[player objectForKey:@"color"]];
		[cell setIsHead:YES];
		[self drawCell:cell];
		[player setObject:cell forKey:@"head"];
		
		[playerCells addObject:cell];
		[player setObject:[playerCells autorelease] forKey:@"cells"];
		[player setObject:[NSNumber numberWithInt:0] forKey:@"newCells"];
		[player setObject:[NSNumber numberWithInt:0] forKey:@"bitesMinus"];
		[player setObject:[NSNumber numberWithBool:NO] forKey:@"isSelected"];
		[playersArray addObject:[player autorelease]];
	}
	
	// Setup hot corners
	if (hotCorners) {
		int lastRow = [self numberOfRows]-1,
			lastColumn = [self numberOfColumns]-1;
				
		GameGridCell *corner1 = [self cellAtRow:0 column:0], 
					 *corner2 = [self cellAtRow:0 column:lastColumn], 
					 *corner3 = [self cellAtRow:lastRow column:0], 
					 *corner4 = [self cellAtRow:lastRow column:lastColumn];
		
		[corner1 setIsHotCorner:YES];
		[self drawCell:corner1];
		[corner2 setIsHotCorner:YES];
		[self drawCell:corner2];
		[corner3 setIsHotCorner:YES];
		[self drawCell:corner3];
		[corner4 setIsHotCorner:YES];
		[self drawCell:corner4];
	}
	
	/* Selecting the first item on the list of the table because player 1 is always starting */
	[playersTableView selectRow:currentPlayer byExtendingSelection:NO];
	[playersTableView reloadData];
	
	{
		NSPoint mouseLocation = [[self window] mouseLocationOutsideOfEventStream];
		BOOL mouseInsideFrame = [self mouse:mouseLocation inRect:[self frame]];
		[[self window] setAcceptsMouseMovedEvents:mouseInsideFrame];
	}
	
	// Block input until we have a shape
	[NSThread detachNewThreadSelector:@selector(threadWaitForShape) 
							 toTarget:self
						   withObject:NULL];
}

- (void)performBiteOnCell:(GameGridCell *)cell
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[self setAllowInput:NO];
	isBusy = YES;
	int playerNumber = [self findPlayerForColor:[cell color]];
	
	// Remove a bite
	NSNumber *number = [NSNumber numberWithInt:
		[[[playersArray objectAtIndex:currentPlayer] objectForKey:@"bites"] intValue]- 1];
	[[playersArray objectAtIndex:currentPlayer] setObject:number forKey:@"bites"];
	[[playersArray objectAtIndex:currentPlayer] setObject:[NSNumber numberWithInt:0] forKey:@"bitesMinus"];
	
	[cell setHighlighted:NO];
	
	if ([cell isHead]) 
	{ 
		[cell setAmazedHead:YES];
		[self drawCell:cell]; // Looks cooler
	}
	
	ERASE([NSArray arrayWithObject:cell]);
	
	// Give some feedback
	[controller performSelectorOnMainThread: @selector(playSound:)
								 withObject:@"bite"
							  waitUntilDone:YES];
	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
	
	TIMED_ERASE([self checkForBrokenChainsForPlayer:playerNumber]);
	
	if (stopThread)
		goto bailout;
	
	if ([cell isHead]) 
	{
		[cell setIsHead:NO];
		[cell setAmazedHead:NO];
		[self drawCell:cell];
		[deadPlayers addObject:[playersArray objectAtIndex:playerNumber]];
	}
	
	[biteButton setState:NSOffState];
	
	if ([playersArray count] - 1 == [deadPlayers count])
		[self endGame];
	else
		[self evaluateInput];
	
	[playersTableView reloadData];

bailout:
	stopThread = NO;
	isBusy = NO;
	[pool release];
	[NSThread release];
}

- (void)performBigBiteOnCell:(GameGridCell *)cell
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	int i;
	isBusy = YES;
	
	NSColor *currentColor = COLOR_FOR_PLAYER(currentPlayer);
	NSMutableArray *biteArray = [[self bigBiteShapeFromCell:cell] retain];
	NSMutableArray *headsArray = [NSMutableArray new];
	
	// Remove 3 bites
	NSNumber *number = [NSNumber numberWithInt:
		[[[playersArray objectAtIndex:currentPlayer] objectForKey:@"bites"] intValue] - 3];
	[[playersArray objectAtIndex:currentPlayer] setObject:number forKey:@"bites"];
	[[playersArray objectAtIndex:currentPlayer] setObject:[NSNumber numberWithInt:0] forKey:@"bitesMinus"];
	
	
	{// Remove cells of player's own color color and look for head
		NSMutableArray *cellsToRemove =[NSMutableArray new];
		for (i = 0; i < [biteArray count] ; i++)
		{
			GameGridCell *aCell = [biteArray objectAtIndex:i];
			if ([aCell color] == currentColor)
				[cellsToRemove addObject:aCell];
				
			if ([aCell isHead] && [aCell color] != currentColor)
			{
				[deadPlayers addObject:[playersArray objectAtIndex:[self findPlayerForColor:[aCell color]]]];
				[aCell setAmazedHead:YES];
				[self drawCell:aCell];
				[headsArray addObject:aCell];
			}
		}
		[biteArray removeObjectsInArray:cellsToRemove];
	}
	
	// Erase the bite
	[self drawShape:biteArray withColor:[NSColor whiteColor] animate:NO];
	
	// Give some feedback sound
	[controller performSelectorOnMainThread: @selector(playSound:)
								 withObject:@"bigbite"
							  waitUntilDone:YES];
	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
	
	// Check for broken chains for all players
	for (i = 0 ; i < [playersArray count]; i++)
	{
		TIMED_ERASE([self checkForBrokenChainsForPlayer:i]);
		
		if (stopThread)
			goto bailout;
	}
	
	for (i = 0; i < [headsArray count]; i++)
	{
		GameGridCell *aHead = [headsArray objectAtIndex:i];
		[aHead setIsHead:NO];
		[aHead setAmazedHead:NO];
		[self drawCell:aHead];
	}
	
	if ([playersArray count] - 1 == [deadPlayers count])
		[self endGame];
	else
		[self evaluateInput];
	
	[playersTableView reloadData];
	
bailout:
	stopThread = NO;
	[biteArray release];
	[headsArray release];

	[pool release];
	[NSThread release];
	isBusy = NO;
}

- (void)playShapeForCell:(GameGridCell *)aCell
{
	BOOL hasEaten = NO;
	isBusy = YES;
	int i, cellsBefore = CELL_COUNT_FOR_PLAYER(currentPlayer);
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSColor *currentColor = COLOR_FOR_PLAYER(currentPlayer);
	NSMutableArray *disconnectedCells = [[NSMutableArray alloc] init];
	
	// Draw the initial shape
	NSArray *shape = [shapeGenerator lastShapeFromCell:aCell withController:self];
	[self drawShape:shape withColor:currentColor animate:NO];
	
	[self setAllowInput:NO];
	
	// Check if inital shape had a hot corner in it
	for (i=0 ; i < [shape count]; i++)
	{
		GameGridCell *aCell = [shape objectAtIndex:i];
		if ([aCell isHotCorner])
		{
			NSNumber *bitesNumber;
			int bites = [[[playersArray objectAtIndex:currentPlayer] objectForKey:@"bites"] intValue];
			bitesNumber = [NSNumber numberWithInt:(bites + BITES_FOR_HOTCORNER)];
			[[playersArray objectAtIndex:currentPlayer] setObject:bitesNumber forKey:@"bites"];
			[aCell setIsHotCorner:NO];
			[self drawCell:aCell];
		}
	}
	
	{ //Checking the diagonals of the diagonals...
	
		NSArray *loopArray = shape;
		NSMutableArray *diagonalsArray = [[NSMutableArray alloc] init];
		
		// Find the diagonals and draw them
		while (1) 
		{
			for(i=0; i < [loopArray count]; i++)
			{
				GameGridCell *cell = [loopArray objectAtIndex:i];
				NSArray *newDiagonals = [self checkDiagonalsWithCell:cell];
				if ([newDiagonals count])
					[self drawShape:newDiagonals withColor:currentColor animate:YES];
				if (stopThread)
					goto bailout;
				
				[diagonalsArray removeObjectsInArray:newDiagonals];
				[diagonalsArray addObjectsFromArray:newDiagonals];
			}
			
			if (![diagonalsArray count])
				break;
			
			hasEaten = YES;
			
			loopArray = [NSArray arrayWithArray:diagonalsArray]; 
			[diagonalsArray removeAllObjects];
		}
		
		[diagonalsArray release];
	}
	
	// If the player has eaten some squares, we need to check for broken chains
	for(i=0; i < [playersArray count] && hasEaten; i++)
	{
		NSArray *disconnectedCells = [self checkForBrokenChainsForPlayer:i];
		
		if ([disconnectedCells count] == CELL_COUNT_FOR_PLAYER(i)) 
		{
			GameGridCell *head = HEAD_FOR_PLAYER(i);
			[head setAmazedHead:YES];
			[self drawCell:head];
		}
		
		if ([disconnectedCells count]) 
			TIMED_ERASE(disconnectedCells);
			
		if (stopThread)
			goto bailout;
	}
	
	{ // The new bites to the player if he deserves
		
		int cellsAfter = CELL_COUNT_FOR_PLAYER(currentPlayer);
		int newCells = cellsAfter - cellsBefore;
		int cellsForBites = [[[playersArray objectAtIndex:currentPlayer] objectForKey:@"newCells"] intValue];
		cellsForBites += newCells;
		[[playersArray objectAtIndex:currentPlayer] setObject:[NSNumber numberWithInt:cellsForBites]																   forKey:@"newCells"];
		[self newBitesForPlayer:[playersArray objectAtIndex:currentPlayer]];
	}
	
	// Check for dead players
	for (i=0; i < [playersArray count]; i++) 
	{
		if (CELL_COUNT_FOR_PLAYER(i) == 0 && ![deadPlayers containsObject:[playersArray objectAtIndex:i]]) 
		{
			GameGridCell *head = HEAD_FOR_PLAYER(i);
			[head setIsHead:NO];
			[self drawCell:head];
			[deadPlayers addObject:[playersArray objectAtIndex:i]];
		}
	}
	
	[self switchToNextPlayer];
	
bailout:
	stopThread = NO;
	isBusy = NO;
	[disconnectedCells release];
	[pool release];
	[NSThread release];
}

- (void)switchToNextPlayer 
{
	
	// Check to see if there's more than one player alive
	// If YES block input and end the game
	if ([deadPlayers count] == ([playersArray count] - 1) || [playersArray count] == 1)
	{
		[self endGame];
		return;
	}
	
	//Changing Players
	do {
		if (currentPlayer < [playersArray count]-1) currentPlayer++;
		
		else currentPlayer = 0;
		
	} while ([deadPlayers containsObject:[playersArray objectAtIndex:currentPlayer]]);
	
	/*Select the player in the table */
	[playersTableView selectRow:currentPlayer byExtendingSelection:NO];
	[playersTableView reloadData];
	[playersTableView scrollRowToVisible:currentPlayer];
	
	// Block input until we have a shape
	[self setAllowInput:NO];
	[NSThread detachNewThreadSelector:@selector(threadWaitForShape) 
							 toTarget:self
						   withObject:NULL];
}

- (void)endGame
{
	[self setAllowInput:NO];
	
	NSString *finalPhrase = NAME_FOR_PLAYER(currentPlayer);
	finalPhrase = [finalPhrase stringByAppendingString:@" won the game!"];
	[statusTextField performSelectorOnMainThread:@selector(setStringValue:) 
									  withObject:finalPhrase 
								   waitUntilDone:NO];
	
	[controller performSelector:@selector(playSound:) withObject:@"drums"];
	if ([controller respondsToSelector:@selector(gameEnded)])
		[controller performSelectorOnMainThread:@selector(gameEnded) withObject:nil waitUntilDone:NO];
	
}

- (void)threadWaitForShape
{
	NSAutoreleasePool *autoPool = [[NSAutoreleasePool alloc] init];
	
	int nextShape;
	
	do {
		nextShape = (int)[controller performSelector:@selector(nextShape)];
		if (stopThread)
		{
			goto bailout;
		}
		
	} while (nextShape == 0);
	
	[shapeGenerator setShape:nextShape];
	[randomShapeView clear];
	NSArray *shape;
	shape = [shapeGenerator lastShapeFromCell:[randomShapeView cellAtRow:2 column:2] 
									  withController:randomShapeView];

	NSColor *currentColor = COLOR_FOR_PLAYER(currentPlayer);
	[randomShapeView drawShape:shape withColor:currentColor];
	
	[self evaluateInput];
	
bailout:
	stopThread = NO;
	[autoPool release];
}

- (void)rotateShape
{
	{ // Change the shape in randomShapeView
		NSArray *shape;
		[randomShapeView clear];
		shape = [shapeGenerator lastShapeRotatedFromCell:[randomShapeView cellAtRow:2 column:2] 
										  withController:randomShapeView];
		[randomShapeView drawShape:shape withColor:COLOR_FOR_PLAYER(currentPlayer)];
	}
	
	if (mouseOverArray) { //Erase the old mouse-over
		[self changeShapeHighlight:mouseOverArray to:NO];
		[mouseOverArray release];
		mouseOverArray = nil;
	}
	mouseOverCell = nil;
	[self mouseMoved:[NSEvent mouseEventWithType:NSMouseMoved 
											location:[mainWindow mouseLocationOutsideOfEventStream]
									   modifierFlags:modifierKeysFlag
										   timestamp:0.0
										windowNumber:0
											 context:nil
									     eventNumber:0
										  clickCount:1
											pressure:0]];
}

- (void)switchBiteButton
{	
	if([biteButton state] == NSOnState)
		[biteButton setState:NSOffState];
	else
		[biteButton setState:NSOnState];
}

- (IBAction)skipTurn:(NSEvent *)sender 
{
	if (mouseOverArray)
	{
		[self changeShapeHighlight:mouseOverArray to:NO];
		[mouseOverArray release];
		mouseOverArray = nil;
		
	}
	mouseOverCell = nil;
	
	[skipTurnButton setEnabled:NO];

	[controller performSelector:@selector(currentPlayerSkippedTurn:) withObject:controller];
}

- (IBAction)biteButtonPushed:(NSEvent *)sender
{
	if (mouseOverArray)
	{
		[self changeShapeHighlight:mouseOverArray to:NO];
		[mouseOverArray release];
		mouseOverArray = nil;
	}
	
	[mouseOverCell setHighlighted:NO];
	[self drawCell:mouseOverCell];
	mouseOverCell = nil;
	
	if ([biteButton state] == NSOnState)
		[statusTextField setStringValue:@"Press shift key for bigger bites"];
	else
	{
		[[playersArray objectAtIndex:currentPlayer] setObject:[NSNumber numberWithInt:0] forKey:@"bitesMinus"];
		[playersTableView reloadData];
		[statusTextField setStringValue:@"Press space bar to rotate the shape"];
	}
	
	NSPoint mouseLocation = [mainWindow mouseLocationOutsideOfEventStream];
		if ([[mainWindow contentView] mouse:mouseLocation inRect:[self frame]])
		{
			NSEvent *mouseDownEvent = [NSEvent mouseEventWithType:NSMouseMoved
														 location:mouseLocation
													modifierFlags:0
														timestamp:[NSDate timeIntervalSinceReferenceDate]
													 windowNumber:[mainWindow windowNumber]
														  context:[NSGraphicsContext currentContext]
													  eventNumber:1
													   clickCount:1
														 pressure:1];
			[self mouseMoved:mouseDownEvent];
		}
	
	[controller performSelector:@selector(currentPlayerPressedBiteButton:) withObject:controller];
}

- (void)newBitesForPlayer:(NSDictionary *)aPlayer
{
	int cellsForNewBite = [self numberOfRows]*2;
	int newCells = [[aPlayer objectForKey:@"newCells"] intValue];
	int newBites = newCells / cellsForNewBite;
	
	if (newBites == 0)
		return;
	
	int remainderCells = newCells % cellsForNewBite;
	[aPlayer setValue:[NSNumber numberWithInt:remainderCells] forKey:@"newCells"];
	
	int playerBites = [[aPlayer objectForKey:@"bites"] intValue];
	playerBites += newBites;
	[aPlayer setValue:[NSNumber numberWithInt:playerBites] forKey:@"bites"];
	[playersTableView reloadData];
}

@end

@implementation GameGrid(GridLogic)

#define DISTANCEFROMBORDER ([self numberOfRows]/5)
- (NSArray *)startPatternWithPlayerQuantity:(int)players
{
	// Method Description:
	// Returns what the next startup cell should be
	int distanceFromMax = [self numberOfRows] - DISTANCEFROMBORDER - 1;
	return	[NSArray arrayWithObjects:[self cellAtRow:DISTANCEFROMBORDER column:DISTANCEFROMBORDER],
									  [self cellAtRow:distanceFromMax column:distanceFromMax],
									  [self cellAtRow:DISTANCEFROMBORDER column:distanceFromMax],
									  [self cellAtRow:distanceFromMax column:DISTANCEFROMBORDER], nil];
}

- (NSArray *)checkForSimilarColorWithMovementOnRow:(int)encrementOnRow 
										  onColumn:(int)encrementOnColumn
										  fromCell:(GameGridCell *)cell
{
	// Method Description:
	/* Moves through columns and rows at indicated encrements to find a similar color 
	Every cell that is not of the same color is put in to an array. If we ever find a cell of the same color
	the cells in the array are returned */
	
	int row, column;
	GameGridCell *secondCell;
	NSMutableArray *cellArray = [[NSMutableArray alloc] init];
	
	[self getRow:&row column:&column ofCell:cell];
	
	while ( (row += encrementOnRow) < [self numberOfRows] && 
	(column += encrementOnColumn) < [self numberOfColumns] && row >= 0 && column >= 0)
	{
		secondCell = [self cellAtRow:row column:column];
		
		if ([secondCell color] == [[playersArray objectAtIndex:currentPlayer] objectForKey:@"color"])
			return [cellArray autorelease];
		else if ([secondCell color] == [NSColor whiteColor])
			break;
			
		[cellArray addObject:secondCell];
	}
	
	[cellArray release];
	return nil;
}

- (NSArray *)checkForBrokenChainsForPlayer:(int)playerIndex;
{
	int i;
	NSColor *color = COLOR_FOR_PLAYER(playerIndex);
	GameGridCell *head = HEAD_FOR_PLAYER(playerIndex);
	
	// If the head is eaten, everything gos
	if ([head color] != color)
		return [NSArray arrayWithArray:CELLS_FOR_PLAYER(playerIndex)];

	NSMutableArray *loopArray = [[NSMutableArray alloc] init];
	NSMutableArray *connectedCells = [[NSMutableArray alloc] init];
	[loopArray addObject:head];
	[connectedCells addObject:head];
	
	// Checks for the neighbors of the neighbors...starting from the head
	while ([loopArray count] > 0) {
		
		NSMutableArray *newNeighbors = [[NSMutableArray alloc] init];
		
		for (i=0; i < [loopArray count]; i++) {
			
			int y;
			GameGridCell *cell = [loopArray objectAtIndex:i];
			
			NSArray *immediateNeighbors = [self neighborsOfSameColorForCell:cell withColor:color];
			
			for (y = 0; y < [immediateNeighbors count]; y++)
			{
				GameGridCell *aNeighborCell = [immediateNeighbors objectAtIndex:y];
				if (![connectedCells containsObject:aNeighborCell] && 
				![loopArray containsObject:aNeighborCell] &&
				![newNeighbors containsObject:aNeighborCell])
					[newNeighbors addObject:aNeighborCell];
			}
		}
		[loopArray setArray:newNeighbors];
		
		[connectedCells addObjectsFromArray:newNeighbors];
		
		[newNeighbors release];
	}
	
	NSMutableArray *disconnectedCells = [NSMutableArray arrayWithArray:CELLS_FOR_PLAYER(playerIndex)];
	[disconnectedCells removeObjectsInArray:connectedCells];
	
	[connectedCells release];
	[loopArray release];
	
	return disconnectedCells;
}

- (NSArray *)neighborsOfSameColorForCell:(GameGridCell *)cell withColor:(NSColor *)aColor
{
	// Method Description:
	/* Verifies if the cell has anny neighbors of the same color */
	int row, column, i;
	NSMutableArray *closeNeighborArray =[[NSMutableArray alloc] init];
	NSMutableArray *neighborOfSameColorArray = [[NSMutableArray alloc] init];
	GameGridCell *neighborCell;
	[self getRow:&row column:&column ofCell:cell];
	
	if(neighborCell = [self cellAtRow:row column:column-1])//On left
		[closeNeighborArray addObject:neighborCell];
	
	if (column+1 <= [self numberOfColumns]-1) 
	{
		neighborCell = [self cellAtRow:row column:column+1];
		[closeNeighborArray addObject:neighborCell];  //On Right
	}
	
	if (neighborCell = [self cellAtRow:row-1 column:column])
		[closeNeighborArray addObject:neighborCell];  //On Top
	
	if (row+1 <= [self numberOfRows]-1)
	{
		neighborCell = [self cellAtRow:row+1 column:column];
		[closeNeighborArray addObject:neighborCell];  //On Bottom
	}
	
	//Going through array
	i = 0;
	while (i < [closeNeighborArray count]){
		if ([[closeNeighborArray objectAtIndex:i] color] == aColor) 
		{
			[neighborOfSameColorArray addObject:[closeNeighborArray objectAtIndex:i]];
		}
		i++;
	}
	[closeNeighborArray autorelease];
	[neighborOfSameColorArray autorelease];
	
	return neighborOfSameColorArray;
}

- (NSArray *)checkDiagonalsWithCell:(GameGridCell *)cell
{
	// Method Description:
	/*	This method takes a cell and uses the checkForSimilarColor on row to find if cells
	of the same color sandwich cells of different colors (except white) 
	The result is then colected and returned */
	
	int row, column;
	NSMutableArray *tempArray = [[NSMutableArray alloc] init];
	id results;
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self getRow:&row column:&column ofCell:cell];
	
	//Check left
	if (column > 2){ //Makes sure theres a far neighboor on left
		results = [self checkForSimilarColorWithMovementOnRow:0 onColumn:-1 fromCell:cell];
		if (results!=nil)
			[tempArray addObjectsFromArray:results];
	}
	
	/*Check top left diagonal */
	if ((column > 2) && (row > 2)){ //Makes sure theres a far neighboor on top left
		results = [self checkForSimilarColorWithMovementOnRow:-1 onColumn:-1 fromCell:cell];
		if (results!=nil)
			[tempArray addObjectsFromArray: results];
	}
	/*Check top right diagonal */
	if ((column < [self numberOfColumns] - 2) && (row > 1)){
		results = [self checkForSimilarColorWithMovementOnRow:-1 onColumn:1 fromCell:cell];
		if (results!=nil)
			[tempArray addObjectsFromArray:results];
	}
	//Check right
	if (column < [self numberOfColumns] - 2){ //Makes sure theres a far neighboor on right
		results = [self checkForSimilarColorWithMovementOnRow:0 onColumn:1 fromCell:cell];
		if (results!=nil)
			[tempArray addObjectsFromArray:results];
	}
	//Check bottom left
	if ((column > 1) && (row < ([self numberOfRows] - 2))){
		results = [self checkForSimilarColorWithMovementOnRow:1 onColumn:-1 fromCell:cell];
		if (results!=nil)
			[tempArray addObjectsFromArray:results];
	}
	//Check Bottom
	if (row < [self numberOfRows] - 2){ //Makes sure theres a far neighboor on top
		results = [self checkForSimilarColorWithMovementOnRow:1 onColumn:0 fromCell:cell];
		if (results!=nil)
			[tempArray addObjectsFromArray:results];
	}
	//Check bottom right
	if (column < [self numberOfColumns] - 2 && row < [self numberOfRows] - 2){
		results = [self checkForSimilarColorWithMovementOnRow:1 onColumn:1 fromCell:cell];
		if (results!=nil)
			[tempArray addObjectsFromArray:results];
	}
	//Check Top
	if (row > 2){ //Makes sure theres a far neighboor on top
		results = [self checkForSimilarColorWithMovementOnRow:-1 onColumn:0 fromCell:cell];
		if (results!=nil)
			[tempArray addObjectsFromArray:results];
	}
	
	[pool release];
	return [tempArray autorelease];
}

@end

@implementation GameGrid(PlayersManipulation)

- (void)removePlayerWithColor:(NSColor *)aColor
{
	NSAutoreleasePool *autoPool = [[NSAutoreleasePool alloc] init];
	while (isBusy) {
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
	}
	isBusy = YES;
	[self setAllowInput:NO];
	
	int playerIndex = [self findPlayerForColor:aColor];
	if (playerIndex < 0)
		return;
	
	NSArray *playerCells = [CELLS_FOR_PLAYER(playerIndex) copy];
	TIMED_ERASE(playerCells);
	if (stopThread)
		goto bailout;
	
	[playerCells release];
	
	GameGridCell *head = HEAD_FOR_PLAYER(playerIndex);
	[head setIsHead:NO];
	[self drawCell:head];
	[playersArray removeObjectAtIndex:playerIndex];
	
	if (currentPlayer == playerIndex)
	{
		currentPlayer -= 1;
		[self switchToNextPlayer];
	}
	else if (currentPlayer >= playerIndex)
		currentPlayer -= 1;
	
	[playersTableView reloadData];
	
	if ([playersArray count] == 1) [self endGame];
	else [self evaluateInput];
		
	isBusy = NO;
bailout:
	[autoPool release];
}


- (int)findPlayerForColor:(NSColor *)aColor
{
	int i;
	NSColor *playerColor;
	
	if (aColor == [NSColor whiteColor])
		return -1;
	
	for (i = 0; i < [playersArray count]; i++) {
		playerColor = [[playersArray objectAtIndex:i] objectForKey:@"color"];
		if ([NSColor color:playerColor isEqualToColor:aColor])
			return i;
	}
	
	return -1;	
}

- (NSColor *)currentPlayerColor
{
	return COLOR_FOR_PLAYER(currentPlayer);
}
@end

@implementation GameGrid(Drawing)

- (NSSize)cellSizeConsideringBounds
{
	NSSize cellSize;
	cellSize.width = [self frame].size.width / [self numberOfColumns];
	cellSize.height = [self frame].size.height / [self numberOfRows];
	
	return cellSize;
}

- (void)drawRect:(NSRect)aRect
{
	// Draw the background
	[[NSGraphicsContext currentContext] setShouldAntialias:NO];
	[[NSColor whiteColor] set];
	[NSBezierPath fillRect:aRect];
	
	// Draw the cells
	[super drawRect:aRect];
	
	// Draw the grid in the gridview
	[gridView lockFocus]; 
	{
		[[NSGraphicsContext currentContext] setShouldAntialias:NO];
		[[NSColor gridColor] set];
		[gridPath stroke];
		
		[[NSGraphicsContext currentContext] setShouldAntialias:YES];
		NSRect frame = [gridView bounds];
		NSBezierPath *path = [NSBezierPath bezierPathWithRect:frame];
		[[NSColor disabledControlTextColor] set];
		[path setLineWidth:1.5f];
		[path stroke];
	} 
	[gridView unlockFocus];
}

- (NSArray *)bigBiteShapeFromCell:(GameGridCell *)cell
{
	int row, column;
	GameGridCell *cell1, *cell2, *cell3;
	
	NSMutableArray *cellArray;
	
	[self getRow:&row column:&column ofCell:cell];
	
	cell1 = [self cellAtRow:row column:column-1];
	cell2 = [self cellAtRow:row-1 column:column-1];
	cell3 = [self cellAtRow:row-1 column:column];
	
	cellArray = [[NSMutableArray alloc] initWithObjects:cell, cell1, cell2, cell3, nil];
	return [cellArray autorelease];
}

- (void)changeShapeHighlight:(NSArray *)cellArray to:(BOOL)isHighlighted
{
	int i;
	if (!cellArray || [cellArray count] == 0)
		return;
		
	for (i = 0 ; i < [cellArray count]; i++)
	{
		GameGridCell *aCell = [cellArray objectAtIndex:i];
		[aCell setHighlighted:isHighlighted];
		[self drawCell:aCell];
	}
}

- (void)drawShape:(NSArray *)cellArray 
		withColor:(NSColor *)aColor 
		  animate:(BOOL)animate
{	
	if (!cellArray) { NSLog(@"drawShape:cellArray was nil"); return; }
	if (!aColor){NSLog(@"drawShape:!aColor was nil"); return; }	
	if (![cellArray count]){ NSLog(@"drawShape:Cell array was empty"); return; }
	if (stopThread) return;
	
	int i, lastPlayerNumber, playerNumber= [self findPlayerForColor:aColor];
	NSString *soundName = nil;
	
	if (aColor == [NSColor whiteColor])
		soundName = @"phaser";
	else
		soundName = @"bite";
	
	for (i=0; i < [cellArray count]; i++)
	{
		if (stopThread)
			return;
		
		//Get the cell to be drawn
		GameGridCell *cell = [cellArray  objectAtIndex:i];
		
		// Remove cell from the old player
		if ((lastPlayerNumber = [self findPlayerForColor:[cell color]]) >= 0)
			[CELLS_FOR_PLAYER(lastPlayerNumber) removeObject:cell];
		
		//Add the cell to the player
		if (playerNumber >= 0)
			[CELLS_FOR_PLAYER(playerNumber) addObject:cell];
		
		// Change the color and redraw
		[cell setColor:aColor];
		[self drawCell:cell];
		[playersTableView reloadData];
		
		if (animate)
		{
			if (stopThread) return;
			
			[controller performSelector:@selector(playSound:) withObject:soundName];
			[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:animationSpeed]];
		}
	}
}

- (void)clear
{
	int i;
	stopThread = YES;
	NSArray *array = [self cells];
	GameGridCell *cell;
	for (i=0;i<[array count];i++) {
		cell = [array objectAtIndex:i] ;
		[cell setColor:[NSColor whiteColor]];
		[cell setIsHead:NO];
		[cell setAmazedHead:NO];
		[cell setIsHotCorner:NO];
	}
	
	[statusTextField setStringValue:@"Go in the File menu to start a new game"];
	[self setNeedsDisplay:YES];
	[playersArray removeAllObjects];
	[playersTableView reloadData];
	[randomShapeView clear];
	
	isBusy = NO;
}

- (void)createGridPath
{
	NSPoint drawPoint;
	NSRect matrixRect = [gridView bounds];
	NSSize cellSize = [self cellSizeConsideringBounds];
	
	if (gridPath) [gridPath release];
	gridPath = [[NSBezierPath alloc] init];
	[gridPath setLineWidth:0.5f];
	
	// Verticals 
	for (drawPoint.x = matrixRect.origin.x ; matrixRect.size.width > drawPoint.x; drawPoint.x += cellSize.width)
	{
		drawPoint.y = matrixRect.origin.y;
		[gridPath moveToPoint:drawPoint];
		drawPoint.y = matrixRect.size.height;
		[gridPath lineToPoint:drawPoint];
	}
	
	// Horizontals
	for (drawPoint.y = matrixRect.origin.y; matrixRect.size.height > drawPoint.y; drawPoint.y += cellSize.height)
	{
		drawPoint.x = matrixRect.origin.x;
		[gridPath moveToPoint:drawPoint];
		drawPoint.x = matrixRect.size.width;
		[gridPath lineToPoint:drawPoint];
	}
}

- (BOOL)isResizingGrid
{
	return isResizingGrid;
}

- (void)resizeGridAndWindowToGridSize:(int)gridSize withPlayers:(int)players
{
	int rowDifference ;
	
	if ( !(rowDifference = gridSize - [self numberOfRows]) )
		return;
	
	NSRect windowRect = [mainWindow frame];
	NSRect visibleFrame = [[mainWindow screen] visibleFrame];
	NSRect bounds = [self bounds];
	
	float sizeDifference;
	
	// Do not let the bounds be bigger than the frame
	if (bounds.size.width > [self frame].size.width)
		sizeDifference = [self cellSize].width * gridSize - [self cellSizeConsideringBounds].width * [self numberOfRows];
	else
		sizeDifference = [self cellSizeConsideringBounds].width * rowDifference;
	
	// if the window does not fit inside the screen accept to make the bounds smaller
	if (windowRect.size.height + sizeDifference > visibleFrame.size.height)
		sizeDifference = visibleFrame.size.height - windowRect.size.height;

	{ // Do not let the player's table view get smaller than its cells
		
		float rowHeight = [playersTableView rowHeight],
			  tableViewHeight = [playersTableView frame].size.height,
		      cellsHeight = rowHeight * players;
		if (cellsHeight > tableViewHeight + sizeDifference)
			sizeDifference += cellsHeight - (tableViewHeight + sizeDifference);
	}
	
	
	// Add the necessary size to the window to fit the grid
	windowRect.size.width += sizeDifference;
	windowRect.size.height += sizeDifference;
	windowRect.origin.y -= sizeDifference;
	windowRect.origin.x -= sizeDifference/2;
	
	// Fix the bounds
	bounds.size.width = [self cellSize].width  * ( [self numberOfRows] + rowDifference );
	bounds.size.height = [self cellSize].height * ( [self numberOfColumns] + rowDifference );
	
	// Make sure the window doesn't go off screen
	if (windowRect.origin.y < visibleFrame.origin.y)
		windowRect.origin.y = visibleFrame.origin.y;
	if (windowRect.origin.x + windowRect.size.width > visibleFrame.size.width + visibleFrame.origin.x)
		windowRect.origin.x = visibleFrame.origin.x + visibleFrame.size.width - windowRect.size.width;
	
	isResizingGrid = YES;
	[self createGridPath];
	[self renewRows:gridSize columns:gridSize];

	[mainWindow setFrame:windowRect display:YES animate:YES];
	
	[self setBounds:bounds];
	isResizingGrid = NO;
	
	{ // Fix tracking rect
		if (trackingRectTag)
			[self removeTrackingRect:trackingRectTag];
		
		NSPoint mouseLocation = [[self window] mouseLocationOutsideOfEventStream];
		BOOL isMouseInsiderFrame = [self mouse:mouseLocation inRect:[self frame]];
		[[self window] setAcceptsMouseMovedEvents:isMouseInsiderFrame];
		trackingRectTag = [self addTrackingRect:[self bounds] 
										  owner:self
									   userData:nil 
								   assumeInside:isMouseInsiderFrame];
	}
}

- (void)setFrame:(NSRect)aFrame
{
	NSRect bounds = [self bounds];
	[gridView setFrame:aFrame];
	[super setFrame:aFrame];
	[self setBounds:bounds];
	[self createGridPath];
	NSPoint mouseLocation = [[self window] mouseLocationOutsideOfEventStream];
	if (trackingRectTag)
		[self removeTrackingRect:trackingRectTag];
	trackingRectTag = [self addTrackingRect:[self bounds] 
									  owner:self
								   userData:nil 
							   assumeInside:[self mouse:mouseLocation inRect:[self frame]]];
}

- (BOOL)isBusy
{
	return isBusy;
}

@end

@implementation GameGrid(Input)

- (void)evaluateInput
{
	NSColor *controllerColor = [controller performSelector:@selector(color)];
	
	
	if([self findPlayerForColor:controllerColor] == currentPlayer) {
		
		[statusTextField performSelectorOnMainThread:@selector(setStringValue:)
										  withObject:@"Press the space bar to rotate the shape" 
									   waitUntilDone:YES];
		[self setAllowInput:YES];
		NSPoint mouseLocation = [mainWindow mouseLocationOutsideOfEventStream];
		
		if ([[mainWindow contentView] mouse:mouseLocation inRect:[self frame]])
		{
			NSEvent *mouseMovedEvent = [NSEvent mouseEventWithType:NSMouseMoved
														 location:mouseLocation
													modifierFlags:0
														timestamp:[NSDate timeIntervalSinceReferenceDate]
													 windowNumber:[mainWindow windowNumber]
														  context:[NSGraphicsContext currentContext]
													  eventNumber:1
													   clickCount:1
														 pressure:1];
			[self mouseMoved:mouseMovedEvent];
		}
		
	} else {
		
		NSString *playerName = NAME_FOR_PLAYER(currentPlayer);
		NSString *statusString = 
			[NSString stringWithFormat:@"Waiting for %@ to finish his turn", playerName];
		
		[statusTextField performSelectorOnMainThread:@selector(setStringValue:)
										  withObject:statusString 
									   waitUntilDone:YES];
		
		[self setAllowInput:NO];
	}
}

- (void)setAllowInput:(BOOL)allowInput
{
	if (allowInput)
	{
	
	int bites = [[[playersArray objectAtIndex:currentPlayer] objectForKey:@"bites"] intValue];
	
	[biteButton setEnabled:( bites > 0 ? YES : NO)];

	[skipTurnButton setEnabled:YES];
	
	canInput = YES;
	
	} else {
		canInput = NO;
		[biteButton setEnabled:NO];
		[biteButton setState:NSOffState];
		[skipTurnButton setEnabled:NO];
	}
}

- (BOOL)canInput
{
	return canInput;
}

// Input methods
//  -------------------------------------------------------------------

- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (BOOL)becomeFirstResponder
{
	return YES;
}

- (void)mouseDown:(NSEvent *)theEvent
{
	// Method description:
	// Verifies if a lastDrawnShape exists. If yes it calls the end of turn method.
	// Performs a bite if the bite button is On.
	
	if (![[self window] isKeyWindow])
	{
		[[self window] makeKeyAndOrderFront:self];
		[[self window] makeFirstResponder:self];
		return;
	}
	
	if (![self canInput])
	{
		NSBeep();
		return;
	}
	
	if ([theEvent type] == NSRightMouseDown)
	{
		[controller performSelector:@selector(currentPlayerRotatedShape:) withObject:controller];
		return;
	}
	
	
	while (1)
	{
		theEvent = [ [ self window ] nextEventMatchingMask: NSLeftMouseUpMask & 
															 NSLeftMouseDraggedMask &
															 NSFlagsChangedMask];
		if ([theEvent type] == NSLeftMouseUp)
		{
			[self mouseUp:theEvent];
			return;
		}
		
		if ([theEvent type] == NSLeftMouseDragged)
			[self mouseMoved:theEvent];
		else if ([theEvent type] == NSFlagsChangedMask)
			[self modifierKeysChanged:theEvent];
	}
} 

- (void)mouseUp:(NSEvent *)theEvent
{
	int i;
	NSColor *playerColor = COLOR_FOR_PLAYER(currentPlayer);
	
	if (!mouseOverArray || [mouseOverArray count] == 0)
		goto bailout;
	
	BOOL foundNeighbor = NO;
	
	for (i = 0 ; i < [mouseOverArray count] ; i++)
	{
		if([[self neighborsOfSameColorForCell:[mouseOverArray objectAtIndex:i]
									withColor:playerColor] count] > 0)
		{
			foundNeighbor = YES;
			break;
		}
	}
				
	if (!foundNeighbor)
		goto bailout;
	
	if ([biteButton state] == NSOnState) 
	{
		SEL aSelector;
		int row, col;
		int playerBites = [[[playersArray objectAtIndex:currentPlayer] objectForKey:@"bites"] intValue];
		[self setAllowInput:NO];
		[self changeShapeHighlight:mouseOverArray to:NO];
		
		if ((modifierKeysFlag & NSShiftKeyMask)!= 0 && playerBites >= 3)
			aSelector = @selector(currentPlayerPlacedBigBiteAtRow:column:sender:);
		else
			aSelector = @selector(currentPlayerPlacedBiteAtRow:column:sender:);
		
		[self getRow:&row column:&col ofCell:mouseOverCell];
		objc_msgSend(controller, aSelector, row, col, controller);
		
		mouseOverCell = nil;
		
		return;
	} 
	else
	{
		[self setAllowInput:NO];
		if ([mouseOverArray count] != [shapeGenerator currentShapeSquares])
			goto bailout;
			
		int row, col;
		[self changeShapeHighlight:mouseOverArray to:NO];
		[mouseOverArray release];
		mouseOverArray = nil;
		
		[self getRow:&row column:&col ofCell:mouseOverCell];
		mouseOverCell = nil;
		
		objc_msgSend(controller, @selector(currentPlayerPlacedShapeAtRow:column:sender:)
					 , row, col, controller);
		return;
	}
	
bailout:
		NSBeep();
		[self setAllowInput:YES];
		
}

- (void)mouseEntered:(NSEvent *)theEvent
{
	// Method description:
	// Mouse tracking is expensive. We only want it when it is inside the view
	[[self window] setAcceptsMouseMovedEvents:YES];
}

- (void)mouseExited:(NSEvent *)theEvent
{
	// Method description:
	// Mouse tracking is expensive. We only want it when it is inside the view
	[[self window] setAcceptsMouseMovedEvents:NO];
	
	if (mouseOverArray)
	{
		[self changeShapeHighlight:mouseOverArray to:NO];
		[mouseOverArray release];
		mouseOverArray = nil;
	}
}

- (void)mouseMoved:(NSEvent *)theEvent
{
	// Method description:
	/* Finds the cell under the cursor. If it can draw the 
	random shape with the mouseOverColor */
	if (![self canInput] || isBusy || ![mainWindow acceptsMouseMovedEvents]){
		return;
	}
	
	GameGridCell *cell;
	
	{ // Find what cell is under the cursor
		int row, column;
		NSPoint point = [theEvent locationInWindow]; 
		NSPoint pointInView = [self convertPoint:point fromView:nil];
		[self getRow:&row column:&column forPoint:pointInView];
		cell = [self cellAtRow:row column:column];
	}
	
	// Check if mouseOverCell changed
	if (cell == mouseOverCell)
		return; 
	
	// Erase the previous array
	if (mouseOverArray)
	{
		[self changeShapeHighlight:mouseOverArray to:NO];
		[mouseOverArray release];
		mouseOverArray = nil;
	}
	
	mouseOverCell = cell;
	
	// If it's a bite
	if ([biteButton state] == NSOnState) 
	{ 
		NSColor *playerColor = COLOR_FOR_PLAYER(currentPlayer);
		int playerBites = [[[playersArray objectAtIndex:currentPlayer] objectForKey:@"bites"] intValue];
		
		if (([theEvent modifierFlags] & NSShiftKeyMask) != 0 && playerBites >= 3) 
		{
			[[playersArray objectAtIndex:currentPlayer] setObject:[NSNumber numberWithInt:3] 
														   forKey:@"bitesMinus"];
			[playersTableView reloadData];
			mouseOverArray = [[self bigBiteShapeFromCell:mouseOverCell] retain];
		}
		else
		{
			[[playersArray objectAtIndex:currentPlayer] setObject:[NSNumber numberWithInt:1] 
														   forKey:@"bitesMinus"];
			[playersTableView reloadData];
			mouseOverArray = [[NSMutableArray alloc] initWithObjects:mouseOverCell, nil];
		}
		
		{ // Mask out the cells which are white or current player color
			NSMutableArray *bitesToRemove = [NSMutableArray new];
			int i;
			for (i = 0; i < [mouseOverArray count]; i++)
			{
				GameGridCell *biteCell = [mouseOverArray objectAtIndex:i];
				if ([biteCell color] == [NSColor whiteColor] || [biteCell color] == playerColor)
					[bitesToRemove addObject:biteCell];
			}
			
			[mouseOverArray removeObjectsInArray:bitesToRemove];
			[self changeShapeHighlight:mouseOverArray to:YES];
			[bitesToRemove release];
		}
	} 
	else // It's a shape being moved
	{
		mouseOverArray = [[shapeGenerator lastShapeFromCell:cell withController:self] mutableCopy];
		
		NSMutableArray *bitesToRemove = [NSMutableArray new];
		int i;
		for (i = 0; i < [mouseOverArray count]; i++)
		{
			GameGridCell *biteCell = [mouseOverArray objectAtIndex:i];
			if ([biteCell color] != [NSColor whiteColor])
				[bitesToRemove addObject:biteCell];
		}
		[mouseOverArray removeObjectsInArray:bitesToRemove];
		[self changeShapeHighlight:mouseOverArray to:YES];
		[bitesToRemove release];
	}
}

- (void)modifierKeysChanged:(NSEvent *)theEvent
{
	BOOL shiftKeyWasDown = ((modifierKeysFlag & NSShiftKeyMask) != 0);
	modifierKeysFlag = [theEvent modifierFlags];
	BOOL shiftKeyIsDown = ((modifierKeysFlag & NSShiftKeyMask) != 0);
	
	if ([mainWindow acceptsMouseMovedEvents] && 
		shiftKeyIsDown != shiftKeyWasDown && 
		[biteButton state] == NSOnState)
	{
		[self changeShapeHighlight:mouseOverArray to:NO];
		[mouseOverArray release];
		mouseOverArray = nil;
		
		mouseOverCell = nil;
		
		[[self window] sendEvent:[NSEvent mouseEventWithType:NSMouseMoved 
											location:[mainWindow mouseLocationOutsideOfEventStream]
									   modifierFlags:modifierKeysFlag
										   timestamp:0
										windowNumber:[[self window] windowNumber]
											 context:[NSGraphicsContext currentContext]																	 eventNumber:nil
										  clickCount:1
											pressure:0.0f]];
	}
}

- (void)keyDown:(NSEvent *)event
{
	// Method description:
	// Space bar tells GridShapeGenerator to rotate the shape	
	NSLog(@"key down");
	if ([[event characters] characterAtIndex:0] == '	' && [chatDrawerButton isEnabled])
	{
		if ([chatDrawerButton state] == NSOffState)
			[chatDrawerButton performClick:self];
		[[self window] makeFirstResponder:[self nextKeyView]];
		return;
	}
	
	if ([[event characters] characterAtIndex:0] == ' ' && [self canInput])
	{
		[controller performSelector:@selector(currentPlayerRotatedShape:) withObject:controller];
		return;
	}

bailout:
	NSBeep();
}

@end

@implementation GameGrid(TableViewDataSource)

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	return [playersArray objectAtIndex:rowIndex];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [playersArray count];
}

@end
