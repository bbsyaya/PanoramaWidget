
//
//  HardDecoder.m
//  GKCamara
//
//  Created by张乐昌 on 17/6/28.
//  Copyright © 2017年 张乐昌. All rights reserved.
//

#import "HardDecoder.h"
#import "Parameter.h"

static void doDecompress( void *decompressionOutputRefCon, void *sourceFrameRefCon, OSStatus status, VTDecodeInfoFlags infoFlags, CVImageBufferRef pixelBuffer, CMTime presentationTimeStamp, CMTime presentationDuration ){
    
    CVPixelBufferRef *outputPixelBuffer = (CVPixelBufferRef *)sourceFrameRefCon;
    *outputPixelBuffer = CVPixelBufferRetain(pixelBuffer);
}


@implementation HardDecoder

-(BOOL)initDecoderSps:(uint8_t*)sps spsLen:(size_t)spsLen Pps:(uint8_t*)pps ppsLen:(size_t)ppsLen Sei:(uint8_t *)sei seiSize:(size_t)seiLen{
    
    if(mDecoderSession) return YES;
    if (!_seiSize) {
        const uint8_t* const setPtParam[2] = {sps, pps};
        const size_t setSizesParam[2] = {spsLen, ppsLen};
        OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault, 2, setPtParam, setSizesParam, 4, &mDecoderFormatDesc);
        if(status == noErr){
            
            /*const void* keys[] = {kCVPixelBufferPixelFormatTypeKey};
             uint32_t v = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange; //YUV420
             const void* values[] = {CFNumberCreate(NULL, kCFNumberSInt32Type, &v)};
             
             CFDictionaryRef attrs = CFDictionaryCreate(NULL, keys, values, 1, NULL,
             NULL);
             VTDecompressionOutputCallbackRecord callbackRecord;
             callbackRecord.decompressionOutputCallback = doDecompress;
             callbackRecord.decompressionOutputRefCon = NULL;
             
             status = VTDecompressionSessionCreate(kCFAllocatorDefault, mDecoderFormatDesc, NULL, attrs, &callbackRecord, &mDecoderSession);*/
            [self resetH264Decoder];
            
            printf("create h264 decoder ok");
        }else{
            printf("create h264 decoder err");
        }
    }else{
        const uint8_t* const setPtParam[3] = {sps, pps, sei};
        const size_t setSizesParam[3] = {spsLen, ppsLen, seiLen};
        OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault, 3, setPtParam, setSizesParam, 4, &mDecoderFormatDesc);
        if(status == noErr){
            /*const void* keys[] = {kCVPixelBufferPixelFormatTypeKey};
             uint32_t v = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange; //YUV420
             const void* values[] = {CFNumberCreate(NULL, kCFNumberSInt32Type, &v)};
             
             CFDictionaryRef attrs = CFDictionaryCreate(NULL, keys, values, 1, NULL,
             NULL);
             VTDecompressionOutputCallbackRecord callbackRecord;
             callbackRecord.decompressionOutputCallback = doDecompress;
             callbackRecord.decompressionOutputRefCon = NULL;
             
             status = VTDecompressionSessionCreate(kCFAllocatorDefault, mDecoderFormatDesc, NULL, attrs, &callbackRecord, &mDecoderSession);*/
            [self resetH264Decoder];
            
            printf("create h264 decoder ok");
        }else{
            printf("create h264 decoder err");
        }
    }
    

    
    return YES;
}

-(CVPixelBufferRef)decode:(VideoPacket*)vp{
    
    CVPixelBufferRef outputPixelBuffer = NULL;
    CMBlockBufferRef blockBuffer = NULL;
    OSStatus status  = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault,(void*)vp.buffer, vp.size,
                                kCFAllocatorNull,NULL, 0, vp.size, 0, &blockBuffer);
    
    if(status == kCMBlockBufferNoErr){
        
        CMSampleBufferRef sampleBuffer = NULL;
        const size_t sampleSizeArray[] = {vp.size};
        status = CMSampleBufferCreateReady(kCFAllocatorDefault, blockBuffer, mDecoderFormatDesc ,
                                           1, 0, NULL, 1, sampleSizeArray, &sampleBuffer);
        if(status == kCMBlockBufferNoErr && sampleBuffer){
            VTDecodeFrameFlags flags = 0;
            VTDecodeInfoFlags flagOut = 0;
            // 解码
            OSStatus decodeStatus = VTDecompressionSessionDecodeFrame(mDecoderSession, sampleBuffer, flags,
                                            &outputPixelBuffer, &flagOut);
            if(decodeStatus == kVTInvalidSessionErr){
                printf("invalid session");
//                [self resetH264Decoder];
                [self unitDecoder];
            }else if(decodeStatus == kVTVideoDecoderBadDataErr){
                [self unitDecoder];
                printf("decode err");
            }else if(decodeStatus != noErr){
                [self unitDecoder];
                printf("decode other err");
            }
            // NSLog(@"decode ok");
            CFRelease(sampleBuffer);
        }
        
        CFRelease(blockBuffer);
    }

    return outputPixelBuffer; // NULL失败
}

-(void)unitDecoder{
    
    if(mDecoderSession){
        VTDecompressionSessionInvalidate(mDecoderSession);
        CFRelease(mDecoderSession);
        mDecoderSession = NULL;
    }
    
    if(mDecoderFormatDesc){
        CFRelease(mDecoderFormatDesc);
        mDecoderFormatDesc = NULL;
    }
    if (_spsSize) {
        free(_sps);
        _spsSize = 0;
    }
    if (_ppsSize) {
        free(_pps);
        _ppsSize = 0;
    }
    if (_seiSize) {
        free(_sei);
        _seiSize = 0;
    }
    NSLog(@"release decoder ok");
}
-(void)logByte:(uint8_t *)bytes Len:(int)len Str:(NSString *)str
{
    NSMutableString *tempMStr=[[NSMutableString alloc] init];
    for (int i=0;i<len;i++)
        [tempMStr appendFormat:@"%0x ",bytes[i]];
    NSLog(@"%@ == %@",str,tempMStr);
}
-(CVPixelBufferRef)decode2Surface:(VideoPacket *)vp{
    [self logByte:vp.buffer Len:20 Str:@"vvvvvvv"];
    uint32_t kSize    = 0;
    uint32_t nalSize;
    uint8_t *pNalSize = (uint8_t*)(&nalSize);
    int nalType = 0;
    if (memcmp(vp.buffer, KStartCode, 4) == 0) {
        nalSize = (uint32_t)(vp.size)-4;
        vp.buffer[0] = *(pNalSize + 3);
        vp.buffer[1] = *(pNalSize + 2);
        vp.buffer[2] = *(pNalSize + 1);
        vp.buffer[3] = *(pNalSize);
        kSize = 4;
        nalType = vp.buffer[4] & 0x1F;
    }else if(memcmp(vp.buffer, KStartSEICode, 3) == 0){
        nalSize = (uint32_t)(vp.size -3);
        vp.buffer[0] = *(pNalSize + 2);
        vp.buffer[1] = *(pNalSize + 1);
        vp.buffer[2] = *(pNalSize);
        kSize = 3;
        nalType = vp.buffer[3] & 0x1F;
    }
    _pixelBuffer = NULL;
    switch (nalType) {
        case 0x05:
            NSLog(@"Nal type is I");
            if ([self initDecoderSps:_sps spsLen:_spsSize Pps:_pps ppsLen:_ppsSize Sei:_sei seiSize:_seiSize]) {
                _pixelBuffer = [self decode:vp];
            }
            break;
        case 0x06:
            NSLog(@"Nal type is SEI");
            if (_seiSize) {
                free(_sei);
                _sei = NULL;
            }
            _seiSize = vp.size - kSize;
            _sei     = (uint8_t *)malloc(_seiSize);
            memset(_sei, 0, _seiSize);
            memcpy(_sei, vp.buffer+kSize, _seiSize);
//            if([self initDecoderSps:_sps spsLen:_spsSize Pps:_pps ppsLen:_ppsSize]) {
//                _pixelBuffer = [self decode:vp];
//            }
            break;
        case 0x07:
            NSLog(@"Nal type is SPS");
            if (_spsSize) {
                free(_sps);
                _sps = NULL;
            }
            _spsSize = vp.size - 4;
            _sps = (uint8_t*)malloc(_spsSize);
            memset(_sps, 0, _spsSize);
            memcpy(_sps, vp.buffer + 4, _spsSize);
            break;
        case 0x08:
            NSLog(@"Nal type is PPS");
            if (_ppsSize) {
                free(_pps);
                _pps = NULL;
            }
             _ppsSize = vp.size - 4;
            _pps = (uint8_t*)malloc(_ppsSize);
            memset(_pps, 0, _ppsSize);
            memcpy(_pps, vp.buffer + 4, _ppsSize);
            break;
            
        default:
            NSLog(@"Nal type is B/P frame");
            _pixelBuffer = [self decode:vp];
            break;
    }
    return _pixelBuffer;
}

- (void)resetH264Decoder
{
    if(mDecoderSession) {
        VTDecompressionSessionInvalidate(mDecoderSession);
        CFRelease(mDecoderSession);
        mDecoderSession = NULL;
    }
    CFDictionaryRef attrs = NULL;
    const void *keys[] = { kCVPixelBufferPixelFormatTypeKey };
    //      kCVPixelFormatType_420YpCbCr8Planar is YUV420
    //      kCVPixelFormatType_420YpCbCr8BiPlanarFullRange is NV12
    uint32_t v = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
    const void *values[] = { CFNumberCreate(NULL, kCFNumberSInt32Type, &v) };
    attrs = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
    
    VTDecompressionOutputCallbackRecord callBackRecord;
    callBackRecord.decompressionOutputCallback = doDecompress;
    callBackRecord.decompressionOutputRefCon = NULL;
    if(VTDecompressionSessionCanAcceptFormatDescription(mDecoderSession, mDecoderFormatDesc))
    {
        NSLog(@"yes");
    }
    
    OSStatus status = VTDecompressionSessionCreate(kCFAllocatorSystemDefault,
                                                   mDecoderFormatDesc,
                                                   NULL, attrs,
                                                   &callBackRecord,
                                                   &mDecoderSession);
    CFRelease(attrs);
}

@end
