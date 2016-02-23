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
    func circlePointWithAngle(angle:CGFloat, andRadius radius:CGFloat) -> CGPoint {
        return CGPoint.circlePointAtCenter(self, withAngle: angle, andRadius: radius)
    }
    
    // 计算某点到中心的角度
    static func angleWithCenter(center:CGPoint, atPoint point:CGPoint) -> CGFloat {
        let width  = center.x - point.x
        let height = point.y - center.y
        let radian = atan( height / width )
        var result = 180.0 * radian / CGFloat(M_PI)
        if width >= 0 {
            result += 180.0
        } else if height >= 0 {
            result += 360.0
        }
        return result
    }
    func angleWithCenter(center:CGPoint) -> CGFloat {
        return CGPoint.angleWithCenter(center, atPoint: self)
    }
    
}