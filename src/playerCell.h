/* PlayerCell */

#import <Cocoa/Cocoa.h>

@interface PlayerCell : NSCell
{
	int blocks, bites, bitesMinus;
	NSString *name;
	NSColor *playerColor, *highlightedTextColor, *normalTextColor;

}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- (id) nameAttributes;
- (void)setObjectValue:(id)object;
- (NSColor *)playerColor;
@end
