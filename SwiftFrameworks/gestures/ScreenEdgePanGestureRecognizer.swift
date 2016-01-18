//
//  ScreenEdgePanGestureRecognizer.swift
//  TallyCloud
//
//  Created by 慧趣小歪 on 16/1/16.
//  Copyright © 2016年 小分队. All rights reserved.
//

import UIKit
//#import <UIKit/UIGestureRecognizerSubclass.h> 必须引入此头文件

public class ScreenEdgePanGestureRecognizer: UIScreenEdgePanGestureRecognizer {
    
    private enum RectEdge : Int {
        case Left, Right, Top ,Bottom
    }
    
    private var edge:RectEdge = RectEdge.Left
    private var limitationMoved:[CGFloat] = [CGFloat]()
    private func saveMaxMoved(touches: Set<UITouch>) {
        if minimumNumberOfTouches - limitationMoved.count > 0 {
            limitationMoved.appendContentsOf([CGFloat](count: minimumNumberOfTouches - limitationMoved.count, repeatedValue: 0.0))
        }
        
        for var i:Int = 0; i < minimumNumberOfTouches; i++ {
            let index = touches.startIndex.advancedBy(i)
            let began = beganTouches[index]
            let touch = touches[index]
            let point = touch.locationInView(touch.window)
            let beganPoint = began.locationInView(began.window)
            switch edge {
            case .Left:     limitationMoved[i] = max(limitationMoved[i], point.x - beganPoint.x)
            case .Right:    limitationMoved[i] = max(limitationMoved[i], beganPoint.x - point.x)
            case .Top:      limitationMoved[i] = max(limitationMoved[i], point.y - beganPoint.y)
            case .Bottom:   limitationMoved[i] = max(limitationMoved[i], beganPoint.y - point.y)
            }
        }
    }
    
    lazy var beganTouches:Set<UITouch> = []
    
    override public func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent) {
        super.touchesBegan(touches, withEvent: event)
        // 如果不符合最小触碰条件则直接失败
        if touches.count < minimumNumberOfTouches || minimumNumberOfTouches == 0 {
            //print("不符合最小数量")
            state = .Failed
            return
        }
        
        var edgeArray:[RectEdge] = []
        if edges.contains(.Left)    { edgeArray.append(.Left) }
        if edges.contains(.Right)   { edgeArray.append(.Right) }
        if edges.contains(.Top)     { edgeArray.append(.Top) }
        if edges.contains(.Bottom)  { edgeArray.append(.Bottom) }
        
        // 不同方向触控需要符合的条件
        func isValidTouch(point:CGPoint, _ size:CGSize, withEdge edge:RectEdge) -> Bool {
            switch edge {
            case .Left:     return point.x < 25
            case .Right:    return point.x + 25 > size.width
            case .Top:      return point.y < 25
            case .Bottom:   return point.y + 25 > size.height
            }
        }
        
        // 判断多个触控是否同时符合条件
        func validTouches(touches:Set<UITouch>, withEdge edge:RectEdge) -> Bool {
            var validTouches:Set<UITouch> = Set<UITouch>(minimumCapacity: minimumNumberOfTouches)
            
            for var i:Int = 0; i < minimumNumberOfTouches; i++ {
                let touch = touches[touches.startIndex.advancedBy(i)]
                let point = touch.locationInView(touch.window)
                
                let size = touch.window?.bounds.size ?? UIScreen.mainScreen().bounds.size
                // 符合左侧屏幕边缘条件
                if isValidTouch(point, size, withEdge: edge) {
                    validTouches.insert(touch)
                }
            }
            return validTouches.count == minimumNumberOfTouches
        }
        
        for edge in edgeArray {
            if validTouches(touches, withEdge: edge) {
                self.edge = edge
                self.beganTouches = touches
                self.limitationMoved = []
                state = .Began
                return
            }
        }
        //print("1全都不符合失败")
        state = .Failed
    }
    
    
    override public func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent) {
        super.touchesMoved(touches, withEvent: event)
        if case .Failed = state {
            return
        }
        //saveMaxMoved(touches)
        if limitationMoved.count == 0 {
            
            // 如果不符合最小触碰条件则直接失败
            if touches.count < minimumNumberOfTouches || minimumNumberOfTouches == 0 {
                //print("不符合最小数量")
                state = .Failed
                return
            }
            
            // 不同方向触控需要符合的条件
            func isValidTouch(point:CGPoint, _ previousPoint:CGPoint, withEdge edge:RectEdge) -> Bool {
                let absX = abs(previousPoint.x - point.x)
                let absY = abs(previousPoint.y - point.y)
                switch edge {
                case .Left:     return previousPoint.x < point.x && absX > absY
                case .Right:    return previousPoint.x > point.x && absX > absY
                case .Top:      return previousPoint.y < point.y && absX < absY
                case .Bottom:   return previousPoint.y > point.y && absX < absY
                }
            }
            
            // 判断多个触控是否同时符合条件
            
            var validTouches:Set<UITouch> = Set<UITouch>(minimumCapacity: minimumNumberOfTouches)
            
            for var i:Int = 0; i < minimumNumberOfTouches; i++ {
                let touch = touches[touches.startIndex.advancedBy(i)]
                let point = touch.locationInView(touch.window)
                let previousPoint = touch.previousLocationInView(touch.window)
                // 符合左侧屏幕边缘条件
                if isValidTouch(point, previousPoint, withEdge: edge) {
                    validTouches.insert(touch)
                }
            }
            
            if validTouches.count == minimumNumberOfTouches {
                self.limitationMoved = [CGFloat](count: minimumNumberOfTouches, repeatedValue: 0)
                saveMaxMoved(touches)
                state = .Changed
            } else {
                state = .Failed
                //print("2全都不符合失败\(edge)")
            }
            return
        }
        saveMaxMoved(touches)
        state = .Changed
    }
    
    override public func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent) {
        super.touchesEnded(touches, withEvent: event)
        
        if case .Failed = state {
            return
        }
        
        for var i:Int = 0; i < minimumNumberOfTouches; i++ {
            let index = touches.startIndex.advancedBy(i)
            let began = beganTouches[index]
            let touch = touches[index]
            let point = touch.locationInView(touch.window)
            let beganPoint = began.locationInView(began.window)
            switch edge {
            case .Left:
                let moved = point.x - beganPoint.x
                if moved < 30 || moved + 50.0 < limitationMoved[i] {
                    state = .Cancelled
                    return
                }
            case .Right:
                let moved = beganPoint.x - point.x
                if moved < 30 || moved + 50.0 < limitationMoved[i] {
                    state = .Cancelled
                    return
                }
            case .Top:
                let moved = point.y - beganPoint.y
                if moved < 30 || moved + 50.0 < limitationMoved[i] {
                    state = .Cancelled
                    return
                }
            case .Bottom:
                let moved = beganPoint.y - point.y
                if moved < 30 || moved + 50.0 < limitationMoved[i] {
                    state = .Cancelled
                    return
                }
            }
        }
        state = UIGestureRecognizerState.Recognized
        
    }
    
    
    
}
