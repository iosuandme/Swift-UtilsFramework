//
//  Error.swift
//
//  Created by 李招利 on 14/9/29.
//
//  值类型错误 Error
//

import Foundation

public func ==(lhs: Error, rhs: Error) -> Bool {
    switch (lhs,rhs) {
    case (.OK, .OK):
        return true
    case (.Warning(let lContent), .Warning(let rContent)):
        return lContent == rContent
    case (let .Error(lCode, lContent, _), let .Error(rCode, rContent, _)):
        return lCode == rCode && lContent == rContent
    default:
        return false
    }
}


public enum Error : Equatable, ErrorType {
    case OK
    case Warning(content:String)
    case Error(code:Int, content:String, userInfo:Any?)
}

/*
struct Error {
let code:Int
let content:String
let file:String
let funcName:String
let line:UInt
let userInfo:Any?

init(code:Int, content:String, userInfo:Any? = nil, file:String = __FILE__, funcName:String = __FUNCTION__, line:UInt = __LINE__) {
self.code = code
self.content = content
self.file = file
self.line = line
self.funcName = funcName
self.userInfo = userInfo
}
}
*/

extension Error : CustomStringConvertible {
    public var description: String {
        switch self {
        case .OK:
            return "OK"
        case let .Warning (content):
            return "Warning:\(content)"
        case let .Error (code, content, _):
            return "Error:\(code) -> \(content)"
        }
    }
}

extension Error : CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .OK:
            return "OK"
        case let .Warning (content):
            return "Warning:\(content)"
        case let .Error (code, content, userInfo):
            return "Error:\(code) -> \(content) [userInfo:\(userInfo)]"
        }
    }
}