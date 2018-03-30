//
//  AudioPlayer.m
//  GKCamara
//
//  Created by 张乐昌 on 17/7/10.
//  Copyright © 2017年 张乐昌. All rights reserved.
//

#import "AudioPlayer.h"

@implementation AudioPlayer


-(id)init
{
    self = [super init];
    if (self) {
        [self reset];
    }
    return self;
}

-(void)dealloc
{
    if (audioQueue != nil) {
        AudioQueueStop(audioQueue, true);
    }
    audioQueue = nil;
    
    sysnLock = nil;
    
    NSLog(@"PCMDataPlayer dealloc...");
}

static void AudioPlayerAQInputCallback(void* inUserData, AudioQueueRef outQ, AudioQueueBufferRef outQB)
{
    AudioPlayer* player = (__bridge AudioPlayer*)inUserData;
    [player playerCallback:outQB];
}

- (void)reset
{
    [self stop];
    
    sysnLock = [[NSLock alloc] init];
    
    ///设置音频参数
    audioDescription.mSampleRate = 16000; //采样率
    audioDescription.mFormatID = kAudioFormatLinearPCM;
    audioDescription.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    audioDescription.mChannelsPerFrame = 1; ///单声道
    audioDescription.mFramesPerPacket = 1; //每一个packet一侦数据
    audioDescription.mBitsPerChannel = 16; //每个采样点16bit量化
    audioDescription.mBytesPerFrame = (audioDescription.mBitsPerChannel / 8) * audioDescription.mChannelsPerFrame;
    audioDescription.mBytesPerPacket = audioDescription.mBytesPerFrame;
    
    AudioQueueNewOutput(&audioDescription, AudioPlayerAQInputCallback, (__bridge void*)self, nil, nil, 0, &audioQueue); //使用player的内部线程播放
    
    //初始化音频缓冲区
    for (int i = 0; i < QUEUE_BUFFER_SIZE; i++) {
        int result = AudioQueueAllocateBuffer(audioQueue, MIN_SIZE_PER_FRAME, &audioQueueBuffers[i]); ///创建buffer区，MIN_SIZE_PER_FRAME为每一侦所需要的最小的大小，该大小应该比每次往buffer里写的最大的一次还大
        NSLog(@"AudioQueueAllocateBuffer i = %d,result = %d", i, result);
    }
    
    NSLog(@"PCMDataPlayer reset");
}

- (void)stop
{
    if (audioQueue != nil) {
        AudioQueueStop(audioQueue, true);
        AudioQueueReset(audioQueue);
    }
    
    audioQueue = nil;
}

- (void)play:(void*)pcmData length:(unsigned int)length
{
    if (audioQueue == nil || ![self checkBufferHasUsed]) {
        [self reset];
         OSStatus qStatus = AudioQueueStart(audioQueue, NULL);
        if (qStatus) {
            NSLog(@"AudioQueueStart ErrCode = %d",qStatus);
        }
    }
    
    [sysnLock lock];
    
    AudioQueueBufferRef audioQueueBuffer = NULL;
    
    while (true) {
        audioQueueBuffer = [self getNotUsedBuffer];
        if (audioQueueBuffer != NULL) {
            break;
        }
    }
    
    audioQueueBuffer->mAudioDataByteSize = length;
    Byte* audiodata = (Byte*)audioQueueBuffer->mAudioData;
    for (int i = 0; i < length; i++) {
        audiodata[i] = ((Byte*)pcmData)[i];
    }
    
    OSStatus eStatus = AudioQueueEnqueueBuffer(audioQueue, audioQueueBuffer, 0, NULL);
    if (eStatus) {
        NSLog(@"AudioQueueEnqueueBuffer ErrCode = %d",eStatus);
    }
    NSLog(@"PCMDataPlayer play dataSize:%d", length);
    [sysnLock unlock];
}

- (BOOL)checkBufferHasUsed
{
    for (int i = 0; i < QUEUE_BUFFER_SIZE; i++) {
        if (YES == audioQueueUsed[i]) {
            return YES;
        }
    }
    NSLog(@"PCMDataPlayer 播放中断............");
    return NO;
}

- (AudioQueueBufferRef)getNotUsedBuffer
{
    for (int i = 0; i < QUEUE_BUFFER_SIZE; i++) {
        if (NO == audioQueueUsed[i]) {
            audioQueueUsed[i] = YES;
            NSLog(@"PCMDataPlayer play buffer index:%d", i);
            return audioQueueBuffers[i];
        }
    }
    return NULL;
}

- (void)playerCallback:(AudioQueueBufferRef)outQB
{
    for (int i = 0; i < QUEUE_BUFFER_SIZE; i++) {
        if (outQB == audioQueueBuffers[i]) {
            audioQueueUsed[i] = NO;
        }
    }
}


@end
