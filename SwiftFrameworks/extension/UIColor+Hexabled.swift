//
//  UIColor+Hexabled.swift
//  ExamWinnerSwift
//
//  Created by 李招利 on 14/10/30.
//  Copyright (c) 2014年 Jintianyu Culture Communication Co., Ltd. All rights reserved.
//
#if os (iOS)
import UIKit
#elseif os (OSX)
import AppKit
#endif

#if os (iOS)

extension UIColor {
    convenience init(hex:String) {
        let regular = NSRegularExpression(pattern: "(#?|0x)[0-9a-fA-F]{2,}", options: NSRegularExpressionOptions.CaseInsensitive, error: nil)
        let length = distance(hex.startIndex, hex.endIndex)
        if let result = regular!.firstMatchInString(hex, options: NSMatchingOptions(0), range: NSMakeRange(0, length)) {
            let start = advance(hex.startIndex, result.rangeAtIndex(1).length + result.rangeAtIndex(1).location)
            let end = advance(hex.startIndex, result.range.length + result.range.location)
            let length = distance(start, end)
            let number = strtoul(hex[start..<end], nil, 16)
            let b = (number >> 0) & 0xFF
            let g = (number >> 8) & 0xFF
            let r = (number >> 16) & 0xFF
            let a = distance(start, end) > 6 ? (number >> 24) & 0xFF : 255
            
            self.init(red: CGFloat(r)/255, green: CGFloat(g)/255, blue:CGFloat(b)/255 , alpha: CGFloat(a)/255)
            return
        }
        self.init()
    }
    convenience init(number:UInt32) {
        let b = (number >> 0) & 0xFF
        let g = (number >> 8) & 0xFF
        let r = (number >> 16) & 0xFF
        let a = number > 0xFFFFFF ? (number >> 24) & 0xFF : 255
        self.init(red: CGFloat(r)/255, green: CGFloat(g)/255, blue:CGFloat(b)/255 , alpha: CGFloat(a)/255)
    }
}

#elseif os (OSX)
extension NSColor {
    convenience init(hex:String) {
        let regular = NSRegularExpression(pattern: "(#?|0x)[0-9a-fA-F]{2,}", options: NSRegularExpressionOptions.CaseInsensitive, error: nil)
        let length = distance(hex.startIndex, hex.endIndex)
        if let result = regular!.firstMatchInString(hex, options: NSMatchingOptions(0), range: NSMakeRange(0, length)) {
            let start = advance(hex.startIndex, result.rangeAtIndex(1).length + result.rangeAtIndex(1).location)
            let end = advance(hex.startIndex, result.range.length + result.range.location)
            let length = distance(start, end)
            let number = strtoul(hex[start..<end], nil, 16)
            let b = (number >> 0) & 0xFF
            let g = (number >> 8) & 0xFF
            let r = (number >> 16) & 0xFF
            let a = distance(start, end) > 6 ? (number >> 24) & 0xFF : 255
            
            self.init(red: CGFloat(r)/255, green: CGFloat(g)/255, blue:CGFloat(b)/255 , alpha: CGFloat(a)/255)
            return
        }
        self.init()
    }
    
    convenience init(number:UInt32) {
        let b = (number >> 0) & 0xFF
        let g = (number >> 8) & 0xFF
        let r = (number >> 16) & 0xFF
        let a = number > 0xFFFFFF ? (number >> 24) & 0xFF : 255
    
        self.init(red: CGFloat(r)/255, green: CGFloat(g)/255, blue:CGFloat(b)/255 , alpha: CGFloat(a)/255)
    }
}
#endif
