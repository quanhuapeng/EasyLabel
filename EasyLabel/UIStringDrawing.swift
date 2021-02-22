//
//  UIStringDrawing.swift
//  CoreTextDemo
//
//  Created by quanhua on 2020/8/17.
//  Copyright © 2020 ifanr. All rights reserved.
//

import Foundation
import UIKit


public func CreateCTLinesForString(_ string: String, constrainedTo size: CGSize, font: UIFont, textColor: UIColor, lineBreakMode: NSLineBreakMode, truncationToken: NSAttributedString?, renderSize: inout CGSize) -> [CTLine] {
    
    var lines = [CTLine]()
    var drawSize: CGSize = .zero
    
    let attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: textColor]
    
    let attributedString = NSAttributedString(string: string, attributes: attributes)
    let typesetter = CTTypesetterCreateWithAttributedString(attributedString)
    
    // 字符个数
    let stringLength = CFAttributedStringGetLength(attributedString)
    let lineHeight = font.lineHeight
    let capHeight = font.capHeight
    
    var start: CFIndex = 0
    var isLastLine: Bool = false
    
    while (start < stringLength && !isLastLine) {
        drawSize.height += lineHeight
        isLastLine = (drawSize.height+capHeight >= size.height)
        
        var usedCharacters: CFIndex = 0
        var line: CTLine?
        
        if (isLastLine && (lineBreakMode != .byWordWrapping && lineBreakMode != .byCharWrapping)) {
            
            if lineBreakMode == .byClipping {
                usedCharacters = CTTypesetterSuggestClusterBreak(typesetter, start, Double(size.width))
                line = CTTypesetterCreateLine(typesetter, CFRangeMake(start, usedCharacters))
            } else {
                
                let truncType: CTLineTruncationType
                
                if lineBreakMode == .byTruncatingHead {
                    truncType = .start
                } else if lineBreakMode == .byTruncatingTail {
                    truncType = .end
                } else {
                    truncType = .middle
                }
                
                usedCharacters = stringLength - start
                let truncationLineString = truncationToken ?? NSAttributedString(string: "…", attributes: attributes)
                let truncationLine = CTLineCreateWithAttributedString(truncationLineString)
                let tempLine = CTTypesetterCreateLine(typesetter, CFRangeMake(start, usedCharacters))
                line = CTLineCreateTruncatedLine(tempLine, Double(size.width), truncType, truncationLine)
            }
        } else {
            
            if lineBreakMode == .byCharWrapping {
                usedCharacters = CTTypesetterSuggestClusterBreak(typesetter, start, Double(size.width))
            } else {
                usedCharacters = CTTypesetterSuggestLineBreak(typesetter, start, Double(size.width))
            }
            
            line = CTTypesetterCreateLine(typesetter, CFRangeMake(start, usedCharacters))
        }
        
        if let line = line {
            drawSize.width = max(drawSize.width, CGFloat(ceilf(Float(CTLineGetTypographicBounds(line, nil, nil, nil)))))
            
            lines.append(line)
        }
        
        start += usedCharacters
    }
    
    renderSize = drawSize
    
    return lines
}

public extension String {
    
    @discardableResult
    func drawInRect(_ rect: CGRect, font: UIFont, textColor: UIColor, lineBreakMode: NSLineBreakMode, alignment: NSTextAlignment, truncationToken: NSAttributedString?) -> CGSize {
        
        var actualSize: CGSize = .zero
        let lines = CreateCTLinesForString(self, constrainedTo: rect.size, font: font, textColor: textColor, lineBreakMode: lineBreakMode, truncationToken: truncationToken, renderSize: &actualSize)
        
        let numberOfLines = lines.count
        let fontLineHeight = font.lineHeight
        var textOffset: CGFloat = 0
        
        let ctx: CGContext? = UIGraphicsGetCurrentContext()
        ctx?.saveGState()
        ctx?.translateBy(x: rect.origin.x, y: rect.origin.y+font.ascender)
        ctx?.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
        
        for lineNumber in 0..<numberOfLines {
            let line = lines[lineNumber]
            let flush: CGFloat
            switch alignment {
            case .center: flush = 0.5
            case .left: flush = 0
            case .right: flush = 1.0
            default: flush = 0
            }
            
            let penOffset = CTLineGetPenOffsetForFlush(line, flush, Double(rect.size.width))
            ctx?.textPosition = CGPoint(x: CGFloat(penOffset), y: textOffset)
            CTLineDraw(line, ctx!)
            textOffset += fontLineHeight
        }
        
        ctx?.restoreGState()
        
        actualSize.height = min(actualSize.height, rect.size.height)
        
        return actualSize
    }
    
    func size(with font: UIFont, constrainedTo size: CGSize, lineBreakMode: NSLineBreakMode) -> CGSize {
        
        var resultingSize: CGSize = .zero
        
        _ = CreateCTLinesForString(self, constrainedTo: size, font: font, textColor: UIColor.clear, lineBreakMode: lineBreakMode, truncationToken: nil, renderSize: &resultingSize)
        
        return resultingSize
    }
    
    func height(with width: CGFloat, font: UIFont, numberOfLines: Int = 0, lineBreakMode: NSLineBreakMode = .byTruncatingTail) -> CGFloat {
        
        let constrainedHeight = (numberOfLines == 0) ? CGFloat(Float.greatestFiniteMagnitude) : (CGFloat(numberOfLines) * font.lineHeight)
        let constrainedSize = CGSize(width: width, height: constrainedHeight)
        return size(with: font, constrainedTo: constrainedSize, lineBreakMode: lineBreakMode).height
    }
    
}
