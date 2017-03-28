//
//  pregressView.m
//  videoTest
//
//  Created by SapientiaWind on 17/3/27.
//  Copyright © 2017年 Social Capital Consulting Limited. All rights reserved.
//

#import "ProgressView.h"




@implementation ProgressView

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    [self.color set];
    if (self.isCompleted == true){
        self.finishAngle = 2 * M_PI - M_PI_2;
    }
    
    UIBezierPath *aPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(self.frame.size.width * 0.5,self.frame.size.width * 0.5) radius:self.frame.size.width * 0.5 - 2 startAngle:self.beginAngle endAngle:self.finishAngle clockwise:true];
    
    //        aPath.addLine(to: CGPoint(x: self.width * 0.5, y: self.width * 0.5))
    //        aPath.close()
    aPath.lineWidth = self.lineWidth; // 线条宽度
 // Draws line 根据坐标点连线，填充
    [aPath stroke];
    self.finishAngle += M_PI/30;

}


@end
