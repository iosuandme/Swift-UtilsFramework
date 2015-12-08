//
//  main.swift
//  SwiftFrameworks
//
//  Created by 李招利 on 14/9/11.
//  Copyright (c) 2014年 慧趣工作室. All rights reserved.
//

import Foundation


var str = "Sign"
let data = str.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!
let bytes:UnsafePointer<Int8> = UnsafePointer<Int8>(data.bytes)
var chars:[Int8] = []
for var i:Int = 0; i<data.length; i++ {
    chars.append(bytes[i])
}

let home = NSHomeDirectory()
let dir = (home as NSString).stringByAppendingPathComponent("Wunderlist")
//println(dir)


/*
let r = String(format: "数量%.2f", 0.5567)
println(r)

let str = "RVTR&67}=Zh^X(>^\\YZ(9aoYRa',y;Je'~Sh%9h$D}O7a091P0g4,/Rc$&\"9JgTM75`P^-3!\""

let publicKey = "1321asq水电费13213"

let privateKey = "121313123"

let json = "{\"book\":\"Swift开发最高秘籍\"}"
println(json)

let encrypt = Encrypt(publicKey: publicKey, randomKeyLength: 31)
let result = encrypt.encodeJSON(json, privateKey: privateKey)
println(result)

let data = result.encodeURL()
let post = "{key:\(privateKey), data:\(data)}"


let src = encrypt.decodeJSON(str, privateKey: privateKey)

println(src)
*/
/*

var char:Int32 = 0x778F9D & 0x7F
let num:Int8 = Int8(char)
println(num)

func getRandomKey(length:Int) -> String {
    var buffer = Array<UInt8>()
    
    for var i:Int = 0; i < length; i++ {
        let char = UInt8(arc4random() % 95 + 32)
        buffer.append(char)
    }
    let they2 = NSString(bytes: &buffer, length: length, encoding: NSUTF8StringEncoding)! as String
    println(they2)
    let data = NSData(bytes: &buffer, length: length)
    return they2
}


var randomKey = getRandomKey(32)

println(randomKey.length)
println(randomKey)
*/
/*

struct CPU: SQLiteDataBase {
    static func tableColumnTypes() -> [(SQLColumnName, SQLColumnType, SQLColumnState)] {
        return [
            ("cpu_id",  .INTEGER,      .PrimaryKey),
            ("cpu_firm",.VARCHAR(30),  .NotNull)
        ]
    }
    
    init(id:UInt, frim:String) {
        cpu_id = id
        cpu_firm = frim
    }
    
    var cpu_id:UInt
    var cpu_firm:String
}

class Computer : SQLiteDataBase {
    class func tableColumnTypes() -> [(SQLColumnName, SQLColumnType, SQLColumnState)] {
        return [
            ("computer_id",     .INTEGER,      .PrimaryKeyAutoincrement),
            ("computer_brand",  .VARCHAR(50),  .NotNull),
            ("cpu_id",          .INTEGER,      .NotNull)
        ]
    }
    
    init(id:UInt, brand:String, cpu:UInt) {
        computer_id = id
        computer_brand = brand
        cpu_id = cpu
    }
    
    var computer_id:UInt
    var computer_brand:String
    var cpu_id:UInt
}

class Preson: SQLiteDataBase {
    class func tableColumnTypes() -> [(SQLColumnName, SQLColumnType, SQLColumnState)] {
        return [
            ("preson_id",  .INTEGER,       .PrimaryKey),
            ("preson_name",.VARCHAR(80),   .NotNull),
            ("preson_age", .INTEGER,       .None),
            ("computer_id",.INTEGER,       .NotNull)
        ]
    }
    
    init(id:Int, name:String, computer:Int, age:Int? = nil) {
        preson_id = id
        preson_name = name
        preson_age = age
        computer_id = computer
    }
    var preson_id:Int
    var preson_name:String
    var preson_age:Int?
    var computer_id:Int
}


func main() {
    //NSFileManager.defaultManager().removeItemAtPath("/Users/apple/Documents/test.sqlite", error: nil)
    
    let sqlite = SQLite(path: "/Users/apple/Documents/test.sqlite", version: 2) {
        (db, oldVersion, newVersion) -> Bool in
        println("oldVersion:\(oldVersion) newVersion:\(newVersion)")
        switch (oldVersion,newVersion) {
        case (0,1):
            //db.createTableIfNotExists("cpu", withType: CPU.self)
            // 创建表方式1
            db.createTableIfNotExists("cpu", params: [
                ("cpu_id",  .INTEGER,     .PrimaryKey),
                ("cpu_firm",.VARCHAR(20), .None)
            ])
            // 创建表方式2
            db.createTableIfNotExists("computer", withType: Computer.self)
            db.createTableIfNotExists("preson", withType: Preson.self)
            
            // 插入数据方式1
            db.insert(into: "cpu", values: 1,"Intel")
            // 插入数据方式2
            db.insertOrReplace(into: "cpu", values: 2,"AMD")
            
            // 插入数据方式3
            let computers = [
                Computer(id: 1, brand: "Apple", cpu: 1),
                Computer(id: 2, brand: "IBM", cpu: 1),
                Computer(id: 3, brand: "HP", cpu: 2),
                Computer(id: 4, brand: "Lenovo", cpu: 2)
            ]
            db.insertOrReplace(into: "computer", ["computer_brand","cpu_id"]) {
                (index:Int) -> [String : Any]? in
                if index >= computers.count {
                    return nil
                }
                return [
                    "computer_brand":computers[index].computer_brand,
                    "cpu_id"        :computers[index].cpu_id
                ]
            }
            
            
            // 插入数据方式4
            let presons = [
                Preson(id: 1, name: "张三", computer: 2),
                Preson(id: 2, name: "李四", computer: 1, age: 36),
                Preson(id: 3, name: "王五", computer: 4, age: 48),
                Preson(id: 4, name: "赵六", computer: 3, age: 24),
                Preson(id: 5, name: "燕七", computer: 1)
            ]
            db.insertOrReplace(into: "preson", rows: presons)
        case (0,2):
            // 创建表方式1
            db.createTableIfNotExists("cpu", params: [
                ("cpu_id",  .INTEGER,     .PrimaryKey),
                ("cpu_firm",.VARCHAR(20), .None),
                ("cpu_imei",.VARCHAR(20), .None)
                ])
            // 创建表方式2
            db.createTableIfNotExists("computer", withType: Computer.self)
            db.createTableIfNotExists("preson", withType: Preson.self)
            
            // 插入数据方式1
            db.insert(into: "cpu", values: 1,"Intel","123456")
            // 插入数据方式2
            db.insertOrReplace(into: "cpu", values: 2,"AMD","")
            
            // 插入数据方式3
            let computers = [
                Computer(id: 1, brand: "Apple", cpu: 1),
                Computer(id: 2, brand: "IBM", cpu: 1),
                Computer(id: 3, brand: "HP", cpu: 2),
                Computer(id: 4, brand: "Lenovo", cpu: 2)
            ]
            db.insertOrReplace(into: "computer", ["computer_brand","cpu_id"]) {
                (index:Int) -> [String : Any]? in
                if index >= computers.count {
                    return nil
                }
                return [
                    "computer_brand":computers[index].computer_brand,
                    "cpu_id"        :computers[index].cpu_id
                ]
            }
            
            
            // 插入数据方式4
            let presons = [
                Preson(id: 1, name: "张三", computer: 2),
                Preson(id: 2, name: "李四", computer: 1, age: 36),
                Preson(id: 3, name: "王五", computer: 4, age: 48),
                Preson(id: 4, name: "赵六", computer: 3, age: 24),
                Preson(id: 5, name: "燕七", computer: 1)
            ]
            db.insertOrReplace(into: "preson", rows: presons)
        case (1,2):
            db.alterTable("cpu", add: "cpu_imei", SQLColumnType.VARCHAR(20))
        default:
            return false
        }
        return true
    }
    
    let (db,error) = sqlite.open()
    
    if error != .OK {
        println("不能操作数据库:\(error)")
    } else {        
        let count = db.select(count: nil, from: "preson", Where: nil)
        println("程序员共 \(count) 人")
        if let rs = db.select(nil, from: ["p":"preson","c":"computer","u":"cpu"], Where: "p.computer_id = c.computer_id AND c.cpu_id = u.cpu_id AND u.cpu_id = 1") {
            print("使用Intel CPU 的人有:")
            while rs.next {
                print(" " + rs.getString("preson_name"))
            }
            println(" <")
            println(db.lastSQL)
        }
    }
}

main()
*/