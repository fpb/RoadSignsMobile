//
//  ViewController.m
//  HelloOpenCViOS
//
//  Created by Fernando Birra on 4/16/13.
//  Copyright (c) 2013 FCT/UNL. All rights reserved.
//

#import "ViewController.h"

#include "ShapeFinder.h"

#import "PlaceOfInterest.h"
#import "ARView.h"
#import "FetchResults.h"
#import "Location.h"
#import "RoadSign.h"

#define GRAD_THRESHOLD  150

const float kGradThresholdSquare = GRAD_THRESHOLD * GRAD_THRESHOLD;

void drawShapes(const std::vector<Shape*> &shapes, cv::Mat &img)
{
    for(std::vector<Shape*>::const_iterator it = shapes.begin(); it!=shapes.end(); ++it)
        (*it)->drawOn(img);
}

@interface ViewController ()

@end


@implementation ViewController

@synthesize managedObjectContext = _managedObjectContext;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	ARView *arView = (ARView *)self.view;
	[arView setManagedObjectContext:self.managedObjectContext];
	
	NSArray *results = FetchResultsFromEntitywithPredicate(self.managedObjectContext, @"Location", nil);
	//	[NSPredicate predicateWithFormat:@"name == %@", @"Give way"]
	//	NSLog(@"%@", [results count]);
	
	NSMutableArray *placesOfInterest = [NSMutableArray arrayWithCapacity:[results count]];
	int i = 0;
	for (Location *l in results)
	{
		// Get RoadSigns in this location
		NSArray *roadSigns = [[l.roadsigns allObjects] valueForKey:@"name"];
		
		UILabel *label = [[UILabel alloc] init];
		label.adjustsFontSizeToFitWidth = NO;
		label.opaque = NO;
		label.backgroundColor = [UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:0.5f];
		label.center = CGPointMake(200.0f, 200.0f);
		label.textAlignment = NSTextAlignmentCenter;
		label.textColor = [UIColor whiteColor];
		label.text = [roadSigns componentsJoinedByString:@"/"];
		CGSize size = [label.text sizeWithFont:label.font];
		label.bounds = CGRectMake(0.0f, 0.0f, size.width, size.height);
		
		PlaceOfInterest *poi = [PlaceOfInterest placeOfInterestWithView:label at:[[CLLocation alloc] initWithLatitude:[l.latitude doubleValue]
																											longitude:[l.longitude doubleValue]]
															   facingAt:[l.face floatValue]];
		[placesOfInterest insertObject:poi atIndex:i++];
	}
	
	[arView setPlacesOfInterest:placesOfInterest];

    //lengths.push_back(10);
    lengths.push_back(13);
    lengths.push_back(17);
    lengths.push_back(22);
	
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
//	[self.button setHidden:NO];
	ARView *arView = (ARView *)self.view;
	[arView start];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
//	[self.button setHidden:YES];
	[super viewDidDisappear:animated];
	ARView *arView = (ARView *)self.view;
	[arView stop];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return interfaceOrientation == UIInterfaceOrientationPortrait;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
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
*/

#pragma mark - UI Actions

//- (IBAction)actionStart:(id)sender;
//{
//    [self.videoCamera start];
//	[self.button setHidden:YES];
//}

@end
