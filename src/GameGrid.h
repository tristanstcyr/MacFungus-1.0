#import <Cocoa/Cocoa.h>

#import "GameGridCell.h"
#import "GridShapeGenerator.h"
#import "RandomShapeView.h"
#import "PlayersTableView.h"

@interface GameGrid : NSMatrix
{
	BOOL isResizingGrid, 
		 canInput, 
		 isBusy,
		 stopThread;
		 
	int currentPlayer,
		trackingRectTag,
		modifierKeysFlag,
		currentShapeSquares;
		
	float animationSpeed;
	
	NSBezierPath *gridPath;
	RandomShapeView *randomShapeView;
	NSView *gridView;
	
	GameGridCell *mouseOverCell;
	NSMutableArray *mouseOverArray;
	
	NSMutableArray *playersArray, *deadPlayers;
	GridShapeGenerator *shapeGenerator;
	
	id controller;
	IBOutlet NSWindow *mainWindow;
	IBOutlet NSView *randomShapeViewBox;
	IBOutlet NSButton *biteButton, 
					  *skipTurnButton, 
					  *chatDrawerButton;
	IBOutlet PlayersTableView *playersTableView;
	IBOutlet NSTextField *statusTextField;
}
- (void)awakeFromNib;
- (void)dealloc;

@end

@interface GameGrid(GameEvents)

- (void)startNewGameWithPlayers:(NSArray *)players 
					 controller:(id)aController 
					   gridSize:(int)gridSize
					 hotCorners:(BOOL)hotCorners
				 animationSpeed:(float)anAnimationSpeed;
- (void)performBiteOnCell:(GameGridCell *)cell;
- (void)performBigBiteOnCell:(GameGridCell *)cell;
- (void)switchToNextPlayer;
- (void)endGame;
- (void)playShapeForCell:(GameGridCell *)aCell;
- (void)threadWaitForShape;
- (void)rotateShape;
- (void)switchBiteButton;
- (IBAction)skipTurn:(NSEvent *)sender;
- (IBAction)biteButtonPushed:(NSEvent *)sender;
- (void)newBitesForPlayer:(NSDictionary *)aPlayer;

@end

@interface GameGrid(GridLogic)

- (NSArray *)startPatternWithPlayerQuantity:(int)players;
- (NSArray *)checkForSimilarColorWithMovementOnRow:(int)encrementOnRow 
										  onColumn:(int)encrementOnColumn 
										  fromCell:(GameGridCell *)cell;
- (NSArray *)checkForBrokenChainsForPlayer:(int)playerIndex;
- (NSArray *)checkDiagonalsWithCell:(GameGridCell *)Cell;
- (NSArray *)neighborsOfSameColorForCell:(GameGridCell *)cell withColor:(NSColor *)aColor;

@end

@interface GameGrid(PlayersManipulation)

- (void)removePlayerWithColor:(NSColor *)aColor;
- (int)findPlayerForColor:(NSColor *)aColor;
- (NSColor *)currentPlayerColor;

@end

@interface GameGrid(Drawing)

- (void)drawRect:(NSRect)aRect;
- (void)drawShape:(NSArray *)cellArray 
		withColor:(NSColor *)aColor 
		  animate:(BOOL)animate;
- (NSArray *)bigBiteShapeFromCell:(GameGridCell *)cell;
- (void)changeShapeHighlight:(NSArray *)cellArray to:(BOOL)isHighlighted;
- (void)clear;
- (BOOL)isBusy;

- (void)createGridPath;
- (void)resizeGridAndWindowToGridSize:(int)gridSize withPlayers:(int)players;
- (NSSize)cellSizeConsideringBounds;
- (BOOL)isResizingGrid;

@end

@interface GameGrid(Input)

- (void)mouseDown:(NSEvent *)theEvent;
- (void)mouseMoved:(NSEvent *)theEvent;
- (void)mouseUp:(NSEvent *)theEvent;
- (void)modifierKeysChanged:(NSEvent *)theEvent;
- (void)evaluateInput;
- (void)setAllowInput:(BOOL)allowInput;
- (BOOL)canInput;

@end

@interface GameGrid(TableViewDataSource)

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;

@end