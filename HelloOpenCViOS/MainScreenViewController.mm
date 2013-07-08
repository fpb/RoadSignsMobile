//
//  MainScreenViewController.m
//  HelloOpenCViOS
//
//  Created by David on 18/06/13.
//  Copyright (c) 2013 FCT/UNL. All rights reserved.
//

#import "MainScreenViewController.h"

#import "ViewController.h"

@interface MainScreenViewController ()

@end

@implementation MainScreenViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	ViewController *gameViewController = [segue destinationViewController];
    if ([[segue identifier] isEqualToString:@"MainToLearning"])
	{
		[gameViewController setMode:GameModes::Learning];
    }
	
	if ([[segue identifier] isEqualToString:@"MainToFindTheSign"])
	{
		[gameViewController setMode:GameModes::FindTheSign];
    }

}

@end
