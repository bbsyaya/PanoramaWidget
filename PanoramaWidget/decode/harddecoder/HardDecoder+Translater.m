//
//  HardDecoder+Translater.m
//  GKCamara
//
//  Created by 张乐昌 on 2018/2/6.
//  Copyright © 2018年 张乐昌. All rights reserved.
//

#import "HardDecoder+Translater.h"
#import <VideoToolbox/VideoToolbox.h>
#import "ParseFrame.h"
#import "VideoPacket.h"

@implementation HardDecoder (Translater)
//远程文件解码图片
-(UIImage *)translate:(uint8_t *)iframe length:(NSUInteger)length;
{
    // 添加到链表
    VideoPacket *vp = nil;
    ParseFrame* parseFrame = [[ParseFrame alloc] init];
    [parseFrame init:iframe len:(int)length];
    while(YES){
        vp = [parseFrame GetNextNalu];
        if(vp == NULL) break;
        CVPixelBufferRef pixelBuffer = [self decode2Surface:vp];
        if(pixelBuffer){
            CVPixelBufferLockBaseAddress(pixelBuffer, 0);
            CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
            CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
            CIContext *temporaryContext = [CIContext contextWithOptions:nil];
            CGImageRef videoImage = [temporaryContext
                                     createCGImage:ciImage
                                     fromRect:CGRectMake(0, 0,
                                                         CVPixelBufferGetWidth(pixelBuffer),
                                                         CVPixelBufferGetHeight(pixelBuffer))];
            UIImage *uiImage = [UIImage imageWithCGImage:videoImage];
            CGImageRelease(videoImage);
            CVPixelBufferRelease(pixelBuffer);
            if (uiImage) {
                return uiImage;
            }
        }
        [NSThread sleepForTimeInterval:0.001];
    }
    [parseFrame uint];
    return nil;
}

@end
