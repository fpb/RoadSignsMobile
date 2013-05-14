//
//  MyCamera.mm
//  HelloOpenCViOS
//
//  Created by David on 13/05/13.
//  Copyright (c) 2013 FCT/UNL. All rights reserved.
//

#import "MyCamera.h"

@implementation MyCamera
@synthesize captureLayer	= _captureLayer;
@synthesize captureSession	= _captureSession;
@synthesize captureView		= _captureView;

- (id) initWithFrame:(CGRect) frame
{
	self = [super init];
	if (self)
	{
		_captureView = [[UIView alloc] initWithFrame:frame];
		_captureView.bounds = frame;
	}
	
	return self;
}

- (void)dealloc
{
	[self stopCameraPreview];
	[_captureView removeFromSuperview];
}

- (void)startCameraPreview
{
	AVCaptureDevice* camera = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	if (camera == nil) {
		return;
	}
	
	_captureSession = [[AVCaptureSession alloc] init];
	AVCaptureDeviceInput *newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:camera error:nil];
	[_captureSession addInput:newVideoInput];
	
	_captureLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
	_captureLayer.frame = _captureView.bounds;
	//	[captureLayer setOrientation:AVCaptureVideoOrientationPortrait];
	[[_captureLayer connection] setVideoOrientation:AVCaptureVideoOrientationPortrait];
	[_captureLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
	[_captureView.layer addSublayer:_captureLayer];
	
	// Start the session. This is done asychronously since -startRunning doesn't return until the session is running.
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{[_captureSession startRunning];});
}

- (void)stopCameraPreview
{
	[_captureSession stopRunning];
	[_captureLayer removeFromSuperlayer];
	_captureSession = nil;
	_captureLayer = nil;
}

@end
