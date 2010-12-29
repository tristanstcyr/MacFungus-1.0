/* MFMainWindow */

#import <Cocoa/Cocoa.h>
#import "GameGrid.h"
#import <MFResizingTextField.h>

@interface MFMainWindow : NSWindow
{
	IBOutlet GameGrid *gameGrid;
	IBOutlet id tableView;
	IBOutlet MFResizingTextField *chatDrawerTextField;
}

@end
