//
//  HttpSessionRequest.swift
//  QuestionLib
//
//  Created by 慧趣小歪 on 16/3/21.
//  Copyright © 2016年 小分队. All rights reserved.
//

import Foundation

public class HttpSessionResponse {
    
    /// 访问结果 HTML 内容
    public var data:NSData?
    public var content:String {
        guard let data = data else { return "" }
        return String(data: data, encoding: NSUTF8StringEncoding) ?? ""
    }
    
    /// 附加信息
    public var tag:Any?
    
    /// HTTP 访问 错误信息
    public var error:ErrorType?
    
    /// 服务端响应头字段
    public var headerFields:NSDictionary = [:]
    
    /// 服务器时间戳
    public var timestamp:NSTimeInterval = 0
    public var serverDate:Date { return Date(timestamp) }
    
    /// HTTP 状态代码
    public var statusCode:Int = 0
    public var isCancel:Bool { return statusCode < 0 }
    
    /// HTTP 状态文字描述
    public var statusString:String {
        if statusCode < 0 { return "user cancel" }
        return NSHTTPURLResponse.localizedStringForStatusCode(statusCode)
    }
    
}

public class HttpSessionDownload:HttpResponse {
    
    /// 文件总大小
    public var totalSize:UInt64 = 0
    
    /// 已下载大小
    public var localSize:UInt64 = 0
    
    /// 本地下载路径
    public var localPath:String { return content }
    
    /// 下载结束标记(如果下载结束, 无论成功失败都为 true)
    public var isOver:Bool = false
    
    /// 下载进度百分比
    public var progressPercent:Double {
        if totalSize == 0 { return 0 }
        return ceil(Double(localSize / totalSize) * 100)
    }
}

class HttpSessionRequest {

}
