#import "MFNormalGameController.h"
#import "ColorCell.h"
#import "NSColor_Compare.h"
#import "MFLobbyNameCell.h"

#define MFDragDropTableViewDataType @"MFDragDropTableViewDataType"

@implementation MFNormalGameController

- (id)initWithAppController:(id)anAppController;
{
	if (!(self = [super init]))
		return nil;

	appController = anAppController;
	gameGrid = [appController valueForKey:@"gameGrid"];
	mainWindow = [gameGrid window];
			
	normalGameNib = [[NSNib alloc] initWithNibNamed:@"NormalGameSheet" bundle:nil];
	[normalGameNib instantiateNibWithOwner:self topLevelObjects:nil];
	
	MFLobbyNameCell *cell = [MFLobbyNameCell new];
	[cell setEditable:YES];
	[[[playersTableView tableColumns] objectAtIndex:0] setDataCell:cell];
	
	ColorCell *colorCell = [ColorCell new];
	[colorCell setEditable: YES];
	[colorCell setTarget: self];
	[colorCell setAction: @selector (colorClick:)];
	[[[playersTableView tableColumns] objectAtIndex:1] setDataCell:colorCell];
	
	[playersTableView setDoubleAction:@selector(cellDoubleClicked:)];
	[playersTableView registerForDraggedTypes: 
                        [NSArray arrayWithObject:MFDragDropTableViewDataType]];
	
	return self;
}

- (void)openNewGameSheet
{
	[gameGrid setAllowInput:NO];
	[gameGrid clear];
	
	if (!players) {
		players = [[NSMutableArray alloc] init];
		NSMutableDictionary *aPlayer;
		aPlayer = [[NSMutableDictionary alloc] init];
		
		NSString *aName = [[appController valueForKey:@"defaultNameField"] stringValue];
		NSColor *aColor = [[appController valueForKey:@"defaultColorWell"] color];
		
		[aPlayer setObject:aColor forKey:@"color"];
		[aPlayer setObject:aName forKey:@"name"];
		[aPlayer setObject:[NSNumber numberWithBool:YES] forKey:@"defaultPlayer"];
		[players addObject:aPlayer];
			
		[self addPlayer:self];
	
	} else {
		
		int i;
		NSMutableDictionary *defaultPlayer;
		for (i = 0; i < [players count]; i++)
		{
			defaultPlayer = [players objectAtIndex:i];
			if ([defaultPlayer objectForKey:@"defaultPlayer"])
				break;
		}
		NSString *aName = [[appController valueForKey:@"defaultNameField"] stringValue];
		NSColor *aColor = [[appController valueForKey:@"defaultColorWell"] color];
		[defaultPlayer setObject:aColor forKey:@"color"];
		[defaultPlayer setObject:aName forKey:@"name"];
	}
	
	[NSApp beginSheet:lobbySheet
	   modalForWindow:mainWindow
		modalDelegate:self
	   didEndSelector:NULL
		  contextInfo:NULL];
	[NSApp endSheet:lobbySheet];
	
	[mainWindow makeFirstResponder:gameGrid];
}

- (IBAction)cancelNormalGame:(id)sender
{
	[[NSColorPanel sharedColorPanel] close];
	[lobbySheet orderOut:sender];
	[NSApp endSheet:lobbySheet returnCode:1];	
}

- (IBAction)startNewNormalGame:(id)sender
{
	[super startGame];
}

- (IBAction)addPlayer:(id)sender
{
	if ([players count] == 4)
		return;
	
	int i, highestPlayerNumber, colorIndex, selectedRow = [playersTableView selectedRow];
	if (selectedRow < 0)
		selectedRow = [players count] - 1;
	
	NSMutableDictionary *newPlayer = [[NSMutableDictionary alloc] init];
	NSArray *colorArray = [[NSArray alloc] initWithObjects:[NSColor redColor],
														   [NSColor blueColor],
														   [NSColor greenColor],
														   [NSColor orangeColor],
														   nil];
	
	// Check for a similar name
	for (i = 0, highestPlayerNumber = 1; i < [players count]; i++) 
	{
		NSString *name = [[players objectAtIndex:i] objectForKey:@"name"];
		const unichar aUnichar = [name characterAtIndex:[name length]-1];
		NSString *numberString = 
			[[NSString alloc] initWithCharacters:&aUnichar length:1];
		if ([numberString intValue] > highestPlayerNumber)
			highestPlayerNumber = [numberString intValue];

		[numberString release];
	}
	
	// Check for similar color
	for (i = 0, colorIndex = 0; i < [players count]; i++) 
	{
		NSColor *aColor = [colorArray objectAtIndex:colorIndex];
		NSColor *aPlayersColor = [[players objectAtIndex:i] objectForKey:@"color"];
		if ([NSColor color:aColor isEqualToColor:aPlayersColor withinRange:0.1f]) {
				i = -1;
				colorIndex++;
		}
	}
	
	NSColor *aColor = [colorArray objectAtIndex:colorIndex];
	NSString *name = [NSString stringWithFormat:@"Player %i", highestPlayerNumber+1];
	[newPlayer setObject:name forKey:@"name"];
	[newPlayer setObject:aColor forKey:@"color"];
	
	[players insertObject:newPlayer atIndex:selectedRow+1];
	
	[playersTableView reloadData];
	
	[playersTableView selectRow:selectedRow+1 byExtendingSelection:NO];
}

- (IBAction)removePlayer:(id)sender
{
	int selectedRow = [playersTableView selectedRow];
	
	if ([players count] == 2 || 
	[[players objectAtIndex:selectedRow] objectForKey:@"defaultPlayer"] != nil)
	{
		NSBeep();
		return;
	}
	
	[players removeObjectAtIndex:selectedRow];
	
	[playersTableView reloadData];
	
	if (selectedRow > [players count] -1)
		selectedRow -= 1;
		
	[playersTableView selectRow:selectedRow byExtendingSelection:NO];
}

@end

@implementation MFNormalGameController (GameGridDelegation)

- (NSColor *)color
{
	return [gameGrid currentPlayerColor];
}

@end

@implementation MFNormalGameController (PlayersTableViewDelegation)
///////////////////////////////
// To allow Editing
//////////////////////////////`

#define MAXNAMELENGTH 10

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject 
	forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if ([[aTableColumn dataCell] class] == [ColorCell class])
		return;
	
	NSString *newName = anObject;
	
	if ([newName length] > MAXNAMELENGTH)
		newName = [newName substringWithRange:NSMakeRange(0, MAXNAMELENGTH)];
    [[players objectAtIndex:rowIndex] setObject:anObject 
											  forKey:[aTableColumn identifier]];
}

- (BOOL)tableView:(NSTableView *)view
    shouldEditTableColumn:(NSTableColumn *)col
					  row:(int)row
{
   return YES;
}

@end
