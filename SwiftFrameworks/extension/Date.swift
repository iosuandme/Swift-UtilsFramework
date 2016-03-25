//
//  Date.swift
//
//  Created by bujiandi(慧趣小歪) on 14/9/26.
//
//  值类型的 Date 使用方便 而且避免使用 @NSCopying 的麻烦
//  基本遵循了官方所有关于值类型的实用协议 放心使用
//

import Foundation

public struct Date : CustomStringConvertible, CustomDebugStringConvertible, Hashable, Equatable, Comparable ,ForwardIndexType {
    var timeInterval:NSTimeInterval = 0
    
    public init() { self.timeInterval = NSDate().timeIntervalSince1970 }
    public static var zeroDate:Date { return Date(0) }
    
    // MARK: - 构造函数
    public init(year:Int, month:Int = 1, day:Int = 1, hour:Int = 0, minute:Int = 0, second:Int = 0) {
        let comps = NSDateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        comps.hour = hour
        comps.minute = minute
        comps.second = second
        if let date = NSCalendar.currentCalendar().dateFromComponents(comps) {
            timeInterval = date.timeIntervalSince1970
        }
    }
    
    public init(_ v: UInt8) { timeInterval = Double(v) }
    public init(_ v: Int8) { timeInterval = Double(v) }
    public init(_ v: UInt16) { timeInterval = Double(v) }
    public init(_ v: Int16) { timeInterval = Double(v) }
    public init(_ v: UInt32) { timeInterval = Double(v) }
    public init(_ v: Int32) { timeInterval = Double(v) }
    public init(_ v: UInt64) { timeInterval = Double(v) }
    public init(_ v: Int64) { timeInterval = Double(v) }
    public init(_ v: UInt) { timeInterval = Double(v) }
    public init(_ v: Int) { timeInterval = Double(v) }
    
    public init(_ v: Float) { timeInterval = Double(v) }
    //init(_ v: Float80) { timeInterval = Double(v) }
    public init(_ v: NSTimeInterval) { timeInterval = v }
    
    public init(_ v: NSTimeInterval, sinceDate:Date) {
        let date = NSDate(timeIntervalSince1970: sinceDate.timeInterval)
        timeInterval = NSDate(timeInterval: v, sinceDate: date).timeIntervalSince1970
    }
    
    public init(sinceNow: NSTimeInterval) {
        timeInterval = NSDate(timeIntervalSinceNow: sinceNow).timeIntervalSince1970
    }
    
    public init(sinceReferenceDate: NSTimeInterval) {
        timeInterval = NSDate(timeIntervalSinceReferenceDate: sinceReferenceDate).timeIntervalSince1970
    }
    
    public init?(_ v: String, style: NSDateFormatterStyle) {
        let formatter = NSDateFormatter()
        formatter.dateStyle = style
        if let date = formatter.dateFromString(v) {
            self.timeInterval = date.timeIntervalSince1970
        } else {
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            if let date = formatter.dateFromString(v) {
                self.timeInterval = date.timeIntervalSince1970
            } else {
                return nil
                #if DEBUG
                    assert("日期字符串格式异常[\(v)] at line:\(#line) at column:\(#column)")//__FILE__,__FUNCTION__
                #endif
            }
        }
    }
    
    public init?(_ v: String, dateFormat:String = "yyyy-MM-dd HH:mm:ss") {
        let formatter = NSDateFormatter()
        formatter.dateFormat = dateFormat
        if let date = formatter.dateFromString(v) {
            self.timeInterval = date.timeIntervalSince1970
        } else {
            return nil

            #if DEBUG
                assert("日期字符串格式异常[\(v)] at line:\(#line) at column:\(#column)")//__FILE__,__FUNCTION__
            #endif
        }
    }
    
    // MARK: - 计算属性
    public var timeIntervalSinceReferenceDate: NSTimeInterval {
        return NSDate(timeIntervalSince1970: timeInterval).timeIntervalSinceReferenceDate
    }
    public var timeIntervalSinceNow: NSTimeInterval {
        return NSDate(timeIntervalSince1970: timeInterval).timeIntervalSinceNow
    }
    public var timeIntervalSince1970: NSTimeInterval { return timeInterval }
    
    // MARK: - 输出
    public func stringWithFormat(format:String = "yyyy-MM-dd HH:mm:ss") -> String {
        let formatter = NSDateFormatter()
        formatter.dateFormat = format
        return formatter.stringFromDate(NSDate(timeIntervalSince1970: timeInterval))
    }
    
    // MARK: - 计算
    public mutating func add(day day:Int) {
        timeInterval += Double(day) * 24 * 3600
    }
    public mutating func add(hour hour:Int) {
        timeInterval += Double(hour) * 3600
    }
    public mutating func add(minute minute:Int) {
        timeInterval += Double(minute) * 60
    }
    public mutating func add(second second:Int) {
        timeInterval += Double(second)
    }
    public mutating func add(month m:Int) {
        let date = NSDate(timeIntervalSince1970: timeInterval)
        let comps = NSCalendar.currentCalendar().components([.Year, .Month, .Day, .Hour, .Minute, .Second], fromDate: date)
        comps.month += m
        
        if let date = NSCalendar.currentCalendar().dateFromComponents(comps) {
            timeInterval = date.timeIntervalSince1970
        } else {
            timeInterval += Double(m) * 30 * 24 * 3600
        }
    }
    public mutating func add(year y:Int) {
        let date = NSDate(timeIntervalSince1970: timeInterval)
        let comps = NSCalendar.currentCalendar().components([.Year, .Month, .Day, .Hour, .Minute, .Second], fromDate: date)
        comps.year += y
        
        if let date = NSCalendar.currentCalendar().dateFromComponents(comps) {
            timeInterval = date.timeIntervalSince1970
        } else {
            timeInterval += Double(y) * 365 * 24 * 3600
        }
    }
    
    // MARK: - 判断(ForwardIndexType)
    public func between(begin:Date,_ over:Date) -> Bool {
        return (self >= begin && self <= over) || (self >= over && self <= begin)
    }
    
    public func between(range:Range<Date>) -> Bool {
        return self >= range.startIndex && self <= range.endIndex
    }
    
    public func successor() -> Date { return self + 1 }
    public func predecessor() -> Date { return self - 1 }
    
    // 闰年
    public var isBissextileYear:Bool {
        let (year, _, _) = getDay()
        return year % 4 == 0
    }
    // 闰月
    public var isFebruary:Bool {
        let (_, month, _) = getDay()
        return month == 2
    }
    
    // 更早的时间
    public func earlierDate(anotherDate: Date) -> Date { return min(self, anotherDate) }
    // 更晚的时间
    public func laterDate(anotherDate: Date) -> Date { return max(self, anotherDate) }
    
    // MARK: - 获取 日期 或 时间
    public var weekday:Int {
        let date = NSDate(timeIntervalSince1970: timeInterval)
        return NSCalendar.currentCalendar().components(.Weekday, fromDate: date).weekday
    }
    
    public func getDateComponents() -> NSDateComponents {
        let date = NSDate(timeIntervalSince1970: timeInterval)
        return NSCalendar.currentCalendar().components([.Year, .Month, .Day, .Hour, .Minute, .Second, .Weekday], fromDate: date)
    }
    
    // for example : let (year, month, day) = date.getDay()
    public func getDay() -> (year:Int, month:Int, day:Int) {
        let date = NSDate(timeIntervalSince1970: timeInterval)
        let comps = NSCalendar.currentCalendar().components([.Year, .Month, .Day], fromDate: date)
        return (comps.year, comps.month, comps.day)
    }
    
    // for example : let (hour, minute, second) = date.getTime()
    public func getTime() -> (hour:Int, minute:Int, second:Int) {
        let date = NSDate(timeIntervalSince1970: timeInterval)
        let comps = NSCalendar.currentCalendar().components([.Hour, .Minute, .Second], fromDate: date)
        return (comps.hour, comps.minute, comps.second)
    }
    
    // MARK: - 可以直接输出
    public var description: String {
        return NSDate(timeIntervalSince1970: timeInterval).description
    }
    public var debugDescription: String {
        return NSDate(timeIntervalSince1970: timeInterval).debugDescription
    }
    
//    // MARK: - 可反射(Reflectable)
//    public func getMirror() -> MirrorType {
//        return reflect(self)
//    }

//    public func getMirror() -> MirrorType {
//        return reflect(self)
//    }
    // MARK: - 可哈希(Hashable)
    public var hashValue: Int { return timeInterval.hashValue }
    
    // MARK: - 转日期
    public var object: NSDate { return NSDate(timeIntervalSince1970: timeInterval) }
    public init(_ v:NSDate) { self.timeInterval = v.timeIntervalSince1970 }
}

//// MARK: - 可反射(Reflectable)
extension Date : _Reflectable {
    public func _getMirror() -> _MirrorType {
        return _reflect(self)
    }
}

// MARK: - 可以用 == 或 != 对比
public func ==(lhs: Date, rhs: Date) -> Bool {
    return lhs.timeInterval == rhs.timeInterval
}

// MARK: - 可以用 > < >= <= 对比
public func <=(lhs: Date, rhs: Date) -> Bool {
    return lhs.timeInterval <= rhs.timeInterval
}
public func >=(lhs: Date, rhs: Date) -> Bool {
    return lhs.timeInterval >= rhs.timeInterval
}
public func >(lhs: Date, rhs: Date) -> Bool {
    return lhs.timeInterval > rhs.timeInterval
}
public func <(lhs: Date, rhs: Date) -> Bool {
    return lhs.timeInterval < rhs.timeInterval
}

// MARK: - 可以 + - 天、时、分、秒
public func +(lhs: Date, rhs: NSTimeInterval) -> Date {
    return Date(rhs, sinceDate:lhs)
}
public func -(lhs: Date, rhs: NSTimeInterval) -> Date {
    return Date(-rhs, sinceDate:lhs)
}
public func +(lhs: NSTimeInterval, rhs: Date) -> Date {
    return Date(lhs, sinceDate:rhs)
}
public func -(lhs: NSTimeInterval, rhs: Date) -> Date {
    return Date(-lhs, sinceDate:rhs)
}
public func +=(inout lhs: Date, rhs: NSTimeInterval) {
    return lhs = Date(rhs, sinceDate:lhs)
}
public func -=(inout lhs: Date, rhs: NSTimeInterval) {
    return lhs = Date(-rhs, sinceDate:lhs)
}

// MARK: - 可以获取时间差
public func -(lhs: Date, rhs: Date) -> NSTimeInterval {
    return lhs.timeInterval - rhs.timeInterval
}
public func -(lhs: NSDate, rhs: Date) -> NSTimeInterval {
    return lhs.timeIntervalSince1970 - rhs.timeInterval
}
public func -(lhs: Date, rhs: NSDate) -> NSTimeInterval {
    return lhs.timeInterval - rhs.timeIntervalSince1970
}
public func -(lhs: NSDate, rhs: NSDate) -> NSTimeInterval {
    return lhs.timeIntervalSince1970 - rhs.timeIntervalSince1970
}

// MARK: - NSDate可转换为值类型
extension NSDate {
    public var value:Date { return Date(timeIntervalSince1970) }
    public convenience init(_ v:Date) { self.init(timeIntervalSince1970: v.timeIntervalSince1970) }
}

/*

extension Date : Hashable {
}

extension Date : Equatable {
    
}

extension Date : Comparable {
    
}
*/

/*
// MARK: - 可以直接赋值整数

extension Date : IntegerLiteralConvertible {
public typealias IntegerLiteralType = Int64

static func __convertFromIntegerLiteral(value: Int64) -> Date {
return Date(Double(value))
}
}

extension Date : IntegerLiteralConvertible {
typealias IntegerLiteralType = Int64

static func convertFromIntegerLiteral(value: Int64) -> Date {
return Date(Double(value))
}
}

// MARK: - 可以直接赋值浮点数
extension Date : FloatLiteralConvertible {
typealias FloatLiteralType = Double
static func convertFromFloatLiteral(value: Double) -> Date {
return Date(value)
}
}
*/
/*
// 竟然报错提示各种继承,这类要大改
extension Date :StringLiteralConvertible {
static func convertFromStringLiteral(value: String) -> Date {
return Date(value)
}
static func convertFromExtendedGraphemeClusterLiteral(value: String) -> Date {
return Date(value)
}

}
*/

/*
// __conversion() 功能不再允许
extension Date {
func __conversion() -> NSDate { return NSDate(timeIntervalSince1970: timeInterval) }
func __conversion() -> Double { return timeInterval }
func __conversion() -> Int64 { return Int64(timeInterval) }
}
*/


// MARK: - 可以直接赋值日期
/*
protocol DateLiteralConvertible {
typealias DateLiteralType
class func convertFromDateLiteral(value: DateLiteralType) -> Self
}
typealias DateLiteralType = Date

extension Date : DateLiteralConvertible {
//typealias DateLiteralType = NSDate

static func convertFromDateLiteral(value: NSDate) -> Date {
return Date(value.timeIntervalSince1970)
}
}
*/
/*
extension NSDate : FloatLiteralConvertible {
public class func convertFromFloatLiteral(value: FloatLiteralType) -> Self {
return self(timeIntervalSince1970: value)
}
}
*/
/*
extension NSDate : DateLiteralConvertible {
class func convertFromDateLiteral(value: Date) -> Self {
return self(timeIntervalSince1970: value.timeInterval)
}
}
*/

