//
//  UIActionButton.swift
//  ExamWinnerSwift
//
//  Created by 李招利 on 14/11/10.
//  Copyright (c) 2014年 Jintianyu Culture Communication Co., Ltd. All rights reserved.
//

import UIKit

class UIActionButton: UIButton {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    private var _callback:(() -> Void)?
    
    func setAction(actionBlock:(() -> Void)?) {
        _callback = actionBlock
        self.addTarget(self, action: Selector("onButtonClicked"), forControlEvents: .TouchUpInside)
    }
    
    func onButtonClicked() {
        _callback?()
    }

    deinit {
        _callback = nil
    }
}
