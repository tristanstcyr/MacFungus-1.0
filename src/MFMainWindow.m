#import "MFMainWindow.h"

@implementation MFMainWindow

- (void)awakeFromNib
{
	[self makeFirstResponder:gameGrid];
}

- (void)sendEvent:(NSEvent *)theEvent
{	
	if ([theEvent type] == NSFlagsChanged)
		[gameGrid modifierKeysChanged:theEvent];
	
	if ([theEvent type] == NSRightMouseDown && [self acceptsMouseMovedEvents])
		[gameGrid mouseDown:theEvent];
	
	if (([theEvent type] == NSMouseMoved || 
	[theEvent type] == NSLeftMouseDown || 
	[theEvent type] == NSRightMouseDown ||
	[theEvent type] == NSRightMouseDragged) &&
	[theEvent window] == self &&
	[self acceptsMouseMovedEvents])
	{
		if ([theEvent type] == NSMouseMoved)
		{
			[gameGrid mouseMoved:theEvent];
			return;
		}
		else if ([theEvent type] == NSLeftMouseDown)
			[gameGrid mouseDown:theEvent];
	}
	
	if ([theEvent type] == NSKeyDown && 
	[[self firstResponder] class] == [NSTextView class] &&
	[[theEvent characters] characterAtIndex:0] == '	')
	{
		[self makeFirstResponder:gameGrid];
		return;
	}
	
	if ([theEvent type] == NSKeyDown && [[self firstResponder] class] != [NSTextView class])
	{
		[gameGrid keyDown:theEvent];
		return;
	}
	[super sendEvent:theEvent];
}

- (void)setFrame:(NSRect)newWindowFrame display:(BOOL)displayViews
{
	// Let the grid dictate how the window should be resized in case we need to
	// have bounds that which are bigger that the frame.
	// Also improves performance slightly
	
	if ([gameGrid isResizingGrid])
	{
		[super setFrame:newWindowFrame display:displayViews];
		return;
	}
	
	NSRect oldWindowFrame = [self frame];
	NSRect visibleFrame = [[self screen] visibleFrame];
	
	float widthDifference = newWindowFrame.size.width - oldWindowFrame.size.width;
	float heightDifference = newWindowFrame.size.height - oldWindowFrame.size.height;
	
	float difference = (widthDifference > heightDifference ? 
						widthDifference : heightDifference);
	
	NSRect gridFrame = [gameGrid frame], 
		   gridBounds = [gameGrid bounds];
	
	// Make sure that the frame doesn't go smaller than the bounds
	// and result in really small squares
	
	if (gridBounds.size.width > gridFrame.size.width + difference)
			difference = gridBounds.size.width - gridFrame.size.width;

	// Make sure we don't go beyond the visible area's origin
	
	if (oldWindowFrame.origin.y - difference < visibleFrame.origin.y && difference)
		difference = oldWindowFrame.origin.y - visibleFrame.origin.y;
	
	// Make sure we don't go beyond the visible area's width
	
	if (oldWindowFrame.origin.x + oldWindowFrame.size.width + difference 
	> visibleFrame.origin.x + visibleFrame.size.width  && difference)
		difference = visibleFrame.size.width + visibleFrame.origin.x - 
			(oldWindowFrame.size.width + oldWindowFrame.origin.x);
	
	// Apply the difference evenly and fix the origin so the window grows from
	// its origin
	
	newWindowFrame.size.width = oldWindowFrame.size.width + difference;
	newWindowFrame.size.height = oldWindowFrame.size.height + difference;
	newWindowFrame.origin.y =  oldWindowFrame.origin.y - difference;
	newWindowFrame.origin.x = oldWindowFrame.origin.x;

	[super setFrame:newWindowFrame display:displayViews];	
}

- (void)orderOut:(id)sender
{
	NSLog(@"orderout");
	[super orderOut:sender];
}



@end
