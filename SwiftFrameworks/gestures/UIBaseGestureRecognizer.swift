//
//  UITapDownGestureRecognizer.swift
//  TallyCloud
//
//  Created by 招利 李 on 15/12/21.
//  Copyright © 2015年 小分队. All rights reserved.
//

import UIKit
//#import <UIKit/UIGestureRecognizerSubclass.h> 必须引入此头文件

//extension UITapGestureRecognizer {
//    override public func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent) {
//        if case .Possible = state {
//            state = .Began
//        }
//    }
//    override public func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent) {
//        state = .Failed
//    }
//
//    override public func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent) {
//        state = .Recognized
//    }
//    
//}

class UIBaseGestureRecognizer: UIGestureRecognizer {
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent) {
        if case .Possible = state {
            state = .Began//UIGestureRecognizerState.Recognized
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent) {
        state = .Changed
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent) {
        state = .Ended
    }
    
}
