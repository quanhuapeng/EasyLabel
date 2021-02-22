//
//  YYAsyncLayer.swift
//  CoreTextDemo
//
//  Created by quanhua on 2020/8/22.
//  Copyright © 2020 ifanr. All rights reserved.
//

import UIKit

private let YYAsyncLayerGetReleaseQueue = DispatchQueue.global(qos: .utility)
private let onceToken = UUID().uuidString
private var queueCount = 0
private let MAX_QUEUE_COUNT = 16

private var counter: Int32 = 0

private var queues = [DispatchQueue](repeating: DispatchQueue(label: ""), count: MAX_QUEUE_COUNT)

private let YYAsyncLayerGetDisplayQueue: DispatchQueue = {
    
    DispatchQueue.once(token: onceToken) {
        
        queueCount = ProcessInfo().activeProcessorCount
        queueCount = queueCount < 1 ? 1 : queueCount > MAX_QUEUE_COUNT ? MAX_QUEUE_COUNT : queueCount
        
        for i in 0 ..< queueCount {
            queues[i] = DispatchQueue(label: "com.ibireme.MTkit.render")
        }
    }
    
    var cur = OSAtomicIncrement32(&counter)
    if cur < 0 {
        cur = -cur
    }
    
    return queues[Int(cur) % queueCount]
}()

class YYAsyncLayer: CALayer {
    
    var displaysAsynchronously = true
    var _sentinel: YYSentinel!
    var scale: CGFloat = 0
    private let _onceToken = UUID().uuidString
    
    override class func defaultValue(forKey key: String) -> Any? {
        if key == "displaysAsynchronously" {
            return true
        } else {
            return super.defaultValue(forKey: key)
        }
    }
    
    override init() {
        super.init()
        
        DispatchQueue.once(token: _onceToken) {
            scale = UIScreen.main.scale
        }
        
        contentsScale = scale
        
        _sentinel = YYSentinel()
    }
    
    // 取消绘制
    deinit {
        _sentinel.increase()
    }
    
    override func setNeedsDisplay() {
        self.cancelAsyncDisplay()
        super.setNeedsDisplay()
    }
    
    // 重写展示方法，设置 contents
    override func display() {
        super.contents = super.contents
        
        displayAsync(async: displaysAsynchronously)
    }
    
    private func displayAsync(async: Bool) {
        
        guard let delegate = self.delegate as? YYAsyncLayerDelegate else { return }
        
        let task = delegate.newAsyncDisplayTask
        
        if task.display == nil {
            task.willDisplay?(self)
            contents = nil
            task.didDisplay?(self, true)
            return
        }
        
        if async {
            task.willDisplay?(self)
            let sentinel = _sentinel
            let value = sentinel!.value
            let isCancelled = {
                return value != sentinel!.value
            }
            
            let size = bounds.size
            let opaque = isOpaque
            let scale = contentsScale
            var backgroundColor = (opaque && (self.backgroundColor != nil)) ? self.backgroundColor : nil
            
            // 当图层宽度或高度小于1时(此时没有绘制意义)
            if size.width < 1 || size.height < 1 {
                var image = contents
                
                contents = nil
                if image != nil {
                    YYAsyncLayerGetReleaseQueue.async {
                        image = nil
                    }
                    
                    task.didDisplay?(self, true)
                    backgroundColor = nil
                    return
                }
            }
            
            YYAsyncLayerGetDisplayQueue.async {
                guard !isCancelled() else { return }
                
                UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
                guard let context = UIGraphicsGetCurrentContext() else { return }
                
                if opaque {
                    
                    context.saveGState()
                    if backgroundColor == nil || backgroundColor!.alpha < 1 {
                        context.setFillColor(UIColor.white.cgColor)
                        context.addRect(CGRect(x: 0, y: 0, width: size.width * scale, height: size.height * scale))
                        context.fillPath()
                    }
                    
                    if let backgroundColor = backgroundColor {
                        context.setFillColor(backgroundColor)
                        context.addRect(CGRect(x: 0, y: 0, width: size.width * scale, height: size.height * scale))
                        context.fillPath()
                    }
                    
                    context.restoreGState()
                    backgroundColor = nil
                }
                
                task.display?(context, size, isCancelled)
                
                if isCancelled() {
                    UIGraphicsEndImageContext()
                    DispatchQueue.main.async {
                        task.didDisplay?(self, false)
                    }
                    return
                }
                
                let image = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                if isCancelled() {
                    UIGraphicsEndImageContext()
                    DispatchQueue.main.async {
                        task.didDisplay?(self, false)
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    if isCancelled() {
                        task.didDisplay?(self, false)
                    }else{
                        self.contents = image?.cgImage
                        task.didDisplay?(self, true)
                    }
                }
            }
        } else {
            _sentinel.increase()
            task.willDisplay?(self)
            UIGraphicsBeginImageContextWithOptions(bounds.size, isOpaque, contentsScale)
            guard let context = UIGraphicsGetCurrentContext() else { return }
            if isOpaque {
                var size = bounds.size
                size.width *= contentsScale
                size.height *= contentsScale
                context.saveGState()
            
                if backgroundColor == nil || backgroundColor!.alpha < 1 {
                    context.setFillColor(UIColor.white.cgColor)
                    context.addRect(CGRect(origin: .zero, size: size))
                    context.fillPath()
                }
                if let backgroundColor = backgroundColor {
                    context.setFillColor(backgroundColor)
                    context.addRect(CGRect(origin: .zero, size: size))
                    context.fillPath()
                }
                context.restoreGState()
            }
            
            task.display?(context, bounds.size, {return false })
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            contents = image?.cgImage
            task.didDisplay?(self, true)
        }
    }
    
    private func cancelAsyncDisplay() {
        // 增加计数，标明取消之前的渲染
        _sentinel.increase()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

protocol YYAsyncLayerDelegate {
    
    var newAsyncDisplayTask:  YYAsyncLayerDisplayTask { get }
}

/**
 YYAsyncLayer在后台渲染contents的显示任务类
 */
open class YYAsyncLayerDisplayTask: NSObject {
    
    /**
     这个block会在异步渲染开始的前调用，只在主线程调用。
     */
    public var willDisplay: ((CALayer) -> Void)?
    
    /**
     这个block会调用去显示layer的内容
     */
    public var display: ((_ context: CGContext, _ size: CGSize, _ isCancelled: (() -> Bool)?) -> Void)?
    
    /**
     这个block会在异步渲染结束后调用，只在主线程调用。
     */
    public var didDisplay: ((_ layer: CALayer, _ finished: Bool) -> Void)?
}
