//
//  Listener.swift
//  TallyCloud
//
//  Created by 慧趣小歪 on 16/6/30.
//  Copyright © 2016年 小分队. All rights reserved.
//
//  通知监听器
//

import Foundation

public class Listener<T> {
    
    private var notifications:[Notification<T>] = []
    
    public var count:Int { return notifications.count }
    
    
    /// callback mast use `[unowned self]` or `[weak self]` before `(params) in {`
    public func addNotificationBy(target target:AnyObject, callback:(T)->Void) {
        notifications.append(Notification<T>(target, callback))
        if let item:T = onInitNotification?() {
            callback(item)
        }
    }
    public func addNotificationBy(target target:NSObject, callback:Selector) {
        notifications.append(Notification<T>(target, callback))
        if let item:T = onInitNotification?() {
            NSOperationQueue.mainQueue().addOperationWithBlock {
                if let obj = item as? AnyObject {
                    target.performSelector(callback, withObject: obj)
                } else {
                    target.performSelector(callback)
                }
            }
        }
    }
    
    public func dispatchChanged(item:T) {
        NSOperationQueue.mainQueue().addOperationWithBlock {
            for i in (0..<self.notifications.count).reverse() {
                let notification = self.notifications[i]
                if notification.target === nil {
                    self.notifications.removeAtIndex(i)
                } else if let selector = notification.selector {
                    let target = notification.target as! NSObject
                    if let obj = item as? AnyObject {
                        target.performSelector(selector, withObject: obj)
                    } else {
                        target.performSelector(selector)
                    }
                } else {
                    notification.callback(item)
                }
            }
        }
    }
    
    public func removeNotificationBy(target target:AnyObject) {
        for i in (0..<notifications.count).reverse() {
            if notifications[i].target === target {
                notifications.removeAtIndex(i)
            }
        }
    }
    
    private var onInitNotification:(()->T)?
    init(onInitNotification:(()->T)? = nil) {
        self.onInitNotification = onInitNotification
    }
    
}


private class Notification<T> {
    
    private weak var target:AnyObject?
    
    private var callback:(T)->Void
    private var selector:Selector?
    
    init(_ target:AnyObject, _ callback:(T)->Void) {
        self.target = target
        self.callback = callback
    }
    
    init (_ target:NSObject, _ callback:Selector) {
        self.target = target
        self.selector = callback
        self.callback = {_ in }
    }
    
}
