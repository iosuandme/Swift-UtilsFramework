//
//  IntegerHexabled.swift
//
//  Created by 慧趣工作室 on 14/9/23.
//

import Foundation

protocol Hexabled {
    func toHex() -> String
    func strtoul(n:Self) -> String
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
}
