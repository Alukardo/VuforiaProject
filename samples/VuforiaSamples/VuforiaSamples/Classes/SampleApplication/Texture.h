/*===============================================================================
 Copyright (c) 2012-2015 Qualcomm Connected Experiences, Inc. All Rights Reserved.
 
 Vuforia is a trademark of PTC Inc., registered in the United States and other
 countries.
 ===============================================================================*/

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface Texture : NSObject {
}


// --- Properties ---
@property (nonatomic, readonly)  int width;
@property (nonatomic, readonly)  int height;
@property (nonatomic, readonly)  int channels;
@property (nonatomic, readwrite) int textureID;
@property (nonatomic, readonly)  unsigned char* pngData;
@property (nonatomic, readonly)  GLubyte *textureData;

// --- Public methods ---
- (id)initWithImageFile:(NSString * )filename;
- (id)initWithUIImage:(UIImage * )image;

@end
