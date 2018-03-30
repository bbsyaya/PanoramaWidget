//
//  StateFitter.m
//  PanoramaWidget
//
//  Created by 周勇 on 2018/3/29.
//  Copyright © 2018年 张乐昌. All rights reserved.
//

#import "StateFitter.h"

@implementation StateFitter

+(BOOL)nextKey:(NSDictionary *)states currentBoolenKey:(BOOL)key
{
   return [self nextKey:states currentIntKey:key];
}

+(int)nextKey:(NSDictionary *)states currentIntKey:(int)key
{
    NSArray  *Keys  = states.allKeys;
    NSNumber *kyNum = [NSNumber numberWithInt:key];
    int      ret   = [kyNum intValue];
    if ([kyNum intValue] == (int)[Keys.lastObject intValue]) {
        ret  = (int)[Keys.firstObject intValue];
    }else
    {
        int nextIndex = 0;
        for (NSNumber *num in Keys) {
            nextIndex++;
            if (key == [num intValue]) {
                break;
            }
        }
        ret = (int)[Keys[nextIndex] intValue];
    }
    return ret;
}


+(NSNumber *)nextKey:(NSDictionary *)states currentNumKey:(NSNumber *)keyNum
{
    return [NSNumber numberWithInt:[self nextKey:states currentIntKey:[keyNum intValue]]];
}
@end
