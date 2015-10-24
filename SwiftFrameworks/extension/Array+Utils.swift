//
//  Array+Utils.swift
//
//  Created by bujiandi(慧趣小歪) on 14/10/4.
//

import Foundation

extension LazyMapCollection {
    // 用指定分隔符 连接 数组元素 为 字符串
    func componentsJoinedByString(separator: String) -> String {
        var result = ""
        for item:Element in self {
            if !result.isEmpty {
                result += separator
            }
            result += "\(item)"
        }
        return result
    }
}

extension Array {
    
    // 过滤符合条件的数组元素
    public func filter(includeElement: (Element) -> Bool) -> [Element] {
        var items:[Element] = []
        for item in self where includeElement(item) {
            items.append(item)
        }
        return items
    }
    
    // 用指定分隔符 连接 数组元素 为 字符串
    public func componentsJoinedByString(separator: String) -> String {
        var result = ""
        for item:Element in self {
            if !result.isEmpty {
                result += separator
            }
            result += "\(item)"
        }
        return result
    }
    
    //    // 利用闭包功能 给数组添加 包涵方法
    //    public func contains(includeElement: (Element) -> Bool) -> Bool {
    //        for item in self where includeElement(item) {
    //            return true
    //        }
    //        return false
    //    }
    
    // 利用闭包功能 给数组添加 查找首个符合条件元素 的 方法
    public func find(includeElement: (Element) -> Bool) -> Element? {
        for item in self where includeElement(item) {
            return item
        }
        return nil
    }
    
    // 利用闭包功能 给数组添加 查找首个符合条件元素下标 的 方法
    public func indexOf(includeElement: (Element) -> Bool) -> Int {
        for var i:Int = 0; i<count; i++ {
            if includeElement(self[i]) {
                return i
            }
        }
        return NSNotFound
    }
    
    // 利用闭包功能 获取数组元素某个属性值的数组
    public func valuesFor<U>(includeElement: (Element) -> U) -> [U] {
        var result:[U] = []
        for item:Element in self {
            result.append(includeElement(item))
        }
        return result
    }
    
    // 利用闭包功能 获取符合条件数组元素 相关内容的数组
    public func valuesFor<U>(includeElement: (Element) -> U?) -> [U] {
        var result:[U] = []
        for item:Element in self {
            if let u:U = includeElement(item) {
                result.append(u)
            }
        }
        return result
    }
    
}