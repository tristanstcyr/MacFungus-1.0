#import "PlayersTableView.h"
#import "PlayerCell.h"

@implementation PlayersTableView

- (void)mouseDown:(NSEvent *)theEvent
{
	NSBeep();
}

- (void)keyDown:(NSEvent *)theEvent
{
	NSBeep();
}

- (id)_highlightColorForCell:(PlayerCell *)cell
{
	return nil;
}

- (BOOL)acceptsFirstResponder { 
	return NO;
}
	
- (void)rightMouseDown:(NSEvent *)theEvent
{
	if ([self numberOfRows] == 0)
		return;
	
	NSPoint pointInView = [self convertPoint:[theEvent locationInWindow] 
								    fromView:nil];
	int row = [self rowAtPoint:pointInView];
	if (row == -1)
		return;
	
	NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys: theEvent, @"event", 
																		[NSNumber numberWithInt:row], @"row", nil];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"MFPlayersTableViewRightClicked"
													    object:self 
													  userInfo:dict];
	[dict autorelease];

}

@end
