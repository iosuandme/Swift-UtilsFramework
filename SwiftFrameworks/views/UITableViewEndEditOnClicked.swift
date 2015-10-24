//
//  UITableViewEndEditOnClicked.swift
//  TestUI
//
//  Created by 李招利 on 14/7/10.
//  Copyright (c) 2014年 慧趣工作室. All rights reserved.
//

import UIKit

@objc protocol UITableViewEndEditOnClickedDelegate : UITableViewDelegate {
    func endEditing(view:UIView!, point:CGPoint, withEvent event: UIEvent!)
}

class UITableViewEndEditOnClicked: UITableView {

    override func hitTest(point: CGPoint, withEvent event: UIEvent!) -> UIView?  {
        let view = super.hitTest(point, withEvent: event)
        let mirror:_MirrorType = view._getMirror()
        switch mirror.valueType {
        case _ as UITextField.Type:
            break;
        case _ as UITextView.Type:
            break;
        case _ as UISearchBar.Type:
            break;
        default:
            if let delegate = self.delegate as? UITableViewEndEditOnClickedDelegate {
                delegate.endEditing(view, point: point, withEvent: event)
            }
            self.endEditing(true)
        }
        return view
    }
    
    
}
