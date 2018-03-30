
//
//  VideoFileParser.m
//  DORADemo
//
//  Created by wuping on 2017/11/14.
//  Copyright © 2017年 DORAPlayer. All rights reserved.
//
#import <Foundation/Foundation.h>
#include "VideoFileParser.h"
#import "Parameter.h"



@interface VideoFileParser ()
{
    uint8_t *_buffer;
    NSInteger _bufferSize;
    NSInteger _bufferCap;
    uint8_t *originalBuffer;
    NSInteger originalSize;
}
@property NSData *inputData;
@property NSInputStream *dataStream;
@end

@implementation VideoFileParser

-(BOOL)open:(NSData*)inputData
{
    _bufferSize = 0;
    _bufferCap = 512 * 1024;
    _buffer = malloc(_bufferCap);
    self.inputData = inputData;
    self.dataStream = [NSInputStream inputStreamWithData:inputData];
    [self.dataStream open];
    return YES;
}

-(BOOL)openData:(char *)inputs Length:(NSInteger)length
{
    self.paserSize = length;
    self.paserBuffer = malloc(length);
    memcpy(self.paserBuffer, inputs, length);
    return YES;
}


-(VideoPacket *)nextPacketOf:(uint8_t *)CapBuf
{
    return nil;
}
-(VideoPacket *)nextCharsPackets
{
    return nil;
}

-(VideoPacket *)nextOriginalPaceket
{
    if(memcmp(_paserBuffer, KStartCode, 4) != 0)
    {
        return nil;
    }
    if(_paserSize >= 5)
    {
        uint8_t *bufferBegin = _paserBuffer+4;
        uint8_t *bufferEnd   = _paserBuffer + _paserSize;
        while(bufferBegin != bufferEnd) {
            if(*bufferBegin == 1)
            {
                if(memcmp(bufferBegin - 3, KStartCode, 4) == 0)
                {
                    NSInteger packetSize = bufferBegin - _paserBuffer - 3;
                    VideoPacket *vp = [[VideoPacket alloc] initWithSize:packetSize];
                    memcpy(vp.buffer, _paserBuffer, packetSize);
                    memmove(_paserBuffer, _paserBuffer + packetSize, _paserSize - packetSize);
                    _paserSize -= packetSize;
                    return vp;
                }
            }
            ++bufferBegin;
        }
    }
    return nil;
}

-(VideoPacket*)nextPacket
{
    if(_bufferSize < _bufferCap && self.dataStream.hasBytesAvailable) {
        NSInteger readBytes = [self.dataStream read:_buffer + _bufferSize maxLength:_bufferCap - _bufferSize];
        _bufferSize += readBytes;
    }
    if(memcmp(_buffer, KStartCode, 4) != 0 && memcmp(_buffer, KStartSEICode, 3) != 0)
    {
        return nil;
    }
    if(_bufferSize >= 5)
    {
        uint8_t *bufferBegin = _buffer+4;
        uint8_t *bufferEnd   = _buffer + _bufferSize;
        while(bufferBegin != bufferEnd) {
            if(*bufferBegin == 1)
            {
                
                if (memcmp(bufferBegin-2 , KStartSEICode, 3) == 0) {
                    if(memcmp(bufferBegin - 3, KStartCode, 4) == 0)
                    {
                        NSInteger packetSize = bufferBegin - _buffer - 3;
                        VideoPacket *vp = [[VideoPacket alloc] initWithSize:packetSize];
                        memcpy(vp.buffer, _buffer, packetSize);
                        memmove(_buffer, _buffer + packetSize, _bufferSize - packetSize);
                        _bufferSize -= packetSize;
//                        [self logByte:vp.buffer Len:vp.size Str:@"______KStartSEICode"];
                        return vp;
                    }
                    NSInteger packetSize = bufferBegin - _buffer - 2;
                    VideoPacket *vp = [[VideoPacket alloc] initWithSize:packetSize];
                    memcpy(vp.buffer, _buffer, packetSize);
                    memmove(_buffer, _buffer + packetSize, _bufferSize - packetSize);
                    _bufferSize -= packetSize;
//                    [self logByte:vp.buffer Len:vp.size Str:@"______KStartCode"];

                    return vp;
                }
            }
            ++bufferBegin;
        }
    }
    return nil;
}



-(void)close
{
    free(_buffer);
    _buffer = NULL;
    [self.dataStream close];
}

-(void)closeDataPaser
{
    free(_paserBuffer);
    _paserBuffer = NULL;
}

@end
