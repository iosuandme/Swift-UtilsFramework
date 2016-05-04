//
//  TreeType.swift
//  QuestionLib
//
//  Created by 慧趣小歪 on 16/4/29.
//  Copyright © 2016年 小分队. All rights reserved.
//

import Foundation


protocol TreeType {
    
    // 必须实现
    
    /// mast use weak
    var parent: Self? { get set }
    
    var childs:[Self] { get set }
    var isRoot: Bool  { get }
    
    // 已实现
    func enumerate(@noescape body: (Self) -> Void)
    mutating func setChilds(items:[Self], @noescape isChild: (parent:Self, child:Self) throws -> Bool) rethrows
    static func rootsFromList(items:[Self], @noescape isChild: (parent:Self, child:Self) throws -> Bool) rethrows -> [Self]
    var hasChild:Bool { get }
}

extension TreeType {
    
    static func rootsFromList(items:[Self], @noescape isChild: (parent:Self, child:Self) throws -> Bool) rethrows -> [Self] {
        var result:[Self] = []
        for var item in items {
            try item.setChilds(items, isChild: isChild)
            if item.isRoot { result.append(item) }
        }
        return result
    }
    
    mutating func setChilds(items:[Self], @noescape isChild: (parent:Self, child:Self) throws -> Bool) rethrows {
        childs.removeAll()
        for var item in items {
            if try isChild(parent: self, child: item) {
                childs.append(item)
                item.parent = self
            }
        }
    }
    
    func enumerate(@noescape body: (Self) -> Void) {
        body(self)
        childs.forEach { $0.enumerate(body) }
    }
    
    var hasChild:Bool { return childs.count > 0 }
}

extension CollectionType where Generator.Element : TreeType {
    
    func enumerate(body: (Generator.Element) -> Void) {
        forEach { $0.enumerate(body) }
    }
}
