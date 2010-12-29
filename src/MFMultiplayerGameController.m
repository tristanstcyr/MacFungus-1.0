//
//  MFMultiplayerGameController.m
//  MacFungus
//
//  Created by tristan on 18/08/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "MFMultiplayerGameController.h"


const char MF_N_ACCEPTEDCONNECT = 1, // Connection Accepted
			MF_N_GAMESTARTS = 2, // Game starts
			MF_N_BACKTOLOBBY = 3, // Back to lobby
			MF_N_DISCONNECT = 4, // Disconnect or disconnected
			
			MF_N_SKIPTURN = 5, // Skip turn
			MF_N_BITEBUTTON = 6, // Bite button pressed
			MF_N_BITEPLACED = 7, // Place bite
			MF_N_PLACEDSHAPE = 8, // Place shape
			MF_N_ROTATED = 9, // Rotate shape
			MF_N_CHATMESSAGE = 10, // A chat message
			
			MF_N_PLAYERDESCRIPTION = 11, //Player description
			MF_N_PLAYLIST = 12, // Players List
			MF_N_NEWCOLOR = 13, // New color
			MF_N_NEWSHAPE = 14, // New Shape
			MF_N_REMOVEPLAYER = 15, // Remove Player
			MF_N_GRIDSIZE = 16,
			MF_N_NEWNAME = 17,
			MF_N_PLAYLISTMOVE = 18,
			MF_N_HOTCORNERSSWITCH = 19,
			MF_N_GAMESPEED = 20,
			MF_N_PLAYERKICKED = 21,
			MF_N_BIGBITEPLACED = 22,
			MF_VERSIONNUMBER = 5; // A new game grid size

@implementation MFMultiplayerGameController

- (id)initWithObjectDict:(NSDictionary *)objectDict
{
	if(self = [super init]) 
	{
		appController = [objectDict objectForKey:@"appController"];
		gameGrid = [objectDict objectForKey:@"gameGrid"];
		mainWindow = [gameGrid window];
		chatDrawer = [objectDict objectForKey:@"chatDrawer"];
		chatDrawerButton = [objectDict objectForKey:@"chatDrawerButton"];
		chatDrawerTextView = [objectDict objectForKey:@"chatDrawerTextView"];
		chatDrawerTextField = [objectDict objectForKey:@"chatDrawerTextField"];
		
		muteList = [NSMutableArray new];
	}
	
	return self;
}

- (void)startGame
{
	// If the user has text in the text field politely carry it to the chat drawer
	if ([[chatMessageField stringValue] length] > 0)
	{	
		if ([lobbySheet firstResponder] == chatMessageField)
			[mainWindow makeFirstResponder:chatDrawerTextField];
			
		[chatDrawerTextField setStringValue:[chatMessageField stringValue]];
	}
	
	
	// Open the chat drawer and dump the chat text in there
	[chatDrawerTextView setString:@""];
	[[chatDrawerTextView textStorage] appendAttributedString:[chatTextView textStorage]];
	int textLength = [[chatDrawerTextView textStorage] length];
	[chatDrawerTextView scrollRangeToVisible:NSMakeRange(textLength - 1, 1)];
	
	[super startGame];
	
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	// For the context menu with mute/kick
	[nc addObserver:self 
		   selector:@selector(inGameTableViewRightClicked:)
			   name:@"MFPlayersTableViewRightClicked"
			 object:nil];	
	
	// So space alone in chat drawer text view rotates shape
	[nc addObserver:self
		   selector:@selector(drawerTextFieldTextDidChange:)
			   name:NSControlTextDidChangeNotification
			 object:chatDrawerTextField];
	
	// Only open the drawer if someone has already chatted
	if (playerDidChat)
	{
		[chatDrawer openOnEdge:NSMaxXEdge];
		[chatDrawerButton setState:NSOnState];
	}
	
	[chatDrawerButton setEnabled:YES];
	[self systemPost:@"Game started"];
}

- (void)cleanUpGame
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self
				  name:@"MFPlayersTableViewRightClicked"
				object:playersTableView];
	[nc removeObserver:self
				  name:NSControlTextDidChangeNotification
				object:chatDrawerTextField];
	
	[[NSColorPanel sharedColorPanel] close];
	
	[muteList release];
	muteList = nil;
	
	[chatDrawer close];
	[chatDrawerButton setState:NSOffState];
	[chatDrawerButton setEnabled:NO];
	
	[chatDrawerTextView setString:@""];
	[chatTextView setString:@""];
	[super cleanUpGame];
}

- (NSDictionary *)playerWithID:(int)anID
{
	int i;
	for (i = 0; i < [players count]; i++)
	{
		NSDictionary *playerDict = [players objectAtIndex:i];
		int anotherID = [[playerDict objectForKey:@"id"] intValue];
		if (anID == anotherID)
			return playerDict;
	}
	NSLog(@"Didn't find player for ID %i", anID);
	return 0;
}

/*
- (void)currentPlayerPlacedShapeAtRow:(int)row column:(int)col sender:(id)sender
{
	int currentPlayer = [[gameGrid valueForKey:@"currentPlayer"] intValue];
	NSString *playerName = [[players objectAtIndex:currentPlayer] objectForKey:@"name"];
	NSString *messageString = [NSString stringWithFormat:@"%@ finished his turn", playerName];
	[self systemPost:messageString];
	
	[super currentPlayerPlacedShapeAtRow:row column:col sender:sender];
}
*/

@end
@implementation MFMultiplayerGameController (Chat)
- (NSDictionary *)chatNameAttributes
{
	NSFont *font = [NSFont fontWithName:@"Lucida Grande" size:10.0];
	font = [[NSFontManager sharedFontManager] convertFont:font toHaveTrait:NSBoldFontMask];
       
	NSMutableParagraphStyle *pStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopyWithZone:NULL] autorelease];
	[pStyle setLineBreakMode:NSLineBreakByWordWrapping];
	[pStyle setLineSpacing:1.8];
	[pStyle setParagraphSpacing:1.0];
	[pStyle setParagraphSpacingBefore:1.0];										
	
	return [NSDictionary dictionaryWithObjectsAndKeys: font, NSFontAttributeName, 
													    pStyle , NSParagraphStyleAttributeName, NULL];
}

- (NSDictionary *)chatMessageAttributes
{
	NSFont *font = [NSFont fontWithName:@"Lucida Grande" size:10.0];
	NSColor *color = [NSColor blackColor];
	
	NSMutableParagraphStyle *pStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopyWithZone:NULL] autorelease];
	[pStyle setLineBreakMode:NSLineBreakByWordWrapping];
	[pStyle setLineSpacing:1.8];
	[pStyle setParagraphSpacing:1.0];
	[pStyle setParagraphSpacingBefore:1.0];
	
	return [NSDictionary dictionaryWithObjectsAndKeys: font, NSFontAttributeName, 
													   color, NSForegroundColorAttributeName, 
													    pStyle , NSParagraphStyleAttributeName, NULL];
}

- (NSDictionary *)serverMessageAttributes
{
	NSFont *font = [NSFont fontWithName:@"Lucida Grande" size:10.0];
	font = [[NSFontManager sharedFontManager] convertFont:font toHaveTrait:NSItalicFontMask];
	NSColor *color = [NSColor grayColor];
	
	NSMutableParagraphStyle *pStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopyWithZone:NULL] autorelease];
	[pStyle setLineBreakMode:NSLineBreakByWordWrapping];
	[pStyle setLineSpacing:1];
	[pStyle setParagraphSpacing:1.0];
	[pStyle setParagraphSpacingBefore:1.0];
	return [NSDictionary dictionaryWithObjectsAndKeys: font, NSFontAttributeName, 
													   color, NSForegroundColorAttributeName, 
													    pStyle , NSParagraphStyleAttributeName, NULL];
}

- (void)postMessage:(NSString *)messageString from:(NSDictionary *)playerDict
{
	int i;
	int playerID = [[playerDict objectForKey:@"id"] intValue];
	
	for (i = 0; i < [muteList count]; i++)
		if ([[[muteList objectAtIndex:i] objectForKey:@"id"] intValue] == playerID)
			return;
	
	NSString *playerName = [playerDict objectForKey:@"name"];
	
	NSAttributedString *nameString = [NSAttributedString alloc];
	[nameString initWithString:[NSString stringWithFormat:@"%@: ", playerName]
					attributes:[self chatNameAttributes]];
	NSMutableAttributedString *postString = [NSAttributedString alloc];
	[postString initWithString:[NSString stringWithFormat:@"%@\n",messageString] 
					attributes:[self chatMessageAttributes]];
	
	if ([lobbySheet isVisible])
	{
		[[chatTextView textStorage] appendAttributedString:nameString];
		[[chatTextView textStorage] appendAttributedString:postString];
		int textLength = [[chatTextView textStorage] length];
		[chatTextView scrollRangeToVisible:NSMakeRange(textLength - 1, 1)];
	
	} else {
	
		[[chatDrawerTextView textStorage] appendAttributedString:nameString];
		[[chatDrawerTextView textStorage] appendAttributedString:postString];
		int textLength = [[chatDrawerTextView textStorage] length];
		[chatDrawerTextView scrollRangeToVisible:NSMakeRange(textLength - 1, 1)];
		
		if (!playerDidChat && [chatDrawerButton state] == NSOffState)
			[chatDrawerButton performClick:self];
	}
	
	playerDidChat = YES;
	[postString release];
	[nameString release];
}

- (void)systemPost:(NSString *)messageString
{
	NSDate *now = [NSDate date];
	NSMutableString *finalString = [[NSMutableString alloc] init];
	NSAttributedString *systemString = [NSAttributedString alloc];
	
	NSString *dateString = [[[now description] componentsSeparatedByString:@" "] objectAtIndex:1];
	
	[finalString appendFormat:@"(%@) %@\n", dateString, messageString];
	
	[systemString initWithString:finalString attributes:[self serverMessageAttributes]];
	
	if ([lobbySheet isVisible])
	{
		[[chatTextView textStorage] appendAttributedString:systemString];
		int textLength = [[chatTextView textStorage] length];
		[chatTextView scrollRangeToVisible:NSMakeRange(textLength - 1, 1)];
	}
	else
	{
		[[chatDrawerTextView textStorage] appendAttributedString:systemString];
		int textLength = [[chatDrawerTextView textStorage] length];
		[chatDrawerTextView scrollRangeToVisible:NSMakeRange(textLength - 1, 1)];
	}
		
	[finalString release];
}

- (IBAction)mutePlayer:(id)sender
{
	if ([lobbySheet isVisible])
	{
		NSDictionary *aPlayer = [players objectAtIndex:[playersTableView selectedRow]];
		if ([muteList containsObject:aPlayer])
		{
			[muteList removeObject:aPlayer];
			[mutePlayerButton setTitle:@"Mute"];
		} else {
			[muteList addObject:aPlayer];
			[mutePlayerButton setTitle:@"Unmute"];
		}
	} else {
		NSDictionary *aPlayer = [players objectAtIndex:[sender tag]];
		if ([muteList containsObject:aPlayer])
		{
			[muteList removeObject:aPlayer];
			[mutePlayerButton setTitle:@"Mute"];
		} else {
			[muteList addObject:aPlayer];
			[mutePlayerButton setTitle:@"Unmute"];
		}
	}
}

- (void)drawerTextFieldTextDidChange:(NSNotification *)aNotif
{
	// If the textfield is empty and the player pressed space
	// rotate the shape
	
	if ([[chatDrawerTextField stringValue] isEqualToString:@" "])
	{
		[chatDrawerTextField setStringValue:@""];
		
		if ([gameGrid canInput])
			[self currentPlayerRotatedShape:self];
	}

}

@end
