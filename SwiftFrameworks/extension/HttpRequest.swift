import Foundation



// MARK: - http 应答结果

public class HttpResponse {
    
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

public class HttpDownload:HttpResponse {
    
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

// MARK: - http 网络访问
public class HttpRequest {
    
    public typealias OnHttpRequestComplete = (HttpResponse) -> Void
    public typealias OnHttpRequestDownload = (HttpDownload) -> Void
    
    private let _url:NSURL
    public var url:NSURL { return _url }
    public var post:[String:String]?
    public var headers:[String:String]?
    public var timeout:NSTimeInterval = 15
    public var tag:Any? = nil
    
    public init(URL url:NSURL, post:[String:String]?, tag:Any? = nil, headers:[String:String]?, timeout:NSTimeInterval = 15) {
        self._url = url
        self.post = post
        self.tag  = tag
        self.headers = headers
        self.timeout = timeout
        NSURLSessionTask
    }
    
    public convenience init(URL url:NSURL, tag:Any? = nil) {
        self.init(URL:url, post:nil, tag:tag, headers:nil)
    }
    
    public convenience init(URL url:NSURL, tag:Any? = nil, timeout:NSTimeInterval) {
        self.init(URL:url, post:nil, tag:tag, headers:nil, timeout:timeout)
    }
    
    public convenience init(URL url:NSURL, post:[String:String]?, tag:Any? = nil) {
        self.init(URL:url, post:post, tag:tag, headers:nil)
    }
    
    public convenience init(URL url:NSURL, post:[String:String]?, tag:Any? = nil, timeout:NSTimeInterval) {
        self.init(URL:url, post:post, tag:tag, headers:nil, timeout:timeout)
    }
    
    class DownloadListener: ConnectListener {
        init (localPath:String, onStop:() -> Void) {
            super.init(onStop: onStop)
            self.response = HttpDownload()
            fileHandle = NSFileHandle(forWritingAtPath: "\(localPath).download")
            
            downloadResponse.data = localPath.dataUsingEncoding(NSUTF8StringEncoding)
            downloadResponse.localSize = fileHandle?.seekToEndOfFile() ?? 0
        }
        
        var fileHandle: NSFileHandle?
        var downloadResponse:HttpDownload { return response as! HttpDownload }
        var onProgress:OnHttpRequestDownload?
        
        //接收到服务器回应的时候调用此方法
        override func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
            super.connection(connection, didReceiveResponse: response)
            receiveData = nil
            // 获取将下载的文件大小 从 HeaderField  // Content-Length
            
            downloadResponse.totalSize = JSON.getValue(downloadResponse.headerFields["Content-Length"])?.unsignedLongLongValue ?? 0
            
            onProgress?(downloadResponse)
        }
        
        //接收到服务器传输数据的时候调用，此方法根据数据大小执行若干次
        override func connection(connection: NSURLConnection, didReceiveData data: NSData) {
            downloadResponse.localSize += UInt64(data.length)
            fileHandle?.writeData(data)
            onProgress?(downloadResponse)
        }
        
        //数据传完之后调用此方法
        override func connectionDidFinishLoading(connection: NSURLConnection) {
            fileHandle?.closeFile()
            fileHandle = nil
            
            let downloadResponse = self.downloadResponse
            downloadResponse.isOver = true
            let fileManager = NSFileManager.defaultManager()
            let path:String = downloadResponse.localPath
            do {
                try fileManager.moveItemAtPath("\(path).download", toPath: path)
            } catch let error {
                downloadResponse.error = error
            }
            
            onStop()
            onProgress?(downloadResponse)
        }
        
        //网络请求过程中，出现任何错误（断网，连接超时等）会进入此方法
        override func connection(connection: NSURLConnection, didFailWithError error: NSError) {
            fileHandle?.closeFile()
            fileHandle = nil
            
            let downloadResponse = self.downloadResponse
            downloadResponse.error = error
            downloadResponse.isOver = true
            onStop()
            onProgress?(downloadResponse)
        }
        
        override func cancel() {
            cancelConnection()
            onProgress?(downloadResponse)
        }
        
        deinit {
            fileHandle?.closeFile()
            fileHandle = nil
        }
    }
    
    class ConnectListener : NSObject, NSURLConnectionDelegate {
        var onStop:() -> Void
        init (onStop:() -> Void) {
            self.onStop = onStop
            self.response = HttpResponse()
        }
        
        var httpResponse:HttpResponse { return response }
        var response:HttpResponse
        
        var connection:NSURLConnection? = nil
        var receiveData:NSMutableData? = nil
        
        var onComplete:OnHttpRequestComplete?
        
        var isCancel:Bool = false
        
        private func cancelConnection() {
            isCancel = true
            connection?.cancel()
            onStop()
            response.statusCode = -1
        }
        func cancel() {
            cancelConnection()
            onComplete?(response)
        }
        
        //接收到服务器回应的时候调用此方法
        func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
            //let httpResponse = response as NSHTTPURLResponse
            receiveData = NSMutableData()
            
            guard let res = response as? NSHTTPURLResponse else {
                print("无法显示网络响应")
                return
            }
            
            let dateString:String = res.allHeaderFields["Date"] as? String ?? "Thu, 01 Jan 1970 00:00:00 GMT"
            
            let format  = NSDateFormatter()
            format.locale = NSLocale(localeIdentifier: "en_US")
            format.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
            
            let date:NSDate? = format.dateFromString(dateString)
            
            self.response.timestamp = date?.timeIntervalSince1970 ?? 0
            self.response.statusCode = res.statusCode
            self.response.headerFields = res.allHeaderFields
        }
        
        //接收到服务器传输数据的时候调用，此方法根据数据大小执行若干次
        func connection(connection: NSURLConnection, didReceiveData data: NSData) {
            if receiveData == nil {
                receiveData = NSMutableData()
            }
            receiveData!.appendData(data)
        }
        
        //数据传完之后调用此方法
        func connectionDidFinishLoading(connection: NSURLConnection) {
            self.connection = nil
            // 如果是Http访问
            if onComplete != nil {
                httpResponse.data = receiveData
            }
            receiveData = nil
            onStop()
            onComplete?(httpResponse)
        }
        
        //网络请求过程中，出现任何错误（断网，连接超时等）会进入此方法
        func connection(connection: NSURLConnection, didFailWithError error: NSError) {
            self.connection = nil
            receiveData = nil
            httpResponse.error = error
            onStop()
            onComplete?(httpResponse)
        }
    }
    
    private class func getURLRequest(http:HttpRequest) -> NSMutableURLRequest {
        let request:NSMutableURLRequest = NSMutableURLRequest(URL: http.url, cachePolicy: .UseProtocolCachePolicy, timeoutInterval: http.timeout)
        
        request.HTTPMethod = "GET"
        if let datas = http.post where datas.count > 0 {
            request.HTTPMethod = "POST"
            var postString = ""
            for (key, value) in datas {
                if !postString.isEmpty {
                    postString += "&"
                }
                postString += "\(key.encodeURL())=\(value.encodeURL())"
            }
            let data:NSData = postString.dataUsingEncoding(NSUTF8StringEncoding)!
            
            request.HTTPBody = data;
            request.setValue("\(data.length)", forHTTPHeaderField: "Content-Length")
            if let httpHeaders = http.headers {
                for (header, value) in httpHeaders {
                    request.setValue(value, forHTTPHeaderField: header)
                }
            }
        }
        return request
    }
    
    public var isConnecting:Bool { return !(_listener?.isCancel ?? true) }
    public var isCancel:Bool { return !(_listener?.isCancel ?? false) }
    public func cancel() {
        _listener?.cancel()
    }
    
    private var _listener:ConnectListener?
    public func send(onComplete:OnHttpRequestComplete) {
        if let listener = _listener {
            listener.cancel()
        }
        let listener = ConnectListener() { self._listener = nil }
        listener.onComplete = onComplete
        listener.response.tag = self.tag
        
        let request:NSMutableURLRequest = HttpRequest.getURLRequest(self)
        
        //连接服务器
        _listener = listener
        listener.connection = NSURLConnection(request: request, delegate: listener)
        
    }
    
    public func downloadTo(localPath:String, onProgress:OnHttpRequestDownload) {
        if let listener = _listener {
            listener.cancel()
        }
        let listener = DownloadListener(localPath: localPath) { self._listener = nil }
        
        listener.onProgress = onProgress
        listener.response.tag = self.tag
        
        let request:NSMutableURLRequest = HttpRequest.getURLRequest(self)
        _listener = listener
        listener.connection = NSURLConnection(request: request, delegate: listener)
        
    }
    
}


// MARK: - Http 队列
struct HttpQueue {
    
    private typealias DownloadListener = HttpRequest.DownloadListener
    private typealias ConnectListener = HttpRequest.ConnectListener
    private typealias OnComplete = HttpRequest.OnHttpRequestComplete
    private typealias OnProgress = HttpRequest.OnHttpRequestDownload
    private typealias Request = (HttpRequest, OnComplete)
    private typealias Download = (HttpRequest, String, OnProgress)
    
    private static var _requests:[Request] = []
    private static var _downloads:[Download] = []
    
    static func cancel() {
        _listener?.cancel()
    }
    static func cancelAll() {
        _requests.removeAll()
        _listener?.cancel()
    }
    
    static func cancelDownload() {
        _downloadListener?.cancel()
    }
    static func cancelAllDownload() {
        _downloads.removeAll()
        _downloadListener?.cancel()
    }
    
    static func sendRequest(request:HttpRequest, onComplete:HttpRequest.OnHttpRequestComplete) {
        _requests.append((request, onComplete))
        sendNextIfHas(true)
    }
    
    static func downloadRequest(request:HttpRequest, localPath:String, onProgress:HttpRequest.OnHttpRequestDownload) {
        _downloads.append((request, localPath, onProgress))
        downloadNextFileIfHas(true)
    }
    
    private static func downloadNextFileIfHas(callByAdd:Bool) {
        if _downloads.count == 0 {
            _downloadListener = nil
            return
        }
        if _downloads.count > 1 && callByAdd{
            return
        }
        let (request, localPath, onProgress) = _downloads.first!
        
        let listener = DownloadListener(localPath: localPath) { self._listener = nil }
        
        listener.onProgress = {
            (response) in
            NSOperationQueue.mainQueue().addOperationWithBlock {
                onProgress(response)
            }
            if response.isOver {
                if _downloads.count > 0 { _downloads.removeFirst() }
                downloadNextFileIfHas(false)
            }
        }
        listener.response.tag = request.tag
        
        let urlRequest:NSMutableURLRequest = HttpRequest.getURLRequest(request)
        _downloadListener = listener
        listener.connection = NSURLConnection(request: urlRequest, delegate: listener)
    }
    
    private static var _downloadListener:DownloadListener?
    private static var _listener:ConnectListener?
    
    private static func sendNextIfHas(callByAdd:Bool) {
        if _requests.count == 0 {
            _listener = nil
            return
        }
        if _requests.count > 1 && callByAdd {
            return
        }
        let (request, onComplete) = _requests.first!
        
        let listener = ConnectListener() {  }
        listener.onComplete = {
            (response:HttpResponse) in
            NSOperationQueue.mainQueue().addOperationWithBlock {
                onComplete(response)
            }
            if _requests.count > 0 {
                _requests.removeFirst()
            }
            sendNextIfHas(false)
        }
        listener.response.tag = request.tag
        
        let urlRequest:NSMutableURLRequest = HttpRequest.getURLRequest(request)
        
        //连接服务器
        _listener = listener
        listener.connection = NSURLConnection(request: urlRequest, delegate: listener)
        
    }
    
    
}