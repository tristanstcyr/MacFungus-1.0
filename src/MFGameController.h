
#import <Cocoa/Cocoa.h>
#import <GridShapeGenerator.h>
#import <GameGrid.h>
#import <NSColor_Compare.h>

#define MFDragDropTableViewDataType @"MFDragDropTableViewDataType"
#define MF_ANIMSPEED1 0.4f
#define MF_ANIMSPEED2 0.2f
#define MF_ANIMSPEED3 0.1f

@interface MFGameController : NSObject 
{
	id appController;
	
	NSColor *defaultColor;
	NSString *defaultName;
	
	GameGrid *gameGrid;
	NSWindow *mainWindow;
	
	GridShapeGenerator *shapeGenerator;
	
	// Lobby
	//////////////////////////
	IBOutlet NSView *topSectionView;
	IBOutlet NSWindow *lobbySheet;
	IBOutlet NSTableView *playersTableView;
	
	IBOutlet NSButton *goDisclosureTriangle;
	IBOutlet NSBox *goBox;
	IBOutlet NSPopUpButton *gridSizePopUp;
	IBOutlet NSPopUpButton *gameSpeedPopUp;
	IBOutlet NSButton *hotCornersSwitch;
	
	NSMutableArray *players;
	
	int colorRow;
	NSColor *newColor;
	int nextShape;
	
	NSSound *previousSound;
}

- (IBAction)goDisclosureTriangleToggled:(id)sender;
- (BOOL)isConnectedToGame;
- (void)playSound:(NSString *)soundName;
- (void)startGame;
- (void)cleanUpGame;
@end

@interface MFGameController (GridControl)
- (void)currentPlayerPlacedShapeAtRow:(int)row column:(int)col sender:(id)sender;
- (void)currentPlayerPressedBiteButton:(id)sender;
- (void)currentPlayerRotatedShape:(id)sender;
- (void)currentPlayerPlacedBiteAtRow:(int)row column:(int)col sender:(id)sender;
- (void)currentPlayerPlacedBigBiteAtRow:(int)row column:(int)col sender:(id)sender;
- (void)currentPlayerSkippedTurn:(id)sender;
- (int)nextShape;
@end

@interface MFGameController (ColorChange)
- (void)colorClick:(id)sender;
- (BOOL)colorChanged:(id)sender;
@end
