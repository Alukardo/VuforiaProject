//
//  GrabCutHandle.m
//  VuforiaSamples
//
//  Created by  qztcm09 on 2018/2/11.
//  Copyright © 2018年 PTC. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "GrabCutHandle.h"
#include "MaskImage.h"

using namespace cv;
using namespace std;

@implementation UIImage (UIImage_OpenCV)

-(Mat)CVMat{
    
    CGColorSpaceRef colorSpace =CGImageGetColorSpace(self.CGImage);
    CGFloat cols =self.size.width;
    CGFloat rows =self.size.height;
    
    Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                // Pointer to backing data
                                                    cols,                     // Width of bitmap
                                                    rows,                    // Height of bitmap
                                                    8,                         // Bits per component
                                                    cvMat.step[0],             // Bytes per row
                                                    colorSpace,                // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), self.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

-(Mat)CVGrayscaleMat{
    CGColorSpaceRef colorSpace =CGColorSpaceCreateDeviceGray();
    CGFloat cols =self.size.width;
    CGFloat rows =self.size.height;
    
    Mat cvMat =Mat(rows, cols,CV_8UC1); // 8 bits per component, 1 channel
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to backing data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNone |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), self.CGImage);
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
    
    return cvMat;
}

+ (UIImage *)imageWithCVMat:(const Mat&)cvMat{
    return [[UIImage alloc] initWithCVMat:cvMat] ;
}

- (id)initWithCVMat:(const Mat&)cvMat{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize() * cvMat.total()];
    
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1){
        colorSpace = CGColorSpaceCreateDeviceGray();
    }
    else{
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider =CGDataProviderCreateWithCFData((CFDataRef)data);
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                    // Width
                                        cvMat.rows,                                    // Height
                                        8,                                             // Bits per component
                                        8 * cvMat.elemSize(),                          // Bits per pixel
                                        cvMat.step[0],                                 // Bytes per row
                                        colorSpace,                                    // Colorspace
                                        kCGImageAlphaLast | kCGBitmapByteOrderDefault, // Bitmap info flags
                                        provider,                                      // CGDataProviderRef
                                        NULL,                                          // Decode
                                        false,                                         // Should interpolate
                                        kCGRenderingIntentDefault);                    // Intent
    
    self = [self initWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return self;
}

- (UIImage *)GrabFrontImage:(UIImage *)image{
    
    //Mat RGBAimage = Mat(512, 512, CV_8UC4);
    // Mat BGRimage  = Mat(512, 512, CV_8UC3);
    
    
    
    Mat BGRimage  = Mat(512, 512, CV_8UC3);
    Mat RGBAimage = Mat(512, 512, CV_8UC4);
    
    Mat mask, bgModel, fgModel, tempFrame;
    
    RGBAimage = [image CVMat];
    
    NSLog(@"RGBAimage通道是%d",RGBAimage.channels());
    
    
    cvtColor(RGBAimage, BGRimage,COLOR_RGBA2BGR);//转换成3通道BGR
    NSLog(@"BGRimage通道是%d",BGRimage.channels());
    MaskImage * maskimage = [MaskImage GetSingletonMaskImage];
    
    mask = [maskimage getMask];
    
    
    cv::Rect rectangle(10,10,BGRimage.cols-20,BGRimage.rows -20);//检测的范围
    //grabCut(BGRimage, mask, rectangle, bgModel, fgModel, 5,cv::GC_INIT_WITH_RECT);//GrabCut分割图像
    grabCut(BGRimage, mask, rectangle, bgModel, fgModel, 1,cv::GC_INIT_WITH_MASK);//GrabCut分割图像
    cvtColor(BGRimage, RGBAimage,cv::COLOR_BGR2RGBA); //转换成4通道RGBA
    
    int nrow = RGBAimage.rows;
    int ncol = RGBAimage.cols;
    
    
    for(int i=0; i<nrow; i++){
        for(int j=0; j<ncol; j++){
            if(mask.at<uchar>(i,j)!=cv::GC_PR_FGD){
                RGBAimage.at<cv::Vec4b>(i,j)[0]= '\255';
                RGBAimage.at<cv::Vec4b>(i,j)[1]= '\255';
                RGBAimage.at<cv::Vec4b>(i,j)[2]= '\255';
                RGBAimage.at<cv::Vec4b>(i,j)[3]= '\0';
            }
        }
    }
    
    return [[UIImage alloc] initWithCVMat:RGBAimage];//显示结果
}

-(void)MaskImageFormGrabCut{
    
    
    
}

//剪裁图片
- (UIImage *) Croppimage:(CGFloat) s
{
    //CGFloat ratioPic =  0.5f;//宽高比1比1
    
    CGFloat x  = 0.5f * (self.size.width * self.scale - s);
    //image.size.width乘以缩放比才是真正的尺寸。
    //图像的实际的尺寸(像素)等于image.size乘以image.scale
    CGFloat y = 0.5f * (self.size.height * self.scale - s);
    //CGRect rect = CGRectMake(x,y,512.0f,512.0f);
    CGRect rect = CGRectMake(x,y,s,s);
    
    CGImageRef imageRef = self.CGImage;
    CGImageRef imagePartRef=CGImageCreateWithImageInRect(imageRef,rect);
    UIImage * cropImage=[UIImage imageWithCGImage:imagePartRef];
    CGImageRelease(imagePartRef);
    CGImageRelease(imageRef);
    return cropImage;
}

//缩放图片
- (UIImage *) scaleImage:(float) scaleSize
{
    
    UIGraphicsBeginImageContext(CGSizeMake(self.size.width * scaleSize, self.size.height * scaleSize));
    [self drawInRect:CGRectMake(0, 0, self.size.width * scaleSize, self.size.height * scaleSize)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return scaledImage;
    
}

//自定义尺寸
- (UIImage *) reSizeImage:(CGSize) reSize
{
    UIGraphicsBeginImageContext(CGSizeMake(reSize.width, reSize.height));
    [self drawInRect:CGRectMake(0, 0, reSize.width, reSize.height)];
    UIImage *reSizeImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return reSizeImage;
}


@end
