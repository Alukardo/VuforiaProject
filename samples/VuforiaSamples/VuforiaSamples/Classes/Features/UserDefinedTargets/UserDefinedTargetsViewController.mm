/*===============================================================================
 Copyright (c) 2016-2017 PTC Inc. All Rights Reserved.
 
 Copyright (c) 2012-2015 Qualcomm Connected Experiences, Inc. All Rights Reserved.
 
 Vuforia is a trademark of PTC Inc., registered in the United States and other
 countries.
 ===============================================================================*/
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

#import "UserDefinedTargetsViewController.h"
#import "VuforiaSamplesAppDelegate.h"

#import <Vuforia/Vuforia.h>
#import <Vuforia/TrackerManager.h>
#import <Vuforia/ObjectTracker.h>
#import <Vuforia/Trackable.h>
#import <Vuforia/TrackableSource.h>
#import <Vuforia/DataSet.h>
#import <Vuforia/CameraDevice.h>
#import <Vuforia/Frame.h>
#import <Vuforia/Image.h>
#import <Vuforia/Renderer.h>
#import <QuartzCore/QuartzCore.h>

#import "MaskImage.h"
#import "UnwindMenuSegue.h"
#import "PresentMenuSegue.h"
#import "MyAppMenuViewController.h"
#import "GrabCutHandle.h"

#define TOOLBAR_HEIGHT 53

@interface UserDefinedTargetsViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *ARViewPlaceholder;

@end

@implementation UserDefinedTargetsViewController

@synthesize tapGestureRecognizer, vapp, eaglView, toolbar;
//@synthesize device, input, output, session, previewLayer, img;

- (CGRect)getCurrentARViewFrame
{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGRect viewFrame = screenBounds;
    
    // If this device has a retina display, scale the view bounds
    // for the AR (OpenGL) view
    if (YES == vapp.isRetinaDisplay) {
        viewFrame.size.width *= [UIScreen mainScreen].nativeScale;
        viewFrame.size.height *= [UIScreen mainScreen].nativeScale;
    }
    return viewFrame;
}

- (void)loadView
{
    // Custom initialization
    self.title = @"Object Reco";
    
    
    if (self.ARViewPlaceholder != nil) {
        [self.ARViewPlaceholder removeFromSuperview];
        self.ARViewPlaceholder = nil;
    }
    
    dataSetUserDef = nil;
    
    extendedTrackingEnabled = NO;
    continuousAutofocusEnabled = YES;
    flashEnabled = NO;
    frontCameraEnabled = NO;
    
    vapp = [[SampleApplicationSession alloc] initWithDelegate:self];
    
    CGRect viewFrame = [self getCurrentARViewFrame];
    
    refFreeFrame = new RefFreeFrame();
    eaglView = [[UserDefinedTargetsEAGLView alloc] initWithFrame:viewFrame appSession:vapp];
    [eaglView setBackgroundColor:UIColor.clearColor];
    [eaglView setRefFreeFrame: refFreeFrame];
    [self setView:eaglView];
    
    VuforiaSamplesAppDelegate *appDelegate = (VuforiaSamplesAppDelegate*)[[UIApplication sharedApplication] delegate];
    appDelegate.glResourceHandler = eaglView;
    
    // double tap used to also trigger the menu
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget: self action:@selector(doubleTapGestureAction:)];
    doubleTap.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:doubleTap];
    
    // a single tap will trigger a single autofocus operation
    tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(autofocus:)];
    if (doubleTap != NULL) {
        [tapGestureRecognizer requireGestureRecognizerToFail:doubleTap];
    }
    
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeGestureAction:)];
    [swipeRight setDirection:UISwipeGestureRecognizerDirectionRight];
    [self.view addGestureRecognizer:swipeRight];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dismissARViewController)
                                                 name:@"kDismissARViewController"
                                               object:nil];
    
    // we use the iOS notification to pause/resume the AR when the application goes (or come back from) background
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(pauseAR)
     name:UIApplicationWillResignActiveNotification
     object:nil];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(resumeAR)
     name:UIApplicationDidBecomeActiveNotification
     object:nil];
    
    // initialize AR
    [vapp initAR:Vuforia::GL_20 orientation:self.interfaceOrientation];
    
    refFreeFrame->stopImageTargetBuilder();
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(goodFrameQuality:)
                                                 name:@"kGoodFrameQuality"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(badFrameQuality:)
                                                 name:@"kBadFrameQuality"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(trackableCreated:)
                                                 name:@"kTrackableCreated"
                                               object:nil];
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    // show loading animation while AR is being initialized
    [self showLoadingAnimation];
}

-(void) addToolbar
{
    dispatch_async(dispatch_get_main_queue(), ^{
        //  Init Toolbar
        CGRect toolbarFrame = CGRectMake(0,
                                         self.view.frame.size.height - TOOLBAR_HEIGHT,
                                         self.view.frame.size.width,
                                         TOOLBAR_HEIGHT);
        
        toolbar = [[CustomToolbar alloc] initWithFrame:toolbarFrame];
        toolbar.delegate = self;
        toolbar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;// | UIViewAutoresizingFlexibleWidth;
        
        //  Finally, add toolbar to ViewController's view
        [self.view addSubview:toolbar];
    });
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view.superview isKindOfClass:[CustomToolbar class]]) return FALSE;
    return YES;
}

- (void) pauseAR {
    NSError * error = nil;
    if (![vapp pauseAR:&error]) {
        NSLog(@"Error pausing AR:%@", [error description]);
    }
}

- (void) resumeAR {
    NSError * error = nil;
    if(! [vapp resumeAR:&error]) {
        NSLog(@"Error resuming AR:%@", [error description]);
    }
    [eaglView updateRenderingPrimitives];
    // on resume, we reset the flash
    Vuforia::CameraDevice::getInstance().setFlashTorchMode(false);
    flashEnabled = NO;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.showingMenu = NO;
    
    // Do any additional setup after loading the view.
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [self.view addGestureRecognizer:tapGestureRecognizer];
    //[self cameraInital];
    NSLog(@"self.navigationController.navigationBarHidden: %s", self.navigationController.navigationBarHidden ? "Yes" : "No");
    
    
    
    
    
}


- (void)viewWillDisappear:(BOOL)animated{
    
    
    // on iOS 7, viewWillDisappear may be called when the menu is shown
    // but we don't want to stop the AR view in that case
    if (self.showingMenu) {
        return;
    }
    
    refFreeFrame->deInit();
    
    [vapp stopAR:nil];
    
    // Be a good OpenGL ES citizen: now that Vuforia is paused and the render
    // thread is not executing, inform the root view controller that the
    // EAGLView should finish any OpenGL ES commands
    [self finishOpenGLESCommands];
    
    VuforiaSamplesAppDelegate *appDelegate = (VuforiaSamplesAppDelegate*)[[UIApplication sharedApplication] delegate];
    appDelegate.glResourceHandler = nil;
    
    delete refFreeFrame;
    
    [super viewWillDisappear:animated];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)finishOpenGLESCommands
{
    // Called in response to applicationWillResignActive.  Inform the EAGLView
    [eaglView finishOpenGLESCommands];
}

- (void)freeOpenGLESResources
{
    // Called in response to applicationDidEnterBackground.  Inform the EAGLView
    [eaglView freeOpenGLESResources];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - loading animation

- (void) showLoadingAnimation {
    CGRect indicatorBounds;
    CGRect mainBounds = [[UIScreen mainScreen] bounds];
    int smallerBoundsSize = MIN(mainBounds.size.width, mainBounds.size.height);
    int largerBoundsSize = MAX(mainBounds.size.width, mainBounds.size.height);
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown ) {
        indicatorBounds = CGRectMake(smallerBoundsSize / 2 - 12,
                                     largerBoundsSize / 2 - 12, 24, 24);
    }
    else {
        indicatorBounds = CGRectMake(largerBoundsSize / 2 - 12,
                                     smallerBoundsSize / 2 - 12, 24, 24);
    }
    
    UIActivityIndicatorView *loadingIndicator = [[UIActivityIndicatorView alloc]
                                                 initWithFrame:indicatorBounds];
    
    loadingIndicator.tag  = 1;
    loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    [eaglView addSubview:loadingIndicator];
    [loadingIndicator startAnimating];
}

- (void) hideLoadingAnimation {
    UIActivityIndicatorView *loadingIndicator = (UIActivityIndicatorView *)[eaglView viewWithTag:1];
    [loadingIndicator removeFromSuperview];
}


-(void)setCameraMode
{
    refFreeFrame->startImageTargetBuilder();
    
    toolbar.isCancelButtonHidden = YES;
    toolbar.shouldRotateActionButton = YES;
    toolbar.actionImage = [UIImage imageNamed:@"icon_camera.png"];
}

#pragma mark - Notifications
- (void)goodFrameQuality:(NSNotification *)aNotification
{
    //NSLog(@">> goodFrameQuality");
}

- (void)badFrameQuality:(NSNotification *)aNotification
{
    //NSLog(@">> badFrameQuality");
}

- (void)trackableCreated:(NSNotification *)aNotification
{
    // we restart the camera mode once a target has been added
    [self setCameraMode];
}

#pragma mark - CustomToolbarDelegateProtocol

-(void)actionButtonWasPressed
{
    //  Camera button was pressed
    if (refFreeFrame->isImageTargetBuilderRunning() == YES){
        refFreeFrame->startBuild();
        
        MaskImage * mask = [MaskImage GetSingletonMaskImage];
        mask.origImage   = [self imageWithScreenshot];
        mask.scalImage   = [[mask.origImage Croppimage:1024.0f] scaleImage:0.5f];
        
        
        [self loadImageFinished:[self imageWithScreenshot]];
        
        NSLog(@"hhhhhaaaa");
        
    }
    
}

-(void)cancelButtonWasPressed
{
    // No cancel button
}


#pragma mark - SampleApplicationControl

// Initialize the application trackers
- (bool) doInitTrackers {
    // Initialize the object tracker
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    Vuforia::Tracker* trackerBase = trackerManager.initTracker(Vuforia::ObjectTracker::getClassType());
    if (trackerBase == NULL){
        NSLog(@"Failed to initialize ObjectTracker.");
        return false;
    }
    return true;
}

- (bool) doLoadTrackersData {
    // Get the image tracker:
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    Vuforia::ObjectTracker* objectTracker = static_cast<Vuforia::ObjectTracker*>(trackerManager.getTracker(Vuforia::ObjectTracker::getClassType()));
    if (objectTracker != nil)
    {
        // Create the data set:
        dataSetUserDef = objectTracker->createDataSet();
        if (dataSetUserDef != nil)
        {
            if (!objectTracker->activateDataSet(dataSetUserDef))
            {
                NSLog(@"Failed to activate data set.");
                return false;
            }
        }
    }
    return true;
}

// start the application trackers
- (bool) doStartTrackers {
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    Vuforia::Tracker* tracker = trackerManager.getTracker(Vuforia::ObjectTracker::getClassType());
    if(tracker == 0) {
        return false;
    }
    tracker->start();
    return true;
}

// callback called when the initailization of the AR is done
- (void) onInitARDone:(NSError *)initError {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIActivityIndicatorView *loadingIndicator = (UIActivityIndicatorView *)[eaglView viewWithTag:1];
        [loadingIndicator removeFromSuperview];
    });
    
    if (initError == nil) {
        NSError * error = nil;
        
        //  Add bottom toolbar
        [self addToolbar];
        
        [self setCameraMode];
        
        [vapp startAR:Vuforia::CameraDevice::CAMERA_DIRECTION_BACK error:&error];
        
        [eaglView updateRenderingPrimitives];
        
        // by default, we try to set the continuous auto focus mode
        continuousAutofocusEnabled = Vuforia::CameraDevice::getInstance().setFocusMode(Vuforia::CameraDevice::FOCUS_MODE_CONTINUOUSAUTO);
        
    } else {
        NSLog(@"Error initializing AR:%@", [initError description]);
        
        dispatch_async( dispatch_get_main_queue(), ^{
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:[initError localizedDescription]
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        });
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kDismissARViewController" object:nil];
}

- (void)dismissARViewController
{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (void)configureVideoBackgroundWithViewWidth:(float)viewWidth andHeight:(float)viewHeight
{
    [eaglView configureVideoBackgroundWithViewWidth:(float)viewWidth andHeight:(float)viewHeight];
}

// update from the Vuforia loop
- (void) onVuforiaUpdate: (Vuforia::State *) state {
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    Vuforia::ObjectTracker* objectTracker = static_cast<Vuforia::ObjectTracker*>(trackerManager.getTracker(Vuforia::ObjectTracker::getClassType()));
    
    if (refFreeFrame->hasNewTrackableSource())
    {
        Vuforia::Trackable * lastCreated;
        
        NSLog(@"Attempting to transfer the trackable source to the dataset");
        
        // Deactiveate current dataset
        objectTracker->deactivateDataSet(objectTracker->getActiveDataSet(0));
        
        // Clear the oldest target if the dataset is full or the dataset
        // already contains five user-defined targets.
        if (dataSetUserDef->hasReachedTrackableLimit()
            || dataSetUserDef->getNumTrackables() >= 5)
            dataSetUserDef->destroy(dataSetUserDef->getTrackable(0));
        
        // if extended tracking is on, we need to stop the extended tracking on the
        // last trackable first as extended tracking should only be enable on one trackable
        if ((extendedTrackingEnabled) && (dataSetUserDef->getNumTrackables() > 0)) {
            lastCreated = dataSetUserDef->getTrackable(dataSetUserDef->getNumTrackables() - 1);
            lastCreated->stopExtendedTracking();
            objectTracker->resetExtendedTracking();
        }
        
        // Add new trackable source
        lastCreated = dataSetUserDef->createTrackable(refFreeFrame->getNewTrackableSource());
        
        // if extended tracking is on we activate it on this newly created trackable
        if (extendedTrackingEnabled) {
            lastCreated->startExtendedTracking();
        }
        
        // Reactivate current dataset
        objectTracker->activateDataSet(dataSetUserDef);
    }
}


// stop your trackerts
- (bool) doStopTrackers {
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    Vuforia::Tracker* tracker = trackerManager.getTracker(Vuforia::ObjectTracker::getClassType());
    
    if (NULL == tracker) {
        NSLog(@"ERROR: failed to get the tracker from the tracker manager");
        return false;
    }
    
    tracker->stop();
    return true;
}

// unload the data associated to your trackers
- (bool) doUnloadTrackersData {
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    Vuforia::ObjectTracker* objectTracker = static_cast<Vuforia::ObjectTracker*>(trackerManager.getTracker(Vuforia::ObjectTracker::getClassType()));
    if (objectTracker == NULL)
    {
        NSLog(@"Failed to destroy the tracking data set because the ObjectTracker has not been initialized.");
        return false;
    }
    
    if (dataSetUserDef != nil)
    {
        if (objectTracker->getActiveDataSet(0) && !objectTracker->deactivateDataSet(dataSetUserDef))
        {
            NSLog(@"Failed to destroy the tracking data set because the data set could not be deactivated.");
            return false;
        }
        if (!objectTracker->destroyDataSet(dataSetUserDef))
        {
            NSLog(@"Failed to destroy the tracking data set.");
            return false;
        }
    }
    extendedTrackingEnabled = NO;
    dataSetUserDef = nil;
    return true;
}

// deinitialize your trackers
- (bool) doDeinitTrackers {
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    trackerManager.deinitTracker(Vuforia::ObjectTracker::getClassType());
    return true;
}

- (void)autofocus:(UITapGestureRecognizer *)sender
{
    [self performSelector:@selector(cameraPerformAutoFocus) withObject:nil afterDelay:.4];
}

- (void)cameraPerformAutoFocus
{
    Vuforia::CameraDevice::getInstance().setFocusMode(Vuforia::CameraDevice::FOCUS_MODE_TRIGGERAUTO);
    
    // After triggering an autofocus event,
    // we must restore the previous focus mode
    if (continuousAutofocusEnabled)
    {
        [self performSelector:@selector(restoreContinuousAutoFocus) withObject:nil afterDelay:2.0];
    }
}

- (void)restoreContinuousAutoFocus
{
    Vuforia::CameraDevice::getInstance().setFocusMode(Vuforia::CameraDevice::FOCUS_MODE_CONTINUOUSAUTO);
}

- (void)doubleTapGestureAction:(UITapGestureRecognizer*)theGesture
{
    if (!self.showingMenu) {
        [self performSegueWithIdentifier: @"PresentMenu" sender: self];
    }
}

- (void)swipeGestureAction:(UISwipeGestureRecognizer*)gesture
{
    if (!self.showingMenu) {
        [self performSegueWithIdentifier:@"PresentMenu" sender:self];
    }
}


- (BOOL)activateDataSet:(Vuforia::DataSet *)theDataSet
{
    BOOL success = NO;
    
    // Get the image tracker:
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    Vuforia::ObjectTracker* objectTracker = static_cast<Vuforia::ObjectTracker*>(trackerManager.getTracker(Vuforia::ObjectTracker::getClassType()));
    
    if (objectTracker == NULL) {
        NSLog(@"Failed to load tracking data set because the ObjectTracker has not been initialized.");
    }
    else
    {
        // Activate the data set:
        if (!objectTracker->activateDataSet(theDataSet))
        {
            NSLog(@"Failed to activate data set.");
        }
        else
        {
            NSLog(@"Successfully activated data set.");
            success = YES;
        }
    }
    
    // we set the off target tracking mode to the current state
    if (success) {
        [self setExtendedTrackingForDataSet:theDataSet start:extendedTrackingEnabled];
    }
    
    return success;
}

- (BOOL)deactivateDataSet:(Vuforia::DataSet *)theDataSet
{
    BOOL success = NO;
    
    // we deactivate the enhanced tracking
    [self setExtendedTrackingForDataSet:theDataSet start:NO];
    
    // Get the image tracker:
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    Vuforia::ObjectTracker* objectTracker = static_cast<Vuforia::ObjectTracker*>(trackerManager.getTracker(Vuforia::ObjectTracker::getClassType()));
    
    if (objectTracker == NULL)
    {
        NSLog(@"Failed to unload tracking data set because the ObjectTracker has not been initialized.");
    }
    else
    {
        // Activate the data set:
        if (!objectTracker->deactivateDataSet(theDataSet))
        {
            NSLog(@"Failed to deactivate data set.");
        }
        else
        {
            success = YES;
        }
    }
    
    return success;
}

- (BOOL) setExtendedTrackingForDataSet:(Vuforia::DataSet *)theDataSet start:(BOOL) start {
    BOOL result = YES;
    // With UDT targets we can only enable Extended Tracking on one target at a time,
    // so, first we stop ExtTracking on all targets
    for (int tIdx = 0; tIdx < theDataSet->getNumTrackables(); tIdx++)
    {
        Vuforia::Trackable* trackable = theDataSet->getTrackable(tIdx);
        if (!trackable->stopExtendedTracking())
        {
            NSLog(@"Failed to stop extended tracking on: %s", trackable->getName());
            result = NO;
        }
    }
    
    if (start && theDataSet->getNumTrackables() > 0) {
        int lastTarget = theDataSet->getNumTrackables()-1;
        Vuforia::Trackable* trackable = theDataSet->getTrackable(lastTarget);
        if (start)
        {
            if (!trackable->startExtendedTracking())
            {
                NSLog(@"Failed to start extended tracking on: %s", trackable->getName());
                result = NO;
            }
        }
    }
    
    return result;
}


#pragma mark - menu delegate protocol implementation

- (BOOL) menuProcess:(NSString *)itemName value:(BOOL)value
{
    if ([@"Extended Tracking" isEqualToString:itemName]) {
        BOOL result = [self setExtendedTrackingForDataSet:dataSetUserDef start:value];
        if (result) {
            [eaglView setOffTargetTrackingMode:value];
            // we keep track of the state of the extended tracking mode
            extendedTrackingEnabled = value;
        }
        return result;
    }
    return NO;
}

- (void) menuDidExit
{
    self.showingMenu = NO;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue isKindOfClass:[PresentMenuSegue class]]) {
        UIViewController *dest = [segue destinationViewController];
        if ([dest isKindOfClass:[MyAppMenuViewController class]]) {
            self.showingMenu = YES;
            
            MyAppMenuViewController *menuVC = (MyAppMenuViewController *)dest;
            menuVC.menuDelegate = self;
            menuVC.sampleAppFeatureName = @"User Defined Targets";
            menuVC.dismissItemName = @"Vuforia Samples";
            menuVC.backSegueId = @"BackToUserDefinedTargets";
            
            
            // initialize menu item values (ON / OFF)
            [menuVC setValue:extendedTrackingEnabled forMenuItem:@"Extended Tracking"];
        }
    }
}
#pragma mark - ScreenCut
//截取当前屏幕
-(NSData *)dataWithScreenshotInPNGFormat{
    CGSize imageSize = CGSizeZero;
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (UIInterfaceOrientationIsPortrait(orientation))
        imageSize = [UIScreen mainScreen].bounds.size;
    else
        imageSize = CGSizeMake([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    for (UIWindow *window in [[UIApplication sharedApplication] windows])
    {
        CGContextSaveGState(context);
        CGContextTranslateCTM(context, window.center.x, window.center.y);
        CGContextConcatCTM(context, window.transform);
        CGContextTranslateCTM(context, -window.bounds.size.width * window.layer.anchorPoint.x, -window.bounds.size.height * window.layer.anchorPoint.y);
        if (orientation == UIInterfaceOrientationLandscapeLeft)
        {
            CGContextRotateCTM(context, M_PI_2);
            CGContextTranslateCTM(context, 0, -imageSize.width);
        }
        else if (orientation == UIInterfaceOrientationLandscapeRight)
        {
            CGContextRotateCTM(context, -M_PI_2);
            CGContextTranslateCTM(context, -imageSize.height, 0);
        } else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
            CGContextRotateCTM(context, M_PI);
            CGContextTranslateCTM(context, -imageSize.width, -imageSize.height);
        }
        if ([window respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)])
        {
            [window drawViewHierarchyInRect:window.bounds afterScreenUpdates:YES];
        }
        else
        {
            [window.layer renderInContext:context];
        }
        
        CGContextRestoreGState(context);
    }
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return UIImagePNGRepresentation(image);
}

//返回截取到的图片
- (UIImage *)imageWithScreenshot
{
    NSData *imageData = [self dataWithScreenshotInPNGFormat];
    return [UIImage imageWithData:imageData];
}

#pragma mark - Save Photo To Album

- (void)loadImageFinished:(UIImage *)image
{
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), (__bridge void *)self);
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    
    NSLog(@"image = %@, error = %@, contextInfo = %@", image, error, contextInfo);
}


//#pragma mark - AVCapture
//
//- (void)cameraInital
//{
//
//    self.session = [[AVCaptureSession alloc] init];
//    self.session.sessionPreset = AVCaptureSessionPresetPhoto;
//
//    self.settings = [AVCapturePhotoSettings photoSettings];
//
//    self.device  = [self backCamera];
//
//    //[self resetFocusAndExposureModes];
//    self.input = [[AVCaptureDeviceInput alloc] initWithDevice:self.device error:nil];
//    if ([self.session canAddInput:self.input]) {
//        [self.session addInput:self.input];
//    }
//
//    self.output = [[AVCapturePhotoOutput alloc]init];
//
//    if ([self.session canAddOutput:self.output]) {
//        [self.session addOutput:self.output];
//    }
//}
//
//- (BOOL)resetFocusAndExposureModes{
//    AVCaptureDevice *device = self.device;
//    AVCaptureExposureMode exposureMode = AVCaptureExposureModeContinuousAutoExposure;
//    AVCaptureFocusMode focusMode = AVCaptureFocusModeContinuousAutoFocus;
//    BOOL canResetFocus = [device isFocusPointOfInterestSupported] && [device isFocusModeSupported:focusMode];
//    BOOL canResetExposure = [device isExposurePointOfInterestSupported] && [device isExposureModeSupported:exposureMode];
//    CGPoint centerPoint = CGPointMake(0.5f, 0.5f);
//    NSError *error;
//    if ([device lockForConfiguration:&error]) {
//        if (canResetFocus) {
//            device.focusMode = focusMode;
//            device.focusPointOfInterest = centerPoint;
//        }
//        if (canResetExposure) {
//            device.exposureMode = exposureMode;
//            device.exposurePointOfInterest = centerPoint;
//        }
//        [device unlockForConfiguration];
//        return YES;
//    }
//    else{
//        return NO;
//    }
//}
//
//- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition) position {
//
//    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
//    for (AVCaptureDevice *device in devices) {
//        if ([device position] == position) {
//            return device;
//        }
//    }
//    return nil;
//}
//
//- (AVCaptureDevice *)frontCamera {
//    return [self cameraWithPosition:AVCaptureDevicePositionFront];
//}
//
//- (AVCaptureDevice *)backCamera {
//    return [self cameraWithPosition:AVCaptureDevicePositionBack];
//}
//
//- (void)photoBtnDidClick
//{
//    AVCaptureConnection * videoConnection = [self.output connectionWithMediaType:AVMediaTypeVideo];
//    if (!videoConnection) {
//        NSLog(@"take photo failed!");
//        return;
//    }
//    [self resetFocusAndExposureModes];
//    if ([videoConnection isVideoStabilizationSupported]) {
//        videoConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;//防抖模式
//    }
//    [self.output capturePhotoWithSettings:self.settings delegate:self];
//}
//
//- (UIImage *)scaleImage:(UIImage *)image toScale:(float)scaleSize{
//    UIGraphicsBeginImageContext(CGSizeMake(image.size.width * scaleSize, image.size.height * scaleSize));
//    [image drawInRect:CGRectMake(0, 0, image.size.width * scaleSize, image.size.height * scaleSize)];
//    UIImage * scaledImage = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//    return scaledImage;
//}
//
//
//-(void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error{
//    if (error) {
//        NSLog(@"error : %@", error.localizedDescription);
//    }else{
//
//        UIImage *image = [UIImage imageWithCGImage:[photo CGImageRepresentation] scale:1 orientation:UIImageOrientationLeft];
//        //UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
//        //img = [self GrabFrontImage:image];
//
//        NSLog(@"scuess capture Image");
//    }
//}
//


//#pragma mark - ImagePickerController
//// 选择图片成功调用此方法
//- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
//
//    
//    // dismiss UIImagePickerController
//    [self dismissViewControllerAnimated:YES completion:nil];
//    self.img = [info objectForKey:UIImagePickerControllerOriginalImage];
//    // 选择的图片信息存储于info字典中
//    NSLog(@"%@", info);
//}
//// 取消图片选择调用此方法
//- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
//
//    // dismiss UIImagePickerController
//    [self dismissViewControllerAnimated:YES completion:nil];
//}
//
//-(void)GetThePicture{
//    self.imagePickerController.navigationBarHidden = YES;
//    self.imagePickerController.showsCameraControls = NO;
//    self.imagePickerController = [[UIImagePickerController alloc] init];
//    self.imagePickerController.delegate = self;
//    self.imagePickerController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
//
//
//    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
//        self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
//        [self presentViewController:self.imagePickerController animated:YES completion:^{
//            //TODO :: something
//        }];
//    }
//
//}
//
//-(UIImage *)screenImageWithSize:(CGSize )imgSize{
//    UIGraphicsBeginImageContext(imgSize);
//    CGContextRef context = UIGraphicsGetCurrentContext();
//
//    VuforiaSamplesAppDelegate *app = (VuforiaSamplesAppDelegate*)[[UIApplication sharedApplication] delegate];
//    [app.window.layer renderInContext:context];
//
//    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//    return img;
//}



//截屏
//CGImageRef screen = UIGetScreenImage();
//UIImage* image = [UIImage imageWithCGImage:screen];

@end
