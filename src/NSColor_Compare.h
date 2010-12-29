#import <Cocoa/Cocoa.h>

@interface NSColor (Compare)

+ (BOOL)color:(NSColor *)color1 isEqualToColor:(NSColor*)color2;
+ (BOOL)color:(NSColor *)color1 isEqualToColor:(NSColor*)color2 withinRange:(float)range;
@end
