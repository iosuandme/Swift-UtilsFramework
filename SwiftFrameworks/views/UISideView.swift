//
//  UISideView.swift
//  ExamWinnerSwift
//
//  Created by 李招利 on 14/10/28.
//  Copyright (c) 2014年 Jintianyu Culture Communication Co., Ltd. All rights reserved.
//

import UIKit

class UISideView: UIView {

    var separatorLineColor = UIColor(white: 200/255, alpha: 1)
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        let context = UIGraphicsGetCurrentContext()
        
        CGContextSetStrokeColorWithColor(context, separatorLineColor.CGColor)
        CGContextSetLineWidth(context, 1)
        
        //        CGContextMoveToPoint(context, 15, 0);
        //        CGContextAddLineToPoint(context, rect.width, 0)
        
        CGContextMoveToPoint(context, 0, 0);
        CGContextAddLineToPoint(context, 0, rect.height)

        CGContextMoveToPoint(context, rect.width, 0);
        CGContextAddLineToPoint(context, rect.width, rect.height)
        
        CGContextStrokePath(context);
        
        // Drawing code
    }

}
