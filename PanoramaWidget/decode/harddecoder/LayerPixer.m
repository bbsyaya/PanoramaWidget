//
//  LayerPixer.m
//  DORADemo
//
//  Created by 张乐昌 on 2017/11/14.
//  Copyright © 2017年 张乐昌. All rights reserved.
//


#import "LayerPixer.h"
#import "VideoFileParser.h"
#import "Parameter.h"


typedef uint32_t uint32, uint32_be, uint32_le;

@interface LayerPixer()
{
    uint8_t *_sps;
    NSInteger _spsSize;
    uint8_t *_pps;
    NSInteger _ppsSize;
    uint8_t *_sei;
    NSInteger _seiSize;
    int counts;
    NSString *_fileName;
    NSString *_fileType;
    
    VTDecompressionSessionRef _deocderSession;
    CMVideoFormatDescriptionRef _decoderFormatDescription;
}
@property(nonatomic,strong)NSMutableData *h264d;
@end

@implementation LayerPixer

-(NSData *)h264d
{
    if (!_h264d) {
        NSString *path = [[NSBundle mainBundle] pathForResource:_fileName ofType:_fileType];
        _h264d = [NSMutableData dataWithContentsOfFile:path options:NSDataReadingMappedIfSafe error:nil];
        NSMutableData *data = [NSMutableData dataWithBytes:KStartCode length:4];
        [_h264d appendData:data];
    }
    return _h264d;
}

//返回根目录路径 "document"
- (NSString *)getDocumentPath{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [paths firstObject];
    return documentPath;
}
-(void)decodeFile:(NSString *)path
{
    NSAssert(path, @"文件路径为空");
    NSString *fullName = [path componentsSeparatedByString:@"/"].lastObject;
    _fileType = [fullName componentsSeparatedByString:@"."].lastObject;
    _fileName = [fullName componentsSeparatedByString:[NSString stringWithFormat:@".%@",_fileType]].firstObject;
    [self decodeFile:_fileName fileExt:_fileType];
}

BOOL isWait = false;
-(void)decodeFile:(NSString*)fileName fileExt:(NSString*)fileExt
{
    _fileName = fileName;
    _fileType = fileExt;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        while (true) {
            if (_closeFileParser || !self.h264d)
            {
                isWait = false;
                break;
            }
            [self distributepackOf:self.h264d];
            [NSThread sleepForTimeInterval:0.05];

        }
    });
}

-(void)distributepackOf:(NSData *)inputData
{
    VideoFileParser *parser = [VideoFileParser alloc];
    [parser open:inputData];
    VideoPacket *vp = nil;
    while(true)
    {
        if (_closeFileParser) {
            isWait = false;
            break;
        }
        vp = [parser nextPacket];
        if(vp == nil)
        {
            break;
        }
        [self anlyseFrameVideoPack:vp];
        [NSThread sleepForTimeInterval:0.05];
    }
    [parser close];
    return;
}

-(void)anlyseFrameVideoPack:(VideoPacket *)vp
{
    if (vp.size < 5) {
        return;
    }
    FRAMETYPE type;
    int nalType = 0;
    if (memcmp(vp.buffer, KStartCode, 4)) {
        nalType = vp.buffer[3] & 0x1F;
    }else if(memcmp(vp.buffer, KStartSEICode, 3)){
        nalType = vp.buffer[4] & 0x1F;
    }
    switch (nalType)
    {
        case 0x05:
            type = I_FRAME;
            NSLog(@"🍑🍑->I size = %ld",vp.size);
            break;
        case 0x07:
            type = P_FRAME;
            NSLog(@"🍑🍑->SPS = %ld",vp.size);
            break;
        case 0x08:
            type = P_FRAME;
            NSLog(@"🍑🍑->PPS = %ld",vp.size);
            break;
        case 0x06: //SEI
            type = P_FRAME;
            NSLog(@"🍑🍑->SEI = %ld",vp.size);
            break;
        default:
            type = P_FRAME;
            NSLog(@"🍑🍑->P = %ld",vp.size);
            break;
    }
    vp.type = type;
    if ([_delegate respondsToSelector:@selector(sortPackData:)]) {
        [_delegate sortPackData:vp];
    }
}

@end

