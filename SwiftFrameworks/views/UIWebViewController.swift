//
//  UIWebViewController.swift
//  ExamWinnerSwift
//
//  Created by 李招利 on 14/10/7.
//  Copyright (c) 2014年 Jintianyu Culture Communication Co., Ltd. All rights reserved.
//

import UIKit
import WebKit

class UIWebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    
    var webView:WKWebView {
        
        if _webView == nil {
            _webView = WKWebView(frame: view.bounds)
            view.addSubview(_webView!)
            let left = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Leading, multiplier: 1, constant: 0)
            let right = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Trailing, multiplier: 1, constant: 0)
            let top = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Top, multiplier: 1, constant: 0)
            let bottom = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 0)
            _webView?.addConstraints([left,top,right,bottom])
        }
        return _webView!
    }
    private var _webView:WKWebView? = nil

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let source = "function msgbox(msg) { alert(msg) }"
        let userScript = WKUserScript(source: source, injectionTime: .AtDocumentStart, forMainFrameOnly: false)
        
        let userContentController = WKUserContentController()
        userContentController.addUserScript(userScript)
        
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController
        
        _webView = WKWebView(frame: view.bounds, configuration: configuration)
        view.addSubview(_webView!)
        let left = NSLayoutConstraint(item: _webView!, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.Leading, multiplier: 1, constant: 0)
        let right = NSLayoutConstraint(item: _webView!, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.Trailing, multiplier: 1, constant: 0)
        let top = NSLayoutConstraint(item: _webView!, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.Top, multiplier: 1, constant: 0)
        let bottom = NSLayoutConstraint(item: _webView!, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 0)
        view.addConstraints([left,top,right,bottom])
    
        _webView?.loadHTMLString("我就是网页内容", baseURL: nil)
    }
    


}
