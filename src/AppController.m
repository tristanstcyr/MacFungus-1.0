#import "AppController.h"
#import "Message/NSMailDelivery.h"

@implementation AppController

- (void)awakeFromNib 
{
	prefs = [[NSUserDefaults standardUserDefaults] retain];
	
	gameSpeedPrefs = 1;
	if ([prefs objectForKey:@"gameSpeed"])
		gameSpeedPrefs = [[prefs objectForKey:@"gameSpeed"] intValue];
	hotCornersPrefs = YES;
	if ([prefs objectForKey:@"hotCorners"])
		hotCornersPrefs = [[prefs objectForKey:@"hotCorners"] boolValue];
	if ([prefs objectForKey:@"sound"])
		[soundsPrefsButton setState:([[prefs objectForKey:@"sound"] boolValue] ? NSOnState:NSOffState)];
		
	if ([prefs objectForKey:@"tracker"])
	{
		BOOL onOff = [[prefs objectForKey:@"tracker"] boolValue];
		[trackerCheckBox setState:(onOff ? NSOnState : NSOffState)];
		[self trackerPreferencesCheckBoxToggled:trackerCheckBox];
	}
	
	if ([prefs objectForKey:@"defaultName"])
			[defaultNameField setStringValue:[prefs objectForKey:@"defaultName"]];
	if ([prefs objectForKey:@"defaultColor"] )
		[defaultColorWell setColor:
			[NSUnarchiver unarchiveObjectWithData:[prefs objectForKey:@"defaultColor"]]];
	
	if ([prefs objectForKey:@"gameName"])
		[gameNameField setStringValue:[prefs objectForKey:@"gameName"]];
		
	if ([prefs objectForKey:@"gameDescription"])
		[gameDescriptionField setStringValue:[prefs objectForKey:@"gameDescription"]];
		
	[self fixNameFields];
	
	chatDrawerTextFieldHeight = [chatDrawerTextField frame].size.height;
	[chatDrawerTextField setNextResponder:gameGrid];
	[chatDrawerTextField setNextKeyView:gameGrid];
	[chatDrawerTextView setTextContainerInset:NSMakeSize(5,5)];
	
	// So the picker can only pick RGB
	[NSColorPanel setPickerMask:NSColorPanelRGBModeMask];
	
			
	[[NSNotificationCenter defaultCenter] addObserver:self
	selector:@selector(windowDidResize:)
	name:NSWindowDidResizeNotification
	object:mainWindow];
	
	[[NSAppleEventManager sharedAppleEventManager] setEventHandler:self 
													   andSelector:@selector(getUrl:withReplyEvent:) 
													 forEventClass:kInternetEventClass 
													    andEventID:kAEGetURL];
}

- (void)getUrl:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
	if (!hostGameSheetController || ![hostGameSheetController isConnectedToGame])
	{
		NSString *ip, *port;
		NSString *url = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
		NSArray *components = [url componentsSeparatedByString:@":"];
		
		if ([components count] < 3)
			return;
		
		ip = [components objectAtIndex:1];
		ip = [ip substringWithRange:NSMakeRange(2, [ip length] - 2)];
		port = [components objectAtIndex:2];
		[self scriptCommandJoinGame:ip withName:[defaultNameField stringValue]];
	} 
	else 
	{
		NSBeep();
	}
	
}

- (void)openPlayerConfigurationSheet
{
	[NSApp beginSheet:playerConfigurationSheet
	   modalForWindow:mainWindow
		modalDelegate:self
	   didEndSelector:NULL
		  contextInfo:NULL];
}

- (IBAction)closePlayerConfigurationSheet:(id)sender
{
	[defaultNameField setStringValue:[configurationNameField stringValue]];
	[defaultColorWell setColor:[configurationColorWell color]];
	
	[playerConfigurationSheet orderOut:nil];
	[NSApp endSheet:playerConfigurationSheet];
	
	if (lastController == joinGameSheetController)
		[self joinGameMenu:self];
	else
		[self hostGameMenu:self];
}

// Prevent buffer overflow
#define MAX_GAME_DESCRIPTION_LENGTH 30
#define MAX_GAME_NAME_LENGTH 30

- (void)fixNameFields
{
	NSString *defaultNameString = [defaultNameField stringValue];
	NSString *configurationNameString = [configurationNameField stringValue];
	if ([defaultNameString length] > 10)
		[defaultNameField setStringValue:[defaultNameString substringWithRange:NSMakeRange(0,9)]];
	if ([configurationNameString length] > 10)
		[defaultNameField setStringValue:[configurationNameString substringWithRange:NSMakeRange(0,9)]];
	
	if ([[gameNameField stringValue] length] > MAX_GAME_NAME_LENGTH)
		[gameNameField setStringValue:[[gameNameField stringValue] substringToIndex:MAX_GAME_NAME_LENGTH]];
	if ([[gameDescriptionField stringValue] length] > MAX_GAME_DESCRIPTION_LENGTH)
		[gameDescriptionField setStringValue:[[gameDescriptionField stringValue] substringToIndex:MAX_GAME_DESCRIPTION_LENGTH]];
	
	
	if ([[gameNameField stringValue] length] == 0)
	{
		NSString *defaultString = [NSString stringWithFormat:@"%@'s Game", [defaultNameField stringValue]];
		[[gameNameField cell] setPlaceholderString:defaultString];
	}
	
	if ([[gameDescriptionField stringValue] length] == 0)
		[[gameDescriptionField cell] setPlaceholderString:@"No Description"];
}

- (IBAction)joinGameMenu:(id)sender
{
	if (!joinGameSheetController) {
		NSDictionary *objectDict = 
			[[NSDictionary alloc] initWithObjectsAndKeys:	   self, @"appController",
														   gameGrid, @"gameGrid",
														 chatDrawer, @"chatDrawer",
												   chatDrawerButton, @"chatDrawerButton",
												 chatDrawerTextView, @"chatDrawerTextView",
												chatDrawerTextField, @"chatDrawerTextField", nil];
		
		joinGameSheetController = [[MFClientGameController alloc] 
									initWithObjectDict:objectDict];
		[objectDict release];
	}
	
	if ([[defaultNameField stringValue] isEqualToString:@"Player 1"]) {
		lastController = joinGameSheetController;
		[self openPlayerConfigurationSheet];
		return;
	}
		
	if ([hostGameSheetController isConnectedToGame]) 
	{
		[self networkGameWarningFrom:hostGameSheetController to:joinGameSheetController];
		return;
	} 
	
	if ([joinGameSheetController isConnectedToGame]) 
	{
		[self networkGameWarningFrom:joinGameSheetController to:joinGameSheetController];
		return;
	}
	
	[self fixNameFields];
	[joinGameSheetController openBrowserSheet];
}

- (IBAction)hostGameMenu:(id)sender
{
	if (!hostGameSheetController) 
	{
		
		NSDictionary *objectDict = 
			[[NSDictionary alloc] initWithObjectsAndKeys:	self, @"appController",
														gameGrid, @"gameGrid",
														chatDrawer, @"chatDrawer",
														chatDrawerButton, @"chatDrawerButton",
														chatDrawerTextView, @"chatDrawerTextView",
														chatDrawerTextField, @"chatDrawerTextField", nil];
		hostGameSheetController = [[MFHostGameController alloc]  initWithObjectDict:objectDict];
		[objectDict release];
		
		[[hostGameSheetController valueForKey:@"gameSpeedPopUp"] selectItemAtIndex:gameSpeedPrefs];
		[[hostGameSheetController valueForKey:@"hotCornersSwitch"] setState:(hotCornersPrefs?NSOnState:NSOffState)];
	}
	
	if ([[defaultNameField stringValue] isEqualToString:@"Player 1"]) 
	{
		lastController = hostGameSheetController;
		[self openPlayerConfigurationSheet];
		return;
	}
	
	if ([hostGameSheetController isConnectedToGame]) 
	{
		[self networkGameWarningFrom:hostGameSheetController to:hostGameSheetController];
		return;
	}
	
	if ([joinGameSheetController isConnectedToGame]) 
	{
		[self networkGameWarningFrom:joinGameSheetController to:hostGameSheetController];
		return;
	}
	
	[self fixNameFields];
	[hostGameSheetController openLobbySheet];
}

- (void)networkGameWarningSheetDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	[[alert window] orderOut:self];
	[NSApp endSheet:[alert window]];
	
	if (returnCode != 1)
		return;
	
	if (oldController == hostGameSheetController) 
	{
			[hostGameSheetController cancelHostGame:self];
	
	} else if (oldController == joinGameSheetController) {
		
			[joinGameSheetController sendDisconnectionMessage];
			[joinGameSheetController disconnectFromServerWithAlert:nil];
	}
		
	if (newController == hostGameSheetController)
			[self hostGameMenu:self];
	else if (newController == joinGameSheetController)
			[self joinGameMenu:self];
	else
			[self normalGameMenu:self];

}

- (IBAction)normalGameMenu:(id)sender
{
	if (!normalGameSheetController)
	{
		normalGameSheetController = [[MFNormalGameController alloc] initWithAppController:self];
		int preferedSpeed = 1;
		if ([prefs objectForKey:@"gameSpeed"])
			preferedSpeed = [[prefs objectForKey:@"gameSpeed"] intValue];
			
		[[normalGameSheetController valueForKey:@"gameSpeedPopUp"] selectItemAtIndex:gameSpeedPrefs];
		[[normalGameSheetController valueForKey:@"hotCornersSwitch"] setState:(hotCornersPrefs?NSOnState:NSOffState)];
		
		if ([prefs objectForKey:@"normalPlayers"])
		{
			NSDictionary *prefsNormalPlayer = 
				[NSUnarchiver unarchiveObjectWithData:[prefs objectForKey:@"normalPlayers"]];
			[normalGameSheetController setValue:prefsNormalPlayer forKey:@"players"];
		}
	
	}
	
	if ([hostGameSheetController isConnectedToGame]) 
	{
		[self networkGameWarningFrom:hostGameSheetController to:normalGameSheetController];
		return;
	}
	
	if ([joinGameSheetController isConnectedToGame]) 
	{
		[self networkGameWarningFrom:joinGameSheetController to:normalGameSheetController];
		return;
	}
	
	[self fixNameFields];
	[normalGameSheetController openNewGameSheet];
}

- (void)networkGameWarningFrom:(id)originalController to:(id)nextController
{
	NSString *alertMessage;
	NSString *informativeText;
	oldController = originalController;
	newController = nextController;
	
	
	if (nextController == hostGameSheetController)
		alertMessage = @"Are you sure you want to host a new game?";
	else if (nextController == joinGameSheetController)
		alertMessage = @"Are you sure you want to join a new game?";
	else
		alertMessage = @"Are you sure you want to start a new game?";

	if (originalController == hostGameSheetController)
		informativeText = @"All the players from the current game will be disconnected.";
	else
		informativeText = @"You will be disconnected from the current game.";
	
	NSAlert *alertSheet =[NSAlert alertWithMessageText:alertMessage
			defaultButton:@"OK" 
			alternateButton:@"Cancel"
			otherButton:nil
			informativeTextWithFormat:informativeText];
		
	[alertSheet beginSheetModalForWindow:mainWindow
						   modalDelegate:self
						  didEndSelector:@selector(networkGameWarningSheetDidEnd:returnCode:contextInfo:)
							 contextInfo:nil];
}


- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{	
	BOOL isASheetDown = ([mainWindow attachedSheet] ? YES : NO);
	BOOL bugSheetIsDown = ([bugCopyPasteSheet isVisible] || [bugCopyPasteSheet isVisible]);
	
	switch ([menuItem tag])
	{
		case 1: //Quit
				return YES;
		
		case 2: //Close Window
				return (!isASheetDown);
		
		case 3: //Disconnect...
				if (joinGameSheetController && [joinGameSheetController isConnectedToGame] && !bugSheetIsDown)
					return YES;
				
				if (hostGameSheetController && [hostGameSheetController isConnectedToGame] && !bugSheetIsDown)
					return YES;
				
				return NO;
		
		case 4: //Back to Lobby
				return (hostGameSheetController && 
				[hostGameSheetController isConnectedToGame] &&
				!isASheetDown &&
				![gameGrid isBusy]);
		
		case 5: // Bug Report
				return (!isASheetDown);
		
		default: //The rest: Host, Join, Normal Game...
				return (!isASheetDown);
	}
}

- (IBAction)goBackToLobbyMenu:(id)sender
{
	[hostGameSheetController backToLobby];
}

- (IBAction)disconnectMenu:(id)sender
{	
	if ([hostGameSheetController isConnectedToGame] && [mainWindow attachedSheet]) {
		[hostGameSheetController cancelHostGame:self];
		return;
	}
	
	NSAlert *alertSheet = [NSAlert alertWithMessageText:@"Are you sure you want to disconnect from the game?"
										  defaultButton:@"OK" 
									    alternateButton:@"Cancel"
									   	    otherButton:nil
							 informativeTextWithFormat:@"If you're the host, all players will be kicked."];
	
	[alertSheet beginSheetModalForWindow:mainWindow
						   modalDelegate:self
						  didEndSelector:@selector(disconnectionSheetDidEnd:returnCode:contextInfo:)
							 contextInfo:nil];
}

- (void)disconnectionSheetDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	[NSApp endSheet:[alert window]];
	if (returnCode == 1) {
		if (joinGameSheetController && [joinGameSheetController isConnectedToGame]) {
			[joinGameSheetController sendDisconnectionMessage];
			[joinGameSheetController disconnectFromServerWithAlert:nil];
			
		} else if (hostGameSheetController && [hostGameSheetController isConnectedToGame]) {
			[hostGameSheetController cancelHostGame:self];
		} 
	}
}

- (IBAction)openHelpWebPage:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://macfungus.com/faq/"]];
}

- (IBAction)openTrackerWebPage:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://macfungus.com/servers/"]];
}

- (IBAction)reportABug:(id)sender
{
	NSString *path = @"~/Library/Logs/CrashReporter/MacFungus b2.crash.log";
	path = [path stringByExpandingTildeInPath];
	crashReport = [[NSString alloc] initWithContentsOfFile:path];

	[bugNameField setStringValue:[defaultNameField stringValue]];
	
	if (!crashReport) {
		[bugIncludeReportCheckBox setEnabled:NO];
		[bugIncludeReportCheckBox setState:NSOffState];
	} else
		[bugIncludeReportCheckBox setEnabled:YES];
	
	[NSApp beginSheet:bugSheet
	   modalForWindow:mainWindow
		modalDelegate:self
	   didEndSelector:NULL
		  contextInfo:NULL];

}

- (IBAction)closeBugSheet:(id)sender
{
	[bugSheet orderOut:self];
	[NSApp endSheet:bugSheet];
}
- (IBAction)sendBugReport:(id)sender
{
	[bugSheet orderOut:self];
	[NSApp endSheet:bugSheet];
	
	if ([NSMailDelivery hasDeliveryClassBeenConfigured])
		[NSThread detachNewThreadSelector:@selector(sendBugReportInThread) toTarget:self withObject:NULL];
	else {
		[bugCopyPasteTextView setString:[self constructBugReport]];
		[NSApp beginSheet:bugCopyPasteSheet
		   modalForWindow:mainWindow 
		    modalDelegate:self 
		   didEndSelector:NULL
		      contextInfo:NULL];
	}
}

- (NSString *)constructBugReport
{
	NSMutableString *msg = [[NSMutableString alloc] initWithString:
		[NSString stringWithFormat:@"Bug report \nFrom: %@\nEmail:%@ \n%@", 
			[bugNameField stringValue], [bugEmailField stringValue], [bugProblemDescriptionField string]]];
	[msg appendString:@"\n"];
	
	if ([bugIncludeReportCheckBox state] == NSOnState) {
		NSString *path = @"~/Library/Logs/CrashReporter/MacFungus B3.crash.log";
		path = [path stringByExpandingTildeInPath];
		[msg appendString:[NSString stringWithContentsOfFile:path]];
	}
	
	return [msg autorelease];

}

- (void)sendBugReportInThread
{
	NSAutoreleasePool *autoPool = [[NSAutoreleasePool alloc] init];
	
	NSString *subject =  [NSString stringWithFormat:@"Bug Report From %@ , %@",[bugNameField stringValue], [bugEmailField stringValue]];
	NSDictionary *headers = [NSDictionary dictionaryWithObjectsAndKeys:
		@"talk2tristan@gmail.com", @"From",
		@"macfungus@gmail.com", @"To",
		subject, @"Subject",
		@"Apple Message", @"X-Mailer",
		@"multipart/alternative", @"Content-Type",
		@"1.0", @"Mime-Version",
		nil];
	
	NSAttributedString *attString = [[NSAttributedString alloc] initWithString:[self constructBugReport]];
	
	[NSMailDelivery deliverMessage:attString
						   headers:headers
						    format:NSMIMEMailFormat
						  protocol:nil];
										  
	[crashReport release];
	crashReport = NULL;
	[autoPool release];

	[NSThread release];
}

- (IBAction)closeBugCopyPasteSheet:(id)sender
{
	[bugCopyPasteSheet orderOut:self];
	[NSApp endSheet:bugCopyPasteSheet];
}

- (IBAction)trackerPreferencesCheckBoxToggled:(id)sender
{
	BOOL enabled = NO;
	NSColor *textColor = [NSColor disabledControlTextColor];
	if ([sender state] == NSOnState)
	{
		enabled = YES;
		textColor = [NSColor blackColor];
	}
	
	[gameNameLabel setTextColor:textColor];
	[gameDescriptionLabel setTextColor:textColor];
	[gameNameField setEnabled:enabled];
	[gameDescriptionField setEnabled:enabled];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	NSWindow *sheet = [mainWindow attachedSheet];
	
	if (sheet) 
	{	
		[sheet orderOut:self];
		[NSApp endSheet:sheet];
	}
	
	if ([gameGrid isBusy])
		return NSTerminateCancel;
	
	return NSTerminateNow;
}

- (void)dealloc
{		
	int preferedSpeed = 1;
	BOOL hotCornersSwitchState = YES;
	NSDictionary *normalGamePlayers = nil;
	if (hostGameSheetController)
	{
		preferedSpeed = [[hostGameSheetController valueForKey:@"gameSpeedPopUp"] indexOfSelectedItem];
		hotCornersSwitchState = ([[hostGameSheetController valueForKey:@"hotCornersSwitch"] state] == NSOnState);
		[hostGameSheetController release];
	}
	
	if (joinGameSheetController)
		[joinGameSheetController release];
		
	if (normalGameSheetController)
	{
		preferedSpeed = [[normalGameSheetController valueForKey:@"gameSpeedPopUp"] indexOfSelectedItem];
		hotCornersSwitchState = ([[normalGameSheetController valueForKey:@"hotCornersSwitch"] state] == NSOnState);
		normalGamePlayers = [[normalGameSheetController valueForKey:@"players"] retain];
		[normalGameSheetController release];
	}
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[prefs setObject:[defaultNameField stringValue] forKey:@"defaultName"];
	[prefs setObject:[NSArchiver archivedDataWithRootObject:[defaultColorWell color]] forKey:@"defaultColor"];
	[prefs setObject:[NSNumber numberWithInt:preferedSpeed] forKey:@"gameSpeed"];
	[prefs setObject:[NSNumber numberWithBool:hotCornersSwitchState] forKey:@"hotCorners"];
	[prefs setObject:[NSNumber numberWithBool:([soundsPrefsButton state] == NSOnState)] forKey:@"sound"];
	
	// Save the tracker info
	[prefs setObject:[NSNumber numberWithBool:([trackerCheckBox state] == NSOnState)] forKey:@"tracker"];
	if ([[gameNameField stringValue] length] > 0)
		[prefs setObject:[gameNameField stringValue] forKey:@"gameName"];
	if ([[gameDescriptionField stringValue] length] > 0)
		[prefs setObject:[gameDescriptionField stringValue] forKey:@"gameDescription"];
	
	if (normalGamePlayers)
	{
		[prefs setObject:[NSArchiver archivedDataWithRootObject:normalGamePlayers] forKey:@"normalPlayers"];
		[normalGamePlayers release];
	}
	
	[prefs synchronize];
    [prefs release];
	[super dealloc];
}

@end

//WindowDelegation
@implementation AppController (WindowDelegation)

- (BOOL)windowShouldZoom:(NSWindow *)sender toFrame:(NSRect)newFrame
{
	return NO;
}

- (void)windowDidResize:(NSNotification *)aNotification
{
	[chatDrawerTextField sizeToFit];
	int textLength = [[chatDrawerTextView textStorage] length];
	[chatDrawerTextView scrollRangeToVisible:NSMakeRange(textLength - 1, 1)];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	NSWindow *aWindow = [aNotification object];
	if (aWindow == mainWindow) 
	{
		[application terminate:self];
		[self dealloc];
	}
}

- (IBAction)closeWindow:(id)sender
{
	[[NSApp keyWindow] close];
}

@end
