//
//  Array+Utils.swift
//
//  Created by bujiandi(慧趣小歪) on 14/10/4.
//

import Foundation

extension Array {
    func indexOf(includeElement: (T) -> Bool) -> Int {
        for i in 0..<count {
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