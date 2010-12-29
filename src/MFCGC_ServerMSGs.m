#import "MFCGC_ServerMSGs.h"
#import "MFClientGameController.h"

@implementation MFClientGameController (BufferReading)

- (void)receiveData:(NSNotification *)notification
{	
	/* Protocol structure :
	sizeByte(1 byte):MessageType(1 byte):Message
	*/
	
	NSData *data = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];
	
	if (![data length]) { // Received null data, we are disconnected
		NSLog(@"Received null from server");
		
		if ([browserSheet isVisible]) 
		{
			[self cancelJoin:nil];
			return;
		}
		
		[self disconnectFromServerWithAlert:@"Server closed connection without warning."];
		return;
	}
	
	[buffer appendData:data];
	
walkBuffer:
		
		if (!messageSize) //Did we start a new message?
		{ 
			//Get the data byte size
			unsigned char firstByte;
			[buffer getBytes:&firstByte length:sizeof(firstByte)];
			messageSize = firstByte;
			
			//Strip the size bytes
			[buffer setData:[buffer subdataWithRange:NSMakeRange(1,[buffer length] - 1)]];
		}
	
	if (messageSize <= [buffer length]) { // we got an entire message
		
		[self processData:[buffer subdataWithRange:NSMakeRange(0, messageSize)]];
		
		if (messageSize == [buffer length]) 
		{
			[buffer release];
			buffer = [[NSMutableData alloc] init];
			messageSize = 0;
		} else {
			
			//Take the rest		
			NSRange aRange = NSMakeRange(messageSize, [buffer length] - messageSize);
			[buffer setData:[buffer subdataWithRange:aRange]];
			messageSize = 0;
			goto walkBuffer;
		}
	}
	
	[remoteServer readInBackgroundAndNotify];
}

- (void)processData:(NSData *)messageData
{
	unsigned char messageType;
	[messageData getBytes:&messageType length:sizeof(messageType)];
	NSRange subDataRange = 
		NSMakeRange( sizeof(messageType), [messageData length] - sizeof(messageType) );
	NSData *subData = [messageData subdataWithRange:subDataRange];
	
	if (messageType == MF_N_ACCEPTEDCONNECT)
		[self connectionAccepted:subData];
	
	else if (messageType == MF_N_PLAYLIST) 
		[self receivedPlaylist:subData];

	else if (messageType == MF_N_PLAYLISTMOVE)
		[self receivedPlaylistMove:subData];
		
	else if (messageType == MF_N_NEWCOLOR)
		[self receivedNewColor:subData];
	
	else if (messageType == MF_N_NEWNAME)
		[self receivedNewName:subData];
	
	else if (messageType == MF_N_DISCONNECT)  
		[self disconnectFromServerWithAlert:@"Server has closed down or you have been kicked"];
	
	//GameStarted
	else if (messageType == MF_N_GAMESTARTS)  
	{
		nextShape = 0;
		[self startGame];
	}
	
	//CurrentPlayerPlacedShape
	else if (messageType == MF_N_PLACEDSHAPE)  
		[self receivedPlacedShape:subData];
	
	else if (messageType == MF_N_BITEPLACED)  
		[self receivedBite:subData];
	
	else if (messageType == MF_N_BIGBITEPLACED)  
		[self receivedBigBite:subData];
		
	else if (messageType == MF_N_NEWSHAPE)
		[self receivedNewShape:subData];
		
	else if (messageType == MF_N_BITEBUTTON)
		[self currentPlayerPressedBiteButton:remoteServer];
		
	else if (messageType == MF_N_ROTATED)
		[gameGrid rotateShape];
		
	else if (messageType == MF_N_SKIPTURN)
		[self currentPlayerSkippedTurn:remoteServer];
		
	else if (messageType == MF_N_REMOVEPLAYER) 
		[self receivedPlayerRemoval:subData];
		
	else if (messageType == MF_N_BACKTOLOBBY)
		[self receivedBackToLobby:subData];
	
	else if (messageType == MF_N_CHATMESSAGE)
		[self receivedChatMessage:subData];
	
	else if (messageType == MF_N_GRIDSIZE)
		[self receivedGridSize:subData];
	
	else if (messageType == MF_N_HOTCORNERSSWITCH)
		[self receivedHotCornersState:subData];
		
	else if (messageType == MF_N_GAMESPEED)
		[self receivedGameSpeed:subData];
	
}

- (NSMutableArray *)playersListFromData:(NSData *)data
{
	int bytePointer = 0;
	NSMutableArray *playersArray = [[NSMutableArray alloc] init];
	
	while (bytePointer < [data length]) 
	{
		NSDictionary *aPlayer;
		NSString *playerName;
		
		char anID;
		unsigned char nameSize; 
		CFSwappedFloat32 colors[3];
		
		[data getBytes:&nameSize range:NSMakeRange(bytePointer, 1)];
		bytePointer += sizeof(nameSize);
		
		char nameString[nameSize];
		
		[data getBytes:nameString range:NSMakeRange(bytePointer, nameSize)];
		bytePointer += nameSize;
		
		[data getBytes:&colors range:NSMakeRange(bytePointer, sizeof( colors ) )];
		bytePointer += sizeof(colors);
		
		
		[data getBytes:&anID range:NSMakeRange(bytePointer, sizeof(anID))];
		bytePointer += sizeof(anID);
		
		playerName = [[NSString alloc] initWithBytes:nameString 
											  length:sizeof(nameString)
											encoding:NSUTF8StringEncoding];
		NSColor *playerColor = [NSColor colorWithCalibratedRed:CFConvertFloat32SwappedToHost(colors[0])
														 green:CFConvertFloat32SwappedToHost(colors[1])
														  blue:CFConvertFloat32SwappedToHost(colors[2])
														 alpha:1];
														 
		aPlayer = [NSDictionary dictionaryWithObjectsAndKeys:playerColor, @"color",
															 playerName, @"name",
															 [NSNumber numberWithChar:anID], @"id", nil];
		[playersArray addObject:aPlayer];
		[playerName release];
	}
	
	[playersArray autorelease];
	return playersArray;
}

@end

@implementation MFClientGameController (DataExecution)

- (void)connectionAccepted:(NSData *)messageData
{
	NSLog(@"Received connection accepted");
	
	// Check Size of data
	if ([messageData length] < sizeof(MF_VERSIONNUMBER))
	{
		[self cancelJoin:nil];
		return;
	}
	
	{ // Check version of MacFungus
		char hostVersion;
		[messageData getBytes:&hostVersion range:
			NSMakeRange(0 ,sizeof(MF_VERSIONNUMBER))];
		
		
		if (MF_VERSIONNUMBER != hostVersion)
		{
			[self cancelJoin:nil];
			return;
		}
	}
	
	// We're goodw! Stop the timouttimer
	timerShouldStop = YES;
	
	[appController fixNameFields];
	if (defaultName) [defaultName release];
	if (defaultColor) [defaultColor release];
		
	defaultName = [[[appController valueForKey:@"defaultNameField"] stringValue] retain];
	defaultColor = [[[appController valueForKey:@"defaultColorWell"] color] retain];
	//Send player description
	{
		NSMutableData *data = [[NSMutableData alloc] init];
		const char *aName = [defaultName UTF8String];
		
		unsigned char sizeOfName = strlen(aName);
		
		CFSwappedFloat32 playerColorSwapped[3] = 
		{ CFConvertFloatHostToSwapped([defaultColor redComponent]), 
			CFConvertFloatHostToSwapped([defaultColor greenComponent]),
			CFConvertFloatHostToSwapped([defaultColor blueComponent]) };
		
		[data appendBytes:&MF_N_PLAYERDESCRIPTION length:sizeof(MF_N_PLAYERDESCRIPTION)];
		[data appendBytes:&sizeOfName length:sizeof(sizeOfName)];
		[data appendBytes:aName length:sizeOfName];
		[data appendBytes:playerColorSwapped length:sizeof(playerColorSwapped)];
		
		[self sendDataToServer:data];
		
		[data release];
	}
	
	[chatDrawerTextView setString:@""];
	[self closeBrowserSheet:nil];
	[self openLobbySheet];
}

- (void)receivedPlaylist:(NSData *)messageData
{
	// Data structure:
	// sizeofname (1) : name (sizeofname) : colors (16): sizeofname...end of message
	
	NSLog(@"Receive a player list");
	
	[players release];
	players = [self playersListFromData:messageData];
	[players retain];
	
	{ // Remove players which are gone from the muteList
		int i;
		NSMutableArray *mutesToKeep = [NSMutableArray new];
		
		for (i = 0; i < [muteList count]; i++)
		{
			int mutedID = [[[muteList objectAtIndex:i] objectForKey:@"id"] intValue];
			if ([self playerWithID:mutedID])
				[mutesToKeep addObject:muteList];
		}
		
		[muteList removeAllObjects];
		[muteList addObjectsFromArray:mutesToKeep];
		[mutesToKeep release];
	}
	
	[playersTableView reloadData];
	
	{ // Set the title of the window to the host's game
		NSString *hostName = [[self playerWithID:1] objectForKey:@"name"];
		NSString *windowTitle = [NSString stringWithFormat:@"%@'s game", hostName];
		[mainWindow setTitle:windowTitle];
	}
	
}

- (void)receivedPlaylistMove:(NSData *)messageData
{
	NSLog(@"Received moved player in list");
	
	int bytePointer;
	unsigned char dragRow;
	unsigned char dropRow;
	
	int requiredSize = sizeof(dragRow) + sizeof(dropRow);
	
	if ([messageData length] != requiredSize)
	{
		[self disconnectFromServerWithAlert:@"Received incomplete message while sending a move in the playlist."];
		return;
	}
	
	bytePointer = 0;
	[messageData getBytes:&dragRow range:NSMakeRange(bytePointer, sizeof(unsigned char))];
	
	bytePointer += sizeof(unsigned char);
	[messageData getBytes:&dropRow range:NSMakeRange(bytePointer, sizeof(unsigned char))];
	
	[self movePlayerAtRow:(unsigned int)dragRow toRow:(unsigned int)dropRow];
}

- (void)receivedNewColor:(NSData *)messageData
{
	NSLog(@"received new color");
	
	int requiredSize = sizeof(CFSwappedFloat32)*3;
	if ([messageData length] != requiredSize)
	{
		[self disconnectFromServerWithAlert:@"Received incomplete message (new color). You have been disconnected."];
		return;
	}
	
	CFSwappedFloat32 color[3];
	[messageData getBytes:color length:sizeof(color)];
	
	[defaultColor release];
	defaultColor = [NSColor colorWithDeviceRed:CFConvertFloat32SwappedToHost(color[0])
										 green:CFConvertFloat32SwappedToHost(color[1])
										  blue:CFConvertFloat32SwappedToHost(color[2])
										 alpha:1];
	[defaultColor retain];
}

- (void)receivedNewName:(NSData *)messageData
{
	NSLog(@"received new name");
	
	char newName;
	[messageData getBytes:&newName length:[messageData length]];
	
	[defaultName release];
	defaultName = [NSString stringWithUTF8String:&newName];
	[defaultName retain];
}

- (void)receivedPlacedShape:(NSData *)messageData
{
	NSLog(@"receivedPlacedShape");
	
	unsigned char row, col;
	int requiredSize = sizeof(row)*2;
	
	if ([messageData length] != requiredSize)
	{
		[self disconnectFromServerWithAlert:
			@"Received incomplete message (shape coordinates). You have been disconnected."];
		return;
	}
	
	size_t bytePointer = 0;
	[messageData getBytes:&row 
					range:NSMakeRange(bytePointer,sizeof(row))];
	bytePointer += sizeof(row);
	[messageData getBytes:&col range:NSMakeRange(bytePointer,sizeof(col))];
	
	[self currentPlayerPlacedShapeAtRow:(int)row 
								 column:(int)col 
								 sender:remoteServer];
	
}

- (void)receivedBite:(NSData *)messageData
{
	NSLog(@"receivedBite");
	unsigned char row, col;
	
	int requiredSize = sizeof(row)*2;
	
	if ([messageData length] != requiredSize)
	{
		[self disconnectFromServerWithAlert:
			@"Received incomplete message (bite coordinates). You have been disconnected."];
		return;
	}
	
	size_t bytePointer = 0;
	
	[messageData getBytes:&row range:NSMakeRange(bytePointer,sizeof(row))];
	bytePointer += sizeof(row);
	
	[messageData getBytes:&col range:NSMakeRange(bytePointer,sizeof(col))];
	
	[self currentPlayerPlacedBiteAtRow:(int)row 
								column:(int)col 
								sender:remoteServer];
}

- (void)receivedBigBite:(NSData *)messageData
{
	NSLog(@"receivedBite");
	unsigned char row, col;
	
	int requiredSize = sizeof(row)*2;
	
	if ([messageData length] != requiredSize)
	{
		[self disconnectFromServerWithAlert:
			@"Received incomplete message (bite coordinates). You have been disconnected."];
		return;
	}
	
	size_t bytePointer = 0;
	
	[messageData getBytes:&row range:NSMakeRange(bytePointer,sizeof(row))];
	bytePointer += sizeof(row);
	
	[messageData getBytes:&col range:NSMakeRange(bytePointer,sizeof(col))];
	
	[self currentPlayerPlacedBigBiteAtRow:(int)row 
								column:(int)col 
								sender:remoteServer];
}

- (void)receivedNewShape:(NSData *)messageData
{
	NSLog(@"receivedNewShape");
	
	nextShape = 0;
	unsigned char charNextShape;
	int requiredSize = sizeof(charNextShape);
	
	if ([messageData length] != requiredSize)
	{
		[self disconnectFromServerWithAlert:
			@"Received incomplete message (new shape). You have been disconnected."];
		return;
	}
	
	[messageData getBytes:&charNextShape length:sizeof(charNextShape)];
	
	nextShape = (int)charNextShape;
}

- (void)receivedPlayerRemoval:(NSData *)messageData
{
	NSLog(@"receivedPlayerRemoval");
	
	char playerID;
	char wasKicked;
	int bytePointer = 0;
	int requiredSize = sizeof(playerID) + sizeof(wasKicked);
	NSDictionary *playerDict;
	
	if ([messageData length] != requiredSize)
	{
		[self disconnectFromServerWithAlert:@"Received incomplete message (disconnected player). You have been disconnected."];
		return;
	}
	
	[messageData getBytes:&playerID range:NSMakeRange(bytePointer, sizeof(playerID))];
	bytePointer += sizeof(playerID);
	NSLog(@"kicked id:%i", playerID);
	[messageData getBytes:&wasKicked range:NSMakeRange(bytePointer, sizeof(wasKicked))];
	
	playerDict = [self playerWithID:playerID];
	
	if (![lobbySheet isVisible])
		[self removePlayerWithColorDuringGame:[playerDict objectForKey:@"color"]];
	
	if (wasKicked != 0)
	{
		NSString *playerName = [playerDict objectForKey:@"name"];
		[self systemPost:[NSString stringWithFormat:@"%@ was kicked from server", playerName]]; 
	}
	
	[players removeObject:playerDict];
	[playersTableView reloadData];
	
	
}

- (void)receivedBackToLobby:(NSData *)messageData
{
	[players release];
	players = [self playersListFromData:messageData];
	[players retain];
	
	[chatDrawer close];
	[self openLobbySheet];
}

- (void)receivedChatMessage:(NSData *)messageData
{
	NSDictionary *playerDict;
	NSString *messageString;
	char playerID;
	
	int bytePointer = 0;
	
	[messageData getBytes:&playerID range:NSMakeRange( bytePointer, sizeof(playerID))];
	bytePointer += sizeof(playerID);
	
	char messageCString[[messageData length] - bytePointer];
	[messageData getBytes:&messageCString range:NSMakeRange( bytePointer , sizeof(messageCString))];
	
	messageCString[[messageData length] - bytePointer] = '\0';
	
	messageString = [[NSString alloc] initWithBytes:messageCString  
											 length:sizeof(messageCString) 
										   encoding:NSUTF8StringEncoding];
	{	// find the player with the ID											 
		int i;
		for (i = 0 ; i < [players count] ; i++)
		{
			char anotherID = [[[players objectAtIndex:i] objectForKey:@"id"] charValue];
			if (anotherID == playerID)
				playerDict = [players objectAtIndex:i];
		}
	}
	
	[self postMessage:messageString from:playerDict];
	[messageString release];
}

- (void)receivedGridSize:(NSData *)messageData
{
	NSLog(@"receivedGridSize");
	
	unsigned char gridSizeIndex;
	int requiredSize = sizeof(gridSizeIndex);
	
	if ([messageData length] != requiredSize)
	{
		[self disconnectFromServerWithAlert:@"Received incomplete message (new grid size). You have been disconnected."];
		return;
	}
	[messageData getBytes:&gridSizeIndex length:sizeof(gridSizeIndex)];
	[gridSizePopUp selectItemAtIndex:(int)gridSizeIndex];
	
	NSString *systemString = [NSString stringWithFormat:@"Grid size set to %@", [gridSizePopUp titleOfSelectedItem]];
	[self systemPost:systemString];
}

- (void)receivedHotCornersState:(NSData *)messageData
{
	NSLog(@"Received MF_N_HOTCORNERSSWITCH");
	unsigned char state;
	
	int requiredSize = sizeof(state);
	if ([messageData length] != requiredSize)
	{
		[self disconnectFromServerWithAlert:@"Received incomplete message (hot corner switch). You have been disconnected."];
		return;
	}
	
	[messageData getBytes:&state length:sizeof(state)];
	[hotCornersSwitch setState:(state ? NSOnState : NSOffState)];
	
	NSString *onOffString = (state ? @"On" : @"Off");
	NSString *systemString = [NSString stringWithFormat:@"Hot corners set to %@", onOffString];
	[self systemPost:systemString];
}

- (void)receivedGameSpeed:(NSData *)messageData
{
	NSLog(@"Received MF_N_GAMESPEED");
	unsigned char gameSpeedIndex;
	int requiredSize = sizeof(gameSpeedIndex);
	if ([messageData length] != requiredSize)
	{
		[self disconnectFromServerWithAlert:@"Received incomplete message (new game speed). You have been disconnected."];
		return;
	}
	[messageData getBytes:&gameSpeedIndex length:sizeof(gameSpeedIndex)];
	[gameSpeedPopUp selectItemAtIndex:(int)gameSpeedIndex];
	
	NSString *systemString = [NSString stringWithFormat:@"Game speed set to %@", [gameSpeedPopUp titleOfSelectedItem]];
	[self systemPost:systemString];
}

@end
