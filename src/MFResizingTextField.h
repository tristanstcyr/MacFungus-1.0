//
//  MFResizingTextField.h
//  MacFungus
//
//  Created by tristan on 08/08/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MFResizingTextField: NSTextField
{
	NSRect baseFrame;
}
- (NSRect)baseFrame;
- (void)setBaseFrame:(NSRect)frame;

- (NSSize)contentSize;
@end

