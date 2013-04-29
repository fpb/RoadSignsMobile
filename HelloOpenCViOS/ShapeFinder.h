//
//  ShapeFinder.h
//  HelloOpenCViOS
//
//  Created by Fernando Birra on 4/17/13.
//  Copyright (c) 2013 FCT/UNL. All rights reserved.
//

#ifndef HelloOpenCViOS_ShapeFinder_h
#define HelloOpenCViOS_ShapeFinder_h


#include <iostream>
#include <opencv2/opencv.hpp>

#include "Shapes.h"

void computeGradients(cv::Mat input, cv::Mat &gx, cv::Mat &gy, cv::Mat &mag);
void normalizeFloatImage(cv::Mat &img);

class ShapeFinder {
public:
    ShapeFinder(cv::Mat &img) : img(img), r(img.rows), c(img.cols) {};
    
    virtual ~ShapeFinder() {};
    
    void prepare(double threshold);
    std::vector<Shape*> findShape(int nsides, const std::vector<int> &rs);
    
    const cv::Mat &getScalarGradient() const { return mag; }
    const cv::Mat &getS() const { return nS; }
    
protected:
    void computeGradients(double threshold);
    
private:
    int r, c;
    cv::Mat &img;
    cv::Mat gx, gy, mag;
    cv::Mat S;
    cv::Mat nS;
    
    std::vector<Shape*> findCircles(const std::vector<int> &rs);
    std::vector<Shape*> findPolygons(int nsides, const std::vector<int> &rs);
};


#endif
