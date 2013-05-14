//
//  CoreMotionModule.h
//  HelloOpenCViOS
//
//  Created by David on 13/05/13.
//  Copyright (c) 2013 FCT/UNL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>

@interface CoreMotionModule : NSObject

@property (readonly, nonatomic, strong) CMMotionManager *motionManager;

- (void)startDeviceMotion;
- (void)stopDeviceMotion;

@end
