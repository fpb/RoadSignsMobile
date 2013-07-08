//
//  MyCamera.mm
//  HelloOpenCViOS
//
//  Created by David on 13/05/13.
//  Copyright (c) 2013 FCT/UNL. All rights reserved.
//

#import "MyCamera.h"
#import "ViewController.h"

// used for KVO observation of the @"capturingStillImage" property to perform flash bulb animation
static const NSString *AVCaptureStillImageIsCapturingStillImageContext = @"AVCaptureStillImageIsCapturingStillImageContext";

@interface MyCamera ()
{
	dispatch_queue_t _videoDataOutputQueue;
	UIView *_flashView;
	UIView *_captureView;
	AVCaptureSession *_captureSession;
	AVCaptureVideoPreviewLayer *_captureLayer;
}

@end

@implementation MyCamera
@synthesize delegate		 = _delegate;
@synthesize stillImageOutput = _stillImageOutput;

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

- (void)startCameraPreviewWithPreset:(NSString*) preset
{
	
	//-- Setup Capture Session.
	_captureSession = [AVCaptureSession new];
    [_captureSession beginConfiguration];
	
    //-- Set preset session size.
    [_captureSession setSessionPreset:preset];
	
	//-- Creata a video device and input from that Device.  Add the input to the capture session.
	AVCaptureDevice* camera = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	if (camera == nil)
		assert(0);
	
	//-- Add the device to the session.
	NSError *error;
	AVCaptureDeviceInput *newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:camera error:&error];
	if (error)
		assert(0);
	
	[_captureSession addInput:newVideoInput];
	
	// Make a still image output
	_stillImageOutput = [AVCaptureStillImageOutput new];
	[_stillImageOutput addObserver:self forKeyPath:@"capturingStillImage"
						   options:NSKeyValueObservingOptionNew
						   context:(__bridge void*)AVCaptureStillImageIsCapturingStillImageContext];
	if ( [_captureSession canAddOutput:_stillImageOutput] )
		[_captureSession addOutput:_stillImageOutput];
	
	
	//-- Create the output for the capture session.
	AVCaptureVideoDataOutput * dataOutput = [AVCaptureVideoDataOutput new];
	[dataOutput setAlwaysDiscardsLateVideoFrames:YES]; // Probably want to set this to NO when recording
	
	//-- Set to YUV420.
	[dataOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
															 forKey:(id)kCVPixelBufferPixelFormatTypeKey]]; // Necessary for manual preview
	
	// Set dispatch to be on the main thread so OpenGL can do things with the data
	[dataOutput setSampleBufferDelegate:_delegate queue:dispatch_get_main_queue()];
	
	if ( [_captureSession canAddOutput:dataOutput] )
		[_captureSession addOutput:dataOutput];
/*
	// create a serial dispatch queue used for the sample buffer delegate as well as when a still image is captured
	// a serial dispatch queue must be used to guarantee that video frames will be delivered in order
	// see the header doc for setSampleBufferDelegate:queue: for more information
	_videoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
	[dataOutput setSampleBufferDelegate:_delegate queue:_videoDataOutputQueue];
	
	_captureLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
	_captureLayer.frame = _captureView.bounds;
	//	[captureLayer setOrientation:AVCaptureVideoOrientationPortrait];
	[[_captureLayer connection] setVideoOrientation:AVCaptureVideoOrientationPortrait];
	[_captureLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
	[_captureView.layer addSublayer:_captureLayer];
*/	
 
    [_captureSession commitConfiguration];
	
	// Start the session. This is done asychronously since -startRunning doesn't return until the session is running.
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{[_captureSession startRunning];});
}

- (void)stopCameraPreview
{
	[_stillImageOutput removeObserver:self forKeyPath:@"capturingStillImage"];
	
	[_captureSession stopRunning];
	
	if (_captureLayer)
		[_captureLayer removeFromSuperlayer];
	
	
	_videoDataOutputQueue = nil;
	_captureSession = nil;
	_captureLayer = nil;
}

// perform a flash bulb animation using KVO to monitor the value of the capturingStillImage property of the AVCaptureStillImageOutput class
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == (__bridge void*)AVCaptureStillImageIsCapturingStillImageContext)
	{
		BOOL isCapturingStillImage = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
		
		if (isCapturingStillImage)
		{
			// do flash bulb like animation
			_flashView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
			[_flashView setBackgroundColor:[UIColor whiteColor]];
			[_flashView setAlpha:0.0f];
			[[[(ViewController*)_delegate view] window] addSubview:_flashView];
			
			[UIView animateWithDuration:.4f
							 animations:^{[_flashView setAlpha:1.f];}
			 ];
		}
		else {
			[UIView animateWithDuration:.4f
							 animations:^{[_flashView setAlpha:0.f];}
							 completion:^(BOOL finished)
							 {
								 [_flashView removeFromSuperview];
								 _flashView = nil;
							 }
			 ];
		}
	}
}

- (void)startRunning
{
	[_captureSession startRunning];
}

- (void)stopRunning
{
	[_captureSession stopRunning];
}

- (BOOL)isRunning
{
	return [_captureSession isRunning];
}

@end
