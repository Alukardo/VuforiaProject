//
//  GrabCutHandle.h
//  VuforiaSamples
//
//  Created by  qztcm09 on 2018/2/11.
//  Copyright © 2018年 PTC. All rights reserved.
//

#ifndef GrabCutHandle_h
#define GrabCutHandle_h



#import <UIKit/UIKit.h>
#include <opencv2/opencv.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>



@interface UIImage (UIImage_OpenCV)

+ (UIImage *)imageWithCVMat:(const cv::Mat&)cvMat;
- (id)initWithCVMat:(const cv::Mat&)cvMat;

- (UIImage *) GrabFrontImage:(UIImage *) image;

- (void) MaskImageFormGrabCut;

- (UIImage *) Croppimage : (CGFloat) s;
- (UIImage *) scaleImage : (float)   scaleSize;
- (UIImage *) reSizeImage: (CGSize)  reSize;


@property(nonatomic,readonly) cv::Mat CVMat;
@property(nonatomic,readonly) cv::Mat CVGrayscaleMat;
@end



#endif /* GrabCutHandle_h */
