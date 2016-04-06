//
//  Operator.swift
//  NetWork
//
//  Created by 慧趣小歪 on 16/3/25.
//  Copyright © 2016年 小分队. All rights reserved.
//
//  那些曾被Swift删除但是很有用的运算符
//

import Foundation

prefix operator * {}
prefix operator ++ {}
prefix operator -- {}
postfix operator -- {}
postfix operator ++ {}

infix operator |= {
associativity right
precedence 90
assignment
}
infix operator &= {
associativity right
precedence 90
assignment
}
infix operator ^= {
associativity right
precedence 90
assignment
}

// MARK: - * 指针
/// Replace `i` with its `successor()` and return the original value of `i`.
@warn_unused_result
prefix public func *<T>(any: T) -> UnsafePointer<T> {
    var a = any
    return getPointer(&a)
}
private func getPointer<T>(pointer:UnsafePointer<T>) -> UnsafePointer<T> {
    return pointer
}

// MARK: - ++

/// Replace `i` with its `successor()` and return the original value of `i`.
postfix public func ++<T : _Incrementable>(inout i: T) -> T {
    let j = i
    i = i.successor()
    return j
}
/// Replace `i` with its `successor()` and return the updated value of `i`.
prefix public func ++<T : _Incrementable>(inout i: T) -> T {
    i = i.successor()
    return i
}

prefix public func ++(inout x: UInt32) -> UInt32 {
    x += 1
    return x
}

postfix public func ++(inout x: UInt32) -> UInt32 {
    let y = x
    x += 1
    return y
}

prefix public func ++(inout x: Int32) -> Int32 {
    x += 1
    return x
}

postfix public func ++(inout x: Int32) -> Int32 {
    let y = x
    x += 1
    return y
}

prefix public func ++(inout x: UInt64) -> UInt64 {
    x += 1
    return x
}

postfix public func ++(inout x: UInt64) -> UInt64 {
    let y = x
    x += 1
    return y
}

postfix public func ++(inout x: Int16) -> Int16 {
    let y = x
    x += 1
    return y
}

prefix public func ++(inout x: Int16) -> Int16 {
    x += 1
    return x
}

postfix public func ++(inout x: UInt16) -> UInt16 {
    let y = x
    x += 1
    return y
}

postfix public func ++(inout lhs: Float80) -> Float80 {
    let rhs = lhs
    lhs += 1
    return rhs
}

prefix public func ++(inout rhs: Float80) -> Float80 {
    rhs += 1
    return rhs
}

prefix public func ++(inout x: UInt16) -> UInt16 {
    x += 1
    return x
}

postfix public func ++(inout x: Int8) -> Int8 {
    let y = x
    x += 1
    return y
}

prefix public func ++(inout x: Int8) -> Int8 {
    x += 1
    return x
}

postfix public func ++(inout x: UInt8) -> UInt8 {
    let y = x
    x += 1
    return y
}

prefix public func ++(inout x: UInt8) -> UInt8 {
    x += 1
    return x
}

postfix public func ++(inout lhs: Double) -> Double {
    let rhs = lhs
    lhs += 1
    return rhs
}

prefix public func ++(inout rhs: Double) -> Double {
    rhs += 1
    return rhs
}

postfix public func ++(inout lhs: Float) -> Float {
    let rhs = lhs
    lhs += 1
    return rhs
}

prefix public func ++(inout rhs: Float) -> Float {
    rhs += 1
    return rhs
}

postfix public func ++(inout x: Int) -> Int {
    let y = x
    x += 1
    return y
}


prefix public func ++(inout x: Int) -> Int {
    x += 1
    return x
}

postfix public func ++(inout x: UInt) -> UInt {
    let y = x
    x += 1
    return y
}


prefix public func ++(inout x: UInt) -> UInt {
    x += 1
    return x
}

postfix public func ++(inout x: Int64) -> Int64 {
    let y = x
    x += 1
    return y
}


prefix public func ++(inout x: Int64) -> Int64 {
    x += 1
    return x
}

// MARK: - --

/// Replace `i` with its `predecessor()` and return the updated value of `i`.
prefix public func --<T : BidirectionalIndexType>(inout i: T) -> T {
    i = i.predecessor()
    return i
}
/// Replace `i` with its `predecessor()` and return the original value of `i`.
postfix public func --<T : BidirectionalIndexType>(inout i: T) -> T {
    let j = i
    i = i.predecessor()
    return j
}

prefix public func --(inout rhs: Double) -> Double {
    rhs -= 1
    return rhs
}

postfix public func --(inout lhs: Double) -> Double {
    let rhs = lhs
    lhs -= 1
    return rhs
}

postfix public func --(inout lhs: Float) -> Float {
    let rhs = lhs
    lhs -= 1
    return rhs
}

prefix public func --(inout rhs: Float80) -> Float80 {
    rhs -= 1
    return rhs
}

prefix public func --(inout rhs: Float) -> Float {
    rhs -= 1
    return rhs
}

postfix public func --(inout lhs: Int) -> Int {
    let rhs = lhs
    lhs -= 1
    return rhs
}

prefix public func --(inout rhs: Int) -> Int {
    rhs -= 1
    return rhs
}

postfix public func --(inout lhs: Float80) -> Float80 {
    let rhs = lhs
    lhs -= 1
    return rhs
}

postfix public func --(inout lhs: UInt) -> UInt {
    let rhs = lhs
    lhs -= 1
    return rhs
}

prefix public func --(inout rhs: UInt) -> UInt {
    rhs -= 1
    return rhs
}

postfix public func --(inout lhs: Int64) -> Int64 {
    let rhs = lhs
    lhs -= 1
    return rhs
}

postfix public func --(inout lhs: UInt32) -> UInt32 {
    let rhs = lhs
    lhs -= 1
    return rhs
}

prefix public func --(inout rhs: Int64) -> Int64 {
    rhs -= 1
    return rhs
}

prefix public func --(inout rhs: UInt8) -> UInt8 {
    rhs -= 1
    return rhs
}

postfix public func --(inout lhs: UInt8) -> UInt8 {
    let rhs = lhs
    lhs -= 1
    return rhs
}

prefix public func --(inout rhs: Int8) -> Int8 {
    rhs -= 1
    return rhs
}

postfix public func --(inout lhs: Int8) -> Int8 {
    let rhs = lhs
    lhs -= 1
    return rhs
}

postfix public func --(inout lhs: UInt64) -> UInt64 {
    let rhs = lhs
    lhs -= 1
    return rhs
}

prefix public func --(inout rhs: UInt64) -> UInt64 {
    rhs -= 1
    return rhs
}

prefix public func --(inout rhs: UInt16) -> UInt16 {
    rhs -= 1
    return rhs
}

postfix public func --(inout lhs: UInt16) -> UInt16 {
    let rhs = lhs
    lhs -= 1
    return rhs
}

prefix public func --(inout rhs: Int16) -> Int16 {
    rhs -= 1
    return rhs
}

postfix public func --(inout lhs: Int32) -> Int32 {
    let rhs = lhs
    lhs -= 1
    return rhs
}

postfix public func --(inout lhs: Int16) -> Int16 {
    let rhs = lhs
    lhs -= 1
    return rhs
}

prefix public func --(inout rhs: UInt32) -> UInt32 {
    rhs -= 1
    return rhs
}

prefix public func --(inout rhs: Int32) -> Int32 {
    rhs -= 1
    return rhs
}


// MARK: - &=

public func &=(inout lhs: Int, rhs: Int) {
    lhs = lhs & rhs
}

public func &=(inout lhs: UInt, rhs: UInt) {
    lhs = lhs & rhs
}

public func &=(inout lhs: Int64, rhs: Int64) {
    lhs = lhs & rhs
}

public func &=(inout lhs: UInt64, rhs: UInt64) {
    lhs = lhs & rhs
}

public func &=(inout lhs: Int32, rhs: Int32) {
    lhs = lhs & rhs
}

public func &=(inout lhs: UInt32, rhs: UInt32) {
    lhs = lhs & rhs
}

public func &=(inout lhs: Int16, rhs: Int16) {
    lhs = lhs & rhs
}

public func &=(inout lhs: UInt16, rhs: UInt16) {
    lhs = lhs & rhs
}

public func &=(inout lhs: Int8, rhs: Int8) {
    lhs = lhs & rhs
}

public func &=(inout lhs: UInt8, rhs: UInt8){
    lhs = lhs & rhs
}

// MARK: - |=

public func |=(inout lhs: Int, rhs: Int) {
    lhs = lhs | rhs
}

public func |=(inout lhs: UInt, rhs: UInt) {
    lhs = lhs | rhs
}

public func |=(inout lhs: Int64, rhs: Int64) {
    lhs = lhs | rhs
}

public func |=(inout lhs: UInt64, rhs: UInt64) {
    lhs = lhs | rhs
}

public func |=(inout lhs: Int32, rhs: Int32) {
    lhs = lhs | rhs
}

public func |=(inout lhs: UInt32, rhs: UInt32) {
    lhs = lhs | rhs
}

public func |=(inout lhs: Int16, rhs: Int16) {
    lhs = lhs | rhs
}

public func |=(inout lhs: UInt16, rhs: UInt16) {
    lhs = lhs | rhs
}

public func |=(inout lhs: Int8, rhs: Int8) {
    lhs = lhs | rhs
}

public func |=(inout lhs: UInt8, rhs: UInt8) {
    lhs = lhs | rhs
}


// MARK: - ^=

public func ^=(inout lhs: Int, rhs: Int) {
    lhs = lhs ^ rhs
}

public func ^=(inout lhs: UInt, rhs: UInt) {
    lhs = lhs ^ rhs
}

public func ^=(inout lhs: Int64, rhs: Int64) {
    lhs = lhs ^ rhs
}

public func ^=(inout lhs: UInt64, rhs: UInt64) {
    lhs = lhs ^ rhs
}

public func ^=(inout lhs: Int32, rhs: Int32) {
    lhs = lhs ^ rhs
}

public func ^=(inout lhs: UInt32, rhs: UInt32) {
    lhs = lhs ^ rhs
}

public func ^=(inout lhs: Int16, rhs: Int16) {
    lhs = lhs ^ rhs
}

public func ^=(inout lhs: UInt16, rhs: UInt16) {
    lhs = lhs ^ rhs
}

public func ^=(inout lhs: Int8, rhs: Int8) {
    lhs = lhs ^ rhs
}

public func ^=(inout lhs: UInt8, rhs: UInt8) {
    lhs = lhs ^ rhs
}

