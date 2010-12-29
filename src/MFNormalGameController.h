/* NewGameSheetController */
#import <Cocoa/Cocoa.h>
#import <GameGrid.h>
#import <MFLobbyTableView.h>
#import <MFGameController.h>

@interface MFNormalGameController : MFGameController
{
	NSNib *normalGameNib;
}

- (id)initWithAppController:(id)anAppController;
- (IBAction)cancelNormalGame:(id)sender;
- (IBAction)startNewNormalGame:(id)sender;

- (void)openNewGameSheet;

- (IBAction)addPlayer:(id)sender;
- (IBAction)removePlayer:(id)sender;
@end

@interface MFNormalGameController (GameGridDelegation)
- (NSColor *)color;
@end
