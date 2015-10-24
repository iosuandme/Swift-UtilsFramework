//
//  UISectionNotificationController.swift
//
//  Created by 李招利 on 14/9/25.
//
//  从Section 1 开始使用, Section 0 被通知占用
//  设置 notificationCellIdentifier 为通知Cell
//

import UIKit

class UISectionNotificationController: UITableViewController {
    
    enum NotificationCellAccessoryType {
        case None
        case Clean
        case ActivityIndicator
        case Button (String, () -> Void)
    }
    
    let allSections = NSIndexSet(indexesInRange: NSMakeRange(0, 2))

    
    private var messageType:NotificationCellAccessoryType = .None
    private var message:String? = nil
    
    var notificationCellIdentifier = ""

    func showNotification(message:String?, messageType:NotificationCellAccessoryType) {
        self.message = message
        self.messageType = messageType
        
        switch messageType {
        case .Clean:
            clearNotification()
        case .ActivityIndicator:
            NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: Selector("delayRunReload"), userInfo: nil, repeats: false)
        default:
            self.tableView.reloadSections(allSections, withRowAnimation: UITableViewRowAnimation.Fade)
        }
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSTimer.cancelPreviousPerformRequestsWithTarget(self)
    }
    
    func delayRunReload() {
        
        self.tableView.reloadSections(allSections, withRowAnimation: UITableViewRowAnimation.Fade)
    }
    
    func clearNotification() {
        self.message = nil
        tableView.reloadSections(allSections, withRowAnimation: UITableViewRowAnimation.Fade)
    }
    
    func onCallBack() {
        switch messageType {
        case .Button (_, let callBack):
            callBack()
            messageType = .Clean
            clearNotification()
        default:
            break
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch messageType {
        case .Clean:
            return 0
        default :
            return 1
        }
    }
    
    // MARK: - Table view data source
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(notificationCellIdentifier, forIndexPath: indexPath) 
        
        cell.textLabel?.text = message
        cell.backgroundColor = UIColor(red: 250/255, green: 250/255, blue: 210/255, alpha: 1)
        
        switch messageType {
        case .Button (let title, _):
            let height = cell.bounds.height
            let button = UIButton(frame: CGRect(x: 0, y: 0, width: height, height: height))
            button.setTitle(title, forState: UIControlState.Normal)
            button.setTitleColor(UIColor.purpleColor(), forState: UIControlState.Normal)
            button.setBackgroundImage(UIImage(named: "alpha"), forState: UIControlState.Normal)
            button.addTarget(self, action: Selector("onCallBack"), forControlEvents: .TouchUpInside)
            button.sizeToFit()
            button.frame.size.height = height
            cell.accessoryView = button
        case .ActivityIndicator:
            let activity = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
            cell.accessoryView = activity
            activity.hidesWhenStopped = true
            activity.startAnimating()
        case .Clean:
            cell.textLabel?.text = nil
            fallthrough
        case .None:
            if let activity = cell.accessoryView as? UIActivityIndicatorView {
                activity.stopAnimating()
            }
            if let view = cell.accessoryView {
                view.removeFromSuperview()
            }
            cell.accessoryView = nil
        }
        
        return cell
    }
    /*
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section > 0 {
            return tableView.rowHeight
        }
        switch messageType {
        case .Clean, .None:
            return 0
        default :
            return tableView.rowHeight
        }
    }
    */
    
/*
    let sectionReused = "notificationSection"
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        var header = tableView.dequeueReusableHeaderFooterViewWithIdentifier(sectionReused) as? SectionNotificationHeaderFooterView
        if header == nil {
            header = SectionNotificationHeaderFooterView(reuseIdentifier: sectionReused)
            header!.button.addTarget(self, action: Selector("onCallBack"), forControlEvents: UIControlEvents.TouchUpInside)
            header!.button.setTitle(buttonTitle, forState: UIControlState.Normal)
        }
        header!.textLabel.text = nil
        var textLabel = header!.titleLabel
        textLabel.text = message
//        textLabel.textAlignment = .Center
//        textLabel.lineBreakMode = NSLineBreakMode.ByClipping
        
        return header
    }

    class SectionNotificationHeaderFooterView: UITableViewHeaderFooterView {
        var titleLabel:UILabel! {
            if  _titleLabel == nil {
                _titleLabel = UILabel(frame: bounds)
                _titleLabel!.textAlignment = NSTextAlignment.Center
                _titleLabel!.lineBreakMode = NSLineBreakMode.ByClipping
                addSubview(_titleLabel!)
                let constraintTop = NSLayoutConstraint(
                    item: _titleLabel!,
                    attribute: NSLayoutAttribute.Top,
                    relatedBy: NSLayoutRelation.Equal,
                    toItem: self,
                    attribute: NSLayoutAttribute.Top,
                    multiplier: 1,
                    constant: 0
                )
                let constraintBottom = NSLayoutConstraint(
                    item: _titleLabel!,
                    attribute: NSLayoutAttribute.Bottom,
                    relatedBy: NSLayoutRelation.Equal,
                    toItem: self,
                    attribute: NSLayoutAttribute.Bottom,
                    multiplier: 1,
                    constant: 0
                )
                let constraintLeading = NSLayoutConstraint(
                    item: _titleLabel!,
                    attribute: NSLayoutAttribute.Leading,
                    relatedBy: NSLayoutRelation.Equal,
                    toItem: self,
                    attribute: NSLayoutAttribute.Leading,
                    multiplier: 1,
                    constant: 0
                )
                let constraintTrailing = NSLayoutConstraint(
                    item: _titleLabel!,
                    attribute: NSLayoutAttribute.Trailing,
                    relatedBy: NSLayoutRelation.Equal,
                    toItem: button,
                    attribute: NSLayoutAttribute.Left,
                    multiplier: 1,
                    constant: 0
                )
                _titleConstraints = [constraintTop,constraintBottom,constraintLeading,constraintTrailing]
                //addConstraints(_titleConstraints)
                layoutIfNeeded()
            }
            return _titleLabel
        }
        private var _titleLabel:UILabel?
        private var _titleConstraints:[AnyObject] = []
        
        var button:UIButton! {
            if  _button == nil {
                _button = UIButton(frame: CGRect(x: 0, y: 0, width: 90, height: bounds.height))
                addSubview(_button!)
                let constraintTop = NSLayoutConstraint(
                    item: _button!,
                    attribute: NSLayoutAttribute.Top,
                    relatedBy: NSLayoutRelation.Equal,
                    toItem: self,
                    attribute: NSLayoutAttribute.Top,
                    multiplier: 1,
                    constant: 0
                )
                let constraintBottom = NSLayoutConstraint(
                    item: _button!,
                    attribute: NSLayoutAttribute.Bottom,
                    relatedBy: NSLayoutRelation.Equal,
                    toItem: self,
                    attribute: NSLayoutAttribute.Bottom,
                    multiplier: 1,
                    constant: 0
                )
                let constraintTrailing = NSLayoutConstraint(
                    item: _button!,
                    attribute: NSLayoutAttribute.Trailing,
                    relatedBy: NSLayoutRelation.Equal,
                    toItem: self,
                    attribute: NSLayoutAttribute.Trailing,
                    multiplier: 1,
                    constant: 0
                )
                let constraintWidth = NSLayoutConstraint(
                    item: _button!,
                    attribute: NSLayoutAttribute.Width,
                    relatedBy: NSLayoutRelation.GreaterThanOrEqual,
                    toItem: nil,
                    attribute: NSLayoutAttribute.Width,
                    multiplier: 1,
                    constant: 40
                )
                _buttonConstraints = [constraintTop,constraintBottom,constraintTrailing,constraintWidth]
                //addConstraints(_buttonConstraints)
                layoutIfNeeded()
            }
            return _button
        }
        private var _button:UIButton?
        private var _buttonConstraints:[AnyObject] = []
        
        override func removeFromSuperview() {
            super.removeFromSuperview()
            _titleLabel?.removeFromSuperview()
            _titleLabel = nil
            _button?.removeFromSuperview()
            _button = nil
            removeConstraints(_titleConstraints)
            removeConstraints(_buttonConstraints)
            _titleConstraints = []
            _buttonConstraints = []
        }
    }
    
*/
   
}
