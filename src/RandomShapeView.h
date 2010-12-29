#import <Cocoa/Cocoa.h>

@interface RandomShapeView : NSMatrix 
{
} 

- (NSBezierPath *)calculateGridPath;
- (void)drawShape:(NSArray *)cellArray withColor:(NSColor *)aColor;
- (void)clear;

@end
