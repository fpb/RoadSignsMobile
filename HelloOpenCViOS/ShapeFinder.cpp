//
//  ShapeFinder.cpp
//  HelloOpenCViOS
//
//  Created by Fernando Birra on 4/17/13.
//  Copyright (c) 2013 FCT/UNL. All rights reserved.
//

double maxV=0.0;
bool debug_mode = false;

#include "ShapeFinder.h"

float radius_value(int nsides, float length)
{
    switch(nsides) {
        case 3: return (float) sqrt(3.0f)*length/6.0f;
        default: return length/2.0f;
    }
}


// Inputs:
//      input: Input grayscale image
//      threshold: threshold value to consider. Gradient values below will produce black pixels
// Outputs:
//      gx: floating point image with normalized x-coordinate component of the gradient image
//      gy: floating point image with normalized y-coordinate component of the gradient image
//      mag: floatinh point image with gradient magnitude (non normalized)

void computeGradients(cv::Mat input, cv::Mat &gx, cv::Mat &gy, cv::Mat &mag, double threshold)
{
    cv::Mat workImg = cv::Mat(input);
    workImg = input.clone();
    
    
    cv::Mat magX = cv::Mat(input.rows, input.cols, CV_32F);
    cv::Mat magY = cv::Mat(input.rows, input.cols, CV_32F);
    cv::Sobel(workImg, magX, CV_32F, 1, 0, 3);
    cv::Sobel(workImg, magY, CV_32F, 0, 1, 3);
    
    for(int i=0; i<input.rows; i++)
        for(int j=0; j<input.cols; j++) {
            float mx = magX.at<float>(i,j);
            float my = magY.at<float>(i,j);
            float mg = (float)::sqrt(mx*mx + my*my);
            if(mg < threshold) {
                mag.at<float>(i,j) = gx.at<float>(i,j) = gy.at<float>(i,j) = 0.0f;
            }
            else {
                mx /= mg; my /= mg;
                mag.at<float>(i,j) = mg;
                gx.at<float>(i,j) = mx;
                gy.at<float>(i,j) = my;
            }
        }
}

void normalizeFloatImage(cv::Mat &img)
{
    double max;
    
    cv::minMaxLoc(img, NULL, &max);
    img *= 1.0f/max;
}



void ShapeFinder::computeGradients(double grad_threshold)
{
    gx = cv::Mat(r,c,CV_32F);
    gy = cv::Mat(r,c,CV_32F);
    mag = cv::Mat(r,c,CV_32F);
    
    ::computeGradients(img, gx, gy, mag, grad_threshold);
    ::normalizeFloatImage(mag);
}

void ShapeFinder::prepare(double threshold)
{
    S = cv::Mat::zeros(r,c,CV_32F);
    
    if(debug_mode)  nS = S;
    
    computeGradients(threshold);
}

std::vector<Shape*> ShapeFinder::findCircles(const std::vector<int> &sizes)
{
    std::vector<float> radiuses;
    std::vector<Shape*> res;
    std::vector<cv::Mat*> Sn;
    
    S = cv::Mat::zeros(r,c,CV_32F);
    
    double single_threshold = 0.3;
    double overall_threshold = single_threshold / sizes.size();
    
    for(std::vector<int>::const_iterator it=sizes.begin(); it!=sizes.end(); it++) {
        radiuses.push_back(radius_value(0,*it));
    }
    
    for(std::vector<float>::const_iterator it = radiuses.begin(); it!=radiuses.end(); it++)
    {
        // Create and zero O_r - vote image for current radius value
        cv::Mat *O_r = new cv::Mat;
        *O_r = cv::Mat::zeros(r,c,CV_32F);
        
        // Current radius being considered
        int radius = *it;
        
        // Maximum value for individual votes. Anything above will be clamped
        float kn = (float) sqrt(radius)/0.1f;
        
        float *ptr_gx = (float*) gx.data;
        float *ptr_gy = (float*) gy.data;
        
        // Process each pixel in the image
        for(int i=0; i<r; i++) {
            for(int j=0; j<c; j++) {
                float gpx = radius * (*ptr_gx++); //gx.at<float>(i,j)*radius;
                float gpy = radius * (*ptr_gy++); //gy.at<float>(i,j)*radius;
                
                // Follow positive gradient at a "radius" distance
                int pvex = j + gpx;
                int pvey = i + gpy;
                
                // Only consider center points inside the image and cast a new vote
                if(pvex >= 0 && pvex < c && pvey >=0 && pvey < r) {
                    O_r->at<float>(pvey,pvex) += 1.0f;
                }
                
                // Follow negative gradient at a "radius" distance
                pvex -= 2*gpx;
                pvey -= 2*gpy;
                
                // Only consider center points inside the image and cast a new vote
                if(pvex >= 0 && pvex < c && pvey >=0 && pvey < r) {
                    O_r->at<float>(pvey,pvex) += 1.0f;
                }
            }
        }
        
        // Clamp all values above the computed maximum threshold
        cv::threshold(*O_r, *O_r, kn, 0, cv::THRESH_TRUNC);
        
        // Scale the vote image to the [0-1] range
        *O_r /= kn;
        
        // TODO: Put the 1 value as a parameter in a config file
        cv::pow(*O_r, 1, *O_r);
        
        // Blur it...
        cv::GaussianBlur(*O_r, *O_r, cv::Size(3,3), 0, 0);
        
        // Put the vote image in a vector
        Sn.push_back(O_r);
    }
    
    // Accumulate Sn images into S and compute the mean
    for(int radius=0; radius<radiuses.size(); radius++)
        S += *(Sn.at(radius));
    S /= radiuses.size();
    
    // Compute the maximum value
    double m;
    cv::minMaxLoc(S, NULL, &m);
    
    if(debug_mode) {
        nS = S.clone();
        nS /= m;
        if(m>maxV) maxV = m;
        
        std::ostringstream ss;
        ss << "Radius = " << radiuses.at(0) << " " << "Max=" << m << "(" << maxV << ")";
        std::string s(ss.str());
        putText(nS, s, cvPoint(10,30),
                cv::FONT_HERSHEY_SIMPLEX, 0.4, cvScalar(200), 1, CV_AA);
    }
    
    // Check final S image for white spots
    for(int i=0; i<r; i++) {
        for(int j=0; j<c; j++) {
            if(S.at<float>(i,j)>overall_threshold) {    // White spot in mean image...
                
                // Check individual images to overule false positives
                int k=0;
                for(k=0; k<Sn.size() && Sn.at(k)->at<float>(i,j)<single_threshold; k++);
                if(k<Sn.size()) {
                    float rad = radiuses.at(k);
                    float siz = sizes.at(k);
                    cv::rectangle(S, cv::Point(j-siz/2,i-siz/2), cv::Point(j+siz/2,i+siz/2), cv::Scalar(0.0), -1);
                    res.push_back(new Circle(j,i,round(rad),siz));
                }
            }
        }
    }
    // Free all Sn images in the end
    for(std::vector<cv::Mat*>::iterator it=Sn.begin(); it!=Sn.end(); it++)
        delete *it;
    
    return res;
}


void vote(const cv::Point &a, const cv::Point &b, float weight, float vx, float vy, cv::Mat &vote_img, cv::Mat &brx, cv::Mat &bry )
{
    cv::LineIterator it_votes(vote_img, a, b, 8);
    cv::LineIterator it_brx(brx, a, b, 8);
    cv::LineIterator it_bry(bry, a, b, 8);
    
    for(int i=0; i<it_votes.count; i++, ++it_votes, ++it_brx, ++it_bry) {
        float *vote_ptr = (float *)(*it_votes);
        (*vote_ptr) += weight;
        float *brx_ptr = (float*) (*it_brx);
        float *bry_ptr = (float*) (*it_bry);
        
        (*brx_ptr) += (weight*vx);
        (*bry_ptr) += (weight*vy);
    }
}

std::vector<Shape*> ShapeFinder::findPolygons(int nsides, const std::vector<int> &sizes)
{
    std::vector<float> radiuses;
    std::vector<Shape*> res;
    std::vector<cv::Mat*> Sn;
    
    for(std::vector<int>::const_iterator it=sizes.begin(); it!=sizes.end(); it++) {
        radiuses.push_back(radius_value(nsides,*it));
    }
    
    S = cv::Mat::zeros(r,c,CV_32F);
    
    double single_threshold = 15.0/(nsides+1);
    double overall_threshold = single_threshold / radiuses.size();
    
    for(std::vector<float>::const_iterator it = radiuses.begin(); it!=radiuses.end(); it++) {
        cv::Mat *O_r = new cv::Mat; *O_r = cv::Mat::zeros(r,c,CV_32F);
        cv::Mat brx = cv::Mat::zeros(r,c,CV_32F);
        cv::Mat bry = cv::Mat::zeros(r,c,CV_32F);
        cv::Mat magn = cv::Mat::zeros(r, c, CV_32F);
        
        float radius = *it;
        float w = (float) round(radius * tan(M_PI/nsides));
        
        float *ptr_gx = (float *) gx.data;
        float *ptr_gy = (float *) gy.data;
        
        for(int i=0; i<r; i++) {
            for(int j=0; j<c; j++) {
                float g_x = *ptr_gx++;  //gx.at<float>(i,j);
                float g_y = *ptr_gy++;  //gy.at<float>(i,j);
                float l_x = -g_y;
                float l_y = g_x;
                
                float theta = atan2(g_y, g_x);
                float gamma = nsides * theta;
                
                float vx = (float)cos(gamma);
                float vy = (float)sin(gamma);
                
                // Compute center of each line of votes
                cv::Point c1 = cv::Point(j + g_x * radius, i + g_y * radius);
                cv::Point c2 = cv::Point(j - g_x * radius, i - g_y * radius);
                
                cv::Point a1 = cv::Point( c1.x - l_x * w, c1.y - l_y * w); cv::Point a_1 = cv::Point( c1.x - l_x * 2*w, c1.y - l_y * 2*w );
                cv::Point b1 = cv::Point( c1.x + l_x * w, c1.y + l_y * w); cv::Point b_1 = cv::Point( c1.x + l_x * 2*w, c1.y + l_y * 2*w );
                
                cv::Point a2 = cv::Point( c2.x - l_x * w, c2.y - l_y * w); cv::Point a_2 = cv::Point( c2.x - l_x * 2*w, c2.y - l_y * 2*w );
                cv::Point b2 = cv::Point( c2.x + l_x * w, c2.y + l_y * w); cv::Point b_2 = cv::Point( c2.x + l_x * 2*w, c2.y + l_y * 2*w );
                
                // Paint lines (a1, b1) and (a2, b2)
                vote(a1, b1, 1.0f, vx, vy, *O_r, brx, bry);
                vote(a2, b2, 1.0f, vx, vy, *O_r, brx, bry);
                
                vote(a_1, a1, -1.0f, vx, vy, *O_r, brx, bry);
                vote(b1, b_1, -1.0f, vx, vy, *O_r, brx, bry);
                vote(a_2, a2, -1.0f, vx, vy, *O_r, brx, bry);
                vote(b2, b_2, -1.0f, vx, vy, *O_r, brx, bry);
            }
        }
        
        cv::accumulateSquare(brx, magn);
        cv::accumulateSquare( bry, magn );
        cv::sqrt( magn, magn );//Magnitude of equiangular image
        cv::multiply(*O_r, magn, *O_r);//Or.||Br||«
        
        // clamp values below 0
        cv::threshold(*O_r, *O_r, 0, 0, cv::THRESH_TOZERO);
        
        cv::sqrt(*O_r, *O_r);
        *O_r /= radius;
        
        //*O_r = magn;
        cv::GaussianBlur(*O_r, *O_r, cv::Size(3,3), 0, 0);
        Sn.push_back(O_r);
    }
    // Accumulate Sn images into S
    for(int radius=0; radius<radiuses.size(); radius++)
        S += *(Sn.at(radius));
    // Scale S according to number of radius tested
    S /= radiuses.size();
    
    double max, min;
    cv::minMaxLoc(S, &min, &max);
    
    if(debug_mode) {
        nS = S.clone();
        nS -= min;
        nS /= (max-min);
        if(max>maxV) maxV = max;
        
        std::ostringstream ss;
        ss << "Radius = " << radiuses.at(0) << " " << "Max=" << max << "(" << maxV << ")";
        std::string s(ss.str());
        putText(nS, s, cvPoint(10,30),
                cv::FONT_HERSHEY_SIMPLEX, 0.4, cvScalar(200), 1, CV_AA);
    }
    
    // Check final S image for white spots
    for(int i=0; i<r; i++) {
        for(int j=0; j<c; j++) {
            if(S.at<float>(i,j)>overall_threshold) {
                // Check individual images to overule false positives
                int k;
                for(k=0; k<Sn.size() && Sn.at(k)->at<float>(i,j)<single_threshold; k++);
                
                if(k<Sn.size())
                {
                    float rad = radiuses.at(k);
                    float siz = sizes.at(k);
                    
                    cv::rectangle(S, cv::Point(j-siz/2,i-siz/2), cv::Point(j+siz/2,i+siz/2), cv::Scalar(0.0), -1);
                    switch(nsides) {
                        case 3:
                            res.push_back(new Triangle(j,i,rad,siz)); break;
                        case 4:
                            res.push_back(new Square(j,i,rad,siz)); break;
                        case 8:
                            res.push_back(new Octagon(j,i,rad,siz)); break;
                    }
                }
            }
        }
    }
    
    // Free all Sn images in the end
    for(std::vector<cv::Mat*>::iterator it=Sn.begin(); it!=Sn.end(); it++)
        delete *it;
    
    return res;
    
}

std::vector<Shape*> ShapeFinder::findShape(int nsides, const std::vector<int> &rs)
{
    if(nsides == 0) return findCircles(rs);
    else return findPolygons(nsides, rs);
}
