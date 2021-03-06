//
//  Array+Utils.swift
//
//  Created by bujiandi(慧趣小歪) on 14/10/4.
//

import Foundation

//extension DictionaryLiteral {
//    // 用指定分隔符 连接 数组元素 为 字符串
//    public func componentsJoinedByString(separator:String, includeElement:(Generator.Element) -> String) -> String {
//        var result:String = ""
//        for item:Generator.Element in self {
//            if !result.isEmpty { result += separator }
//            result += includeElement(item)
//        }
//        return result
//    }
//}
extension Int {
    func times(_ function: (Int) -> Void) {
        for i in 0 ..< self { function(i) }
    }
}

extension Collection {
    
    // 用指定分隔符 连接 数组元素 为 字符串
//    public func componentsJoinedByString(separator:String, includeElement:(Generator.Element) -> String = { "\($0)" }) -> String {
//        var result:String = ""
//        for item:Self.Generator.Element in self {
//            if !result.isEmpty { result += separator }
//            result += includeElement(item)
//        }
//        return result
//    }
    
    
    /*  
     *  遍历数组中的元素并加入下标索引 例如:
     *  for (i, item) in array.indexItems {
     *      print(i, item)
     *  }
     */
//    public var indexItems:AnyGenerator<(Int, Generator.Element)> {
//        var i = 0
//        var generator = generate()
//        return AnyGenerator {
//            if let next = generator.next() {
//                defer { i += 1 }
//                return (i, next)
//            }
//            return nil
//        }
//    }
    
    /*
     *  系统中本来就有 例如:
     *  for (i, item) in array.enumerate() {
     *      print(i, item)
     *  }
     */
    
    public func set<T:Hashable>(_ includeElement: (Iterator.Element) -> T) -> Set<T> {
        var set = Set<T>()
        for item:Self.Iterator.Element in self {
            set.insert(includeElement(item))
        }
        return set
    }
    
    public func joined(separator:String, includeElement:(Iterator.Element) -> String = { "\($0)" }) -> String {
        var result:String = ""
        for item:Self.Iterator.Element in self {
            if !result.isEmpty { result += separator }
            result += includeElement(item)
        }
        return result
    }
    
    // 利用闭包功能 给数组添加 查找首个符合条件元素 的 方法
    public func find(_ includeElement: (Self.Iterator.Element) -> Bool) -> Self.Iterator.Element? {
        for item in self where includeElement(item) {
            return item
        }
        return nil
    }
    
    
}
