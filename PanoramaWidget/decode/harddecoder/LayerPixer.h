//
//  LayerPixer.h
//  DORADemo
//
//  Created by 张乐昌 on 2017/11/14.
//  Copyright © 2017年 张乐昌. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>
#import "VideoPacket.h"

@protocol PackSortDelegate <NSObject>

-(void)sortPackData:(VideoPacket *)pack;

@end

@interface LayerPixer : NSObject
typedef void(^DecodePiexBufResult)(CVPixelBufferRef ref);           //解码结果回调
@property(nonatomic,weak)id<PackSortDelegate>delegate;
@property(nonatomic,assign)BOOL isKey;
@property(nonatomic,strong)NSString *videoRecordPath;
@property(nonatomic,strong)DecodePiexBufResult pixerResults;
@property (nonatomic, assign) BOOL closeFileParser;

-(void)decodeFile:(NSString*)fileName fileExt:(NSString*)fileExt;

-(void)decodeFile:(NSString *)path;

@end
