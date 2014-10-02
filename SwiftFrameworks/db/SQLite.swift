//
//  SQLite.swift
//  SwiftFrameworkTesting
//
//  Created by 招利 李 on 14-6-27.
//  Copyright (c) 2014年 慧趣工作室. All rights reserved.
//
//  引用 libsqlite.3.0.dylib
//  需要建立 ProjectName-Bridging-Header.h 桥文件,并写下 #import "sqlite3.h"
//
//  使用例子如下 : (OS X 开发也可以用)
//
////////////////////////////////////////////////////////////////////////////////////////////////
//
//    extension ViewController : SQLiteDelegate {
//        func create(handle:COpaquePointer, sqlite:SQLite) {
//            //创建电脑表
//            sqlite.create(handle,
//                tableName: "Computer",
//                params:    [.SQL_Int    ("cid",  .SQL_PrimaryKeyAutoincrement),
//                            .SQL_String ("brand",.SQL_NotNull),
//                            .SQL_Int    ("cpu", .SQL_NotNull)])
//            //创建处理器表
//            sqlite.create(handle,
//                tableName: "CPU",
//                params:    [.SQL_Int    ("uid",  .SQL_PrimaryKeyAutoincrement),
//                            .SQL_String ("firm",.SQL_NotNull)])
//            //创建使用者表
//            sqlite.create(handle,
//                tableName: "Preson",
//                params:    [.SQL_Int    ("pid",  .SQL_PrimaryKeyAutoincrement),
//                            .SQL_String ("name",.SQL_NotNull),
//                            .SQL_Int    ("computer",.SQL_Default)])
//
//            sqlite.insert(handle, tableName: "CPU", params:["firm":"AMD"])
//            sqlite.insert(handle, tableName: "CPU", params:["firm":"Intel"])
//
//            sqlite.insert(handle, tableName: "Computer", params:["brand":"Apple", "cpu":2])
//            sqlite.insert(handle, tableName: "Computer", params:["brand":"Hp", "cpu":1])
//            sqlite.insert(handle, tableName: "Computer", params:["brand":"Dell", "cpu":2])
//
//            sqlite.insert(handle, tableName: "Preson", params:["name":"lzl", "computer":1])
//            sqlite.insert(handle, tableName: "Preson", params:["name":"lc", "computer":1])
//            sqlite.insert(handle, tableName: "Preson", params:["name":"jc", "computer":1])
//            sqlite.insert(handle, tableName: "Preson", params:["name":"gd", "computer":2])
//
//            println("插入完成")
//
//        }
//    }
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  在需要查询的时候代码如下
//
//  let sqlite = SQLite(path:"/Users/apple/Documents/test.sqlite",delegate:self)
//
//  let (handle,_) = sqlite.open()
//  let count = sqlite.count(handle,tableName: "Preson", Where: "computer = 1")
//  println("有苹果电脑的人数为\(count)")
//
//  //查询所有电脑品牌为 Apple的数据
//  if let rs = sqlite.select(handle,params:nil, tables: ["p":"Preson","cp":"Computer","c":"CPU"], Where: "p.computer = cp.cid AND cp.cpu = c.uid AND p.computer = 1") {
//      println("查询成功")
//      while rs.next {
//          let dict = rs.getDictionary()
//          println("data:\(dict)")
//      }
//
//  } else {
//      println("查询失败")
//  }
//


@asmname("sqlite3_exec") func sqlite3_execute(COpaquePointer,UnsafePointer<CChar>,CFunctionPointer<Void>,COpaquePointer,AutoreleasingUnsafeMutablePointer<UnsafePointer<CChar>>) -> CInt
@asmname("sqlite3_bind_blob") func sqlite3_bind_data(COpaquePointer,CInt,UnsafePointer<()>,CInt,COpaquePointer) -> CInt
@asmname("sqlite3_bind_text") func sqlite3_bind_string(COpaquePointer,CInt,UnsafePointer<CChar>,CInt,COpaquePointer) -> CInt
//@asmname("sqlite3_column_table_name") func sqlite3_column_table_title(COpaquePointer,CInt) -> CString
//sqlite3_column_table_name
import Foundation

// MARK: - protocols 接口
protocol SQLiteBaseSet {
    var step:CInt { get }
    var next:Bool { get }
    var row:Int { get }
    func reset()
    func close()
}
//结果集
protocol SQLiteResultSet : SQLiteBaseSet {
    func firstValue() -> Int
    func getDictionary() -> [String:Any]
    func getUInt(columnName:String) -> UInt
    func getInt(columnName:String) -> Int64
    func getFloat(columnName:String) -> Float
    func getDouble(columnName:String) -> Double
    func getString(columnName:String) -> String!
    func getData(columnName:String) -> NSData!
    func getDate(columnName:String) -> NSDate!
}

// 绑定结果集
protocol SQLiteBindSet : SQLiteBaseSet {
    var bindCount:CInt { get }
    func bindClear() -> CInt
    // 泛型绑定 自动递归拆包
    func bindValue<T>(columnValue:T?,index:Int) -> CInt
}

protocol SQLiteDataBase {
    // 返回纯属性所代表 字段(column)的类型 和 参数
    class func tableColumnTypes() -> [(SQLite.ColumnName, SQLite.ColumnType, SQLite.ColumnState)]
}

// 代理
protocol SQLiteDelegate {
    // MARK: 当数据库为空时
    func onCreate(handle:COpaquePointer, db:SQLite)      // <- 需要创建所有的表
    
    // MARK: 当数据库版本变化时
    func onUpgrade(handle:COpaquePointer, db:SQLite, oldVersion:UInt, newVersion:UInt) -> Bool
    
}

protocol SQLiteLogDelegate {
    
    // MARK: 输出 SQL 语句
    func logSQL(sql:String)
    
    // MARK: 当执行 SQL 语句出错时输出错误 @result 如果为 true 则 使用断言 中断程序,一般 DEBUG 模式下使用
    func logError(error:NSError)
}

// MARK: - SQLiteProtocol 索引
protocol SQLiteCreateIndex {
    func create(index indexName:String, on tableName:String, columns columnNames:String...) -> Error?
}

// MARK: - SQLiteProtocol 基本
protocol SQLiteBase {
    //执行 SQL 语句
    func executeSQL(SQL:String) -> Error?
    //执行 SQL 查询语句
    func querySQL(SQL:String) -> SQLiteResultSet?
    //获取最后出错信息
    var lastError:Error { get }
}

// MARK: - SQLiteProtocol 事务
protocol SQLiteQueue {
    // MARK: 开启事务 BEGIN TRANSACTION
    func beginTransaction() -> Error?
    // MARK: 提交事务 COMMIT TRANSACTION
    func commitTransaction() -> Error?
    // MARK: 回滚事务 ROLLBACK TRANSACTION
    func rollbackTransaction() -> Error?
}

// MARK: - SQLiteProtocol 创建
protocol SQLiteCreate {
    // 通过一个
    func createTableIfNotExists(tableName:String, params:[(SQLite.ColumnName,SQLite.ColumnType,SQLite.ColumnState)]) -> Error?
    
    // 通过一个类来创建表 类必须实现 SQLiteDataBase 协议 (推荐)
    func createTableIfNotExists<T : SQLiteDataBase>(tableName:String, withType:T.Type) -> Error?
}

// MARK: - SQLiteProtocol 改变
protocol SQLiteUpdate {
    func update(tableName:String, set params:[String:Any], Where:String?) -> Error?
}

// MARK: - SQLiteProtocol 增加
protocol SQLiteInsert {
    
    // 单条插入全部字段
    func insert(into tableName:String, values:Any...) -> Error?
    func insertOrReplace(into tableName:String, values:Any...) -> Error?
    // 单条插入部分字段
    func insertOrReplace(into tableName:String, columns:[String], params:(Int) -> [String:Any]?) -> Error?
    //func insert(into tableName:String, params:[SQLite.ColumnValue]) -> Error?
}

// MARK: - SQLiteProtocol 删除
protocol SQLiteDelete {
    func delete(from tableName:String, Where:String?) -> Error?
}

// MARK: - SQLiteProtocol 查询
protocol SQLiteSelect {
    //查询数量
    func select(count columns:[String]?, from tableName:String, Where:String?) -> Int
    
    //普通查询
    func select(columns:[String]?, from tableName:String, Where:String?) -> SQLiteResultSet?
    
    //联合查询
    func select(columns:[String]?, from tables:[String:SQLite.TableName], Where:String?) -> SQLiteResultSet?
}

// MARK: - SQLite 主函数
class SQLite {
    typealias ColumnName = String
    typealias TableName = String

    let version:UInt
    let path:String
    //weak var delegate:protocol<NSObjectProtocol, SQLiteDelegate, SQLiteLogDelegate>!
    var delegate:protocol<SQLiteDelegate, SQLiteLogDelegate>?
    //weak var delegate:SQLitedelegate?
    //var logDelegate:SQLiteLogDelegate?
    
    // 适合 OS X 和 iOS
    required init(path:String, version: UInt = 1, delegate:protocol<SQLiteDelegate, SQLiteLogDelegate>! = nil) {
        self.path = path
        self.delegate = delegate
        self.version = version
        setVersion(version)
    }
    // 适合 iOS
    convenience init(name:String, version: UInt = 1, delegate:protocol<SQLiteDelegate, SQLiteLogDelegate>! = nil) {
        let docDir = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString
        self.init(path:docDir.stringByAppendingPathComponent(name),version:version,delegate:delegate)
    }
    
    func open() -> (SQLiteHandle!,Error?) {
        var handle:COpaquePointer = nil
        let dbPath:NSString = path
        
        //如果文件不存在并且代理不为空
        var isDir:ObjCBool = false
        if !NSFileManager.defaultManager().fileExistsAtPath(path, isDirectory: &isDir) || isDir {
            NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil, error: nil)
        }
        
        let result = sqlite3_open(dbPath.UTF8String, &handle)
        if result != SQLITE_OK {
            let errorCode = sqlite3_errcode(handle)
            let errorDescription = String.fromCString(sqlite3_errmsg(handle))
            sqlite3_close(handle)
            assert(DEBUG == 0, "打开数据库[\(path)]失败")
            return (nil,Error(code: Int(errorCode), content: errorDescription ?? "", userInfo: path))
            //(handle, NSError(domain: "打开数据库[\(path)]失败", code: Int(result), userInfo: ["path":path]))
        }
        return (SQLite.Handle(handle: handle), nil)
    }
    
    private func setVersion(newVersion: UInt) {
        /*
        // 打开数据库
        let (handle,openError) = open()
        
        // 如果打开数据库失败则输出这个错误
        if let error = openError {
            delegate?.logError(error)
        } else if let rs = query(handle, SQL: "PRAGMA user_version") {
        // 否则判断版本是否变化,
            let oldVersion = UInt(rs.firstValue())
            if oldVersion != newVersion {
                // 如果变化则调用更新函数来更新字段
                if delegate?.onUpgrade(handle, db:self, oldVersion:oldVersion, newVersion:newVersion) == true {
                    execute(handle, SQL: "PRAGMA user_version = \(newVersion)")
                }
            }
            delegate?.onCreate(handle, db: self)
            close(handle)
        }
        */
    }

    deinit{
        println("SQLite 已释放")
    }
    
}

// MARK: - 数据库操作句柄
protocol SQLiteHandle : SQLiteBase, SQLiteCreate, SQLiteCreateIndex, SQLiteQueue, SQLiteUpdate, SQLiteDelete, SQLiteSelect, SQLiteInsert { }

extension SQLite {
    class Handle {
        // 通过 SQLite 的 open 函数获得一个 Handle
        private var _handle:COpaquePointer = nil
        init(handle:COpaquePointer) {
            _handle = handle
        }

        deinit {
            if _handle != nil {
                sqlite3_close(_handle)
            }
        }
        private var _lastSQL:NSString = ""
    }
}

// MARK: - SQLiteHandle 基本执行
extension SQLite.Handle : SQLiteHandle {
    //执行 SQL 语句
    func executeSQL(SQL:String) -> Error? {
        //delegate?.logSQL("SQL -> \(SQL)")
        _lastSQL = SQL
        if SQLITE_OK != sqlite3_execute(_handle,_lastSQL.UTF8String,nil,nil,nil) {
            return lastError
        }
        return nil
    }
    
    //执行 SQL 查询语句
    func querySQL(SQL:String) -> SQLiteResultSet? {
        //delegate?.logSQL("SQL -> \(SQL)")
        _lastSQL = SQL
        var stmt:COpaquePointer = nil
        if SQLITE_OK != sqlite3_prepare_v2(_handle, _lastSQL.UTF8String, -1, &stmt, nil) {
            sqlite3_finalize(stmt)
            return nil
        }
        return SQLite.RowSet(stmt);
    }
    
    // 获取最后出错信息
    var lastError:Error {
        let errorCode = sqlite3_errcode(_handle)
        let errorDescription = String.fromCString(sqlite3_errmsg(_handle))
        return Error(code: Int(errorCode), content: errorDescription ?? "", userInfo:_lastSQL)
    }
}

// MARK: - SQLiteHandle 创建表
extension SQLite.Handle : SQLiteCreate {
    
    func createTableIfNotExists(tableName:String, params:[(SQLite.ColumnName,SQLite.ColumnType,SQLite.ColumnState)]) -> Error? {
        var paramString = ""
        for (name,type,state) in params {
            if !paramString.isEmpty {
                paramString += ", "
            }
            paramString += "\"\(name)\" \(type)\(state)"
        }
        let sql = "CREATE TABLE IF NOT EXISTS \"\(tableName)\" (\(paramString))"
        return executeSQL(sql)
    }
    
    func createTableIfNotExists<T : SQLiteDataBase>(tableName:String, withType:T.Type) -> Error? {
        var paramString = ""
        
        let params = T.tableColumnTypes()
        assert(params.count > 0 || DEBUG == 0, "模板类型没有返回表结构参数")
        for (name, type, state) in params {
            if !paramString.isEmpty {
                paramString += ", "
            }
            paramString += "\"\(name)\" \(type)\(state)"
        }
        /*
        var count:UInt32 = 0
        let ivarList = class_copyIvarList(clsType, &count)
        for i in 0..<count {
            let ivar = ivarList[Int(i)]
            if let name = String.fromCString(ivar_getName(ivar)) {
                if let (type,state) = clsType.tableColumnTypeWithProperty(name) {
                    if !paramString.isEmpty {
                        paramString += ", "
                    }
                    paramString += "\"\(name)\" \(type)\(state)"
                }
            }
        }
        */
        let sql = "CREATE TABLE IF NOT EXISTS \"\(tableName)\" (\(paramString))"
        return executeSQL(sql)

    }
    
}

// MARK: - SQLiteHandle 创建索引
extension SQLite.Handle : SQLiteCreateIndex {
    func create(index indexName:String, on tableName:String, columns columnNames:String...) -> Error? {
        if columnNames.count == 0 {
            return Error(code: 0, content: "[\(tableName)]没有指定任何索引字段", userInfo: indexName)
        }
        let names = columnNames.componentsJoinedByString(", ")
        //let names = NSArray(array: columnNames).componentsJoinedByString(", ")
        return executeSQL("CREATE INDEX \(indexName) ON \(tableName)(\(names))")
    }
}

// MARK: - SQLiteHandle 事务
extension SQLite.Handle : SQLiteQueue {
    // MARK: 开启事务 BEGIN TRANSACTION
    func beginTransaction() -> Error? {
        return executeSQL("BEGIN TRANSACTION")
    }
    // MARK: 提交事务 COMMIT TRANSACTION
    func commitTransaction() -> Error? {
        return executeSQL("COMMIT TRANSACTION")
    }
    // MARK: 回滚事务 ROLLBACK TRANSACTION
    func rollbackTransaction() -> Error? {
        return executeSQL("ROLLBACK TRANSACTION")
    }
}

// MARK: - SQLiteHandle 更新
extension SQLite.Handle : SQLiteUpdate {
    func update(tableName:String, set params:[String:Any], Where:String?) -> Error? {
        var paramString = ""
        for (key,value) in params {
            if !paramString.isEmpty {
                paramString += " AND "
            }
            paramString += "\"\(key)\" = \"\(value)\""
        }
        if let condition = Where {
            if !condition.isEmpty {
                paramString += "WHERE \(condition)"
            }
        }
        let sql = "UPDATE \(tableName) SET \(paramString)"
        return executeSQL(sql)
    }
}

// MARK: - SQLiteHandle 删除
extension SQLite.Handle : SQLiteDelete {
    // 删除
    func delete(from tableName:String, Where:String?) -> Error? {
        if let condition = Where {
            return executeSQL("DELETE FROM \(tableName) WHERE \(condition)")
        }
        return executeSQL("DELETE FROM \(tableName)")
    }
}

// MARK: - SQLiteHandle 查询
extension SQLite.Handle : SQLiteSelect {
    // 查询数量
    func select(count columns:[String]?, from tableName:String, Where:String?) -> Int {
        var fields = ""
        if let array:NSArray = columns {
            fields = array.componentsJoinedByString(", ")
        } else {
            fields = "*"
        }
        var sql = "SELECT count(\(fields)) FROM \(tableName)"
        if let end = Where {
            sql += " WHERE \(end)"
        }
        var count:Int = 0
        if let rs = querySQL(sql) {
            if rs.next {
                count = rs.firstValue() //Int(sqlite3_column_int(rs.stmt, 0))
            }
            rs.close()
        }
        return count
    }
    
    // 普通查询
    func select(columns:[String]?, from tableName:String, Where:String?) -> SQLiteResultSet? {
        var sql:String = "SELECT "
        if let array:NSArray = columns {
            sql += array.componentsJoinedByString(", ")
        } else {
            sql += "*"
        }
        if let end:String = Where {
            sql += " FROM \(tableName) WHERE \(end)"
        } else {
            sql += " FROM \(tableName)"
        }
        return querySQL(sql)
    }
    
    // 联合查询
    func select(columns:[String]?, from tables:[String:SQLite.TableName], Where:String?) -> SQLiteResultSet? {
        var sql:String = "SELECT "
        if let array:NSArray = columns {
            sql += array.componentsJoinedByString(", ")
        } else {
            sql += "*"
        }
        var paramString = ""
        for (key,value) in tables {
            if !paramString.isEmpty {
                paramString += ", "
            }
            paramString += "\(value) \(key)"
        }
        if let condition:String = Where {
            sql += " FROM \(paramString) WHERE \(condition)"
        } else {
            sql += " FROM \(paramString)"
        }
        return querySQL(sql)
    }
}

// MARK: - SQLiteHandle 插入
extension SQLite.Handle : SQLiteInsert {
    
    // 单条插入全部字段
    private func insertValues(otherKeywords:String, into tableName:String, values:[Any]) -> Error? {
        var valueString = ""
        for value in values {
            if !valueString.isEmpty {
                valueString += ", "
            }
            valueString += "\"\(value)\""
        }
        let sql = "INSERT\(otherKeywords) INTO \(tableName) VALUES(\(valueString))"
        return executeSQL(sql)
    }
    func insert(into tableName:String, values:Any...) -> Error? {
        return insertValues("", into: tableName, values: values)
    }
    
    func insertOrReplace(into tableName:String, values:Any...) -> Error? {
        return insertValues(" OR REPLACE", into: tableName, values: values)
    }

    // 单条插入部分字段
    func insertOrReplace(into tableName:String, params:[String:Any]) -> Error? {
        var keyString = ""
        var valueString = ""
        for (key,value) in params {
            if !keyString.isEmpty {
                keyString += ", "
                valueString += ", "
            }
            keyString += "\"\(key)\""
            valueString += "\"\(value)\""
        }
        let sql = "INSERT OR REPLACE INTO \(tableName) (\(keyString)) values(\(valueString))"
        return executeSQL(sql)
    }
    
    private func getValue<T>(valueMirror:MirrorType, nilReplaceTo defaultValue:T?) -> T? {
        var value:T? = nil
        if valueMirror.disposition == .Optional {
            if valueMirror.count > 0 {
                value = valueMirror[0].1.value as? T
            } else {
                value = defaultValue
            }
        } else {
            value = valueMirror.value as? T
        }
        return value
    }
    
    func insertOrReplace<T : SQLiteDataBase>(into tableName:String, rows:[T]) -> Error? {
        let params = T.tableColumnTypes()
        var columns:[String] = []
        assert(params.count > 0 || DEBUG == 0, "模板类型没有返回表结构参数")
        var keyString = ""
        var valueString = ""
        for (name, _, state) in params {
            if !keyString.isEmpty {
                keyString += ", "
                valueString += ", "
            }
            keyString += "\"\(name)\""
            if state.insertMask {
                valueString += "Null"
            } else {
                valueString += "?"
                columns.append(name)
            }
        }
        //创建事务
        beginTransaction()
        
        var error:Error? = nil
        var hasError = false

        let SQL = "INSERT OR REPLACE INTO \(tableName) (\(keyString)) values(\(valueString))"
        if let rs:SQLiteBindSet = querySQL(SQL) as? SQLite.RowSet {
            //let length = rs.bindCount
            for row in rows {
                
                let mirror = reflect(row)
                var flag:CInt = SQLITE_ERROR
                
                for index in 1...columns.count {
                    let key = columns[index-1]
                    for i in 0..<mirror.count {
                        let tuple = mirror[i]
                        if key == tuple.0 {
                            flag = rs.bindValue(tuple.1.value, index: index)
                            break
                        }
                    }
                    assert(flag == SQLITE_OK || DEBUG == 0, "绑定[\(key)]失败 value=\(row)")
                    if flag != SQLITE_OK {
                        error = lastError //String.fromCString(sqlite3_errmsg(handle))
                        //delegate?.logSQL("错误并跳过本组数据,因为给字段[\(key)]绑定值[\(result)]失败 ERROR \(error)")
                        break;
                    }
                }
                if flag == SQLITE_OK {
                    let result = rs.step
                    assert(result == SQLITE_OK || result == SQLITE_DONE || DEBUG == 0, "严重错误并回滚操作,绑定失败\(row)")
                    if result != SQLITE_OK && result != SQLITE_DONE {
                        hasError = true
                        error = lastError
                        break
                    } else {    // <- 否则数据写入成功
                        rs.bindClear()
                        rs.reset()
                    }
                } else {        // <- 否则数据绑定失败开始下一组
                    rs.bindClear()
                }
            }
        } else {
            let error = lastError
            hasError = true
        }
        hasError ? rollbackTransaction() : commitTransaction()
        return error
    }
    
    func insertOrReplace(into tableName:String, columns:[String], params:(Int) -> [String:Any]?) -> Error? {
        var keyString = ""
        var valueString = ""
        
        for column in columns {
            if !keyString.isEmpty {
                keyString += ", "
                valueString += ", "
            }
            keyString += "\"\(column)\""
            valueString += "?"
        }
        //创建事务
        beginTransaction()
        
        var error:Error? = nil
        var hasError = false
        //获取插入句柄绑定
        let SQL = "INSERT OR REPLACE INTO \(tableName) (\(keyString)) values(\(valueString))"
        if let rs:SQLiteBindSet = querySQL(SQL) as? SQLite.RowSet {
            //let length = rs.bindCount
            
            var i = 0
            while let values = params(i++) {
                var flag:CInt = 0
                for index in 1...columns.count {
                    let key = columns[index-1]
                    flag = rs.bindValue(values[key], index: index)
                    assert(flag == SQLITE_OK || DEBUG == 0, "绑定[\(key)]失败 value=\(values[key])")
                    if flag != SQLITE_OK {
                        error = lastError //String.fromCString(sqlite3_errmsg(handle))
                        //delegate?.logSQL("错误并跳过本组数据,因为给字段[\(key)]绑定值[\(result)]失败 ERROR \(error)")
                        break;
                    }
                }
                if flag == SQLITE_OK {
                    let result = rs.step
                    assert(result == SQLITE_OK || result == SQLITE_DONE || DEBUG == 0, "严重错误并回滚操作,绑定失败\(values)")
                    if result != SQLITE_OK && result != SQLITE_DONE {
                        hasError = true
                        error = lastError
                        break
                    } else {    // <- 否则数据写入成功
                        rs.bindClear()
                        rs.reset()
                    }
                } else {        // <- 否则数据绑定失败开始下一组
                    rs.bindClear()
                }
            }
            
        } else {
            let error = lastError
            hasError = true
        }
        hasError ? rollbackTransaction() : commitTransaction()
        return error
    }

}

// MARK: - SQLiteResultSet
extension SQLite {
    
    // MARK: ResultSet 查询结果集
    class RowSet {
        private var _stmt:COpaquePointer = nil
        //private let columnNames:NSArray
        init (_ stmt:COpaquePointer) {
            _stmt = stmt
            let length = sqlite3_column_count(_stmt);
            var columns:[String] = []
            for i:CInt in 0..<length {
                let name:UnsafePointer<CChar> = sqlite3_column_name(_stmt,i)
                columns.append(String.fromCString(name)!)
            }
            self.columns = columns
            //columnNames = NSArray(array: columns)
        }
        deinit {
            if _stmt != nil {
                sqlite3_finalize(_stmt)
            }
        }
        private let columns:[String]
    }
}


// MARK: - SQLiteBindSet
extension SQLite.RowSet : SQLiteBindSet {
    var bindCount:CInt {
        return sqlite3_bind_parameter_count(_stmt)
    }

    func bindClear() -> CInt {
        return sqlite3_clear_bindings(_stmt)
    }
    // 泛型绑定
    func bindValue<T>(columnValue:T?,index:Int) -> CInt {
        if let v = columnValue {
            switch v {
            case let value as Int:
                return sqlite3_bind_int64(_stmt,CInt(index),CLongLong(value))
            case let value as UInt:
                return sqlite3_bind_int64(_stmt,CInt(index),CLongLong(value))
            case let value as Int8:
                return sqlite3_bind_int(_stmt,CInt(index),CInt(value))
            case let value as UInt8:
                return sqlite3_bind_int(_stmt,CInt(index),CInt(value))
            case let value as Int16:
                return sqlite3_bind_int(_stmt,CInt(index),CInt(value))
            case let value as UInt16:
                return sqlite3_bind_int(_stmt,CInt(index),CInt(value))
            case let value as Int32:
                return sqlite3_bind_int(_stmt,CInt(index),CInt(value))
            case let value as UInt32:
                return sqlite3_bind_int64(_stmt,CInt(index),CLongLong(value))
            case let value as Int64:
                return sqlite3_bind_int64(_stmt,CInt(index),CLongLong(value))
            case let value as UInt64:
                return sqlite3_bind_int64(_stmt,CInt(index),CLongLong(value))
            case let value as Float:
                return sqlite3_bind_double(_stmt,CInt(index),CDouble(value))
            case let value as Double:
                return sqlite3_bind_double(_stmt,CInt(index),CDouble(value))
            case let value as NSDate:
                return sqlite3_bind_double(_stmt,CInt(index),CDouble(value.timeIntervalSince1970))
            case let value as Date:
                return sqlite3_bind_double(_stmt,CInt(index),CDouble(value.timeIntervalSince1970))
            case let value as NSData:
                return sqlite3_bind_data(_stmt,CInt(index),value.bytes,-1,nil)
            case let value as String:
                let string:NSString = value
                return sqlite3_bind_string(_stmt,CInt(index),string.UTF8String,-1,nil)
            default:
                let mirror = reflect(v)
                if mirror.disposition == .Optional {
                    if mirror.count == 0 {
                        return sqlite3_bind_null(_stmt,CInt(index))
                    }
                    return bindValue(mirror[0].1.value, index: index)
                }
                let string:NSString = "\(v)"
                return sqlite3_bind_string(_stmt,CInt(index),string.UTF8String,-1,nil)
            }
        } else {
            return sqlite3_bind_null(_stmt,CInt(index))
        }
    }
}

// MARK: - SQLiteBaseSet
extension SQLite.RowSet : SQLiteBaseSet {
    var step:CInt {
        return sqlite3_step(_stmt)
    }
    var next:Bool {
        return step == SQLITE_ROW
    }
    var row:Int {
        return Int(sqlite3_data_count(_stmt))
    }
    func reset() {
        sqlite3_reset(_stmt)
    }
    func close() {
        sqlite3_finalize(_stmt)
        _stmt = nil
    }
}

// MARK: - SQLiteRowSet
extension SQLite.RowSet : SQLiteResultSet {
    
    
    
    func firstValue() -> Int {
        if next {
            return Int(sqlite3_column_int(_stmt, 0))
        }
        return 0
    }

    func getDictionary() -> [String:Any] {
        var dict:[String:Any] = [:]
        for i in 0..<columns.count {
            let index = CInt(i)
            let type = sqlite3_column_type(_stmt, index);
            let table:UnsafePointer<Int8> = sqlite3_column_table_name(_stmt, index)
            let tableName = String.fromCString(UnsafePointer<CChar>(table))
            println("rs:\(tableName)")
            let key:String = columns[i]
            var value:Any? = nil
            switch type {
            case SQLITE_INTEGER:
                value = Int64(sqlite3_column_int64(_stmt, index))
            case SQLITE_FLOAT:
                value = Double(sqlite3_column_double(_stmt, index))
            case SQLITE_TEXT:
                let text:UnsafePointer<UInt8> = sqlite3_column_text(_stmt, index)
                value = String.fromCString(UnsafePointer<CChar>(text))
            case SQLITE_BLOB:
                let data:UnsafePointer<Void> = sqlite3_column_blob(_stmt, index)
                let size:CInt = sqlite3_column_bytes(_stmt, index)
                value = NSData(bytes:data, length: Int(size))
            case SQLITE_NULL:
                fallthrough     //下降关键字 执行下一 CASE
            default :
                break           //什么都不执行
            }
            dict[key] = value
//            //如果出现重名则
//            if i != columnNames.indexOfObject(key) {
//                //取变量类型
//                //let tableName = String.fromCString(sqlite3_column_table_name(stmt, index))
//                //dict["\(tableName).\(key)"] = value
//                dict["\(key).\(i)"] = value
//            } else {
//                dict[key] = value
//            }
        }
        
        return dict
    }
    func getUInt(columnName:String) -> UInt {
        return UInt(getInt(columnName))
    }
    func getInt(columnName:String) -> Int64 {
        let index = columns.indexOf { $0 == columnName }
        //CInt(columnNames.indexOfObject(columnName))
        if index == NSNotFound {
            return 0
        }
        return Int64(sqlite3_column_int64(_stmt, CInt(index)))
    }
    func getDouble(columnName:String) -> Double {
        let index = columns.indexOf { $0 == columnName }
        if index == NSNotFound {
            return 0
        }
        return Double(sqlite3_column_double(_stmt, CInt(index)))
    }
    func getFloat(columnName:String) -> Float {
        return Float(getDouble(columnName))
    }
    func getString(columnName:String) -> String! {
        let index = columns.indexOf { $0 == columnName }
        if index == NSNotFound {
            return nil
        }
        let result = UnsafePointer<CChar>(sqlite3_column_text(_stmt, CInt(index)))
        return String.fromCString(result)
    }
    func getData(columnName:String) -> NSData! {
        let index = columns.indexOf { $0 == columnName }
        if index == NSNotFound {
            return nil
        }
        let data:UnsafePointer<Void> = sqlite3_column_blob(_stmt, CInt(index))
        let size:CInt = sqlite3_column_bytes(_stmt, CInt(index))
        return NSData(bytes:data, length: Int(size))
    }
    func getDate(columnName:String) -> NSDate! {
        let index = columns.indexOf { $0 == columnName }
        if index == NSNotFound {
            return nil
        }
        let columnType = sqlite3_column_type(_stmt, CInt(index))
        
        switch columnType {
        case SQLITE_INTEGER:
            fallthrough
        case SQLITE_FLOAT:
            let time = sqlite3_column_double(_stmt, CInt(index))
            return NSDate(timeIntervalSinceReferenceDate: time)
        case SQLITE_TEXT:
            let result = UnsafePointer<CChar>(sqlite3_column_text(_stmt, CInt(index)))
            let date = String.fromCString(result)
            let formater = NSDateFormatter()
            formater.dateFormat = "yyyy-MM-dd HH:mm:ss"
            //formater.calendar = NSCalendar.currentCalendar()
            return formater.dateFromString(date!)
        default:
            return nil
        }
        
    }
}


// MARK: - SQLite 其他
extension SQLite {
    
    // MARK: ColumnState 头附加状态
    enum ColumnState : Int, Printable {
        case None = 0
        case ForeignKey                 //外键 SQLite中好像没有约束作用
        case PrimaryKey                 //主键
        case PrimaryKeyAutoincrement    //自动增量主键
        case Autoincrement              //自动增量
        case Unique                     //唯一的
        case Check                      //检查
        case NotNull                    //非空
        
        var description:String {
        switch self {
        case .PrimaryKey :
            return " PRIMARY KEY"
        case .PrimaryKeyAutoincrement :
            return " PRIMARY KEY AUTOINCREMENT"
        case .Autoincrement :
            return " AUTOINCREMENT"
        case .NotNull :
            return " NOT NULL"
        case .Unique :
            return " UNIQUE"
        case .ForeignKey :
            return " FOREIGN KEY"
        case .Check :
            return " CHECK"
        default :
            return ""
            }
        }
        
        var insertMask:Bool {
            switch self {
            case .PrimaryKey :
                return false
            case .PrimaryKeyAutoincrement :
                return true
            case .Autoincrement :
                return true
            case .NotNull :
                return false
            case .Unique :
                return false
            case .ForeignKey :
                return false
            case .Check :
                return false
            default :
                return false
            }
        }
    }
    
    // MARK: ColumnType
    enum ColumnType : Printable{
        
        // INTEGER 1 数值
        case INTEGER
        case INT
        case TINYINT
        case SMALLINT
        case MEDIUMINT
        case BIGINT
        case UNSIGNED_BIG_INT
        case INT2
        case INT8

        // TEXT 2 字符 字符串
        case TEXT               // 2,147,483,647 字符
        case CLOB
        case CHAR(Int)          // 0 - 8000 非 Unicode
        case VARCHAR(Int)       // 0 - 8000 非 Unicode
        case NCHAR(Int)         // 0 - 4000 Unicode
        case NVARCHAR(Int)      // 0 - 4000 Unicode
        case CHARACTER(Int)
        case NATIVE_CHARACTER(Int)
        case VARYING_CHARACTER(Int)
        
        // NONE 3 
        case BLOB
        
        // REAL 4 浮点数
        case REAL
        case FLOAT
        case DOUBLE
        case DOUBLE_PRECISION
        
        // NUMERIC 5 
        case NUMERIC
        case DECIMAL (Int,Int)
        case BOOLEAN
        case DATE
        case DATETIME
        case TIMESTAMP
        
        var description:String {
            switch self {
                // INTEGER 1 数值
            case .INTEGER:
                return "INTEGER"
            case .INT:
                return "INT"
            case .TINYINT:
                return "TINYINT"
            case .SMALLINT:
                return "SMALLINT"
            case .MEDIUMINT:
                return "MEDIUMINT"
            case .BIGINT:
                return "BIGINT"
            case .UNSIGNED_BIG_INT:
                return "UNSIGNED BIG INT"
            case .INT2:
                return "INT2"
            case .INT8:
                return "INT8"

                // TEXT 2 字符 字符串
            case .TEXT:               // 2,147,483,647 字符
                return "TEXT"
            case .CLOB:
                return "CLOB"
            case .CHAR(let num):          // 0 - 8000 非 Unicode
                return "CHAR(\(num))"
            case .VARCHAR(let num):       // 0 - 8000 非 Unicode
                return "VARCHAR(\(num))"
            case .NCHAR(let num):         // 0 - 4000 Unicode
                return "NCHAR(\(num))"
            case .NVARCHAR(let num):      // 0 - 4000 Unicode
                return "NVARCHAR(\(num))"
            case .CHARACTER(let num):
                return "CHARACTER(\(num))"
            case .NATIVE_CHARACTER(let num):
                return "NATIVE CHARACTER(\(num))"
            case .VARYING_CHARACTER(let num):
                return "VARYING CHARACTER(\(num))"
                
                // NONE 3
            case .BLOB:
                return "BLOB"
                
                // FLOAT 4 浮点数
            case .REAL:
                return "REAL"
            case .FLOAT:
                return "FLOAT"
            case .DOUBLE:
                return "DOUBLE"
            case .DOUBLE_PRECISION:
                return "DOUBLE PRECISION"
                
                // NUMERIC 5
            case .NUMERIC:
                return "NUMERIC"
            case .DECIMAL(let num, let length):
                return "DECIMAL(\(num),\(length))"
            case .BOOLEAN:
                return "BOOLEAN"
            case .DATE:
                return "DATE"
            case .DATETIME:
                return "DATETIME"
            case .TIMESTAMP:
                return "TIMESTAMP"
            }
        }
    }
    // <- 自定义类型枚举结束
}



