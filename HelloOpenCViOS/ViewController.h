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

class Shape;

@interface ViewController : UIViewController<CLLocationManagerDelegate>
{
	std::vector<int> lengths;
}

// Core Data
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end
