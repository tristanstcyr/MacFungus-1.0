#import "MFClientGameController.h"
#import "ColorCell.h"
#import "MFLobbyNameCell.h"
#import "NSColor_Compare.h"

#import <sys/socket.h> // sockets
#import <sys/types.h>
#include <stdio.h> // fprintf
#import <netinet/in.h> // sockaddr_in
#import <errno.h> // errno
#import <string.h> // strerrno
#import <netdb.h> // gethostbyname2

#define STATUSFIELD_SPACE ([connectingStatusField frame].size.height + 13.0f)

#define PORT_NUMBER 47888

@implementation MFClientGameController

- (id)initWithObjectDict:(NSDictionary *)objectDict
{
	
	self = [super initWithObjectDict:objectDict];
	
	buffer = [[NSMutableData alloc] init];
	messageSize = 0;
	timerShouldStop = NO;
	lastMessageDate = NULL;

	defaultName = NULL;
	defaultColor = NULL;
	
	joinGameNib = [[NSNib alloc] initWithNibNamed:@"JoinGameSheets" bundle:nil];
	[joinGameNib instantiateNibWithOwner:self topLevelObjects:nil];
	
	browserSheetDefaultFrame = [browserSheet frame];
	[playersTableView setFrame:[[playersTableView superview] frame]];
	
	MFLobbyNameCell *nameCell = [[MFLobbyNameCell alloc] init];
	[nameCell setEditable: NO];
	NSTableColumn *tableColumn = [[playersTableView tableColumns] objectAtIndex:0];
	[tableColumn setDataCell:nameCell];
	[tableColumn setWidth:87];
	
	ColorCell *colorCell = [ColorCell new];
	[colorCell setEditable: NO];
	[[[playersTableView tableColumns] objectAtIndex:1] setDataCell:colorCell];
	
	[chatTextView setTextContainerInset:NSMakeSize(3,3)];
	
	discoveredServices = [[NSMutableArray alloc] init];
	domainBrowser = [[NSNetServiceBrowser alloc] init];
	[domainBrowser setDelegate:self];
	serviceBrowser = [[NSNetServiceBrowser alloc] init];
	[serviceBrowser setDelegate:self];
	
	return self;
}

- (void)dealloc
{
	if (defaultName)
		[defaultName release];
	if (defaultColor)
		[defaultColor release];
	[super dealloc];
}
@end
@implementation MFClientGameController (BrowserSheet)

- (void)openBrowserSheet
{	
	[chatDrawerTextField setTarget:self];
	[chatDrawerTextField setAction:@selector(returnChatMessage:)];
	[chatTextView setString:@""];
	
	[gameGrid setAllowInput:NO];
	[gameGrid clear];
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self 
		selector:@selector(textFieldDidAcceptFirstResponder:)
		name:NSControlTextDidBeginEditingNotification 
		object:customIPTextField];
	[nc addObserver:self 
		selector:@selector(controlTextDidChange:)
		name:NSControlTextDidChangeNotification
		object:browserTableView];
	[nc addObserver:self
		selector:@selector(controlTextDidChange:)
		name:NSControlTextDidChangeNotification
		object:browserTableView];
	[nc addObserver:self 
		selector:@selector(tableViewSelectionDidChange:)
		name:NSTableViewSelectionDidChangeNotification
		object:browserTableView];
	
	[discoveredServices removeAllObjects];
	[self setupBrowser];
	
	[joinGameButton setEnabled:([[customIPTextField stringValue] length] > 0)];
	
	[NSApp beginSheet:browserSheet
	   modalForWindow:mainWindow
		modalDelegate:self
	   didEndSelector:NULL
		  contextInfo:NULL];
	[NSApp endSheet:browserSheet];
}

- (IBAction)closeBrowserSheet:(id)sender
{
	[browserSheet orderOut:nil];
	[NSApp endSheet:browserSheet];
	
	[serviceBrowser stop];
	[domainBrowser stop];
	
	[joinGameButton setEnabled:YES];
	[cancelBrowserButton setAction:@selector(closeBrowserSheet:)];
	[customIPTextField setEditable:YES];
	[customIPTextField setSelectable:YES];
	
	// Setup progress indicators
	[connectingProgressIndicator stopAnimation:nil];
	[connectingStatusField setHidden:YES];
	[connectingProgressIndicator setHidden:YES];
}

- (IBAction)joinGame:(id)sender
{			
	// Connect to server
	[self connectToServer];
	[muteList removeAllObjects];
	// Disable the join button and make the cancel button cancel connection
	[joinGameButton setEnabled:NO];
	[cancelBrowserButton setAction:@selector(cancelJoin:)];
	[customIPTextField setEditable:NO];
	[customIPTextField setSelectable:NO];
	
	// Setup progress indicators
	[connectingProgressIndicator startAnimation:nil];
	[connectingStatusField setHidden:NO];
	[connectingProgressIndicator setHidden:NO];
	
	// Start the timeout timer
	[NSThread detachNewThreadSelector:@selector(startTimeOutTimer) 
							 toTarget:self 
						   withObject:nil];
}

- (IBAction)cancelJoin:(id)sender
{
	timerShouldStop = YES;
	
	[joinGameButton setEnabled:YES];
	[cancelBrowserButton setAction:@selector(closeBrowserSheet:)];
	[customIPTextField setEditable:YES];
	[customIPTextField setSelectable:YES];
	
	if ([[customIPTextField stringValue] length] > 0)
	{
		[customIPTextField setNeedsDisplay:YES];
		[mainWindow makeFirstResponder:customIPTextField];
	}
	else
		[mainWindow makeFirstResponder:browserTableView];
	
	// Setup progress indicators
	[connectingProgressIndicator stopAnimation:nil];
	[connectingStatusField setHidden:YES];
	[connectingProgressIndicator setHidden:YES];
	
	if (remoteServer) 
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:NSFileHandleReadCompletionNotification
													  object:remoteServer];
		[remoteServer closeFile];
		[remoteServer release];
		remoteServer = nil;
	}
}

- (void)startTimeOutTimer
{
	NSAutoreleasePool *autoPool = [[NSAutoreleasePool alloc] init];
	int i = 0;
	timerShouldStop = NO;
	
	while (i++ < 20 && !timerShouldStop) 
	{
		NSString *statusString = [NSString stringWithFormat:@"Waiting for reply: %i sec", i];
		[connectingStatusField performSelectorOnMainThread:@selector(setStringValue:) 
												withObject:statusString 
											 waitUntilDone:NO];
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
	}
	
	if (!timerShouldStop)
	{
		[connectingStatusField setStringValue:[NSString stringWithFormat:@"Server did not respond"]];
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.5f]];
		[self performSelectorOnMainThread:@selector(cancelJoin:) 
							   withObject:nil
						    waitUntilDone:nil];
	}

	[autoPool release];
}

- (void)controlTextDidChange:(NSNotification *)aNotification
{
	[joinGameButton setEnabled:([[customIPTextField stringValue] length] > 0)];
}

- (void)textFieldDidAcceptFirstResponder:(NSNotification *)aNotification
{
	[joinGameButton setEnabled:([[customIPTextField stringValue] length] > 0 ? YES : NO)];
	[browserTableView deselectAll:self];
}

- (void)browserBecameFirstResponder:(NSNotification *)aNotification
{
	if ([discoveredServices count] > 0) 
	{
		if ([browserTableView selectedRow] < 0)
			[browserTableView selectRow:0 byExtendingSelection:NO];
		
		[joinGameButton setEnabled:YES];
	
	} else {
	
		[joinGameButton setEnabled:NO];
		[customIPTextField becomeFirstResponder];
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if ([aNotification object] == browserTableView)
	{
		if ([browserTableView selectedRow] >= 0)
			[joinGameButton setEnabled:YES];
		else
		{
			[browserSheet makeFirstResponder:customIPTextField];
			if ([[customIPTextField stringValue] length] > 0)
				[joinGameButton setEnabled:YES];
			else
				[joinGameButton setEnabled:NO];
		}
		return;
	} 
	
	if ([aNotification object] == playersTableView)
	{
		if	([playersTableView selectedRow] < 0)
		{
			[mutePlayerButton setEnabled:NO];
			[mutePlayerButton setTitle:@"Mute"];
			return;
		}
		
		NSDictionary *aPlayer = [players objectAtIndex:[playersTableView selectedRow]];
		
		// The player is already muted
		if ([muteList containsObject:aPlayer])
		{
			[mutePlayerButton setEnabled:YES];
			[mutePlayerButton setTitle:@"Unmute"];
			return;
		}
		
		// The player is the client
		if ([NSColor color:[aPlayer objectForKey:@"color"] isEqualToColor:defaultColor]) 
		{
			[mutePlayerButton setTitle:@"Mute"];
			[mutePlayerButton setEnabled:NO];
			return;
		}
		
		// The player is not in the list or the client
		[mutePlayerButton setTitle:@"Mute"];
		[mutePlayerButton setEnabled:YES];
	}
}

@end

@implementation MFClientGameController (LobbySheet)

- (void)openLobbySheet
{	
	if ([[chatDrawerTextView textStorage] length] == 0)
	{
		NSAttributedString *attributedString;
		playerDidChat = NO;
		NSString *firstMessageString = [NSString stringWithFormat:@"Connected to: %@\n", serverIP];
		attributedString = [[NSAttributedString alloc] initWithString:firstMessageString 
														   attributes:[self serverMessageAttributes]];
		[[chatTextView textStorage] appendAttributedString:attributedString];
		[serverIP release];
	}
	else
	{
		[chatTextView setString:@""];
		[[chatTextView textStorage] appendAttributedString:[chatDrawerTextView textStorage]];
		int textLength = [[chatTextView textStorage] length];
		[chatTextView scrollRangeToVisible:NSMakeRange(textLength,textLength)];
		
		if ([[chatDrawerTextField stringValue] length] > 0)
		{	
			if ([mainWindow firstResponder] == chatDrawerTextField)
				[lobbySheet makeFirstResponder:chatMessageField];
			
			[chatMessageField setStringValue:[chatDrawerTextField stringValue]];
		}
	}
	
	[lobbySheet makeFirstResponder:chatMessageField];
	[playersTableView reloadData];
	[NSApp beginSheet:lobbySheet
	   modalForWindow:mainWindow
		modalDelegate:self
	   didEndSelector:NULL
		  contextInfo:NULL];
	[NSApp endSheet:lobbySheet];
}

- (IBAction)backToBrowserSheet:(id)sender
{
	[self sendDisconnectionMessage];
	[self disconnectFromServerWithAlert:nil];
	[lobbySheet orderOut:self];
	[NSApp endSheet:lobbySheet];
	
	[gameGrid setAllowInput:NO];
	[gameGrid clear];
	[self cleanUpGame];
	[self openBrowserSheet];
}

- (IBAction)cancelGame:(id)sender
{
	[self sendDisconnectionMessage];
	[self disconnectFromServerWithAlert:nil];
	[lobbySheet orderOut:self];
	[NSApp endSheet:lobbySheet];
	[gameGrid setAllowInput:NO];
	[gameGrid clear];
	[self cleanUpGame];
}

#define MAXMESSAGELENGTH 200
- (IBAction)returnChatMessage:(id)sender
{
	[[sender window] makeFirstResponder:sender];
	
	NSDate *now = [[NSDate alloc] init];
	if (lastMessageDate && [now timeIntervalSinceDate:lastMessageDate] < 0.5)
	{
		[[sender window] makeFirstResponder:sender];
		[now release];
		return;
	} else {
		[lastMessageDate release];
		lastMessageDate = now;
	}
	
	NSString *messageString = [sender stringValue];
	
	if (!messageString || [messageString length] == 0) 
		return;
	
	[sender setStringValue:@""];
	[[mainWindow fieldEditor:NO forObject:sender] setString:@""];
	if ([sender class] == [chatDrawerTextField class])
		[sender sizeToFit];
	
	
	if ([messageString length] > MAXMESSAGELENGTH)
		messageString = [messageString substringWithRange:NSMakeRange(0,MAXMESSAGELENGTH)];
		
	// Send message to server
	NSMutableData *data = [[NSMutableData alloc] initWithBytes:&MF_N_CHATMESSAGE length:sizeof(MF_N_CHATMESSAGE )];
	const char *messageCString = [messageString UTF8String];
	[data appendBytes:messageCString length:strlen(messageCString)];
	[self sendDataToServer:data];
	
	{ // find ourselves in the players list
		int i;
		NSDictionary *selfDict;
		for (i = 0 ; i < [players count] ; i++)
		{
			NSColor *aColor = [[players objectAtIndex:i] objectForKey:@"color"];
			if ([NSColor color:aColor isEqualToColor:defaultColor])
				break;
		}
		
		selfDict = [players objectAtIndex:i];
		[self postMessage:messageString from:selfDict];
	}
}

- (void)movePlayerAtRow:(int)dragRow toRow:(int)dropRow
{
	NSMutableDictionary *dragObject = [players objectAtIndex:dragRow];
	[dragObject retain];
	[players removeObject:dragObject];
	[players insertObject:dragObject atIndex:dropRow];
	[dragObject release];

	[playersTableView reloadData];
}

@end

@implementation MFClientGameController (InGame)

- (void)sendDataToServer:(NSData *)data
{	
	[remoteServer writeData:data];
}

- (void)currentPlayerPlacedShapeAtRow:(int)row column:(int)col sender:(id)sender
{
	if (sender == self)  //If client played send it to server
	{ 
		NSMutableData *data = [[NSMutableData alloc] 
									initWithBytes:&MF_N_PLACEDSHAPE 
										   length:sizeof(MF_N_PLACEDSHAPE)];
		unsigned char charRow = (unsigned char) row,
					  charCol = (unsigned char) col;
		[data appendBytes:&charRow length:sizeof(unsigned char)];
		[data appendBytes:&charCol length:sizeof(unsigned char)];
		[self sendDataToServer:data];
		[data release];
	}
	
	nextShape = 0;
	[super currentPlayerPlacedShapeAtRow:row column:col sender:sender];
}

- (void)currentPlayerPressedBiteButton:(id)sender
{
	if (sender == self)
		[self sendDataToServer:[NSData dataWithBytes:&MF_N_BITEBUTTON 
											  length:sizeof(MF_N_BITEBUTTON)]];
	else
		[super currentPlayerPressedBiteButton:sender];
}

- (void)currentPlayerRotatedShape:(id)sender
{
	if (sender == self)
		[self sendDataToServer:[NSData dataWithBytes:&MF_N_ROTATED 
											  length:sizeof(MF_N_ROTATED)]];
		
	[super currentPlayerRotatedShape:sender];
}

- (void)currentPlayerPlacedBiteAtRow:(int)row column:(int)col sender:(id)sender
{
	if (sender == self) {
		NSMutableData *data = [[NSMutableData alloc] 
									initWithBytes:&MF_N_BITEPLACED 
										   length:sizeof(MF_N_BITEPLACED)];
		unsigned char charRow = (unsigned char) row,
					  charCol = (unsigned char) col;
		[data appendBytes:&charRow length:sizeof(unsigned char)];
		[data appendBytes:&charCol length:sizeof(unsigned char)];
		[self sendDataToServer:data];
		[data release];
	}
	
	[super currentPlayerPlacedBiteAtRow:row column:col sender:sender];
}

- (void)currentPlayerPlacedBigBiteAtRow:(int)row column:(int)col sender:(id)sender
{
	if (sender == self) {
		NSMutableData *data = [[NSMutableData alloc] 
									initWithBytes:&MF_N_BIGBITEPLACED 
										   length:sizeof(MF_N_BIGBITEPLACED)];
		unsigned char charRow = (unsigned char) row,
					  charCol = (unsigned char) col;
		[data appendBytes:&charRow length:sizeof(unsigned char)];
		[data appendBytes:&charCol length:sizeof(unsigned char)];
		[self sendDataToServer:data];
		[data release];
	}
	
	[super currentPlayerPlacedBigBiteAtRow:row column:col sender:sender];
}

- (void)currentPlayerSkippedTurn:(id)sender
{
	if (sender == self)
		[self sendDataToServer:[NSData dataWithBytes:&MF_N_SKIPTURN 
											  length:sizeof(MF_N_SKIPTURN)]];
		
	nextShape = 0;
	[super currentPlayerSkippedTurn:sender];
}

- (void)removePlayerWithColorDuringGame:(NSColor *)aColor
{
	NSLog(@"removePlayerWithColorDuringGame:%@", aColor);
	[NSThread detachNewThreadSelector:@selector(removePlayerWithColor:)
							 toTarget:gameGrid 
						   withObject:aColor];
}

- (int)nextShape
{
	return nextShape;
}

- (NSColor *)color
{
	return defaultColor;
}

- (void)inGameTableViewRightClicked:(NSNotification *)notif
{
	NSEvent *theEvent = [[notif userInfo] objectForKey:@"event"];
	int row = [[[notif userInfo] objectForKey:@"row"] intValue];
	
	id contextMenuPlayer = [players objectAtIndex:row];

	NSMenu *contextMenu = [[NSMenu alloc] initWithTitle:[contextMenuPlayer objectForKey:@"name"]];
	
	[contextMenu addItemWithTitle:([muteList containsObject:contextMenuPlayer] ?  @"Unmute" : @"Mute")
						   action:@selector(mutePlayer:)
				    keyEquivalent:@""];
	[[contextMenu itemAtIndex:0] setEnabled:(![[contextMenuPlayer objectForKey:@"name"] isEqualToString:defaultName])];
	[[contextMenu itemAtIndex:0] setTarget:self];
	[[contextMenu itemAtIndex:0] setTag:row];
	
	[NSMenu popUpContextMenu:contextMenu
				   withEvent:theEvent
				     forView:playersTableView];
	[contextMenu autorelease];
}

@end

@implementation MFClientGameController (NSNetServiceBrowserDelegation)

- (void)connectToServer
{
	int index;
	struct sockaddr *socketAddress;
	struct sockaddr_in *socketAddress_in;
    NSNetService *remoteService;
	
	if ( [browserTableView selectedRow] >= 0) // Obtain sockAddr based on selected name in list
	{ 
		remoteService = [discoveredServices objectAtIndex:[browserTableView selectedRow]];
		for (index = 0; index < [[remoteService addresses] count]; index++) 
		{
			socketAddress = (struct sockaddr *)[[[remoteService addresses] objectAtIndex:index] bytes];
			if (socketAddress->sa_family == AF_INET) 
				break; // Found the IPV4 address
		}
		
		socketAddress_in = (struct sockaddr_in *)socketAddress;
		socketAddress_in->sin_port = htons(PORT_NUMBER);
		socketAddress = (struct sockaddr *)socketAddress_in;
		
	} else { 
		
		// Obtain sockAddr with customIPTextField
		
		const char *charAddress = (const char *)[[customIPTextField stringValue] cString];
		struct hostent *hostInfo = gethostbyname2(charAddress, AF_INET);
		if (hostInfo == NULL) {
			fprintf (stderr, "could not gethostbyname for '%s'\n", charAddress);
			fprintf (stderr, " error: %d / %s\b", h_errno, hstrerror(h_errno));
			[self cancelJoin:nil];
			goto bailout;
		}
		
		// Configure socketAddress_in
		socketAddress_in = malloc(sizeof(struct sockaddr_in));
		socketAddress_in->sin_len = sizeof(struct sockaddr_in);
		socketAddress_in->sin_family = AF_INET;
		socketAddress_in->sin_addr = *((struct in_addr *) (hostInfo->h_addr));
		socketAddress_in->sin_port = htons(PORT_NUMBER);
		socketAddress = (struct sockaddr *)socketAddress_in;
	}

	//char serverAddress = ntoa(&socketAddress_in->sin_addr)
	char *charAddress = (char *)inet_ntoa( socketAddress_in->sin_addr );
	serverIP = [[NSString alloc] initWithBytes:charAddress
							            length:strlen(charAddress)
									  encoding:NSASCIIStringEncoding];
	
	int s = socket( AF_INET, SOCK_STREAM, 0 );
	int oldopts = fcntl(s, F_GETFL, 0);
	
	fcntl(s, F_SETFL, oldopts | O_NONBLOCK);
    connect( s, socketAddress, sizeof(struct sockaddr));
	fcntl(s, F_SETFL, oldopts & !O_NONBLOCK);
	
    remoteServer = [[NSFileHandle alloc] initWithFileDescriptor:s];
	
	[remoteServer readInBackgroundAndNotify];
	[[NSNotificationCenter defaultCenter] addObserver:self 
	       selector:@selector(receiveData:)
	           name:NSFileHandleReadCompletionNotification
		 object:remoteServer];
		 
bailout:
	if (!([browserTableView selectedRow] >= 0))
		free(socketAddress_in);
}

- (void)sendDisconnectionMessage
{
	NSMutableData *data = [[NSMutableData alloc] init];
	NSKeyedArchiver *keyedArchive = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
	[keyedArchive setOutputFormat:NSPropertyListBinaryFormat_v1_0];
	[keyedArchive encodeObject:@"disconnecting" forKey:@"disconnecting"];
	[keyedArchive finishEncoding];
	[remoteServer writeData:data];
	[data release];
	[keyedArchive release];
}

- (void)disconnectFromServerWithAlert:(NSString *)aString
{
	[[NSNotificationCenter defaultCenter] removeObserver:self 
													name:NSFileHandleReadCompletionNotification
												  object:remoteServer];
	[remoteServer closeFile];
	[remoteServer release];
	remoteServer = nil;
	
	if (!aString)
		return;
	
	NSAlert *alertSheet = [NSAlert alertWithMessageText:@"Disconnected from server"
										  defaultButton:@"OK"
										alternateButton:nil
											otherButton:nil
							  informativeTextWithFormat:aString];
	[lobbySheet orderOut:self];
	[alertSheet beginSheetModalForWindow:mainWindow
						   modalDelegate:self
						  didEndSelector:nil
							 contextInfo:nil];
	[self cleanUpGame];
}
@end

@implementation MFClientGameController (TableViewDataSource)

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{	
	if (aTableView == browserTableView)
		return [discoveredServices count];
	else if (aTableView == playersTableView) {
			if (players) return [players count];
			else return 0;
	}
	return 0;
}

- (id)tableView:(NSTableView *)aTableView 
	    objectValueForTableColumn:(NSTableColumn *)aTableColumn 
	    row:(int)rowIndex
{
	if (aTableView == browserTableView) {
		NSArray *stringArray;
		NSString *aString = [[discoveredServices objectAtIndex:rowIndex] name];
		stringArray = [aString componentsSeparatedByString:@":"];
		
		if ([[aTableColumn identifier] compare:@"name"] == NSOrderedSame)
			return [stringArray objectAtIndex:0];
		else
			return [stringArray objectAtIndex:1];
			
	} else if (aTableView == playersTableView) {
		NSDictionary *aPlayer = [players objectAtIndex:rowIndex];
		return [aPlayer objectForKey:[aTableColumn identifier]];
	} else return @"table unknown";
}

@end
