//
//  VideoPacket.h
//  GKCamara
//
//  Created by 张乐昌 on 17/6/28.
//  Copyright © 2017年 张乐昌. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef NS_ENUM(NSInteger, FRAMETYPE){
    
    I_FRAME = 1,    // I帧
    P_FRAME = 2,    // P帧
    A_FRAME = 3     // 音频帧
};

@interface VideoPacket : NSObject{
    
    uint8_t* buffer;
    size_t size;
    FRAMETYPE type;
}

@property(nonatomic, assign) uint8_t* buffer;
@property(nonatomic, assign) size_t size;
@property(nonatomic, assign) FRAMETYPE type;

-(instancetype)initWithSize:(NSInteger)size;

@end
