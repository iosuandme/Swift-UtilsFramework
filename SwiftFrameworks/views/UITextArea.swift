//
//  UITextArea.swift
//  TestUI
//
//  Created by 李招利 on 14/7/10.
//  Copyright (c) 2014年 慧趣工作室. All rights reserved.
//

import UIKit

//@IBDesignable

class UITextArea: UITextView {
    
    @IBInspectable var cornerRadius:CGFloat = 5.0
    @IBInspectable var borderWidth:CGFloat = 0.5
    @IBInspectable var borderColor:UIColor = UIColor(white: 0.8, alpha: 1.0)
    @IBInspectable var defaultHeight:CGFloat = 30.0
    @IBInspectable var placeholder:NSString? = "" {
    didSet {
        if let label = placeholderLabel {
            if let newValue = placeholder {
                label.text = newValue as String
            } else {
                label.text = ""
            }
        }
    }
    }
    
    var placeholderLabel:UILabel?
    
    override func removeFromSuperview() {
        self.placeholderLabel?.removeFromSuperview()
        self.placeholderLabel = nil
        super.removeFromSuperview()
        
    }
    
    
    override func insertText(text: String) {
        let size = self.sizeThatFits(CGSize(width: bounds.width, height: textContainer.size.height))
        print("size\(size)")
        frame.size.height = size.height// + textContainerInset.top + textContainerInset.bottom
        super.insertText(text)
    }
    
    override func replaceRange(range: UITextRange, withText text: String)  {
        super.replaceRange(range, withText: text)
        let size = self.sizeThatFits(CGSize(width: bounds.width, height: textContainer.size.height))
        frame.size.height = size.height + textContainerInset.top + textContainerInset.bottom
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        self.layer.cornerRadius = cornerRadius
        self.layer.borderWidth = borderWidth
        self.layer.borderColor = borderColor.CGColor
    }
    
    override func didMoveToWindow()  {
        super.didMoveToWindow()
        self.layer.cornerRadius = cornerRadius
        self.layer.borderWidth = borderWidth
        self.layer.borderColor = borderColor.CGColor
    }
///*
    override func willMoveToSuperview(newSuperview: UIView!)  {
        
        self.layer.cornerRadius = cornerRadius
        self.layer.borderWidth = borderWidth
        self.layer.borderColor = borderColor.CGColor

        if placeholderLabel == nil {
            var rect = self.bounds
            rect.origin.x = 7.0
            rect.size.width = rect.width - 14.0
            let label = UILabel(frame: rect)
            if let text = placeholder {
                label.text = text as String
            }
            label.textColor = UIColor(white: 0.7, alpha: 1.0)
            label.font = self.font
            
            self.addSubview(label);
            
            placeholderLabel = label
        }
        super.willMoveToSuperview(newSuperview)
    }
    
    override var showsHorizontalScrollIndicator:Bool {
    didSet {
        showsHorizontalScrollIndicator = false
    }
    }
    override var showsVerticalScrollIndicator:Bool {
    didSet {
        showsVerticalScrollIndicator = false
    }
    }

//*/
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect)
    {
        // Drawing code
    }
    */

}
