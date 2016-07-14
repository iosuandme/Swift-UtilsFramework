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
    
    public func addNotificationBy(target target:AnyObject, callback:(T)->Void) {
        notifications.append(Notification<T>(target, callback))
        if let item:T = onInitNotification?() {
            NSOperationQueue.mainQueue().addOperationWithBlock {
                callback(item)
            }
        }
    }
    
    public func dispatchChanged(item:T) {
        NSOperationQueue.mainQueue().addOperationWithBlock {
            for i in (0..<self.notifications.count).reverse() {
                let notification = self.notifications[i]
                if notification.target === nil {
                    self.notifications.removeAtIndex(i)
                } else { notification.callback(item) }
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
    
    init(_ target:AnyObject, _ callback:(T)->Void) {
        self.target = target
        self.callback = callback
    }
    
}
