//
//  main.swift
//  SwiftFrameworks
//
//  Created by 李招利 on 14/9/11.
//  Copyright (c) 2014年 慧趣工作室. All rights reserved.
//

import Foundation



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

*/

class Computer {
  
    init(id:UInt, brand:String, cpu:UInt) {
        computer_id = id
        computer_brand = brand
        cpu_id = cpu
    }
    
    var computer_id:UInt
    var computer_brand:String
    var cpu_id:UInt
}


func main() {
    let err = try? NSFileManager.defaultManager().removeItemAtPath("/Users/bujiandi/Documents/test.sqlite")
    print(err)
    
    let sqlite = SQLite(path: "/Users/bujiandi/Documents/test.sqlite", version: 2) {
        (db, oldVersion, newVersion) -> Bool in
        print("oldVersion:\(oldVersion) newVersion:\(newVersion)")
        switch (oldVersion,newVersion) {
        case (0,2):
            // 创建表方式1
            try! db.createTableIfNotExists("cpu", params: [
                ("cpu_id",  .integer, [.PrimaryKey, .Autoincrement], nil),
                ("cpu_firm",.text, .None, "AMD"),
                ("cpu_imei",.text, .None, nil)
                ])
            try! db.createTableIfNotExists("computer", params: [
                ("computer_id", .integer, [.PrimaryKey, .Autoincrement], "1000"),
                ("computer_brand", .text, .NotNull, nil),
                ("cpu_id", .integer, .None, nil)
                ])
            
            // 创建表方式2
            try! db.createTableIfNotExists("user", params: [
                ("user_id", .integer, [.PrimaryKey, .Autoincrement], nil),
                ("user_name", .text, .None, nil),
                ("computer_id", .integer, .None, nil)
                ])
            
//            try! db.createTableIfNotExists("book", params: [
//                ("book_id", .integer, [.PrimaryKey, .Autoincrement], nil),
//                ("book_name", .text, .None, nil),
//                ("another_id", .integer, .None, nil)
//                ])
            print(db.lastSQL)
            //db.createTableIfNotExists("computer", withType: Computer.self)
            //db.createTableIfNotExists("preson", withType: Preson.self)
            
            // 插入数据方式1
            try! db.insert(into: "cpu", columns: nil, values: 1, "Intel", "90381")
            // 插入数据方式2
            try! db.insertOrReplace(into: "cpu", columns: nil, values: 2, "AMD", "")
            try! db.insertOrReplace(into: "cpu", columns: nil, values: 2, "AMD", "32767")
            
            // 插入数据方式3
            let computers = [
                Computer(id: 1, brand: "Apple"  , cpu: 1),
                Computer(id: 2, brand: "IBM"    , cpu: 1),
                Computer(id: 3, brand: "HP"     , cpu: 2),
                Computer(id: 4, brand: "Lenovo" , cpu: 2)
            ]
            db.insertOrReplace(into: "computer", columns: ["computer_brand", "cpu_id"], values: computers) {
                (id, item) -> [String : Any] in
                print(id)
                return ["computer_brand": item.computer_brand, "cpu_id": item.cpu_id]
            }
            
        //case (1,2):
            //db.alterTable("cpu", add: "cpu_imei", SQLColumnType.VARCHAR(20))
        default:
            return false
        }
        return true
    }
    
    
    if let db = try? sqlite.open() {
        if let rs = try? db.select(nil, from: "computer", Where: "cpu_id = 1") {
            while rs.next {
                let id = rs.getInt("computer_id")
                let brand = rs.getString("computer_brand")
                let cpu = rs.getInt("cpu_id")
                
                print("id:\(id) brand:\(brand) cpu:\(cpu)")
            }
        }
        // 插入数据方式3
        let computers = [
            Computer(id: 4, brand: "Apple"  , cpu: 1),
            Computer(id: 3, brand: "IBM"    , cpu: 1),
            Computer(id: 2, brand: "HP"     , cpu: 2),
            Computer(id: 1, brand: "Lenovo" , cpu: 2)
        ]
        db.insertOrReplace(into: "computer", columns: ["computer_id", "computer_brand", "cpu_id"], values: computers) {
            (id, item) -> [String : Any] in
            print(id)
            return ["computer_id": item.computer_id,"computer_brand": item.computer_brand, "cpu_id": item.cpu_id]
        }
    }
//    let (db,error) = sqlite.open()
//    
//    if error != .OK {
//        println("不能操作数据库:\(error)")
//    } else {
//        let count = db.select(count: nil, from: "preson", Where: nil)
//        println("程序员共 \(count) 人")
//        if let rs = db.select(nil, from: ["p":"preson","c":"computer","u":"cpu"], Where: "p.computer_id = c.computer_id AND c.cpu_id = u.cpu_id AND u.cpu_id = 1") {
//            print("使用Intel CPU 的人有:")
//            while rs.next {
//                print(" " + rs.getString("preson_name"))
//            }
//            println(" <")
//            println(db.lastSQL)
//        }
//    }
}

main()