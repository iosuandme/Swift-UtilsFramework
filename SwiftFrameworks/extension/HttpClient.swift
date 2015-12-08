//
//  HttpClient.swift
//  SwiftFrameworkTesting
//
//  Created by 招利 李 on 14-6-24.
//  Copyright (c) 2014年 慧趣工作室. All rights reserved.
//

import Foundation



class HttpClient: NSObject {
    
    //URL 解编码
    class func decodeEscapesURL(value:String) -> String? {
        let str:NSString = value
        return str.stringByReplacingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
/*
        var outputStr:NSMutableString = NSMutableString(string:value);
        outputStr.replaceOccurrencesOfString("+", withString: " ", options: NSStringCompareOptions.LiteralSearch, range: NSMakeRange(0, outputStr.length))
        return outputStr.stringByReplacingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
*/
    }
    //URL 编码
    class func encodeEscapesURL(value:String) -> String {
        let originalString:CFStringRef = value as NSString
        let charactersToBeEscaped = "!*'();:@&=+$,/?%#[]" as CFStringRef  //":/?&=;+!@#$()',*"    //转意符号
        //let charactersToLeaveUnescaped = "[]." as CFStringRef  //保留的符号
        let result =
        CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
            originalString,
            nil,    //charactersToLeaveUnescaped,
            charactersToBeEscaped,
            CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)) as NSString
        
        return result as String
    }

    class func arrayFromJSON(json:String!) -> [AnyObject]! {
        return objectFromJSON(json) as? [AnyObject] //Array<AnyObject>
    }
    class func dictionaryFromJSON(json:String!) -> [NSObject:AnyObject]! {
        return objectFromJSON(json) as? [NSObject:AnyObject] //Dictionary<String,AnyObject>
    }
    
    //把 JSON 转成 Array 或 Dictionary
    class func objectFromJSON(json:String!) -> AnyObject! {
        let string:NSString = json
        let data = string.dataUsingEncoding(NSUTF8StringEncoding)
        var object : AnyObject!
        do {
            object = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions(rawValue: 0))
        } catch let error {
            print("JSON to object error:\(error)")
            return nil
        }
        return object;

    }
    //把 Array 或 Dictionary 转 JSON
    class func JSONFromObject(object:AnyObject!) -> String!{
        if !NSJSONSerialization.isValidJSONObject(object) {
            return nil
        }
        do {
            let data = try NSJSONSerialization.dataWithJSONObject(object, options: NSJSONWritingOptions(rawValue: 0))
            return String(data: data, encoding: NSUTF8StringEncoding)
        } catch let error {
            print("object to JSON error:\(error)")
            return nil
        }

    }

    var timeoutInterval: NSTimeInterval
    init(timeoutInterval: NSTimeInterval){
        self.timeoutInterval = timeoutInterval
    }
    override init() {
        timeoutInterval = 10;
    }
    
    var downloadCachePath:String {
        //let document = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString
        //return document.a
        return (NSTemporaryDirectory() as NSString).stringByAppendingPathComponent("DownloadCaches")
    }
    
    func downloadCachePathWithURL(url:NSURL) -> String {
        let name = url.description.componentsSeparatedByString(".").last!
        //assert(!name.isEmpty || DEBUG == 0, "找不到要下载的文件名[\(url)]")
        let fileName = "\(name).download"
        return (downloadCachePath as NSString).stringByAppendingPathComponent(fileName)
    }
    
    // MARK: - Http下载
    typealias DownloadCompleteBlock = (topbytes:UInt64, data:NSData?, error:NSError?, finishPath:String?) -> Void
    var onDownloadOver:DownloadCompleteBlock?
    func download(URL url:NSURL, post:[String:String]?, cleanCache:Bool = false, var headers:[String:String]? = nil, onComplete:DownloadCompleteBlock) {
        self.cancel();
        
        let cache = downloadCachePath
        
        // 如果下载缓存目录不存在则创建
        var isDir:ObjCBool = false
        let fileManager = NSFileManager.defaultManager()
        if !fileManager.fileExistsAtPath(cache, isDirectory: &isDir) || !isDir {
            do {
                try fileManager.createDirectoryAtPath(cache, withIntermediateDirectories: false, attributes: nil)
            } catch { }
        }
        
        let path = downloadCachePathWithURL(url)
        var size:UInt64 = 0
        
        if fileManager.fileExistsAtPath(path) {         // 如果文件已下载完
            let data = NSData(contentsOfFile: path)
            receiveData = nil//NSMutableData(contentsOfFile: path) //data.mutableCopy() as? NSMutableData
            topbytes = 0
            if let onDownloadComplete = onDownloadOver {
                let length = data?.length ?? 0
                onDownloadComplete(topbytes: UInt64(length), data: data, error: nil, finishPath: path)
                onDownloadOver = nil
            }
            return
        } else if fileManager.fileExistsAtPath(path + ".download") {
            let filePath = path + ".download"
            if cleanCache {
                do {
                    try fileManager.removeItemAtPath(filePath)
                } catch {}
                fileManager.createFileAtPath(filePath, contents: nil, attributes: nil)
            } else {
                do {
                    let number = try fileManager.attributesOfItemAtPath(filePath)["fileSize"] as! NSNumber
                    size = number.unsignedLongLongValue
                } catch {}
            }
        } else {
            fileManager.createFileAtPath(path + ".download", contents: nil, attributes: nil)
        }

        if size > 0 {
            if headers == nil { headers = [:] }
            headers!["Range"] = "bytes=\(size)-"
            headers!["Content-Type"] = "application/octet-stream"
        }
        
        

        _request(URL: url, post: post, headers: headers, onComplete: nil)
        
        // 设置下载回调函数
        self.onDownloadOver = onComplete

    }
    
    // MARK: - Http访问
    typealias HttpCompleteBlock = (html:String, error:NSError?) -> Void
    var onHttpOver:HttpCompleteBlock?
    func request(URL url:NSURL, post:[String:String]? = nil, headers:[String:String]? = nil, onComplete:HttpCompleteBlock?) {
        self.cancel();
        _request(URL: url, post: post, headers: headers, onComplete: onComplete)
    }
    private func _request(URL url:NSURL, post:[String:String]? = nil, headers:[String:String]? = nil, onComplete:HttpCompleteBlock?) {
        //设置回掉函数
        self.onHttpOver = onComplete
        
        let request:NSMutableURLRequest = NSMutableURLRequest(URL: url, cachePolicy: .UseProtocolCachePolicy, timeoutInterval: timeoutInterval)
        
        request.HTTPMethod = "GET"
        if let datas = post {
            if datas.count > 0 {
                request.HTTPMethod = "POST"
                let postString:NSMutableString = ""
                for (key,value) in datas {
                    if postString.length > 0 {
                        postString.appendString("&")
                    }
                    let keyEncodeURL = HttpClient.encodeEscapesURL(key)
                    let valueEncodeURL = HttpClient.encodeEscapesURL(value)
                    postString.appendString("\(keyEncodeURL)=\(valueEncodeURL)")
                }
                let data:NSData = postString.dataUsingEncoding(NSUTF8StringEncoding)!
                request.HTTPBody = data;
                request.setValue("\(data.length)", forHTTPHeaderField: "Content-Length")
                if let httpHeaders = headers {
                    for (header,value) in httpHeaders {
                        request.setValue(value, forHTTPHeaderField: header)
                    }
                }
                
            }
        }
        //连接服务器
        
        connection = NSURLConnection(request: request, delegate: self)
    }
    
    var connection:NSURLConnection? = nil
    func cancel() {
        if let conn = connection {
            conn.cancel()
        }
        self.connection = nil
        // 如果是Http访问
        if let complete = onHttpOver {
            complete(html: "",error: NSError(domain: "用户取消了HTTP发送", code: 0, userInfo: nil))
            onHttpOver = nil
        }
        // 如果是Http下载
        if let onDownloadComplete = onDownloadOver {
            
            if let handle = fileHandle {
                handle.closeFile()
                fileHandle = nil
            }
            
            onDownloadOver = nil
            topbytes = 0
            onDownloadComplete(topbytes: topbytes, data: receiveData, error: NSError(domain: "用户取消了HTTP下载", code: 0, userInfo: nil), finishPath: nil)
        }
        receiveData = nil
    }
    
    deinit {
        if let _ = connection {
            cancel()
        }
        if let handle = fileHandle {
            handle.closeFile()
            fileHandle = nil
        }
        receiveData = nil
    }
    
    // MARK: - 正在接收数据
    var isReceiving:Bool {
        return receiveData != nil
    }
    
    var topbytes:UInt64 = 0
    var receiveData:NSMutableData? = nil
    var fileHandle:NSFileHandle! = nil
}

extension HttpClient:NSURLConnectionDelegate {
    
    //接收到服务器回应的时候调用此方法
    func connection(connection: NSURLConnection!, didReceiveResponse response: NSURLResponse!) {
        //let httpResponse = response as NSHTTPURLResponse
        receiveData = NSMutableData()
        if let onDownloadComplete = onDownloadOver {
            let path = downloadCachePathWithURL(connection.currentRequest.URL!)
            if let data = NSData(contentsOfFile: path + ".download") {
                receiveData!.appendData(data)
            }
            if let res = response as? NSHTTPURLResponse {
                let length = res.allHeaderFields["Content-Length"] as! NSString
                topbytes = UInt64(length.longLongValue)
            }
            onDownloadComplete(topbytes: topbytes, data: receiveData, error: nil, finishPath: nil)
        }
    }
    
    //接收到服务器传输数据的时候调用，此方法根据数据大小执行若干次
    func connection(connection: NSURLConnection!, didReceiveData data: NSData!) {
        if receiveData == nil {
            receiveData = NSMutableData()
        }
        //receiveData!.appendData(data)
        if let onDownloadComplete = onDownloadOver {
            if fileHandle == nil {
                let path = downloadCachePathWithURL(connection.currentRequest.URL!)
                fileHandle = NSFileHandle(forWritingAtPath: path + ".download")
            }
            fileHandle.seekToEndOfFile()
            fileHandle.writeData(data)
            onDownloadComplete(topbytes: topbytes, data: receiveData, error: nil, finishPath: nil)
        }

        if let receive = receiveData {
            receive.appendData(data)
        } else {
            receiveData = NSMutableData()
            receiveData!.appendData(data)
        }
    }
    
    //数据传完之后调用此方法
    func connectionDidFinishLoading(connection: NSURLConnection!) {
        self.connection = nil
        // 如果是Http访问
        if let complete = onHttpOver {
            let html:String = NSString(data: receiveData!, encoding: NSUTF8StringEncoding)! as String
            complete(html: html,error: nil)
            onHttpOver = nil
        }
        // 如果是Http下载
        if let onDownloadComplete = onDownloadOver {
            
            if let handle = fileHandle {
                handle.closeFile()
                fileHandle = nil
            }
            
            let url = connection.currentRequest.URL!
            let path = downloadCachePathWithURL(url)
            
            let fileManager = NSFileManager.defaultManager()
            do {
            try fileManager.moveItemAtPath(path + ".download", toPath: path)
            } catch {}
            
            
            onDownloadOver = nil
            topbytes = 0
            onDownloadComplete(topbytes: topbytes, data: receiveData, error: nil, finishPath: path)
        }
        receiveData = nil
    }
    
    //网络请求过程中，出现任何错误（断网，连接超时等）会进入此方法
    func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        self.connection = nil
        // 如果是Http访问
        if let complete = onHttpOver {
            complete(html: "",error: error)
            onHttpOver = nil
        }
        // 如果是Http下载
        if let onDownloadComplete = onDownloadOver {
            
            if let handle = fileHandle {
                handle.closeFile()
                fileHandle = nil
            }
            
            
            onDownloadOver = nil
            topbytes = 0
            onDownloadComplete(topbytes: topbytes, data: receiveData, error: error, finishPath: nil)

        }
        receiveData = nil
    }
}
