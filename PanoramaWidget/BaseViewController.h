//
//  BaseViewController.h
//  PanoramaWidget
//
//  Created by 张乐昌 on 2018/3/29.
//  Copyright © 2018年 张乐昌. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BaseViewController : UIViewController

-(UIBarButtonItem *)createBarButtonWithBackgroundImage:(NSString *)iconName SELfun:(SEL)clickAction;

@end
