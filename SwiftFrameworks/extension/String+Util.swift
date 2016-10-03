
#if os(iOS)
import UIKit
#elseif os(OSX)
import Foundation
#endif

let EmptyString = ""
extension String {
    
    
//    // create a static method to get a swift class for a string name
    public static func swiftClassFromString(_ className: String) -> AnyClass! {
        // get the project name
        if  let appName: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String {
            // generate the full name of your class (take a look into your "YourProject-swift.h" file)
            let classStringName = "_TtC\(appName.utf16.count)\(appName)\(className.length)\(className)"
            // return the class!
            return NSClassFromString(classStringName)
        }
        return nil
    }
    // MARK: - 取类型名
//    public static func typeNameFromClass(_ aClass:AnyClass) -> String {
//        let name = NSStringFromClass(aClass)
//        let demangleName = _stdlib_demangleName(name)
//        return demangleName.components(separatedBy: ".").last!
//    }
    
//    public init(_ items: Any...) {
//        let string = items.map({ "\($0)" }).joinWithSeparator(", ")
//        self.init(string)
//    }

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
    func boundingRectWithSize(size: CGSize, defaultFont:UIFont = UIFont.systemFontOfSize(16), lineBreakMode:NSLineBreakMode = .ByWordWrapping) -> CGSize {
    
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineBreakMode = lineBreakMode
    return (self as NSString).boundingRectWithSize(size, options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: [NSFontAttributeName:defaultFont, NSParagraphStyleAttributeName:paragraphStyle], context: nil).size
    
    }
    
    // MARK: - 快捷生成富文本
    public func attributedStringBy(attributes: [String : AnyObject]?) -> NSAttributedString {
        return NSAttributedString(string: self, attributes: attributes)
    }

    #endif
    // MARK: - 取路径末尾文件名
    public var stringByDeletingPathPrefix:String {
        return self.components(separatedBy: "/").last!
    }
    // MARK: - 长度
    public var length:Int {
        return self.characters.distance(from: self.startIndex, to: endIndex) //distance(startIndex, endIndex)
    }
    
    // MARK: - 字符串截取
    public func substringToIndex(_ index:Int) -> String {
        return self.substring(to: self.characters.index(self.startIndex, offsetBy: index)) // advance(self.startIndex, index))
    }
    public func substringFromIndex(_ index:Int) -> String {
        return self.substring(from: self.characters.index(self.startIndex, offsetBy: index)) //advance(self.startIndex, index))
    }
    public func substringWithRange(_ range:Range<Int>) -> String {
        let start = characters.index(startIndex, offsetBy: range.lowerBound) //advance(self.startIndex, range.startIndex)
        let end = characters.index(startIndex, offsetBy: range.upperBound) //advance(self.startIndex, range.endIndex)
        return self.substring(with: start..<end)
    }
    
    public subscript(index:Int) -> Character{
        return self[self.characters.index(self.startIndex, offsetBy: index)] //advance(self.startIndex, index)]
    }
    
    public subscript(subRange:Range<Int>) -> String {
        return self[self.characters.index(self.startIndex, offsetBy: subRange.lowerBound)..<self.characters.index(self.startIndex, offsetBy: subRange.upperBound)]
    }
    
    // MARK: - 字符串修改 RangeReplaceableCollectionType
    public mutating func insert(_ newElement: Character, atIndex i: Int) {
        insert(newElement, at: index(startIndex, offsetBy: i)) //advance(self.startIndex,i))
    }
    
    public mutating func replaceRange(_ subRange: Range<Int>, with newValues: String) {
        let start = index(startIndex, offsetBy: subRange.lowerBound) //advance(self.startIndex, range.startIndex)
        let end = index(startIndex, offsetBy: subRange.upperBound) //advance(self.startIndex, range.endIndex)
        replaceSubrange(start..<end, with: newValues)
    }
    
    public mutating func removeAtIndex(_ i: Int) -> Character {
        return remove(at: index(startIndex, offsetBy: i)) //advance(self.startIndex,i))
    }
    
    public mutating func removeRange(_ subRange: Range<Int>) {
        let start = index(startIndex, offsetBy: subRange.lowerBound) //advance(self.startIndex, range.startIndex)
        let end = index(startIndex, offsetBy: subRange.upperBound) //advance(self.startIndex, range.endIndex)
        removeSubrange(start..<end)
    }
    
    // MARK: - 字符串拆分
    public func splitByString(_ separator: String) -> [String] {
        return self.components(separatedBy: separator)
    }
    public func splitByCharacters(_ separators: String) -> [String] {
        return self.components(separatedBy: CharacterSet(charactersIn: separators))
    }
    
    // MARK: - URL解码/编码
    
    /// 给URL解编码
    public func decodeURL() -> String! {
        //let str:NSString = self
        //return str.stringByReplacingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        return removingPercentEncoding
    }
    
    /// 给URL编码
    public func encodeURL() -> String {
        let originalString:CFString = self as NSString
        let charactersToBeEscaped = "!*'();:@&=+$,/?%#[]" as CFString  //":/?&=;+!@#$()',*"    //转意符号
        //let charactersToLeaveUnescaped = "[]." as CFStringRef  //保留的符号
        let result =
        CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
            originalString,
            nil,    //charactersToLeaveUnescaped,
            charactersToBeEscaped,
            CFStringConvertNSStringEncodingToEncoding(String.Encoding.utf8.rawValue)) as NSString
        
        return result as String
    }
    
}

extension String.UnicodeScalarView {
    public subscript (i: Int) -> UnicodeScalar {
        return self[index(startIndex, offsetBy: i)] //advance(self.startIndex, i)]
    }
}


/// trim 去掉字符串两段的换行与空格
extension String {
    public enum TrimMode : Int {
        case both
        case prefix
        case suffix
    }
    
    public func trim(_ mode:TrimMode = .both) -> String {
        var start:Int = 0
        switch mode {
        case .both:
            return self.trim(.prefix).trim(.suffix)
        case .prefix:
            for char:Character in characters {
                switch char {
                case " ", "\n", "\r", "\r\n", "\t":   // \r\n 是一个字符  \n\r 是2个字符
                    start += 1
                default:
                    return substringFromIndex(start)
                }
            }
        case .suffix:
            let chars = characters.reversed()
            for char:Character in chars {
                switch char {
                case " ", "\n", "\r", "\r\n", "\t":   // \r\n 是一个字符  \n\r 是2个字符
                    start += 1
                default:
                    return substringToIndex(chars.count - start)
                }
            }
        }
        return ""
    }
    
    public func joinIn(_ prefix:String, _ suffix:String) -> String {
        return "\(prefix)\(self)\(suffix)"
    }
    
    public var isNumeric:Bool {
        return matchRegular(try! NSRegularExpression(pattern: "[0-9]+\\.?[0-9]*", options: NSRegularExpression.Options.caseInsensitive))
    }
    
    public var isInteger:Bool {
        return matchRegular(try! NSRegularExpression(pattern: "[0-9]+", options: NSRegularExpression.Options.caseInsensitive))
    }
    
    public func matchRegular(_ regular:NSRegularExpression) -> Bool {
        let length = characters.distance(from: startIndex, to: endIndex) //characters.count
        let range = regular.rangeOfFirstMatch(in: self, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, length))
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
