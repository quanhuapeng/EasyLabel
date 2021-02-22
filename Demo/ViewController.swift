//
//  ViewController.swift
//  Demo
//
//  Created by Quanhua Peng on 2021/2/22.
//

import UIKit
import EasyLabel

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
let textFont = UIFont.systemFont(ofSize: 15)
let screenWidth = UIScreen.main.bounds.width
let labelWidth = screenWidth-20*2

let text1 = "在过去的几年中，技术一直在迅速变化，我们在数字世界中引入了许多创新。尽管其中一些并不那么重要，但还是有一些被证明是成功的。促成这些变化的技术之一是增强现实，它对包括零售、游戏和娱乐在内的许多行业产生了重大影响。"
let labelHeight1 = text1.height(with: labelWidth, font: textFont)
let label1 = EasyLabel(frame: CGRect(x: 20, y: 100, width: labelWidth, height: labelHeight1))
label1.font = textFont
label1.textColor = .red
label1.text = text1
self.view.addSubview(label1)

// 超过 5 行显示...
let text2 = "在过去的几年中，技术一直在迅速变化，我们在数字世界中引入了许多创新。尽管其中一些并不那么重要，但还是有一些被证明是成功的。促成这些变化的技术之一是增强现实，它对包括零售、游戏和娱乐在内的许多行业产生了重大影响。AR还影响了数字通信领域，在发生疫情初期，我们当中许多人不得不开始在家中进行日常工作，学习和其他活动，这一点尤其明显。"
let labelHeight2 = text2.height(with: labelWidth, font: textFont, numberOfLines: 5, lineBreakMode: .byTruncatingTail)
let label2 = EasyLabel(frame: CGRect(x: 20, y: label1.frame.maxY + 30, width: labelWidth, height: labelHeight2))
label2.numberOfLines = 5
label2.displaysAsynchronously = true
label2.lineBreakMode = .byTruncatingTail
label2.font = textFont
label2.textColor = .blue
label2.text = text2
self.view.addSubview(label2)

// 超过 5 行显示 ...[展开]
let labelHeight3 = text2.height(with: labelWidth, font: textFont, numberOfLines: 5, lineBreakMode: .byTruncatingTail)
let label3 = EasyLabel(frame: CGRect(x: 20, y: label2.frame.maxY + 30, width: labelWidth, height: labelHeight3))
label3.numberOfLines = 5
label3.lineBreakMode = .byTruncatingTail
label3.font = textFont
label3.textColor = .orange
label3.text = text2
label3.truncationToken = NSAttributedString(string: "...[更多]", attributes: [NSAttributedString.Key.foregroundColor: UIColor.red])
self.view.addSubview(label3)
        
        
    }

}

