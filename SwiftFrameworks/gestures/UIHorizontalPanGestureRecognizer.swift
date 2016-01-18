//
//  UIHorizontalPanGestureRecognizer.swift
//  TallyCloud
//
//  Created by 慧趣小歪 on 16/1/18.
//  Copyright © 2016年 小分队. All rights reserved.
//

import UIKit

class UIHorizontalPanGestureRecognizer: UIPanGestureRecognizer {

    var firstMoved:Bool = false
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent) {
        super.touchesBegan(touches, withEvent: event)
        firstMoved = true
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent) {
        super.touchesMoved(touches, withEvent: event)
        if firstMoved {
            let firstTouch = touches.first!
            let point = firstTouch.locationInView(firstTouch.window)
            let previousPoint = firstTouch.previousLocationInView(firstTouch.window)
            if abs(point.x - previousPoint.x) < abs(point.y - previousPoint.y) {
                state = .Failed
            }
        }
        firstMoved = false
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent) {
        super.touchesEnded(touches, withEvent: event)
        firstMoved = false
    }
}
