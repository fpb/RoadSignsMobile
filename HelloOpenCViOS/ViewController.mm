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
#import "FetchResults.h"
#import "Location.h"
#import "RoadSign.h"
#include "Utilities.h"
#import "MyCamera.h"
#import "FPS.h"

#import <CoreVideo/CoreVideo.h>

const BOOL showFPS = YES;
const BOOL showDistance = NO;
const BOOL showHeading = YES;

const CGFloat toolbarHeight = 44.0f;
const CGFloat screenHeight = 480.0f;
const CGFloat screenWithToolBar = (screenHeight - toolbarHeight) / screenHeight;

const float kMinDistnace = 10.0f;
const float kMaxDistnace = 500.0f;

const GLfloat texCoords[] = {
	0,0,
	1,0,
	0,1,
	1,1
};

const GLfloat vertices[] = {
	// Full screen
	//	 1, 1,
	//	 1,-1,
	//	-1, 1,
	//	-1,-1
	
	// Full screen with toolbar. ToolbarHeight is double because of retina screen
	1, 1,
	1,-(screenHeight - toolbarHeight * 2) / screenHeight,
	-1, 1,
	-1,-(screenHeight - toolbarHeight * 2) / screenHeight
	
};

const GLushort indices[]  = {0, 1, 2, 3};

// Uniform index.
enum
{
    UNIFORM_Y,
    UNIFORM_UV,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum
{
    ATTRIB_VERTEX,
    ATTRIB_TEXCOORD,
    NUM_ATTRIBUTES
};

#define GRAD_THRESHOLD  150

//const float kGradThresholdSquare = GRAD_THRESHOLD * GRAD_THRESHOLD;

void drawShapes(const std::vector<Shape*> &shapes, cv::Mat &img)
{
    for(std::vector<Shape*>::const_iterator it = shapes.begin(); it!=shapes.end(); ++it)
        (*it)->drawOn(img);
}

@interface ViewController ()
{
	FramesPerSecond fps;
	
	MyCamera *camera;
	
	GLuint _program;
    
    GLuint _positionVBO;
    GLuint _texcoordVBO;
    GLuint _indexVBO;
    
    size_t _textureWidth;
    size_t _textureHeight;
    
    EAGLContext *_context;
    
    CVOpenGLESTextureRef _lumaTexture;
    CVOpenGLESTextureRef _chromaTexture;
    
    CVOpenGLESTextureCacheRef _videoTextureCache;
	
	CoreLocationModule *_locationManager;
	CoreMotionModule *_motionManager;
	
	vec4f_t *_placesOfInterestCoordinates;
	NSArray *_placesOfInterest;
	
	mat4f_t _projectionTransform;
	mat4f_t _cameraTransform;
	
	float _deviceYrotation;
}

- (void)cleanUpTextures;
- (void)setupAVCapture;
- (void)tearDownAVCapture;

- (void)setupBuffers;
- (void)setupGL;
- (void)tearDownGL;

- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;

- (void)setupPois;
- (void)updatePlacesOfInterestCoordinates;
- (void)tearDownPois;

- (void)setupLocationManager;
- (void)tearDownLocationManager;

- (void)setupMotionManager;
- (void)tearDownMotionManager;

@end


@implementation ViewController

@dynamic placesOfInterest;
@synthesize managedObjectContext = _managedObjectContext;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	//lengths.push_back(10);
    lengths.push_back(13);
    lengths.push_back(17);
    lengths.push_back(22);
	
	if (showFPS)
	{
		self.fpsLabel.hidden = NO;
		self.fpsLabel2.hidden = NO;
	}
	if (showDistance)
	{
		self.distanceLabel.hidden = NO;
		self.distanceLabel2.hidden = NO;
	}
	if (showHeading)
	{
		self.headingLabel.hidden = NO;
		self.headingLabel2.hidden = NO;
	}
	
    [self setupGL];
    [self setupAVCapture];
	
	// Initialize projection matrix
	CGRect frame = CGRectMake(0, 0, 320, 480 - toolbarHeight); // Substract toolbar height
	createProjectionMatrix(_projectionTransform, 60.8f * DEGREES_TO_RADIANS, frame.size.width * 1.0f / frame.size.height, 0.25f, 1000.0f);
	
	[self setupPois];
	[self setupLocationManager];
	[self setupMotionManager];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
	[self tearDownPois];
	[self tearDownMotionManager];
	[self tearDownLocationManager];
    [self tearDownAVCapture];
    [self tearDownGL];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	fps.initFPS();
	
	[_locationManager startLocation];
	[_motionManager startDeviceMotion];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	//	[self.button setHidden:YES];
	[super viewDidDisappear:animated];
	
	[_locationManager stopLocation];
	[_motionManager stopDeviceMotion];
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

#pragma mark - Camera
- (void)setupAVCapture
{
	camera = [MyCamera new];
	
    //-- Create CVOpenGLESTextureCacheRef for optimal CVImageBufferRef to GLES texture conversion.
#if COREVIDEO_USE_EAGLCONTEXT_CLASS_IN_API
    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, _context, NULL, &_videoTextureCache);
#else
    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, (__bridge void *)_context, NULL, &_videoTextureCache);
#endif
	
	NSString *sessionPreset;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        sessionPreset = AVCaptureSessionPreset1280x720;
    else
        sessionPreset = AVCaptureSessionPreset352x288;
    
	camera.delegate = self;
	[camera startCameraPreviewWithPreset:sessionPreset];
	
    if (err)
    {
        NSLog(@"Error at CVOpenGLESTextureCacheCreate %d", err);
        return;
    }
	
	[self setupBuffers];
}

- (void)tearDownAVCapture
{
    [self cleanUpTextures];
    
    CFRelease(_videoTextureCache);
	
	[camera stopCameraPreview];
	camera = nil;
}
#pragma mark Camera delegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CVReturn err;
	CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
	CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    size_t width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0);
    size_t height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0);
	
    if (!_videoTextureCache)
    {
        NSLog(@"No video texture cache");
        return;
    }
    	
    [self cleanUpTextures];
    
    // CVOpenGLESTextureCacheCreateTextureFromImage will create GLES texture optimally from CVImageBufferRef.
    
    // Y-plane
    glActiveTexture(GL_TEXTURE0);
	
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                       _videoTextureCache,
                                                       pixelBuffer,
                                                       NULL,
                                                       GL_TEXTURE_2D,
                                                       GL_RED_EXT,
                                                       width,
                                                       height,
                                                       GL_RED_EXT,
                                                       GL_UNSIGNED_BYTE,
                                                       0,
                                                       &_lumaTexture);
    if (err)
    {
        NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    
    glBindTexture(CVOpenGLESTextureGetTarget(_lumaTexture), CVOpenGLESTextureGetName(_lumaTexture));
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    // UV-plane
    glActiveTexture(GL_TEXTURE1);
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                       _videoTextureCache,
                                                       pixelBuffer,
                                                       NULL,
                                                       GL_TEXTURE_2D,
                                                       GL_RG_EXT,
                                                       width >> 1,
                                                       height >> 1,
                                                       GL_RG_EXT,
                                                       GL_UNSIGNED_BYTE,
                                                       1,
                                                       &_chromaTexture);
    if (err)
    {
        NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    
    glBindTexture(CVOpenGLESTextureGetTarget(_chromaTexture), CVOpenGLESTextureGetName(_chromaTexture));
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		
	CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
}

#pragma mark - OpenCV
- (void) processImage:(cv::Mat&) image
{
	//	// Do some OpenCV stuff with the image
	//	cv::Mat image_copy;
	//    cvtColor(image, image_copy, CV_BGRA2BGR);
    
    // invert image
	//    bitwise_not(image_copy, image_copy);
	//    cvtColor(image_copy, image, CV_BGR2BGRA);
	
	//    cvtColor(image_copy, image_copy, CV_RGB2GRAY);
    
    
	//    ShapeFinder sf(image);
	//
	//    // TODO: Change this to a configured parameter
	//    sf.prepare(GRAD_THRESHOLD);
	//
	//    std::vector<Shape*> c_shapes;
	//    c_shapes = sf.findShape(0,lengths);
	
	//    cvtColor(image, image, CV_RGBA2BGR);
	//    drawShapes(c_shapes, image);
}

#pragma mark - OpenGL ES

- (void)cleanUpTextures
{
    if (_lumaTexture)
    {
        CFRelease(_lumaTexture);
        _lumaTexture = nullptr;
    }
    
    if (_chromaTexture)
    {
        CFRelease(_chromaTexture);
        _chromaTexture = nullptr;
    }
    
    // Periodic texture cache flush every frame
    CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
	
	
}

- (void)setupBuffers
{
    glGenBuffers(1, &_indexVBO);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexVBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(GLushort) << 2, indices, GL_STATIC_DRAW);
    
    glGenBuffers(1, &_positionVBO);
    glBindBuffer(GL_ARRAY_BUFFER, _positionVBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat) << 3, vertices, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, GL_FALSE, 0, 0);
	
    glGenBuffers(1, &_texcoordVBO);
    glBindBuffer(GL_ARRAY_BUFFER, _texcoordVBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat) << 3, texCoords, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(ATTRIB_TEXCOORD);
    glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, GL_FALSE, 0, 0);
}

- (void)setupGL
{
	_context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
	
    if (!_context) {
        NSLog(@"Failed to create ES context");
    }
	GLKView *glkView = (GLKView*)self.view;
    glkView.context = _context;
    self.preferredFramesPerSecond = 60;
    
	glkView.contentScaleFactor = [UIScreen mainScreen].scale;
	
    [EAGLContext setCurrentContext:_context];
    
    [self loadShaders];
    
    glUseProgram(_program);
	
    glUniform1i(uniforms[UNIFORM_Y], 0);
    glUniform1i(uniforms[UNIFORM_UV], 1);
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:_context];
    
    glDeleteBuffers(1, &_positionVBO);
    glDeleteBuffers(1, &_texcoordVBO);
    glDeleteBuffers(1, &_indexVBO);
    
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
	
	if ([EAGLContext currentContext] == _context)
        [EAGLContext setCurrentContext:nil];
}

#pragma mark OpenGL ES 2 shader compilation

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    _program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"YUVShader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"YUVShader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(_program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(_program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(_program, ATTRIB_VERTEX, "position");
    glBindAttribLocation(_program, ATTRIB_TEXCOORD, "texCoord");
    
    // Link program.
    if (![self linkProgram:_program]) {
        NSLog(@"Failed to link program: %d", _program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        return NO;
    }
    
    // Get uniform locations.
    uniforms[UNIFORM_Y] = glGetUniformLocation(_program, "SamplerY");
    uniforms[UNIFORM_UV] = glGetUniformLocation(_program, "SamplerUV");
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

#pragma mark - CLKViewController delegate
- (void) update
{
	CMDeviceMotion *d = _motionManager.motionManager.deviceMotion;
	if (d != nil)
	{
		CMRotationMatrix r = d.attitude.rotationMatrix;
		transformFromCMRotationMatrix(_cameraTransform, &r);
		_deviceYrotation = atan2f(d.gravity.x, d.gravity.y) + M_PI;
	}
	
	if (!_fpsLabel.hidden)
		_fpsLabel.text = [NSString stringWithFormat:@"%.2f fps", fps.CalculateFPS()];
}

#pragma mark - GLKView delegate
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClear(GL_COLOR_BUFFER_BIT);
    
	glDrawElements(GL_TRIANGLE_STRIP, 4, GL_UNSIGNED_SHORT, 0);
	
	if (_placesOfInterestCoordinates == nil)
		return;
	
	mat4f_t projectionCameraTransform;
	multiplyMatrixAndMatrix(projectionCameraTransform, _projectionTransform, _cameraTransform);
	
	int i = 0;
	for (PlaceOfInterest *poi in [_placesOfInterest objectEnumerator])
	{
		vec4f_t v;
		multiplyMatrixAndVector(v, projectionCameraTransform, _placesOfInterestCoordinates[i]);
		
		float x = (v[0] / v[3] + 1.0f) * 0.5f;
		float y = (v[1] / v[3] + 1.0f) * 0.5f;
		
		if (v[2] < 0.0f)
		{
			CGRect bounds = self.view.bounds;
			poi.view.backgroundColor = [UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:0.5f];
			poi.view.center = CGPointMake(x*bounds.size.width, bounds.size.height-y*bounds.size.height);

			if ([poi distance] < kMaxDistnace)
			{
				poi.view.hidden = NO;
				float scale = 1.0f - ([poi distance] - kMinDistnace) / (kMaxDistnace - kMinDistnace);
				poi.view.transform = CGAffineTransformMakeScale(scale, scale);
				poi.view.transform = CGAffineTransformRotate(poi.view.transform, _deviceYrotation);
				
				if (_locationManager.currentHeading.trueHeading < (poi.face - 90.0) && _locationManager.currentHeading.trueHeading > (poi.face + 90.0))
					poi.view.backgroundColor = [UIColor colorWithRed:0.0f green:1.0f blue:0.0f alpha:0.5f];
				if (x < 0.0f || x > 1.0f)
					poi.view.backgroundColor = [UIColor colorWithRed:1.0f green:0.0f blue:0.0f alpha:0.5f];
				if (y < 1.0f - screenWithToolBar || y > 1.0f)
					poi.view.backgroundColor = [UIColor colorWithRed:1.0f green:0.0f blue:0.0f alpha:0.5f];
			}
			else
				poi.view.hidden = YES;
		}
		else
		{
			poi.view.hidden = YES;
		}
		++i;
	}
	
	//	// Distance to closest sign
	//	if (!_distanceLabel.hidden)
	//		_distanceLabel.text = [NSString stringWithFormat:@"%f", distance];
}

#pragma mark - Places of Interest
- (void)setupPois
{
	NSArray *results = FetchResultsFromEntitywithPredicate(self.managedObjectContext, @"Location", nil);
	
	NSMutableArray *placesOfInterest = [NSMutableArray arrayWithCapacity:[results count]];
	int i = 0;
	for (Location *l in results)
	{
		// Get RoadSigns in this location
		NSArray *roadSigns = [[l.roadsigns allObjects] valueForKey:@"name"];
		
		UILabel *label = [UILabel new];
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
	
	[self setPlacesOfInterest:placesOfInterest];
}

- (void)tearDownPois
{
	if (_placesOfInterestCoordinates != nullptr)
	{
		free(_placesOfInterestCoordinates);
		_placesOfInterestCoordinates = nullptr;
	}
	
}
- (void)setPlacesOfInterest:(NSArray *)pois
{
	for (PlaceOfInterest *poi in [_placesOfInterest objectEnumerator])
		[poi.view removeFromSuperview];
	
	_placesOfInterest = nil;
	
	_placesOfInterest = pois;
	if (_locationManager.bestLocation != nil)
	{
		[self updatePlacesOfInterestCoordinates];
	}
}

- (NSArray *)placesOfInterest
{
	return _placesOfInterest;
}

- (void)updatePlacesOfInterestCoordinates
{
	if (_placesOfInterest == nil)
		return;
	
	if (_placesOfInterestCoordinates != NULL)
		free(_placesOfInterestCoordinates);
	
	_placesOfInterestCoordinates = (vec4f_t *)malloc(sizeof(vec4f_t)*_placesOfInterest.count);
	
	int i = 0;
	
	double myX, myY, myZ;
	latLonToEcef(_locationManager.bestLocation.coordinate.latitude, _locationManager.bestLocation.coordinate.longitude, 0.0, &myX, &myY, &myZ);
	
	// Array of NSData instances, each of which contains a struct with the distance to a POI and the
	// POI's index into placesOfInterest
	// Will be used to ensure proper Z-ordering of UIViews
	typedef struct {
		float distance;
		int index;
	} DistanceAndIndex;
	NSMutableArray *orderedDistances = [NSMutableArray arrayWithCapacity:_placesOfInterest.count];
	
	// Compute the world coordinates of each place-of-interest
	for (PlaceOfInterest *poi in [[self placesOfInterest] objectEnumerator]) {
		double poiX, poiY, poiZ, e, n, u;
		
		latLonToEcef(poi.location.coordinate.latitude, poi.location.coordinate.longitude, 0.0, &poiX, &poiY, &poiZ);
		ecefToEnu(_locationManager.bestLocation.coordinate.latitude, _locationManager.bestLocation.coordinate.longitude, myX, myY, myZ, poiX, poiY, poiZ, &e, &n, &u);
		
		_placesOfInterestCoordinates[i][0] = (float)n;
		_placesOfInterestCoordinates[i][1]= -(float)e;
		_placesOfInterestCoordinates[i][2] = 0.0f;
		_placesOfInterestCoordinates[i][3] = 1.0f;
		
		// Add struct containing distance and index to orderedDistances
		DistanceAndIndex distanceAndIndex;
		distanceAndIndex.distance = sqrtf(n*n + e*e);
		distanceAndIndex.index = i;
		[orderedDistances insertObject:[NSData dataWithBytes:&distanceAndIndex length:sizeof(distanceAndIndex)] atIndex:i++];
		
		[poi setDistance:distanceAndIndex.distance];
	}
	
	// Sort orderedDistances in ascending order based on distance from the user
	[orderedDistances sortUsingComparator:(NSComparator)^(NSData *a, NSData *b) {
		const DistanceAndIndex *aData = (const DistanceAndIndex *)a.bytes;
		const DistanceAndIndex *bData = (const DistanceAndIndex *)b.bytes;
		if (aData->distance < bData->distance) {
			return NSOrderedAscending;
		} else if (aData->distance > bData->distance) {
			return NSOrderedDescending;
		} else {
			return NSOrderedSame;
		}
	}];
	
	// Add subviews in descending Z-order so they overlap properly
	for (NSData *d in [orderedDistances reverseObjectEnumerator]) {
		const DistanceAndIndex *distanceAndIndex = (const DistanceAndIndex *)d.bytes;
		PlaceOfInterest *poi = (PlaceOfInterest *)[_placesOfInterest objectAtIndex:distanceAndIndex->index];
		[self.view addSubview:poi.view];
	}
	
	[self.view bringSubviewToFront:_toolbar];
}

#pragma mark - Location Manager
- (void)setupLocationManager
{
	_locationManager = [CoreLocationModule new];
	_locationManager.delegate = self;
	[_locationManager startLocation];
}

- (void)tearDownLocationManager
{
	[_locationManager stopLocation];
	_locationManager = nil;
}

- (void)locationDataReceived
{
	if (_placesOfInterest != nil)
		[self updatePlacesOfInterestCoordinates];
}

- (void)headingDataReceived
{
	if (!self.headingLabel.hidden)
		self.headingLabel.text = [NSString stringWithFormat:@"%f", _locationManager.currentHeading.trueHeading];
}

#pragma mark - Motion Manager
- (void)setupMotionManager
{
	_motionManager = [CoreMotionModule new];
	[_motionManager startDeviceMotion];
}

- (void)tearDownMotionManager
{
	[_motionManager stopDeviceMotion];
	_motionManager = nil;
}

#pragma mark - UI Actions
- (IBAction)takePicture:(id)sender
{
	// Find out the current orientation and tell the still image output.
	AVCaptureStillImageOutput *stillImageOutput = camera.stillImageOutput;
	AVCaptureConnection *stillImageConnection = [stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
	[stillImageConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
	
    // set the appropriate pixel format / image type output setting
	[stillImageOutput setOutputSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
																	forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
	
	[stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection
												  completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error)
	 {
		 if (error)
		 {
			 [self displayErrorOnMainQueue:error withMessage:@"Take picture failed"];
		 }
		 else
		 {
			 // Got an image.
			 CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(imageDataSampleBuffer);
			 CVPixelBufferLockBaseAddress(pixelBuffer, 0);
			 void* bufferAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
			 size_t bytesPerRow	= CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
			 size_t width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0);
			 size_t height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0);

/*			 CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, imageDataSampleBuffer, kCMAttachmentMode_ShouldPropagate);
			 CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer options:(NSDictionary *)attachments];
			 if (attachments)
				 CFRelease(attachments);
			 
			 NSDictionary *imageOptions = nil;
			 NSNumber *orientation = CMGetAttachment(imageDataSampleBuffer, kCGImagePropertyOrientation, NULL);
			 if (orientation) {
				 imageOptions = [NSDictionary dictionaryWithObject:orientation forKey:CIDetectorImageOrientation];
			 }
			 
			 // when processing an existing frame we want any new frames to be automatically dropped
			 // queueing this block to execute on the videoDataOutputQueue serial queue ensures this
			 // see the header doc for setSampleBufferDelegate:queue: for more information
			 dispatch_sync(videoDataOutputQueue, ^(void) {
				 
				 // get the array of CIFeature instances in the given image with a orientation passed in
				 // the detection will be done based on the orientation but the coordinates in the returned features will
				 // still be based on those of the image.
				 NSArray *features = [faceDetector featuresInImage:ciImage options:imageOptions];
				 CGImageRef srcImage = NULL;
				 OSStatus err = CreateCGImageFromCVPixelBuffer(CMSampleBufferGetImageBuffer(imageDataSampleBuffer), &srcImage);
				 check(!err);
				 
				 CGImageRef cgImageResult = [self newSquareOverlayedImageForFeatures:features
																		   inCGImage:srcImage
																	 withOrientation:curDeviceOrientation
																		 frontFacing:isUsingFrontFacingCamera];
				 if (srcImage)
					 CFRelease(srcImage);
				 
				 CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault,
																			 imageDataSampleBuffer,
																			 kCMAttachmentMode_ShouldPropagate);
				 [self writeCGImageToCameraRoll:cgImageResult withMetadata:(id)attachments];
				 if (attachments)
					 CFRelease(attachments);
				 if (cgImageResult)
					 CFRelease(cgImageResult);
				 
			 });
*/			 
			 cv::Mat image(height, width, CV_8UC1, bufferAddress, bytesPerRow);
			 [self processImage:image];
			 CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
		 }
	 }
	 ];
}

// utility routine to display error aleart if takePicture fails
- (void)displayErrorOnMainQueue:(NSError *)error withMessage:(NSString *)message
{
	dispatch_async(dispatch_get_main_queue(), ^(void) {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ (%d)", message, (int)[error code]]
															message:[error localizedDescription]
														   delegate:nil
												  cancelButtonTitle:@"Dismiss"
												  otherButtonTitles:nil];
		[alertView show];
	});
}

@end
