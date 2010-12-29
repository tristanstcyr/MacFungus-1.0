#import <Cocoa/Cocoa.h>
#import <MFHostGameController.h>

@interface ClientPlayer : NSObject 
{
	NSFileHandle *fileHandle;
	id server;
	NSMutableDictionary *playerDict;
}

- (id)initWithFileHandle:(NSFileHandle *)aFileHandle hostServer:(id)aServer;
- (void)sendData:(NSData *)data;
- (void)receiveMessage:(NSNotification *)notification;

@end