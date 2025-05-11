//
//  ExpandLabelVC.swift
//  GXSwiftDemo
//
//  Created by 孙广鑫 on 2024/12/19.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

extension Reactive where Base: UIView {
    var hitTest: Observable<(CGPoint?, UIEvent?)> {
        methodInvoked(#selector(UIView.hitTest(_:with:))).map { args in
            var point = args[0] as? CGPoint
            var event = args[1] as? UIEvent
            return (point, event)
        }
    }
}

class ExpandableLabel: UILabel {
    
    private let maxLines = 2
    private let ellipsis = "..."
    private let expandText = "展开"
    
    var originalText: String? {
        didSet {
            updateText()
        }
    }
    
    private func updateText() {
        guard let originalText = originalText else { return }
        
        let fullText = originalText + ellipsis + expandText
        let attributedString = NSMutableAttributedString(string: fullText)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingTail
        
        let expandRange = (fullText as NSString).range(of: expandText)
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: fullText.count))
        attributedString.addAttribute(.foregroundColor, value: UIColor.blue, range: expandRange)
        
        self.attributedText = attributedString
        
        let size = CGSize(width: self.frame.width, height: CGFloat.greatestFiniteMagnitude)
        let boundingRect = attributedString.boundingRect(with: size, options: .usesLineFragmentOrigin, context: nil)
        
        if boundingRect.height > self.font.lineHeight * CGFloat(maxLines) {
            let truncatedText = truncateText(originalText)
            let truncatedAttributedString = NSMutableAttributedString(string: truncatedText + ellipsis + expandText)
            truncatedAttributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: truncatedText.count + ellipsis.count + expandText.count))
            truncatedAttributedString.addAttribute(.foregroundColor, value: UIColor.blue, range: expandRange)
            self.attributedText = truncatedAttributedString
        }
    }
    
    private func truncateText(_ text: String) -> String {
        var truncatedText = text
        while truncatedText.count > 0 {
            let size = CGSize(width: self.frame.width, height: CGFloat.greatestFiniteMagnitude)
            let attributedString = NSAttributedString(string: truncatedText + ellipsis + expandText)
            let boundingRect = attributedString.boundingRect(with: size, options: .usesLineFragmentOrigin, context: nil)
            
            if boundingRect.height <= self.font.lineHeight * CGFloat(maxLines) {
                break
            }
            
            truncatedText = String(truncatedText.dropLast())
        }
        return truncatedText
    }
}
class ExpandLabelVC: UIViewController {
    var disposeBag = DisposeBag()
    lazy var label: UILabel = {
        let t = UILabel()
        t.backgroundColor = .red
        t.textColor = .white
        t.numberOfLines = 3
        return t
    }()
    
    lazy var text: String = "1234567890123456789012345678901234567890123456789012345678901234567890"
    
    @objc func tap() {
        print("sgx tap")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //open func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView?
    view.rx.hitTest.share().subscribe { args in
        print("sgx hitTest point: \(args.0) event: \(args.1)")
    }.disposed(by: disposeBag)

        
        let testView = UIButton(type: .custom)
        testView.backgroundColor = .blue
        testView.addTarget(self, action: #selector(tap), for: .touchUpInside)
        view.addSubview(testView)
        testView.translatesAutoresizingMaskIntoConstraints = false
        testView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -100).isActive = true
        testView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 100).isActive = true
        testView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 200).isActive = true
        testView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -200).isActive = true
        
        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 100).isActive = true
        label.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -100).isActive = true
        label.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 100).isActive = true
        label.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        
        let isPlaying = true
        let textColor: UIColor = isPlaying ? .blue : .darkGray
        let text = self.text
        let font = UIFont.systemFont(ofSize: 14)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.02
        paragraphStyle.lineBreakMode = .byTruncatingTail
        paragraphStyle.firstLineHeadIndent = isPlaying ? 12+4 : 0
        // first line attrs
        let result = NSMutableAttributedString(string: text, attributes: [
            .paragraphStyle: paragraphStyle,
            .font: font,
            .foregroundColor: textColor
        ])
        
        let paragraphStyle1 = NSMutableParagraphStyle()
        paragraphStyle1.lineHeightMultiple = 1.02
        paragraphStyle1.lineBreakMode = .byTruncatingTail
        paragraphStyle1.firstLineHeadIndent = isPlaying ? 12+4 : 0
        paragraphStyle1.tailIndent = 30
        
        result.addAttribute(.paragraphStyle, value: paragraphStyle1, range: NSRange(location: text.count-60, length: 60))
        
        label.attributedText = result
        
    }

}
