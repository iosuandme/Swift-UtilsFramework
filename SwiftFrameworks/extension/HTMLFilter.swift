//
//  HTMLFilter.swift
//  ExamReader
//
//  Created by C Lau on 15/5/7.
//  Copyright (c) 2015年 C Lau. All rights reserved.
//

import UIKit

class HTMLFilter {
   
    static func filter(HTML:String) -> String {
        let html:NSMutableString = NSMutableString(string: HTML)
        
//        var regular = NSRegularExpression(pattern: "<\\!--[\\S|\\s]*?-->", options: NSRegularExpressionOptions.CaseInsensitive, error: nil)
        
        do {
            var regular = try NSRegularExpression(pattern: "<\\!--[\\S|\\s]*?-->", options: NSRegularExpressionOptions.CaseInsensitive)
            regular.replaceMatchesInString(html, options: NSMatchingOptions(rawValue: 0), range: NSMakeRange(0, html.length), withTemplate: "")
            do {
                regular = try NSRegularExpression(pattern: "<[^>]+>", options: NSRegularExpressionOptions.CaseInsensitive)
                regular.replaceMatchesInString(html, options: NSMatchingOptions(rawValue: 0), range: NSMakeRange(0, html.length), withTemplate: "")
            } catch {
            
            }
            


        } catch {
            
        }
        
        
        return html as String
/*
        let matches = regular!.matchesInString(HTML, options: NSMatchingOptions(0), range: NSMakeRange(0, html.length))
        var elements:[NSAttributedStringHTML.HTMLElement] = []
        var tagStack:[NSAttributedStringHTML.HTMLElement] = []
        var content:String = ""
        
        var lastRange = NSMakeRange(0, 0)
        var lastLength:Int = 0
        for match :NSTextCheckingResult in matches as! [NSTextCheckingResult] {
            // 获取非TAG部分
            let loaction = lastRange.location + lastRange.length
            let length = match.range.location - loaction;
            let tmp = html.substringWithRange(NSMakeRange(loaction, length))
            let (text,offset) = NSAttributedStringHTML.replaceSymbol(tmp)
            content += text //html.substringWithRange(NSMakeRange(loaction, length))
            lastRange = match.range;
            lastLength += length - offset;
            
        }
        
        //把所有标记后的内容加入文本
        let loaction = lastRange.location + lastRange.length
        if loaction < html.length {
            let length = html.length - loaction
            let (text,_) = NSAttributedStringHTML.replaceSymbol(html.substringWithRange(NSMakeRange(loaction, length)))
            content += text
        }
        return content
*/
    }
}
