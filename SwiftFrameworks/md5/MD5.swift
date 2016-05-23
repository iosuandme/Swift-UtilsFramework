//
//  MD5.swift
//  QuestionLib
//
//  Created by 慧趣小歪 on 16/5/23.
//  Copyright © 2016年 小分队. All rights reserved.
//

import Foundation

extension String {
    var MD5:String {
        let str = cStringUsingEncoding(NSUTF8StringEncoding)!
        let strLen = CC_LONG(lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.alloc(digestLen)
        CC_MD5(str, strLen, result)
        
        let hash = NSMutableString()
        for i in 0 ..< digestLen {
            hash.appendFormat("%02x", result[i])
        }
        result.destroy(digestLen)
        
        return hash as String//String(format: hash as String)
    }
}