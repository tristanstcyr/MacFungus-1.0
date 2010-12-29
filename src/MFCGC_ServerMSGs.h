//
//  MFCGC_ServerMSGs.h
//  MacFungus
//
//  Created by tristan on 19/08/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <MFClientGameController.h>

@interface MFClientGameController (BufferReading)
- (void)receiveData:(NSNotification *)notification;
- (void)processData:(NSData *)messageData;
- (NSMutableArray *)playersListFromData:(NSData *)data;
@end
@interface MFClientGameController (DataExecution)

- (void)connectionAccepted:(NSData *)data;

- (void)receivedPlaylist:(NSData *)data;
- (void)receivedPlaylistMove:(NSData *)messageData;
- (void)receivedPlayerRemoval:(NSData *)messageData;

- (void)receivedNewName:(NSData *)messageData;
- (void)receivedNewColor:(NSData *)messageData;

- (void)receivedPlacedShape:(NSData *)messageData;
- (void)receivedBite:(NSData *)messageData;
- (void)receivedBigBite:(NSData *)messageData;
- (void)receivedNewShape:(NSData *)messageData;

- (void)receivedBackToLobby:(NSData *)messageData;
- (void)receivedChatMessage:(NSData *)messageData;

- (void)receivedHotCornersState:(NSData *)messageData;
- (void)receivedGridSize:(NSData *)messageData;
- (void)receivedGameSpeed:(NSData *)messageData;

@end