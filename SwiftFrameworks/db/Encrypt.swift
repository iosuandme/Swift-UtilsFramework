//
//  Encrypt.swift
//  SwiftFrameworks
//
//  Created by 招利 李 on 14/11/17.
//  Copyright (c) 2014年 慧趣工作室. All rights reserved.
//

import Foundation

struct Encrypt {
    
    let publicKey:String
    var randomKeyLength = 32
    
    init (publicKey:String, randomKeyLength:Int = 32) {
        self.publicKey = publicKey
        self.randomKeyLength = randomKeyLength <= 0 ? 32 : randomKeyLength
    }
    
    // 加密 json
    func encodeJSON(json:String, privateKey:String) -> String {
        let randomKeyChars  = Encrypt.getRandomKeyChars(randomKeyLength)
        let publicKeyChars  = Encrypt.bufferWithString(publicKey)
        let privateKeyChars = Encrypt.bufferWithString(privateKey)
        var contentChars    = Encrypt.bufferWithString(json)
        
        // 第一步先用随机密钥 从前往后 编码
        var keyIndex = 0
        for var i:Int = 0; i < contentChars.count; i++ {
            var char = Int32(contentChars[i])
            let randomChar = Int32(randomKeyChars[keyIndex])
            
            // 如果密钥循环一遍后 从0开始重新循环
            if ++keyIndex >= randomKeyChars.count { keyIndex = 0 }
            char += randomChar - 32
            char = char > 126 ? char - 94 : char
            contentChars[i] = UInt8(char & 0xFF)
        }

        // 第二步先用随机密钥 从后往前 编码
        keyIndex = 0
        for var i:Int = contentChars.count - 1; i >= 0; i-- {
            var char = Int32(contentChars[i])
            let randomChar = Int32(randomKeyChars[keyIndex])
            
            // 如果密钥循环一遍后 从0开始重新循环
            if ++keyIndex >= randomKeyChars.count { keyIndex = 0 }
            char += randomChar - 32
            char = char > 126 ? char - 94 : char
            contentChars[i] = UInt8(char & 0xFF)
        }
        

        // 将随机密钥附加到内容顶部
        contentChars = randomKeyChars + contentChars

        // 在顶部附加随机密钥长度
        for var i:Int = 0; i < 32; i += 4 {
            let num = (randomKeyLength >> i) & 0xF
            let numChar = UInt8(num + (num > 9 ? 55 : 48))
            contentChars.insert(numChar, atIndex: 0)
        }
        
        // 第三步再用私有密钥 从后往前 编码
        keyIndex = 0
        for var i:Int = contentChars.count - 1; i >= 0; i-- {
            var char = Int32(contentChars[i])
            let privateChar = Int32(privateKeyChars[keyIndex])
            
            // 如果密钥循环一遍后 从0开始重新循环
            if ++keyIndex >= privateKeyChars.count { keyIndex = 0 }
            char += privateChar - 32
            char = char > 126 ? char - 94 : char
            contentChars[i] = UInt8(char & 0xFF)
        }
        
        // 第四步最后用共有密钥 从前往后 编码
        keyIndex = 0
        for var i:Int = 0; i < contentChars.count; i++ {
            var char = Int32(contentChars[i])
            let publicChar = Int32(publicKeyChars[keyIndex])
            
            // 如果密钥循环一遍后 从0开始重新循环
            if ++keyIndex >= publicKeyChars.count { keyIndex = 0 }
            char += publicChar - 32
            char = char > 126 ? char - 94 : char
            contentChars[i] = UInt8(char & 0xFF)
        }


        return NSString(bytes: &contentChars, length: contentChars.count, encoding: NSUTF8StringEncoding)! as String
    }
    
    // 解密 JSON
    func decodeJSON(encodeJSON:String, privateKey:String) -> String {
        let publicKeyChars  = Encrypt.bufferWithString(publicKey)
        let privateKeyChars = Encrypt.bufferWithString(privateKey)
        var length = count(encodeJSON) + 1
        var contentChars:[UInt8] = Array<UInt8>(count: length, repeatedValue: 0)

        var range = encodeJSON.startIndex..<encodeJSON.endIndex
        if encodeJSON.getBytes(&contentChars, maxLength: contentChars.count, usedLength: &length, encoding: NSUTF8StringEncoding, options: NSStringEncodingConversionOptions.allZeros, range: range, remainingRange: &range) {
            
            contentChars.removeRange(length..<contentChars.count)
            
            // 解密共有密钥 从前往后 减编码
            var keyIndex = 0
            for var i:Int = 0; i < contentChars.count; i++ {
                var char = Int32(contentChars[i])
                let publicChar = Int32(publicKeyChars[keyIndex])
                
                // 如果密钥循环一遍后 从0开始重新循环
                if ++keyIndex >= publicKeyChars.count { keyIndex = 0 }
                char -= publicChar - 32
                char = char < 32 ? char + 94 : char
                contentChars[i] = UInt8(char & 0x7F)
            }
            
            // 解密私有密钥 从后往前 减编码
            keyIndex = 0
            for var i:Int = contentChars.count - 1; i >= 0; i-- {
                var char = Int32(contentChars[i])
                let privateChar = Int32(privateKeyChars[keyIndex])
                
                // 如果密钥循环一遍后 从0开始重新循环
                if ++keyIndex >= privateKeyChars.count { keyIndex = 0 }
                char -= privateChar - 32
                char = char < 32 ? char + 94 : char
                contentChars[i] = UInt8(char & 0x7F)
            }
            
            // 解密随机密钥
            var length = 0
            for var i:Int = 0; i < 8; i++ {
                var char = Int(contentChars[i]) - 48
                char = char < 10 ? char : char - 7
                length += char << (28 - i * 4)
            }
            print("随机密钥长度\(length)")
            // 0 ... 5     0 , 1 ,2 , 3 ,4
            let randomKeyChars = contentChars[8...(length + 7)]
            //var contents = contentChars[(length + 3)..<usedLength]
            contentChars.removeRange(0...(length + 7))
            
            // 第三步先用随机密钥 从后往前 减编码
            keyIndex = 0
            for var i:Int = contentChars.count - 1; i >= 0; i-- {
                var char = Int32(contentChars[i])
                let randomChar = Int32(randomKeyChars[keyIndex])
                
                // 如果密钥循环一遍后 从0开始重新循环
                if ++keyIndex >= randomKeyChars.count { keyIndex = 0 }
                char -= randomChar - 32
                char = char < 32 ? char + 94 : char
                contentChars[i] = UInt8(char & 0x7F)
            }
            
            // 第四步再用随机密钥 从前往后 减编码
            keyIndex = 0
            for var i:Int = 0; i < contentChars.count; i++ {
                var char = Int32(contentChars[i])
                let randomChar = Int32(randomKeyChars[keyIndex])
                
                // 如果密钥循环一遍后 从0开始重新循环
                if ++keyIndex >= randomKeyChars.count { keyIndex = 0 }
                char -= randomChar - 32
                char = char < 32 ? char + 94 : char
                contentChars[i] = UInt8(char & 0x7F)
            }
            print(contentChars.count)

        }
        // 读取加密内容到数组
        
        
        return NSString(bytes: &contentChars, length: contentChars.count, encoding: NSUTF8StringEncoding)! as String
    }
    

    // MARK: - 给中文加 \uXXXX 编码
    static func bufferWithString(string:String) -> [UInt8] {
        var buffer = Array<UInt8>()
        for unicodeScalar in string.unicodeScalars {
            let char = unicodeScalar.value
            if !unicodeScalar.isASCII() {
                buffer.append(92)           // 代表\
                buffer.append(117)          // 代表u
                // 2字节 16位 (1字节8位)  转16进制后为4字节字符串
                // 0xA5F8  A5F8
                // char >> 0   15
                
                for var i:UInt32 = 0; i < 16; i+=4 {
                    let k = char >> (12 - i)
                    let c = UInt8(k & 0xF)
                    buffer.append(c + (c > 9 ? 55 : 48))
                }
            } else {
                buffer.append(UInt8(char))
            }
        }
        return buffer
    }
    
    // MARK: - 获取随机密钥
    static func getRandomKeyChars(length:Int) -> [UInt8] {
        var buffer = Array<UInt8>()
        
        for var i:Int = 0; i < length; i++ {
            let char = UInt8(arc4random() % 95 + 32)
            buffer.append(char)
        }
        return buffer
    }
    static func getRandomKey(length:Int) -> String {
        var buffer = getRandomKeyChars(length)
        return (NSString(bytes: &buffer, length: length, encoding: NSUTF8StringEncoding) ?? String(count: length, repeatedValue: UnicodeScalar(79))) as String
    }
    // 完成
}
