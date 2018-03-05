/*===============================================================================
Copyright (c) 2016 PTC Inc. All Rights Reserved.

Copyright (c) 2012-2015 Qualcomm Connected Experiences, Inc. All Rights Reserved.

Vuforia is a trademark of PTC Inc., registered in the United States and other 
countries.
===============================================================================*/


#import <UIKit/UIKit.h>
#import "UserDefinedTargetsEAGLView.h"
#import "SampleApplicationSession.h"
#import "MyAppMenuViewController.h"
#import "CustomToolbar.h"

#import <Vuforia/DataSet.h>
#import <AVFoundation/AVFoundation.h>
#import "MaskImage.h"

@interface UserDefinedTargetsViewController : UIViewController <SampleApplicationControl, CustomToolbarDelegateProtocol, MyAppMenuDelegate> {
    Vuforia::DataSet *dataSetUserDef;
    RefFreeFrame *refFreeFrame;
    
    // menu options
    BOOL extendedTrackingEnabled;
    BOOL continuousAutofocusEnabled;
    BOOL flashEnabled;
    BOOL frontCameraEnabled;
}


@property (nonatomic, strong) UserDefinedTargetsEAGLView *eaglView;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, strong) SampleApplicationSession *vapp;

@property (nonatomic, strong) CustomToolbar *toolbar;
@property (nonatomic, readwrite) BOOL showingMenu;

//@property (nonatomic, weak) UIImage *img;
//@property (nonatomic, strong) AVCaptureDevice *device;
//@property (nonatomic, strong) AVCaptureDeviceInput *input;
//@property (nonatomic ,strong) AVCapturePhotoOutput *output;
//@property (nonatomic, strong) AVCaptureSession *session;
//@property (nonatomic, strong) AVCapturePhotoSettings *settings;
//@property (nonatomic ,strong) AVCaptureVideoPreviewLayer *previewLayer;

//@property (nonatomic, strong) UIImagePickerController *imagePickerController;



@end
