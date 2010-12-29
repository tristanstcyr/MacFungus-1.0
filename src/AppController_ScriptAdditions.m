#include <AppController_ScriptAdditions.h>

@implementation AppController (ScriptingSupport)

- (NSString *)scriptCommandHostGameWithName:(NSString *)name
{
	NSMutableString *results = @"done";
	if (name && [name length]>0)
	{
		if ([name length] > 10)
		{
			results = @"Nickname larger than 10 characters cropped";
			name = [name substringWithRange:NSMakeRange(0,10)];
		}
		NSLog(@"%@",name);
		[defaultNameField setStringValue:name];
	}
		
	if ([hostGameSheetController isConnectedToGame])
		[hostGameSheetController cancelHostGame:self];
	if ([hostGameSheetController isConnectedToGame])
	{
		[joinGameSheetController sendDisconnectionMessage];
		[joinGameSheetController disconnectFromServerWithAlert:nil];
	}
	
	if ([mainWindow attachedSheet] == [joinGameSheetController valueForKey:@"browserSheet"])
		[joinGameSheetController closeBrowserSheet:self];
	
	NSWindow *aSheet;
	if (aSheet = [mainWindow attachedSheet])
	{
		[aSheet orderOut:self];
		[NSApp endSheet:aSheet];
	}
	
	[self hostGameMenu:self];
		
	return @"Done";
}

- (NSString *)scriptCommandJoinGame:(NSString *)addressString withName:(NSString *)name
{
	NSString *results = @"Done";
	
	if (name && [name length]>0)
	{
		if ([name length] > 10)
		{
			results = @"Nickname larger than 10 characters cropped";
			name = [name substringWithRange:NSMakeRange(0,10)];
		}
		[defaultNameField setStringValue:name];
	}
	
	if ([hostGameSheetController isConnectedToGame])
		[hostGameSheetController cancelHostGame:self];
	if ([hostGameSheetController isConnectedToGame])
	{
		[joinGameSheetController sendDisconnectionMessage];
		[joinGameSheetController disconnectFromServerWithAlert:nil];
	}
	
	if ([mainWindow attachedSheet] == [joinGameSheetController valueForKey:@"browserSheet"])
		[joinGameSheetController closeBrowserSheet:self];
	
	NSWindow *aSheet;
	if (aSheet = [mainWindow attachedSheet])
	{
		[aSheet orderOut:self];
		[NSApp endSheet:aSheet];
	}
	
	[self joinGameMenu:self];
	
	id textField = [joinGameSheetController valueForKey:@"customIPTextField"];
	id joinGameButton = [joinGameSheetController valueForKey:@"joinGameButton"];
	[textField setStringValue:addressString];
	[joinGameButton setEnabled:YES];
	[joinGameButton performClick:self];

	return results;
}

@end
