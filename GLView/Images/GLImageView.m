//
//  GLImageView.m
//
//  GLView Project
//  Version 1.3.4
//
//  Created by Nick Lockwood on 10/07/2011.
//  Copyright 2011 Charcoal Design
//
//  Distributed under the permissive zlib License
//  Get the latest version from either of these locations:
//
//  http://charcoaldesign.co.uk/source/cocoa#glview
//  https://github.com/nicklockwood/GLView
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//

#import "GLImageView.h"


@interface GLImageView ()

@property (nonatomic, unsafe_unretained) id currentFrame;

@end


@implementation GLImageView

@synthesize image = _image;
@synthesize blendColor = _blendColor;
@synthesize animationImages = _animationImages;
@synthesize animationDuration = _animationDuration;
@synthesize animationRepeatCount = _animationRepeatCount;
@synthesize currentFrame = _currentFrame;


- (GLImageView *)initWithImage:(GLImage *)image
{
	if ((self = [self initWithFrame:CGRectMake(0, 0, image.size.width, image.size.height)]))
	{
		self.image = image;
	}
	return self;
}

- (void)setImage:(GLImage *)image
{
    if (_image != image)
    {
        AH_RELEASE(_image);
        _image = AH_RETAIN(image);
        [self setNeedsDisplay];
    }
}

- (void)setAnimationImages:(NSArray *)animationImages
{
	if (_animationImages != animationImages)
	{
		[self stopAnimating];
		AH_RELEASE(_animationImages);
		_animationImages = [animationImages copy];
		self.animationDuration = [animationImages count] / 30.0;
	}
}

#pragma mark Animation

- (void)startAnimating
{
	if (self.animationImages)
	{
		[super startAnimating];
	}
}

- (void)step:(NSTimeInterval)dt
{
    //end animation?
    if (self.animationRepeatCount > 0 && self.elapsedTime / self.animationDuration >= self.animationRepeatCount)
    {
        self.elapsedTime = self.animationDuration * self.animationRepeatCount - 0.001;
        [self stopAnimating];
    }
	
	//calculate frame
	NSInteger numberOfFrames = [self.animationImages count];
	if (numberOfFrames)
	{
        NSInteger frameIndex = numberOfFrames * (self.elapsedTime / self.animationDuration);
		id frame = [self.animationImages objectAtIndex:frameIndex % numberOfFrames];
		if (frame != self.currentFrame)
		{
			self.currentFrame = frame;
			if ([self.currentFrame isKindOfClass:[GLImage class]])
			{
				self.image = self.currentFrame;
			}
			else if ([self.currentFrame isKindOfClass:[NSString class]])
			{
				self.image = [GLImage imageWithContentsOfFile:self.currentFrame];
			}
		}
	}
}

- (CGSize)sizeThatFits:(CGSize)size
{
    return self.image.size;
}

- (void)didMoveToSuperview
{
	[super didMoveToSuperview];
	if (!self.superview)
	{
		[self stopAnimating];
	}
}

- (void)drawRect:(CGRect)rect
{
    //set blend color
    [self.blendColor ?: [UIColor whiteColor] bindGLColor];
	switch (self.contentMode)
	{
		case UIViewContentModeCenter:
		{
			rect = CGRectMake((self.bounds.size.width - self.image.size.width) / 2,
							  (self.bounds.size.height - self.image.size.height) / 2,
							  self.image.size.width, self.image.size.height);
			break;
		}
		case UIViewContentModeTopLeft:
		{
			rect = CGRectMake(0, 0, self.image.size.width, self.image.size.height);
			break;
		}
		case UIViewContentModeTop:
		{
			rect = CGRectMake((self.bounds.size.width - self.image.size.width) / 2,
							  0, self.image.size.width, self.image.size.height);
			break;
		}
		case UIViewContentModeRight:
		{
			rect = CGRectMake(self.bounds.size.width - self.image.size.width,
							  (self.bounds.size.height - self.image.size.height) / 2,
							  self.image.size.width, self.image.size.height);
			break;
		}
		case UIViewContentModeBottomRight:
		{
			rect = CGRectMake(self.bounds.size.width - self.image.size.width,
							  self.bounds.size.height - self.image.size.height,
							  self.image.size.width, self.image.size.height);
			break;
		}
		case UIViewContentModeBottom:
		{
			rect = CGRectMake((self.bounds.size.width - self.image.size.width) / 2,
							  self.bounds.size.height - self.image.size.height,
							  self.image.size.width, self.image.size.height);
			break;
		}
		case UIViewContentModeBottomLeft:
		{
			rect = CGRectMake(0, self.bounds.size.height - self.image.size.height,
							  self.image.size.width, self.image.size.height);
			break;
		}
		case UIViewContentModeLeft:
		{
			rect = CGRectMake(0, (self.bounds.size.height - self.image.size.height) / 2,
							  self.image.size.width, self.image.size.height);
			break;
		}
		case UIViewContentModeScaleAspectFill:
		{
			CGFloat aspect1 = self.image.size.width / self.image.size.height;
			CGFloat aspect2 = self.bounds.size.width / self.bounds.size.height;
			if (aspect1 < aspect2)
			{
				rect = CGRectMake(0, (self.bounds.size.height - self.bounds.size.width / aspect1) / 2,
								  self.bounds.size.width, self.bounds.size.width / aspect1);
			}
			else
			{
				rect = CGRectMake((self.bounds.size.width - self.bounds.size.height * aspect1) / 2,
								  0, self.bounds.size.height * aspect1, self.bounds.size.height);
			}
			break;
		}
		case UIViewContentModeScaleAspectFit:
		{
			CGFloat aspect1 = self.image.size.width / self.image.size.height;
			CGFloat aspect2 = self.bounds.size.width / self.bounds.size.height;
			if (aspect1 > aspect2)
			{
				rect = CGRectMake(0, (self.bounds.size.height - self.bounds.size.width / aspect1) / 2,
								  self.bounds.size.width, self.bounds.size.width / aspect1);
			}
			else
			{
				rect = CGRectMake((self.bounds.size.width - self.bounds.size.height * aspect1) / 2,
								  0, self.bounds.size.height * aspect1, self.bounds.size.height);
			}
			break;
		}
		case UIViewContentModeScaleToFill:
		default:
		{
			rect = self.bounds;
		}
	}
    [self.image drawInRect:rect];
}

- (void)dealloc
{
    AH_RELEASE(_image);
    AH_RELEASE(_blendColor);
	AH_RELEASE(_animationImages);
    AH_SUPER_DEALLOC;
}

@end
