//
//  UISegmented+Listener.swift
//  ExamWinnerSwift
//
//  Created by CocoaController on 15/4/3.
//  Copyright (c) 2015年 Jintianyu Culture Communication Co., Ltd. All rights reserved.
//

import UIKit

typealias OnSelectedSegmentIndexChanged = (value:Int) -> Void

class TYSegmentedController : UISegmentedControl {
    
    internal var listener:OnSelectedSegmentIndexChanged?
    
    override var selectedSegmentIndex:Int {
        didSet {
            listener?(value: selectedSegmentIndex)
        }
    }
}
