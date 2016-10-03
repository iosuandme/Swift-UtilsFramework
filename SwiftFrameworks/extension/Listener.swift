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

open class Listener<T> {
    
    fileprivate var notifications:[Notification<T>] = []
    
    open var count:Int { return notifications.count }
    
    
    /// callback mast use `[unowned self]` or `[weak self]` before `(params) in {`
    open func addNotificationBy(target:AnyObject, callback:@escaping (T)->Void) {
        notifications.append(Notification<T>(target, callback))
        if let item:T = onInitNotification?() {
            callback(item)
        }
    }
    open func addNotificationBy(target:NSObject, callback:Selector) {
        notifications.append(Notification<T>(target, callback))
        if let item:T = onInitNotification?() {
            OperationQueue.main.addOperation {
                target.perform(callback, with: item)
            }
        }
    }
    
    open func dispatchChanged(_ item:T) {
        OperationQueue.main.addOperation {
            for i in (0..<self.notifications.count).reversed() {
                let notification = self.notifications[i]
                if notification.target === nil {
                    self.notifications.remove(at: i)
                } else if let selector = notification.selector {
                    let target = notification.target as! NSObject
                    target.perform(selector, with: item)
                } else {
                    notification.callback(item)
                }
            }
        }
    }
    
    open func removeNotificationBy(target:AnyObject) {
        for i in (0..<notifications.count).reversed() {
            if notifications[i].target === target {
                notifications.remove(at: i)
            }
        }
    }
    
    fileprivate var onInitNotification:(()->T)?
    init(onInitNotification:(()->T)? = nil) {
        self.onInitNotification = onInitNotification
    }
    
}


private class Notification<T> {
    
    fileprivate weak var target:AnyObject?
    
    fileprivate var callback:(T)->Void
    fileprivate var selector:Selector?
    
    init(_ target:AnyObject, _ callback:@escaping (T)->Void) {
        self.target = target
        self.callback = callback
    }
    
    init (_ target:NSObject, _ callback:Selector) {
        self.target = target
        self.selector = callback
        self.callback = {_ in }
    }
    
}
