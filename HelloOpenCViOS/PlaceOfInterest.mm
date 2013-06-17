/*
 File: PlaceOfInterest.m
 Abstract: Class that represents a place-of-interest: a position (latitude and longitude) and associated UIView.
 Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2012 Apple Inc. All Rights Reserved.
 
 */

#import "PlaceOfInterest.h"
#import "Utilities.h"

@implementation PlaceOfInterest

- (id)init
{
    self = [super init];
    if (self)
	{
		_views = nil;
//		_view = nil;
		_location = nil;
		_heading = nil;
    }
    return self;
}

//- (void)dealloc
//{
//	[view release];
//	[location release];
//	[super dealloc];
//}

- (void)setFace:(CLLocationDirection) trueHeading
{
	_heading = trueHeading;
}

- (CLLocationDirection) face
{
	return _heading;
}

- (void)setDistance:(CLLocationDistance)distance
{
	_distance = distance;
}

- (CLLocationDistance) distance
{
	return _distance;
}

- (void)setViewsCenter:(CGPoint)center
{
//	for (UIView *view in _views)
//	{
//		view.center = center;
//	}
	int numberOfImages = [_views count];
	
	if (numberOfImages == 1)
	{
		((UIImageView*)[_views objectAtIndex:0]).center = center;
	}
	else // More than one item
	{
		CGPoint newCenter = center;
		float displace;
		float sign;
		if (numberOfImages % 2 == 0)
		{
			displace = 25;
			sign = 1;
			for (UIView *view in _views)
			{
				view.center = CGPointMake(newCenter.x, newCenter.y + displace * sign);
				sign *= -1;
				if (sign == 1) displace += 50;
			}
		}
		else
		{
			displace = 0;
			sign = 1;
			for (UIView *view in _views)
			{
				view.center = CGPointMake(newCenter.x, newCenter.y + displace * sign);
				if (sign == 1) displace += 50;
				sign *= -1;
				
			}
		}
	}
}

- (void)setViewsHidden:(BOOL)hidden
{
	for (UIView *view in _views)
	{
		view.hidden = hidden;
	}

}

- (void)setViewsSize:(CGSize)size
{
	for (UIView *view in _views)
	{
		view.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y, size.width, size.height);
	}
}

- (void)removeFromSuperview
{
	for (UIView *view in _views)
	{
		[view removeFromSuperview];
	}
}

- (void)transformViews:(CGAffineTransform)transform
{
	for (UIView *view in _views)
	{
		view.transform = transform;
	}
	
//	int numberOfImages = [_views count];
//
//	if (numberOfImages == 1)
//	{
//		((UIImageView*)[_views objectAtIndex:0]).transform = transform;
//	}
//	else // More than one item
//	{
//		float displace;
//		float sign;
//		if (numberOfImages % 2 == 0)
//		{
//			displace = 25;
//			sign = 1;
//			for (UIView *view in _views)
//			{
//				
//				view.transform = CGAffineTransformConcat(transform, CGAffineTransformMakeTranslation(view.center.x, view.center.y + displace * sign));
//				sign *= -1;
//				if (sign == 1) displace += 50;
//			}
//		}
//		else
//		{
//			displace = 0;
//			sign = 1;
//			for (UIView *view in _views)
//			{
//				view.transform = CGAffineTransformConcat(transform, CGAffineTransformMakeTranslation(view.center.x, view.center.y + displace * sign));
//				if (sign == 1) displace += 50;
//				sign *= -1;
//				
//			}
//		}
//	}
}

//+ (PlaceOfInterest *)placeOfInterestWithView:(UIView *)view at:(CLLocation *)location facingAt:(CLLocationDirection) trueHeading
//{
//	PlaceOfInterest *poi = [PlaceOfInterest new];
//	poi.view = view;
//	poi.view.hidden = YES;
//	poi.location = location;
//	[poi setFace:trueHeading];
//	
//	return poi;
//}

+ (PlaceOfInterest *)placeOfInterestWithViews:(NSArray *)images at:(CLLocation *)location facingAt:(CLLocationDirection) trueHeading
{
	PlaceOfInterest *poi = [PlaceOfInterest new];
//	poi.view = view;
	NSMutableArray *imageViews = [[NSMutableArray alloc] initWithCapacity:[images count]];
	
	for (UIImage *image in images)
	{
		UIImageView *imageView = [[UIImageView alloc] initWithImage:image highlightedImage:convertImageToGrayScale(image)];
		//set contentMode to scale aspect to fit
		imageView.contentMode = UIViewContentModeScaleAspectFit;
		//change width of frame
		CGRect frame = imageView.frame;
		frame.size.height = 50;
		frame.size.width = 50;
		imageView.frame = frame;
		[imageViews addObject:imageView];
	}
	
	poi.views = imageViews;
	[poi setViewsHidden:YES];
	poi.location = location;
	[poi setFace:trueHeading];
	
	return poi;
}

@end
