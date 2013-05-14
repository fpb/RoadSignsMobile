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

// Not used
//#import <arm_neon.h>

#import <Accelerate/Accelerate.h>

const float kSqrt3 = sqrtf(3.0f);
const float reciprocal6 = 1.0f / 6.0f;

float radius_value(int nsides, float length)
{
    switch(nsides) {
        case 3: return (float) kSqrt3 * length * reciprocal6;
        default: return length * 0.5f;
    }
}


// Inputs:
//      input: Input grayscale image
//      threshold: threshold value to consider. Gradient values below will produce black pixels
// Outputs:
//      gx: floating point image with normalized x-coordinate component of the gradient image
//      gy: floating point image with normalized y-coordinate component of the gradient image
//      mag: floatinh point image with gradient magnitude (non normalized)

void accelerate_computeGradients(cv::Mat input, cv::Mat &gx, cv::Mat &gy, cv::Mat &mag, float threshold)
{
	cv::Mat workImg = cv::Mat(input);
    
    int nRows = input.rows;
    int nCols = input.cols; // * input.channels
	
    cv::Mat magX = cv::Mat(input.rows, input.cols, CV_32F);
    cv::Mat magY = cv::Mat(input.rows, input.cols, CV_32F);
    cv::Sobel(workImg, magX, CV_32F, 1, 0, 3);
    cv::Sobel(workImg, magY, CV_32F, 0, 1, 3);
	
	float *pMagX, *pMagY;
	float *pGx, *pGy;
	float *mg = new float[nCols];
	float *result = new float[nCols];
	
	for(int i = 0; i < nRows; ++i)
	{
		pMagX = magX.ptr<float>(i);
		pMagY = magY.ptr<float>(i);
		
		pGx   = gx.ptr<float>(i);
		pGy   = gy.ptr<float>(i);
		
		vDSP_vdist(pMagX, 1, pMagY, 1, mg, 1, nCols);
		vDSP_vthres(mg, 1, &threshold, result, 1, nCols);
		vDSP_vdiv(result, 1, pMagX, 1, pGx, 1, nCols);
		vDSP_vdiv(result, 1, pMagY, 1, pGy, 1, nCols);
	}
	
	delete [] mg;
	delete [] result;
}


// Too slow
/*
void neon_computeGradients(cv::Mat input, cv::Mat &gx, cv::Mat &gy, cv::Mat &mag, float threshold)
{
	cv::Mat workImg = cv::Mat(input);
	
	int nRows = input.rows;
	int nCols = input.cols; // * input.channels
	
	cv::Mat magX = cv::Mat(input.rows, input.cols, CV_32F);
	cv::Mat magY = cv::Mat(input.rows, input.cols, CV_32F);
	cv::Sobel(workImg, magX, CV_32F, 1, 0, 3);
	cv::Sobel(workImg, magY, CV_32F, 0, 1, 3);
	
	float *pMagX, *pMagY;
	float *pGx, *pGy;
	
	float32x4_t vMx;
	float32x4_t vMy;
	float32x4_t vThreshold = vdupq_n_f32(threshold);
	float32x4_t vMgSquare;
	uint32x4_t vResult;
	float32x4_t vMg;
	float32x4_t rx, ry;
	
	for(int i = 0; i < nRows; ++i)
	{
		pMagX = magX.ptr<float>(i);
		pMagY = magY.ptr<float>(i);
		
		//		pMag  = mag.ptr<float>(i);
		pGx   = gx.ptr<float>(i);
		pGy   = gy.ptr<float>(i);
		
		for(int j = 0; j < nCols ; j += 4)
		{
			vMx = vld1q_f32(&pMagX[j]);
			vMy = vld1q_f32(&pMagY[j]);
			
			vMgSquare = vaddq_f32(vmulq_f32(vMx, vMx), vmulq_f32(vMy, vMy));
			// If the condition is true, the corresponding element in the destination vector is set to all ones.
			// Otherwise, it is set to all zeros
			vResult = vcgtq_f32(vMgSquare, vThreshold);
			
			vMg = vrsqrteq_f32(vMgSquare);
			//			float32x4_t aux = vmulq_f32(vMg, vMgSquare);
			//			float32x4_t result = vrsqrtsq_f32(aux, vMg);
			//			vMg = vmulq_f32(vMg, result);
			//			aux = vmulq_f32(vMg, vMgSquare);
			//			result = vrsqrtsq_f32(aux, vMg);
			//			vMg = vmulq_f32(vMg, result);
			
			//			vMg = vandq_u32(vResult, vMg);
			//			float32x4_t vMg3 = vrecpeq_f32(vMg);
			rx = vmulq_f32(vMx, vMg);
			ry = vmulq_f32(vMy, vMg);
			rx = vandq_u32(vResult, rx);
			ry = vandq_u32(vResult, ry);
			vst1q_f32(&pGx[j], rx);
			vst1q_f32(&pGy[j], ry);
			
			//			vst1q_f32(&pMag[j], vMg3);
		}
	}
}
*/


void computeGradients(cv::Mat input, cv::Mat &gx, cv::Mat &gy, cv::Mat &mag, double squareThreshold)
{
    cv::Mat workImg = cv::Mat(input);
	//    workImg = input.clone();
    
 	
    cv::Mat magX = cv::Mat(input.rows, input.cols, CV_32F);
    cv::Mat magY = cv::Mat(input.rows, input.cols, CV_32F);
    cv::Sobel(workImg, magX, CV_32F, 1, 0, 3);
    cv::Sobel(workImg, magY, CV_32F, 0, 1, 3);
	
    for(int i=0; i<input.rows; ++i)
        for(int j=0; j<input.cols; ++j)
		{
            float mx = magX.at<float>(i,j);
            float my = magY.at<float>(i,j);
            float mg = (mx*mx + my*my); //sqrtf(mx*mx + my*my);
            if(mg > squareThreshold)
			{
				mg = sqrtf(mg);
                mx /= mg; my /= mg;
// gradient magnitude matrix is not used ?
//                mag.at<float>(i,j) = mg;
                gx.at<float>(i,j) = mx;
                gy.at<float>(i,j) = my;
            }
        }
}

void normalizeFloatImage(cv::Mat &img)
{
    double max;
    
    cv::minMaxLoc(img, NULL, &max);
    img *= (1.0f / max);
}



void ShapeFinder::computeGradients(double grad_threshold)
{
    gx = cv::Mat(r,c,CV_32F);
	gx = cv::Mat::zeros(r, c, CV_32F);
    gy = cv::Mat(r,c,CV_32F);
	gy = cv::Mat::zeros(r, c, CV_32F);
// gradient magnitude matrix is not used ?
//    mag = cv::Mat(r,c,CV_32F);
//    mag = cv::Mat::zeros(r, c, CV_32F);
	
	//	::computeGradients(img, gx, gy, mag, grad_threshold);
	//	neon_computeGradients(img, gx, gy, mag, grad_threshold);
	accelerate_computeGradients(img, gx, gy, mag, grad_threshold);
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
    std::vector<cv::Mat> Sn;
        
	static const float single_threshold = 0.3f;
    const float overall_threshold = single_threshold / sizes.size();
    
    for(std::vector<int>::const_iterator it = sizes.begin(); it != sizes.end(); ++it)
        radiuses.push_back(radius_value(0, *it));
    
	float radius;
	float *ptr_gx, *ptr_gy;
	float gpx, gpy;
	float pvex, pvey;
    for(std::vector<float>::const_iterator it = radiuses.begin(); it != radiuses.end(); ++it)
    {
        // Create and zero O_r - vote image for current radius value
		//        cv::Mat *O_r = new cv::Mat;
		//        *O_r = cv::Mat::zeros(r, c, CV_32F);
		cv::Mat O_r = cv::Mat::zeros(r, c, CV_32F);
		
        // Current radius being considered
        radius = *it;
        
        // Maximum value for individual votes. Anything above will be clamped
		const float kn = sqrtf(radius) * 10.0f;
        
        ptr_gx = (float*) gx.data;
        ptr_gy = (float*) gy.data;
        
        // Process each pixel in the image
        for(int i = 0; i < r; ++i)
		{
            for(int j = 0; j < c; ++j)
			{
                gpx = radius * (*ptr_gx++); //gx.at<float>(i,j)*radius;
                gpy = radius * (*ptr_gy++); //gy.at<float>(i,j)*radius;
                
                // Follow positive gradient at a "radius" distance
                pvex = j + gpx;
                pvey = i + gpy;
                
                // Only consider center points inside the image and cast a new vote
                if(pvex >= 0 && pvex < c && pvey >=0 && pvey < r)
                    O_r.at<float>(pvey, pvex) += 1.0f;
                
                // Follow negative gradient at a "radius" distance
                pvex -= 2 * gpx;
                pvey -= 2 * gpy;
                
                // Only consider center points inside the image and cast a new vote
                if(pvex >= 0 && pvex < c && pvey >=0 && pvey < r)
                    O_r.at<float>(pvey, pvex) += 1.0f;
            }
        }
		
        // Clamp all values above the computed maximum threshold
        cv::threshold(O_r, O_r, kn, 0, cv::THRESH_TRUNC);
        
        // Scale the vote image to the [0-1] range
        O_r *= (1.0f / kn);
        
        // TODO: Put the 1 value as a parameter in a config file
		//        cv::pow(O_r, 1, O_r);
        
        // Blur it...
        cv::GaussianBlur(O_r, O_r, cv::Size(3,3), 0, 0);
        
        // Put the vote image in a vector
        Sn.push_back(O_r);
    }
    
    // Accumulate Sn images into S and compute the mean
    for(int radius = 0; radius<radiuses.size(); ++radius)
        S += Sn.at(radius);
    S *= (1.0f / radiuses.size());
    
    
    if(debug_mode)
	{
		// Compute the maximum value
		double m;
		cv::minMaxLoc(S, NULL, &m);
		
        nS = S.clone();
        nS /= m;
        if(m>maxV) maxV = m;
        
        std::ostringstream ss;
        ss << "Radius = " << radiuses.at(0) << " " << "Max=" << m << "(" << maxV << ")";
        std::string s(ss.str());
        putText(nS, s, cvPoint(10,30), cv::FONT_HERSHEY_SIMPLEX, 0.4, cvScalar(200), 1, CV_AA);
    }
    
    // Check final S image for white spots
    for(int i = 0; i < r; ++i)
	{
        for(int j = 0; j < c; ++j)
		{
            if(S.at<float>(i,j) > overall_threshold) // White spot in mean image...
			{
                // Check individual images to overule false positives
                int k = 0;
				while (k < Sn.size() && Sn.at(k).at<float>(i,j) < single_threshold)
					++k;
				
                if(k < Sn.size())
				{
                    const float rad = radiuses.at(k);
                    const float siz = sizes.at(k);
					const float halfSiz = siz * 0.5f;
                    cv::rectangle(S, cv::Point(j - halfSiz, i - halfSiz), cv::Point(j + halfSiz, i + halfSiz), cv::Scalar(0.0), -1);
                    res.push_back(new Circle(j, i, round(rad), siz));
                }
            }
        }
    }
	
    return res;
}


void vote(const cv::Point &a, const cv::Point &b, float weight, float vx, float vy, cv::Mat &vote_img, cv::Mat &brx, cv::Mat &bry )
{
    cv::LineIterator it_votes(vote_img, a, b, 8);
    cv::LineIterator it_brx(brx, a, b, 8);
    cv::LineIterator it_bry(bry, a, b, 8);
    
    for(int i = 0; i < it_votes.count; ++i, ++it_votes, ++it_brx, ++it_bry)
	{
        float *vote_ptr = (float *)(*it_votes);
        (*vote_ptr) += weight;
        float *brx_ptr = (float*) (*it_brx);
        float *bry_ptr = (float*) (*it_bry);
        
        (*brx_ptr) += (weight * vx);
        (*bry_ptr) += (weight * vy);
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
