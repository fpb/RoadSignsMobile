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

@property(nonatomic, weak) id<AVCaptureVideoDataOutputSampleBufferDelegate> delegate;
@property(nonatomic, readonly, strong) AVCaptureStillImageOutput *stillImageOutput;

- (id)initWithFrame:(CGRect) frame;
- (void)startCameraPreviewWithPreset:(NSString*) preset;
- (void)stopCameraPreview;
- (void)startRunning;
- (void)stopRunning;
- (BOOL)isRunning;
@end
