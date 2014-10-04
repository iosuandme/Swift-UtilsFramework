//
//  Error.swift
//
//  Created by 李招利 on 14/9/29.
//
//  值类型错误 Error
//

import Foundation

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

extension Error : Printable {
    var description: String {
        return "[error:\(code)] \(content)"
    }
}

extension Error : DebugPrintable {
    var debugDescription: String {
        return "[error:\(code)] \(content)\nat file:\(file) line:\(line)\nuserInfo:\(userInfo)"
    }
}