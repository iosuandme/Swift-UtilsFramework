//
//  FtpClient.swift
//
//  Created by 慧趣工作室 on 14/9/24.
//

import UIKit

func ==(lhs: FtpClient.Item, rhs: FtpClient.Item) -> Bool {
    return lhs.name == rhs.name &&
        lhs.size == rhs.size &&
        lhs.type == rhs.type &&
        lhs.createDate.timeIntervalSince1970 == rhs.createDate.timeIntervalSince1970
}

class FtpClient :NSObject, NSStreamDelegate {
    
    // MARK: - 文件或目录数据结构
    struct Item : Equatable, Printable {
        
        var description: String { return toDictionary().description }

        enum Type : Int {
            case Unknow = 0
            case Dictionary = 4
            case File = 8
        }
        
        var owner:String
        var group:String
        
        var link:NSURL?
        var name:String
        var createDate:NSDate
        
        var type:Type
        var accessMode:UInt
        var size:UInt64
        
        init (dictionary dict:[NSObject:AnyObject], rootURL:NSURL? = nil) {
            let ownerKey = "\(kCFFTPResourceGroup)" //kCFFTPResourceGroup as NSObject
            owner = ((dict["kCFFTPResourceOwner"] as? NSString) ?? "") as String
            group = ((dict["kCFFTPResourceGroup"] as? NSString) ?? "") as String
            
            name = ((dict["kCFFTPResourceName"] as? NSString) ?? "") as String
            
            let typeValue = dict["kCFFTPResourceType"] as? NSNumber
            type = Type(rawValue: typeValue?.integerValue ?? 0) ?? .Unknow
            let sizeValue = dict["kCFFTPResourceSize"] as? NSNumber
            size = sizeValue?.unsignedLongLongValue ?? 0
            let modeValue = dict["kCFFTPResourceMode"] as? NSNumber
            accessMode = modeValue?.unsignedLongValue ?? 0
            
            createDate = dict["kCFFTPResourceModDate"] as? NSDate ?? NSDate(timeIntervalSince1970: 0)
            
            if let root = rootURL {
                link = NSURL(string: "\(root)\(name)")
                //println("link:\(link)")
            } else if let url = dict["kCFFTPResourceLink"] as? NSString {
                link = NSURL(string: url as String) // dict["kCFFTPResourceLink"] as? NSURL
            }

        }
        
        func toDictionary() -> [NSObject:AnyObject] {
            var dict:[NSObject:AnyObject] = [:]
            
            dict["kCFFTPResourceModDate"] = createDate
            dict["kCFFTPResourceOwner"] = owner
            dict["kCFFTPResourceGroup"] = group
            dict["kCFFTPResourceName"] = name
            dict["kCFFTPResourceType"] = NSNumber(integer: type.rawValue)
            dict["kCFFTPResourceSize"] = NSNumber(unsignedLongLong: size)
            dict["kCFFTPResourceMode"] = NSNumber(unsignedLong: accessMode)
            dict["kCFFTPResourceLink"] = link?.description ?? ""
        
            return dict
        }
    }
    
    let name:String
    let pass:String
    let host:String
    let port:UInt
    
    init (host:String, port:UInt, name:String = "", pass:String = "") {
        self.host = host
        self.port = port
        self.name = name
        self.pass = pass
    }
    
    // MARK: - 获取列表回调函数
    typealias OnGetListCompleteBlock = (items:[Item]?, error:NSError?) -> Void
    
    private var _onGetListComplete:OnGetListCompleteBlock?
    private var _inputStream:NSInputStream?
    private var _listData:NSMutableData?
    private var _url:NSURL?
    
    deinit {
        stopReceiveWithStatus("canceled with deinit")
    }
    
    // MARK: - 获取FTP目录内容
    func getListWithPath(path:String, onComplete:OnGetListCompleteBlock) {
        stopReceiveWithStatus("canceled with new getList")
        _onGetListComplete = onComplete
        //println("ftp://\(name):\(pass)@\(host):\(port)/\(path)/")
        _url = NSURL(string: "ftp://\(name):\(pass)@\(host):\(port)/\(path)/")
        
        //println("ftp获取列表:\(_url)")
        
        if let url = _url {
            _listData = NSMutableData()
            
            let unmanaged = CFReadStreamCreateWithFTPURL(nil, url as CFURLRef)
            let inputStream:NSInputStream = unmanaged.takeUnretainedValue()
            unmanaged.release()
            
            inputStream.delegate = self
            inputStream.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
            inputStream.open()
            _inputStream = inputStream
        }
    }
    
    func cancel() {
        stopReceiveWithStatus("canceled")
    }
    
    // MARK: - 正在接收数据
    var isReceiving:Bool {
        return _inputStream != nil
    }
    
    // MARK: - 停止接收数据
    private func stopReceiveWithStatus(state:String) {

        if let inputStream = _inputStream {
            inputStream.removeFromRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
            inputStream.delegate = nil
            inputStream.close()
            _inputStream = nil
        }

        if let complete = _onGetListComplete {
            complete(items: nil, error: NSError(domain: state, code: 0, userInfo: nil))
            _onGetListComplete = nil
        }

        _listData = nil
        _url = nil
    }
    
    // MARK: - NSStreamDelegate
    internal func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent) {
        assert(aStream == _inputStream, "异常的接收数据流对象")
        switch eventCode {
        case NSStreamEvent.OpenCompleted:
            println("打开链接[\(_url)]")
        case NSStreamEvent.HasBytesAvailable:
            //println("已接收数据:\(_listData?.length)")
            let length = 32768
            var buffer: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.alloc(length)
            //let size = sizeofValue(buffer)
            //println("size\(buffer.)")
            if let inputStream = _inputStream {
                let bytesRead = inputStream.read(buffer, maxLength: length)
                if bytesRead < 0 {
                    stopReceiveWithStatus("网络数据读取失败")
                } else if bytesRead == 0 {
                    stopReceiveWithStatus("")
                } else {
                    assert(_listData != nil, "数据不能为 nil")
                    //println("又接收数据:\(bytesRead)")
                    
                    _listData!.appendBytes(buffer, length: bytesRead)
                    
                    // TODO: 解析文件列表数据
                    parseListData()
                }
            }
        case NSStreamEvent.HasSpaceAvailable:
            assert(false, "should never happen for the output stream")
        case NSStreamEvent.ErrorOccurred:
            stopReceiveWithStatus("数据流打开失败")
        case NSStreamEvent.EndEncountered:
            break   //ignore
        default:
            break
        }
    }
    
    // MARK: - 解析收到数据包
    private func parseListData() {
        
        if let listData = _listData {
            
            var newEntries:[[NSObject:AnyObject]] = []
            
            var offset:Int = 0
            do {
                var thisEntry:Unmanaged<CFDictionaryRef>?

                let length = listData.length - offset

                var buffer:UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.alloc(length)
                listData.getBytes(buffer, range: NSMakeRange(offset, length))
                
                let bytesConsumed = CFFTPCreateParsedResourceListing(nil, buffer, CFIndex(length), &thisEntry)
                
                if bytesConsumed > 0 {
                    if let entry = thisEntry {
                        newEntries.append(entryByReencodingNameInEntry(entry.takeUnretainedValue(), encoding: NSUTF8StringEncoding))
                        entry.release()
                    }
                    offset += bytesConsumed;
                } else if bytesConsumed == 0 {
                    break
                } else {
                    stopReceiveWithStatus("Listing parse failed")
                    break
                }
                
            } while true
                        
            if newEntries.count > 0 {
                if let complete = _onGetListComplete {
                    var items:[Item] = []
                    for dict in newEntries {
                        items.append(Item(dictionary: dict, rootURL: _url))
                    }
                    complete(items: items, error: nil)
                    _onGetListComplete = nil
                }
                stopReceiveWithStatus("")
            }
            
        }
        
    }
    
    // MARK: - 字典编码转换处理
    private func entryByReencodingNameInEntry(entry:NSDictionary, encoding:NSStringEncoding) -> [NSObject:AnyObject] {
        
        //println("dict:\(entry)")
        
        var dict:[NSObject:AnyObject] = [:]
        
        var newName:String? = nil
        
        if let name = entry["kCFFTPResourceName"] as? NSString {
            if let data = name.dataUsingEncoding(NSMacOSRomanStringEncoding) {
                newName = NSString(data: data, encoding: NSUTF8StringEncoding) as?  String
            }
        }
        if let name = newName {
            dict["kCFFTPResourceName"] = name
        } else {
            dict["kCFFTPResourceName"] = entry["kCFFTPResourceName"]
        }
        dict["kCFFTPResourceModDate"] = entry["kCFFTPResourceModDate"]
        dict["kCFFTPResourceOwner"] = entry["kCFFTPResourceOwner"]
        dict["kCFFTPResourceGroup"] = entry["kCFFTPResourceGroup"]
        dict["kCFFTPResourceMode"] = entry["kCFFTPResourceMode"]
        dict["kCFFTPResourceSize"] = entry["kCFFTPResourceSize"]
        dict["kCFFTPResourceType"] = entry["kCFFTPResourceType"]
        dict["kCFFTPResourceLink"] = entry["kCFFTPResourceLink"]
        
        return dict
    }

    
    
}

