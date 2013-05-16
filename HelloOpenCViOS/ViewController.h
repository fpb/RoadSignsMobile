//
//  ViewController.h
//  HelloOpenCViOS
//
//  Created by Fernando Birra on 4/16/13.
//  Copyright (c) 2013 FCT/UNL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>
#import <GLKit/GLKit.h>
#import <AVFoundation/AVFoundation.h>

#import "CoreLocationModule.h"
#import "CoreMotionModule.h"

class Shape;

@interface ViewController : GLKViewController <AVCaptureVideoDataOutputSampleBufferDelegate, GLKViewDelegate, CoreLocationModuleDelegate>
{
	std::vector<int> lengths;
}

@property (nonatomic, strong) NSArray *placesOfInterest;

// Core Data
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

// Options
@property (nonatomic, strong) IBOutlet UILabel *distanceLabel2;
@property (nonatomic, strong) IBOutlet UILabel *headingLabel2;
@property (nonatomic, strong) IBOutlet UILabel *fpsLabel2;

@property (nonatomic, strong) IBOutlet UILabel *distanceLabel;
@property (nonatomic, strong) IBOutlet UILabel *headingLabel;
@property (nonatomic, strong) IBOutlet UILabel *fpsLabel;

@property (nonatomic, strong) IBOutlet UIToolbar *toolbar;

- (IBAction)takePicture:(id)sender;
@end
