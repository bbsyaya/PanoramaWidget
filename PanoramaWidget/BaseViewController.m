//
//  BaseViewController.m
//  PanoramaWidget
//
//  Created by 张乐昌 on 2018/3/29.
//  Copyright © 2018年 张乐昌. All rights reserved.
//

#import "BaseViewController.h"

@interface BaseViewController ()

@end

@implementation BaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(UIBarButtonItem *)createBarButtonWithBackgroundImage:(NSString *)iconName SELfun:(SEL)clickAction
{
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    [btn addTarget:self action:clickAction forControlEvents:UIControlEventTouchUpInside];
    [btn setBackgroundImage:[UIImage imageNamed:iconName] forState:UIControlStateNormal];
    UIBarButtonItem *btnItem = [[UIBarButtonItem alloc]initWithCustomView:btn];
    return btnItem;
}

@end
