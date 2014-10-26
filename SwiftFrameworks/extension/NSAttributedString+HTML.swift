//
//  NSAttributedString+HTML.swift
//  ExamWinnerSwift
//
//  Created by 李招利 on 14/7/15.
//  Copyright (c) 2014年 长春金天宇文化传播有限公司. All rights reserved.
//

import UIKit

extension NSAttributedString {
    
    func boundingRectWithSize(size: CGSize, defaultFont:UIFont = UIFont.systemFontOfSize(16), lineBreakMode:NSLineBreakMode = .ByWordWrapping) -> CGSize {
        var label:UILabel = UILabel()
        label.lineBreakMode = lineBreakMode
        label.font = defaultFont
        label.numberOfLines = 0
        label.attributedText = self
        return label.sizeThatFits(size)
    }
    
    convenience init(HTML:String, defaultFontSize size:CGFloat, imageFactory:((imageURL:String) -> UIImage?)?) {
        let html:NSString = HTML
        let regular = NSRegularExpression(pattern: "<\\s*(/)?\\s*(\\w+)(.*?)(/)?\\s*>", options: NSRegularExpressionOptions.CaseInsensitive, error: nil)
        let matches = regular!.matchesInString(HTML, options: NSMatchingOptions(0), range: NSMakeRange(0, html.length))
        var elements:[NSAttributedStringHTML.HTMLElement] = []
        var tagStack:[NSAttributedStringHTML.HTMLElement] = []
        var content:String = ""
        
        var lastRange = NSMakeRange(0, 0)
        var lastLength:Int = 0
        for match :NSTextCheckingResult in matches as [NSTextCheckingResult] {
            // 获取非TAG部分
            let loaction = lastRange.location + lastRange.length
            let length = match.range.location - loaction;
            let tmp = html.substringWithRange(NSMakeRange(loaction, length))
            let (text,offset) = NSAttributedStringHTML.replaceSymbol(tmp)
            content += text //html.substringWithRange(NSMakeRange(loaction, length))
            lastRange = match.range;
            lastLength += length - offset;
            
            //解析TAG
            let tag = html.substringWithRange(match.rangeAtIndex(2)).uppercaseString
            
            if match.rangeAtIndex(1).location == NSNotFound {               //如果是TAG起始
                let attrs = html.substringWithRange(match.rangeAtIndex(3))
                var element = NSAttributedStringHTML.HTMLElement(tag: tag, attributesString: attrs)
                element.range = NSMakeRange(lastLength, 0)
                if match.rangeAtIndex(4).location != NSNotFound {           //如果TAB 以/>结束
                    elements.append(element)                                //<--加入结果集
                } else if tag == NSAttributedStringHTML.HTMLElementType.BR.name {   //如果 是<br>
                    elements.append(element)                                //<--加入结果集
                } else {
                    tagStack.append(element)                                //<--加入栈
                }
            } else if tagStack.count > 0 {                                  //如果是TAG结束
                var element = tagStack.removeLast()
                if tag.uppercaseString == element.type.name {
                    let loc = element.range.location
                    element.range = NSMakeRange(loc, lastLength - loc)
                    elements.append(element)
                } else {
                    tagStack.append(element)
                    println("抛弃不成对的标记\(html.substringWithRange(match.range))")
                }
            } else {
                println("抛弃不对称标记:\(html.substringWithRange(match.range))")
            }
            
        }
        //把所有标记后的内容加入文本
        let loaction = lastRange.location + lastRange.length
        if loaction < html.length {
            let length = html.length - loaction
            let (text,_) = NSAttributedStringHTML.replaceSymbol(html.substringWithRange(NSMakeRange(loaction, length)))
            content += text
        }
        
        var attrString = NSMutableAttributedString(string: content, attributes: [NSFontAttributeName:UIFont.systemFontOfSize(size)])
        while elements.count > 0 {
            let element = elements.removeAtIndex(0)
            let range = element.range
            
            switch element.type {
            case .P :
                attrString.addAttribute(NSParagraphStyleAttributeName, value: NSParagraphStyle(), range: range)
                attrString.replaceCharactersInRange(NSMakeRange(range.location, 0), withString: "\n")
                NSAttributedStringHTML.HTMLElement.changeElementOffset(1, withLoacaton: range.location, inElements: &elements)
                let tmplocation = range.location + range.length + 1
                attrString.replaceCharactersInRange(NSMakeRange(tmplocation, 0), withString: "\n\n")
                NSAttributedStringHTML.HTMLElement.changeElementOffset(2, withLoacaton: tmplocation, inElements: &elements)
            case .B :
                attrString.addAttribute(NSFontAttributeName, value: UIFont.boldSystemFontOfSize(size), range: range)
            case .I :
                attrString.addAttribute(NSFontAttributeName, value: UIFont.italicSystemFontOfSize(size), range: range)
            case .U :
                attrString.addAttribute(NSUnderlineStyleAttributeName, value: 1, range: range)
            case let .A (href, type, target) :
                attrString.addAttribute(NSLinkAttributeName, value: href, range: range)
            case .BR :
                attrString.replaceCharactersInRange(NSMakeRange(range.location, 0), withString: "\n")
                NSAttributedStringHTML.HTMLElement.changeElementOffset(1, withLoacaton: range.location, inElements: &elements)
            case .Hn (let htmlSize) :
                let fontSize = NSAttributedStringHTML.HTMLElement.HTMLSizeToFontSize(htmlSize)
                attrString.addAttributes([NSFontAttributeName:UIFont.boldSystemFontOfSize(fontSize),NSParagraphStyleAttributeName:NSParagraphStyle()], range: range)
                attrString.replaceCharactersInRange(NSMakeRange(range.location, 0), withString: "\n")
                NSAttributedStringHTML.HTMLElement.changeElementOffset(1, withLoacaton: range.location, inElements: &elements)
                let tmplocation = range.location + range.length + 1
                attrString.replaceCharactersInRange(NSMakeRange(tmplocation, 0), withString: "\n\n")
                NSAttributedStringHTML.HTMLElement.changeElementOffset(2, withLoacaton: tmplocation, inElements: &elements)
            case .LI :
                break
            case .SUB :
                attrString.addAttributes(["NSSuperScript":NSNumber(int: -1), NSFontAttributeName:UIFont.systemFontOfSize(9.0)], range: range)
            case .SUP :
                attrString.addAttributes(["NSSuperScript":NSNumber(int: 1), NSFontAttributeName:UIFont.systemFontOfSize(9.0)], range: range)
            case let .IMG(src, alt) :
                if let image = imageFactory?(imageURL: src) {                //如果能取到图片
                    var attachment = NSTextAttachment(data: nil, ofType: nil)
                    attachment.image = image
                    attrString.replaceCharactersInRange(range, withAttributedString: NSAttributedString(attachment: attachment))
                    NSAttributedStringHTML.HTMLElement.changeElementOffset(1-range.length, withLoacaton: range.location + 1, inElements: &elements)
                } else {                                                    //如果取不到图片
                    if let str:NSString = alt {
                        attrString.replaceCharactersInRange(NSMakeRange(range.location, 0), withString: alt)
                        NSAttributedStringHTML.HTMLElement.changeElementOffset(str.length, withLoacaton: range.location, inElements: &elements)
                    }
                }
            default :
                break
            }
        }//<-while结束
        //解析完成
        self.init(attributedString:attrString)
        
    }
}


// MARK: - HTML helper
class NSAttributedStringHTML {
    
    

//extension NSAttributedString {

    enum HTMLTarget : Int {
        case _Self
        case _Blank
        case _Parent
        case _Top
        
        static func fromString(target:String!) -> HTMLTarget {
            if let targetString = target?.lowercaseString {
                switch targetString {
                case "_self" :
                    return ._Self
                case "_blank" :
                    return ._Blank
                case "_parent" :
                    return ._Parent
                case "_top" :
                    return ._Top
                default :
                    return ._Self
                }
            }
            return ._Self
        }
    }
    
    enum HTMLElementType {
        case Undefine
        case P
        case B,I,U
        case A (String, String!, HTMLTarget) //(href,type,target)
        case BR
        case Hn (Int) //(size)
        case LI
        case SUB,SUP
        case IMG (String, String!) //(src,alt)
        
        //分辨TAG类型
        static func fromTag(tag:String, attributesString:String!) -> HTMLElementType {
            switch tag.uppercaseString {
            case "P" :
                return .P
            case "B" :
                return .B
            case "I" :
                return .I
            case "U" :
                return .U
            case "A" :
                let attrs = decodeAttributes(attributesString)
                if let href = attrs["href"] {
                    let type = attrs["type"]
                    let target = HTMLTarget.fromString(attrs["target"])
                    return .A (href, type, target)
                }
                return .Undefine
            case "BR" :
                return .BR
            case "H1","H2","H3","H4","H5","H6","H7" :
                let str:NSString = tag
                return .Hn (Int(str.characterAtIndex(1) - 48))
            case "LI" :
                return .LI
            case "SUB" :
                return .SUB
            case "SUP" :
                return .SUP
            case "IMG" :
                let attrs = decodeAttributes(attributesString)
                if let src = attrs["src"] {
                    let alt = attrs["alt"]
                    return .IMG (src, alt)
                }
                return .Undefine
            default :
                return .Undefine
            }
            
        }
        
        //解析TAG属性
        static func decodeAttributes(attributesString:String!) -> [String:String] {
            var result:[String:String] = [:]
            if let attrs:NSString = attributesString {
                let regular = NSRegularExpression(pattern: "\\s+(\\w+?)\\s*=\\s*['\"]?([^'\"]*)['\"\\s]?", options: NSRegularExpressionOptions.CaseInsensitive, error: nil)
                let matches = regular!.matchesInString(attributesString, options: NSMatchingOptions(0), range: NSMakeRange(0, attrs.length))
                for match :NSTextCheckingResult in matches as [NSTextCheckingResult] {
                    let key:String = attrs.substringWithRange(match.rangeAtIndex(1))
                    let value:String = attrs.substringWithRange(match.rangeAtIndex(2))
                    result[key.lowercaseString] = value
                }
            
            }
            
            return result
        }
        
        //TAG名字
        var name:String {
        switch self {
        case .P :               return "P"
        case .B :               return "B"
        case .I :               return "I"
        case .U :               return "U"
        case .A :               return "A"
        case .BR :              return "BR"
        case .Hn (let size) :   return "H\(size)"
        case .LI :              return "LI"
        case .SUB :             return "SUB"
        case .SUP :             return "SUP"
        case .IMG :             return "IMG"
        default :               return ""
            }
        }
    }
    
    
    
    struct HTMLElement {
        
        static func changeElementOffset(offset:Int, withLoacaton loaction:Int,inout inElements:[HTMLElement]) {
            for i in 0..<inElements.count {
                var range = inElements[i].range
                if range.location > loaction {
                    range.location += offset
                } else if range.location + range.length > loaction {
                    range.length += offset
                }
                inElements[i].range = range
            }
        }
        
        static func HTMLSizeToFontSize(size:Int) -> CGFloat {
            switch size {
            case 1: return 24.0;
            case 2: return 18.0;
            case 3: return 16.0;
            case 4: return 14.0;
            case 5: return 12.0;
            case 6: return 11.0;
            case 7: return 10.0;
            default: return 14.0;
            }
        }
        
        let type:HTMLElementType
        init(tag:String, attributesString:String!) {
            type = HTMLElementType.fromTag(tag, attributesString: attributesString)
        }
        var range:NSRange = NSMakeRange(NSNotFound, 0)
    }
    
    class func replaceSymbol(var content:String) -> (String,Int) {
        var offset = 0
        let str:NSMutableString = NSMutableString(string: content)
        let regular = NSRegularExpression(pattern: "&([#A-Za-z0-9]+?);", options: NSRegularExpressionOptions.CaseInsensitive, error: nil)
        let matches = regular!.matchesInString(content, options: NSMatchingOptions(0), range: NSMakeRange(0, str.length))
        //反序替换
        for i in reverse(0..<matches.count) {
            let match = matches[i] as NSTextCheckingResult
            let symbol = str.substringWithRange(match.rangeAtIndex(1))
                offset += match.range.length - 1
            switch symbol {
            case let x where x.hasPrefix("#"):
                if let num = x.substringFromIndex(advance(x.startIndex, 1)).toInt() {
                    let char = String(Character(UnicodeScalar(UInt32(num))))
                    str.replaceCharactersInRange(match.range, withString: char)
                } else {
                    offset -= match.range.length - 1
                }
            case "lt":
                str.replaceCharactersInRange(match.range, withString: "<")
            case "gt":
                str.replaceCharactersInRange(match.range, withString: ">")
            case "amp":
                str.replaceCharactersInRange(match.range, withString: "&")
            case "quot":
                str.replaceCharactersInRange(match.range, withString: "\"")
            case "reg": //已注册
                str.replaceCharactersInRange(match.range, withString: "®")
            case "copy":
                str.replaceCharactersInRange(match.range, withString: "©")
            case "times":
                str.replaceCharactersInRange(match.range, withString: "×")
            case "divide":
                str.replaceCharactersInRange(match.range, withString: "÷")
            case "yen":
                str.replaceCharactersInRange(match.range, withString: "¥")
            case "ordf":
                str.replaceCharactersInRange(match.range, withString: "ª")
            case "macr":
                str.replaceCharactersInRange(match.range, withString: "¯")
            case "acute":
                str.replaceCharactersInRange(match.range, withString: "´")
            case "sup1":
                str.replaceCharactersInRange(match.range, withString: "¹")
            case "sup2":
                str.replaceCharactersInRange(match.range, withString: "²")
            case "sup3":
                str.replaceCharactersInRange(match.range, withString: "³")
            case "frac12":
                str.replaceCharactersInRange(match.range, withString: "½")
            case "frac14":
                str.replaceCharactersInRange(match.range, withString: "¼")
            case "frac34":
                str.replaceCharactersInRange(match.range, withString: "¾")
            case "iexcl":
                str.replaceCharactersInRange(match.range, withString: "¡")
            case "cent":
                str.replaceCharactersInRange(match.range, withString: "¢")
            case "pound":
                str.replaceCharactersInRange(match.range, withString: "£")
            case "curren":
                str.replaceCharactersInRange(match.range, withString: "¤")
            case "brvbar":
                str.replaceCharactersInRange(match.range, withString: "¦")
            case "sect":
                str.replaceCharactersInRange(match.range, withString: "§")
            case "uml":
                str.replaceCharactersInRange(match.range, withString: "¨")
            case "laquo":
                str.replaceCharactersInRange(match.range, withString: "«")
            case "raquo":
                str.replaceCharactersInRange(match.range, withString: "»")
            case "not":
                str.replaceCharactersInRange(match.range, withString: "¬")
            case "deg":
                str.replaceCharactersInRange(match.range, withString: "°")
            case "plusmn":
                str.replaceCharactersInRange(match.range, withString: "±")
            case "micro":
                str.replaceCharactersInRange(match.range, withString: "µ")
            case "para":
                str.replaceCharactersInRange(match.range, withString: "¶")
            case "middot":
                str.replaceCharactersInRange(match.range, withString: "·")
            case "cedil":
                str.replaceCharactersInRange(match.range, withString: "¸")
            case "ordm":
                str.replaceCharactersInRange(match.range, withString: "º")
            case "iquest":
                str.replaceCharactersInRange(match.range, withString: "¿")
            case "frasl":
                str.replaceCharactersInRange(match.range, withString: "⁄")
            case "weierp":
                str.replaceCharactersInRange(match.range, withString: "℘")
            case "image":
                str.replaceCharactersInRange(match.range, withString: "ℑ")
            case "real":
                str.replaceCharactersInRange(match.range, withString: "ℜ")
            case "alefsym":
                str.replaceCharactersInRange(match.range, withString: "ℵ")
            case "lArr":
                str.replaceCharactersInRange(match.range, withString: "⇐")
            case "uArr":
                str.replaceCharactersInRange(match.range, withString: "⇑")
            case "rArr":
                str.replaceCharactersInRange(match.range, withString: "⇒")
            case "dArr":
                str.replaceCharactersInRange(match.range, withString: "⇓")
            case "hArr":
                str.replaceCharactersInRange(match.range, withString: "⇔")
            case "lang":
                str.replaceCharactersInRange(match.range, withString: "〈")
            case "rang":
                str.replaceCharactersInRange(match.range, withString: "〉")
                //以下HTML支持的数学符号
            case "forall":
                str.replaceCharactersInRange(match.range, withString: "∀")
            case "part":
                str.replaceCharactersInRange(match.range, withString: "∂")
            case "exists":
                str.replaceCharactersInRange(match.range, withString: "∃")
            case "empty":
                str.replaceCharactersInRange(match.range, withString: "∅")
            case "nabla":
                str.replaceCharactersInRange(match.range, withString: "∇")
            case "isin":
                str.replaceCharactersInRange(match.range, withString: "∈")
            case "notin":
                str.replaceCharactersInRange(match.range, withString: "∉")
            case "ni":
                str.replaceCharactersInRange(match.range, withString: "∋")
            case "prod":
                str.replaceCharactersInRange(match.range, withString: "∏")
            case "sum":
                str.replaceCharactersInRange(match.range, withString: "∑")
            case "minus":
                str.replaceCharactersInRange(match.range, withString: "−")
            case "lowast":
                str.replaceCharactersInRange(match.range, withString: "∗")
            case "radic":
                str.replaceCharactersInRange(match.range, withString: "√")
            case "prop":
                str.replaceCharactersInRange(match.range, withString: "∝")
            case "infin":
                str.replaceCharactersInRange(match.range, withString: "∞")
            case "ang":
                str.replaceCharactersInRange(match.range, withString: "∠")
            case "and":
                str.replaceCharactersInRange(match.range, withString: "∧")
            case "or":
                str.replaceCharactersInRange(match.range, withString: "∨")
            case "cap":
                str.replaceCharactersInRange(match.range, withString: "∩")
            case "cup":
                str.replaceCharactersInRange(match.range, withString: "∪")
            case "int":
                str.replaceCharactersInRange(match.range, withString: "∫")
            case "there4":
                str.replaceCharactersInRange(match.range, withString: "∴")
            case "sim":
                str.replaceCharactersInRange(match.range, withString: "∼")
            case "cong":
                str.replaceCharactersInRange(match.range, withString: "≅")
            case "asymp":
                str.replaceCharactersInRange(match.range, withString: "≈")
            case "ne":
                str.replaceCharactersInRange(match.range, withString: "≠")
            case "equiv":
                str.replaceCharactersInRange(match.range, withString: "≡")
            case "le":
                str.replaceCharactersInRange(match.range, withString: "≤")
            case "ge":
                str.replaceCharactersInRange(match.range, withString: "≥")
            case "sub":
                str.replaceCharactersInRange(match.range, withString: "⊂")
            case "sup":
                str.replaceCharactersInRange(match.range, withString: "⊃")
            case "nsub":
                str.replaceCharactersInRange(match.range, withString: "⊄")
            case "sube":
                str.replaceCharactersInRange(match.range, withString: "⊆")
            case "supe":
                str.replaceCharactersInRange(match.range, withString: "⊇")
            case "oplus":
                str.replaceCharactersInRange(match.range, withString: "⊕")
            case "otimes":
                str.replaceCharactersInRange(match.range, withString: "⊗")
            case "perp":
                str.replaceCharactersInRange(match.range, withString: "⊥")
            case "sdot":
                str.replaceCharactersInRange(match.range, withString: "⋅")
                //以下HTML支持的其他符号
            case "OElig":
                str.replaceCharactersInRange(match.range, withString: "Œ")
            case "oelig":
                str.replaceCharactersInRange(match.range, withString: "œ")
            case "Scaron":
                str.replaceCharactersInRange(match.range, withString: "Š")
            case "scaron":
                str.replaceCharactersInRange(match.range, withString: "š")
            case "Yuml":
                str.replaceCharactersInRange(match.range, withString: "Ÿ")
            case "fnof":
                str.replaceCharactersInRange(match.range, withString: "ƒ")
            case "circ":
                str.replaceCharactersInRange(match.range, withString: "ˆ")
            case "tilde":
                str.replaceCharactersInRange(match.range, withString: "˜")
            case "ensp":
                str.replaceCharactersInRange(match.range, withString: " ")
            case "nbsp":
                str.replaceCharactersInRange(match.range, withString: " ")
            case "emsp":
                str.replaceCharactersInRange(match.range, withString: " ")
            case "thinsp":
                str.replaceCharactersInRange(match.range, withString: " ")
            case "ndash":
                str.replaceCharactersInRange(match.range, withString: "–")
            case "mdash":
                str.replaceCharactersInRange(match.range, withString: "—")
            case "lsquo":
                str.replaceCharactersInRange(match.range, withString: "‘")
            case "rsquo":
                str.replaceCharactersInRange(match.range, withString: "’")
            case "sbquo":
                str.replaceCharactersInRange(match.range, withString: "‚")
            case "ldquo":
                str.replaceCharactersInRange(match.range, withString: "“")
            case "rdquo":
                str.replaceCharactersInRange(match.range, withString: "”")
            case "bdquo":
                str.replaceCharactersInRange(match.range, withString: "„")
            case "dagger":
                str.replaceCharactersInRange(match.range, withString: "†")
            case "Dagger":
                str.replaceCharactersInRange(match.range, withString: "‡")
            case "bull":
                str.replaceCharactersInRange(match.range, withString: "•")
            case "hellip":
                str.replaceCharactersInRange(match.range, withString: "…")
            case "permil":
                str.replaceCharactersInRange(match.range, withString: "‰")
            case "prime":
                str.replaceCharactersInRange(match.range, withString: "′")
            case "Prime":
                str.replaceCharactersInRange(match.range, withString: "″")
            case "lsaquo":
                str.replaceCharactersInRange(match.range, withString: "‹")
            case "rsaquo":
                str.replaceCharactersInRange(match.range, withString: "›")
            case "oline":
                str.replaceCharactersInRange(match.range, withString: "‾")
            case "euro":
                str.replaceCharactersInRange(match.range, withString: "€")
            case "trade":
                str.replaceCharactersInRange(match.range, withString: "™")
            case "larr":
                str.replaceCharactersInRange(match.range, withString: "←")
            case "uarr":
                str.replaceCharactersInRange(match.range, withString: "↑")
            case "rarr":
                str.replaceCharactersInRange(match.range, withString: "→")
            case "darr":
                str.replaceCharactersInRange(match.range, withString: "↓")
            case "harr":
                str.replaceCharactersInRange(match.range, withString: "↔")
            case "crarr":
                str.replaceCharactersInRange(match.range, withString: "↵")
            case "lceil":
                str.replaceCharactersInRange(match.range, withString: "⌈")
            case "rceil":
                str.replaceCharactersInRange(match.range, withString: "⌉")
            case "lfloor":
                str.replaceCharactersInRange(match.range, withString: "⌊")
            case "rfloor":
                str.replaceCharactersInRange(match.range, withString: "⌋")
            case "loz":
                str.replaceCharactersInRange(match.range, withString: "◊")
            case "spades":
                str.replaceCharactersInRange(match.range, withString: "♠")
            case "clubs":
                str.replaceCharactersInRange(match.range, withString: "♣")
            case "hearts":
                str.replaceCharactersInRange(match.range, withString: "♥")
            case "diams":
                str.replaceCharactersInRange(match.range, withString: "♦")
                //以下HTML支持的希腊字母
            case "Alpha":
                str.replaceCharactersInRange(match.range, withString: "Α")
            case "Beta":
                str.replaceCharactersInRange(match.range, withString: "Β")
            case "Gamma":
                str.replaceCharactersInRange(match.range, withString: "Γ")
            case "Delta":
                str.replaceCharactersInRange(match.range, withString: "Δ")
            case "Epsilon":
                str.replaceCharactersInRange(match.range, withString: "Ε")
            case "Zeta":
                str.replaceCharactersInRange(match.range, withString: "Ζ")
            case "Eta":
                str.replaceCharactersInRange(match.range, withString: "Η")
            case "Theta":
                str.replaceCharactersInRange(match.range, withString: "Θ")
            case "Iota":
                str.replaceCharactersInRange(match.range, withString: "Ι")
            case "Kappa":
                str.replaceCharactersInRange(match.range, withString: "Κ")
            case "Lambda":
                str.replaceCharactersInRange(match.range, withString: "Λ")
            case "Mu":
                str.replaceCharactersInRange(match.range, withString: "Μ")
            case "Nu":
                str.replaceCharactersInRange(match.range, withString: "Ν")
            case "Xi":
                str.replaceCharactersInRange(match.range, withString: "Ξ")
            case "Omicron":
                str.replaceCharactersInRange(match.range, withString: "Ο")
            case "Pi":
                str.replaceCharactersInRange(match.range, withString: "Π")
            case "Rho":
                str.replaceCharactersInRange(match.range, withString: "Ρ")
            case "Sigma":
                str.replaceCharactersInRange(match.range, withString: "Σ")
            case "Tau":
                str.replaceCharactersInRange(match.range, withString: "Τ")
            case "Upsilon":
                str.replaceCharactersInRange(match.range, withString: "Υ")
            case "Phi":
                str.replaceCharactersInRange(match.range, withString: "Φ")
            case "Chi":
                str.replaceCharactersInRange(match.range, withString: "Χ")
            case "Psi":
                str.replaceCharactersInRange(match.range, withString: "Ψ")
            case "Omega":
                str.replaceCharactersInRange(match.range, withString: "Ω")
            case "alpha":
                str.replaceCharactersInRange(match.range, withString: "α")
            case "beta":
                str.replaceCharactersInRange(match.range, withString: "β")
            case "gamma":
                str.replaceCharactersInRange(match.range, withString: "γ")
            case "delta":
                str.replaceCharactersInRange(match.range, withString: "δ")
            case "epsilon":
                str.replaceCharactersInRange(match.range, withString: "ε")
            case "zeta":
                str.replaceCharactersInRange(match.range, withString: "ζ")
            case "eta":
                str.replaceCharactersInRange(match.range, withString: "η")
            case "theta":
                str.replaceCharactersInRange(match.range, withString: "θ")
            case "iota":
                str.replaceCharactersInRange(match.range, withString: "ι")
            case "kappa":
                str.replaceCharactersInRange(match.range, withString: "κ")
            case "lambda":
                str.replaceCharactersInRange(match.range, withString: "λ")
            case "mu":
                str.replaceCharactersInRange(match.range, withString: "μ")
            case "nu":
                str.replaceCharactersInRange(match.range, withString: "ν")
            case "xi":
                str.replaceCharactersInRange(match.range, withString: "ξ")
            case "omicron":
                str.replaceCharactersInRange(match.range, withString: "ο")
            case "pi":
                str.replaceCharactersInRange(match.range, withString: "π")
            case "rho":
                str.replaceCharactersInRange(match.range, withString: "ρ")
            case "sigmaf":
                str.replaceCharactersInRange(match.range, withString: "ς")
            case "sigma":
                str.replaceCharactersInRange(match.range, withString: "σ")
            case "tau":
                str.replaceCharactersInRange(match.range, withString: "τ")
            case "upsilon":
                str.replaceCharactersInRange(match.range, withString: "υ")
            case "phi":
                str.replaceCharactersInRange(match.range, withString: "φ")
            case "chi":
                str.replaceCharactersInRange(match.range, withString: "χ")
            case "psi":
                str.replaceCharactersInRange(match.range, withString: "ψ")
            case "omega":
                str.replaceCharactersInRange(match.range, withString: "ω")
            case "thetasym":
                str.replaceCharactersInRange(match.range, withString: "ϑ")
            case "upsih":
                str.replaceCharactersInRange(match.range, withString: "ϒ")
            case "piv":
                str.replaceCharactersInRange(match.range, withString: "ϖ")
                
                //其他符号
            case "Agrave":
                str.replaceCharactersInRange(match.range, withString: "À")
            case "Aacute":
                str.replaceCharactersInRange(match.range, withString: "Á")
            case "Acirc":
                str.replaceCharactersInRange(match.range, withString: "Â")
            case "Atilde":
                str.replaceCharactersInRange(match.range, withString: "Ã")
            case "Auml":
                str.replaceCharactersInRange(match.range, withString: "Ä")
            case "Aring":
                str.replaceCharactersInRange(match.range, withString: "Å")
            case "AElig":
                str.replaceCharactersInRange(match.range, withString: "Æ")
            case "Ccedil":
                str.replaceCharactersInRange(match.range, withString: "Ç")
            case "Egrave":
                str.replaceCharactersInRange(match.range, withString: "È")
            case "Eacute":
                str.replaceCharactersInRange(match.range, withString: "É")
            case "Ecirc":
                str.replaceCharactersInRange(match.range, withString: "Ê")
            case "Euml":
                str.replaceCharactersInRange(match.range, withString: "Ë")
            case "Igrave":
                str.replaceCharactersInRange(match.range, withString: "Ì")
            case "Iacute":
                str.replaceCharactersInRange(match.range, withString: "Í")
            case "Icirc":
                str.replaceCharactersInRange(match.range, withString: "Î")
            case "Iuml":
                str.replaceCharactersInRange(match.range, withString: "Ï")
            case "ETH":
                str.replaceCharactersInRange(match.range, withString: "Ð")
            case "Ntilde":
                str.replaceCharactersInRange(match.range, withString: "Ñ")
            case "Ograve":
                str.replaceCharactersInRange(match.range, withString: "Ò")
            case "Oacute":
                str.replaceCharactersInRange(match.range, withString: "Ó")
            case "Ocirc":
                str.replaceCharactersInRange(match.range, withString: "Ô")
            case "Otilde":
                str.replaceCharactersInRange(match.range, withString: "Õ")
            case "Ouml":
                str.replaceCharactersInRange(match.range, withString: "Ö")
            case "Oslash":
                str.replaceCharactersInRange(match.range, withString: "Ø")
            case "Ugrave":
                str.replaceCharactersInRange(match.range, withString: "Ù")
            case "Uacute":
                str.replaceCharactersInRange(match.range, withString: "Ú")
            case "Ucirc":
                str.replaceCharactersInRange(match.range, withString: "Û")
            case "Uuml":
                str.replaceCharactersInRange(match.range, withString: "Ü")
            case "Yacute":
                str.replaceCharactersInRange(match.range, withString: "Ý")
            case "THORN":
                str.replaceCharactersInRange(match.range, withString: "Þ")
            case "szlig":
                str.replaceCharactersInRange(match.range, withString: "ß")
            case "agrave":
                str.replaceCharactersInRange(match.range, withString: "à")
            case "aacute":
                str.replaceCharactersInRange(match.range, withString: "á")
            case "acirc":
                str.replaceCharactersInRange(match.range, withString: "â")
            case "atilde":
                str.replaceCharactersInRange(match.range, withString: "ã")
            case "auml":
                str.replaceCharactersInRange(match.range, withString: "ä")
            case "aring":
                str.replaceCharactersInRange(match.range, withString: "å")
            case "aelig":
                str.replaceCharactersInRange(match.range, withString: "æ")
            case "ccedil":
                str.replaceCharactersInRange(match.range, withString: "ç")
            case "egrave":
                str.replaceCharactersInRange(match.range, withString: "è")
            case "eacute":
                str.replaceCharactersInRange(match.range, withString: "é")
            case "ecirc":
                str.replaceCharactersInRange(match.range, withString: "ê")
            case "euml":
                str.replaceCharactersInRange(match.range, withString: "ë")
            case "igrave":
                str.replaceCharactersInRange(match.range, withString: "ì")
            case "iacute":
                str.replaceCharactersInRange(match.range, withString: "í")
            case "icirc":
                str.replaceCharactersInRange(match.range, withString: "î")
            case "iuml":
                str.replaceCharactersInRange(match.range, withString: "ï")
            case "eth":
                str.replaceCharactersInRange(match.range, withString: "ð")
            case "ntilde":
                str.replaceCharactersInRange(match.range, withString: "ñ")
            case "ograve":
                str.replaceCharactersInRange(match.range, withString: "ò")
            case "oacute":
                str.replaceCharactersInRange(match.range, withString: "ó")
            case "ocirc":
                str.replaceCharactersInRange(match.range, withString: "ô")
            case "otilde":
                str.replaceCharactersInRange(match.range, withString: "õ")
            case "ouml":
                str.replaceCharactersInRange(match.range, withString: "ö")
            case "oslash":
                str.replaceCharactersInRange(match.range, withString: "ø")
            case "ugrave":
                str.replaceCharactersInRange(match.range, withString: "ù")
            case "uacute":
                str.replaceCharactersInRange(match.range, withString: "ú")
            case "ucirc":
                str.replaceCharactersInRange(match.range, withString: "û")
            case "uuml":
                str.replaceCharactersInRange(match.range, withString: "ü")
            case "yacute":
                str.replaceCharactersInRange(match.range, withString: "ý")
            case "thorn":
                str.replaceCharactersInRange(match.range, withString: "þ")
            case "yuml":
                str.replaceCharactersInRange(match.range, withString: "ÿ")
            default :
                offset -= match.range.length - 1
                break
            }
            //
        }
        return (str,offset)
    }

}