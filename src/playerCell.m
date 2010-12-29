#import "PlayerCell.h"

@implementation PlayerCell

- (id)init
{
	if([super init])
	{
		blocks = 0;
		bites = 0;
		bitesMinus = 0;
		playerColor = [NSColor redColor];
		highlightedTextColor = [NSColor whiteColor];
	}
	return self;
}

- (id) nameAttributes
{
    NSColor *fontColor;
	id attributes;
	
	if ([self isHighlighted])
		fontColor = highlightedTextColor;
	else
		fontColor = normalTextColor;

	attributes = [[NSDictionary alloc] initWithObjectsAndKeys: 
							[NSFont boldSystemFontOfSize: 12], NSFontAttributeName, 
													fontColor, NSForegroundColorAttributeName,
										 [NSColor blackColor], NSStrokeColorAttributeName, nil];
	return attributes;
}

- (id) statsAttributes
{
    NSColor *fontColor;
	id attributes;
	
	if ([self isHighlighted])
		fontColor = highlightedTextColor;
	else
		fontColor = normalTextColor;
	
	attributes = [[NSDictionary alloc] initWithObjectsAndKeys: 
		[NSFont systemFontOfSize: 10], NSFontAttributeName, 
							fontColor, NSForegroundColorAttributeName, nil];
	
    return attributes;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	
	if ([self isHighlighted])
	{
		NSImage *gradient = [NSImage imageNamed:@"gradient"];
		[gradient setFlipped:YES];
	
		NSRect drawingRect = cellFrame;
		drawingRect.size.height -= 1;
		
		NSSize gradientSize = [gradient size];
		
		[playerColor set];
		[NSBezierPath fillRect:drawingRect];
		
		NSRect imageRect;
		imageRect.origin = NSZeroPoint;
		imageRect.size = gradientSize;
		
		if(drawingRect.size.width != 0 && drawingRect.size.height != 0)
		{
			[gradient drawInRect:drawingRect
						fromRect:imageRect
					   operation:NSCompositeSourceOver
						fraction:0.2f];
						
		}
		if (highlightedTextColor != [NSColor whiteColor])
			[highlightedTextColor set];
	}
	NSPoint stringOrigin;
	NSSize stringSize;
	NSString *playerName, *blocksString, *bitesString;
	
	// Draw the strings
	playerName = name;
	blocksString = [NSString stringWithFormat:@"Squares: %i", blocks];
	if (bitesMinus != 0)
		bitesString = [NSString stringWithFormat:@"Bites: %i -%i", bites, bitesMinus];
	else
		bitesString = [NSString stringWithFormat:@"Bites: %i", bites];
	
	stringSize = [playerName sizeWithAttributes:[self nameAttributes]];
	stringOrigin.x = cellFrame.origin.x + 5;
	stringOrigin.y = cellFrame.origin.y + 1;
	[playerName drawAtPoint:stringOrigin withAttributes:[self nameAttributes]];
	
	stringSize = [blocksString sizeWithAttributes:[self statsAttributes]];
	stringOrigin.y += 18;
	[blocksString drawAtPoint:stringOrigin withAttributes:[self statsAttributes]];
	
	stringSize = [bitesString sizeWithAttributes:[self statsAttributes]];
	stringOrigin.y += 15;
	[bitesString drawAtPoint:stringOrigin withAttributes:[self statsAttributes]];
}

#define MAX_BRIGHTNESS 150
#define COLOR_UNIT_MAX 255

- (void)setObjectValue:(id)object
{
	NSDictionary *dictionary = object;
	name = [[NSString alloc] initWithString:[dictionary objectForKey:@"name"]];
	blocks = [[dictionary objectForKey:@"cells"] count];
	bites = [[dictionary objectForKey:@"bites"] intValue];
	playerColor = [dictionary objectForKey:@"color"];
	bitesMinus = [[dictionary objectForKey:@"bitesMinus"] intValue];
	
	float red = [playerColor redComponent] * COLOR_UNIT_MAX,
	green = [playerColor greenComponent] * COLOR_UNIT_MAX,
	blue = [playerColor blueComponent] * COLOR_UNIT_MAX;
	
	int brightness = (red +green*6 + blue*2)/9;
	
	if (brightness > MAX_BRIGHTNESS)
	{
		float colorRemoved = (brightness - MAX_BRIGHTNESS)*2;
		green -= colorRemoved;
		blue -= colorRemoved;
		red -= colorRemoved;
		highlightedTextColor = [NSColor colorWithDeviceRed:red/COLOR_UNIT_MAX
													 green:green/COLOR_UNIT_MAX
													  blue:blue/COLOR_UNIT_MAX
													 alpha:1.0f];
		normalTextColor = highlightedTextColor;
		
	} else {
		highlightedTextColor = [NSColor whiteColor];
		normalTextColor = playerColor;
	}
}

- (void)setState:(int)state
{
	NSLog(@"%i",state);
}

- (NSColor *)playerColor
{
	return playerColor;
}


- (void)dealloc
{
	[super dealloc];
	[name release];
}
@end
