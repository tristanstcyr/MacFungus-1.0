//
//  HostGameScriptCommand.m
//  MacFungus
//
//  Created by tristan on 15/08/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "HostGameScriptCommand.h"
#import <AppController_ScriptAdditions.h>

@implementation HostGameScriptCommand

-(id) performDefaultImplementation
{
	AppController *controller = [[NSApplication sharedApplication] delegate];
	NSString *nickname = [[self evaluatedArguments] objectForKey:@"nickname"];
	NSLog(@"%@", nickname);
	return [controller scriptCommandHostGameWithName:nickname];
}

@end
