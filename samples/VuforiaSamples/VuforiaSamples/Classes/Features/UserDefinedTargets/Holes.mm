//
//  Holes.m
//  VuforiaSamples
//
//  Created by  qztcm09 on 2018/2/7.
//  Copyright © 2018年 PTC. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <opencv2/opencv.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <iostream>
#include <vector>

#define zoom 3 // 缩放因子, 将大图像缩小 n 倍显示

using namespace cv;
using namespace std;

// 填充holes
void fillHole(const Mat srcBw, Mat &dstBw);

int Holes(Mat srcImage)
{
    
    //【2】将图片转为灰度图
    cvtColor(srcImage, srcImage, COLOR_BGR2GRAY);
    
    Mat temp = srcImage.clone();
    resize(temp, temp, cv::Size(temp.cols/zoom, temp.rows/zoom), (static_cast<void>(0), 0), (static_cast<void>(0), 0), 3);
    //imshow("[灰度图]", temp);
    
    
    // 【3】canny算子边缘检测
    Mat edge;
    blur(srcImage, edge, cv::Size(3, 3));//3x3内核降噪
    Canny(srcImage, edge, 150, 100, 3);
    temp = edge;
    resize(edge, temp, cv::Size(temp.cols/zoom, temp.rows/zoom), (static_cast<void>(0), 0), (static_cast<void>(0), 0), 3);
    //imshow("[canny算子边缘检测]", temp);
    
    //【4】膨胀操作, 填充边缘缝隙
    Mat element = getStructuringElement(MORPH_RECT, cv::Size(3, 3));
    for (int i = 0;i < 3;i++) {
        dilate(edge, edge, element);
    }
    temp = edge;
    resize(edge, temp, cv::Size(temp.cols/zoom, temp.rows/zoom), (static_cast<void>(0), 0), (static_cast<void>(0), 0), 3);
    //imshow("[膨胀操作效果图]", temp);
    
    // 【5】Holes填充
    for (int i = 0;i < 10;i++) // 填充10次
    {
        fillHole(edge, edge);
    }
    temp = edge;
    resize(edge, temp, cv::Size(temp.cols/zoom, temp.rows/zoom), (static_cast<void>(0), 0), (static_cast<void>(0), 0), 3);
    //imshow("[Holes填充图]", temp);
    
    return 0;
}

// 填充Holes
void fillHole(const Mat srcBw, Mat &dstBw)
{
    cv::Size m_Size = srcBw.size();
    Mat Temp = Mat::zeros(m_Size.height + 2, m_Size.width + 2, srcBw.type());//延展图像
    srcBw.copyTo(Temp(Range(1, m_Size.height + 1), Range(1, m_Size.width + 1)));
    
    floodFill(Temp, cv::Point(0, 0), Scalar(255));
    
    Mat cutImg;//裁剪延展的图像
    Temp(Range(1, m_Size.height + 1), Range(1, m_Size.width + 1)).copyTo(cutImg);
    
    dstBw = srcBw | (~cutImg);
}
