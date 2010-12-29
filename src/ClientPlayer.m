#import "ClientPlayer.h"

@implementation ClientPlayer

- (id)initWithFileHandle:(NSFileHandle *)aFileHandle hostServer:(id)aServer
{
	if ([super init] && aFileHandle){

		fileHandle = [aFileHandle retain];
		server = aServer;
		playerDict = NULL;
		
		[fileHandle readInBackgroundAndNotify];
		
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self 
			   selector:@selector(receiveMessage:)
				   name:NSFileHandleReadCompletionNotification
				 object:fileHandle];
		
		NSMutableData *data = [NSMutableData dataWithData:
			[NSData dataWithBytes:&MF_N_ACCEPTEDCONNECT length:sizeof(MF_N_ACCEPTEDCONNECT)]];
		[data appendBytes:&MF_VERSIONNUMBER length:sizeof(MF_VERSIONNUMBER)];
		
		[self sendData:data];
		
		return self;
		
	} else
		return nil;
}

- (void)sendData:(NSData *)data
{
	NSMutableData *dataWithSize = [[NSMutableData alloc] init];
	unsigned char messageSize = (unsigned char)[data length];
	[dataWithSize appendBytes:&messageSize length:sizeof(messageSize)];
	[dataWithSize appendBytes:[data bytes] length:[data length]];
	
	[fileHandle writeData:dataWithSize];
	[dataWithSize release];
}

- (void)receiveMessage:(NSNotification *)notification
{
	NSData *messageData = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];
	
	if ( [messageData length] == 0 ) 
	{
		if (playerDict == NULL)
			[self release];
		else
			[server removePlayer:self wasKicked:NO];
		return;
	}

	char messageType;
	[messageData getBytes:&messageType range:NSMakeRange(0,1)];
	
	// The player sets his name and color at first
	if (messageType == MF_N_PLAYERDESCRIPTION) 
	{
		unsigned char nameSize;
		int bytePointer;
		CFSwappedFloat32 colors[3];
		
		int requiredSize = sizeof(MF_N_PLAYERDESCRIPTION) + sizeof(nameSize);
		
		if ([messageData length] < requiredSize)
		{
			NSLog(@"Player sent incomplete description");
			[self release];
			return;
		}
		
		bytePointer = sizeof(MF_N_PLAYERDESCRIPTION);
		
		[messageData getBytes:&nameSize range:NSMakeRange( bytePointer , sizeof(nameSize) )];
		
		requiredSize += (int)nameSize + sizeof(colors);
		
		if ([messageData length] != requiredSize)
		{
			NSLog(@"Player sent incomplete description");
			[self release];
			return;
		}
		
		bytePointer += sizeof(nameSize);
		
		char playerName[nameSize + 1];
			
		[messageData getBytes:playerName range:NSMakeRange( bytePointer , sizeof(playerName))];
		bytePointer += sizeof(playerName) - 1;
		playerName[nameSize] = '\0';
		
		[messageData getBytes:colors range:NSMakeRange( bytePointer , sizeof(colors) )];
		bytePointer += sizeof(colors);
		
		NSString *name = [[NSString alloc] initWithBytes:playerName 
									    length:sizeof(playerName)
									  encoding:NSUTF8StringEncoding];
		[name autorelease];
		NSColor *color = [NSColor colorWithCalibratedRed:CFConvertFloat32SwappedToHost(colors[0])
									      green:CFConvertFloat32SwappedToHost(colors[1])
										   blue:CFConvertFloat32SwappedToHost(colors[2])
										  alpha:1];
		
		if (name == NULL || color == NULL)
		{
			NSLog(@"Player sent incomplete description");
			[self release];
			return;
		}
		
		playerDict = [[[NSMutableDictionary alloc] init] autorelease];
		[playerDict setObject:name forKey:@"name"];
		[playerDict setObject:color forKey:@"color"];
										  
		if(!name || !color) {
			[self release];
			return;
		}
		
		[server addPlayer:[self autorelease]];
	}
	
	else if (messageType == MF_N_DISCONNECT)  
	{
		[server removePlayer:self wasKicked:NO];
		return;
	}
	
	else if (messageType == MF_N_PLACEDSHAPE)  
	{
		size_t bytePointer = sizeof(MF_N_PLACEDSHAPE);
		unsigned char charRow, charCol;
		
		int requiredSize = sizeof(MF_N_PLACEDSHAPE) + sizeof(charRow)*2;
		if ([messageData length] != requiredSize)
		{
			[server removePlayer:self wasKicked:NO];
			NSLog(@"Player sent incomplete coordinates for shape");
			return;
		}
		
		[messageData getBytes:&charRow range:NSMakeRange( bytePointer , sizeof(charRow) )];
		bytePointer += sizeof(charRow);
		[messageData getBytes:&charCol range:NSMakeRange( bytePointer, sizeof(charCol) )];
		
		[server currentPlayerPlacedShapeAtRow:(int)charRow 
									   column:(int)charCol 
									   sender:self];
	}
	
	else if (messageType == MF_N_ROTATED)  
		[server currentPlayerRotatedShape:self];
	
	else if (messageType == MF_N_BITEBUTTON)  
		[server currentPlayerPressedBiteButton:self];
	
	else if (messageType == MF_N_BITEPLACED)   
	{
		size_t bytePointer = sizeof(MF_N_BITEPLACED);
		unsigned char charRow, charCol;
		
		int requiredSize = sizeof(MF_N_BITEPLACED) + sizeof(charRow)*2;
		
		if ([messageData length] != requiredSize)
		{
			[server removePlayer:self wasKicked:NO];
			NSLog(@"Player sent incomplete coordinates for bite");
			return;
		}
		
		[messageData getBytes:&charRow range:NSMakeRange( bytePointer , sizeof(charRow) )];
		bytePointer += sizeof(charRow);
		[messageData getBytes:&charCol range:NSMakeRange( bytePointer, sizeof(charCol) )];
		
		[server currentPlayerPlacedBiteAtRow:(int)charRow 
									   column:(int)charCol 
									   sender:self];
	}
	
	else if (messageType == MF_N_BIGBITEPLACED)   
	{
		size_t bytePointer = sizeof(MF_N_BIGBITEPLACED);
		unsigned char charRow, charCol;
		
		int requiredSize = sizeof(MF_N_BIGBITEPLACED) + sizeof(charRow)*2;
		
		if ([messageData length] != requiredSize)
		{
			[server removePlayer:self wasKicked:NO];
			NSLog(@"Player sent incomplete coordinates for bite");
			return;
		}
		
		[messageData getBytes:&charRow range:NSMakeRange( bytePointer , sizeof(charRow) )];
		bytePointer += sizeof(charRow);
		[messageData getBytes:&charCol range:NSMakeRange( bytePointer, sizeof(charCol) )];
		
		[server currentPlayerPlacedBigBiteAtRow:(int)charRow 
									   column:(int)charCol 
									   sender:self];
	}
	
	else if (messageType == MF_N_SKIPTURN)   
		[server currentPlayerSkippedTurn:self];
		
	else if (messageType == MF_N_CHATMESSAGE)
	{
		int messageSize = [messageData length] - sizeof(MF_N_CHATMESSAGE);
		char chatMessage[messageSize + 1];
		[messageData getBytes:&chatMessage range:NSMakeRange(sizeof(MF_N_CHATMESSAGE), messageSize)];
		chatMessage[messageSize] = '\0';
		NSString *messageString = [[NSString alloc] initWithBytes:chatMessage 
														   length:sizeof(chatMessage)
														 encoding:NSUTF8StringEncoding];
		[server broadcastChatMessage:messageString from:self];
	}

	[fileHandle readInBackgroundAndNotify];
}

-(void)dealloc
{
	NSLog(@"player dealloc");
	[fileHandle closeFile];
	[fileHandle release];
		
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

@end
