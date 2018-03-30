//
//  AudioPlayer.h
//  GKCamara
//
//  Created by 张乐昌 on 17/7/10.
//  Copyright © 2017年 张乐昌. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

#define QUEUE_BUFFER_SIZE 6 //队列缓冲个数
#define MIN_SIZE_PER_FRAME 2000 //每帧最小数据长度

@interface AudioPlayer : NSObject{
    
    BOOL audioQueueUsed[QUEUE_BUFFER_SIZE];
    NSLock* sysnLock;
    
    AudioStreamBasicDescription audioDescription;
    AudioQueueRef audioQueue;
    AudioQueueBufferRef audioQueueBuffers[QUEUE_BUFFER_SIZE];
}

-(id)init;
-(void)reset;
-(void)stop;
-(void)play:(void*)pcmData length:(unsigned int)length;

@end
