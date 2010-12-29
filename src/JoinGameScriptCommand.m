//
//  JoinGameScriptCommand.m
//  MacFungus
//
//  Created by tristan on 15/08/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "JoinGameScriptCommand.h"
#import <AppController_ScriptAdditions.h>

@implementation JoinGameScriptCommand

-(id) performDefaultImplementation
{
	
	AppController *controller = [[NSApplication sharedApplication] delegate];
	
	NSString *address = [[self evaluatedArguments] objectForKey:@""];
	NSString *nickname = [[self evaluatedArguments] objectForKey:@"nickname"];
	NSLog(@"%@", address);
	
	if (address == NULL || [address length] == 0)
		return @"Must supply an address after the join game command";
	return [controller scriptCommandJoinGame:address withName:nickname];
}

@end
