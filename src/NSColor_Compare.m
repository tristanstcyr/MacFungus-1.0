#import "NSColor_Compare.h"


@implementation NSColor (Compare)

+ (BOOL)color:(NSColor *)color1 isEqualToColor:(NSColor*)color2
{	
	if ([color1 redComponent] == [color2 redComponent] &&
		[color1 greenComponent] == [color2 greenComponent] &&
		[color1 blueComponent] == [color2 blueComponent])
		return YES;
	else
		return NO;
}

+ (BOOL)color:(NSColor *)color1 isEqualToColor:(NSColor*)color2 withinRange:(float)range
{
	float red, green, blue;
	
	red = [color1 redComponent] - [color2 redComponent];
	green = [color1 greenComponent] - [color2 greenComponent];
	blue = [color1 blueComponent] - [color2 blueComponent];
	
	if (red < 0) red *= -1;
	if (green < 0) green *= -1;
	if (blue < 0) blue *= -1;
	
	if ( ((red+green+blue) / 3) < range) return YES;
	else return NO;
}	

@end
