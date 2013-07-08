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

enum class GameModes
{
	Learning,
	FindTheSign
};

class Shape;

@interface ViewController : GLKViewController <AVCaptureVideoDataOutputSampleBufferDelegate,
GLKViewControllerDelegate,
GLKViewDelegate,
CoreLocationModuleDelegate>
{
	std::vector<int> lengths;
}

@property (nonatomic, weak) NSArray *placesOfInterest;

// Core Data
@property (nonatomic, weak) NSManagedObjectContext *managedObjectContext;

// Options
@property (weak, nonatomic) IBOutlet UILabel *locationLabel2;
@property (nonatomic, weak) IBOutlet UILabel *headingLabel2;
@property (nonatomic, weak) IBOutlet UILabel *fpsLabel2;

@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (nonatomic, weak) IBOutlet UILabel *headingLabel;
@property (nonatomic, weak) IBOutlet UILabel *fpsLabel;

@property (nonatomic, weak) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *pictureButton;

@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *loadingView;
@property (nonatomic, weak) IBOutlet UILabel *warningLabel;

@property (weak, nonatomic) IBOutlet UIButton *mainMenuButton;

@property (nonatomic, assign) GameModes mode;
@property (weak, nonatomic) IBOutlet UILabel *findTheSignLabel;

- (IBAction)takePicture:(id)sender;
@end
