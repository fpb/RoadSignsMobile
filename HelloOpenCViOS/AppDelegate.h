//
//  AppDelegate.h
//  HelloOpenCViOS
//
//  Created by Fernando Birra on 4/16/13.
//  Copyright (c) 2013 FCT/UNL. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CoreDataModule;
@class ViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) CoreDataModule *cdm;
@property (weak, nonatomic) ViewController *controller;
@end
