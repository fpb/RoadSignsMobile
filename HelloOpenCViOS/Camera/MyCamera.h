//
//  MyCamera.h
//  HelloOpenCViOS
//
//  Created by David on 13/05/13.
//  Copyright (c) 2013 FCT/UNL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface MyCamera : NSObject

@property (readonly, nonatomic, strong) UIView *captureView;
@property (readonly, nonatomic, strong) AVCaptureSession *captureSession;
@property (readonly, nonatomic, strong) AVCaptureVideoPreviewLayer *captureLayer;


- (id)initWithFrame:(CGRect) frame;
- (void)startCameraPreview;
- (void)stopCameraPreview;

@end
