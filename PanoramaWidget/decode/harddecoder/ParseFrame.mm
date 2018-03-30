 
//
//  ParseFrame.m
//  GKCamara
//
//  Created by 张乐昌 on 17/6/10.
//  Copyright © 2017年 张乐昌. All rights reserved.
//

#import "ParseFrame.h"
#import "Parameter.h"

@implementation ParseFrame

-(void)init:(uint8_t*)frame len:(int)len{
    
//    _frame = new uint8_t[len];
    _frame = (uint8_t *)malloc(len+4);
    if (_frame) {
        memset(_frame, 0, len+4);
#pragma mark Thread 16 EXC_BAD_ACCESS(code=1,address=0x10c7d8000)
        memcpy(_frame, frame, len);//crashed
        memcpy(_frame+len, KStartCode, 4);
    }
    _len = len+4;
    _currentPos = 0;
    _bakFrame = _frame;
}

-(VideoPacket*)GetNextNalu{
    if (!_bakFrame || _len < 5) {
        return nil;
    }
    if (memcmp(_bakFrame, KStartCode, 4)) { //crashed
        return nil;
    }
    if(_len > 5){
        uint8_t* bufferBegin = _bakFrame+4; // 640
        uint8_t* bufferEnd = _bakFrame+_len;
        while(bufferBegin != bufferEnd) {
            if (*bufferBegin == 1)
            {
                if(memcmp(bufferBegin - 3, KStartCode, 4) == 0) {
                    
                    NSInteger packetSize = bufferBegin - _bakFrame - 3;
                    VideoPacket *vp = [[VideoPacket alloc] initWithSize:packetSize];
                    memcpy(vp.buffer, _bakFrame, packetSize);
                    memmove(_bakFrame, _bakFrame+packetSize, _len-packetSize);
                    //_bakFrame = _bakFrame + packetSize;
                    _len -= packetSize;
                    vp.size = packetSize;
                    return vp;
                }
            }
            ++bufferBegin;
        }
        return nil;
    }
    
    return nil;
}

-(void)uint{
    
    if(_frame){
//        delete _frame;
        free(_frame);
        _frame = NULL;
    }
    _bakFrame = NULL;
}


@end
