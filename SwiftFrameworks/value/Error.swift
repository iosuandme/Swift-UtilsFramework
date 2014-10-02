//
//  Error.swift
//
//  Created by 李招利 on 14/9/29.
//
//  值类型错误 Error
//

import Foundation

extension Array {
    func indexOf(includeElement: (T) -> Bool) -> Int {
        for i in 0..<count {
            if includeElement(self[i]) {
                return i
            }
        }
        return NSNotFound
    }
    
    func componentsJoinedByString(separator:String) -> String {
        var result = ""
        for item:T in self {
            if !result.isEmpty {
                result += separator
            }
            result += "\(item)"
        }
        return result
    }
}

struct Error {
    let code:Int
    let content:String
    let file:String
    let line:UInt
    let userInfo:Any?
    
    init(code:Int, content:String, userInfo:Any? = nil, file:String = __FILE__, line:UInt = __LINE__) {
        self.code = code
        self.content = content
        self.file = file
        self.line = line
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