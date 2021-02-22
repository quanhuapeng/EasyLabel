//
//  YYSentinel.swift
//  CoreTextDemo
//
//  Created by quanhua on 2020/8/22.
//  Copyright © 2020 ifanr. All rights reserved.
//

import UIKit

class YYSentinel: NSObject {

    private var _value: Int32 = 0
    
    public var value: Int32 {
        return _value
    }
    
    @discardableResult
    public func increase() -> Int32 {
        
        return OSAtomicIncrement32(&_value)
    }
}
