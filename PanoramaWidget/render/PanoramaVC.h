//
//  HTYGLKVC.h
//  HTY360Player
//
//  Created by 张乐昌 on 2018/3/27.
//  Copyright © 2018年 张乐昌. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@class HTY360PlayerVC;
typedef enum ZLCPanoSRCType
{
    ZLCPanoSRCTypeStream                     = 0,    //数据流
    ZLCPanoSRCTypePicture,                           //图片
    
} ZLCPanoSRCType;

typedef enum ZLCPanoPerspectMode
{
    ZLCPanoPerspectModeNormal               = 0,    // 普通
    ZLCPanoPerspectModeFisheye,                     // 鱼眼
    ZLCPanoPerspectModeLittlePlanet,                // 小行星
    
} ZLCPanoPerspectMode;


@interface PanoramaVC : GLKViewController <UIGestureRecognizerDelegate>

@property (assign, nonatomic,  readonly)  BOOL                 isUsingMotion;
@property (assign, nonatomic, readwrite)  ZLCPanoPerspectMode  perspectiveMode;
@property (assign, nonatomic, readwrite)  ZLCPanoSRCType       srcType;
@property (assign, nonatomic, readwrite)  BOOL                 isSupportAnimate;
@property (strong, nonatomic,  readwrite) UIImage             *loadImage;
@property (assign, nonatomic)             BOOL                 gyroMotioning;


- (instancetype)initWithSrcType:(ZLCPanoSRCType)srcType orientation:(UIDeviceOrientation)orientation;
- (instancetype)initWithSrcType:(ZLCPanoSRCType)srcType;
- (instancetype)initWithImage:(UIImage *)image;
- (void)rotateTo: (UIDeviceOrientation)orientation;
- (void)refreshTexture:(CVPixelBufferRef)pixelBuffer;
- (void)drawTexture:(UIImage *)image;



@end
