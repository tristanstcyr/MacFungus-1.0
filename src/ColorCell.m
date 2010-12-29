#import "ColorCell.h"

@implementation ColorCell

- (void)awakeFromNib
{
	isSelected = NO;
	color = [[NSColor whiteColor] retain];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	[[NSGraphicsContext currentContext] setShouldAntialias:NO];
	
	[color set];
	NSRect smallerRect = cellFrame;
	
	
	smallerRect.size.width = smallerRect.size.height -= 5;
	smallerRect.origin.y += 2;
	smallerRect.origin.x = cellFrame.origin.x + cellFrame.size.width/2 - smallerRect.size.width/2;
	
	NSGraphicsContext *gContext;
	gContext = [NSGraphicsContext currentContext];
	[gContext setShouldAntialias:YES];
	NSBezierPath *circle = [NSBezierPath bezierPathWithOvalInRect:smallerRect];
	[circle fill];
	if ([self isHighlighted]) 
	{
		[circle setLineWidth:1.0f];
		[[NSColor whiteColor] set];
		[circle stroke];
	}
	
	[[NSGraphicsContext currentContext] setShouldAntialias:YES];
}

- (void)setObjectValue:(id)object
{
	if (!object) {
		return;
	}

	color = object;
}

- (BOOL)acceptsFirstResponder
{
	if ([self isEditable])
		return YES;
	else
		return NO;
}

- (void)setIsSelected:(BOOL)aBool
{
	isSelected = aBool;

}
@end
