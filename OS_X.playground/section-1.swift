// Playground - noun: a place where people can play

import Cocoa
var str = "Hello, playground"

protocol SQLiteTableClassDelegate : NSObjectProtocol {
    class func tableColumnTypeWithProperty(propertyName:String) -> (String, Int)?
}

class Person: NSObject, SQLiteTableClassDelegate {
//class Person {

    
    var name:String
    var id:Int!
    
    init(name:String, id:Int?) {
        self.name = name
        self.id = id
    }
    
    class func tableColumnTypeWithProperty(propertyName: String) -> (String, Int)? {
        switch propertyName {
        case "name":
            return ("name",1)
        case "id":
            return ("id",2)
        default :
            return nil
        }
    }
}

/*
func create<T : SQLiteTableClassDelegate>(clsType:T.Type)  {
    var count:UInt32 = 0
    let ivarList = class_copyIvarList(clsType, &count)
    for i in 0..<count {
        let ivar = ivarList[Int(i)]
        if let name = String.fromCString(ivar_getName(ivar)) {
            if let (key,state) = clsType.tableColumnTypeWithProperty(name) {
                println("key:\(key), state:\(state)")
            }
        }
        println("name")
    }
    let coun = strideof(clsType)
    
}
create(Person.self)

*/

func getValue<T>(valueMirror:MirrorType, nilReplaceTo defaultValue:T?) -> T? {
    var value:T? = nil
    if valueMirror.disposition == .Optional {
        if valueMirror.count > 0 {
            value = valueMirror[0].0 as? T
        } else {
            value = defaultValue
        }
    } else {
        value = valueMirror.value as? T
    }
    return value
}


func bindValue<T>(columnValue:T?,index:Int) {
    if let v = columnValue {
        switch v {
        case let value as Int:
            println("Int:\(value)")
        default:
            if reflect(v).disposition == .Optional {
                println("Unkonw:nil")
            }
            println("Unknow:\(v)")
        }
    } else {
        println("nil")
    }
}

let person = Person(name: "1", id: nil)

let mirror:MirrorType = reflect(person)
let count = mirror.count
for i in 0..<mirror.count {
    let (key,valueMirror) = mirror[i]
    println("\(key) = \(valueMirror.value)")
    bindValue(valueMirror.value, 0)
    switch valueMirror.valueType {
    case _ as Int?.Type, _ as Int.Type:
        let defaultValue:Int? = nil
        if let value = getValue(valueMirror, nilReplaceTo: defaultValue) {
        println(valueMirror.value)
        }
    default:
        println("nil")
    }
//    if let value = valueMirror.value {
//        println("value:\(value)")
//    }
}


