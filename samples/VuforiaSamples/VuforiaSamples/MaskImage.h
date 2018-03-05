//
//  MaskImage.h
//  VuforiaSamples
//
//  Created by  qztcm09 on 2018/2/12.
//  Copyright © 2018年 PTC. All rights reserved.
//

#ifndef MaskImage_h
#define MaskImage_h



#import <UIKit/UIKit.h>

#include <opencv2/opencv.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>

@class MaskImage;
@interface MaskImage : NSObject

@property(nonatomic,strong) UIImage * maskImage;//512*512
@property(nonatomic,strong) UIImage * origImage;
@property(nonatomic,strong) UIImage * scalImage;



+ (MaskImage *) GetSingletonMaskImage;

- (void)maskRest;

- (BOOL)SetRectWithSize:(int)Size;

- (BOOL)getFinished;
- (void)setFinished: (bool)stat;

- (void)changMaskPointType;
- (void)changMaskWithX:(int)x andY:(int)y;

- (cv::Mat)getMask;

- (void)printMASK;

@end



#endif /* MaskImage_h */
