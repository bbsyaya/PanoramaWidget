//
//  HardDecoder.h
//  GKCamara
//
//  Created by 张乐昌 on 17/6/28.
//  Copyright © 2017年 张乐昌. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VideoPacket.h"
#import <VideoToolbox/VideoToolbox.h>

@interface HardDecoder : NSObject{
    
    VTDecompressionSessionRef mDecoderSession;
    CMVideoFormatDescriptionRef mDecoderFormatDesc;
    
    uint8_t *_sps;
    size_t _spsSize;
    uint8_t *_pps;
    size_t _ppsSize;
    uint8_t *_sei;
    size_t _seiSize;
    
    CVPixelBufferRef _pixelBuffer;
}

-(CVPixelBufferRef)decode2Surface:(VideoPacket *)vp;

@end
