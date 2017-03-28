//
//  pregressView.h
//  videoTest
//
//  Created by SapientiaWind on 17/3/27.
//  Copyright © 2017年 Social Capital Consulting Limited. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProgressView : UIView
@property (nonatomic, assign) CGFloat beginAngle;
@property (nonatomic, assign) CGFloat finishAngle;
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, assign) BOOL isCompleted;
@property (nonatomic, assign) CGFloat lineWidth;
@end
