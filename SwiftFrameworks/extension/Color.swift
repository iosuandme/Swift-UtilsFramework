//
//  Color.swift
//  QuestionLib
//
//  Created by 慧趣小歪 on 16/4/8.
//  Copyright © 2016年 小分队. All rights reserved.
//
import Foundation
import CoreGraphics
#if os (iOS)
import UIKit
#elseif os (OSX)
import Cocoa
#endif

public struct Color: RawRepresentable {
    
    // MARK: - RawRepresentable
    public typealias RawValue = UInt32
    
    private var _rawValue:RawValue = 0
    public init(rawValue: RawValue) {
        _rawValue = rawValue > 0xFFFFFF ? rawValue : rawValue | 0xFF000000
    }
    public var rawValue: RawValue { return _rawValue }
    
    // MARK: - RGB
    var red:  UInt32 { return (_rawValue >> 16) & 0xFF }
    var green:UInt32 { return (_rawValue >>  8) & 0xFF }
    var blue: UInt32 { return (_rawValue >>  0) & 0xFF }
    var alpha:CGFloat {
        get { return CGFloat((_rawValue >> 24) & 0xFF) / 0xFF }
        set { _rawValue = UInt32(min(newValue, 1.0) * 0xFF) << 24 | (_rawValue & 0xFFFFFF)}
    }
    
    // MARK: - Dark and light
    func lightColorWith(ratio:CGFloat) -> Color {
        let a = _rawValue & 0xFF000000
        var r:CGFloat = 1 - CGFloat((_rawValue >> 16) & 0xFF) / 0xFF
        var g:CGFloat = 1 - CGFloat((_rawValue >>  8) & 0xFF) / 0xFF
        var b:CGFloat = 1 - CGFloat((_rawValue >>  0) & 0xFF) / 0xFF
        
        r = 1.0 - r * r * min(ratio, 1.0)
        g = 1.0 - g * g * min(ratio, 1.0)
        b = 1.0 - b * b * min(ratio, 1.0)
        
        return Color(rawValue: a | (UInt32(r * 0xFF) << 16) | (UInt32(g * 0xFF) << 8) | UInt32(b * 0xFF))
    }

    func darkColorWith(ratio:CGFloat) -> Color {
        
        let a = _rawValue & 0xFF000000
        var r:CGFloat = CGFloat((_rawValue >> 16) & 0xFF) / 0xFF
        var g:CGFloat = CGFloat((_rawValue >>  8) & 0xFF) / 0xFF
        var b:CGFloat = CGFloat((_rawValue >>  0) & 0xFF) / 0xFF
        
        r = r * r * min(ratio, 1.0)
        g = g * g * min(ratio, 1.0)
        b = b * b * min(ratio, 1.0)

        return Color(rawValue: a | (UInt32(r * 0xFF) << 16) | (UInt32(g * 0xFF) << 8) | UInt32(b * 0xFF))
    }
    var darkColor:Color { return darkColorWith(0.7) }
    var lightColor:Color { return lightColorWith(0.7) }

}

extension Color {
#if os (iOS)
    public var uiColor:UIColor {
        return UIColor(number: _rawValue)
    }
#elseif os (OSX)
    public var nsColor:NSColor {
        return NSColor(number: _rawValue)
    }
#endif
}

#if os (iOS)
    extension UIColor {
        var valueColor:Color {
            var r:CGFloat = 0
            var g:CGFloat = 0
            var b:CGFloat = 0
            var a:CGFloat = 0
            getRed(&r, green: &g, blue: &b, alpha: &a)
            var value:UInt32 = 0
            value = value | UInt32(a * 0xFF) << 24
            value = value | UInt32(r * 0xFF) << 16
            value = value | UInt32(g * 0xFF) << 8
            value = value | UInt32(b * 0xFF)
            return Color(rawValue: value)
        }
    }
#elseif os (OSX)
    extension NSColor {
        
    }
#endif