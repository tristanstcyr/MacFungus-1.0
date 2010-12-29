#import <MFMultiplayerGameController.h>

@interface MFClientGameController : MFMultiplayerGameController {

	BOOL timerShouldStop;

	NSNib *joinGameNib;
	
	// Browser sheet
	//////////////////////////
	NSRect browserSheetDefaultFrame;
	IBOutlet NSWindow *browserSheet;
	IBOutlet NSTextField *customIPTextField;
	IBOutlet NSTableView *browserTableView;
	IBOutlet NSButton *joinGameButton;
	IBOutlet NSButton *cancelBrowserButton;
	IBOutlet NSProgressIndicator *connectingProgressIndicator;
	IBOutlet NSTextField *connectingStatusField;
	
	// Networking
	//////////////////////////
	NSString *serverIP;
	NSNetService *service;
    NSNetServiceBrowser *serviceBrowser;
    NSNetServiceBrowser *domainBrowser;
    NSMutableArray *discoveredServices;
	NSFileHandle *remoteServer;
}

- (id)initWithObjectDict:(NSDictionary *)objectDict;
- (void)dealloc;
@end

@interface MFClientGameController (BrowserSheet)
- (void)openBrowserSheet;
- (IBAction)closeBrowserSheet:(id)sender;
- (IBAction)joinGame:(id)sender;
- (IBAction)cancelJoin:(id)sender;
- (void)controlTextDidChange:(NSNotification *)aNotification;
- (void)textFieldDidAcceptFirstResponder:(NSNotification *)aNotification;
- (void)browserBecameFirstResponder:(NSNotification *)aNotification;
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;
@end

@interface MFClientGameController (LobbySheet)
- (void)openLobbySheet;
- (IBAction)backToBrowserSheet:(id)sender;
- (IBAction)cancelGame:(id)sender;
- (void)movePlayerAtRow:(int)dragRow toRow:(int)dropRow;
@end

@interface MFClientGameController (Chat)
- (IBAction)mutePlayer:(id)sender;
- (IBAction)returnChatMessage:(id)sender;
@end

@interface MFClientGameController (InGame)
- (void)currentPlayerPlacedShapeAtRow:(int)row column:(int)col sender:(id)sender;
- (void)currentPlayerPressedBiteButton:(id)sender;
- (void)currentPlayerRotatedShape:(id)sender;
- (void)currentPlayerPlacedBiteAtRow:(int)row column:(int)col sender:(id)sender;
- (void)currentPlayerSkippedTurn:(id)sender;
- (void)removePlayerWithColorDuringGame:(NSColor *)color;
- (int)nextShape;

@end

@interface MFClientGameController (NetworkCode)
- (void)sendDataToServer:(NSData *)data;
- (void)setupBrowser;

- (void)connectToServer;
- (void)disconnectFromServerWithAlert:(NSString *)aString;
- (void)sendDisconnectionMessage;
@end

@interface MFClientGameController (TableViewDataSource)

- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView 
	    objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
@end
