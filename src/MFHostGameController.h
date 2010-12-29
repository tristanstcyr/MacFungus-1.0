#import <ClientPlayer.h>
#import <MFMultiplayerGameController.h>
#import <Foundation/Foundation.h>
#define PORT_NUMBER 47888

@interface MFHostGameController : MFMultiplayerGameController {

	IBOutlet NSButton *startGameButton;
	
	NSNetService *service;
	NSFileHandle *listeningSocket;
	NSMutableDictionary *playerDict;
	
	IBOutlet NSButton *kickPlayerButton;
	NSNib  *hostGameSheetNib;
	
	// Game Tracker
	NSTimer *trackerTimer;
}

- (id)initWithObjectDict:(NSDictionary *)objectDict;
- (void)dealloc;

- (void)addPlayer:(id)newPlayer;
- (void)removePlayer:(id)aPlayer wasKicked:(BOOL)wasKicked;
- (IBAction)kickPlayer:(id)sender;
- (NSData *)playersData;

@end
@interface MFHostGameController (LobbySheet)
- (void)openLobbySheet;

- (void)newPlayerConnected:(NSNotification *)notification;

- (IBAction)returnChatMessage:(id)sender;
- (void)broadcastChatMessage:(NSString *)messageString from:(id)player;
- (IBAction)gridSizeChanged:(id)sender;
- (IBAction)hotCornerSwitch:(id)sender;
- (IBAction)gameSpeedChanged:(id)sender;


- (IBAction)startHostGame:(id)sender;
- (IBAction)cancelHostGame:(id)sender;
- (void)backToLobby;
@end

@interface MFHostGameController (GameGridControl)
- (void)sendDataToPlayers:(NSData *)data withException:(id)exception;
- (void)currentPlayerPlacedShapeAtRow:(int)row column:(int)col sender:(id)sender;
- (void)currentPlayerPressedBiteButton:(id)sender;
- (void)currentPlayerRotatedShape:(id)sender;
- (void)currentPlayerPlacedBiteAtRow:(int)row column:(int)col sender:(id)sender;
- (void)currentPlayerPlacedBigBiteAtRow:(int)row column:(int)col sender:(id)sender;
- (void)currentPlayerSkippedTurn:(id)sender;

- (int)nextShape;

- (void)noMorePlayersSheetDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)disconnectedPlayersSheetDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo;
@end

@interface MFHostGameController (NSNetServiceDelegation)
// Publication Specific
- (void)setupService;
- (void)updateService;
- (void)stopService;
- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict;
- (void)netServiceWillPublish:(NSNetService *)sender;
- (void)netServiceDidStop:(NSNetService *)sender;

// Resolution Specific
- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict;
- (void)netServiceDidResolveAddress:(NSNetService *)sender;
- (void)netServiceWillResolve:(NSNetService *)sender;

@end

@interface MFHostGameController (ColorChange)
- (BOOL)colorChanged:(id)sender;
@end

@interface MFHostGameController (GameTracker)
- (void)startTrackerTimer;
- (void)stopTrackerTimer;
- (void)updateTracker;
@end

@interface NSString (ReplaceAndEncode)
- (NSString *)replaceMatchingCharacters:(char)character withString:(NSString*)replacement;
- (NSString*)encryptStringWithPassword:(NSString*)password;
@end