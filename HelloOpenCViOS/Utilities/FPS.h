//
//  FPS.h
//  HelloOpenCViOS
//
//  Created by David on 29/04/13.
//  Copyright (c) 2013 FCT/UNL. All rights reserved.
//

#pragma once

class FramesPerSecond
{
	double fps = 0.0, frames = 0.0;
	double currentTime = 0.0, lastTime = 0.0, timeInterval = 0.0;
	
public:
	void initFPS(void);
	float CalculateFPS(void);
};
