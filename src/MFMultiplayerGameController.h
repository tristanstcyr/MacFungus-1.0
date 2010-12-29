#import <MFGameController.h>

#define DEFAULT_GRIDSIZE 20
#define MF_PROTOCOL @"_macfungusB402._tcp."

extern const char 
		MF_N_ACCEPTEDCONNECT, // Connection Accepted
		MF_N_GAMESTARTS, // Game starts
		MF_N_BACKTOLOBBY, // Back to lobby
		MF_N_DISCONNECT, // Disconnect or disconnected
		
		MF_N_SKIPTURN, // Skip turn
		MF_N_BITEBUTTON, // Bite button pressed
		MF_N_BITEPLACED, // Place bite
		MF_N_PLACEDSHAPE, // Place shape
		MF_N_ROTATED, // Rotate shape
		MF_N_CHATMESSAGE, // A chat message
		
		MF_N_PLAYERDESCRIPTION, //Player description
		MF_N_PLAYLIST, // Players List
		MF_N_NEWCOLOR, // New color
		MF_N_NEWSHAPE, // New Shape
		MF_N_REMOVEPLAYER, // Removes a player during a game
		MF_N_GRIDSIZE, // Game grid size
		MF_N_NEWNAME, // Remove Player
		MF_N_PLAYLISTMOVE, // Host switched around 2 players' spots
		MF_N_HOTCORNERSSWITCH,
		MF_N_GAMESPEED,
		MF_N_PLAYERKICKED,
		MF_N_BIGBITEPLACED,
		MF_VERSIONNUMBER;

@interface MFMultiplayerGameController : MFGameController 
{
	NSDrawer *chatDrawer;
	NSButton *chatDrawerButton;
	NSTextView *chatDrawerTextView;
	NSTextField *chatDrawerTextField;
	IBOutlet NSButton *mutePlayerButton;
	
	IBOutlet NSTextView *chatTextView;
	IBOutlet NSTextField *chatMessageField;
	
	BOOL playerDidChat;
	NSDate *lastMessageDate;
	
	NSMutableArray *muteList;
	NSMutableData *buffer;
	unsigned int messageSize;
}

- (id)initWithObjectDict:(NSDictionary *)objectDict;
- (void)startGame;
- (void)cleanUpGame;
- (NSDictionary *)playerWithID:(int)anID;
@end
@interface MFMultiplayerGameController(Chat)

- (NSDictionary *)chatNameAttributes;
- (NSDictionary *)chatMessageAttributes;
- (NSDictionary *)serverMessageAttributes;

- (void)postMessage:(NSString *)messageString from:(NSDictionary *)playerDict;
- (void)systemPost:(NSString *)messageString;
- (IBAction)mutePlayer:(id)sender;
- (void)drawerTextFieldTextDidChange:(NSNotification *)aNotif;
@end
