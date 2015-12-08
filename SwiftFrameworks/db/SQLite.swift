//
//  SQLite.swift
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

import Foundation
//
//@asmname("sqlite3_exec")
//func sqlite3_execute(COpaquePointer,UnsafePointer<CChar>,CFunctionPointer<Void>,COpaquePointer,AutoreleasingUnsafeMutablePointer<UnsafePointer<CChar>>) -> CInt
//
//@asmname("sqlite3_bind_blob")
//func sqlite3_bind_data(COpaquePointer,CInt,UnsafePointer<Void>,CInt,COpaquePointer) -> CInt
//
//@asmname("sqlite3_bind_text")
//func sqlite3_bind_string(COpaquePointer,CInt,UnsafePointer<CChar>,CInt,COpaquePointer) -> CInt

//@asmname("sqlite3_column_table_name") func sqlite3_column_table_title(COpaquePointer,CInt) -> UnsafePointer<UInt8>


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
    func getInt64(columnName:String) -> Int64
    func getInt(columnName:String) -> Int
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
    // 泛型绑定 自动递归拆包可选值
    func bindValue<T>(columnValue:T?,index:Int) -> CInt
}

protocol SQLiteDataBase : CustomReflectable {
    // 返回纯属性所代表 字段(column)的类型 和 参数
    static func tableColumnTypes() -> [(SQLColumnName, SQLColumnType, SQLColumnState)]
    
    func customMirror() -> Mirror

}

extension SQLiteDataBase {
    func customMirror() -> Mirror {
        return Mirror(reflecting: self)
    }
}


// MARK: - SQLiteProtocol 基本
protocol SQLiteBase {
    // 执行 SQL 语句
    func execSQL(sql:String) -> CInt
    // 执行 SQL 语句
    func executeSQL(sql:String) throws
    // 执行 SQL 查询语句
    func querySQL(sql:String) throws -> SQLiteResultSet
    // 获取最后出错信息
    var lastError:NSError { get }
    // 获取最后一次执行的SQL语句
    var lastSQL:String { get }
}

// MARK: - SQLiteProtocol 版本
protocol SQLiteVersion {
    var version:Int { get }
}

// MARK: - SQLiteProtocol 索引
protocol SQLiteCreateIndex {
    func create(index indexName:String, on tableName:String, columns columnNames:String...) throws
    func createUnique(index indexName:String, on tableName:String, columns columnNames:String...) throws
}

// MARK: - SQLiteProtocol 迁移
protocol SQLiteMove {
    // newTableName 必须不存在,系统自动创建
    func select(columns:[String]?, into newTableName:String, from oldTableName:String, Where:String?) throws
    func insert(into newTableName:String, select columns:[String:String]?, from oldTableName:String, Where:String?) throws
    func insertOrReplace(into newTableName:String, select columns:[String:String]?, from oldTableName:String, Where:String?) throws
    func insertOrIgnore(into newTableName:String, select columns:[String:String]?, from oldTableName:String, Where:String?) throws
}

// MARK: - SQLiteProtocol 修改
protocol SQLiteAlter {
    // 修改数据表名
    func alterTable(oldTableName:String, renameTo newTableName:String) throws
    // 修改数据表 列名
    func alterTable(tableName:String, renameColumn oldColumnName:String, to newColumnName:String) throws
    // 修改数据表 列类型
    func alterTable(tableName:String, modify columnName:String, _ columnType:SQLColumnType) throws
    // 修改数据表 插入列
    func alterTable(tableName:String, add columnName:String, _ columnType:SQLColumnType) throws
    // 修改数据表 删除列
    func alterTable(tableName:String, dropColumn columnName:String) throws
}

// MARK: - SQLiteProtocol 事务
protocol SQLiteQueue {
    // MARK: 开启事务 BEGIN TRANSACTION
    func beginTransaction() -> CInt
    // MARK: 提交事务 COMMIT TRANSACTION
    func commitTransaction() -> CInt
    // MARK: 回滚事务 ROLLBACK TRANSACTION
    func rollbackTransaction() -> CInt
}

// MARK: - SQLiteProtocol 创建
protocol SQLiteCreate {
    // 通过一个
    func createTableIfNotExists(tableName:String, params:[(SQLColumnName,SQLColumnType,SQLColumnState)]) throws
    
    // 通过一个类来创建表 类必须实现 SQLiteDataBase 协议 (推荐)
    func createTableIfNotExists<T : SQLiteDataBase>(tableName:String, withType:T.Type) throws
}

// MARK: - SQLiteProtocol 改变
protocol SQLiteUpdate {
    func update(tableName:String, set params:[String:Any], Where:String?) throws
}

// MARK: - SQLiteProtocol 增加
protocol SQLiteInsert {
    func insert(into tableName:String, values:Any...) throws -> Int
    // 单条插入全部字段
    func insert(into tableName:String, values:Any...) -> Error
    func insertOrReplace(into tableName:String, values:Any...) -> Error
    
    // 批量插入
    func insertOrReplace<T : SQLiteDataBase>(into tableName:String, rows:[T]) -> Error
    func insertOrReplace(into tableName:String, _ columns:[String], values:(Int) -> [String:Any]?) -> Error
    //func insert(into tableName:String, params:[SQLite.ColumnValue]) -> Error
}

// MARK: - SQLiteProtocol 删除
protocol SQLiteDelete {
    func delete(from tableName:String, Where:String?) throws
}

// MARK: - SQLiteProtocol 查询
protocol SQLiteSelect {
    //查询数量
    func select(count columns:[String]?, from tableName:String, Where:String?) throws -> Int
    
    //普通查询
    func select(columns:[String]?, from tableName:String, Where:String?) throws -> SQLiteResultSet
    
    //联合查询
    func select(columns:[String]?, from tables:[String:SQLTableName], Where:String?) throws -> SQLiteResultSet
}

typealias SQLColumnName = String
typealias SQLTableName = String

// MARK: - SQLite 主函数
class SQLite {
    
    typealias OnUpgradeFunc = (db:SQLiteHandle, oldVersion:Int, newVersion:Int) -> Bool

    let version:UInt
    let path:String
    
    private let onUpgrade:OnUpgradeFunc
    
    // 适合 OS X 和 iOS
    required init(path:String, version: UInt = 1, onUpgrade:OnUpgradeFunc) {
        self.path = path
        self.onUpgrade = onUpgrade
        self.version = version
        assert(version > 0, "version must more than zero")
        setVersion(version)
    }
    // 适合 iOS
    convenience init(name:String, version: UInt = 1, onUpgrade:OnUpgradeFunc) {
        let docDir = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString
        self.init(path:docDir.stringByAppendingPathComponent(name),version:version,onUpgrade:onUpgrade)
    }
    
    func open() throws -> SQLiteHandle {
        var handle:COpaquePointer = nil
        let dbPath:NSString = path
        let dirPath = dbPath.stringByDeletingLastPathComponent
        
        var isDir:ObjCBool = false

        if !NSFileManager.defaultManager().fileExistsAtPath(dirPath, isDirectory: &isDir) || isDir {
            do {
                try NSFileManager.defaultManager().createDirectoryAtPath(dirPath, withIntermediateDirectories: true, attributes: nil)
            } catch let error as NSError {
                throw error
            }
        }
        let result = sqlite3_open(dbPath.UTF8String, &handle)
        if result != SQLITE_OK {
            let errorCode = sqlite3_errcode(handle)
            let errorDescription = String.fromCString(sqlite3_errmsg(handle)) ?? ""
            sqlite3_close(handle)
            throw NSError(domain: errorDescription, code: Int(errorCode), userInfo: ["path":path])
        }
        return SQLite.Handle(handle: handle)
    }
    
    private func setVersion(version: UInt) {
        // 打开数据库
        guard let sqlHandle = try? open() else {
            return
        }
        //assert(error == .OK, "无法打开数据库")
        let handle = sqlHandle as! SQLite.Handle
        
        let newVersion = Int(version)
        let oldVersion = handle.version
        if oldVersion != newVersion {
            // 如果变化则调用更新函数来更新字段
            if onUpgrade(db: handle, oldVersion: oldVersion, newVersion: newVersion) {
                handle.version = newVersion
            }
        }
    }

//    deinit{
//        println("SQLite 已释放")
//    }
    
}

// MARK: - 数据库操作句柄
typealias SQLiteHandle = protocol<SQLiteBase, SQLiteCreate, SQLiteCreateIndex, SQLiteQueue, SQLiteUpdate, SQLiteDelete, SQLiteSelect, SQLiteInsert, SQLiteAlter, SQLiteMove, SQLiteVersion>

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
            //println("sqliteHandle 已释放")
        }
        private var _lastSQL:String = ""
    }
}

// MARK: - SQLiteHandle 基本执行
extension SQLite.Handle : SQLiteBase {
    
    func pragmaSQL(sql:String) -> CInt {
        return sqlite3_exec(_handle,sql,nil,nil,nil)
    }
    
    func execSQL(sql:String) -> CInt {
        _lastSQL = sql
        return sqlite3_exec(_handle,sql,nil,nil,nil)
    }
    
    //执行 SQL 语句
    func executeSQL(sql:String) throws {
        if SQLITE_OK != execSQL(sql) {
            throw lastError
        }
    }
    
    //执行 SQL 查询语句
    func querySQL(sql:String) throws -> SQLiteResultSet {
        //println("SQL -> \(SQL)")
        _lastSQL = sql
        var stmt:COpaquePointer = nil
        if SQLITE_OK != sqlite3_prepare_v2(_handle, sql, -1, &stmt, nil) {
            sqlite3_finalize(stmt)
            throw lastError
        }
        return SQLite.RowSet(stmt);
    }
    
    // 获取最后出错信息
    var lastError:ErrorType {
        let errorCode = sqlite3_errcode(_handle)
        if let error = SQLite.Error(rawValue: errorCode) {
            return error
        }
        let errorDescription = String.fromCString(sqlite3_errmsg(_handle)) ?? ""
        return NSError(domain: errorDescription, code: Int(errorCode), userInfo: nil)
    }
    
    var lastSQL:String { return _lastSQL }
}

// MARK: - SQLiteHandle 版本
extension SQLite.Handle : SQLiteVersion {
    var version:Int {
        get {
            if let rs = try? querySQL("PRAGMA user_version") {
                return rs.firstValue()
            }
            return -1
        }
        set {
            let result = pragmaSQL("PRAGMA user_version = \(newValue)")
            assert(result == SQLITE_OK && DEBUG == 1, "set version error:\(lastError)")
        }

    }
}

// MARK: - SQLiteHandle 数据迁移
extension SQLite.Handle : SQLiteMove {
    // newTableName 必须不存在,系统自动创建
    func select(columns:[String]?, into newTableName:String, from oldTableName:String, Where:String?) throws {
        let columnNames = columns?.componentsJoinedByString(", ") ?? "*"
        var sql = "SELECT \(columnNames) INTO \(newTableName) FROM \(oldTableName)"
        if let condition = Where {
            sql.appendContentsOf(" WHERE \(condition)")
        }
        if SQLITE_OK != execSQL(sql) { throw lastError }
    }
    
    // oldTableName 必须已存在
    func insert(or:String? = nil, into newTableName:String, select columns:[String:String]?, from oldTableName:String, Where:String?) -> CInt {
        let columnNames:String = columns?.keys.componentsJoinedByString(", ") ?? "*"
        let oldColumnNames:String = columns?.values.componentsJoinedByString(", ") ?? "*"
        var orString = or ?? ""
        orString = orString.isEmpty ? "" : " \(orString)"
        var sql = "INSERT\(orString) INTO \(newTableName)(\(columnNames)) SELECT \(oldColumnNames) FROM \(oldTableName)"
        if let condition = Where {
            sql.appendContentsOf(" WHERE \(condition)")
        }
        return execSQL(sql)
    }
    // oldTableName 必须已存在
    func insert(into newTableName:String, select columns:[String:String]?, from oldTableName:String, Where:String?) throws {
        if SQLITE_OK != insert(nil, into: newTableName, select: columns, from: oldTableName, Where: Where) { throw lastError }
    }
    func insertOrReplace(into newTableName:String, select columns:[String:String]?, from oldTableName:String, Where:String?) throws {
        if SQLITE_OK != insert("OR REPLACE", into: newTableName, select: columns, from: oldTableName, Where: Where) { throw lastError }
    }
    func insertOrIgnore(into newTableName:String, select columns:[String:String]?, from oldTableName:String, Where:String?) throws {
        if SQLITE_OK != insert("OR IGNORE", into: newTableName, select: columns, from: oldTableName, Where: Where) { throw lastError }

    }
}

// MARK: - SQLiteHandle 修改表
extension SQLite.Handle : SQLiteAlter {
    // 修改数据表名
    func alterTable(oldTableName:String, renameTo newTableName:String) throws {
        if SQLITE_OK != execSQL("ALTER TABLE \(oldTableName) RENAME TO \(newTableName)") { throw lastError }
    }
    // 修改数据表 列名
    func alterTable(tableName:String, renameColumn oldColumnName:String, to newColumnName:String) throws {
        if SQLITE_OK != execSQL("ALTER TABLE \(tableName) RENAME COLUMN \(oldColumnName) TO \(newColumnName)") { throw lastError }
    }
    // 修改数据表 列类型
    func alterTable(tableName:String, modify columnName:String, _ columnType:SQLColumnType) throws {
        if SQLITE_OK != execSQL("ALTER TABLE \(tableName) MODIFY \(columnName) \(columnType)") { throw lastError }
    }
    // 修改数据表 插入列
    func alterTable(tableName:String, add columnName:String, _ columnType:SQLColumnType) throws {
        if SQLITE_OK != execSQL("ALTER TABLE \(tableName) ADD \(columnName) \(columnType)") { throw lastError }
    }
    // 修改数据表 删除列
    func alterTable(tableName:String, dropColumn columnName:String) throws {
        if SQLITE_OK != execSQL("ALTER TABLE \(tableName) DROP COLUMN \(columnName)") { throw lastError }
    }
}

// MARK: - SQLiteHandle 创建表
extension SQLite.Handle : SQLiteCreate {
    
    func createTableIfNotExists(tableName:String, params:[(SQLColumnName,SQLColumnType,SQLColumnState)]) throws {
        var paramString = ""
        for (name,type,state) in params {
            if !paramString.isEmpty {
                paramString += ", "
            }
            paramString += "\"\(name)\" \(type)\(state)"
        }
        let sql = "CREATE TABLE IF NOT EXISTS \"\(tableName)\" (\(paramString))"
        if SQLITE_OK != execSQL(sql) { throw lastError }
    }
    
    func createTableIfNotExists<T : SQLiteDataBase>(tableName:String, withType:T.Type) throws {
        var paramString = ""
        
        let params = T.tableColumnTypes()
        assert(params.count > 0 || DEBUG != 1, "模板类型没有返回表结构参数")
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
        if SQLITE_OK != execSQL(sql) { throw lastError }

    }
    
}

// MARK: - SQLiteHandle 创建索引
extension SQLite.Handle : SQLiteCreateIndex {
    func create(index indexName:String, on tableName:String, columns columnNames:String...) throws {
        if columnNames.count == 0 {
            throw NSError(domain: "[\(tableName)]没有指定任何索引字段", code: 0, userInfo: ["index":indexName])
        }
        let names = columnNames.componentsJoinedByString(", ")
        let sql = "CREATE INDEX \(indexName) ON \(tableName)(\(names))"
        if SQLITE_OK != execSQL(sql) { throw lastError }
    }
    func createUnique(index indexName:String, on tableName:String, columns columnNames:String...) throws {
        if columnNames.count == 0 {
            throw NSError(domain: "[\(tableName)]没有指定任何索引字段", code: 0, userInfo: ["index":indexName])
        }
        let names = columnNames.componentsJoinedByString(", ")
        let sql = "CREATE UNIQUE INDEX \(indexName) ON \(tableName)(\(names))"
        if SQLITE_OK != execSQL(sql) { throw lastError }
    }
}

// MARK: - SQLiteHandle 事务
extension SQLite.Handle : SQLiteQueue {
    // MARK: 开启事务 BEGIN TRANSACTION
    func beginTransaction() -> CInt {
        return pragmaSQL("BEGIN TRANSACTION")
    }
    // MARK: 提交事务 COMMIT TRANSACTION
    func commitTransaction() -> CInt {
        return pragmaSQL("COMMIT TRANSACTION")
    }
    // MARK: 回滚事务 ROLLBACK TRANSACTION
    func rollbackTransaction() -> CInt {
        return pragmaSQL("ROLLBACK TRANSACTION")
    }
}

// MARK: - SQLiteHandle 更新
extension SQLite.Handle : SQLiteUpdate {
    func update(tableName:String, set params:[String:Any], Where:String?) throws {
        var paramString = ""
        for (key,value) in params {
            if !paramString.isEmpty {
                paramString += " AND "
            }
            paramString += "\(key) = \"\(value)\""
        }
        if let condition = Where {
            if !condition.isEmpty {
                paramString += " WHERE \(condition)"
            }
        }
        let sql = "UPDATE \(tableName) SET \(paramString)"
        if SQLITE_OK != execSQL(sql) { throw lastError }
    }
}

// MARK: - SQLiteHandle 删除
extension SQLite.Handle : SQLiteDelete {
    // 删除
    func delete(from tableName:String, Where:String?) throws {
        var sql = "DELETE FROM \(tableName)"
        if let condition = Where {
            sql.appendContentsOf(" WHERE \(condition)")
        }
        if SQLITE_OK != execSQL(sql) { throw lastError }
    }
}

// MARK: - SQLiteHandle 查询
extension SQLite.Handle : SQLiteSelect {
    // 查询数量
    func select(count columns:[String]?, from tableName:String, Where:String?) throws -> Int {
        let columnNames = columns?.componentsJoinedByString(", ") ?? "*"
        var sql = "SELECT count(\(columnNames)) FROM \(tableName)"
        if let end = Where {
            sql += " WHERE \(end)"
        }
        if let resultSet = try? querySQL(sql) {
            return resultSet.firstValue()
        }
        throw lastError
    }
    
    // 普通查询
    func select(columns:[String]?, from tableName:String, Where:String?) throws -> SQLiteResultSet {
        let columnNames = columns?.componentsJoinedByString(", ") ?? "*"
        var sql = "SELECT \(columnNames) FROM \(tableName)"
        if let condition = Where {
            sql.appendContentsOf(" WHERE \(condition)")
        }
        guard let resultSet = try? querySQL(sql) else {
            throw lastError
        }
        return resultSet
    }
    
    // 联合查询
    func select(columns:[String]?, from tables:[String:SQLTableName], Where:String?) throws -> SQLiteResultSet {
        let columnNames = columns?.componentsJoinedByString(", ") ?? "*"
        let paramString = tables.componentsJoinedByString(",") { "\($0.1) \($0.0)" }
        var sql = "SELECT \(columnNames) FROM \(paramString)"
        if let condition = Where {
            sql.appendContentsOf(" WHERE \(condition)")
        }
        guard let resultSet = try? querySQL(sql) else {
            throw lastError
        }
        return resultSet
    }
}

// MARK: - SQLiteHandle 插入
extension SQLite.Handle : SQLiteInsert {
    
    func insert(or:String?, into tableName:String, columns:[String]? = nil, values:[Any]) throws -> SQLiteBindSet {
        let orString = or?.joinIn(" ", "")
        let columnNames = columns?.componentsJoinedByString(", ").joinIn("(", ")") ?? ""
        var length = values.count
        if length == 0 {
            let last = _lastSQL
            if let resultSet = try? querySQL("PRAGMA table_info(\"\(tableName)\")") {
                while resultSet.next { length++ }
            }
            _lastSQL = last
        }
        let values = [String](count: length, repeatedValue: "?").componentsJoinedByString(", ")
        let sql = "INSERT\(orString) INTO \(tableName)\(columnNames) VALUES(\(values))"
        guard let resultSet = try? querySQL(sql) else {
            throw lastError
        }
        return resultSet as! SQLite.RowSet
    }
    
    
    func insert(or:String? = nil, into tableName:String, columns:[String]? = nil, values:Any...) throws -> Int {
        guard let bindSet:SQLiteBindSet = try? insert(or, into: tableName, columns: columns, values: values) else {
            throw lastError
        }
        var flag:CInt = SQLITE_OK
        for var i:Int = 0; i<values.count; i++ {
            flag = bindSet.bindValue(values[i], index: i + 1)
            assert(flag == SQLITE_OK || flag == SQLITE_ROW || DEBUG != 1, "绑定[\(i)]失败 value=\(values[i])")
            if flag != SQLITE_OK && flag != SQLITE_ROW { break }
        }
        if flag == SQLITE_OK || flag == SQLITE_ROW {
            flag = bindSet.step
            if flag == SQLITE_OK || flag == SQLITE_DONE {
                return Int(truncatingBitPattern: sqlite3_last_insert_rowid(_handle))
            }
        }
        throw NSError(domain: "Insert data error", code: Int(flag), userInfo: nil)
        
    }
    func insertOrReplace(into tableName:String, columns:[String]?, values:Any...) throws -> Int {
        guard let _ = try? insert("OR REPLACE", into: tableName, columns: columns, values: values) else {
            throw lastError
        }
        return Int(truncatingBitPattern: sqlite3_last_insert_rowid(_handle))
    }
    func insertOrIgnore(into tableName:String, columns:[String]?, values:Any...) throws -> Int {
        guard let _ = try? insert("OR IGLONE", into: tableName, columns: columns, values: values) else {
            throw lastError
        }
        return Int(truncatingBitPattern: sqlite3_last_insert_rowid(_handle))
    }

    // 单条插入全部字段
    private func insertValues(otherKeywords:String, into tableName:String, values:[Any]) -> Error {
        var valueString = ""
        for value in values {
            if !valueString.isEmpty {
                valueString += ", "
            }
            if value is String {
                if (value as! String) == "Null" {
                    valueString += "Null"
                } else {
                    valueString += "\"\(value)\""
                }
            } else {
                valueString += "\(value)"
            }
        }
        let sql = "INSERT\(otherKeywords) INTO \(tableName) VALUES(\(valueString))"
        return executeSQL(sql)
    }
    func insert(into tableName:String, values:Any...) -> Error {
        return insertValues("", into: tableName, values: values)
    }
    
    func insertOrReplace(into tableName:String, values:Any...) -> Error {
        return insertValues(" OR REPLACE", into: tableName, values: values)
    }

    // 单条插入部分字段
    func insertOrReplace(into tableName:String, params:[String:Any]) -> Error {
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
/*
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
*/
    
    func insertOrReplace<T : SQLiteDataBase>(into tableName:String, rows:[T]) -> Error {
        let params = T.tableColumnTypes()
        var columns:[String] = []
        #if DEBUG
        assert(params.count > 0, "模板类型没有返回表结构参数")
        #endif
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
        
        var error:Error = .OK
        var hasError = false

        let SQL = "INSERT OR REPLACE INTO \(tableName) (\(keyString)) values(\(valueString))"
        if let rs:SQLiteBindSet = querySQL(SQL) as! SQLite.RowSet? {
            //let length = rs.bindCount
            for row in rows {
                let mirror = _reflect(row)
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
                    #if DEBUG
                    assert(flag == SQLITE_OK, "绑定[\(key)]失败 value=\(row)")
                    #endif
                    if flag != SQLITE_OK {
                        error = lastError //String.fromCString(sqlite3_errmsg(handle))
                        //println("错误并跳过本组数据,因为给字段[\(key)]绑定值[\(row)]失败 ERROR \(error)")
                        break;
                    }
                }
                if flag == SQLITE_OK {
                    let result = rs.step
                    
                    #if DEBUG
                    assert(result == SQLITE_OK || result == SQLITE_DONE, "严重错误并回滚操作,绑定失败\(row)")
                    #endif

                    if result != SQLITE_OK && result != SQLITE_DONE {
                        hasError = true
                        error = lastError
                        break
                    } else {    // <- 否则数据写入成功
                        rs.reset()
                    }
                } else {        // <- 否则数据绑定失败开始下一组
                    rs.bindClear()
                }
            }
        } else {
            error = lastError
            hasError = true
        }
        hasError ? rollbackTransaction() : commitTransaction()
        return error
    }
    
    func insertOrReplace(into tableName:String, _ columns:[String], values:(Int) -> [String:Any]?) -> Error {
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
        
        var error:Error = .OK
        var hasError = false
        //获取插入句柄绑定
        let SQL = "INSERT OR REPLACE INTO \(tableName) (\(keyString)) values(\(valueString))"
        if let rs:SQLiteBindSet = querySQL(SQL) as! SQLite.RowSet? {
            //let length = rs.bindCount
            
            var i = 0
            while let params = values(i++) {
                var flag:CInt = 0
                for index in 1...columns.count {
                    let key = columns[index-1]
                    flag = rs.bindValue(params[key], index: index)
                    #if DEBUG
                    assert(flag == SQLITE_OK, "绑定[\(key)]失败 value=\(params[key])")
                    #endif

                    if flag != SQLITE_OK {
                        error = lastError 
                        //println("错误并跳过本组数据,因为给字段[\(key)]绑定值[\(values)]失败 ERROR \(error)")
                        break;
                    }
                }
                if flag == SQLITE_OK {
                    let result = rs.step
                    #if DEBUG
                    assert(result == SQLITE_OK || result == SQLITE_DONE, "严重错误并回滚操作,绑定失败\(params)")
                    #endif
                    if result != SQLITE_OK && result != SQLITE_DONE {
                        hasError = true
                        error = lastError
                        break
                    } else {    // <- 否则数据写入成功
                        rs.reset()
                    }
                } else {        // <- 否则数据绑定失败开始下一组
                    rs.bindClear()
                }
            }
            
        } else {
            error = lastError
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
        init (_ stmt:COpaquePointer) {
            _stmt = stmt
            let length = sqlite3_column_count(_stmt);
            var columns:[String] = []
            for i:CInt in 0..<length {
                let name:UnsafePointer<CChar> = sqlite3_column_name(_stmt,i)
                columns.append(String.fromCString(name)!)
            }
            self.columns = columns
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
            case let value as String:
                let string:NSString = value
                return sqlite3_bind_text(_stmt,CInt(index),string.UTF8String,-1,nil)
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
                return sqlite3_bind_blob(_stmt,CInt(index),value.bytes,-1,nil)
            default:
                let mirror = _reflect(v)
                if mirror.disposition == .Optional {
                    if mirror.count == 0 {
                        return sqlite3_bind_null(_stmt,CInt(index))
                    }
                    return bindValue(mirror[0].1.value, index: index)
                }
                let string:NSString = "\(v)"
                return sqlite3_bind_text(_stmt,CInt(index),string.UTF8String,-1,nil)
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
            //let table:UnsafePointer<Int8> = sqlite3_column_table_name(_stmt, index)
            //let tableName = String.fromCString(UnsafePointer<CChar>(table))
            //println("rs:\(tableName)")
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
        return UInt(truncatingBitPattern: getInt64(columnName))
    }
    func getInt(columnName:String) -> Int {
        return Int(truncatingBitPattern: getInt64(columnName))
    }
    func getInt64(columnName:String) -> Int64 {
        guard let index = columns.indexOf({ $0 == columnName }) else {
            return 0
        }
        return sqlite3_column_int64(_stmt, CInt(index))
    }
    func getDouble(columnName:String) -> Double {
        guard let index = columns.indexOf({ $0 == columnName }) else {
            return 0
        }
        return sqlite3_column_double(_stmt, CInt(index))
    }
    func getFloat(columnName:String) -> Float {
        return Float(getDouble(columnName))
    }
    func getString(columnName:String) -> String! {
        guard let index = columns.indexOf({ $0 == columnName }) else {
            return nil
        }
        let result = sqlite3_column_text(_stmt, CInt(index))
        return String.fromCString(UnsafePointer<CChar>(result))
    }
    func getData(columnName:String) -> NSData! {
        guard let index = columns.indexOf({ $0 == columnName }) else {
            return nil
        }
        let data:UnsafePointer<Void> = sqlite3_column_blob(_stmt, CInt(index))
        let size:CInt = sqlite3_column_bytes(_stmt, CInt(index))
        return NSData(bytes:data, length: Int(size))
    }
    func getDate(columnName:String) -> NSDate! {
        guard let index = columns.indexOf({ $0 == columnName }) else {
            return nil
        }
        let columnType = sqlite3_column_type(_stmt, CInt(index))
        
        switch columnType {
        case SQLITE_INTEGER:
            fallthrough
        case SQLITE_FLOAT:
            let time = sqlite3_column_double(_stmt, CInt(index))
            return NSDate(timeIntervalSince1970: time)
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
// MARK: ColumnState 头附加状态
enum SQLColumnState : Int, CustomStringConvertible {
    case None = 0
    //case ForeignKey                 //外键 SQLite中好像没有约束作用,创建也会失败
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
        //case .ForeignKey :
        //    return " FOREIGN KEY"
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
        //case .ForeignKey :
        //    return false
        case .Check :
            return false
        default :
            return false
        }
    }
}

// MARK: ColumnType
enum SQLColumnType : CustomStringConvertible{
    
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
            SQLITE_OK
            return "TIMESTAMP"
        }
    }
}

extension SQLite {
    
    enum Error : CInt, CustomStringConvertible, CustomDebugStringConvertible, ErrorType {
        case OK         =  0//SQLITE_OK         Successful result
        case ERROR      =  1//SQLITE_ERROR      SQL error or missing database
        case INTERNAL   =  2//SQLITE_INTERNAL   Internal logic error in SQLite
        case PERM       =  3//SQLITE_PERM       Access permission denied
        case ABORT      =  4//SQLITE_ABORT      Callback routine requested an abort
        case BUSY       =  5//SQLITE_BUSY       The database file is locked
        case LOCKED     =  6//SQLITE_LOCKED     A table in the database is locked
        case NOMEM      =  7//SQLITE_NOMEM      A malloc() failed
        case READONLY   =  8//SQLITE_READONLY   Attempt to write a readonly database
        case INTERRUPT  =  9//SQLITE_INTERRUPT  Operation terminated by sqlite3_interrupt()
        case IOERR      = 10//SQLITE_IOERR      Some kind of disk I/O error occurred
        case CORRUPT    = 11//SQLITE_CORRUPT    The database disk image is malformed
        case NOTFOUND   = 12//SQLITE_NOTFOUND   Unknown opcode in sqlite3_file_control()
        case FULL       = 13//SQLITE_FULL       Insertion failed because database is full
        case CANTOPEN   = 14//SQLITE_CANTOPEN   Unable to open the database file
        case PROTOCOL   = 15//SQLITE_PROTOCOL   Database lock protocol error
        case EMPTY      = 16//SQLITE_EMPTY      Database is empty
        case SCHEMA     = 17//SQLITE_SCHEMA     The database schema changed
        case TOOBIG     = 18//SQLITE_TOOBIG     String or BLOB exceeds size limit
        case CONSTRAINT = 19//SQLITE_CONSTRAINT Abort due to constraint violation
        case MISMATCH   = 20//SQLITE_MISMATCH   Data type mismatch
        case MISUSE     = 21//SQLITE_MISUSE     Library used incorrectly
        case NOLFS      = 22//SQLITE_NOLFS      Uses OS features not supported on host
        case AUTH       = 23//SQLITE_AUTH       Authorization denied
        case FORMAT     = 24//SQLITE_FORMAT     Auxiliary database format error
        case RANGE      = 25//SQLITE_RANGE      2nd parameter to sqlite3_bind out of range
        case NOTADB     = 26//SQLITE_NOTADB     File opened that is not a database file
        case NOTICE     = 27//SQLITE_NOTICE     Notifications from sqlite3_log()
        case WARNING    = 28//SQLITE_WARNING    Warnings from sqlite3_log()
        case ROW       = 100//SQLITE_ROW        sqlite3_step() has another row ready
        case DONE      = 101//SQLITE_DONE       sqlite3_step() has finished executing
        
        var description: String {
            switch NSLocale.currentLocale().localeIdentifier {
            case NSCalendarIdentifierChinese: return chineseDescription
            default: return defaultDescription
            }
        }
        
        private var chineseDescription:String {
            switch self {
            case .OK          : return "操作成功"
            case .ERROR       : return "SQL 语句错误 或 数据丢失"
            case .INTERNAL    : return "SQLite 内部逻辑错误"
            case .PERM        : return "拒绝存取"
            case .ABORT       : return "回调函数请求取消操作"
            case .BUSY        : return "数据库被他人使用(已锁定)"
            case .LOCKED      : return "此表被其他人使用(已锁定)"
            case .NOMEM       : return "内存不足"
            case .READONLY    : return "不能在只读模式下写入数据库"
            case .INTERRUPT   : return "操作被 sqlite3_interrupt() 终止"
            case .IOERR       : return "磁盘 I/O 读写发生异常"
            case .CORRUPT     : return "数据库磁盘镜像损坏"
            case .NOTFOUND    : return "sqlite3_file_control() 找不到文件"
            case .FULL        : return "数据库已满，插入失败"
            case .CANTOPEN    : return "无法打开数据库文件"
            case .PROTOCOL    : return "数据库接口锁定"
            case .EMPTY       : return "数据库是空的"
            case .SCHEMA      : return "数据库 schema 改变"
            case .TOOBIG      : return "String 或 BLOB 大小超出限制"
            case .CONSTRAINT  : return "违反规则强行中止"
            case .MISMATCH    : return "数据类型不当"
            case .MISUSE      : return "库Library 使用不当"
            case .NOLFS       : return "系统 host 不支持"
            case .AUTH        : return "授权失败"
            case .FORMAT      : return "数据库格式化错误"
            case .RANGE       : return "sqlite3_bind 第二个参数索引超出范围"
            case .NOTADB      : return "文件并非数据库文件"
            case .NOTICE      : return "sqlite3_log() 通知更新"
            case .WARNING     : return "sqlite3_log() 警告更新"
            case .ROW         : return "sqlite3_step() 另有一行数据已经就绪"
            case .DONE        : return "sqlite3_step() 执行成功"
            }
        }
        
        private var defaultDescription:String {
            switch self {
            case .OK          : return "Successful result"
            case .ERROR       : return "SQL error or missing database"
            case .INTERNAL    : return "Internal logic error in SQLite"
            case .PERM        : return "Access permission denied"
            case .ABORT       : return "Callback routine requested an abort"
            case .BUSY        : return "The database file is locked"
            case .LOCKED      : return "A table in the database is locked"
            case .NOMEM       : return "A malloc() failed"
            case .READONLY    : return "Attempt to write a readonly database"
            case .INTERRUPT   : return "Operation terminated by sqlite3_interrupt()"
            case .IOERR       : return "Some kind of disk I/O error occurred"
            case .CORRUPT     : return "The database disk image is malformed"
            case .NOTFOUND    : return "Unknown opcode in sqlite3_file_control()"
            case .FULL        : return "Insertion failed because database is full"
            case .CANTOPEN    : return "Unable to open the database file"
            case .PROTOCOL    : return "Database lock protocol error"
            case .EMPTY       : return "Database is empty"
            case .SCHEMA      : return "The database schema changed"
            case .TOOBIG      : return "String or BLOB exceeds size limit"
            case .CONSTRAINT  : return "Abort due to constraint violation"
            case .MISMATCH    : return "Data type mismatch"
            case .MISUSE      : return "Library used incorrectly"
            case .NOLFS       : return "Uses OS features not supported on host"
            case .AUTH        : return "Authorization denied"
            case .FORMAT      : return "Auxiliary database format error"
            case .RANGE       : return "2nd parameter to sqlite3_bind out of range"
            case .NOTADB      : return "File opened that is not a database file"
            case .NOTICE      : return "Notifications from sqlite3_log()"
            case .WARNING     : return "Warnings from sqlite3_log()"
            case .ROW         : return "sqlite3_step() has another row ready"
            case .DONE        : return "sqlite3_step() has finished executing"
            }
        }
        
        var debugDescription: String { "Error code \(rawValue) is #define SQLITE_\(self) with \(description)" }
    }
}
