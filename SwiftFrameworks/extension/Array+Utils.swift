//
//  Array+Utils.swift
//
//  Created by bujiandi(慧趣小歪) on 14/10/4.
//

import Foundation

extension Array {
    
    func find(includeElement: (T) -> Bool) -> T? {
        for item in self {
            if includeElement(item) {
                return item
            }
        }
        return nil
    }
    
    func indexOf(includeElement: (T) -> Bool) -> Int {
        for var i:Int = 0; i<count; i++ {
            if includeElement(self[i]) {
                return i
            }
        }
        return NSNotFound
    }
    
    func componentsJoinedByString(separator:String) -> String {
        var result = ""
        for item:T in self {
            if !result.isEmpty {
                result += separator
            }
            result += "\(item)"
        }
        return result
    }
}