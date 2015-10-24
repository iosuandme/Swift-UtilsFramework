//
//  NSMutableAttributedString+trim.swift
//  
//
//  Created by C Lau on 15/8/4.
//
//

import UIKit

/// trim 去掉字符串两段的换行与空格
extension NSMutableAttributedString {
    public enum TrimMode : Int {
        case Both
        case Prefix
        case Suffix
    }
    
    public func trim(mode:TrimMode = .Both) {
        var start:Int = 0
        switch mode {
        case .Both:
            self.trim(.Prefix)
            self.trim(.Suffix)
//            return self.trim(.Prefix).trim(.Suffix)
        case .Prefix:
            for char:Character in self.string.characters {
                switch char {
                case " ", "\n", "\r", "\r\n", "\t":   // \r\n 是一个字符  \n\r 是2个字符
                    start++
                default:
                    replaceCharactersInRange(NSMakeRange(0, start), withString: "") //substringFromIndex(start)
                    return
                }
            }
        case .Suffix:
            let chars = (self.string).characters.reverse()
            for char:Character in chars {
                switch char {
                case " ", "\n", "\r", "\r\n", "\t":   // \r\n 是一个字符  \n\r 是2个字符
                    start++
                default:
                    if start > 0 {
                    replaceCharactersInRange(NSMakeRange(chars.count - start, start), withString: "") //substringToIndex(chars.count - start)
                    }
                    return
                }
            }
        }
    }
}