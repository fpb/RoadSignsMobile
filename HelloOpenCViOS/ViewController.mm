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
#import "Grid.h"
#import "Cell.h"
#import "Shaders.h"

#import <CoreVideo/CoreVideo.h>

// TODO: FUTURE WORK: Interpolate to predict to movement
// TODO: FUTURE WORK: What happens if we have moved more than one cell!!!!! Do not store the movement but update the position of the user??? (guess the movements) Iterate until we have all the movements done???

// Grid
using VectorGridCoordinates = std::vector<CLLocationCoordinate2D>;

const unsigned int kMaxVectorGridCoordinates = 5;
const unsigned int kMaxVectorGridMovements = 5;
const int kMinLife = -5;
const int kLifeDecrease = -1;
const int kLifeUser = 2;
const int kLifeAdjacents = 1;
//////////////////////////////////////////////////////////////////

BOOL setPois = YES;
const CGFloat minHorizontalAccuracy = 10.0f;

const BOOL showFPS = YES;
const BOOL showDistance = NO;
const BOOL showHeading = YES;

const CGFloat toolbarHeight = 44.0f;
const CGFloat screenHeight = 480.0f;
const CGFloat screenWithToolBar = (screenHeight - toolbarHeight) / screenHeight;


const float kMinDistnace = 10.0f;
const float kMaxDistnace = 500.0f;

const GLfloat texCoords[] =
{
	0,0,
	1,0,
	0,1,
	1,1
};

const GLfloat screenVerticesWithToolbar[] =
{
	// Full screen with toolbar. ToolbarHeight is double because of retina screen
	 1, 1,
	 1,-(screenHeight - toolbarHeight * 2) / screenHeight,
	-1, 1,
	-1,-(screenHeight - toolbarHeight * 2) / screenHeight
	
};

const GLfloat screenVertices[] =
{
// Full screen
	 1, 1,
	 1,-1,
	-1, 1,
	-1,-1
};

const GLushort indices[]  = {0, 1, 2, 3};

#define GRAD_THRESHOLD  150

//const float kGradThresholdSquare = GRAD_THRESHOLD * GRAD_THRESHOLD;

void drawShapes(const std::vector<Shape*> &shapes, cv::Mat &img)
{
    for(std::vector<Shape*>::const_iterator it = shapes.begin(); it!=shapes.end(); ++it)
        (*it)->drawOn(img);
}

@interface ViewController ()
{
	FramesPerSecond _fps;
	
	MyCamera *_camera;
	
    Shader _cameraShader;
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
	
	Grid* _grid;
	// Stores current and previous grid coordinates
	// Current user position is always at the end of the vector
	VectorGridCoordinates _userVectorGridCoordinates;
	// Stores the scores of the movements in order to predict the next movement
	VectorGridMovements _userVectorGridMovements;
	GridMovementScores _userGridMovementsScores[static_cast<int>(GridMovements::TotalPositions)];
	// Dictionary containing the image views of the signs loaded in the grid
	NSMutableDictionary *signImageViews;
	
	// Minigame 1
	BOOL _isMinigame1Running;
}

- (void)cleanUpTextures;
- (void)setupAVCapture;
- (void)tearDownAVCapture;

- (void)setupBuffers;
- (void)setupGL;
- (void)tearDownGL;

- (void)setupPois;
- (void)updatePlacesOfInterestCoordinates;
- (void)tearDownPois;

- (void)setupLocationManager;
- (void)tearDownLocationManager;

- (void)setupMotionManager;
- (void)tearDownMotionManager;

// Grid
- (void)setupGrid;
- (void)tearDownGrid;

- (void)addNewCells:(GridMovements const &)newMovement;
- (void)removeOldCells;
- (void)updateUserPosition;
@end


@implementation ViewController

@dynamic placesOfInterest;
@synthesize managedObjectContext = _managedObjectContext;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	[_loadingView setHidden:NO];
	[_loadingView startAnimating];
	
	[self showMinigame:NO];
	
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
	
	[self setupLocationManager];
	[self setupMotionManager];
	
	[_loadingView stopAnimating];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
	[self tearDownGrid];
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
	_fps.initFPS();
	
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
	_camera = [MyCamera new];
	
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
    
	_camera.delegate = self;
	[_camera startCameraPreviewWithPreset:sessionPreset];
	
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
	
	[_camera stopCameraPreview];
	_camera = nil;
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
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat) << 3, screenVertices, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(static_cast<int>(Attributes::ATTRIB_VERTEX));
    glVertexAttribPointer(static_cast<int>(Attributes::ATTRIB_VERTEX), 2, GL_FLOAT, GL_FALSE, 0, 0);
	
    glGenBuffers(1, &_texcoordVBO);
    glBindBuffer(GL_ARRAY_BUFFER, _texcoordVBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat) << 3, texCoords, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(static_cast<int>(Attributes::ATTRIB_TEXCOORD));
	glVertexAttribPointer(static_cast<int>(Attributes::ATTRIB_TEXCOORD), 2, GL_FLOAT, GL_FALSE, 0, 0);
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
    
	_cameraShader.LoadShaders([[[NSBundle mainBundle] pathForResource:@"YUVShader" ofType:@"vsh"] UTF8String],
							  [[[NSBundle mainBundle] pathForResource:@"YUVShader" ofType:@"fsh"] UTF8String]);
    
    glUseProgram(_cameraShader.GetProgram());
	
    glUniform1i(uniforms[static_cast<int>(Uniforms::UNIFORM_Y) ], 0);
    glUniform1i(uniforms[static_cast<int>(Uniforms::UNIFORM_UV)], 1);
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:_context];
    
    glDeleteBuffers(1, &_positionVBO);
    glDeleteBuffers(1, &_texcoordVBO);
    glDeleteBuffers(1, &_indexVBO);
    	
	if ([EAGLContext currentContext] == _context)
        [EAGLContext setCurrentContext:nil];
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
		_fpsLabel.text = [NSString stringWithFormat:@"%.2f fps", _fps.CalculateFPS()];
}

#pragma mark - GLKView delegate
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
	if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationFaceUp)
	{
		//face up
		glClear(GL_COLOR_BUFFER_BIT);
		
		glDrawElements(GL_TRIANGLE_STRIP, 4, GL_UNSIGNED_SHORT, 0);
		
		[_camera stopRunning];
	}
	else
	{
		if (![_camera isRunning])
		{
			[_camera startRunning];
		}
		
		glClear(GL_COLOR_BUFFER_BIT);
		
		glDrawElements(GL_TRIANGLE_STRIP, 4, GL_UNSIGNED_SHORT, 0);
		
		if (_placesOfInterestCoordinates == nil)
			return;
		
		mat4f_t projectionCameraTransform;
		multiplyMatrixAndMatrix(projectionCameraTransform, _projectionTransform, _cameraTransform);
		
		int i = 0;
		[self resetPoiIntersection];
		for (PlaceOfInterest *poi in _placesOfInterest)
		{
			vec4f_t v;
			multiplyMatrixAndVector(v, projectionCameraTransform, _placesOfInterestCoordinates[i]);
			
			float x = (v[0] / v[3] + 1.0f) * 0.5f;
			float y = (v[1] / v[3] + 1.0f) * 0.5f;
			
			if (v[2] < 0.0f)
			{
				CGRect bounds = self.view.bounds;
				[poi setViewsCenter:CGPointMake(x*bounds.size.width, bounds.size.height-y*bounds.size.height)];
				//			poi.view.backgroundColor = [UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:0.5f];
				float scale = 1.0f - ([poi distance] - kMinDistnace) / (kMaxDistnace - kMinDistnace);
				CGAffineTransform transform = CGAffineTransformMakeScale(scale, scale);
				[poi transformViews:CGAffineTransformRotate(transform, _deviceYrotation)];
				
				[poi setViewsHidden:NO];
				[self checkPoiIntersection:poi];
				//			if (/*[poi distance] < kMaxDistnace &&*/ [[poi views] count] == 2)
				//			{
				
				//				if (_locationManager.currentHeading.trueHeading < (poi.face - 90.0) && _locationManager.currentHeading.trueHeading > (poi.face + 90.0))
				//					poi.view.backgroundColor = [UIColor colorWithRed:0.0f green:1.0f blue:0.0f alpha:0.5f];
				//				if (x < 0.0f || x > 1.0f)
				//					poi.view.backgroundColor = [UIColor colorWithRed:1.0f green:0.0f blue:0.0f alpha:0.5f];
				//				if (y < 1.0f - screenWithToolBar || y > 1.0f)
				//					poi.view.backgroundColor = [UIColor colorWithRed:1.0f green:0.0f blue:0.0f alpha:0.5f];
				//			}
				//			else
				//				[poi setViewsHidden:YES];
			}
			else
			{
				[poi setViewsHidden:YES];
			}
			++i;
		}
	}
	//	// Distance to closest sign
	//	if (!_distanceLabel.hidden)
	//		_distanceLabel.text = [NSString stringWithFormat:@"%f", distance];
}

#pragma mark - Grid
- (void)setupGrid
{
	// Users current location
	CLLocationCoordinate2D myLocation = _locationManager.bestLocation.coordinate;
	//	NSLog(@"Latitude: %f\tLongitude: %f", myLocation.coordinate.latitude, myLocation.coordinate.longitude);
	
	///////////////////////////////////////////////////////
	// Initialize the grid
	///////////////////////////////////////////////////////
	_grid = [Grid new];
	[_grid setCellSize:kMinCellSize]; // Minimum cell size
	double distance = [_grid cellSize];
	
	// User cell is the center cell
	CLLocationCoordinate2D center = CLLocationCoordinate2DMake(getDoubleRounded(myLocation.latitude, getDecimalPlaces(distance)),
															   getDoubleRounded(myLocation.longitude, getDecimalPlaces(distance)));
	_userVectorGridCoordinates.push_back(center);

	// TODO: Fill another level of cells????
	for (GridMovements i = GridMovements::InitialPosition; i < GridMovements::TotalPositions; ++i)
	{
		// get all cells around the user position and the user's position cell
		CLLocationCoordinate2D newCellId = [_grid getNewCellIdsFromMovement:i andCellId:center];
				
		// Fetch sign inside the cell
		NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"(latitude => %f) AND (latitude < %f) AND (longitude => %f) AND (longitude < %f)",
									   newCellId.latitude, newCellId.latitude + distance, newCellId.longitude, newCellId.longitude + distance];
		NSArray *results = FetchResultsFromEntitywithPredicate(self.managedObjectContext, @"Location", fetchPredicate, nil);
		
		Cell* cell = [[Cell alloc] initWithCellId:newCellId];
		if ([results count] > 0)
		{
			// Get signs and locations that pertain to the current cell
			//			for (Location *l in filteredArray)
			//			{
			//				NSLog(@"Latitude: %f\tLongitude: %f", [l.latitude doubleValue], [l.longitude doubleValue]);
			//			}
			// Fill the Cell
			for (Location *l in results)
			{
				//					NSLog(@"Latitude: %f\tLongitude: %f", [l.latitude doubleValue], [l.longitude doubleValue]);
				
				// Get RoadSigns in this location
				NSArray *roadSigns = [l.roadsigns allObjects];
				CellElement *element = [[CellElement alloc] initWithSignId:[roadSigns valueForKey:@"name"]
															  withLatitude:[l.latitude doubleValue]
															  andLongitude:[l.longitude doubleValue]
															   andFacingTo:[l.face floatValue]];
				[cell addElement:element];
				
				for (RoadSign *r in roadSigns)
				{
					if ([signImageViews objectForKey:r.name] == nil)
					{
						UIImage *image = [UIImage imageNamed:r.imageUrl];
						[signImageViews setObject:image forKey:r.name];
					}
				}
			}
		}
		
		NSString *key = [NSString stringWithFormat:@"%f,%f", newCellId.latitude, newCellId.longitude];
		NSLog(@"%@", key);
		[_grid setCell:cell forKey:key];
		cell = nil;
	}
	///////////////////////////////////////////////////////
	// End of grid initialization
	///////////////////////////////////////////////////////
}

- (void)tearDownGrid
{
	_grid = nil;
}

// Add cells next to the user position
- (void)addNewCells:(GridMovements const &)newMovement
{	
	// User's position
	CLLocationCoordinate2D userCellId = _userVectorGridCoordinates.back();
	
	float distance = [_grid cellSize];
	
	// Add cells around the user cell
	for (GridMovements i = GridMovements::InitialPosition; i < GridMovements::TotalPositions; ++i)
	{
		CLLocationCoordinate2D newCellId = [_grid getNewCellIdsFromMovement:i andCellId:userCellId];
		
		NSString *key = [NSString stringWithFormat:@"%f,%f", newCellId.latitude, newCellId.longitude];
		Cell *oldCell = [_grid getCellFromKey:key];
		
		if (oldCell) // This cell already exists
			continue;
		
		// Cell does not exist. Create it.
		Cell* cell = [[Cell alloc] initWithCellId:newCellId];
		
		
		NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"(latitude => %f) AND (latitude < %f) AND (longitude => %f) AND (longitude < %f)",
									   newCellId.latitude, newCellId.latitude + distance, newCellId.longitude, newCellId.longitude + distance];
		NSArray *results = FetchResultsFromEntitywithPredicate(self.managedObjectContext, @"Location", fetchPredicate, nil);
		
		if ([results count] > 0)
		{
			// Fill the Cell
			for (Location *l in results)
			{
				// Get RoadSigns in this location
				NSArray *roadSigns = [[l.roadsigns allObjects] valueForKey:@"name"];
				CellElement *element = [[CellElement alloc] initWithSignId:roadSigns
															  withLatitude:[l.latitude doubleValue]
															  andLongitude:[l.longitude doubleValue]
															   andFacingTo:[l.face floatValue]];
				[cell addElement:element];
			}
		}
		
		NSLog(@"%@", key);
		[_grid setCell:cell forKey:key];
		cell = nil;
	}
	
	// Add cells based on the prediction movement
	// Get the 5 movements with higher scores
	VectorGridMovements futureMovements = [self getFavoriteMovements];
	// Get cellId based on a movement
	GridMovements maxMovement = *(std::max_element(futureMovements.begin(), futureMovements.end()));
	CLLocationCoordinate2D movementCellId = [_grid getNewCellIdsFromMovement:maxMovement andCellId:userCellId];
	// Add cells for those 5 movements
	for (VectorGridMovements::iterator it = futureMovements.begin(); it != futureMovements.end(); ++it)
	{
		
		CLLocationCoordinate2D newCellId = [_grid getNewCellIdsFromMovement:*it andCellId:movementCellId];
		NSString *key = [NSString stringWithFormat:@"%f,%f", newCellId.latitude, newCellId.longitude];
		Cell *oldCell = [_grid getCellFromKey:key];
		
		if (oldCell) // This cell already exists
			continue;
		
		// Cell does not exist. Create it.
		Cell* cell = [[Cell alloc] initWithCellId:newCellId];
		
		
		NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"(latitude => %f) AND (latitude < %f) AND (longitude => %f) AND (longitude < %f)",
									   newCellId.latitude, newCellId.latitude + distance, newCellId.longitude, newCellId.longitude + distance];
		NSArray *results = FetchResultsFromEntitywithPredicate(self.managedObjectContext, @"Location", fetchPredicate, nil);
		
		if ([results count] > 0)
		{
			// Fill the Cell
			for (Location *l in results)
			{
				// Get RoadSigns in this location
				NSArray *roadSigns = [[l.roadsigns allObjects] valueForKey:@"name"];
				CellElement *element = [[CellElement alloc] initWithSignId:roadSigns
															  withLatitude:[l.latitude doubleValue]
															  andLongitude:[l.longitude doubleValue]
															   andFacingTo:[l.face floatValue]];
				[cell addElement:element];
			}
		}
		
		NSLog(@"%@", key);
		[_grid setCell:cell forKey:key];
		cell = nil;
	}
	
	[self removeOldCells];
}


- (void)updateCellsLife:(CLLocationCoordinate2D)cellId
{
	NSArray *userCells = [_grid getCenterCellAndCellsAroundFromCellId:cellId];
//	NSArray *adjacents;
	
	// Decrease life of every cell with the exception of the user cell and the adjacent cells
	for (Cell *c in _grid.grid)
	{
		if ([userCells containsObject:c])
		{
			[c updateLife:kLifeUser];
//			if (c == [userCells objectAtIndex:static_cast<int>(GridMovements::Center)])
//			{
//				[c updateLife:kLifeUser];
//			}
//			else if ([adjacents containsObject:c])
//			{
//				[c updateLife:kLifeAdjacents];
//			}
//			// else life does not change
		}
		else
			[c updateLife:kLifeDecrease];
	}
}

// Removes the old cells
- (void)removeOldCells
{
	// Only remove cells when memory is full
	NSArray *allCells = [_grid.grid allValues];
	bool condition = [allCells count] > _grid.maxCellsInMemory;
	if (condition)
	{
		NSSortDescriptor *lifeDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"life" ascending:NO];
		NSArray *sortDescriptors = [NSArray arrayWithObject:lifeDescriptor];
		NSMutableArray *sortedArray = [NSMutableArray arrayWithArray:[allCells sortedArrayUsingDescriptors:sortDescriptors]];
		
		// Cells adjacent to the user and user cell
		NSArray * adjacentCells = [_grid getCenterCellAndCellsAroundFromCellId:_userVectorGridCoordinates.back()];
		[sortedArray removeObjectsInArray:adjacentCells];
		
		// Delete cells with less life
		while ((condition) && ([sortedArray count] > 0))
		{
			// Check that the cells we are going to delete are not adjacent to the user cell
			CLLocationCoordinate2D cellId = ((Cell*)[sortedArray objectAtIndex:0]).cellId;
			[_grid.grid removeObjectForKey:[NSString stringWithFormat:@"%f,%f", cellId.latitude, cellId.longitude]];
			[sortedArray removeObjectAtIndex:0];
		}
	}
}

- (void)updateUserPosition
{
	double distance = [_grid cellSize];
	
	CLLocationCoordinate2D lastUserCellId = _userVectorGridCoordinates.back();

	CLLocationCoordinate2D myLocation = _locationManager.bestLocation.coordinate;
	CLLocationCoordinate2D currentUserCellId = CLLocationCoordinate2DMake(getDoubleRounded(myLocation.latitude, getDecimalPlaces(distance)),
																		  getDoubleRounded(myLocation.longitude, getDecimalPlaces(distance)));
	
	// If we have moved to a new cell...
	GridMovements newMovement = [_grid getMovementFromPreviousCellId:lastUserCellId toNewCellId:currentUserCellId];
	if (newMovement != GridMovements::Center)
	{
		_userVectorGridCoordinates.push_back(currentUserCellId);
		// If we have more than the max elements, remove the oldest one
		if (_userVectorGridCoordinates.size() > kMaxVectorGridCoordinates)
		{
			_userVectorGridCoordinates.erase(_userVectorGridCoordinates.begin());
		}
		
		[self updateMovementPrediction:newMovement];
		// Add new cells near to the user position
		[self addNewCells:newMovement];
		// Add life to cells around the user and the user cell
		[self updateCellsLife:currentUserCellId];
		// Load cells around the user position into pois
		// TODO: FUTURE WORK: Load only new pois and delete only new pois
		[self setupPois];
	}

//	NSLog(@"My grid position:%d,%d", myGridRowIndex, myGridColumnIndex);

}

// Update the scores of the movements
- (void)updateMovementPrediction:(GridMovements)lastMovement
{
	_userVectorGridMovements.push_back(lastMovement);
	if (_userVectorGridMovements.size() > 5)
	{
		_userVectorGridMovements.erase(_userVectorGridMovements.begin());
	}
	
	VectorGridMovements adjacents = getAdjacentMovementsFromMovement(lastMovement);
	for (GridMovements i = GridMovements::InitialPosition; i < GridMovements::TotalPositions; ++i)
	{
		VectorGridMovements::iterator it = std::find(adjacents.begin(), adjacents.end(), i);
		if (i == lastMovement)
			_userGridMovementsScores[static_cast<int>(i)].second += 4;
		else if (it != adjacents.end())
			_userGridMovementsScores[static_cast<int>(i)].second += 2;
		else
			_userGridMovementsScores[static_cast<int>(i)].second -= 1;
	}
	
	// TODO: Reset movement scores that are not in the vector????
}

- (VectorGridMovements)getFavoriteMovements
{
	std::vector<GridMovementScores> sortedMovementScores(_userGridMovementsScores, _userGridMovementsScores + static_cast<int>(GridMovements::TotalPositions));
	
	std::sort(sortedMovementScores.begin(), sortedMovementScores.end(),
			  [](const GridMovementScores &s1, const GridMovementScores &s2) -> bool { return s1.second > s2.second; });
	
	VectorGridMovements favoriteMovements;
	favoriteMovements.reserve(5);
	favoriteMovements.push_back(sortedMovementScores.at(0).first);
	favoriteMovements.push_back(sortedMovementScores.at(1).first);
	favoriteMovements.push_back(sortedMovementScores.at(2).first);
	favoriteMovements.push_back(sortedMovementScores.at(3).first);
	favoriteMovements.push_back(sortedMovementScores.at(4).first);
	
	return favoriteMovements;
}

#pragma mark - Places of Interest
- (void)setupPois
{
	// PlacesOfInterest is filled from the cells around the user's position and the user's position cell
	// 1) Get user cell and cells around the user
	CLLocationCoordinate2D userCoords = _userVectorGridCoordinates.back();
	NSArray *cells = [_grid getCenterCellAndCellsAroundFromCellId:userCoords];
	
	// 2) Add the locations to the pois array
	NSMutableArray *placesOfInterest = [NSMutableArray arrayWithCapacity:[cells count]];
	int i = 0;
	for (Cell *c in cells)
	{
		NSArray *cellElements = [c cellElements];
				
		for (CellElement *e in [cellElements reverseObjectEnumerator])
		{
//			NSArray *roadSigns = [e signIds];
//			UILabel *label = [UILabel new];
//			label.adjustsFontSizeToFitWidth = NO;
//			label.opaque = NO;
//			label.backgroundColor = [UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:0.5f];
//			label.center = CGPointMake(200.0f, 200.0f);
//			label.textAlignment = NSTextAlignmentCenter;
//			label.textColor = [UIColor whiteColor];
//			label.text = [roadSigns componentsJoinedByString:@"/"];
//			CGSize size = [label.text sizeWithFont:label.font];
//			label.bounds = CGRectMake(0.0f, 0.0f, size.width, size.height);
			PlaceOfInterest *poi = [PlaceOfInterest placeOfInterestWithViews:[signImageViews objectsForKeys:[e signIds] notFoundMarker:[NSNull null]]
																		 at:[[CLLocation alloc] initWithLatitude:[e latitude]
																									   longitude:[e longitude]]
																   facingAt:[e facing]];
			[placesOfInterest insertObject:poi atIndex:i++];
		}
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
		[poi removeFromSuperview];
	
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
		for (UIView *view in poi.views)
		{
			[self.view addSubview:view];
		}
	}
	
	[self.view bringSubviewToFront:_toolbar];
}

- (void)resetPoiIntersection
{
	NSMutableArray *pois = [NSMutableArray arrayWithArray:[[self view] subviews]];
	
	for (UIView *poiView in pois)
	{
		if ([poiView isKindOfClass:[UIImageView class]])
		{
			((UIImageView*)poiView).highlighted = NO;
		}
		//		else
		//		{
		//			[pois removeObject:poiView];
		//		}
	}
}

- (void)checkPoiIntersection:(PlaceOfInterest*)aPoi
{
	NSArray *views = [[self view] subviews];
	
	for (PlaceOfInterest *poi in _placesOfInterest)
	{
		for (UIImageView *poiViewA in poi.views)
		{
			if (![poiViewA isHidden])
			{
				for (UIImageView *poiViewB in aPoi.views)
				{
					if (poiViewA != poiViewB && ![aPoi.views containsObject:poiViewA] && CGRectIntersectsRect([poiViewA frame], [poiViewB frame]))
					{
						NSUInteger indexA = [views indexOfObject:poiViewA];
						NSUInteger indexB = [views indexOfObject:poiViewB];
						
						if (indexA > indexB)
						{
							for (UIImageView *poiView in aPoi.views)
								poiView.highlighted = YES;
						}
						else
						{
							for (UIImageView *poiView in poi.views)
								poiView.highlighted = YES;
						}
					}
				}
			}
		}
	}
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
	if (setPois)
	{
		[_loadingView setHidden:NO];
		[_loadingView startAnimating];
		[_warningLabel setHidden:NO];

		if (_locationManager.bestLocation.horizontalAccuracy <= minHorizontalAccuracy)
		{
			setPois = NO;
			signImageViews = [NSMutableDictionary new];
			[self setupGrid];
			[self setupPois];
			[_warningLabel setHidden:YES];
			[_loadingView stopAnimating];
		}
	}

	if (_placesOfInterest != nil)
		[self updatePlacesOfInterestCoordinates];
	
	if (_grid)
	{
		[self updateUserPosition];
	}
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
	// Save sensor data
	CLLocation *stillImageLocation = _locationManager.bestLocation; // bestLocation contains the best last location.
	
	// Find out the current orientation and tell the still image output.
	AVCaptureStillImageOutput *stillImageOutput = _camera.stillImageOutput;
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
			 
			 // If processImage fails we should relay on sensor data
			 // TODO: implement sensor data "recognition" !!!!!!!
		 }
	 }
	 ];
}

#pragma mark - Utilities
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


#pragma mark - Minigame 1
- (void)setupMinigame:(NSString*) sign
{
	NSArray *result = FetchResultsFromEntitywithPredicate(_managedObjectContext, @"RoadSign", [NSPredicate predicateWithFormat:@"name == %@", sign], nil);
	if ([result count] > 0)
	{
		RoadSign *r = [result objectAtIndex:0];
		NSLog(@"RoadSign: %@", r.name);
		_minigameLabel.text = @"Probando...";//r.desc;
	}
}

- (void)showMinigame:(BOOL)show
{
	_isMinigame1Running = show;
	
	if (_isMinigame1Running)
	{
		glBindBuffer(GL_ARRAY_BUFFER, _positionVBO);
		glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat) << 3, screenVerticesWithToolbar, GL_STATIC_DRAW);
		_toolbar.hidden = NO;
		_minigameLabel.hidden = NO;
		_pictureButton.enabled = YES;
		[self setupMinigame:@"Give way"];
	}
	else
	{
		glBindBuffer(GL_ARRAY_BUFFER, _positionVBO);
		glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat) << 3, screenVertices, GL_STATIC_DRAW);
		_toolbar.hidden = YES;
		_minigameLabel.hidden = YES;
		_pictureButton.enabled = NO;
	}
}

#if defined(DEBUG)
- (IBAction)minigamePressButton:(UIButton *)sender
{
	_isMinigame1Running = !_isMinigame1Running;
	[self showMinigame:_isMinigame1Running];
}
#endif

@end
