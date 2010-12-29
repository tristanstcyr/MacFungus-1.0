#import <Cocoa/Cocoa.h>`
#import <sys/socket.h>
#import <netinet/in.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "errno.h"
#import "string.h"

#import "GridShapeGenerator.h"
#import "ColorCell.h"
#import "NSColor_Compare.h"
#import "MFLobbyNameCell.h"
#import "MFHostGameController.h"


#define MFDragDropTableViewDataType @"MFDragDropTableViewDataType"

@implementation MFHostGameController

- (id)initWithObjectDict:(NSDictionary *)objectDict
{
	if(self = [super initWithObjectDict:objectDict]) 
	{

		hostGameSheetNib = [[NSNib alloc] initWithNibNamed:@"HostGameSheet" bundle:nil];
		[hostGameSheetNib instantiateNibWithOwner:self topLevelObjects:nil];
		
		[chatTextView setTextContainerInset:NSMakeSize(3,3)];
		
		MFLobbyNameCell *nameCell = [[MFLobbyNameCell alloc] init];
		[nameCell setEditable: NO];
		NSTableColumn *tableColumn = [[playersTableView tableColumns] objectAtIndex:0];
		[tableColumn setDataCell:nameCell];
		[tableColumn setWidth:87];
		
		ColorCell *colorCell = [ColorCell new];
		[colorCell setEditable: YES];
		[colorCell setTarget: self];
		[colorCell setAction: @selector (colorClick:)];
		tableColumn = [[playersTableView tableColumns] objectAtIndex:1];
		[tableColumn  setDataCell:colorCell];
		[tableColumn setWidth:[playersTableView rowHeight]];
		[playersTableView registerForDraggedTypes: 
			[NSArray arrayWithObject:MFDragDropTableViewDataType]];
	}
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[hostGameSheetNib release];

	[super dealloc];
}

- (void)addPlayer:(id)newPlayer
{	
	NSMutableDictionary *aPlayerDict = [newPlayer valueForKey:@"playerDict"];
	NSString *aName = [aPlayerDict objectForKey:@"name"];
	NSColor *aColor = [aPlayerDict objectForKey:@"color"];
	[aPlayerDict setObject:newPlayer forKey:@"device"];
	
	{ // Changing the color if necessary
		int i, colorIndex = 0;
		BOOL changedColor = NO;
		
		NSArray *colorsArray = [NSArray arrayWithObjects:[NSColor redColor], 
														 [NSColor blueColor], 
														 [NSColor greenColor],
														 [NSColor orangeColor], nil];
		for (i = 0; i < [players count]; i++)
		{
			NSDictionary *player = [players objectAtIndex:i];
			
			if ([NSColor color:aColor isEqualToColor:[player objectForKey:@"color"] withinRange:0.2f]) {
				aColor = [colorsArray objectAtIndex:colorIndex++];
				i = -1;
				changedColor = YES;
			}
		}
		
		if (changedColor) 
		{
			[aPlayerDict setObject:aColor forKey:@"color"];
			CFSwappedFloat32 colors[3];
			colors [0] = CFConvertFloatHostToSwapped([aColor redComponent]);
			colors [1] = CFConvertFloatHostToSwapped([aColor greenComponent]);
			colors [2] = CFConvertFloatHostToSwapped([aColor blueComponent]);
			
			NSMutableData *data = [[NSMutableData alloc] init];
			[data appendBytes:&MF_N_NEWCOLOR length:sizeof(MF_N_NEWCOLOR)];
			[data appendBytes:colors length:sizeof(colors)];
			[newPlayer sendData:data];
			[data release];
		}
	} // End: Changing the color if necessary
	
	{ // Give the player a unique ID number
	
		int i, IDNumber = 2;
		
		for (i = 0; i < [players count]; i++)
		{
			int anotherID = [[[players objectAtIndex:i] objectForKey:@"id"] intValue];
			if (anotherID == IDNumber)
			{
				++IDNumber;
				i = -1;
			}
		}
		
		[aPlayerDict setObject:[NSNumber numberWithChar:(char)IDNumber] forKey:@"id"];
	}
	
	
	{ // Send the new player the current selected grid size
		unsigned char index = (unsigned char)[gridSizePopUp indexOfSelectedItem];
		NSMutableData *data = [[NSMutableData alloc] initWithBytes:&MF_N_GRIDSIZE length:sizeof(MF_N_GRIDSIZE)];
		[data appendBytes:&index length:sizeof(index)];
		[newPlayer sendData:data];
		[data release];
	}
	
	{ // Send the new player hot corners switch state
		unsigned char switchState = ([hotCornersSwitch state] == NSOnState ? YES : NO);
		NSMutableData *data = [[NSMutableData alloc] initWithBytes:&MF_N_HOTCORNERSSWITCH 
														length:sizeof(MF_N_HOTCORNERSSWITCH)];
		[data appendBytes:&switchState length:sizeof(switchState)];
		[newPlayer sendData:data];
		[data release];
	}
	
	{ // Send the new player the current selected grid size
		unsigned char index = (unsigned char)[gameSpeedPopUp indexOfSelectedItem];
		NSMutableData *data = [[NSMutableData alloc] initWithBytes:&MF_N_GAMESPEED length:sizeof(MF_N_GAMESPEED)];
		[data appendBytes:&index length:sizeof(index)];
		[newPlayer sendData:data];
		[data release];
	}
	
	[players addObject:aPlayerDict];
	[playersTableView reloadData];
	
	{ //send everyplayer the new list
		NSMutableData *data = [[NSMutableData alloc] initWithBytes:&MF_N_PLAYLIST length:sizeof(MF_N_PLAYLIST)];
		[data appendData:[self playersData]];
		[self sendDataToPlayers:data withException:NULL];
		[data release];
	}

	[self updateService];
	[startGameButton setEnabled:YES];
	[self systemPost:[NSString stringWithFormat:@"%@ entered the game", aName]];
	
	[self playSound:@"wong"];
}

- (NSData *)playersData
{
	int i;
	NSMutableData *data = [[NSMutableData alloc] init];

	for (i = 0; i < [players count]; i++) 
	{
		NSDictionary *aDictionary = [players objectAtIndex:i];
		
		const char *name = [[aDictionary objectForKey:@"name"] UTF8String];
		unsigned char sizeOfName = (unsigned char)strlen(name);
		char anID = [[aDictionary objectForKey:@"id"] charValue];
		
		NSColor *aColor = [aDictionary objectForKey:@"color"];
		CFSwappedFloat32 color[3];
		color[0] = CFConvertFloatHostToSwapped([aColor redComponent]);
		color[1] = CFConvertFloatHostToSwapped([aColor greenComponent]);
		color[2] = CFConvertFloatHostToSwapped([aColor blueComponent]);
		
		[data appendBytes:&sizeOfName length:sizeof(sizeOfName)];
		[data appendBytes:name length:sizeOfName];
		[data appendBytes:color length:sizeof(color)];
		[data appendBytes:&anID length:sizeof(anID)];
	}
	
	return [data autorelease];
}

-(void)removePlayer:(id)aPlayer wasKicked:(BOOL)wasKicked
{
	NSDictionary *aPlayerDict = [aPlayer valueForKey:@"playerDict"];
	NSString *playerName = [aPlayerDict objectForKey:@"name"];
	NSColor *playerColor = [aPlayerDict objectForKey:@"color"];
	char playerID = [[aPlayerDict objectForKey:@"id"] charValue];
	
	[muteList removeObject:aPlayerDict];
	[players removeObject:aPlayerDict];
	
	{ // Log it
		NSString *logString;
		
		if (wasKicked)
			logString = [NSString stringWithFormat:@"%@ was kicked", playerName];
		else
			logString = [NSString stringWithFormat:@"%@ left the game", playerName];
		
		[self systemPost:logString];
	}
	
	if ([players count] < 2)
		[startGameButton setEnabled:NO];
	
	{ // Send the removed player
		const char charWasKicked = (const char)wasKicked;
		NSMutableData *data = [[NSMutableData alloc] initWithBytes:&MF_N_REMOVEPLAYER length:sizeof(MF_N_REMOVEPLAYER)];
		[data appendBytes:&playerID length:sizeof(playerID)];
		[data appendBytes:&charWasKicked length:sizeof(wasKicked)];
		[self sendDataToPlayers:data withException:nil];
		[data release];
	}
	
	if ([lobbySheet isVisible])
	{	
		[self updateService];
		[playersTableView reloadData];
		return;
	}

	if (!wasKicked) 
	{
		NSString *alertMessage = [NSString stringWithFormat:@"%@ has disconnected. He either lost connection or left the game.", playerName];
		NSAlert *alertSheet = [NSAlert alertWithMessageText:@"A player disconnected"
											  defaultButton:@"OK"
											alternateButton:@"Go Back to Lobby"
												otherButton:@"Close Game"
								  informativeTextWithFormat:alertMessage];
		[alertSheet beginSheetModalForWindow:mainWindow
							   modalDelegate:self
							  didEndSelector:@selector(disconnectedPlayersSheetDidEnd:returnCode:contextInfo:)
								 contextInfo:nil];
	}
	
	[NSThread detachNewThreadSelector:@selector(removePlayerWithColor:) toTarget:gameGrid withObject:playerColor];
}

- (IBAction)kickPlayer:(id)sender
{
	int row;
	
	if ([sender class] == [NSButton class]) 
	{
		[kickPlayerButton setEnabled:NO];
		row = [playersTableView selectedRow];
	} 
	else if ([sender class] == [NSMenuItem class])
	{ 
		row = [sender tag];
	}
	
	id aPlayer = [[players objectAtIndex:row] objectForKey:@"device"];
	NSData *data = [NSData dataWithBytes:&MF_N_DISCONNECT 
								  length:sizeof(MF_N_DISCONNECT)];
	[aPlayer sendData:data];
	[self removePlayer:aPlayer wasKicked:YES];
}

@end

@implementation MFHostGameController (LobbySheet)

- (void)openLobbySheet;
{	
	playerDidChat = NO;
	if(players) [players release];
	if(muteList) [muteList release];
	players = [[NSMutableArray alloc] init];
	muteList = [[NSMutableArray alloc] init];
		
	{
		NSString *aName = [[appController valueForKey:@"defaultNameField"] stringValue];
		NSColor *aColor = [[appController valueForKey:@"defaultColorWell"] color];
		
		defaultName = aName;
		defaultColor = aColor;
	}
	
	playerDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:defaultName, @"name",
		defaultColor, @"color",
		self, @"device", 
		[NSNumber numberWithChar: 1 ], @"id", nil];
	
	[players addObject:[playerDict autorelease]];
	
	[playersTableView reloadData];
	
	[gameGrid setAllowInput:NO];
	[gameGrid clear];
	[chatDrawerTextField setTarget:self];
	[chatDrawerTextField setAction:@selector(returnChatMessage:)];
	[chatDrawerButton setState:NSOffState];
	[chatDrawerButton setEnabled:NO];
	[chatDrawer close];

	[NSApp beginSheet:lobbySheet
	   modalForWindow:mainWindow
		modalDelegate:self
	   didEndSelector:NULL
		  contextInfo:NULL];
	[NSApp endSheet:lobbySheet];
	
	{ // find the address and print it in the text view
		int i;
		NSArray *addresses = [[NSHost currentHost] addresses];
		NSMutableString *addressesString = [[NSMutableString alloc] init];
		
		for ( i = 0; i < [addresses count]; i++)
		{
			if([[[addresses objectAtIndex:i] componentsSeparatedByString:@"."] count] == 4 &&
			   ![[[[addresses objectAtIndex:i] componentsSeparatedByString:@"."] objectAtIndex:0] isEqualToString:@"127"])
				[addressesString appendFormat:@"%@\n", [addresses objectAtIndex:i]];
		}
			[addressesString appendFormat:@"Port: %i",PORT_NUMBER];
		
		[chatTextView setString:@""];
		[super systemPost:[NSString stringWithFormat:@"Game started at address(es):\n%@", addressesString]];
	}
	
	[startGameButton setEnabled:NO];  
	[[chatMessageField window] makeFirstResponder:chatMessageField];
	
	{ // setup the stuff for the tracker
		NSTextField *gameNameField = [appController valueForKey:@"gameNameField"];
		NSTextField *gameDescriptionField = [appController valueForKey:@"gameDescriptionField"];
		[gameNameField setTarget:self];
		[gameDescriptionField setTarget:self];
		[gameNameField setAction:@selector(updateTracker)];
		[gameDescriptionField setAction:@selector(updateTracker)];
		
		[mainWindow setTitle:[[appController valueForKey:@"gameNameField"] stringValue]];
	}
	
	[self setupService];
}


#define MAXMESSAGELENGTH 200
- (IBAction)returnChatMessage:(id)sender
{
	NSString *messageString = [sender stringValue];
	
	[sender setStringValue:@""];
	[[mainWindow fieldEditor:NO forObject:sender] setString:@""];
	if (sender == chatDrawerTextField)
		[sender sizeToFit];
	
	NSDate *now = [[NSDate alloc] init];
	[[sender window] makeFirstResponder:sender];
	
	if (lastMessageDate && [now timeIntervalSinceDate:lastMessageDate] < 0.5)
	{
		[now release];
		NSBeep();
		return;
		
	} else {
		[lastMessageDate release];
		lastMessageDate = now;
	}
	
	if ([messageString length] > MAXMESSAGELENGTH)
		messageString = [messageString substringWithRange:NSMakeRange(0,MAXMESSAGELENGTH)];
	
	[self broadcastChatMessage:messageString from:self];
}

- (void)broadcastChatMessage:(NSString *)messageString from:(id)player
{
	if (!messageString || ![messageString length])
		return;
	
	
	NSDictionary *aPlayerDict = [player valueForKey:@"playerDict"];
	char playerID = [[aPlayerDict objectForKey:@"id"] charValue];
	
	[super postMessage:messageString from:aPlayerDict];
	
	{ // Send the message to players
		NSMutableData *data = [[NSMutableData alloc] initWithBytes:&MF_N_CHATMESSAGE 
														    length:sizeof(MF_N_CHATMESSAGE )];
		const char *messageCString = [messageString UTF8String];
		
		[data appendBytes:&playerID length:sizeof(playerID)];
		[data appendBytes:messageCString length:strlen(messageCString)];
		
		[self sendDataToPlayers:data withException:player];
		[data release];
	}
}

- (IBAction)cancelHostGame:(id)sender
{
	NSData *data = [NSData dataWithBytes:&MF_N_DISCONNECT 
								  length:sizeof(MF_N_DISCONNECT)];
	[self sendDataToPlayers:data withException:nil];
	
	//Stop announcing ourselves on the network
	[self cleanUpGame];
	[self stopService];
	
	// Changing the name fields should not send actions anymore
	NSTextField *gameNameField = [appController valueForKey:@"gameNameField"];
	NSTextField *gameDescriptionField = [appController valueForKey:@"gameDescriptionField"];
	[gameNameField setTarget:nil];
	[gameDescriptionField setTarget:nil];
}

- (IBAction)startHostGame:(id)sender
{
	NSMutableData *data = [NSMutableData dataWithBytes:&MF_N_GAMESTARTS length:sizeof(MF_N_GAMESTARTS)];
	[self sendDataToPlayers:data withException:nil];
	[self stopService];
	[super startGame];
}

- (void)backToLobby
{
	
	
	// Rebroadcast on bonjour
	[self setupService];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:@"MFPlayersTableViewRightClicked"
												  object:playersTableView];
	
	// Dump the text in the chat drawer back into the lobby's text view
	[chatTextView setString:@""];
	[[chatTextView textStorage] appendAttributedString:[chatDrawerTextView textStorage]];
	int textLength = [[chatTextView textStorage] length];
	[chatTextView scrollRangeToVisible:NSMakeRange(textLength - 1, 1)];
	[playersTableView reloadData];
	[NSApp beginSheet:lobbySheet
	   modalForWindow:mainWindow
		modalDelegate:self
	   didEndSelector:NULL
		  contextInfo:NULL];
	[NSApp endSheet:lobbySheet];
	
	{ // Tell clients to go back to lobby
		NSMutableData *data = 
			[NSMutableData dataWithBytes:&MF_N_BACKTOLOBBY length:sizeof(MF_N_BACKTOLOBBY)];
		[data appendData:[self playersData]];
		[self sendDataToPlayers:data withException:nil];
	}
	
	if ([players count] < 2)
		[startGameButton setEnabled:NO];
	
	[chatDrawer close];
	[chatDrawerButton setState:NSOffState];
	[chatDrawerButton setEnabled:NO];
}

- (void)newPlayerConnected:(NSNotification *)notification
{
	NSFileHandle *fileHandle = [[notification userInfo] 
					objectForKey:NSFileHandleNotificationFileHandleItem];

	if ([players count] > 3) 
	{
		[fileHandle closeFile];
		return;
	}
	
	ClientPlayer *newPlayer;
	newPlayer = [[ClientPlayer alloc] initWithFileHandle:fileHandle hostServer:self];
	
	[listeningSocket acceptConnectionInBackgroundAndNotify];
}

- (IBAction)gridSizeChanged:(id)sender
{
	unsigned char index = (unsigned char)[sender indexOfSelectedItem];
	NSMutableData *data = [[NSMutableData alloc] initWithBytes:&MF_N_GRIDSIZE 
														length:sizeof(MF_N_GRIDSIZE)];
	[data appendBytes:&index length:sizeof(index)];
	[self sendDataToPlayers:data withException:NULL];
	[data release];
}

- (IBAction)hotCornerSwitch:(id)sender
{
	unsigned char switchState = ([hotCornersSwitch state] == NSOnState ? YES : NO);
	
	NSMutableData *data = [[NSMutableData alloc] initWithBytes:&MF_N_HOTCORNERSSWITCH 
														length:sizeof(MF_N_HOTCORNERSSWITCH)];
	[data appendBytes:&switchState length:sizeof(switchState)];
	[self sendDataToPlayers:data withException:NULL];
	[data release];
}

- (IBAction)gameSpeedChanged:(id)sender
{
	unsigned char index = (unsigned char)[sender indexOfSelectedItem];
	NSMutableData *data = [[NSMutableData alloc] initWithBytes:&MF_N_GAMESPEED 
														length:sizeof(MF_N_GAMESPEED)];
	[data appendBytes:&index length:sizeof(index)];
	[self sendDataToPlayers:data withException:NULL];
	[data release];
}

@end

@implementation MFHostGameController (InGame)

- (void)sendDataToPlayers:(NSData *)data withException:(id)exception 
{
	int i;

	//Send it to the living players but no the host or the exception
	for(i=0; i < [players count]; i++) 
	{
		id aPlayer = [[players objectAtIndex:i] objectForKey:@"device"];
		if (aPlayer != self && aPlayer !=exception)
			[aPlayer sendData:data];
	}
}

- (void)currentPlayerPlacedShapeAtRow:(int)row column:(int)col sender:(id)sender
{
	
	{ //Send coordinates of played cell to players except the one who played
		
		NSMutableData *data = [[NSMutableData alloc] initWithBytes:&MF_N_PLACEDSHAPE 
															length:sizeof(MF_N_PLACEDSHAPE)];
		unsigned char charRow = (unsigned char)row;
		unsigned char charCol = (unsigned char)col; // haha
		[data appendBytes:&charRow length:sizeof(charRow)];	
		[data appendBytes:&charCol length:sizeof(charCol)];	
		
		[self sendDataToPlayers:data withException:sender];
		[data release];
	}

	[super currentPlayerPlacedShapeAtRow:row column:col sender:sender];
}

- (void)currentPlayerPressedBiteButton:(id)sender
{
	NSData *data = [NSData dataWithBytes:&MF_N_BITEBUTTON 
								  length:sizeof(MF_N_BITEBUTTON)];
	[self sendDataToPlayers:data withException:sender ];
	
	if (sender != self)
		[super currentPlayerPressedBiteButton:sender];
}

- (void)currentPlayerRotatedShape:(id)sender
{
	NSData *data = [NSData dataWithBytes:&MF_N_ROTATED 
								  length:sizeof(&MF_N_ROTATED)];
	[self sendDataToPlayers:data withException:sender];
	
	[super currentPlayerRotatedShape:sender];
}

- (void)currentPlayerPlacedBiteAtRow:(int)row column:(int)col sender:(id)sender
{
	//Send coordinates of played cell to players except the one who played
	NSMutableData *data = [[NSMutableData alloc] initWithBytes:&MF_N_BITEPLACED 
														length:sizeof(MF_N_BITEPLACED)];
	unsigned char charRow = (unsigned char)row;
	unsigned char charCol = (unsigned char)col;
	[data appendBytes:&charRow length:sizeof(charRow)];	
	[data appendBytes:&charCol length:sizeof(charCol)];	
		
	[self sendDataToPlayers:data withException:sender];
	[data release];
	
	[super currentPlayerPlacedBiteAtRow:row column:col sender:sender];
}

- (void)currentPlayerPlacedBigBiteAtRow:(int)row column:(int)col sender:(id)sender
{
	//Send coordinates of played cell to players except the one who played
	NSMutableData *data = [[NSMutableData alloc] initWithBytes:&MF_N_BIGBITEPLACED 
														length:sizeof(MF_N_BIGBITEPLACED)];
	unsigned char charRow = (unsigned char)row;
	unsigned char charCol = (unsigned char)col;
	[data appendBytes:&charRow length:sizeof(charRow)];	
	[data appendBytes:&charCol length:sizeof(charCol)];	
		
	[self sendDataToPlayers:data withException:sender];
	
	[super currentPlayerPlacedBigBiteAtRow:row column:col sender:sender];
}

- (void)currentPlayerSkippedTurn:(id)sender
{
	{
		NSData *data = [NSData dataWithBytes:&MF_N_SKIPTURN 
									  length:sizeof(MF_N_SKIPTURN)];
		[self sendDataToPlayers:data withException:sender];
	}
	
	[super currentPlayerSkippedTurn:sender];
}

- (int)nextShape
{
	nextShape = [shapeGenerator generateRandomShape];

	NSMutableData *data = 
		[NSMutableData dataWithBytes:&MF_N_NEWSHAPE length:sizeof(MF_N_NEWSHAPE)];
	char nextShapeByte = (char)nextShape;
	[data appendBytes:&nextShapeByte length:sizeof(nextShapeByte)];
	[self sendDataToPlayers:data withException:nil];

	return nextShape;
}

- (void)noMorePlayersSheetDidEnd:(NSAlert *)alert 
					  returnCode:(int)returnCode 
					 contextInfo:(void *)contextInfo
{
	[[alert window] orderOut:self];
	[NSApp endSheet:[alert window]];
	
	[muteList release];
	muteList = nil;
	
	[gameGrid setAllowInput:NO];
	[[alert window] orderOut:self];
	
	if (returnCode == 1)
		[self openLobbySheet];
	else
		[self cancelHostGame:self];
}

- (void)disconnectedPlayersSheetDidEnd:(NSAlert *)alert 
							returnCode:(int)returnCode 
						   contextInfo:(void *)contextInfo
{
	[[alert window] orderOut:self];
	[NSApp endSheet:[alert window]];
	
	if (returnCode == 0)
	 {
		[self backToLobby];

	} else if (returnCode == -1) 
	{
		[gameGrid setAllowInput:NO];
		[self cancelHostGame:self];
	}
}

- (void)inGameTableViewRightClicked:(NSNotification *)notif
{
	NSEvent *theEvent = [[notif userInfo] objectForKey:@"event"];
	int row = [[[notif userInfo] objectForKey:@"row"] intValue];
	
	if (row > [players count]-1)
		return;
	
	NSDictionary *contextMenuPlayer = [players objectAtIndex:row];

	NSMenu *contextMenu = [[NSMenu alloc] initWithTitle:[contextMenuPlayer objectForKey:@"name"]];
	[contextMenu setAutoenablesItems:NO];
	[contextMenu addItemWithTitle:@"Kick" 
						   action:@selector(kickPlayer:)
				    keyEquivalent:@""];

	[[contextMenu itemAtIndex:0] setEnabled:([contextMenuPlayer objectForKey:@"device"] != self)];
	[[contextMenu itemAtIndex:0] setTarget:self];
	[[contextMenu itemAtIndex:0] setTag:row];
	
	[contextMenu addItemWithTitle:([muteList containsObject:contextMenuPlayer] ? @"Unmute" : @"Mute")
						   action:@selector(mutePlayer:)
				    keyEquivalent:@""];
	[[contextMenu itemAtIndex:1] setEnabled:([contextMenuPlayer objectForKey:@"device"] != self)];
	[[contextMenu itemAtIndex:1] setTarget:self];
	[[contextMenu itemAtIndex:1] setTag:row];
	
	[NSMenu popUpContextMenu:contextMenu
				   withEvent:theEvent
				     forView:playersTableView];
	[contextMenu autorelease];
}
@end

@implementation MFHostGameController (NSNetServiceDelegation)

- (void)setupService
{
    // Setup its address structure
	struct sockaddr_in addr;
    bzero( &addr, sizeof(struct sockaddr_in));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = htonl(INADDR_ANY);	// Bind to any of the system addresses
    addr.sin_port = htons(PORT_NUMBER);
	
    // Create a socket
	int sockfd = socket( AF_INET, SOCK_STREAM, 0 );
	if (sockfd == - 1)
	{
		NSLog(@"could not get a socket");
		[self cancelHostGame:self];
		return;
	}
	
	// Bind it to an address and port
	int on = 1;
	setsockopt( sockfd, SOL_SOCKET, SO_REUSEPORT, &on, sizeof(on) );
	
	if(bind(sockfd, (struct sockaddr *)&addr, sizeof(struct sockaddr)) == - 1)
	{
		NSLog(@"Could not bind Socket :%d/%s\n", errno, strerror(errno));
		[self cancelHostGame:self];
		return;
	}

    // Set it listening for connections
    listen( sockfd, 5 );

    // Create NSFileHandle to communicate with socket
	listeningSocket = [[NSFileHandle alloc] initWithFileDescriptor:sockfd closeOnDealloc:YES];
	if (!listeningSocket)
	{
		NSLog(@"listening socket was nil");
		[self cancelHostGame:self];
		return;
	}

    // Register for NSFileHandle socket-related Notifications
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self 
		selector:@selector(newPlayerConnected:) 
			name:NSFileHandleConnectionAcceptedNotification 
		  object:nil];

    // Accept connections in background and notify
    [listeningSocket acceptConnectionInBackgroundAndNotify];
	
    // Configure and publish the Rendezvous service
    service = [[NSNetService alloc] initWithDomain:@""
				    type:MF_PROTOCOL
				    name:[NSString stringWithFormat:@"%@'s Game:%i/4", defaultName, [players count]]
				    port:addr.sin_port];
    [service setDelegate:self];
    [service publish];
	if ([[appController valueForKey:@"trackerCheckBox"] state] == NSOnState)
		[self startTrackerTimer];
}

- (void)updateService
{
	[service stop];
	[service release];
	service = [[NSNetService alloc] initWithDomain:@""
				    type:MF_PROTOCOL
				    name:[NSString stringWithFormat:@"%@'s Game:%i/4", defaultName, [players count]]
				    port:htons(PORT_NUMBER)];
    [service setDelegate:self];
    [service publish];
	
	if ([[appController valueForKey:@"trackerCheckBox"] state] == NSOnState)
		[self updateTracker];
}

- (void)stopService
{
    [[NSNotificationCenter defaultCenter] removeObserver:self 
													name:NSFileHandleConnectionAcceptedNotification 
												  object:nil];
	
	if (service) {
		[service stop];
		[service release];
		service = nil;
	}
		
	if (listeningSocket) {
		[listeningSocket closeFile];
		[listeningSocket release];
		listeningSocket = nil;
	}
	
	[self stopTrackerTimer];
}

// Publication Specific
- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict
{
    NSLog( @"Could not publish the service %@. Error dictionary follows...", [sender name] );
    NSLog( [errorDict description] );

	[NSAlert alertWithMessageText:@"Server broadcast error"
				    defaultButton:@"OK"
				  alternateButton:nil
				      otherButton:nil
		informativeTextWithFormat:@"Server could not broadcast itself on the local domain. Other people will not see you in their browsers."];
}

- (void)netServiceWillPublish:(NSNetService *)sender
{
    NSLog( @"Publishing service %@", [sender name] );
}

- (void)netServiceDidStop:(NSNetService *)sender
{
    NSLog( @"Stopping service %@", [sender name] );
}

// Resolution Specific
- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
    NSLog( @"There was an error while attempting to resolve address for %@",
			[sender name] );
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
    NSLog( @"Successfully resolved address for %@.", [sender name] );
}

- (void)netServiceWillResolve:(NSNetService *)sender
{
    NSLog( @"Attempting to resolve address for %@...", [sender name] );
}

@end

@implementation MFHostGameController (PlayersTableViewDataSource)

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	if ([playersTableView selectedRow] < 0)
	{
		[kickPlayerButton setEnabled:NO];
		[mutePlayerButton setEnabled:NO];
		[mutePlayerButton setTitle:@"Mute"];
		[[NSColorPanel sharedColorPanel] close];
		return;
	}
	
	int selectedRow = [playersTableView selectedRow];
	NSColor *playerColor = [[players objectAtIndex:selectedRow] objectForKey:@"color"];
	[[NSColorPanel sharedColorPanel] setColor:playerColor];
	
	NSDictionary *aPlayer = [players objectAtIndex:[playersTableView selectedRow]];
	
	if ([aPlayer objectForKey:@"device"] == self) {
		[kickPlayerButton setEnabled:NO];
		[mutePlayerButton setEnabled:NO];
		[mutePlayerButton setTitle:@"Mute"];
		return;
	
	} else {
		[kickPlayerButton setEnabled:YES];
	}
	
	if ([muteList containsObject:aPlayer]) {
		[mutePlayerButton setEnabled:YES];
		[mutePlayerButton setTitle:@"Unmute"];
		
	} else {
		[mutePlayerButton setEnabled:YES];
		[mutePlayerButton setTitle:@"Mute"];
	}
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info
            row:(int)dropRowIndex dropOperation:(NSTableViewDropOperation)operation

{	
	NSPasteboard* pboard = [info draggingPasteboard];
    NSData* rowData = [pboard dataForType:MFDragDropTableViewDataType];
	int dragRowIndex = [[NSKeyedUnarchiver unarchiveObjectWithData:rowData] firstIndex];
	
	id draggedRow = [[players objectAtIndex:dragRowIndex] retain];
	
	if (dragRowIndex < dropRowIndex)
		dropRowIndex -= 1;
	
	[players removeObjectAtIndex:dragRowIndex];
	[players insertObject:draggedRow atIndex:dropRowIndex];
	
	[playersTableView reloadData];
	
	unsigned char dragRow = (unsigned char)dragRowIndex;
	unsigned char dropRow = (unsigned char)dropRowIndex;
	NSMutableData *data = [[NSMutableData alloc] init];
	[data appendBytes:&MF_N_PLAYLISTMOVE length:sizeof(MF_N_PLAYLISTMOVE)];
	[data appendBytes:&dragRow length:sizeof(dragRow)];
	[data appendBytes:&dropRow length:sizeof(dropRow)];
	[self sendDataToPlayers:data withException:nil];
	
	[draggedRow release];
	
	return YES;

}

@end

@implementation MFHostGameController (ColorChange)

- (BOOL)colorChanged:(id)sender
{
	if (![super colorChanged:sender])
		return NO;
	
	int selectedRow = [playersTableView selectedRow];
	id client = [[players objectAtIndex:selectedRow] objectForKey:@"device"];
	NSColor *aColor = [[players objectAtIndex:selectedRow] objectForKey:@"color"];
	if (client != self) 
	{
		NSMutableData *data = [[NSMutableData alloc] init];
		[data appendBytes:&MF_N_NEWCOLOR length:sizeof(MF_N_NEWCOLOR)];
		
		float colors[3];
		colors [0] = [aColor redComponent];
		colors [1] = [aColor greenComponent];
		colors [2] = [aColor blueComponent];
		[data appendBytes:colors length:sizeof(colors)];
		
		[client sendData:data];
		[data release];
	} 
	else
		defaultColor = aColor;
		
	
	{ // Send everyplayer the new list
		NSMutableData *data = [[NSMutableData alloc] initWithBytes:&MF_N_PLAYLIST length:sizeof(MF_N_PLAYLIST)];
		[data appendData:[self playersData]];
		[self sendDataToPlayers:data withException:NULL];
		[data release];
	}

	return YES;
}

@end

