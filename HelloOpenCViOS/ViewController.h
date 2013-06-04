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

@property (nonatomic, weak) NSArray *placesOfInterest;

// Core Data
@property (nonatomic, weak) NSManagedObjectContext *managedObjectContext;

// Options
@property (nonatomic, weak) IBOutlet UILabel *distanceLabel2;
@property (nonatomic, weak) IBOutlet UILabel *headingLabel2;
@property (nonatomic, weak) IBOutlet UILabel *fpsLabel2;

@property (nonatomic, weak) IBOutlet UILabel *distanceLabel;
@property (nonatomic, weak) IBOutlet UILabel *headingLabel;
@property (nonatomic, weak) IBOutlet UILabel *fpsLabel;

@property (nonatomic, weak) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *pictureButton;

@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *loadingView;
@property (nonatomic, weak) IBOutlet UILabel *warningLabel;

// Minigames
@property (nonatomic, weak) IBOutlet UILabel *minigameLabel;
#if defined(DEBUG)
@property (weak, nonatomic) IBOutlet UIButton *minigameButton;


- (IBAction)minigamePressButton:(UIButton *)sender;
#endif

- (IBAction)takePicture:(id)sender;
@end
