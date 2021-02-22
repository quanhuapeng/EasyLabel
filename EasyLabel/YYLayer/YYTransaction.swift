//
//  YYTransaction.swift
//  CoreTextDemo
//
//  Created by quanhua on 2020/8/22.
//  Copyright © 2020 ifanr. All rights reserved.
//

import UIKit

private let onceToken = UUID().uuidString
private var transactionSet: Set<YYTransaction>?

private func YYTransactionSetup() {
    
    DispatchQueue.once(token: onceToken) {
        transactionSet = Set()
        
        let runloop = CFRunLoopGetCurrent()
        var observer: CFRunLoopObserver?
        
        let YYRunLoopObserverCallBack: CFRunLoopObserverCallBack = {_,_,_ in
            guard (transactionSet?.count) ?? 0 > 0 else { return }
            
            let currentSet = transactionSet
            transactionSet = Set()
            
            for transaction in currentSet! {
                _ = (transaction.target as AnyObject).perform(transaction.selector)
            }
        }
        
        observer = CFRunLoopObserverCreate(kCFAllocatorDefault,
                                           CFRunLoopActivity.beforeWaiting.rawValue | CFRunLoopActivity.exit.rawValue,
                                           true,
                                           0xFFFFFF,
                                           YYRunLoopObserverCallBack,
                                           nil)
        
        CFRunLoopAddObserver(runloop, observer, .commonModes)
    }
}

class YYTransaction: NSObject {
    
    var target: Any?
    var selector: Selector?
    
    static func transaction(with target: AnyObject, selector: Selector) -> YYTransaction?{
        
        let t = YYTransaction()
        t.target = target
        t.selector = selector
        return t
    }
    
    func commit() {
        
        guard target != nil && selector != nil else {
            //初始化runloop监听
            YYTransactionSetup()
            //添加行为到Set中
            transactionSet?.insert(self)
            return
        }
    }
    
    override var hash: Int {
        let v1 = selector.hashValue
        let v2 = (target as AnyObject).hash ?? 0
        return v1 ^ v2
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        
        guard let other = object as? YYTransaction else {
            return false
        }
        guard other != self else {
            return true
        }
        return other.selector == selector
    }
    
}


extension DispatchQueue {
    
    private static var _onceTracker = [String]()
    
    public class func once(token: String, block: () -> Void) {
        objc_sync_enter(self); defer { objc_sync_exit(self) }
        
        if _onceTracker.contains(token) {
            return
        }
        _onceTracker.append(token)
        block()
    }
}
