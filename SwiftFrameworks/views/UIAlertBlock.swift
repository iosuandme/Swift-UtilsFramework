//
//  UIAlertBlock.swift
//
//  Created by 慧趣工作室 on 14/9/4.
//

import UIKit

class UIAlertBlock: UIAlertView, UIAlertViewDelegate {
    
    typealias OnTappedBlock = (action:Action, index:Int) -> Void
    
    enum Style: Int {
        case Cancel
        case Default
    }
    
    class Action {
        let title:String
        let style:Style
        let onTapped:OnTappedBlock?
        init(buttonTitle:String, style:Style = .Cancel, onTapped:OnTappedBlock? = nil) {
            self.title = buttonTitle;
            self.style = style;
            self.onTapped = onTapped;
        }
    }
    
    init(title: String?, message: String?) {
        super.init(frame:CGRect.zeroRect)
        self.title = title ?? ""
        self.message = message
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private lazy var actions:[Action] = []
    
    func addAction(action:Action) {
        let index = addButtonWithTitle(action.title)
        if action.style == .Cancel {
            cancelButtonIndex = index
        }
        actions.append(action)
    }
    
    override func show() {
        super.delegate = self
        super.show()
    }
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect)
    {
        // Drawing code
    }
    */

    // MARK: - UIAlertViewDelegate
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        let action = actions[buttonIndex]
        action.onTapped?(action: action, index: buttonIndex)
        actions.removeAll(keepCapacity: false)
        delegate = nil
    }
    
    
}
