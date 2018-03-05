//
//  Mypanle.h
//  VuforiaSamples
//
//  Created by  qztcm09 on 2018/2/5.
//  Copyright © 2018年 PTC. All rights reserved.
//

#ifndef Mypanle_h
#define Mypanle_h


static const int kNumMypanleVertices = 4;
static const int kNumMypanleIndices = 6;


static const float MypanleVertices[kNumMypanleVertices * 3] =
{
    -1.00f,  -1.00f,  0.0f,
     1.00f,  -1.00f,  0.0f,
     1.00f,   1.00f,  0.0f,
    -1.00f,   1.00f,  0.0f,
};

static const float MypanleTexCoords[kNumMypanleVertices * 2] =
{
    0, 0,
    1, 0,
    1, 1,
    0, 1,
};

static const float MypanleNormals[kNumMypanleVertices * 3] =
{
    0, 0, 1,
    0, 0, 1,
    0, 0, 1,
    0, 0, 1,
};

static const unsigned short MypanleIndices[kNumMypanleIndices] =
{
    0,  1,  2,  0,  2,  3,
};

#endif /* Mypanle_h */

#import <Foundation/Foundation.h>


@interface Mypanle : NSObject {
    
}
@end
