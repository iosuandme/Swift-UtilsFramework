//
//  main.swift
//  SwiftFrameworks
//
//  Created by 李招利 on 14/9/11.
//  Copyright (c) 2014年 慧趣工作室. All rights reserved.
//

import Foundation


class CPU :NSObject, SQLiteTableClass {
    
    var cpu_id:Int
    var cpu_firm:String
    
    init(id:Int, firm:String) {
        self.cpu_firm = firm
        self.cpu_id = id
    }
    
    class func tableColumnTypeWithProperty(propertyName: String) -> (SQLite.ColumnType, SQLite.ColumnState)? {
        switch propertyName {
        case "cpu_id":      return (.INTEGER,       .PrimaryKeyAutoincrement)
        case "cpu_firm":    return (.VARCHAR(30),   .NotNull)
        default :           return nil
        }
    }
    
}

class Computer :NSObject, SQLiteTableClass {
    
    var computer_id:Int
    var computer_brand:String
    
    var cpu_id:Int
    
    init(id:Int, brand:String, cpu:Int) {
        self.computer_id = id
        self.computer_brand = brand
        self.cpu_id = cpu
    }
    class func tableColumnTypeWithProperty(propertyName: String) -> (SQLite.ColumnType, SQLite.ColumnState)? {
        switch propertyName {
        case "computer_id":     return (.INTEGER,       .PrimaryKeyAutoincrement)
        case "computer_brand":  return (.VARCHAR(30),   .NotNull)
        case "cpu_id":          return (.INTEGER,       .NotNull)
        default :               return nil
        }
    }
}

class Person : NSObject, SQLiteTableClass {
    
    var person_id:Int
    var person_name:String
    
    var computer_id:Int
    
    
    init(id:Int, name:String, computer:Int) {
        self.person_id = id
        self.person_name = name
        self.computer_id = computer
    }
    class func tableColumnTypeWithProperty(propertyName: String) -> (SQLite.ColumnType, SQLite.ColumnState)? {
        switch propertyName {
        case "person_id":   return (.INTEGER,       .PrimaryKeyAutoincrement)
        case "person_name": return (.VARCHAR(30),   .NotNull)
        case "computer_id": return (.INTEGER,       .NotNull)
        default :           return nil
        }
    }
}

class SQLiteDelegateObject:NSObject, SQLiteDelegate, SQLiteLogDelegate {
    func onCreate(handle:COpaquePointer, db:SQLite) {     //<-需要创建所有的表
        /*
        // 通过元组创建表
        sqlite.create(handle, tableIfNotExists: "CPU", params: [
        ("cpu_id", .INTxEGER, .PrimaryKeyAutoincrement),
        ("cpu_firm", .VARCHAR(30), .Default)
        ])
        sqlite.create(handle, tableIfNotExists: "Computer", params: [
        ("computer_id", .INTEGER, .PrimaryKeyAutoincrement),
        ("computer_brand", .VARCHAR(30), .NotNull),
        ("cpu_id", .INTEGER, .NotNull)
        ])
        sqlite.create(handle, tableIfNotExists: "Person", params: [
        ("person_id", .INTEGER, .PrimaryKeyAutoincrement),
        ("person_name", .VARCHAR(30), .NotNull),
        ("computer_id", .INTEGER, .NotNull)
        ])
        */
        println("onCreate")
        
        db.create(handle, tableIfNotExists: "CPU", withClass: CPU.self)
        db.create(handle, tableIfNotExists: "Computer", withClass: Computer.self)
        db.create(handle, tableIfNotExists: "Person", withClass: Person.self)
        
        // 创建索引
        db.create(handle, index: "indexCPU", on: "CPU", columns: "cpu_id")
        db.create(handle, index: "indexComputer", on: "Computer", columns: "computer_id")
        
        //插入cpu数据 方式1 参数组
        db.insert(handle, into: "CPU", values: 1, "Intel")
        db.insert(handle, into: "CPU", values: 2, "AMD")
        
        db.beginTransaction(handle)
        //插入电脑数据 方式2 通过对象数组(批量)
        db.insert(handle, into: "Computer", datas: [Computer(id: 1, brand: "IBM", cpu: 1)])
        
        //插入电脑数据 方式3 通过字典(单条)
        db.insert(handle, tableName: "Computer", params: [
            "cpu_id":2,"computer_brand":"HP"])
        db.commitTransaction(handle)
        
        //插入电脑数据 方式4 通过枚举(单条)
        db.insert(handle, tableName: "Computer", params: [
            .SQL_Int("cpu_id", 1),
            .SQL_String("computer_brand", "Apple")])
        
        //插入使用者数据 方式5 通过回掉闭包(批量)
        let peoples:[(String,Int)] = [
            ("李明",1),
            ("张三",2),
            ("王五",1),
            ("马六",3)
        ]
        db.insert(handle, tableName: "Person", columnNames: ["person_name","computer_id"]) {
            (index) -> [SQLite.ColumnValue]? in
            if index < peoples.count {
                let (name,id) = peoples[index]
                let columns:[SQLite.ColumnValue] = [
                    .SQL_String("person_name",name),
                    .SQL_Int("computer_id",id)
                ]
                return columns
            } else {
                return nil
            }
        }
        
        
        
    }
    
    func logError(error:NSError) {
        println("error->\(error.localizedDescription)")
    }
    
    func logSQL(log:String) {
        println(log)
    }
    func onUpgrade(handle: COpaquePointer, db: SQLite, oldVersion: UInt, newVersion: UInt) -> Bool {
        println("newVersion:\(newVersion) oldVersion:\(oldVersion)")
        return true
    }
}

let delegateObject = SQLiteDelegateObject()

let db = SQLite(path:"/Users/apple/Documents/test.sqlite",version: 1,delegate:delegateObject)


let (handle,_) = db.open()

let count = db.count(handle, tableName: "Person", Where: nil)


if let rs = db.select(handle, columns: nil, tables: ["p": "Person", "c": "Computer", "cpu": "CPU"], Where: "p.computer_id = c.computer_id AND c.cpu_id = cpu.cpu_id AND cpu.cpu_id = 1") {
    
    print("程序员有 \(count) 人,其中电脑使用 Intel CPU 的有:")
    
    while rs.next {
        let name = rs.getString("person_name")
        print(" \(name)")
    }
    println(" <");
}
db.close(handle)
/*
sqlite.execute(handle, SQL: "PRAGMA user_version = 1")

if let rs = sqlite.query(handle, SQL: "PRAGMA user_version") {
    while rs.next {
        let dict = rs.getDictionary()
        println("dict:\(dict)")
    }
}
*/
