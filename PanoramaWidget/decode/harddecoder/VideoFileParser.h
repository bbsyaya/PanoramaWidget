//
//  VideoFileParser.h
//  DORADemo
//
//  Created by 张乐昌 on 2017/11/14.
//  Copyright © 2017年 张乐昌. All rights reserved.
//

#include <objc/NSObject.h>
#import "VideoPacket.h"

@interface VideoFileParser : NSObject
@property(nonatomic,assign)uint8_t *paserBuffer;   //原始数据
@property(nonatomic,assign)NSInteger paserSize;    //原始数据长度
-(BOOL)open:(NSData*)inputData;
-(BOOL)openData:(char *)inputs Length:(NSInteger)length;
-(VideoPacket *)nextPacket;
-(VideoPacket *)nextOriginalPaceket;
-(void)close;
-(void)closeDataPaser;

@end
