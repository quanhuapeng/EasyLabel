//
//  EasyLabel.swift
//  EasyLabel
//
//  Created by Quanhua Peng on 2021/2/21.
//

import UIKit

import UIKit

let EasyLabelMaxSize: CGSize = CGSize(width: 65536, height: 65536)

open class EasyLabel: UIView {
    
    public convenience init() {
        self.init(frame: .zero)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = .clear
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 是否异步绘制
    public var displaysAsynchronously: Bool = true {
        didSet {
            if let layer = layer as? YYAsyncLayer {
                layer.displaysAsynchronously = displaysAsynchronously
            }
        }
    }
    
    public override var backgroundColor: UIColor? {
        didSet {
            self.layer.backgroundColor = backgroundColor?.cgColor
            self.setNeedsDisplay()
        }
    }
    
    public var numberOfLines: Int = 0 {
        didSet {
            if self.numberOfLines != oldValue {
                self.setNeedsDisplay()
                self.invalidateIntrinsicContentSize()
            }
        }
    }
    
    public var text: String? {
        didSet {
            if self.text != oldValue {
                self.setNeedsDisplay()
                self.invalidateIntrinsicContentSize()
            }
        }
    }
    
    public var font: UIFont = UIFont.systemFont(ofSize: 12) {
        didSet {
            if self.font != oldValue {
                self.setNeedsDisplay()
                self.invalidateIntrinsicContentSize()
            }
        }
    }
    
    public var textColor: UIColor = .black {
        didSet {
            if self.textColor != oldValue {
                self.setNeedsDisplay()
            }
        }
    }
    
    public var textAlignment: NSTextAlignment = .left {
        didSet {
            if self.textAlignment != oldValue {
                self.setNeedsDisplay()
                self.invalidateIntrinsicContentSize()
            }
        }
    }
    
    
    public var lineBreakMode: NSLineBreakMode = .byTruncatingTail {
        didSet {
            if self.lineBreakMode != oldValue {
                self.setNeedsDisplay()
                self.invalidateIntrinsicContentSize()
            }
        }
    }
    
    public var truncationToken: NSAttributedString? = nil {
        didSet {
            if self.truncationToken != oldValue {
                self.setNeedsDisplay()
            }
        }
    }
    
    public var preferedMaxLayoutWidth: CGFloat = 0 {
        didSet {
            if self.preferedMaxLayoutWidth != oldValue {
                self.invalidateIntrinsicContentSize()
            }
        }
    }
    
    private func drwaTextInRect(_ rect: CGRect) {
        text?.drawInRect(rect, font: font, textColor: textColor, lineBreakMode: lineBreakMode, alignment: textAlignment, truncationToken: truncationToken)
    }
    
    open override func draw(_ rect: CGRect) {
        if let text = text, !text.isEmpty {
            let currentCtx = UIGraphicsGetCurrentContext()

            let bounds = self.bounds
            var drawRect: CGRect = .zero

            var maxSize = bounds.size
            if numberOfLines > 0 {
                maxSize.height = font.lineHeight * CGFloat(numberOfLines)
            }

            drawRect.size = text.size(with: font, constrainedTo: maxSize, lineBreakMode: lineBreakMode)

            drawRect.origin.y = (bounds.size.height - drawRect.size.height) / 2.0

            drawRect.origin.x = 0
            drawRect.size.width = bounds.size.width

            self.drwaTextInRect(drawRect)
            currentCtx?.restoreGState()
        }
    }
}

// MARK: - AutoLayout
extension EasyLabel {

    open override var intrinsicContentSize: CGSize {
        let width: CGFloat = (preferedMaxLayoutWidth > 0) ? preferedMaxLayoutWidth : EasyLabelMaxSize.width
        let height: CGFloat = (numberOfLines == 0) ? EasyLabelMaxSize.height : (font.lineHeight * CGFloat(numberOfLines))

        let maxSize = CGSize(width: width, height: height)
        let contentSize: CGSize = text?.size(with: font, constrainedTo: maxSize, lineBreakMode: lineBreakMode) ?? .zero
        let intrinsicContentWidth = min(contentSize.width, width)
        return CGSize(width: intrinsicContentWidth, height: contentSize.height)
    }
}

// MARK: - YYAsyncLayer

extension EasyLabel: YYAsyncLayerDelegate {
    
    var newAsyncDisplayTask: YYAsyncLayerDisplayTask {
        let task = YYAsyncLayerDisplayTask()
        task.willDisplay = { layer in
            
        }
        
        task.display = { [weak self] (context, size, isCancelled) in
            guard let self = self, let text = self.text, !text.isEmpty else { return }
            if (isCancelled?() ?? true) {
                return
            }
            
            var drawRect: CGRect = .zero
            var maxSize = size
            if self.numberOfLines > 0 {
                maxSize.height = self.font.lineHeight * CGFloat(self.numberOfLines)
            }
            
            drawRect.size = text.size(with: self.font, constrainedTo: maxSize, lineBreakMode: self.lineBreakMode)
            drawRect.origin.y = (size.height - drawRect.size.height) / 2.0
            drawRect.origin.x = 0
            drawRect.size.width = size.width
            
            self.drwaTextInRect(drawRect)
        }
        
        return task
    }

    
    open override class var layerClass: AnyClass {
        return YYAsyncLayer.self
    }
    
    
}
