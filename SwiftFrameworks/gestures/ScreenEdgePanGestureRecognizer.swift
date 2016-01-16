//
//  ScreenEdgePanGestureRecognizer.swift
//  TallyCloud
//
//  Created by 慧趣小歪 on 16/1/16.
//  Copyright © 2016年 小分队. All rights reserved.
//

import UIKit
//#import <UIKit/UIGestureRecognizerSubclass.h> 必须引入此头文件

class ScreenEdgePanGestureRecognizer: UIPanGestureRecognizer {
    
    @IBInspectable var edges: UIRectEdge = UIRectEdge.None

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent) {
        if case .Possible = state {
            state = .Began //UIGestureRecognizerState.Recognized
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent) {
        print(touches)
        state = .Changed
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent) {
        state = .Ended
    }
    
}
