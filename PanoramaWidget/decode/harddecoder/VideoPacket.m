//
//  VideoPacket.m
//  GKCamara
//
//  Created by 张乐昌 on 17/6/28.
//  Copyright © 2017年 张乐昌. All rights reserved.
//

#import "VideoPacket.h"

@implementation VideoPacket

@synthesize buffer;
@synthesize size;
@synthesize type;

- (instancetype)initWithSize:(NSInteger)size
{
    self = [super init];
    self.buffer = (uint8_t*)malloc(size);
    self.size   = (NSInteger)size;
    return self;
}

-(void)dealloc
{
    if(self.buffer){
        free(self.buffer);
        self.buffer = NULL;
    }
}

@end
