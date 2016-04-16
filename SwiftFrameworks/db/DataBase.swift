//
//  DataBase.swift
//  QuestionLib
//
//  Created by 招利 李 on 16/4/12.
//  Copyright © 2016年 小分队. All rights reserved.
//
//  import Data.swift
//

import Foundation


/// TableObject mast extends `DataBaseTableType` protocol
public protocol DBTableType {
    /// TableColumn mast extends `DataBaseColumnProtocol` protocol
    associatedtype Column: RawRepresentable, DataBaseColumnProtocol
}

/// DBObject mast extends `DataBaseType` protocol and use final class
public protocol DBType {
    associatedtype Table: RawRepresentable
    var fullPath:String { get }
    
    /// class mast be use `final`, if version changed, mast `alter table`
    func onVersionChanged(db:DBHandle<Self>, oldVersion:Int, newVersion:Int) -> Bool
    
    // MARK: - open data base function
    /// mast set version bigger than `1` at `init`
    func setVersion(version:Int)
    func open() throws -> DBHandle<Self>
}

// MARK: - realize sqlite3
extension DBType {
    
    public func setVersion(newVersion:Int) {
        guard let db = try? open() else {
        #if DEBUG
            fatalError("无法打开数据库")
        #endif
            return
        }
        
        let oldVersion = db.version
        if oldVersion != newVersion {
            // 如果变化则调用更新函数来更新字段
            if onVersionChanged(db, oldVersion: oldVersion, newVersion: newVersion) {
                db.version = newVersion
            }
        }
    }

    // MARK: base sql function
    public func open() throws -> DBHandle<Self> {
        var handle:COpaquePointer = nil
        let dbPath:NSString = fullPath
        let dirPath = dbPath.stringByDeletingLastPathComponent
        let fileManager:NSFileManager = NSFileManager.defaultManager()
        var isDir:ObjCBool = false
        
        if !fileManager.fileExistsAtPath(dirPath, isDirectory: &isDir) || isDir {
            try fileManager.createDirectoryAtPath(dirPath, withIntermediateDirectories: true, attributes: nil)
        }
        
        let result = sqlite3_open(dbPath.UTF8String, &handle)
        if result != SQLITE_OK {
            sqlite3_close(handle)
            throw DBError(rawValue: result)!
        }
        
        return DBHandle(handle, Self.self)
    }
}

// MARK: - data base execuate handle
public class DBHandle<DB:DBType> {
    // 通过 SQLite 的 open 函数获得一个 Handle
    private var _handle:COpaquePointer = nil
    init(_ handle:COpaquePointer, _:DB.Type) {
        _handle = handle
    }
    
    deinit { if _handle != nil { sqlite3_close(_handle) }  }
    
    var version:Int {
        get {
            var stmt:COpaquePointer = nil
            if SQLITE_OK == sqlite3_prepare_v2(_handle, "PRAGMA user_version", -1, &stmt, nil) {
                defer { sqlite3_finalize(stmt) }
                return SQLITE_ROW == sqlite3_step(stmt) ? Int(sqlite3_column_int(stmt, 0)) : 0
            }
            return -1
        }
        set { sqlite3_exec(_handle, "PRAGMA user_version = \(newValue)", nil, nil, nil) }
    }
    
    public var lastError:ErrorType {
        let errorCode = sqlite3_errcode(_handle)
        if let error = DBError(rawValue: errorCode) {
            return error
        }
        let errorDescription = String.fromCString(sqlite3_errmsg(_handle)) ?? ""
        return NSError(domain: errorDescription, code: Int(errorCode), userInfo: nil)
    }
    private var _lastSQL:String?
    public var lastSQL:String { return _lastSQL ?? "" }
}

// MARK: - transaction 事务
extension DBHandle {
    // MARK: 开启事务 BEGIN TRANSACTION
    func beginTransaction() -> CInt {
        return sqlite3_exec(_handle,"BEGIN TRANSACTION",nil,nil,nil)
    }
    // MARK: 提交事务 COMMIT TRANSACTION
    func commitTransaction() -> CInt {
        return sqlite3_exec(_handle,"COMMIT TRANSACTION",nil,nil,nil)
    }
    // MARK: 回滚事务 ROLLBACK TRANSACTION
    func rollbackTransaction() -> CInt {
        return sqlite3_exec(_handle,"ROLLBACK TRANSACTION",nil,nil,nil)
    }
}

// MARK: - base execute sql function
extension DBHandle {
    public func exec(sql:String) throws {
        _lastSQL = sql
        let flag = sqlite3_exec(_handle, sql, nil, nil, nil)
        if flag != SQLITE_OK { throw DBError(rawValue: flag)! }
    }
    
    public func query(sql:String) throws -> DBRowSet {
        var stmt:COpaquePointer = nil
        _lastSQL = sql
        if SQLITE_OK != sqlite3_prepare_v2(_handle, sql, -1, &stmt, nil) {
            sqlite3_finalize(stmt)
            throw lastError
        }
        return DBRowSet(stmt)
    }
    
    public func query<T:DBTableType>(_:T.Type, sql:String) throws -> DBResultSet<T> {
        let rowSet = try query(sql)
        defer { rowSet._stmt = nil }
        return DBResultSet(rowSet._stmt, T.self)
    }
}

// MARK: - create table
extension DBHandle {
    private func exec<T:DBTableType>(_:T.Type, createTable table:DB.Table, _ otherSQL:String) throws {
        var params:String = ""
        var constraintKeys:[T.Column] = []
        var constraintPrimaryKey:T.Column? = nil
        for column in enumerateEnum(T.Column.self) {
            if !params.isEmpty { params += ", " }
            if column.option.contains(.ConstraintPrimaryKey) {
                constraintPrimaryKey = column
            } else {
                if column.option.contains(.ConstraintKey) { constraintKeys.append(column) }
                params += "\(column.rawValue) \(column.type)\(column.option)"
                if let value = column.defaultValue { params += " DEFAULT \(value)" }
            }
        }
        if let constraintPrimaryKey = constraintPrimaryKey where constraintKeys.count > 0 {
            let keys = constraintKeys.joined(separator: ", ") { "\($0.rawValue)" }
            params.appendContentsOf(", CONSTRAINT \(constraintPrimaryKey.rawValue) PRIMARY KEY (\(keys))")
        }
        
        try exec("CREATE TABLE\(otherSQL) \(table.rawValue) (\(params))")
    }
    
    public func exec<DataBaseTable:DBTableType>(_:DataBaseTable.Type, createTable table:DB.Table) throws {
        try exec(DataBaseTable.self, createTable:table, "")
    }
    public func exec<DataBaseTable:DBTableType>(_:DataBaseTable.Type, createTableIfNotExists table:DB.Table) throws {
        try exec(DataBaseTable.self, createTable:table, " IF NOT EXISTS")
    }
}

// MARK: - select table
extension DBHandle {
    
    public func query<T:DBTableType>(_:T.Type, SELECT columns:[T.Column], FROM table:DB.Table, WHERE:String? = nil) throws -> DBResultSet<T> {
        let columnNames = columns.count > 0 ? columns.joined(separator: ",") { "\($0.rawValue)" } : "*"
        var sql = "SELECT \(columnNames) FROM \(table.rawValue)"
        if let condition = WHERE where !condition.isEmpty {
            sql.appendContentsOf(" WHERE \(condition)")
        }
//        if orders.count > 0 {
//            let orderBy = orders.joined(separator: ", ") //{ "\($0.rawValue)" }
//            sql += " ORDER BY \(orderBy)"
//        }
        return try query(T.self, sql: sql)
    }
    
    public func query<T:DBTableType>(_:T.Type, SELECT_COUNT columns:[T.Column], FROM table:DB.Table, WHERE:String? = nil) throws -> Int {
        let columnNames = columns.count > 0 ? columns.joined(separator: ",") { "\($0.rawValue)" } : "*"
        var sql = "SELECT COUNT(\(columnNames)) FROM \(table.rawValue)"
        if let condition = WHERE where !condition.isEmpty  {
            sql.appendContentsOf(" WHERE \(condition)")
        }
        let rs = try query(T.self,sql: sql)
        rs.next
        return rs.firstValue()
    }
    
    public func query<LT:DBTableType,RT:DBTableType>(_:LT.Type, _:RT.Type, SELECT lcolumns:[LT.Column], _ rcolumns:[RT.Column], FROM ltable:DB.Table, LEFT_JOIN rtable:DB.Table, ON lc:LT.Column, equal rc:RT.Column, WHERE:String? = nil, ORDER_BY orders:LT.Column...) throws -> DBResultSet<LT> {
        var columnNames = lcolumns.joined(separator: ",") { "\(ltable.rawValue).\($0.rawValue)" }
        if rcolumns.count > 0 {
            columnNames.appendContentsOf(rcolumns.joined(separator: ", ") { "\(rtable.rawValue).\($0.rawValue)" } ?? "")
        }
        columnNames = columnNames.isEmpty ? "*" : columnNames
        var sql = "SELECT \(columnNames) FROM \(ltable.rawValue) LEFT JOIN \(rtable.rawValue) ON \(lc.rawValue)=\(rc.rawValue)"
        if let condition = WHERE where !condition.isEmpty {
            sql += " WHERE \(condition)"
        }
        if orders.count > 0 {
            let orderBy = orders.joined(separator: ", ") { "\($0.rawValue)" }
            sql += " ORDER BY \(orderBy)"
        }
        return try query(LT.self, sql: sql)
    }
}

// MARK: - alert table
extension DBHandle {
    // 修改数据表名
    public func exec(ALERT_TABLE oldTableName:String, RENAME_TO newTable:DB.Table) throws {
        try exec("ALTER TABLE \(oldTableName) RENAME TO \(newTable.rawValue)")
    }
    // 修改数据表 列名
    public func exec<T:DBTableType>(_:T.Type, ALERT_TABLE table:DB.Table, RENAME_COLUMN oldColumnName:String, TO newColumn:T.Column) throws {
        try exec("ALTER TABLE \(table.rawValue) RENAME COLUMN \(oldColumnName) TO \(newColumn.rawValue)")
    }
    // 修改数据表 列类型
    public func exec<T:DBTableType>(_:T.Type, ALERT_TABLE table:DB.Table, MODIFY column:T.Column, _ columnType:DataBaseColumnType) throws {
        try exec("ALTER TABLE \(table.rawValue) MODIFY \(column.rawValue) \(columnType)")
    }
    // 修改数据表 插入列
    public func exec<T:DBTableType>(_:T.Type, ALERT_TABLE table:DB.Table, ADD column:T.Column, _ columnType:DataBaseColumnType) throws {
        try exec("ALTER TABLE \(table.rawValue) ADD \(column.rawValue) \(columnType)")
    }
    // 修改数据表 删除列
    public func exec<T:DBTableType>(_:T.Type, ALERT_TABLE table:DB.Table, DROP_COLUMN columnName:String) throws {
        try exec("ALTER TABLE \(table.rawValue) DROP COLUMN \(columnName)")
    }
}

// MARK: - create table index
extension DBHandle {
    private func exec<T:DBTableType>(_:T.Type, CREATE other:String, INDEX indexName:String, ON table:DB.Table, columns:[T.Column]) throws {
        if columns.count == 0 {
            throw NSError(domain: "[\(table.rawValue)]没有指定任何索引字段", code: 0, userInfo: ["index":indexName])
        }
        let names = columns.joined(separator: ", ")
        try exec("CREATE\(other) INDEX \(indexName) ON \(table.rawValue)(\(names))")
    }
    public func exec<T:DBTableType>(_:T.Type, CREATE_INDEX indexName:String, ON table:DB.Table, columns:T.Column...) throws {
        try exec(T.self, CREATE: "", INDEX: indexName, ON: table, columns: columns)
    }
    public func exec<T:DBTableType>(_:T.Type, CREATE_UNIQUE_INDEX indexName:String, ON table:DB.Table, columns:T.Column...) throws {
        try exec(T.self, CREATE: " UNIQUE", INDEX: indexName, ON: table, columns: columns)
    }
}

// MARK: - updata
extension DBHandle {
    public func exec<T:DBTableType>(_:T.Type, UPDATE table:DB.Table, SET params:[T.Column:Any], WHERE:String?) throws {
        var paramString = params.joined(separator: ", ") { "\($0.0.rawValue) = \($0.1)" }
        if let condition = WHERE where !condition.isEmpty {
            paramString += " WHERE \(condition)"
        }
        try exec("UPDATE \(table.rawValue) SET \(paramString)")
    }
}

// MARK: - delete
extension DBHandle {
    // 删除
    public func exec(DELETE_FROM table:DB.Table, WHERE:String?) throws {
        var sql = "DELETE FROM \(table.rawValue)"
        if let condition = WHERE where !condition.isEmpty {
            sql.appendContentsOf(" WHERE \(condition)")
        }
        try exec(sql)
    }
}

// MARK: - insert
extension DBHandle {
    
    public func exec<T:DBTableType>(_:T.Type, INSERT OR:String?, INTO table:DB.Table, _ columns:[T.Column]? = nil) throws  -> DBBindSet {
        let orString = OR?.trim().joinIn(" ", "") ?? ""
        let columnNames = columns?.joined(separator: ", ",includeElement: {"\($0.rawValue)"}).joinIn("(", ")") ?? ""
        var tableColumnsCount = 0
        for _ in enumerateEnum(T.Column.self) {
            tableColumnsCount += 1
        }
        let length = columns?.count ?? tableColumnsCount
        let values = [String](count: length, repeatedValue: "?").joined(separator: ", ")
        
        let rowSet = try query("INSERT\(orString) INTO \(table.rawValue)\(columnNames) VALUES(\(values))")
        return DBBindSet(rowSet._stmt)
    }
    
    private func exec<T:DBTableType>(_:T.Type, INSERT OR:String?, INTO table:DB.Table, _ columns:[T.Column]? = nil, VALUES:[Any]) throws {
        let bindSet = try exec(T.self, INSERT: OR, INTO: table, columns)
        var flag:CInt = SQLITE_ERROR
        for i:Int in 0 ..< VALUES.count {
            flag = bindSet.bindValue(VALUES[i], index: i + 1)
            assert(flag == SQLITE_OK || flag == SQLITE_ROW, "绑定[\(i)]失败 value=\(VALUES[i])")
            if flag != SQLITE_OK && flag != SQLITE_ROW { break }
        }
        if flag == SQLITE_OK || flag == SQLITE_ROW {
            flag = bindSet.step
            if flag == SQLITE_OK || flag == SQLITE_DONE {
                flag = SQLITE_OK
            }
        }
    }
    
    public func exec<T:DBTableType>(_:T.Type, INSERT_INTO table:DB.Table, _ columns:[T.Column]? = nil, VALUES values:Any...) throws -> Int {
        try exec(T.self, INSERT: nil, INTO: table, columns, VALUES: values)
        return Int(truncatingBitPattern: sqlite3_last_insert_rowid(_handle))
    }
    public func exec<T:DBTableType>(_:T.Type, INSERT_OR_REPLACE_INTO table:DB.Table, _ columns:[T.Column]? = nil, VALUES values:Any...) throws -> Int {
        try exec(T.self, INSERT: "OR REPLACE", INTO: table, columns, VALUES: values)
        return Int(truncatingBitPattern: sqlite3_last_insert_rowid(_handle))
    }
    public func exec<T:DBTableType>(_:T.Type, INSERT_OR_IGNORE_INTO table:DB.Table, _ columns:[T.Column]? = nil, VALUES values:Any...) throws -> Int {
        try exec(T.self, INSERT: "OR IGNORE", INTO: table, columns, VALUES: values)
        return Int(truncatingBitPattern: sqlite3_last_insert_rowid(_handle))
    }
    
    public func exec<T:DBTableType, Item>(_:T.Type, INSERT OR:String?, INTO table:DB.Table, _ columns:[T.Column]? = nil, VALUES values:[Item], map:(id:Int, item:Item) -> [T.Column:Any]) throws {
        let bindSet = try exec(T.self, INSERT: OR, INTO: table, columns)
        var columnFields:[T.Column] = []
        if let columns = columns {
            columnFields = columns
        } else {
            for column in enumerateEnum(T.Column.self) {
                columnFields.append(column)
            }
        }
        // 获取最后一次插入的ID
        beginTransaction()
        var flag:CInt = SQLITE_ERROR
        for i:Int in 0 ..< columnFields.count {
            let columnOption = columnFields[i].option
            let value:Int? = columnOption.contains(.PrimaryKey) ? nil : 1
            bindSet.bindValue(value, index: i + 1)
        }
        flag = bindSet.step
        if flag == SQLITE_OK || flag == SQLITE_DONE {
            rollbackTransaction()
        } else {
            throw DBError(rawValue: flag) ?? DBError.CUSTOM
        }
        bindSet.reset()
        var lastInsertID = sqlite3_last_insert_rowid(_handle)
        beginTransaction()
        
        // 插入数据
        for value in values {
            let dict = map(id: Int(truncatingBitPattern: lastInsertID), item: value)
            for i:Int in 0 ..< columnFields.count {
                let key = columnFields[i]
                flag = bindSet.bindValue(dict[key], index: i + 1)
                if flag != SQLITE_OK && flag != SQLITE_ROW { break }
            }
            if flag == SQLITE_OK || flag == SQLITE_ROW {
                flag = bindSet.step
                if flag != SQLITE_OK && flag != SQLITE_DONE {
                #if DEBUG
                    fatalError("无法绑定数据[\(dict)] 到[\(columnFields)]")
                #endif
                    bindSet.bindClear()     //如果失败则绑定下一组
                } else {
                    bindSet.reset()
                    if lastInsertID == sqlite3_last_insert_rowid(_handle) {
                        lastInsertID++
                    }
                }
            }
        }
        if flag == SQLITE_OK || flag == SQLITE_DONE {
            flag = SQLITE_OK
            commitTransaction()
        } else {
            rollbackTransaction()
            throw DBError(rawValue: flag) ?? DBError.ERROR
        }
    }
    
    public func exec<T:DBTableType, Item>(_:T.Type, INSERT_INTO table:DB.Table, _ columns:[T.Column]? = nil, VALUES values:[Item], map:(id:Int, item:Item) -> [T.Column:Any]) throws {
        try exec(T.self, INSERT: nil, INTO: table, VALUES: values, map: map)
    }
    public func exec<T:DBTableType, Item>(_:T.Type, INSERT_OR_REPLACE_INTO table:DB.Table, _ columns:[T.Column]? = nil, VALUES values:[Item], map:(id:Int, item:Item) -> [T.Column:Any]) throws {
        try exec(T.self, INSERT: "OR REPLACE", INTO: table, VALUES: values, map: map)
    }
    public func exec<T:DBTableType, Item>(_:T.Type, INSERT_OR_IGNORE_INTO table:DB.Table, _ columns:[T.Column]? = nil, VALUES values:[Item], map:(id:Int, item:Item) -> [T.Column:Any]) throws {
        try exec(T.self, INSERT: "OR IGNORE", INTO: table, VALUES: values, map: map)
    }
}

// MARK: - protocols 接口
public protocol DataBaseRowSetType {
    var step:CInt { get }
    var next:Bool { get }
    var row:Int { get }
    func reset()
    func close()
}
//结果集

public class DBRowSet {
    private var _stmt:COpaquePointer = nil
    init (_ stmt:COpaquePointer) {
        _stmt = stmt
        let length = sqlite3_column_count(_stmt);
        columnCount = Int(length)
        var columns:[String] = []
        for i:CInt in 0..<length {
            let name:UnsafePointer<CChar> = sqlite3_column_name(_stmt,i)
            columns.append(String.fromCString(name)!.lowercaseString)
        }
        //print(columns)
        self.columns = columns
    }
    deinit {
        if _stmt != nil {
            sqlite3_finalize(_stmt)
        }
    }
    private let columns:[String]
    let columnCount:Int
    
}

extension DBRowSet : DataBaseRowSetType {
    public var step:CInt {
        return sqlite3_step(_stmt)
    }
    public var next:Bool {
        return step == SQLITE_ROW
    }
    public var row:Int {
        return Int(sqlite3_data_count(_stmt))
    }
    public func reset() {
        sqlite3_reset(_stmt)
    }
    public func close() {
        sqlite3_finalize(_stmt)
        _stmt = nil
    }
}

public class DBBindSet: DBRowSet {
    var bindCount:CInt {
        return sqlite3_bind_parameter_count(_stmt)
    }
    
    func bindClear() -> CInt {
        return sqlite3_clear_bindings(_stmt)
    }
    // 泛型绑定
    func bindValue<T>(columnValue:T?, index:Int) -> CInt {
        
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

public class DataBaseResultSetBase<T:DBTableType>: DBRowSet {
    
    override init(_ stmt: COpaquePointer) {
        super.init(stmt)
    }
    
    public func firstValue() -> Int {
        if next {
            return Int(sqlite3_column_int(_stmt, 0))
        }
        return 0
    }
    
    public func getDictionary() -> [String:Any] {
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
    public func getInt64(columnIndex:Int) -> Int64 {
        return columnIndex < columnCount ? sqlite3_column_int64(_stmt, CInt(columnIndex)) : 0
    }
    public func getUInt64(columnIndex:Int) -> UInt64 {
        return UInt64(bitPattern: getInt64(columnIndex))
    }
    public func getInt(columnIndex:Int) -> Int {
        return Int(truncatingBitPattern: getInt64(columnIndex))
    }
    public func getUInt(columnIndex:Int) -> UInt {
        return UInt(truncatingBitPattern: getInt64(columnIndex))
    }
    public func getInt32(columnIndex:Int) -> Int32 {
        return Int32(truncatingBitPattern: getInt64(columnIndex))
    }
    public func getUInt32(columnIndex:Int) -> UInt32 {
        return UInt32(truncatingBitPattern: getInt64(columnIndex))
    }
    public func getBool(columnIndex:Int) -> Bool {
        return getInt64(columnIndex) > 0
    }
    public func getFloat(columnIndex:Int) -> Float {
        return Float(sqlite3_column_double(_stmt, CInt(columnIndex)))
    }
    public func getDouble(columnIndex:Int) -> Double {
        return sqlite3_column_double(_stmt, CInt(columnIndex))
    }
    public func getString(columnIndex:Int) -> String! {
        let result = sqlite3_column_text(_stmt, CInt(columnIndex))
        return String.fromCString(UnsafePointer<CChar>(result))
    }
}

public class DBResultSet<T:DBTableType>: DataBaseResultSetBase<T> {
    
    init(_ stmt:COpaquePointer, _:T.Type) {
        super.init(stmt)
    }
    
    init(_ rs: DBRowSet, _:T.Type) {
        super.init(rs._stmt)
    }
    
    func getColumnIndex(column: T.Column) -> Int {
        return columns.indexOf({ $0 == "\(column.rawValue)".lowercaseString }) ?? NSNotFound
    }
    
    public func getUInt(column: T.Column) -> UInt {
        return UInt(truncatingBitPattern: getInt64(column))
    }
    public func getInt(column: T.Column) -> Int {
        return Int(truncatingBitPattern: getInt64(column))
    }
    public func getInt64(column: T.Column) -> Int64 {
        guard let index = columns.indexOf({ $0 == "\(column.rawValue)".lowercaseString }) else {
            return 0
        }
        return sqlite3_column_int64(_stmt, CInt(index))
    }
    public func getDouble(column: T.Column) -> Double {
        guard let index = columns.indexOf({ $0 == "\(column.rawValue)".lowercaseString }) else {
            return 0
        }
        return sqlite3_column_double(_stmt, CInt(index))
    }
    public func getFloat(column: T.Column) -> Float {
        return Float(getDouble(column))
    }
    public func getString(column: T.Column) -> String! {
        guard let index = columns.indexOf({ $0 == "\(column.rawValue)".lowercaseString }) else {
            return nil
        }
        let result = sqlite3_column_text(_stmt, CInt(index))
        return String.fromCString(UnsafePointer<CChar>(result))
    }
    public func getData(column: T.Column) -> NSData! {
        guard let index = columns.indexOf({ $0 == "\(column.rawValue)".lowercaseString }) else {
            return nil
        }
        let data:UnsafePointer<Void> = sqlite3_column_blob(_stmt, CInt(index))
        let size:CInt = sqlite3_column_bytes(_stmt, CInt(index))
        return NSData(bytes:data, length: Int(size))
    }
    public func getDate(column: T.Column) -> NSDate! {
        guard let index = columns.indexOf({ $0 == "\(column.rawValue)".lowercaseString }) else {
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


public protocol DataBaseColumnProtocol : Enumerable {
    var type: DataBaseColumnType { get }
    var option: DataBaseColumnOptions { get }
    var defaultValue:CustomStringConvertible? { get }
}

// MARK: - ColumnState 头附加状态
public struct DataBaseColumnOptions : OptionSetType, CustomStringConvertible {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    
    static let None             = DataBaseColumnOptions(rawValue: 0)
    static let PrimaryKey       = DataBaseColumnOptions(rawValue: 1 << 0)
    static let Autoincrement    = DataBaseColumnOptions(rawValue: 1 << 1)
    static let PrimaryKeyAutoincrement: DataBaseColumnOptions = [PrimaryKey, Autoincrement]
    static let NotNull          = DataBaseColumnOptions(rawValue: 1 << 2)
    static let Unique           = DataBaseColumnOptions(rawValue: 1 << 3)
    static let Check            = DataBaseColumnOptions(rawValue: 1 << 4)
    static let ForeignKey       = DataBaseColumnOptions(rawValue: 1 << 5)
    static let ConstraintKey    = DataBaseColumnOptions(rawValue: 1 << 6)       // 属于联合主键
    static let ConstraintPrimaryKey = DataBaseColumnOptions(rawValue: 1 << 7)   // 联合主键名
    
    public var description:String {
        var result = ""
        
        if contains(.PrimaryKey)    { result.appendContentsOf(" PRIMARY KEY") }
        if contains(.Autoincrement) { result.appendContentsOf(" AUTOINCREMENT") }
        if contains(.NotNull)       { result.appendContentsOf(" NOT NULL") }
        if contains(.Unique)        { result.appendContentsOf(" UNIQUE") }
        if contains(.Check)         { result.appendContentsOf(" CHECK") }
        if contains(.ForeignKey)    { result.appendContentsOf(" FOREIGN KEY") }
        if contains(.ConstraintKey) { result.appendContentsOf(" NOT NULL") }

        return result
    }
}

// MARK: - ColumnType
public enum DataBaseColumnType : CInt, CustomStringConvertible {
    case Integer = 1
    case Float
    case Text
    case Blob
    case Null
    
    public var description:String {
        switch self {
        case .Integer:  return "INTEGER"
        case .Float:    return "FLOAT"
        case .Text:     return "TEXT"
        case .Blob:     return "BLOB"
        case .Null:     return "NULL"
        }
    }
}

// MARK: - ErrorType
public enum DBError : CInt, CustomStringConvertible, CustomDebugStringConvertible, ErrorType {
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
    case CUSTOM     = 99//CUSTOM            insert error
    case ROW       = 100//SQLITE_ROW        sqlite3_step() has another row ready
    case DONE      = 101//SQLITE_DONE       sqlite3_step() has finished executing
    
    public var description: String {
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
        case .CUSTOM      : return "自定义插入失败"
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
        case .CUSTOM      : return "custom insert error"
        case .ROW         : return "sqlite3_step() has another row ready"
        case .DONE        : return "sqlite3_step() has finished executing"
        }
    }
    
    public var debugDescription: String { return "Error code \(rawValue) is #define SQLITE_\(self) with \(description)" }
}