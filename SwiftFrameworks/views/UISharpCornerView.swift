//
//  UISharpCornerView.swift
//  ExamWinnerSwift
//
//  Created by 李招利 on 14/10/23.
//  Copyright (c) 2014年 Jintianyu Culture Communication Co., Ltd. All rights reserved.
//

import UIKit

class UISharpCornerView: UIView {
    
    var titleWidth:CGFloat = 62.0
//    @IBInspectable var titleWidth:CGFloat = 50.0
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.setNeedsDisplay()
    }
    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        
        //let bnil = self.backgroundView == nil
        //self.backgroundView = nil

        let verticalCenter = rect.height / 2.0
        
        let context = UIGraphicsGetCurrentContext()
        
        let backgroundColor = self.backgroundColor ?? UIColor.whiteColor()
        
        CGContextSetFillColorWithColor(context, backgroundColor.CGColor)
        CGContextFillRect(context,rect)
        // Set the stroke color to light gray
        //设置边线颜色和线宽
        CGContextSetStrokeColorWithColor(context, UIColor.lightGrayColor().CGColor)
        CGContextSetLineWidth(context, 0.5);
        
        //绘制边线
        CGContextMoveToPoint(context, titleWidth, 0.0);
        CGContextAddLineToPoint(context, titleWidth, verticalCenter - 5);
        CGContextAddLineToPoint(context, titleWidth - 5, verticalCenter);
        CGContextAddLineToPoint(context, titleWidth, verticalCenter + 5);
        CGContextAddLineToPoint(context, titleWidth, rect.height);
        //CGContextMoveToPoint(context, 0.0, rect.height);
        //CGContextAddLineToPoint(context, rect.width, rect.height);
        
        //开始绘制
        CGContextStrokePath(context);
        // UIColor.lightGrayColor().setStroke()
        //绘制背景
        CGContextMoveToPoint(context, titleWidth, 0.0);
        CGContextAddLineToPoint(context, titleWidth, verticalCenter - 5);
        CGContextAddLineToPoint(context, titleWidth - 5, verticalCenter);
        CGContextAddLineToPoint(context, titleWidth, verticalCenter + 5);
        CGContextAddLineToPoint(context, titleWidth, rect.height);
        CGContextAddLineToPoint(context, 0.0, rect.height);
        
        //补充闭合
        CGContextAddLineToPoint(context, 0.0, rect.height);
        CGContextAddLineToPoint(context, 0.0, 0.0);
        CGContextAddLineToPoint(context, titleWidth, 0.0);
        
        //设置填充
        CGContextSetFillColorWithColor(context, UIColor(white: 0.9, alpha: 0.3).CGColor)
        CGContextFillPath(context);
        //        CGContextDrawPath(context,kCGPathFillStroke)
        
    }
    

}
