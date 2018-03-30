//
//  ViewController.m
//  PanoramaWidget
//
//  Created by 张乐昌 on 2018/3/27.
//  Copyright © 2018年 张乐昌. All rights reserved.
//

#import "ViewController.h"
#import "KxMovieViewController.h"
#import "H264ViewController.h"
#import "PhotoViewController.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

}

- (IBAction)playmkv:(id)sender {
    [self playMedia:LOCALFILE(@"panorama", @"mkv")];
}


- (IBAction)playmp4:(id)sender {
    [self playMedia:LOCALFILE(@"panorama", @"mp4")];
}


- (IBAction)playm4v:(id)sender {
    [self playMedia:LOCALFILE(@"panorama", @"m4v")];

}

- (IBAction)viewpicture:(id)sender {
    [self showPicture:LOCALFILE(@"panorama", @"jpeg")];
}

- (IBAction)playh264:(id)sender {
    [self playNakedFlow:LOCALFILE(@"panorama", @"h264")];
}

-(void)playNakedFlow:(NSString *)path
{
    H264ViewController *h264vc = [[H264ViewController alloc] init];
    [self.navigationController pushViewController:h264vc animated:YES];
}

-(void)showPicture:(NSString *)path
{
     PhotoViewController *photo = [[PhotoViewController alloc]initWithPath:path];
    [self.navigationController pushViewController:photo animated:YES];
}

-(void)playMedia:(NSString *)path
{
    NSAssert(path != NULL, @"media Path Error");
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if ([path.pathExtension isEqualToString:@"wmv"])
        parameters[KxMovieParameterMinBufferedDuration] = @(5.0);
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        parameters[KxMovieParameterDisableDeinterlacing] = @(YES);
    KxMovieViewController *vc = [KxMovieViewController movieViewControllerWithContentPath:path
                                                                               parameters:parameters];
    [self presentViewController:vc animated:YES completion:nil];
}




@end
