//
//  ParseFrame.h
//  GKCamara
//
//  Created by 张乐昌 on 17/6/10.
//  Copyright © 2017年 张乐昌. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VideoPacket.h"

@interface ParseFrame : NSObject{
    
    uint8_t* _frame;
    int _len;
    int _currentPos;
    
    uint8_t* _bakFrame;
}

// 设置一帧数据并保存到本地
-(void)init:(uint8_t*)frame len:(int)len;

// 获取下一个NALU
-(VideoPacket*)GetNextNalu;

// 释放本地资源
-(void)uint;


@end
