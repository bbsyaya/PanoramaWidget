//
//  StateFitter.h
//  PanoramaWidget
//
//  Created by 周勇 on 2018/3/29.
//  Copyright © 2018年 张乐昌. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface StateFitter : NSObject

+(BOOL)nextKey:(NSDictionary *)states currentBoolenKey:(BOOL)key;
+(int)nextKey:(NSDictionary *)states currentIntKey:(int)key;
+(NSNumber *)nextKey:(NSDictionary *)states currentNumKey:(NSNumber *)keyNum;
@end
