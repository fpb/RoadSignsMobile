 //
//  FPS.mm
//  HelloOpenCViOS
//
//  Created by David on 29/04/13.
//  Copyright (c) 2013 FCT/UNL. All rights reserved.
//

#include "FPS.h"
#include <sys/time.h>

const double kUSecond = 0.000001;

float FramesPerSecond::CalculateFPS(void)
{
    timeval interval;
	
	++frames;
	
	if (!currentTime)
	{
		gettimeofday(&interval, NULL);
		currentTime = interval.tv_sec + interval.tv_usec * kUSecond;
	}

	lastTime = currentTime;
	
	gettimeofday(&interval, NULL);
	currentTime = interval.tv_sec + interval.tv_usec * kUSecond;
	
	double elapsedTime = currentTime - lastTime;

	return 1.0 / elapsedTime;
	
//	timeInterval += elapsedTime;
//	if (timeInterval >= 1.0)
//	{
//		fps = frames / timeInterval;
//		frames = 0.0;
//		
//		while(timeInterval >= 1.0)
//			timeInterval -= 1.0;
//	}
//	
//	return fps;
}
