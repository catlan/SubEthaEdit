//
//  SEEAvatarImageView.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 10.04.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

#import "SEEAvatarImageView.h"

@interface SEEAvatarImageView ()
@property (nonatomic, strong) NSTrackingArea *hoverTrackingArea;
@property (nonatomic) BOOL isHovering;
@end

@implementation SEEAvatarImageView

static void * const SEEAvatarRedarwObservationContext = (void *)&SEEAvatarRedarwObservationContext;

+ (void)initialize
{
	if (self == [SEEAvatarImageView class]) {
		[self exposeBinding:@"borderColor"];
		[self exposeBinding:@"backgroundColor"];
		[self exposeBinding:@"image"];
		[self exposeBinding:@"initials"];
	}
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.borderColor = [NSColor redColor];
		self.backgroundColor = [[NSColor redColor] colorWithAlphaComponent:0.4];
		self.initials = @"M E";
		
		[self registerKVO];
    }
    return self;
}

- (void)dealloc
{
    [self unregisterKVO];
}


#pragma mark - KVO

- (void)registerKVO
{
	[self addObserver:self forKeyPath:@"borderColor" options:0 context:SEEAvatarRedarwObservationContext];
	[self addObserver:self forKeyPath:@"backgroundColor" options:0 context:SEEAvatarRedarwObservationContext];
	[self addObserver:self forKeyPath:@"image" options:0 context:SEEAvatarRedarwObservationContext];
	[self addObserver:self forKeyPath:@"initials" options:0 context:SEEAvatarRedarwObservationContext];
}

- (void)unregisterKVO
{
	[self removeObserver:self forKeyPath:@"borderColor" context:SEEAvatarRedarwObservationContext];
	[self removeObserver:self forKeyPath:@"backgroundColor" context:SEEAvatarRedarwObservationContext];
	[self removeObserver:self forKeyPath:@"image" context:SEEAvatarRedarwObservationContext];
	[self removeObserver:self forKeyPath:@"initials" context:SEEAvatarRedarwObservationContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == SEEAvatarRedarwObservationContext) {
        [self setNeedsDisplay:YES];

    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Drawing

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];

	NSRect bounds = self.bounds;
	CGFloat borderWidth = NSWidth(bounds) / 20.0;
	NSRect drawingRect = NSInsetRect(bounds, borderWidth/2.0, borderWidth/2.0);
	NSRect imageRect = [self centerScanRect:drawingRect];

	NSBezierPath *borderPath = [NSBezierPath bezierPathWithOvalInRect:imageRect];
	[borderPath setLineWidth:borderWidth];

	// draw the background
	[self.backgroundColor set];
	[borderPath fill];

	//draw the image clipped
	[[NSGraphicsContext currentContext] saveGraphicsState];
	[borderPath setClip];

	NSImage *image = self.image;
	if (image) {
		[image drawInRect:imageRect
				 fromRect:NSZeroRect
				operation:NSCompositeSourceOver
				 fraction:1.0
		   respectFlipped:YES
					hints:nil];
	} else {
		// draw placeholder image
		image = [NSImage imageNamed:NSImageNameUser];

		NSRect imageBounds = NSZeroRect;
		imageBounds.size = image.size;
		NSRect imageSourceRect = NSInsetRect(imageBounds, 2.0, 2.0);

		[image drawInRect:imageRect
				 fromRect:imageSourceRect
				operation:NSCompositeSourceOver
				 fraction:0.8
		   respectFlipped:YES
					hints:nil];

		// draw initials string
		NSString *initials = self.initials;

		CGFloat fontSize = NSWidth(bounds) / 5.0;

		NSShadow *textShadow = [[NSShadow alloc] init];
		textShadow.shadowBlurRadius = 0.0;
		textShadow.shadowColor = [NSColor blackColor];
		textShadow.shadowOffset = NSMakeSize(0.0, -1.0);

		NSDictionary *stringAttributes = @{NSFontAttributeName: [NSFont fontWithName:@"HelveticaNeue-Light" size:fontSize],
										   NSForegroundColorAttributeName: [[NSColor whiteColor] colorWithAlphaComponent:0.8],
										   NSShadowAttributeName: textShadow};

		NSSize textSize = [initials sizeWithAttributes:stringAttributes];
		NSRect textBounds = [initials boundingRectWithSize:textSize options:0 attributes:stringAttributes];

		NSRect textDrawingRect = NSMakeRect(NSMidX(imageRect) - NSWidth(textBounds) / 2.0,
											NSMidY(imageRect) - NSHeight(textBounds),
											NSWidth(textBounds),
											NSHeight(textBounds));

		[initials drawWithRect:textDrawingRect
					   options:0
					attributes:stringAttributes];

//		NSFrameRect(textDrawingRect);
	}

	if (self.isHovering) {
		[[NSGraphicsContext currentContext] saveGraphicsState]; {
			// background
			[[NSColor colorWithWhite:0.0 alpha:0.5] set];
			[borderPath fill];
			
			// text
			if (self.hoverString) {
				NSShadow *textShadow = [[NSShadow alloc] init];
				textShadow.shadowBlurRadius = 0.0;
				textShadow.shadowColor = [NSColor colorWithWhite:0.7 alpha:0.8];
				textShadow.shadowOffset = NSMakeSize(0.0, -1.0);
				
				NSString *hoverString = self.hoverString;
				CGFloat inset = 10.;
				CGFloat maxFontSize = 16;
				
				NSFont *font = [NSFont fontWithName:@"HelveticaNeue-Light" size:12.];
				NSSize size = [hoverString sizeWithAttributes:@{ NSFontAttributeName : font}];
				NSSize insetSize = CGSizeMake(NSWidth(imageRect) - 2*inset, NSHeight(imageRect) - 2*inset);
				CGFloat scale = MIN( insetSize.width/size.width, insetSize.height/size.height );
				CGFloat fontSize = MIN(font.pointSize * scale, maxFontSize);
				font = [NSFont fontWithName:font.fontName size:fontSize];
				
				NSDictionary *stringAttributes = @{
												   NSFontAttributeName: font,
												   NSForegroundColorAttributeName: [NSColor colorWithWhite:1.0 alpha:0.8],
												   NSShadowAttributeName: textShadow
												   };
				
				NSSize textSize = [hoverString sizeWithAttributes:stringAttributes];
				NSRect textBounds = [hoverString boundingRectWithSize:textSize options:0 attributes:stringAttributes];
				
				NSRect textRect = NSMakeRect(NSMidX(imageRect) - NSWidth(textBounds) / 2.0,
											 NSMidY(imageRect) - NSHeight(textBounds) / 2.0 + 4.,
											 NSWidth(textBounds),
											 NSHeight(textBounds));
				
				textRect = [self centerScanRect:textRect];
				
				[hoverString drawWithRect:textRect
								  options:0
							   attributes:stringAttributes];
				
			}
		}[[NSGraphicsContext currentContext] restoreGraphicsState];
	}

	[[NSGraphicsContext currentContext] restoreGraphicsState];

	// draw the border
	[self.borderColor set];
	[borderPath stroke];
	
}


#pragma mark - Overrides

- (BOOL)isOpaque
{
	return NO;
}

#pragma mark - Hover Image
- (void)enableHoverImage {
	NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
																options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow | NSTrackingInVisibleRect
																  owner:self
															   userInfo:nil];
	self.hoverTrackingArea = trackingArea;
	[self addTrackingArea:trackingArea];
}

- (void)disableHoverImage {
	self.isHovering = NO;
	[self removeTrackingArea:self.hoverTrackingArea];
	self.hoverTrackingArea = nil;
}

- (void)mouseEntered:(NSEvent *)anEvent {
	if (!self.isHovering) {
		[self setNeedsDisplay:YES];
	}
	self.isHovering = YES;
}

- (void)mouseExited:(NSEvent *)anEvent {
	if (self.isHovering) {
		[self setNeedsDisplay:YES];
	}
	self.isHovering = NO;
}

@end
