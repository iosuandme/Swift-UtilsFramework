import Foundation

public struct JSON {
    
    public static func getValue(_ o: AnyObject?) -> Value? {
        if let object:AnyObject = o {
            return JSON.getValue(object)
        }
        return nil
    }
    
    public static func getValue(_ o: AnyObject) -> Value {
        
        switch(o) {
        case (let v as NSDictionary)    : return Value(v)
        case (let v as NSArray)         : return Value(v)
        case (let v as NSNumber)        : return Value(v)
        case (let v as String)          : return Value(v)
        case (let v as NSNull)          : return Value(v)
        default                         : return Value(error: "JSON Unknow object: \(o)")
        }
    }
    
    public enum ValueType {
        case jsonObject (Object)
        case jsonArray  ([Value])
        case jsonString (String)
        case jsonNumber (NSNumber)
        case jsonNull
        case jsonError  (String)
    }
    
    // MARK: - JSONValue 可以赋值字典、数组、数值、字符串、布尔等
    open class Value : ExpressibleByDictionaryLiteral, ExpressibleByArrayLiteral, ExpressibleByIntegerLiteral,ExpressibleByFloatLiteral, ExpressibleByBooleanLiteral, ExpressibleByStringLiteral, IteratorProtocol, Sequence {
        
        public typealias Element = Value
        open func next() -> Value? {
            defer { index += 1 }
            switch value {
            case .jsonObject(let dict):
                if index >= dict.count {
                    index = -1
                    return nil
                }
                return dict[ObjectIndex(rawValue: index)].1
            case .jsonArray(let array):
                if index >= array.count {
                    index = -1
                    return nil
                }
                return array[index]
            default: return nil
            }
        }
        
        fileprivate var index:Int = 0
        fileprivate var value:ValueType
        
        // MARK: JSONValue 可以赋值异常
        public init(error:String) {
            value = .jsonError(error)
        }
        public init(_ v: NSNull) {
            self.value = .jsonNull
        }
        public init(_ v: String) {
            self.value = .jsonString(v)
        }
        public init(_ v: Int64) {
            self.value = .jsonNumber(NSNumber(value: v as Int64))
        }
        public init(_ v: Int) {
            self.value = .jsonNumber(NSNumber(value: v as Int))
        }
        public init(_ v: Bool) {
            self.value = .jsonNumber(NSNumber(value: v as Bool))
        }
        public init(_ v: Double) {
            self.value = .jsonNumber(NSNumber(value: v as Double))
        }
        public init(_ v: Float) {
            self.value = .jsonNumber(NSNumber(value: v as Float))
        }
        public init(_ v: NSNumber) {
            self.value = .jsonNumber(v)
        }
        public init(_ v: NSArray) {
            var values:[Value] = []
            for o in v {
                values.append(JSON.getValue(o as AnyObject))
            }
            self.value = .jsonArray(values)
        }
        
        public init(_ v: NSDictionary) {
            let object = Object(minimumCapacity: v.count)
            for (key, value) in v {
                _ = object.putValue(JSON.getValue(value as AnyObject), forKey: "\(key)")
            }
            self.value = .jsonObject(object)
        }
        
        
        public required init(booleanLiteral value: Bool) {
            self.value = .jsonNumber(NSNumber(value: value as Bool))
        }
        
        public init(_builtinIntegerLiteral value: _MaxBuiltinIntegerType) {
            self.value = .jsonNumber(NSNumber(integerLiteral: Int(_builtinIntegerLiteral: value)))
        }

        
        public typealias ExtendedGraphemeClusterLiteralType = StaticString
        public required init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
            self.value = .jsonString(String(describing: value))
        }
        
        public typealias UnicodeScalarLiteralType = StaticString
        public required init(unicodeScalarLiteral value:UnicodeScalarLiteralType) {
            self.value = .jsonString(String(describing: value))
        }
        
        public required init(stringLiteral value: StaticString) {
            self.value = .jsonString(String(describing: value))
        }
        
        public required init(arrayLiteral elements: Value...) {
            var values:[Value] = []
            let length = elements.count
            for i:Int in 0 ..< length {
                values.append(elements[i])
            }
            self.value = .jsonArray(values)
        }

        // MARK: JSONValue 可以赋值整数
        public required init(integerLiteral value: Int) {
            self.value = .jsonNumber(NSNumber(value: value as Int))
        }
        public typealias FloatLiteralType = Double
        /// Create an instance initialized to `value`.
        public required init(floatLiteral value: Double) {
            self.value = .jsonNumber(NSNumber(value: value as Double))
        }

        
        public required init(dictionaryLiteral elements: (String, Value)...) {
            let length = elements.count
            let value:Object = Object(minimumCapacity: length)
            for i:Int in 0 ..< length {
                _ = value.putValue(elements[i].1, forKey: elements[i].0)
            }
            self.value = .jsonObject(value)
        }
        
        
        
        public subscript (position: Int) -> Value {
            set {
                switch (value) {
                case .jsonObject(let dict)  :
                    if position < dict.count {
                        let index = ObjectIndex(rawValue: position)
                        dict[index] = (dict[index].0, newValue)
                    } else {
                        fatalError("position[\(position)] out of JSON.Object count(\(dict.count)) !")
                    }
                case .jsonArray(var array)  :
                    array[position] = newValue
                    value = .jsonArray(array)
                default :
                    fatalError("[\(self)] isn't JSONArray ! and set \(newValue) fail !")
                }
            }
            get {
                switch (value) {
                case .jsonObject(let dict)  : return dict[ObjectIndex(rawValue: position)].1
                case .jsonArray(let array)  : return array[position]
                default                     : return Value(error: "[\(self)] isn't JSONArray !")
                }
            }
        }
        
        open subscript (position: ObjectIndex) -> (String, Value) {
            set {
                if case .jsonObject(let dict) = value {
                    dict[position] = newValue
                } else {
                    fatalError("[\(self)] isn't JSONObject ! and set \(newValue) fail !")
                }
            }
            get {
                if case .jsonObject(let dict) = value {
                    return dict[position]
                }
                return ("JSON.Error",Value(error: "[\(self)] isn't JSONObject !"))
            }
        }
        
        open subscript (key: String) -> Value {
            set {
                if case .jsonObject(let dict) = value {
                    dict[key] = newValue
                }
            }
            get {
                if case .jsonObject(let dict) = value {
                    return dict[key] ?? Value(error: "not has key: \(key) !")
                }
                return Value(error: "[\(self)] isn't JSONObject !")
            }
        }
        
        open var stringValue:String {
            switch value {
            case let .jsonNumber(num): return num.stringValue
            case let .jsonString(str): return str
            default : break
            }
            return ""
        }
        
        open var unsignedLongLongValue:UInt64 {
            switch value {
            case let .jsonNumber(num): return num.uint64Value
            case let .jsonString(str): return UInt64(str) ?? UInt64(bitPattern: (str as NSString).longLongValue)
            default : break
            }
            return 0
        }
        
        open var longLongValue:Int64 {
            switch value {
            case let .jsonNumber(num): return num.int64Value
            case let .jsonString(str): return Int64(str) ?? (str as NSString).longLongValue
            default : break
            }
            return 0
        }
        
        open var integerValue:Int {
            switch value {
            case let .jsonNumber(num): return num.intValue
            case let .jsonString(str): return Int(str) ?? (str as NSString).integerValue
            default : break
            }
            return 0
        }
        
        open var floatValue:Float {
            switch value {
            case let .jsonNumber(num): return num.floatValue
            case let .jsonString(str): return Float(str) ?? (str as NSString).floatValue
            default : break
            }
            return 0
        }
        
        open var doubleValue:Double {
            switch value {
            case let .jsonNumber(num): return num.doubleValue
            case let .jsonString(str): return Double(str) ?? (str as NSString).doubleValue
            default : break
            }
            return 0
        }
        
        open var boolValue:Bool {
            switch value {
            case let .jsonNumber(num): return num.boolValue
            case let .jsonString(str):
                switch str {
                case "true":    return true;
                case "false":   return false;
                default:        return (str as NSString).boolValue
                }
            default : break
            }
            return false
        }
        
        var count:Int {
            switch (value) {
            case .jsonObject(let dict)  : return dict.count
            case .jsonArray(let array)  : return array.count
            case .jsonNull              : return 0
            default : break
            }
            return 1
        }
        
        var isNull:Bool {
            if case .jsonNull = value {
                return true
            }
            return false
        }
        
        var isObject:Bool {
            if case .jsonObject = value {
                return true
            }
            return false
        }
        
        var isArray:Bool {
            if case .jsonArray = value {
                return true
            }
            return false
        }
        
        var isValue:Bool {
            switch value {
            case .jsonString: fallthrough
            case .jsonNumber: return true
            default: break
            }
            return false
        }
        
        var isError:Bool {
            if case .jsonError = value {
                return true
            }
            return false
        }
        
    }
    
    open class Object : Sequence, ExpressibleByDictionaryLiteral {
        
        fileprivate var _pointer:UnsafeMutablePointer<Int>?
        fileprivate var _keys:Array<String>
        fileprivate var _values:Array<Value>
        fileprivate var _count:Int = 0
        fileprivate var _offset:Int = 0
        fileprivate var _capacity:Int = 10
        fileprivate var _minimumCapacity:Int = 10
        fileprivate var _slice:Bool = false
        
        public typealias Element = (String, Value)
        public typealias Index = ObjectIndex
        /// Create an empty dictionary.
        public convenience init() {
            self.init(minimumCapacity:10)
        }
        /// Create a dictionary with at least the given number of
        /// elements worth of storage.  The actual capacity will be the
        /// smallest power of 2 that's >= `minimumCapacity`.
        public init(minimumCapacity: Int) {
            
            _capacity = minimumCapacity
            _minimumCapacity = minimumCapacity
            _keys = []
            _keys.reserveCapacity(minimumCapacity)
            _values = []
            _values.reserveCapacity(minimumCapacity)
            _pointer = UnsafeMutablePointer<Int>.allocate(capacity: minimumCapacity)
        }
        /// The position of the first element in a non-empty dictionary.
        ///
        /// Identical to `endIndex` in an empty dictionary.
        ///
        /// - Complexity: Amortized O(1) if `self` does not wrap a bridged
        ///   `NSDictionary`, O(N) otherwise.
        open var startIndex: Index {
            return ObjectIndex(rawValue: 0)
        }
        /// The collection's "past the end" position.
        ///
        /// `endIndex` is not a valid argument to `subscript`, and is always
        /// reachable from `startIndex` by zero or more applications of
        /// `successor()`.
        ///
        /// - Complexity: Amortized O(1) if `self` does not wrap a bridged
        ///   `NSDictionary`, O(N) otherwise.
        open var endIndex: Index { return ObjectIndex(rawValue: _count - 1) }
        /// Returns the `Index` for the given key, or `nil` if the key is not
        /// present in the dictionary.
        open func indexForKey(_ key: String) -> Index? {
            let hasValue = key.hashValue
            for i:Int in 0 ..< _count {
                if _pointer?.advanced(by: _offset + i).pointee == hasValue { return ObjectIndex(rawValue: i) }
            }
            return nil
        }
        open subscript (position: Index) -> (String, Value) {
            get {
                let position = position.rawValue
                if position >= _count {
                    fatalError("position(\(position)) out of count(\(_count))")
                }
                return (_keys[position], _values[position])
            }
            set {
                let position = position.rawValue
                if position > _count {
                    fatalError("position(\(position)) out of count(\(_count))")
                } else if position == _count {
                    _ = putValue(newValue.1, forKey: newValue.0)
                } else {
                    _pointer?.advanced(by: _offset + position).pointee = newValue.0.hashValue
                    _keys[position] = newValue.0
                    _values[position] = newValue.1
                }
            }
        }
        open subscript (key: String) -> Value? {
            get {
                if let position = indexForKey(key) {
                    return _values[position.rawValue]
                }
                return nil
            }
            set {
                if let value = newValue {
                    if let position = indexForKey(key) {
                        _values[position.rawValue] = value
                    } else {
                        _ = putValue(value, forKey: key)
                    }
                } else {
                    if let position = indexForKey(key) {
                        _ = removeAtIndex(position)
                    }
                }
            }
        }
        
        open func putValue(_ value: Value, forKey key: String) -> Index {
            if (_count + _offset) == _capacity {
                _resizeUnsafeCapacity(Int(Double(_count) * 1.6) + 1)
            }
            _pointer?.advanced(by: _offset + _count).initialize(to: key.hashValue)
            _keys.append(key)
            _values.append(value)
            defer { _count += 1 }
            return ObjectIndex(rawValue:_count)
        }
        /// Update the value stored in the dictionary for the given key, or, if they
        /// key does not exist, add a new key-value pair to the dictionary.
        ///
        /// Returns the value that was replaced, or `nil` if a new key-value pair
        /// was added.
        open func updateValue(_ value: Value, forKey key: String) -> Value? {
            if let position = indexForKey(key) {
                let oldValue = _values[position.rawValue]
                _values[position.rawValue] = value
                return oldValue
            }
            _ = putValue(value, forKey: key)
            return nil
        }
        /// Remove the key-value pair at `index`.
        ///
        /// Invalidates all indices with respect to `self`.
        ///
        /// - Complexity: O(`count`).
        open func removeAtIndex(_ index: Index) -> (String, Value) {
            let index = index.rawValue
            if index >= _count {
                fatalError("index(\(index)) out of count(\(_count))")
            } else if index == 0 {
                return removeFirst()
            } else if index == _count - 1 {
                return removeLast()
            }
            //        let element = _pointer.advancedBy(_offset + index).memory
            let pointer = UnsafeMutablePointer<Int>.allocate(capacity: _capacity)
            if index > 0 { pointer.moveInitialize(from: (_pointer?.advanced(by: _offset))!, count: index) }
            if index < _count - 1 { pointer.advanced(by: index).moveInitialize(from: (_pointer?.advanced(by: _offset + index + 1))!, count: _count - index - 1) }
            _releaseBuffer(_capacity, oldCapacity:_capacity)
            _pointer = pointer
            _count -= 1
            return (_keys.remove(at: index), _values.remove(at: index))
        }
        
        open func popFirst() -> (String, Value)? {
            if isEmpty { return nil }
            return removeAtIndex(startIndex)
        }
        /// Remove an element from the end of the Array in O(1).
        ///
        /// - Requires: `count > 0`.
        func removeLast() -> (String, Value) {
            if _count == 0 {
                fatalError("can't remove last because count is zero")
            }
            _count -= 1
            let lastPointer = _pointer?.advanced(by: _count)
            lastPointer?.deinitialize()
            return (_keys.remove(at: _count), _values.remove(at: _count))
        }
        
        func removeFirst() -> (String, Value) {
            if _count == 0 {
                fatalError("can't remove first because count is zero")
            }
            _count -= 1
            _pointer?.advanced(by: _offset).deinitialize()
            _offset += 1
            return (_keys.remove(at: 0), _values.remove(at: 0))
        }
        
        /// Remove a given key and the associated value from the dictionary.
        /// Returns the value that was removed, or `nil` if the key was not present
        /// in the dictionary.
        open func removeValueForKey(_ key: String) -> Value? {
            if let position = indexForKey(key) {
                return removeAtIndex(position).1
            }
            return nil
        }
        /// Remove all elements.
        ///
        /// - Postcondition: `capacity == 0` if `keepCapacity` is `false`, otherwise
        ///   the capacity will not be decreased.
        ///
        /// Invalidates all indices with respect to `self`.
        ///
        /// - parameter keepCapacity: If `true`, the operation preserves the
        ///   storage capacity that the collection has, otherwise the underlying
        ///   storage is released.  The default is `false`.
        ///
        /// Complexity: O(`count`).
        open func removeAll(keepCapacity: Bool = false) {
            _pointer?.advanced(by: _offset).deinitialize(count: _count)
            _count = 0
            if !keepCapacity {
                _releaseBuffer(_minimumCapacity, oldCapacity:_capacity)
                _pointer = UnsafeMutablePointer<Int>.allocate(capacity: _capacity)
            }
            _offset = 0
            _keys.removeAll(keepingCapacity: keepCapacity)
            _values.removeAll(keepingCapacity: keepCapacity)
        }
        /// The number of entries in the dictionary.
        ///
        /// - Complexity: O(1).
        open var count: Int {
            return _count
        }
        /// Return a *generator* over the (key, value) pairs.
        ///
        /// - Complexity: O(1).
        open func makeIterator() -> ObjectGenerator {
            return ObjectGenerator(self)
        }
        /// Create an instance initialized with `elements`.
        public required init(dictionaryLiteral elements: (String, Value)...) {
            _capacity = elements.count
            _minimumCapacity = _capacity
            _keys = []
            _keys.reserveCapacity(_capacity)
            _values = []
            _values.reserveCapacity(_capacity)
            //UnsafeMutableBufferPointer<Int>(start: UnsafeMutablePointer<Int>(nil), count: 3)
            _pointer = UnsafeMutablePointer<Int>.allocate(capacity: _capacity)
            for i:Int in 0 ..< _capacity {
                let element = elements[i]
                _pointer?.advanced(by: i).initialize(to: element.0.hashValue)
                _keys.append(element.0)
                _values.append(element.1)
            }
            _count = _capacity
        }
        
        
        /// Reserve enough space to store `minimumCapacity` elements.
        ///
        /// - Postcondition: `capacity >= minimumCapacity` and the array has
        ///   mutable contiguous storage.
        ///
        /// - Complexity: O(`count`).
        func reserveCapacity(_ minimumCapacity: Int) {
            _minimumCapacity = minimumCapacity
            if _capacity >= minimumCapacity && _count < minimumCapacity {
                _resizeUnsafeCapacity(minimumCapacity)
            } else if _capacity < minimumCapacity {
                _resizeUnsafeCapacity(minimumCapacity)
            }
        }
        
        fileprivate func _resizeUnsafeCapacity(_ newCapacity: Int) {
            let pointer = UnsafeMutablePointer<Int>.allocate(capacity: newCapacity)
            pointer.moveInitialize(from: (_pointer?.advanced(by: _offset))!, count: _count)
            _releaseBuffer(newCapacity, oldCapacity:_capacity)
            _pointer = pointer
        }
        
        fileprivate func _releaseBuffer(_ newCapacity: Int, oldCapacity: Int) {
            if !_slice {
                if _count > 0 {
                    _pointer?.advanced(by: _offset).deinitialize(count: _count)
                }
                _pointer?.deallocate(capacity: oldCapacity)
            }
            _slice = false
            _capacity = newCapacity
            _offset = 0
        }
        
        /// A collection containing just the keys of `self`.
        ///
        /// Keys appear in the same order as they occur as the `.0` member
        /// of key-value pairs in `self`.  Each key in the result has a
        /// unique value.
        open var keys: [String] { //LazyForwardCollection<MapCollection<[Key : Value], Key>> {
            return [Key](_keys)
        }
        /// A collection containing just the values of `self`.
        ///
        /// Values appear in the same order as they occur as the `.1` member
        /// of key-value pairs in `self`.
        open var values: [Value] { //LazyForwardCollection<MapCollection<[Key : Value], Value>> {
            return [Value](_values) //LazyForwardCollection<MapCollection<[Key : Value], Value>>(_values)
        }
        
        deinit {
            _releaseBuffer(0, oldCapacity: _capacity)
            _pointer = nil
        }
        
        /// `true` iff `count == 0`.
        open var isEmpty: Bool { return count == 0 }
    }
    
    
    public struct ObjectGenerator : IteratorProtocol {
        
        fileprivate var _position: Int = 0
        fileprivate var _dictionary:Object
        fileprivate init(_ dictionary:Object) {
            _dictionary = dictionary
        }
        
        
        public mutating func next() -> (String, Value)? {
            if _position < _dictionary.count {
                defer { _position += 1 }
                return _dictionary[ObjectIndex(rawValue: _position)]
            }
            return nil
        }
    }
    
    public struct ObjectIndex : Comparable, _Incrementable, Equatable, RawRepresentable, ExpressibleByIntegerLiteral {
        public typealias IntegerLiteralType = Int
        
        public init(integerLiteral value: IntegerLiteralType) {
            _rawValue = value
        }
        
        public typealias RawValue = Int
        
        public init(rawValue: RawValue) {
            _rawValue = rawValue
        }
        /// The corresponding value of the "raw" type.
        ///
        /// `Self(rawValue: self.rawValue)!` is equivalent to `self`.
        public var rawValue: RawValue { return _rawValue }
        fileprivate var _rawValue:RawValue
        /// Returns the next consecutive value after `self`.
        ///
        /// - Requires: The next value is representable.
        public func successor() -> ObjectIndex {
            return ObjectIndex(rawValue: _rawValue + 1)
        }
        
    }
}

public func ==(lhs: JSON.ObjectIndex, rhs: JSON.ObjectIndex) -> Bool {
    return lhs.rawValue == rhs.rawValue
}
public func < (lhs: JSON.ObjectIndex, rhs: JSON.ObjectIndex) -> Bool {
    return lhs.rawValue < rhs.rawValue
}
public func <= (lhs: JSON.ObjectIndex, rhs: JSON.ObjectIndex) -> Bool {
    return lhs.rawValue <= rhs.rawValue
}
public func >= (lhs: JSON.ObjectIndex, rhs: JSON.ObjectIndex) -> Bool {
    return lhs.rawValue >= rhs.rawValue
}
public func > (lhs: JSON.ObjectIndex, rhs: JSON.ObjectIndex) -> Bool {
    return lhs.rawValue > rhs.rawValue
}


extension JSON.Value : CustomStringConvertible, CustomDebugStringConvertible {
    /// A textual representation of `self`.
    public var description: String {
        switch (value) {
        case let .jsonObject(dict)  :
            //let values = dict.map({ "\($0):\($1)" })
            return dict.description
        case let .jsonArray(array)  :
            let values = array.joined(separator: ", ")
            return "[\(values)]"
        case let .jsonNumber(num) : return num.stringValue
        case let .jsonString(str) :
            let text = str.data(using: String.Encoding.nonLossyASCII)?.toUTF8String() ?? ""
            return "\"\(text)\""
        case let .jsonError(error): return "\"(--->\(error)<---)\""
        case .jsonNull            : return "null"
        }
        //return "Unknow JSON"
    }
    /// A textual representation of `self`, suitable for debugging.
    public var debugDescription: String {
        return formatJSON(0)
    }
    
    fileprivate func formatJSON(_ retract:Int) -> String {
        switch (value) {
        case let .jsonObject(dict)  :
            return dict.formatJSON(retract)
        case let .jsonArray(array)  :
            var retractString = String(repeating: "\t", count: retract + 1)
            var result = array.joined(separator: ", ") { $0.formatJSON(retract + 1) }
            result = "[\n\(retractString)\(result)"
            retractString.remove(at: retractString.startIndex)
            return "\n\(retractString)\(result)\n\(retractString)]"
        case let .jsonNumber(num) : return num.stringValue
        case let .jsonString(str) :
            return "\"\(str)\""
        case let .jsonError(error): return "\"(--->\(error)<---)\""
        case .jsonNull            : return "null"
        }
    }
    
}


extension JSON.Object : CustomStringConvertible, CustomDebugStringConvertible {
    /// A textual representation of `self`.
    public var description: String {
        var result:String = ""
        for i:Int in 0 ..< _count {
            if !result.isEmpty { result += ", " }
            result += "\"\(_keys[i])\": \(_values[i])"
        }
        return "{\(result)}"
    }
    /// A textual representation of `self`, suitable for debugging.
    public var debugDescription: String {
        return formatJSON(0)
    }
    
    fileprivate func formatJSON(_ retract:Int) -> String {
        var result:String = ""
        var retractString = String(repeating: "\t", count: retract + 1)
        for i:Int in 0 ..< _count {
            if !result.isEmpty { result += ", \n\(retractString)" }
            result += "\"\(_keys[i])\": \(_values[i].formatJSON(retract + 1))"
        }
        result = "{\n\(retractString)\(result)"
        retractString.remove(at: retractString.startIndex)
        return "\n\(retractString)\(result)\n\(retractString)}"
    }
}

//extension JSON.Object : _Reflectable {
//    public func _getMirror() -> _MirrorType {
//        return _reflect(self)
//    }
//}



extension Data {
    
    var jsonValue:JSON.Value {
        if let value = try? JSONSerialization.jsonObject(with: self, options: JSONSerialization.ReadingOptions(rawValue: 0)) {
            return JSON.getValue(value as AnyObject)
        }
        return JSON.Value(error: "JSON Serialization fail")
    }
    
    // 为了方便，增加一个NSData 直接转 UTF8字符串的功能，这个很常用
    public func toUTF8String() -> String? {
        return NSString(data: self, encoding: String.Encoding.utf8.rawValue) as? String
    }
}


extension String {
    
    var jsonValue:JSON.Value {
        if let data = data(using: String.Encoding.utf8, allowLossyConversion: false) {
            return data.jsonValue
        }
        return JSON.Value(error: "String encoding utf8 fail")
    }
    
}


/*
public typealias JSONArray = (array:NSArray?, error:ErrorType?)
public typealias JSONObject = (dict:NSDictionary?, error:ErrorType?)

extension NSData {
    
    public func jsonParseToDictionary() -> JSONObject {
        do {
            let dict = try NSJSONSerialization.JSONObjectWithData(self, options: NSJSONReadingOptions(rawValue: 0)) as? NSDictionary
            return (dict, nil)
        } catch let error {
            return (nil, error)
        }
    }
    
    public func jsonParseToArray() -> JSONArray {
        do {
            let array = try NSJSONSerialization.JSONObjectWithData(self, options: NSJSONReadingOptions(rawValue: 0)) as? NSArray
            return (array, nil)
        } catch let error {
            return (nil, error)
        }
    }
    
    // 为了方便，增加一个NSData 直接转 UTF8字符串的功能，这个很常用
    public func toUTF8String() -> String? {
        return NSString(data: self, encoding: NSUTF8StringEncoding) as? String
    }
}

extension String {
    
    public func jsonParseToDictionary() -> JSONObject {
        return dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!.jsonParseToDictionary()
    }
    
    public func jsonParseToArray() -> JSONArray {
        return dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!.jsonParseToArray()
    }
    
}

extension NSDictionary {
    public func parseToJSON() -> String? {
        do {
            let data = try NSJSONSerialization.dataWithJSONObject(self, options: [NSJSONWritingOptions(rawValue: 0)])
            let json = String(data: data, encoding: NSUTF8StringEncoding)!
            let jsonData = json.dataUsingEncoding(NSNonLossyASCIIStringEncoding)!
            return String(data: jsonData, encoding: NSUTF8StringEncoding)
        } catch let error {
            print(error)
            return nil
        }
    }
}

infix operator ??= {
    associativity right
    precedence 90
    assignment
}

public func ??=<T>(inout lhs:T, rhs:AnyObject?) {
    lhs = rhs ?? lhs
}

//public func ??<T>(optional: AnyObject?, @autoclosure defaultValue:() -> T) -> T {

public func ??<T>(optional: AnyObject?, @autoclosure defaultValue:() -> T) -> T {
    
    guard let object: AnyObject = optional else {
        return defaultValue()
    }
    // 如果和默认值相同类型
    if let result = object as? T { return result }
    
    let defaultValue:T = defaultValue()
    switch (object, defaultValue) {
        // 如果是数字类型
    case (let result as NSDictionary,  _ as NSArray):
        return result.allValues as! T
    case (let result as NSArray,  _ as NSDictionary):
        let dict:NSMutableDictionary = NSMutableDictionary()
        for var i:Int = 0; i<result.count; i++ {
            dict[i] = result[i]
        }
        return dict as! T
    case (let result as NSNumber, _ as NSArray):
        return NSArray(object: result) as! T
    case (let result as NSNumber, _ as String):
        return result.stringValue as! T
    case (let result as NSNumber, _ as Bool):
        return result.boolValue as! T
    case (let result as NSNumber, _ as Int):
        return result.integerValue as! T
    case (let result as NSNumber, _ as UInt):
        return result.unsignedLongValue as! T
    case (let result as NSNumber, _ as Int8):
        return result.charValue as! T
    case (let result as NSNumber, _ as UInt8):
        return result.unsignedCharValue as! T
    case (let result as NSNumber, _ as Int16):
        return result.shortValue as! T
    case (let result as NSNumber, _ as UInt16):
        return result.unsignedShortValue as! T
    case (let result as NSNumber, _ as Int32):
        return result.intValue as! T
    case (let result as NSNumber, _ as UInt32):
        return result.unsignedIntValue as! T
    case (let result as NSNumber, _ as Int64):
        return result.longLongValue as! T
    case (let result as NSNumber, _ as UInt16):
        return result.unsignedLongLongValue as! T
    case (let result as NSNumber, _ as Float):
        return result.floatValue as! T
    case (let result as NSNumber, _ as Double):
        return result.doubleValue as! T
    case (let result as NSNumber, _ as NSDate):
        return NSDate(timeIntervalSince1970: result.doubleValue) as! T
        
        // 如果是字符串类型
    case (let result as NSString, _ as NSArray):
        return NSArray(object: result) as! T
    case (let result as NSString, _ as String):
        return result as! T
    case (let result as NSString, _ as Bool):
        return result.boolValue as! T
    case (let result as NSString, _ as Int):
        return result.integerValue as! T
    case (let result as NSString, _ as UInt):
        return UInt(result.integerValue) as! T
    case (let result as NSString, _ as Int8):
        return Int8(result.integerValue) as! T
    case (let result as NSString, _ as UInt8):
        return UInt8(result.integerValue) as! T
    case (let result as NSString, _ as Int16):
        return Int16(result.integerValue) as! T
    case (let result as NSString, _ as UInt16):
        return UInt16(result.integerValue) as! T
    case (let result as NSString, _ as Int32):
        return result.intValue as! T
    case (let result as NSString, _ as UInt32):
        return UInt32(result.intValue) as! T
    case (let result as NSString, _ as Int64):
        return result.longLongValue as! T
    case (let result as NSString, _ as UInt64):
        return UInt64(result.longLongValue) as! T
    case (let result as NSString, _ as Float):
        return result.floatValue as! T
    case (let result as NSString, _ as Double):
        return result.doubleValue as! T
//    case (let result as String, _ as Date):
//        guard let date = Date(result) else {
//            guard let date = Date(result, dateFormat:"yyyy-MM-dd") else {
//                return defaultValue
//            }
//            return date as! T
//        }
//        return date as! T
    case (let result as String, _ as NSDate):
        let formater = NSDateFormatter()
        formater.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let date = formater.dateFromString(result) {
            return date as! T
        } else {
            formater.dateFormat = "yyyy-MM-dd"
            if let date = formater.dateFromString(result) {
                return date as! T
            }
        }
        return defaultValue
    default:
        return defaultValue
    }
}
*/

