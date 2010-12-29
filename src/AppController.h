//
//  AppController.h
//  MacFungus
//
//  Created by tristan on 18/06/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <MFClientGameController.h>
#import <MFHostGameController.h>
#import <MFNormalGameController.h>
#import <MFMainWindow.h>

@interface AppController : NSObject
{
	id lastController;
	id oldController;
	id newController;
	
	IBOutlet NSApplication *application;
	IBOutlet MFMainWindow *mainWindow;
	IBOutlet GameGrid *gameGrid;
	
	IBOutlet NSDrawer *chatDrawer;
	IBOutlet NSTextView *chatDrawerTextView;
	float chatDrawerTextFieldHeight;
	IBOutlet NSTextField *chatDrawerTextField;
	IBOutlet NSButton *chatDrawerButton;
	IBOutlet NSSplitView *chatDrawerSplitView;
	
	// Player Configurations (to be removed)
	IBOutlet NSWindow *playerConfigurationSheet;
	IBOutlet NSColorWell *configurationColorWell;
	IBOutlet NSTextField *configurationNameField;
	
	//Preferences/Play Configurations
	IBOutlet NSWindow *preferencesWindow;
	IBOutlet NSTextField *defaultNameField;
	IBOutlet NSColorWell *defaultColorWell;
	IBOutlet NSButton *soundsPrefsButton;
	
	IBOutlet NSButton *trackerCheckBox;
	IBOutlet NSTextField *gameNameLabel;
	IBOutlet NSTextField *gameNameField;
	IBOutlet NSTextField *gameDescriptionLabel;
	IBOutlet NSTextField *gameDescriptionField;
	
	//Bug Report
	IBOutlet NSTextField *bugNameField;
	IBOutlet NSTextField *bugEmailField;
	IBOutlet NSTextView *bugProblemDescriptionField;
	IBOutlet NSButton *bugIncludeReportCheckBox;
	IBOutlet NSWindow *bugSheet;
	NSString *crashReport;
	
	IBOutlet NSTextView *bugCopyPasteTextView;
	IBOutlet NSWindow *bugCopyPasteSheet;
	
	// Preferences file
	NSUserDefaults *prefs;
	int gameSpeedPrefs;
	BOOL hotCornersPrefs;
	
	
	// Game Controllers
	MFClientGameController *joinGameSheetController;
	MFHostGameController *hostGameSheetController;
	MFNormalGameController *normalGameSheetController;
}

- (IBAction)closePlayerConfigurationSheet:(id)sender;

- (IBAction)joinGameMenu:(id)sender;
- (IBAction)hostGameMenu:(id)sender;
- (IBAction)normalGameMenu:(id)sender;
- (IBAction)goBackToLobbyMenu:(id)sender;
- (IBAction)disconnectMenu:(id)sender;

- (IBAction)openHelpWebPage:(id)sender;
- (IBAction)openTrackerWebPage:(id)sender;

- (IBAction)reportABug:(id)sender;
- (IBAction)closeBugSheet:(id)sender;
- (IBAction)sendBugReport:(id)sender;

- (void)sendBugReportInThread;
- (NSString *)constructBugReport;
- (IBAction)closeBugCopyPasteSheet:(id)sender;

- (IBAction)trackerPreferencesCheckBoxToggled:(id)sender;

- (void)openPlayerConfigurationSheet;
- (void)networkGameWarningFrom:(id)originalController to:(id)nextController;
- (void)fixNameFields;

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem;
@end

@interface AppController (WindowDelegation)
- (void)windowWillClose:(NSNotification *)aNotification;
- (IBAction)closeWindow:(id)sender;
@end