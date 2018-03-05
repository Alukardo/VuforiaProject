//
//  MaskImage.m
//  VuforiaSamples
//
//  Created by  qztcm09 on 2018/2/12.
//  Copyright © 2018年 PTC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MaskImage.h"

using namespace cv;

static MaskImage * maskImage = nil;
static uchar maskPointType = GC_BGD;
static BOOL isFinished = false;
static Mat mask = Mat(512, 512, CV_8UC1);
static cv::Rect rect;

@implementation MaskImage

+(MaskImage *)GetSingletonMaskImage{
    
    @synchronized(self){
        if (!maskImage) {
            maskImage = [[MaskImage alloc]init];
        }
        return maskImage;
    }
    
}

- (void)maskRest
{
    if(!mask.empty()){
        
        mask.setTo(Scalar::all(GC_BGD));
        cv::Rect rectangle(10, 10, 512 - 20,512 - 20);//检测的范围
        (mask(rectangle)).setTo(Scalar(GC_PR_FGD));
    }
}

- (BOOL)SetRectWithSize:(int)Size
{
    if(Size > 0 && Size < 512){
        
        rect = cv::Rect(Size,Size,512-2*Size,512-2*Size);//检测的范围
        return true;
    }else{
        return false;
    }
}
- (BOOL)getFinished
{
    return isFinished;
    
}
- (void)setFinished: (bool)stat
{
    isFinished = stat;
    
}
- (void)changMaskPointType
{
    
    if (maskPointType == cv::GC_BGD)
    {
        maskPointType = cv::GC_FGD;
        NSLog(@"# ALK  maskPointType  is GC_FGD");
    }
    else if (maskPointType == cv::GC_FGD)
    {
        maskPointType = cv::GC_PR_BGD;
         NSLog(@"# ALK  maskPointType  is GC_PR_BGD");
        
    }else if (maskPointType == cv::GC_PR_BGD)
    {
        maskPointType = cv::GC_PR_FGD;
         NSLog(@"# ALK  maskPointType  is GC_PR_FGD");
        
    }else if (maskPointType == cv::GC_PR_FGD)
    {
        maskPointType = GC_BGD;
        NSLog(@"# ALK  maskPointType  is GC_BGD");
    }
    
}

- (void)changMaskWithX:(int)x andY:(int)y
{
    
    cv::Rect rectan(x - 3, y - 3, x + 3,y + 3);//检测的范围
    (mask(rectan)).setTo(Scalar(maskPointType));
    //NSLog(@"# ALK  changMask with %u",maskPointType);
    
}

- (cv::Mat)getMask
{
    return mask;
}

- (void)printMASK
{
    for (int i=0; i<256; i++) {
        for (int j=0; j<256; j++){
            
            printf(" %d",mask.at<uchar>(i,j));
        }
        printf("\n");
    }
}
@end

