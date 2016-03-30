//
//  Timer.swift
//  QuestionLib
//
//  Created by 慧趣小歪 on 16/3/29.
//  Copyright © 2016年 小分队. All rights reserved.
//

import Foundation


struct Timer {
    
    static func after(duration:NSTimeInterval, callInMainQueue callback: ()->Void) {
        let triggerTime = NSTimeInterval(NSEC_PER_SEC) * duration
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(triggerTime)), dispatch_get_main_queue()) {
            callback()
        }
    }
    
}