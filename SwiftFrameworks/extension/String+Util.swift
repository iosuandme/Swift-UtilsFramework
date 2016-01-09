
#if os(iOS)
import UIKit
#elseif os(OSX)
import Foundation
#endif

extension String {
    
    
//    // create a static method to get a swift class for a string name
//    public class func swiftClassFromString(className: String) -> AnyClass! {
//        // get the project name
//        if  var appName: String = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleName") as? String {
//            // generate the full name of your class (take a look into your "YourProject-swift.h" file)
//            let classStringName = "_TtC\(appName.utf16count)\(appName)\(className.length)\(className)"
//            // return the class!
//            return NSClassFromString(classStringName)
//        }
//        return nil
//    }
    // MARK: - 取类型名
    public static func typeNameFromClass(aClass:AnyClass) -> String {
        let name = NSStringFromClass(aClass)
        let demangleName = _stdlib_demangleName(name)
        return demangleName.componentsSeparatedByString(".").last!
    }

//    static func typeNameFromAny(thing:Any) -> String {
//        let name = _stdlib_getTypeName(thing)
//        let demangleName = _stdlib_demangleName(name)
//        return demangleName.componentsSeparatedByString(".").last!
//    }
    
    // MARK: - 取大小
    #if os(iOS)
//    func boundingRectWithSize(size: CGSize, defaultFont:UIFont = UIFont.systemFontOfSize(16), lineBreakMode:NSLineBreakMode = .ByWordWrapping) -> CGSize {
//        var label:UILabel = UILabel()
//        label.lineBreakMode = lineBreakMode
//        label.font = defaultFont
//        label.numberOfLines = 0
//        label.text = self
//        return label.sizeThatFits(size)
//    }
    #endif
    
    // MARK: - 取路径末尾文件名
    public var stringByDeletingPathPrefix:String {
        return self.componentsSeparatedByString("/").last!
    }
    // MARK: - 长度
    public var length:Int {
        return self.startIndex.distanceTo(endIndex) //distance(startIndex, endIndex)
    }
    
    // MARK: - 字符串截取
    public func substringToIndex(index:Int) -> String {
        return self.substringToIndex(self.startIndex.advancedBy(index)) // advance(self.startIndex, index))
    }
    public func substringFromIndex(index:Int) -> String {
        return self.substringFromIndex(self.startIndex.advancedBy(index)) //advance(self.startIndex, index))
    }
    public func substringWithRange(range:Range<Int>) -> String {
        let start = startIndex.advancedBy(range.startIndex) //advance(self.startIndex, range.startIndex)
        let end = startIndex.advancedBy(range.endIndex) //advance(self.startIndex, range.endIndex)
        return self.substringWithRange(start..<end)
    }
    
    public subscript(index:Int) -> Character{
        return self[self.startIndex.advancedBy(index)] //advance(self.startIndex, index)]
    }
    
    public subscript(subRange:Range<Int>) -> String {
        return self[self.startIndex.advancedBy(subRange.startIndex)..<self.startIndex.advancedBy(subRange.endIndex)]
        //return self[advance(self.startIndex, subRange.startIndex)..<advance(self.startIndex, subRange.endIndex)]
    }
    
    // MARK: - 字符串修改 RangeReplaceableCollectionType
    public mutating func insert(newElement: Character, atIndex i: Int) {
        insert(newElement, atIndex: startIndex.advancedBy(i)) //advance(self.startIndex,i))
    }
    
//    public mutating func splice<S : CollectionType where S.Generator.Element == Character>(newElements: S, atIndex i:Int) {
//        splice(newElements, atIndex: startIndex.advancedBy(i)) //advance(self.startIndex,i))
//    }
    
    public mutating func replaceRange(subRange: Range<Int>, with newValues: String) {
        let start = startIndex.advancedBy(subRange.startIndex) //advance(self.startIndex, range.startIndex)
        let end = startIndex.advancedBy(subRange.endIndex) //advance(self.startIndex, range.endIndex)
        replaceRange(start..<end, with: newValues)
    }
    
    public mutating func removeAtIndex(i: Int) -> Character {
        return removeAtIndex(startIndex.advancedBy(i)) //advance(self.startIndex,i))
    }
    
    public mutating func removeRange(subRange: Range<Int>) {
        let start = startIndex.advancedBy(subRange.startIndex) //advance(self.startIndex, range.startIndex)
        let end = startIndex.advancedBy(subRange.endIndex) //advance(self.startIndex, range.endIndex)
        removeRange(start..<end)
    }
    
    // MARK: - 字符串拆分
    public func splitByString(separator: String) -> [String] {
        return self.componentsSeparatedByString(separator)
    }
    public func splitByCharacters(separators: String) -> [String] {
        return self.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: separators))
    }
    
    // MARK: - URL解码/编码
    
    /// 给URL解编码
    public func decodeURL() -> String! {
        //let str:NSString = self
        //return str.stringByReplacingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        return self.stringByRemovingPercentEncoding
    }
    
    /// 给URL编码
    public func encodeURL() -> String {
        let originalString:CFStringRef = self as NSString
        let charactersToBeEscaped = "!*'();:@&=+$,/?%#[]" as CFStringRef  //":/?&=;+!@#$()',*"    //转意符号
        //let charactersToLeaveUnescaped = "[]." as CFStringRef  //保留的符号
        let result =
        CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
            originalString,
            nil,    //charactersToLeaveUnescaped,
            charactersToBeEscaped,
            CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)) as NSString
        
        return result as String
    }
    
}

extension String.UnicodeScalarView {
    public subscript (i: Int) -> UnicodeScalar {
        return self[startIndex.advancedBy(i)] //advance(self.startIndex, i)]
    }
}


/// trim 去掉字符串两段的换行与空格
extension String {
    public enum TrimMode : Int {
        case Both
        case Prefix
        case Suffix
    }
    
    public func trim(mode:TrimMode = .Both) -> String {
        var start:Int = 0
        switch mode {
        case .Both:
            return self.trim(.Prefix).trim(.Suffix)
        case .Prefix:
            for char:Character in characters {
                switch char {
                case " ", "\n", "\r", "\r\n", "\t":   // \r\n 是一个字符  \n\r 是2个字符
                    start++
                default:
                    return substringFromIndex(start)
                }
            }
        case .Suffix:
            let chars = characters.reverse()
            for char:Character in chars {
                switch char {
                case " ", "\n", "\r", "\r\n", "\t":   // \r\n 是一个字符  \n\r 是2个字符
                    start++
                default:
                    return substringToIndex(chars.count - start)
                }
            }
        }
        return ""
    }
    
    public func joinIn(prefix:String, _ suffix:String) -> String {
        return "\(prefix)\(self)\(suffix)"
    }
    
    public var isNumeric:Bool {
        return matchRegular(try! NSRegularExpression(pattern: "[0-9]+\\.?[0-9]*", options: NSRegularExpressionOptions.CaseInsensitive))
    }
    
    public var isInteger:Bool {
        return matchRegular(try! NSRegularExpression(pattern: "[0-9]+", options: NSRegularExpressionOptions.CaseInsensitive))
    }
    
    public func matchRegular(regular:NSRegularExpression) -> Bool {
        let length = characters.count
        let range = regular.rangeOfFirstMatchInString(self, options: NSMatchingOptions(rawValue: 0), range: NSMakeRange(0, length))
        return range.location == 0 && range.length == length
    }
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