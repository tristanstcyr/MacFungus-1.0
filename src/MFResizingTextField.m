#import "MFResizingTextField.h"

@implementation MFResizingTextField

- (id)initWithFrame:(NSRect)frame
{
	if (self = [super initWithFrame:frame]) baseFrame = frame;
	return self;
}

- (id)initWithCoder:(NSCoder*)coder {

   if (self = [super initWithCoder:coder]) baseFrame = [self frame];
   return self;
}

- (NSRect)baseFrame { return baseFrame; }

- (void)setBaseFrame:(NSRect)frame { baseFrame = frame; }

- (void)sizeToFit
{
	NSRect frame = [self frame];
	frame.size = [self contentSize];

	[self setFrame:frame];
	
	id superview = [self superview];
	if ([superview class] == [NSSplitView class])
		[superview setNeedsDisplay:YES];
}

- (void)textDidChange:(NSNotification *)aNotification
{
	[[NSNotificationCenter defaultCenter] postNotificationName:NSControlTextDidChangeNotification 
													    object:self];
	[self sizeToFit];
}

- (void)setFrame:(NSRect)aRect
{
	if (aRect.size.height < baseFrame.size.height)
		aRect.size.height = baseFrame.size.height;
		
	[super setFrame:aRect];
}

- (BOOL)resignFirstResponder
{
	return YES;
}

- (NSSize)contentSize
{
	NSTextView *textView = (NSTextView *)[[self window] fieldEditor:YES forObject:self];
	NSSize approxSize = [[textView layoutManager] usedRectForTextContainer:[textView textContainer]].size;
	approxSize.height += 10.0f;
	return approxSize;
}

@end
