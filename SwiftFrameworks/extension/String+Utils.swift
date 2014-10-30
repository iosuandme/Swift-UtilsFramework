//
//  String+Utils.swift
//
//  Created by bujiandi(慧趣小歪) on 14/8/6.
//

import Foundation

extension String {
    
    // MARK: - 取类型名
    static func typeNameFromClass(aClass:AnyClass) -> String {
        let name = NSStringFromClass(aClass)
        let demangleName = _stdlib_demangleName(name)
        return demangleName.componentsSeparatedByString(".").last!
    }
    
    static func typeNameFromAny(thing:Any) -> String {
        let name = _stdlib_getTypeName(thing)
        let demangleName = _stdlib_demangleName(name)
        return demangleName.componentsSeparatedByString(".").last!
    }
    
    // MARK: - 取大小
    func boundingRectWithSize(size: CGSize, defaultFont:UIFont = UIFont.systemFontOfSize(16), lineBreakMode:NSLineBreakMode = .ByWordWrapping) -> CGSize {
        var label:UILabel = UILabel()
        label.lineBreakMode = lineBreakMode
        label.font = defaultFont
        label.numberOfLines = 0
        label.text = self
        return label.sizeThatFits(size)
    }
    
    // MARK: - 取路径末尾文件名
    var stringByDeletingPathPrefix:String {
        return self.componentsSeparatedByString("/").last!
    }
    // MARK: - 长度
    var length:Int {
        return distance(startIndex, endIndex)
    }
    
    // MARK: - 字符串截取
    func substringToIndex(index:Int) -> String {
        return self.substringToIndex(advance(self.startIndex, index))
    }
    func substringFromIndex(index:Int) -> String {
        return self.substringFromIndex(advance(self.startIndex, index))
    }
    func substringWithRange(range:Range<Int>) -> String {
        let start = advance(self.startIndex, range.startIndex)
        let end = advance(self.startIndex, range.endIndex)
        return self.substringWithRange(start..<end)
    }
    
    subscript(index:Int) -> Character{
        return self[advance(self.startIndex, index)]
    }
    
    subscript(subRange:Range<Int>) -> String {
        return self[advance(self.startIndex, subRange.startIndex)..<advance(self.startIndex, subRange.endIndex)]
    }
    
    // MARK: - 字符串修改 RangeReplaceableCollectionType
    mutating func insert(newElement: Character, atIndex i: Int) {
        insert(newElement, atIndex: advance(self.startIndex,i))
    }

    mutating func splice(newValues: String, atIndex i: Int) {
        splice(newValues, atIndex: advance(self.startIndex,i))
    }
    
    mutating func replaceRange(subRange: Range<Int>, with newValues: String) {
        let start = advance(self.startIndex, subRange.startIndex)
        let end = advance(self.startIndex, subRange.endIndex)
        replaceRange(start..<end, with: newValues)
    }
    
    mutating func removeAtIndex(i: Int) -> Character {
        return removeAtIndex(advance(self.startIndex,i))
    }
    
    mutating func removeRange(subRange: Range<Int>) {
        let start = advance(self.startIndex, subRange.startIndex)
        let end = advance(self.startIndex, subRange.endIndex)
        removeRange(start..<end)
    }

    // MARK: - 字符串拆分
    func separatedByString(separator: String) -> [String] {
        let str:NSString = self
        return str.componentsSeparatedByString(separator) as [String]
    }
    func separatedByCharacters(separators: String) -> [String] {
        let str:NSString = self
        return str.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: separators)) as [String]
    }
    
    // MARK: - URL解码/编码
    func decodeURL() -> String! {
        let str:NSString = self
        return str.stringByReplacingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
    }
    
    func encodeURL() -> String {
        let originalString:CFStringRef = self as NSString
        let charactersToBeEscaped = "!*'();:@&=+$,/?%#[]" as CFStringRef  //":/?&=;+!@#$()',*"    //转意符号
        //let charactersToLeaveUnescaped = "[]." as CFStringRef  //保留的符号
        let result =
        CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
            originalString,
            nil,    //charactersToLeaveUnescaped,
            charactersToBeEscaped,
            CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)) as NSString
        
        return result
    }

}

extension String.UnicodeScalarView {
    subscript (i: Int) -> UnicodeScalar {
        return self[advance(self.startIndex, i)]
    }
}

func trimPrefix(text:String) -> String {
    var start:Int = 0
    for char:Character in text {
        switch char {
        case "\n", " ", "\r":
            start++
        default:
            return text.substringFromIndex(start)
        }
    }
    return ""
}
func trimSuffix(text:String) -> String {
    var start:Int = 0
    let chars = reverse(text)
    for char:Character in chars {
        switch char {
        case "\n", " ", "\r":
            start++
        default:
            return text.substringToIndex(chars.count - start)
        }
    }
    return ""
}
func trim(text:String) -> String {
    return trimSuffix(trimPrefix(text))
}

/*
extension NSURL: StringLiteralConvertible {
    public class func convertFromExtendedGraphemeClusterLiteral(value: String) -> Self {
        return self(string: value)
    }
    
    public class func convertFromStringLiteral(value: String) -> Self {
        return self(string: value)
    }
}
*/