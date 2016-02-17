//
//  CGStruct.swift
//  TallyCloud
//
//  Created by 慧趣小歪 on 15/12/22.
//  Copyright © 2015年 小分队. All rights reserved.
//

import Foundation

extension CGRect {
    // 求矩形中心
    var center:CGPoint {
        return CGPoint(x: origin.x + size.width / 2, y: origin.y + size.height / 2)
    }
}


extension CGPoint {
    // 指定圆心, 角度, 半径, 求终点坐标
    static func circlePointAtCenter(center:CGPoint, withAngle angle:CGFloat, andRadius radius:CGFloat) -> CGPoint {
        let radian = Double(angle) * M_PI / 180
        let x = radius * CGFloat(cos(radian))
        let y = radius * CGFloat(sin(radian))
        return CGPointMake(center.x + x, center.y - y)
    }
}