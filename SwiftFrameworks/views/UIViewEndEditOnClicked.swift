//
//  UIViewEndEditOnClicked.swift
//  TestUI
//
//  Created by 李招利 on 14/7/10.
//  Copyright (c) 2014年 慧趣工作室. All rights reserved.
//

import UIKit

class UIViewEndEditOnClicked: UIView {

    override func hitTest(point: CGPoint, withEvent event: UIEvent!) -> UIView?  {
        let view = super.hitTest(point, withEvent: event)
/*
        if view is UITextField {
            
        } else if view is UITextView {
            
        } else if view is UISearchBar {
            
        } else {
            
        }
*/
        let mirror:_MirrorType = view._getMirror()
//        var count:UInt32 = 0
//        let name:NSString = "123"
//        let propertes = class_copyPropertyList(UIViewEndEditOnClicked.Type.self, &count)
        switch mirror.valueType {
        case _ as UITextField.Type:
            break;
        case _ as UITextView.Type:
            break;
        default:
            self.endEditing(true)
        }
        return view
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
