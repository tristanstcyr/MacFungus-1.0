//
//  MFLobbyNameCell.m
//  MacFungus
//
//  Created by tristan on 14/07/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "MFLobbyNameCell.h"


@implementation MFLobbyNameCell

- (id) nameAttributes
{
	id attributes;
	NSColor *textColor;
	if ([self isHighlighted] && 
	[[[self controlView] window] firstResponder]  == [self controlView] &&
	[[[self controlView] window] isKeyWindow])
		textColor = [NSColor whiteColor];
	else
		textColor = [NSColor blackColor];	
			
	attributes = [[NSDictionary alloc] initWithObjectsAndKeys: [NSFont systemFontOfSize: 13], NSFontAttributeName, 
															   textColor, NSForegroundColorAttributeName, nil];
	return attributes;
}


- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSPoint stringOrigin;
	NSString *name = [self stringValue];
	NSSize stringSize = [name sizeWithAttributes:[self nameAttributes]];
	stringOrigin.y = (cellFrame.size.height - stringSize.height)/2 + cellFrame.origin.y;
	stringOrigin.x = cellFrame.origin.x + 3;
	
	[name drawAtPoint:stringOrigin withAttributes:[self nameAttributes]];
}

@end
