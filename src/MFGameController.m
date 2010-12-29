//
//  MFGameController.m
//  MacFungus
//
//  Created by tristan on 17/08/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "MFGameController.h"

@implementation MFGameController

- (BOOL)isConnectedToGame
{
	if (players) return YES; else return NO;
}

- (void)playSound:(NSString *)soundName
{
	if ([[appController valueForKey:@"soundsPrefsButton"] state] == NSOnState && soundName != nil)
	{
		if (previousSound)
			[previousSound stop];
			
		previousSound = [NSSound soundNamed:soundName];
		[previousSound play];
	}
}

- (IBAction)goDisclosureTriangleToggled:(id)sender
{
	float change;
	NSRect lobbyFrame = [lobbySheet frame];
	
	if ([sender state] == NSOnState)
	{
		change = [goBox frame].origin.y - 20.0f;
	}
	else
	{
		change = [topSectionView frame].origin.y;
	}

	lobbyFrame.size.height -= change;
	lobbyFrame.origin.y += change;
	NSSize minSize = [lobbySheet minSize];
	minSize.height -=  change;
	[lobbySheet setMinSize:minSize];

	int topSectionMask = [topSectionView autoresizingMask];
	int goBoxMask = [goBox autoresizingMask];
	
	int newMask = (NSViewNotSizable | NSViewMinYMargin);
	[topSectionView setAutoresizingMask: newMask];
	[goBox setAutoresizingMask: newMask];
	
	[lobbySheet setFrame:lobbyFrame 
					   display:YES 
					   animate:YES];
	
	[topSectionView setAutoresizingMask: topSectionMask];
	[goBox setAutoresizingMask: goBoxMask];
}

- (void)startGame
{
	if (!shapeGenerator)
		shapeGenerator = [GridShapeGenerator alloc];
	float animationSpeed;
	[[NSColorPanel sharedColorPanel] close];
	
	[lobbySheet orderOut:self];
	[NSApp endSheet:lobbySheet];
	
	// Set the animation speed
	
	switch ([gameSpeedPopUp indexOfSelectedItem])
	{
		case 0:
			animationSpeed = MF_ANIMSPEED1;
			break;
		case 1:
			animationSpeed = MF_ANIMSPEED2;
			break;
		case 2:
			animationSpeed = MF_ANIMSPEED3;
			break;
	}
	
	// Start the GameGrid
	[gameGrid clear];
	[gameGrid startNewGameWithPlayers:players
						   controller:self 
					         gridSize:[[gridSizePopUp selectedItem] tag]
						   hotCorners:([hotCornersSwitch state] == NSOnState ? YES : NO)
					   animationSpeed:animationSpeed];
}

- (void)cleanUpGame
{
	[gameGrid clear];
	[gameGrid setAllowInput:NO];
	
	[players release];
	players = nil;

	if ([lobbySheet isVisible]) 
	{
		[lobbySheet orderOut:self];
		[NSApp endSheet:lobbySheet];
	}

	[[gameGrid valueForKey:@"statusTextField"] setStringValue:@"Go in the File menu to start a new game"];
	[mainWindow setTitle:@"MacFungus B4"];
}

@end

@implementation MFGameController (GridControl)

- (void)currentPlayerPlacedShapeAtRow:(int)row column:(int)col sender:(id)sender
{		
		GameGridCell *aCell = [gameGrid cellAtRow:row column:col];
		[NSThread detachNewThreadSelector:@selector(playShapeForCell:) 
								 toTarget:gameGrid 
							   withObject:aCell];
}

- (void)currentPlayerPressedBiteButton:(id)sender
{
	if (sender!= self)
		[gameGrid switchBiteButton];
}

- (void)currentPlayerRotatedShape:(id)sender
{
	[gameGrid rotateShape];
}

- (void)currentPlayerPlacedBiteAtRow:(int)row column:(int)col sender:(id)sender
{
	GameGridCell *aCell = [gameGrid cellAtRow:row column:col];
	[NSThread detachNewThreadSelector:@selector(performBiteOnCell:) 
							 toTarget:gameGrid 
						   withObject:aCell];
}

- (void)currentPlayerPlacedBigBiteAtRow:(int)row column:(int)col sender:(id)sender
{
	GameGridCell *aCell = [gameGrid cellAtRow:row column:col];
	[NSThread detachNewThreadSelector:@selector(performBigBiteOnCell:) 
							 toTarget:gameGrid 
						   withObject:aCell];
}

- (void)currentPlayerSkippedTurn:(id)sender
{
	[gameGrid switchToNextPlayer];
}

- (int)nextShape
{
	return [shapeGenerator generateRandomShape];
}

@end

@implementation MFGameController (ColorChange)

- (void)colorClick:(id)sender
{
	NSColorPanel* panel = [NSColorPanel sharedColorPanel];
	colorRow = [sender clickedRow];
	[panel setTarget: self];
	[panel setShowsAlpha: NO];
	[panel setColor:[[players objectAtIndex:[playersTableView selectedRow]] objectForKey:@"color"]];
	[panel makeKeyAndOrderFront:self];
	[panel setAction: @selector(colorChanged:)];
		// show the panel
}

- (BOOL)colorChanged:(id)sender
{
	int i;
	NSColor *pickedColor = 
		[[sender color] colorUsingColorSpaceName:NSDeviceRGBColorSpace];
	NSColor *whiteColor = 
		[NSColor colorWithDeviceRed:1 green:1 blue:1 alpha:1];
	
	for (i = 0; i < [players count]; i++) 
	{
		NSColor *aColor = [[players objectAtIndex:i] objectForKey:@"color"];
		if (i != colorRow && 
		[NSColor color:aColor 
		isEqualToColor:pickedColor 
		   withinRange:0.2f])
			return NO;
	
		if (i != colorRow && 
		[NSColor color:pickedColor 
		isEqualToColor:whiteColor 
		   withinRange:0.05f])
			return NO;
	}
	
	[[players objectAtIndex:[playersTableView selectedRow]] setObject:pickedColor forKey:@"color"];
	[playersTableView reloadData];
	return YES;
}

- (NSColor *)color
{
	return defaultColor;
}

@end
@implementation MFGameController (TableViewDataSource)


- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	if ([playersTableView selectedRow] < 0)
	{
		[[NSColorPanel sharedColorPanel] close];
		return;
	}
	
	int selectedRow = [playersTableView selectedRow];
	NSColor *selectedColor = [[players objectAtIndex:selectedRow] objectForKey:@"color"];
	[[NSColorPanel sharedColorPanel] setColor:selectedColor];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{	
	return [players count];
}

- (id)tableView:(NSTableView *)aTableView 
	    objectValueForTableColumn:(NSTableColumn *)aTableColumn 
	    row:(int)rowIndex
{
	NSDictionary *playerDict = [players objectAtIndex:rowIndex];
	return [playerDict objectForKey:[aTableColumn identifier]];
}

///////////////////////////////
// To allow dragging
//////////////////////////////

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes 
										    toPasteboard:(NSPasteboard*)pboard 
{
	// Copy the row numbers to the pasteboard.
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    
	[pboard declareTypes:[NSArray arrayWithObject:MFDragDropTableViewDataType] owner:self];
	
    [pboard setData:data forType:MFDragDropTableViewDataType];

    return YES;
}

- (NSDragOperation)tableView:(NSTableView*)tv 
			    validateDrop:(id <NSDraggingInfo>)info 
				 proposedRow:(int)row 
	   proposedDropOperation:(NSTableViewDropOperation)op
{	
	if (op == NSTableViewDropOn)
		[tv setDropRow:(row+1) dropOperation:NSTableViewDropAbove];
    
	return NSDragOperationGeneric;    
}

- (BOOL)tableView:(NSTableView *)aTableView 
	   acceptDrop:(id <NSDraggingInfo>)info
              row:(int)dropRowIndex 
	dropOperation:(NSTableViewDropOperation)operation

{	
	NSPasteboard* pboard = [info draggingPasteboard];

    NSData* rowData = [pboard dataForType:MFDragDropTableViewDataType];

	int dragRowIndex = [[NSKeyedUnarchiver unarchiveObjectWithData:rowData] firstIndex];

	NSDictionary *draggedRow = [[players objectAtIndex:dragRowIndex] retain];
	
	if (dragRowIndex < dropRowIndex)
		dropRowIndex -= 1;
	
	[players removeObjectAtIndex:dragRowIndex];
	[players insertObject:draggedRow atIndex:dropRowIndex];
	
	[playersTableView reloadData];
	[draggedRow release];
	return YES;
}



@end

