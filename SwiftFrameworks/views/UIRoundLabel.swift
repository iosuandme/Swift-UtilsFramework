//
//  UIRoundLabel.swift
//  QuanZhouPreview
//
//  Created by 李招利 on 14/8/9.
//  Copyright (c) 2014年 三杨科技. All rights reserved.
//

import UIKit

class UIRoundLabel: UILabel {
    
    @IBInspectable var cornerRadius:CGFloat {
        get {
            return self.layer.cornerRadius
        }
        set (newValue) {
            self.layer.cornerRadius = newValue
        }
    }
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect)
    {
        // Drawing code
    }
    */

}
