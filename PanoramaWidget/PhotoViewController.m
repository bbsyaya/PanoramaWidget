//
//  UIPlayPhotoViewController.m
//  GKCamara
//
//  Created by 张乐昌 on 17/7/2.
//  Copyright © 2017年 周勇. All rights reserved.
//

#import "PhotoViewController.h"
#import "PanoramaVC.h"
#import "StateFitter.h"
@interface PhotoViewController ()
{
    NSString     *_path;
    PanoramaVC   *_panoramaVC;
    NSDictionary *_modeIcons;
    NSDictionary *_gyroIcons;
    ZLCPanoPerspectMode  _perspectMode;
    BOOL                 _isGyroAction;
}

@end

#define W_NOIMAGE 100
#define H_NOIMAGE 150

@implementation PhotoViewController




-(instancetype)initWithPath:(NSString *)path
{
    self = [super init];
    if (self) {
        _path = path;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor blackColor]];


     _panoramaVC = [[PanoramaVC alloc] initWithSrcType:ZLCPanoSRCTypePicture orientation:UIDeviceOrientationPortrait];
     _panoramaVC.view.frame = self.view.bounds;
    [_panoramaVC setSrcType:ZLCPanoSRCTypePicture];
    [_panoramaVC setPerspectiveMode:_perspectMode];
    [_panoramaVC setGyroMotioning:false];
    [_panoramaVC setLoadImage:[UIImage imageWithContentsOfFile:_path]];
    [self.view addSubview:_panoramaVC.view];
    [self addChildViewController:_panoramaVC];
    [_panoramaVC didMoveToParentViewController:self];
    
    _perspectMode = ZLCPanoPerspectModeLittlePlanet;
    _isGyroAction = false;
    
    
    _modeIcons = @{
                   @(ZLCPanoPerspectModeNormal):@"btn_3d_normal",
                   @(ZLCPanoPerspectModeFisheye):@"btn_fishye_normal",
                   @(ZLCPanoPerspectModeLittlePlanet):@"btn_littleplanet_normal"
                   };
    _gyroIcons = @{
                   @(true):@"btn_glyo_moving",
                   @(false):@"btn_glyo_static"
                   };
    
    UIBarButtonItem *gyroItem = [self createBarButtonWithBackgroundImage:_gyroIcons[@(_isGyroAction)] SELfun:@selector(gyroDidTouch:)];
    UIBarButtonItem *modeItem = [self createBarButtonWithBackgroundImage:_modeIcons[@(_perspectMode)] SELfun:@selector(modeDidTouch:)];

    self.navigationItem.rightBarButtonItems = @[gyroItem,modeItem];
 }


-(void)gyroDidTouch:(UIButton *)sender
{
    _isGyroAction = [StateFitter nextKey:_gyroIcons currentBoolenKey:_isGyroAction];
    [_panoramaVC setGyroMotioning:_isGyroAction];
    [sender setBackgroundImage:[UIImage imageNamed:_gyroIcons[@(_isGyroAction)]] forState:UIControlStateNormal];
}


-(void)modeDidTouch:(UIButton *)sender
{
     _perspectMode = (ZLCPanoPerspectMode)[StateFitter nextKey:_modeIcons currentIntKey:_perspectMode];
    [_panoramaVC setPerspectiveMode:_perspectMode];
    [sender setBackgroundImage:[UIImage imageNamed:_modeIcons[@(_perspectMode)]] forState:UIControlStateNormal];
}



@end
