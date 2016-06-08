//
//  WeChat.swift
//  QuestionLib
//
//  Created by 慧趣小歪 on 16/6/6.
//  Copyright © 2016年 小分队. All rights reserved.
//

import Foundation


public struct WeChat {
    
    public typealias AuthHandle = (Result<JSON.Value, Int32>) -> ()
    /// 微信开放平台,注册的应用程序Secret
    static public var appSecret: String! = "4fa8acadffcf97fbf1bbf2e4e10f8563"
    
    
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
    
}

public protocol WeChatShareDelegate {
    func shareResponse(code: Int32, description:String?)
}

extension WeChat {
    
    static public var shareDelegate: WeChatShareDelegate?
    /**
     分享
     
     - parameter scence:      请求发送场景
     - parameter image:       消息缩略图
     - parameter title:       标题
     - parameter description: 描述内容
     - parameter url:         地址
     - parameter extInfo:     app分享信息
     (点击分享内容返回程序时,会传给WechatManagerShareDelegate.showMessage(message: String)
     */
    static public func share(scence: WXScene,
                      image: UIImage?,
                      title: String,
                      description: String,
                      url: String? = "https://open.weixin.qq.com/",
                      extInfo: String? = nil) {
        
        var message = self.getRequestMesage(image, title: title, description: description)
        
        if let extInfo = extInfo {
            message = self.shareApp(message, url: url, extInfo: extInfo)
        } else {
            message = self.shareUrl(message, url: url)
        }
        
        self.sendReq(message, scence: scence)
    }
    
    //share url
    static private func shareUrl(message: WXMediaMessage, url: String?) -> WXMediaMessage {
        message.mediaTagName = "WECHAT_TAG_JUMP_SHOWRANK"
        
        let ext = WXWebpageObject()
        ext.webpageUrl = url
        message.mediaObject = ext
        
        return message
    }
    /**
     share app
     
     - parameter message: message description
     - parameter url:     url description
     - parameter extInfo: extInfo description
     
     - returns: return value description
     */
    static private func shareApp(message: WXMediaMessage, url: String?, extInfo: String)
        -> WXMediaMessage {
            message.messageExt = extInfo//"附加消息：Come from 現場TOMO" //返回到程序之后用
            message.mediaTagName = "WECHAT_TAG_JUMP_APP"
            //message.messageAction = "<action>\(messageAction)</action>" //不能返回  ..返回到程序之后用
            
            let ext = WXAppExtendObject()
            //        ext.extInfo = extInfo //返回到程序之后用
            ext.url = url;//分享到朋友圈时的链接地址
            let buffer: [UInt8] = [0x00, 0xff]
            let data = NSData(bytes: buffer, length: buffer.count)
            ext.fileData = data
            
            message.mediaObject = ext
            
            return message
    }
    
    //get message
    static private func getRequestMesage(image: UIImage?, title: String, description: String)
        -> WXMediaMessage {
            
            let message = WXMediaMessage()
            /** 描述内容
             * @note 长度不能超过1K
             */
            if description.characters.count > 128 {
                let startIndex = description.startIndex
                let range = startIndex.advancedBy(0)..<startIndex.advancedBy(128)
                message.description = description.substringWithRange(range)
            } else {
                message.description = description
            }
            
            /** 缩略图数据
             * @note 大小不能超过32K
             */
            let thumbImage = image == nil ? UIImage() : self.resizeImage(image!, newWidth: 100)
            
            message.setThumbImage(thumbImage)
            
            /** 标题
             * @note 长度不能超过512字节
             */
            if title.characters.count > 64 {
                
                let startIndex = title.startIndex
                let range = startIndex.advancedBy(0)..<startIndex.advancedBy(64)
                message.title = title.substringWithRange(range)
            } else {
                message.title = title
            }
            return message
    }
    
    static private func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage {
        let newHeight = image.size.height / image.size.width * newWidth
        UIGraphicsBeginImageContext( CGSize(width: newWidth, height: newHeight) )
        image.drawInRect(CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    //send request
    static private func sendReq(message: WXMediaMessage, scence: WXScene) {
        let req = SendMessageToWXReq()
        req.bText = false
        req.message = message
        req.scene = Int32(scence.rawValue)
        
        WXApi.sendReq(req)
    }

}

extension WeChat {
    // 登录授权
    
    static var completionHandler: AuthHandle?
    
    /// 退出
    static public func logout() {
        WeChat.openid = ""
        WeChat.accessToken = ""
        WeChat.refreshToken = ""
    }
    
    // 检查授权
    static public func checkAuth(completionHandler: AuthHandle) {
        if !WXApi.isWXAppInstalled() {
            // 微信没有安装WXErrCodeUnsupport.rawValue
            completionHandler(.Failure(WXErrCodeUnsupport.rawValue))
        } else {
            self.completionHandler = completionHandler
            if let _ = WeChat.openid,
                _ = WeChat.accessToken,
                _ = WeChat.refreshToken {
                checkToken()
            } else {
                sendAuth()
            }
        }
    }
    
    // 获取微信用户数据
    static public func getUserInfo(completionHandler: AuthHandle) {
        self.completionHandler = completionHandler

        let route = WeChatRoute.Userinfo
        let task = post(route.parameters, toURL: route.path) { json in
            self.completionHandler?(.Success(json))
        }
        task.onFailed { errorCode in
            self.completionHandler?(.Failure(errorCode))
        }
        task.onError { errorCode in
            self.completionHandler?(.Failure(errorCode))
        }
    }
    
    static public func getAccessToken(code: String) {
        let route = WeChatRoute.AccessToken(code)
        let task = post(route.parameters, toURL: route.path) { json in
            self.saveOpenId(json)
            self.completionHandler?(.Success(json))
        }
        task.onFailed { errorCode in
            self.completionHandler?(.Failure(errorCode))
        }
        task.onError { errorCode in
            self.completionHandler?(.Failure(errorCode))
        }
    }
    
    static private func sendAuth() {
        let req = SendAuthReq()
        req.scope = "snsapi_userinfo,snsapi_base"
        WXApi.sendReq(req)
    }
    
    //检验授权凭证（access_token）是否有效
    static private func checkToken() {
        let route = WeChatRoute.CheckToken
        let task = post(route.parameters, toURL: route.path) { json in
            self.completionHandler?(.Success(json))
        }
        task.onFailed { errorCode in
            self.refreshAccessToken()
        }
        task.onError { errorCode in
            self.completionHandler?(.Failure(errorCode))
        }
    }
    
    static private func refreshAccessToken() {
        let route = WeChatRoute.RefreshToken
        let task = post(route.parameters, toURL: route.path) { json in
            self.saveOpenId(json)
            self.completionHandler?(.Success(json))
        }
        task.onFailed { errorCode in
            self.sendAuth()
        }
        task.onError { errorCode in
            self.completionHandler?(.Failure(errorCode))
        }
    }
    
    static private func saveOpenId(info: JSON.Value) {
        WeChat.openid = info["openid"].stringValue
        WeChat.accessToken = info["access_token"].stringValue
        WeChat.refreshToken = info["refresh_token"].stringValue
        //self.completionHandler?(.Success(info))
    }
}

// 基础属性
extension WeChat {
    
    static private var `defaults` = NSUserDefaults.standardUserDefaults()

    /// 微信开放平台,注册的应用程序id
    public static var appid: String! {
        didSet {
            WXApi.registerApp(appid, withDescription: "Wechat")
        }
    }
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

// 网络访问队列
extension WeChat {
    
    static var currentTask:WeChatTask?
    static var tasks:[WeChatTask] = []
    
    static private var request:HttpRequest?
    
    static private var onceToken:dispatch_once_t = 0
    static private var _weChatListener: WeChatListener?
    static private var weChatListener: WeChatListener {
        dispatch_once(&onceToken) {
            _weChatListener = WeChatListener() {
                print("收到返回")
            }
        }
        return _weChatListener!
    }
    
    static private func start() {
        if tasks.count == 0 { return }
        if WeChat.request != nil { return }
        let task = tasks.removeAtIndex(0)
        let request = HttpRequest(url: task.url)
        request.postJSON(task.params) {
            (response:HttpResponse) in
            WeChat.request = nil
            WeChat.currentTask = nil
            
            //print(response.statusCode, task.api ,response.content, response.content.jsonValue.debugDescription)
            
            NSOperationQueue.mainQueue().addOperationWithBlock {
                //task._onComplete?()
                var error:String? = nil
                defer {
//                    if let controller = task.controller, let text = error {
//                        Toast.makeText(controller, message: text).show()
//                    }
                    WeChat.start()
                }
                if response.statusCode != 200 {
                    print(response.content)
                    error = response.error?.localizedDescription ?? "🕸未知网络错误:\(response.statusCode)"
                    task._onError?(WXErrCodeSentFail.rawValue)
                    return
                }
                let json = response.content.jsonValue
                if json.isError {
                    print(response.content)
                    error = "😰程序员哥哥正在抢修，请稍后再试!"
                    task._onError?(WXErrCodeCommon.rawValue)
                    return
                }
                //print(json.debugDescription)
                if json["errcode"].integerValue != 0 {
                    //error = "😢" + json["message"].stringValue
                    task._onFailed?(Int32(json["errcode"].integerValue))
                    return
                }
                task.onSuccess(json)
            }
        }
        WeChat.request = request
        WeChat.currentTask = task
    }
    
    static func post(params:[String:Any], toURL url:String, onSuccess:(JSON.Value) -> ()) -> WeChatTask {
        let text = Http.stringByParams(params)
        let task = WeChatTask(URL: NSURL(string: url)!, params: text, onSuccess:onSuccess)
        WeChat.tasks.append(task)
        defer { WeChat.start() }
        return task
    }
}

// 网络任务
class WeChatTask {
    private var _onError:((Int32) -> ())?
    private var _onFailed:((Int32) -> ())?
    
    var onSuccess:(JSON.Value) -> ()
    var params:String
    var url:NSURL
    init(URL url:NSURL, params:String, onSuccess:(JSON.Value) -> ()) {
        self.url = url
        self.params = params
        self.onSuccess = onSuccess
    }
    func onError(callback:(Int32)->()) {
        _onError = callback
    }
    func onFailed(callback:(Int32)->()) {
        _onFailed = callback
    }
    
    func cancel() {
        if WeChat.currentTask === self {
            WeChat.request?.cancel()
        } else {
            if let index = WeChat.tasks.indexOf({ $0 === self }) {
                WeChat.tasks.removeAtIndex(index)
            }
            _onError?(WXErrCodeUserCancel.rawValue)
        }
    }
    
}

// 微信委托
public class WeChatListener : NSObject, WXApiDelegate {
    
    /**
     发送一个sendReq后，收到微信的回应
     
     * 收到一个来自微信的处理结果。调用一次sendReq后会收到onResp。
     * 可能收到的处理结果有SendMessageToWXResp、SendAuthResp等
     
     - parameter resp: 具体的回应内容，是自动释放的
     */
    private var onResponse:()->()
    init(onResponse: ()->()) {
        self.onResponse = onResponse
    }
    
    public func onResp(resp: BaseResp!) {
        switch resp {
        case let temp as SendAuthResp:
            if 0 == temp.errCode {
                WeChat.getAccessToken(temp.code)
            } else {
                //onResponse()
                WeChat.completionHandler?(.Failure(WXErrCodeCommon.rawValue))
            }
        case let temp as SendMessageToWXResp:
            //let jObj:NSDictionary = ["errCode":NSNumber(int: temp.errCode),"message":temp.errStr]
            //WeChat.completionHandler?(.Success(JSON.getValue(jObj)))
            WeChat.shareDelegate?.shareResponse(temp.errCode,description: temp.errStr)
            WeChat.shareDelegate = nil
        default: print("未知微信返回类型")
        }
        print(resp.errStr ?? "", "微信返回")
    }

    
}


public enum Result<Value, Error> {
    case Success(Value)
    case Failure(Error)
    
    /// Returns `true` if the result is a success, `false` otherwise.
    public var isSuccess: Bool {
        switch self {
        case .Success:
            return true
        case .Failure:
            return false
        }
    }
    
    /// Returns `true` if the result is a failure, `false` otherwise.
    public var isFailure: Bool {
        return !isSuccess
    }
    
    /// Returns the associated value if the result is a success, `nil` otherwise.
    public var value: Value? {
        if case .Success(let value) = self {
            return value
        }
        return nil
    }
    
    /// Returns the associated error value if the result is a failure, `nil` otherwise.
    public var error: Error? {
        if case .Failure(let error) = self {
            return error
        }
        return nil
    }
}

// MARK: - CustomStringConvertible

extension Result: CustomStringConvertible {
    /// The textual representation used when written to an output stream, which includes whether the result was a
    /// success or failure.
    public var description: String {
        switch self {
        case .Success:
            return "SUCCESS"
        case .Failure:
            return "FAILURE"
        }
    }
}

// MARK: - CustomDebugStringConvertible

extension Result: CustomDebugStringConvertible {
    /// The debug textual representation used when written to an output stream, which includes whether the result was a
    /// success or failure in addition to the value or error.
    public var debugDescription: String {
        switch self {
        case .Success(let value):
            return "SUCCESS: \(value)"
        case .Failure(let error):
            return "FAILURE: \(error)"
        }
    }
}

// 微信参数
enum WeChatRoute  {
    
    case Userinfo
    case AccessToken(String)
    case RefreshToken
    case CheckToken
    
    var path: String {
        var url:String = "https://api.weixin.qq.com/sns"
        switch self {
        case .Userinfo      :   url += "/userinfo"
        case .AccessToken   :   url += "/oauth2/access_token"
        case .RefreshToken  :   url += "/oauth2/refresh_token"
        case .CheckToken    :   url += "/auth"
        }
        return url
    }
    
    var parameters: [String: Any] {
        switch self {
        case .Userinfo:
            return [
                "openid": WeChat.openid ?? "",
                "access_token": WeChat.accessToken ?? ""
            ]
        case .AccessToken(let code):
            return [
                "appid": WeChat.appid,
                "secret": WeChat.appSecret,
                "code": code,
                "grant_type": "authorization_code"
            ]
        case .RefreshToken:
            return [
                "appid": WeChat.appid,
                "refresh_token": WeChat.refreshToken ?? "",
                "grant_type": "refresh_token"
            ]
        case .CheckToken:
            return [
                "openid": WeChat.openid ?? "",
                "access_token": WeChat.accessToken ?? ""
            ]
        }
    }
    
}