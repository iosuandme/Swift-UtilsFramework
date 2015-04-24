//
//  UISeparatorLineView.swift
//  ExamWinnerSwift
//
//  Created by 李招利 on 14/9/21.
//  Copyright (c) 2014年 Jintianyu Culture Communication Co., Ltd. All rights reserved.
//

import UIKit

class UISeparatorLineView: UIView {

    var separatorLineColor = UIColor(white: 200/255, alpha: 1)

    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        let context = UIGraphicsGetCurrentContext()
        
        CGContextSetStrokeColorWithColor(context, separatorLineColor.CGColor)
        CGContextSetLineWidth(context, 1)
        
        CGContextMoveToPoint(context, 15, rect.height);
        CGContextAddLineToPoint(context, rect.width, rect.height)
        
        CGContextStrokePath(context);

    }

}
