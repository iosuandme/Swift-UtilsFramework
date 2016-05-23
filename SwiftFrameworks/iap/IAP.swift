//
//  IAP.swift
//  QuestionLib
//
//  Created by 慧趣小歪 on 16/5/20.
//  Copyright © 2016年 小分队. All rights reserved.
//

import Foundation
import StoreKit

// 把此协议当枚举实现 真实类型为字符串
public protocol IAPPayProduct: RawRepresentable, Hashable {
    static var prefix:String { get }
}

public enum IAPState:String {
    case Purchased
    case Failed
    case Restored
    case Canceled
}

public struct IAP {
    
    private static var paymentObserver:PaymentObserver!
    public static func purchaseProduct(product:SKProduct, quantity:Int, onComplete:(state:IAPState, transaction: SKPaymentTransaction)->()) {
        if paymentObserver == nil {
            paymentObserver = PaymentObserver()
            SKPaymentQueue.defaultQueue().addTransactionObserver(paymentObserver)
        }
        paymentObserver.onComplete = onComplete
        print("Buying \(product.productIdentifier)...")
        let payment = SKMutablePayment(product: product)
        payment.quantity = quantity
        SKPaymentQueue.defaultQueue().addPayment(payment)
    }
    
    /// 已有产品列表
    private static var _products:[SKProduct] = []
    public static var products:[SKProduct] {
        return _products
    }
    public static func payProductWithIdentifier(identifier:String) -> SKProduct {
        for product in _products where product.productIdentifier == identifier {
            return product
        }
        fatalError("找不到相应的内购条目")
    }
    
    /// 获取内购产品列表
    private static var request:SKProductsRequest?
    private static var requestDelegate:ProductsRequestDelegate?
    public static func getProducts<T:IAPPayProduct>(_:T.Type, onComplete:(error:NSError?)->()) {
        var identifiers = Set<String>()
        for item in T.enumerate() {
            identifiers.insert("\(T.prefix)\(item.rawValue)")
        }
        requestDelegate = ProductsRequestDelegate {
            _products = $1.sort { $0.price.integerValue < $1.price.integerValue }
            request = nil
            requestDelegate = nil
            onComplete(error: $0)
        }
        request = SKProductsRequest(productIdentifiers: identifiers)
        request!.delegate = requestDelegate
        request!.start()
    }
    
}


extension IAPPayProduct {
    public static var prefix:String { return "" }
    
    private static func enumerateEnum<T: Hashable>(_: T.Type) -> AnyGenerator<T> {
        var i = 0
        return AnyGenerator {
            let next = withUnsafePointer(&i) { UnsafePointer<T>($0).memory }
            defer { i += 1 }
            return next.hashValue == i ? next : nil
        }
    }
    
    public static func enumerate() -> AnyGenerator<Self> {
        return enumerateEnum(Self)
    }
}

class PaymentObserver:NSObject, SKPaymentTransactionObserver {
    var onComplete:((state:IAPState, transaction: SKPaymentTransaction)->())?
    
    func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch (transaction.transactionState) {
            case .Purchased:
                completeTransaction(transaction)
                break
            case .Failed:
                failedTransaction(transaction)
                break
            case .Restored:
                restoreTransaction(transaction)
                break
            case .Deferred:
                break
            case .Purchasing:
                break
            }
        }
        
    }
    
    private func completeTransaction(transaction: SKPaymentTransaction) {
        SKPaymentQueue.defaultQueue().finishTransaction(transaction)
        //provideContentForProductIdentifier(productIdentifier)
        onComplete?(state: .Purchased, transaction: transaction)
    }
    
    private func restoreTransaction(transaction: SKPaymentTransaction) {
        SKPaymentQueue.defaultQueue().finishTransaction(transaction)
        //provideContentForProductIdentifier(productIdentifier)
        onComplete?(state: .Restored, transaction: transaction.originalTransaction!)
    }
    
    // Helper: Saves the fact that the product has been purchased and posts a notification.
//    private func provideContentForProductIdentifier(productIdentifier: String) {
//        purchasedProductIdentifiers.insert(productIdentifier)
//        NSUserDefaults.standardUserDefaults().setBool(true, forKey: productIdentifier)
//        NSUserDefaults.standardUserDefaults().synchronize()
//    }
    
    private func failedTransaction(transaction: SKPaymentTransaction) {
        // 支付出错
        SKPaymentQueue.defaultQueue().finishTransaction(transaction)
        if transaction.error!.code != SKErrorCode.PaymentCancelled.rawValue {
            print("Transaction error: \(transaction.error!.localizedDescription)")
            onComplete?(state: .Failed, transaction: transaction)
        } else {
            onComplete?(state: .Canceled, transaction: transaction)
        }
    }
}

class ProductsRequestDelegate:NSObject, SKProductsRequestDelegate {
    var onComplete:(error:NSError?, products:[SKProduct])->()
    
    init(onComplete:(error:NSError?, products:[SKProduct])->()) {
        self.onComplete = onComplete
    }
    
    func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
        onComplete(error: nil, products: response.products)
    }
    
    func request(request: SKRequest, didFailWithError error: NSError) {
        onComplete(error: error, products: [])
    }
}