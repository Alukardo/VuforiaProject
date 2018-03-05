/*===============================================================================
 Copyright (c) 2012-2015 Qualcomm Connected Experiences, Inc. All Rights Reserved.
 
 Vuforia is a trademark of PTC Inc., registered in the United States and other
 countries.
 ===============================================================================*/

#import  <UIKit/UIKit.h>
#import  "MaskImage.h"


@protocol MyAppMenuDelegate <NSObject>

- (BOOL) menuProcess:(NSString *)itemName value:(BOOL) value;
- (void) menuDidExit;

@end


@interface MyAppMenuViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate>

@property (nonatomic, weak) id<MyAppMenuDelegate> menuDelegate;

@property (nonatomic, weak) IBOutlet UIImageView *maskImage;
@property (weak, nonatomic) IBOutlet UIImageView *scaleImage;
@property (nonatomic, weak) IBOutlet UISlider *retangle;
@property (weak, nonatomic) IBOutlet UIButton *maskType;


@property (nonatomic, readwrite) BOOL windowTapGestureRecognizerAdded;
@property (nonatomic, readwrite) BOOL showingMenu;

@property (nonatomic, copy) NSString *dismissItemName;
@property (nonatomic, copy) NSString *sampleAppFeatureName;
@property (nonatomic, copy) NSString *backSegueId;

@property (nonatomic, strong) UITapGestureRecognizer * windowTapGestureRecognizer;


- (IBAction)CutMaskImage:(UIButton *)sender;
- (IBAction)maskType:(UIButton *)sender;
+ (CGFloat)getMenuWidthScale;
- (void)setValue:(BOOL)value forMenuItem:(NSString*)name;


@end
