//
//  CoreMotionModule.mm
//  HelloOpenCViOS
//
//  Created by David on 13/05/13.
//  Copyright (c) 2013 FCT/UNL. All rights reserved.
//

#import "CoreMotionModule.h"

@implementation CoreMotionModule

@synthesize motionManager = _motionManager;

- (id)init
{
	self = [super init];
	if (self)
	{
		_motionManager = [CMMotionManager new];
		// Tell CoreMotion to show the compass calibration HUD when required to provide true north-referenced attitude
		_motionManager.showsDeviceMovementDisplay = YES;
		_motionManager.deviceMotionUpdateInterval = 1.0 / 60.0;

	}
	
	return self;
}

- (void)startDeviceMotion
{
	// New in iOS 5.0: Attitude that is referenced to true north
	[_motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXTrueNorthZVertical];
}

- (void)stopDeviceMotion
{
	[_motionManager stopDeviceMotionUpdates];
}

@end
