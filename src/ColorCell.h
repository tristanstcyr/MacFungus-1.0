/* ColorCell */

#import <Cocoa/Cocoa.h>

@interface ColorCell : NSActionCell
{
	BOOL isSelected;
	NSColor *color;
}

- (void)setIsSelected:(BOOL)aBool;

@end
