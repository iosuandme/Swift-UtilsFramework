// Playground - noun: a place where people can play

import UIKit

// 1 ,2, 4, 8 ,16
// BitAnd( dyo & 4) = 4


// 转化任意进制
func strtoul(var num:UInt32, n:UInt32) -> String {
    var buffer:[Character] = []
    do {
        let i = num & (n - 1)
        let unicode = UInt32(i + (i > 9 ? 55 : 48))
        buffer.append(Character(UnicodeScalar(unicode)))
        num >>= 4
    } while num > 0
    return String(reverse(buffer))
}


func getRandomKey(length:Int) -> String {
    var buffer = Array<Int8>()

    for var i:Int = 0; i < length; i++ {
        let char = Int8(arc4random() % 95 + 32)
        buffer.append(char)
    }
    // 12324453
    return String.fromCString(&buffer) ?? ""
}


var privateKey = ""
var randomKey = getRandomKey(16)
let publicKey = "97582431TYkw"

let chaarr = Int8(127)

let xiegang = "O"
let firstUnicode = xiegang.unicodeScalars[xiegang.unicodeScalars.startIndex]


// MARK: 给中文加 \uXXXX 编码
func bufferWithString(string:String) -> [Int8] {
    var buffer = Array<Int8>()
    for unicodeScalar in string.unicodeScalars {
        var char = unicodeScalar.value
        if !unicodeScalar.isASCII() {
            var utf8:UInt32 = 0
            buffer.append(92)
            buffer.append(117)
            for var i:UInt32 = 0; i < 16; i+=4 {
                let k = char >> (12 - i)
                let c = Int8(k & 0xF)
                buffer.append(c + (c > 9 ? 55 : 48))
            }
        } else {
            buffer.append(Int8(char))
        }
    }
    return buffer
}

func encodeJSON(json:String) -> String {
    var result = ""
    
    // 给中文加 \uXXXX 编码
    var buffer = bufferWithString(json)
    
    // 输出测试 加编码结果 可忽略
    if buffer.count > 0 {
        // 123
        let result = String.fromCString(&buffer)!
        let str = NSString(bytes: &buffer, length: buffer.count, encoding: NSUTF8StringEncoding)!
        let data = str.dataUsingEncoding(NSUTF8StringEncoding)!
        let obj: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.allZeros, error: nil)
    }
    
    let publicKeyBuffer = bufferWithString(publicKey)
    
    
    return result
}

let dict = ["book":"紫钻星云"]

if let jsonData = NSJSONSerialization.dataWithJSONObject(dict, options: NSJSONWritingOptions.allZeros, error: nil) {
    if let json:String = NSString(data: jsonData, encoding: NSUTF8StringEncoding) {
        println(json)
        let dc = encodeJSON(json)
    }
}


//
//let a:(String,Int,Bool) = ("123",123,false)
//
//let i = 0
//
//func iterate<C,R>(t:C, block:(String,Any)->R) {
//    let mirror = reflect(t)
//    for i in 0..<mirror.count {
//        block(mirror[i].0, mirror[i].1.value)
//    }
//}
//
//
//
//var array = NSMutableArray(array: ["str1","str2"])
//let bbb = array.objectAtIndex(0) as NSString
//
//let tuple = ((false, true), 42, 42.195, "42.195km")
//iterate(tuple) { println("\($0) => \($1)") }
//iterate(tuple.0){ println("\($0) => \($1)")}
//iterate(tuple.0.0) { println("\($0) => \($1)")} // no-op
//
//iterate(a) { println("\($0) => \($1)") }

//let b = map(a) { (item) -> String in
//    return "\(item)"
//}


/*
let char:Character = "c"
str.append(char)
str.insert(char, atIndex: advance(str.startIndex, 3))

func alignRight(var string:String, count:Int, pad:Character) -> String {
    let amountToPad = count - string.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
    for _ in 1...amountToPad {
        string.insert(pad, atIndex: string.startIndex)
    }
    return string
}

let price = alignRight("58", 8, "0")

let color:UInt32 = 0xFFAABBCC
let b = CGFloat(color & 0xFF)
let g = CGFloat((color >> 8) & 0xFF)
let r = CGFloat((color >> 16) & 0xFF)
let a = CGFloat((color >> 24) & 0xFF)




let uiColor = UIColor(red: r/255, green: g/255, blue: b/255, alpha:a/255)



*/
