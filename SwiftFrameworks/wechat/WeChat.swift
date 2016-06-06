//
//  WeChat.swift
//  QuestionLib
//
//  Created by 慧趣小歪 on 16/6/6.
//  Copyright © 2016年 小分队. All rights reserved.
//

import Foundation


public struct WeChat {
    
    
    /// 微信开放平台,注册的应用程序Secret
    public static var appSecret: String! = "4fa8acadffcf97fbf1bbf2e4e10f8563"
    
    
    /// 检查微信是否已安装
    static public var isInstalled: Bool { return WXApi.isWXAppInstalled() }
    
    /**
     处理微信通过URL启动App时传递的数据
     
     需要在 application:openURL:sourceApplication:annotation:或者application:handleOpenURL中调用。
     
     - parameter url: 微信启动第三方应用时传递过来的URL
     
     - returns: 成功返回true，失败返回false
     */
    static public func handleOpenURL(url:NSURL) -> Bool {
        return WXApi.handleOpenURL(url, delegate: weChatListener)
    }
    
    
    static private var http:HttpRequest?
    static private var _weChatListener: WeChatListener?
    static private var weChatListener: WeChatListener {
        if _weChatListener == nil {
            _weChatListener = WeChatListener()
        }
        return _weChatListener!
    }
    static private var `defaults` = NSUserDefaults.standardUserDefaults()
}

extension WeChat {
    /// openid
    public static var openid: String! {
        get {
            return defaults.stringForKey("wechatkit_openid")
        }
        set {
            defaults.setObject(newValue, forKey: "wechatkit_openid")
        }
    }
    /// access token
    public static var accessToken: String! {
        get {
            return defaults.stringForKey("wechatkit_access_token")
        }
        set {
            defaults.setObject(newValue, forKey: "wechatkit_access_token")
        }
    }
    
    /// refresh token
    public static var refreshToken: String! {
        get {
            return defaults.stringForKey("wechatkit_refresh_token")
        }
        set {
            defaults.setObject(newValue, forKey: "wechatkit_refresh_token")
        }
    }
}

class WeChatListener : NSObject, WXApiDelegate {
    
}