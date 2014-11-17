//
//  UIViewController+PresentNotificationController.swift
//  ExamWinnerSwift
//
//  Created by 李招利 on 14/11/2.
//  Copyright (c) 2014年 Jintianyu Culture Communication Co., Ltd. All rights reserved.
//
//  Import Accelerate.framework // 如果要实现毛玻璃效果
//

import UIKit

let kNotificationModalAnimationDuration = 0.35

extension UIViewController {
    
    var topViewController:UIViewController {
        var controller = self
        while controller.parentViewController != nil {
            controller = controller.parentViewController!
        }
        return controller
    }
    
    private struct NotificationInstance {
        static weak var instance:UIViewController? = nil
    }
    
    func presentNotificationController(viewController:UIViewController) {
        if NotificationInstance.instance != nil { return }
        
        NotificationInstance.instance = viewController
        
        let topController = topViewController
        let target = topController.view

        // Calulate all frames
        let targetFrame = target.bounds
        let viewFrame = viewController.view.bounds
        let dismissFrame = CGRect(x: 0, y: viewFrame.height, width: targetFrame.width, height: targetFrame.height - viewFrame.height)
        
        
        // Add semi overlay
        var overlay = UIView(frame: target.bounds)
        overlay.backgroundColor = UIColor.blackColor()
        
        // Take screenshot and scale
        UIGraphicsBeginImageContext(target.bounds.size);
        target.layer.renderInContext(UIGraphicsGetCurrentContext())
        let image = UIGraphicsGetImageFromCurrentImageContext()
        let imageView = UIImageView(image: image)
        overlay.addSubview(imageView)
        target.addSubview(overlay)
        
        // Dismiss button
        // Don't use UITapGestureRecognizer to avoid complex handling
        var dismissButton = UIButton(frame: dismissFrame)
        dismissButton.backgroundColor = UIColor.clearColor()
        dismissButton.frame = dismissFrame
        dismissButton.addTarget(self, action: Selector("dismissNotificationController"), forControlEvents: .TouchUpInside)
        overlay.addSubview(dismissButton)
        
        // Begin overlay animation

        // Present view animated
        let vc = viewController.view
        vc.layer.shadowColor = UIColor.blackColor().CGColor
        vc.layer.shadowOffset = CGSizeMake(0, 2);
        vc.layer.shadowRadius = 3.0;
        vc.layer.shadowOpacity = 0.8;
        
        vc.frame = CGRect(x: 0, y: -viewFrame.height, width: viewFrame.width, height: viewFrame.height);
        topController.addChildViewController(viewController)
        target.addSubview(vc);

        UIView.animateWithDuration(kNotificationModalAnimationDuration) {
            imageView.alpha = 0.5
            vc.frame = viewFrame
        }
    }
    
    func dismissNotificationController() {
        if let viewController = NotificationInstance.instance {
        //if let viewController = topController.childViewControllers.last as? UIViewController {
            let topController = topViewController
            let target = topController.view
            let overlay = target.subviews[target.subviews.count - 2] as UIView
            let imageView = overlay.subviews.first as? UIImageView
            
            UIView.animateWithDuration(kNotificationModalAnimationDuration, animations: {
                imageView?.alpha = 1
                
                var frame = viewController.view.bounds
                frame.origin.y = -frame.height
                viewController.view.frame = frame
                
            }) { complete in
                overlay.removeFromSuperview()
                viewController.view.removeFromSuperview()
                viewController.removeFromParentViewController()
            }
            NotificationInstance.instance = nil
        }
        
    }
}

