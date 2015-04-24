//
//  UITextBox.swift
//  UITest
//
//  Created by 李招利 on 14/7/10.
//  Copyright (c) 2014年 慧趣工作室. All rights reserved.
//

import UIKit

enum UITextBoxContentType {
    case AnyChar
    case Number
    case Integer
    case EMail
    case Phone
    case Telephone
    case MobilePhone
    case CustomType
}

@IBDesignable

class UITextBox: UITextField {
    
    @IBInspectable var highlightColor:UIColor = UIColor(red: 0.0, green: 0.65, blue: 1.0, alpha: 0.1)
    @IBInspectable var animateDuration:CGFloat = 0.4
    weak var placeholderLabel:UILabel!
    
    override var placeholder:String! {
    didSet {
        if let label = placeholderLabel {
            label.text = super.placeholder
            self.layoutSubviews()
        }
    }
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addTarget(self, action: Selector("editingChanged"), forControlEvents: UIControlEvents.EditingChanged);
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.addTarget(self, action: Selector("editingChanged"), forControlEvents: UIControlEvents.EditingChanged);
    }
    
    func editingChanged() {
        println("editingChanged:\(text)")
    }
    
    //获得焦点时高亮动画
    override func becomeFirstResponder() -> Bool {
        UIView.animateWithDuration(Double(animateDuration)){
            self.backgroundColor = self.highlightColor
        }
        return super.becomeFirstResponder()
    }
    
    //失去焦点时取消高亮动画
    override func resignFirstResponder() -> Bool {
        UIView.animateWithDuration(Double(animateDuration)){
            self.backgroundColor = UIColor.clearColor()
        }
        return super.resignFirstResponder()
    }
    
    
    //调整子控件布局
    override func layoutSubviews() {
        super.layoutSubviews()
        let rect = super.placeholderRectForBounds(bounds)
        if isFirstResponder() {
            layoutPlaceholderLabel(rect,false)
        } else if text == nil || text == "" {
            layoutPlaceholderLabel(rect,true)
        } else {
            layoutPlaceholderLabel(rect,false)
        }
    }
    
    override func willMoveToSuperview(newSuperview: UIView!)  {
        super.willMoveToSuperview(newSuperview)
        if placeholderLabel == nil {
            let rect = super.placeholderRectForBounds(bounds)
            var label = UILabel(frame: rect)
            label.text = self.placeholder
            label.textColor = UIColor(white: 0.7, alpha: 1.0)
            label.font = self.font
            placeholderLabel = label
            self.addSubview(label);
        }
    }
    
    override func removeFromSuperview() {
        self.placeholderLabel.removeFromSuperview()
        self.placeholderLabel = nil
        super.removeFromSuperview()
    }
    

    override func placeholderRectForBounds(bounds: CGRect) -> CGRect {
        let rect = super.placeholderRectForBounds(bounds)
        if placeholderLabel == nil {
            var label = UILabel(frame: rect)
            label.textColor = UIColor(white: 0.7, alpha: 1.0)
            label.font = self.font
            placeholderLabel = label
            addSubview(label)
        }
        placeholderLabel.text = self.placeholder
        layoutPlaceholderLabel(rect,!isFirstResponder())
        return CGRect.zeroRect
    }
    
    
    //布局提示文本
    func layoutPlaceholderLabel(rect: CGRect,_ left: Bool = false) {
        if let label = placeholderLabel {
            let size = label.sizeThatFits(bounds.size)
            if left {
                UIView.animateWithDuration(Double(animateDuration)){
                    self.placeholderLabel.frame = rect;
                }
            } else {
                UIView.animateWithDuration(Double(animateDuration)){
                    let size = self.placeholderLabel.sizeThatFits(self.bounds.size)
                    var frame = self.placeholderLabel.frame
                    frame.origin.x = self.bounds.width - size.width - 7.0
                    frame.size.width = size.width + 7.0
                    self.placeholderLabel.frame = frame
                }
            }
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
