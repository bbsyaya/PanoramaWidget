//
//  HardDecoder+Translater.h
//  GKCamara
//
//  Created by 张乐昌 on 2018/2/6.
//  Copyright © 2018年 张乐昌. All rights reserved.
//

#import "HardDecoder.h"
#import <UIKit/UIKit.h>

@interface HardDecoder (Translater)
-(UIImage *)translate:(uint8_t *)iframe length:(NSUInteger)length;
@end
