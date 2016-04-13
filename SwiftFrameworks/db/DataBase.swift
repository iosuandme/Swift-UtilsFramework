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


// MARK: - protocols 接口
public protocol DataBaseRowSetType {
    var step:CInt { get }
    var next:Bool { get }
    var row:Int { get }
    func reset()
    func close()
}
//结果集



public class DataBaseRowSet<T:DataBaseTableType> {
    private var _stmt:COpaquePointer = nil
    init (_ stmt:COpaquePointer, _:T.Type) {
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

extension DataBaseRowSet : DataBaseRowSetType {
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

public class DataBaseBindSet<T:DataBaseTableType>: DataBaseRowSet<T> {
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

public class DataBaseResultSet<T:DataBaseTableType>: DataBaseRowSet<T> {
    override init(_ stmt: COpaquePointer, _ type: T.Type) {
        super.init(stmt, type)
    }
    init(_ rs: DataBaseResultSet, _ type: T.Type) {
        super.init(rs._stmt, type)
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

public protocol DataBaseTableType {
    associatedtype Column: RawRepresentable, DataBaseColumnProtocol


}


public protocol DataBaseType {
    associatedtype Table: RawRepresentable
    var version:Int { get }
    
    var fullPath:String { get }
    
    func onVersionChanged(handle:DataBaseHandle, oldVersion:Int, newVersion:Int) -> Bool
    
    // MARK: - init
    init(path:String)
    
    // MARK: - base sql function
    func open() throws -> DataBaseHandle
    
    func query<T:DataBaseTableType>(handle:DataBaseHandle, _:T.Type, sql:String) throws -> DataBaseResultSet<T>
    func exec(handle:DataBaseHandle, sql:String) throws
    
    // MARK: - create table
    func exec<DataBaseTable:DataBaseTableType>(handle:DataBaseHandle, _:DataBaseTable.Type, createTable table:Table) throws
    func exec<DataBaseTable:DataBaseTableType>(handle:DataBaseHandle, _:DataBaseTable.Type, createTableIfNotExists table:Table) throws
    
    // MARK: - select table
    func query<T:DataBaseTableType>(handle:DataBaseHandle, _:T.Type, SELECT columns:[T.Column]?, FROM table:Table, WHERE:String?) throws -> DataBaseResultSet<T>
    func query<T:DataBaseTableType>(handle:DataBaseHandle, _:T.Type, SELECT_COUNT columns:[T.Column]?, FROM table:Table, WHERE:String?) throws -> Int
}

// MARK: - realize sqlite3
extension DataBaseType {
    
    // MARK: base sql function
    public func open() throws -> DataBaseHandle {
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
            throw DataBaseError(rawValue: result)!
        }
        return DataBaseHandle(handle: handle)
    }
    
    public func exec(handle:DataBaseHandle, sql:String) throws {
        handle._lastSQL = sql
        let flag = sqlite3_exec(handle._handle, sql, nil, nil, nil)
        if flag != SQLITE_OK { throw SQLiteError(rawValue: flag)! }
    }
    
    public func query<T:DataBaseTableType>(handle:DataBaseHandle, _:T.Type, sql:String) throws -> DataBaseResultSet<T> {
        var stmt:COpaquePointer = nil
        handle._lastSQL = sql
        if SQLITE_OK != sqlite3_prepare_v2(handle._handle, sql, -1, &stmt, nil) {
            sqlite3_finalize(stmt)
            throw handle.lastError
        }
        return DataBaseResultSet(stmt, T.self)
        //throw NSError(domain: "", code: 0, userInfo: nil)
    }
    
    // MARK: create table
    private func exec<T:DataBaseTableType>(handle:DataBaseHandle, _:T.Type, createTable table:Table, _ otherSQL:String) throws {
        var params:String = ""
        for column in enumerateEnum(T.Column.self) {
            if !params.isEmpty { params += ", " }
            params += "\(column.rawValue) \(column.type)\(column.option)"
            if let value = column.defaultValue { params += " DEFAULT \(value)" }
        }
        try exec(handle, sql:"CREATE TABLE\(otherSQL) \(table.rawValue) (\(params))")
    }
    
    public func exec<DataBaseTable:DataBaseTableType>(handle:DataBaseHandle, _:DataBaseTable.Type, createTable table:Table) throws {
        try exec(handle, DataBaseTable.self, createTable:table, "")
    }
    public func exec<DataBaseTable:DataBaseTableType>(handle:DataBaseHandle, _:DataBaseTable.Type, createTableIfNotExists table:Table) throws {
        try exec(handle, DataBaseTable.self, createTable:table, "")
    }
    
    // MARK: select table
    public func query<T:DataBaseTableType>(handle:DataBaseHandle, _:T.Type, SELECT columns:[T.Column]?, FROM table:Table, WHERE:String?) throws -> DataBaseResultSet<T> {
        let columnNames = columns?.joined(separator: ",") { "\($0.rawValue)" } ?? "*"
        var sql = "SELECT \(columnNames) FROM \(table.rawValue)"
        if let condition = WHERE {
            sql.appendContentsOf(" WHERE \(condition)")
        }
        return try query(handle, T.self, sql: sql)
    }
    public func query<T:DataBaseTableType>(handle:DataBaseHandle, _:T.Type, SELECT_COUNT columns:[T.Column]?, FROM table:Table, WHERE:String?) throws -> Int {
        let columnNames = columns?.joined(separator: ",") { "\($0.rawValue)" } ?? "*"
        var sql = "SELECT COUNT(\(columnNames)) FROM \(table.rawValue)"
        if let condition = WHERE {
            sql.appendContentsOf(" WHERE \(condition)")
        }
        guard let rs = try? query(handle, T.self, sql: sql) else {
            throw handle.lastError
        }
        rs.next
        return rs.firstValue()

    }
}

public class DataBaseHandle {
    // 通过 SQLite 的 open 函数获得一个 Handle
    private var _handle:COpaquePointer = nil
    init(handle:COpaquePointer) {
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
        if let error = SQLiteError(rawValue: errorCode) {
            return error
        }
        let errorDescription = String.fromCString(sqlite3_errmsg(_handle)) ?? ""
        return NSError(domain: errorDescription, code: Int(errorCode), userInfo: nil)
    }
    private var _lastSQL:String?
    public var lastSQL:String { return _lastSQL ?? "" }
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
    
    public var description:String {
        var result = ""
        if contains(.PrimaryKey)    { result.appendContentsOf(" PRIMARY KEY") }
        if contains(.Autoincrement) { result.appendContentsOf(" AUTOINCREMENT") }
        if contains(.NotNull)       { result.appendContentsOf(" NOT NULL") }
        if contains(.Unique)        { result.appendContentsOf(" UNIQUE") }
        if contains(.Check)         { result.appendContentsOf(" CHECK") }
        if contains(.ForeignKey)    { result.appendContentsOf(" FOREIGN KEY") }
        return result
    }
}

// MARK: - ColumnType
public enum DataBaseColumnType : CInt, CustomStringConvertible {
    case integer = 1
    case float
    case text
    case blob
    case null
    
    public var description:String {
        switch self {
        case .integer:  return "INTEGER"
        case .float:    return "FLOAT"
        case .text:     return "TEXT"
        case .blob:     return "BLOB"
        case .null:     return "NULL"
        }
    }
}

// MARK: - ErrorType
public enum DataBaseError : CInt, CustomStringConvertible, CustomDebugStringConvertible, ErrorType {
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