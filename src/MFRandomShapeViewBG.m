//
//  MFRandomShapeViewBG.m
//  MacFungus
//
//  Created by tristan on 10/08/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "MFRandomShapeViewBG.h"


@implementation MFRandomShapeViewBG

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)rect {

    [[NSGraphicsContext currentContext] setShouldAntialias:NO];
	[[NSColor whiteColor] set];
	NSRectFill(rect);
	
	[super drawRect:rect];
}

- (BOOL)acceptsFirstResponder
{
	return NO;
}

@end
