//
//  IntegerHexabled.swift
//
//  Created by 慧趣工作室 on 14/9/23.
//

import Foundation

protocol Hexabled {
    func toHex() -> String
    func strtoul(n:Self) -> String
    func toChinese() -> String
}

func chineseInt(var code:Int64) -> String {
    let units:[Character] = [" ","十","百","千","万","十","百","千","亿","十","百","千","万"]
    let nums:[Character] = ["零","一","二","三","四","五","六","七","八","九"]
    
    var unit = 0
    var buffer:[Character] = []
    var deleteZero = false
    do {
        let i = Int(code % 10)
        code = code / 10
        unit++
        if i > 0 {
            if unit > 1 {
                buffer.append(units[unit-1])
            }
            if i == 1 && code == 0 && unit % 4 == 2 {
                //println(unit)
            } else {
                buffer.append(nums[i])
            }
            deleteZero = false
        } else {
            if unit == 5 {
                buffer.append("万")
                deleteZero = true
            }
            if unit == 9 {
                buffer.append("亿")
                deleteZero = true
            }
            if buffer.last != "零" && buffer.count > 0 && !deleteZero {
                buffer.append("零")
            }
        }
    } while code > 0
    
    return String(reverse(buffer))
}

extension Int : Hexabled {
    func toHex() -> String {
        return strtoul(16)
    }
    func strtoul(n:Int) -> String {
        var buffer:[Character] = []
        var num = self
        do {
            let i = num & (n - 1)
            let unicode = UInt32(i + (i > 9 ? 55 : 48))
            buffer.append(Character(UnicodeScalar(unicode)))
            num >>= 4
        } while num > 0
        return String(reverse(buffer))
    }
    func toChinese() -> String { return chineseInt(Int64(self)) }
}

extension UInt : Hexabled {
    func toHex() -> String {
        return strtoul(16)
    }
    func strtoul(n:UInt) -> String {
        var buffer:[Character] = []
        var num = self
        do {
            let i = num & (n - 1)
            let unicode = UInt32(i + (i > 9 ? 55 : 48))
            buffer.append(Character(UnicodeScalar(unicode)))
            num >>= 4
        } while num > 0
        return String(reverse(buffer))
    }
    func toChinese() -> String { return chineseInt(Int64(self)) }
}

extension Int8 : Hexabled{
    func toHex() -> String {
        return strtoul(16)
    }
    func strtoul(n:Int8) -> String {
        var buffer:[Character] = []
        var num = self
        do {
            let i = num & (n - 1)
            let unicode = UInt32(i + (i > 9 ? 55 : 48))
            buffer.append(Character(UnicodeScalar(unicode)))
            num >>= 4
        } while num > 0
        return String(reverse(buffer))
    }
    func toChinese() -> String { return chineseInt(Int64(self)) }
}

extension UInt8 : Hexabled{
    func toHex() -> String {
        return strtoul(16)
    }
    func strtoul(n:UInt8) -> String {
        var buffer:[Character] = []
        var num = self
        do {
            let i = num & (n - 1)
            let unicode = UInt32(i + (i > 9 ? 55 : 48))
            buffer.append(Character(UnicodeScalar(unicode)))
            num >>= 4
        } while num > 0
        return String(reverse(buffer))
    }
    func toChinese() -> String { return chineseInt(Int64(self)) }
}

extension Int16 : Hexabled{
    func toHex() -> String {
        return strtoul(16)
    }
    func strtoul(n:Int16) -> String {
        var buffer:[Character] = []
        var num = self
        do {
            let i = num & (n - 1)
            let unicode = UInt32(i + (i > 9 ? 55 : 48))
            buffer.append(Character(UnicodeScalar(unicode)))
            num >>= 4
        } while num > 0
        return String(reverse(buffer))
    }
    func toChinese() -> String { return chineseInt(Int64(self)) }
}

extension UInt16 : Hexabled{
    func toHex() -> String {
        return strtoul(16)
    }
    func strtoul(n:UInt16) -> String {
        var buffer:[Character] = []
        var num = self
        do {
            let i = num & (n - 1)
            let unicode = UInt32(i + (i > 9 ? 55 : 48))
            buffer.append(Character(UnicodeScalar(unicode)))
            num >>= 4
        } while num > 0
        return String(reverse(buffer))
    }
    func toChinese() -> String { return chineseInt(Int64(self)) }
}

extension Int32 : Hexabled{
    func toHex() -> String {
        return strtoul(16)
    }
    func strtoul(n:Int32) -> String {
        var buffer:[Character] = []
        var num = self
        do {
            let i = num & (n - 1)
            let unicode = UInt32(i + (i > 9 ? 55 : 48))
            buffer.append(Character(UnicodeScalar(unicode)))
            num >>= 4
        } while num > 0
        return String(reverse(buffer))
    }
    func toChinese() -> String { return chineseInt(Int64(self)) }
}

extension UInt32 : Hexabled{
    func toHex() -> String {
        return strtoul(16)
    }
    func strtoul(n:UInt32) -> String {
        var buffer:[Character] = []
        var num = self
        do {
            let i = num & (n - 1)
            let unicode = UInt32(i + (i > 9 ? 55 : 48))
            buffer.append(Character(UnicodeScalar(unicode)))
            num >>= 4
        } while num > 0
        return String(reverse(buffer))
    }
    func toChinese() -> String { return chineseInt(Int64(self)) }
}

extension Int64 : Hexabled{
    func toHex() -> String {
        return strtoul(16)
    }
    func strtoul(n:Int64) -> String {
        var buffer:[Character] = []
        var num = self
        do {
            let i = num & (n - 1)
            let unicode = UInt32(i + (i > 9 ? 55 : 48))
            buffer.append(Character(UnicodeScalar(unicode)))
            num >>= 4
        } while num > 0
        return String(reverse(buffer))
    }
    func toChinese() -> String { return chineseInt(Int64(self)) }
}

extension UInt64 : Hexabled{
    func toHex() -> String {
        return strtoul(16)
    }
    func strtoul(n:UInt64) -> String {
        var buffer:[Character] = []
        var num = self
        do {
            let i = num & (n - 1)
            let unicode = UInt32(i + (i > 9 ? 55 : 48))
            buffer.append(Character(UnicodeScalar(unicode)))
            num >>= 4
        } while num > 0
        return String(reverse(buffer))
    }
    func toChinese() -> String { return chineseInt(Int64(self)) }
}
