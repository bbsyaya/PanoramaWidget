//
//  H264ViewController.m
//  PanoramaWidget
//
//  Created by 张乐昌 on 2018/3/28.
//  Copyright © 2018年 张乐昌. All rights reserved.
//

#import "H264ViewController.h"
#import "HardDecoder.h"
#import "LayerPixer.h"
#import "PanoramaVC.h"
#import "Parameter.h"
#import "StateFitter.h"
@interface H264ViewController ()<PackSortDelegate>
{
    HardDecoder *_decoder;
    LayerPixer  *_layerPixer;
    PanoramaVC  *_panoramaVC;
    NSDictionary *_modeIcons;
    NSDictionary *_gyroIcons;
    ZLCPanoPerspectMode _perspectMode;
    BOOL                _isGyroAction;
}

@end

@implementation H264ViewController

-(void)dealloc
{
    _layerPixer.closeFileParser = true;
}

- (void)viewDidLoad {
    _decoder                    = [[HardDecoder alloc] init];
    _layerPixer                 = [[LayerPixer  alloc] init];
    _layerPixer.delegate        = self;
    _layerPixer.closeFileParser = false;
   [_layerPixer decodeFile:LOCALFILE(@"panorama", @"h264")];
    
    _perspectMode               = ZLCPanoPerspectModeFisheye;
    _isGyroAction               = false;

    
     _panoramaVC = [[PanoramaVC alloc] initWithSrcType:ZLCPanoSRCTypeStream orientation:UIDeviceOrientationPortrait];
     _panoramaVC.view.frame = self.view.bounds;
    [_panoramaVC setPerspectiveMode:_perspectMode];
    [_panoramaVC setGyroMotioning:false];
    [self.view addSubview:_panoramaVC.view];
    [self addChildViewController:_panoramaVC];
    [_panoramaVC didMoveToParentViewController:self];
    
    
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
    [super viewDidLoad];
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


-(void)sortPackData:(VideoPacket *)pack
{
    dispatch_sync(dispatch_get_main_queue(), ^{
        CVPixelBufferRef curPixelRef = [_decoder decode2Surface:pack];
        [_panoramaVC refreshTexture:curPixelRef];
    });
}


@end
