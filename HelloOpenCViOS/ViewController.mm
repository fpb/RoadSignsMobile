//
//  ViewController.m
//  HelloOpenCViOS
//
//  Created by Fernando Birra on 4/16/13.
//  Copyright (c) 2013 FCT/UNL. All rights reserved.
//

#import "ViewController.h"

#include "ShapeFinder.h"


#define GRAD_THRESHOLD  150

void drawShapes(const std::vector<Shape*> &shapes, cv::Mat &img)
{
    for(std::vector<Shape*>::const_iterator it = shapes.begin(); it!=shapes.end(); it++)
        (*it)->drawOn(img);
}

@interface ViewController ()

@end

@implementation ViewController

@synthesize videoCamera;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.videoCamera = [[CvVideoCamera alloc] initWithParentView:imageView];
    self.videoCamera.delegate = self;
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset352x288;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.videoCamera.defaultFPS = 25;
    self.videoCamera.grayscaleMode = NO;
}

#pragma mark - Protocol CvVideoCameraDelegate

#ifdef __cplusplus
- (void)processImage:(Mat&)image;
{
    // Do some OpenCV stuff with the image
    Mat image_copy;
    cvtColor(image, image_copy, CV_BGRA2BGR);
    
    // invert image
//    bitwise_not(image_copy, image_copy);
//    cvtColor(image_copy, image, CV_BGR2BGRA);

    cvtColor(image_copy, image_copy, CV_RGB2GRAY);
    
    
    ShapeFinder sf(image_copy);
    
    // TODO: Change this to a configured parameter
    sf.prepare(GRAD_THRESHOLD);
    
    std::vector<Shape*> c_shapes;
    std::vector<int> lengths;
    //lengths.push_back(10);
    lengths.push_back(13);
    lengths.push_back(17);
    lengths.push_back(22);
    c_shapes = sf.findShape(0,lengths);

    cvtColor(image, image, CV_RGBA2BGR);
    drawShapes(c_shapes, image);

}
#endif

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - UI Actions

- (IBAction)actionStart:(id)sender;
{
    [self.videoCamera start];
}

@end
