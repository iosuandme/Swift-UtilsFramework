// Playground - noun: a place where people can play

import UIKit

var str = "Hello, playground"

let a:(String,Int,Bool) = ("123",123,false)

let i = 0

func iterate<C,R>(t:C, block:(String,Any)->R) {
    let mirror = reflect(t)
    for i in 0..<mirror.count {
        block(mirror[i].0, mirror[i].1.value)
    }
}



var array = NSMutableArray(array: ["str1","str2"])
let bbb = array.objectAtIndex(0) as NSString

let tuple = ((false, true), 42, 42.195, "42.195km")
iterate(tuple) { println("\($0) => \($1)") }
iterate(tuple.0){ println("\($0) => \($1)")}
iterate(tuple.0.0) { println("\($0) => \($1)")} // no-op

iterate(a) { println("\($0) => \($1)") }

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
