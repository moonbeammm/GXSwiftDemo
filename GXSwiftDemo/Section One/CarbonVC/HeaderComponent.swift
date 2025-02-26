//
//  HeaderComponent.swift
//  GXSwiftDemo
//
//  Created by sgx on 2024/4/28.
//

import Foundation
import Carbon

struct HeaderComponent: IdentifiableComponent {
    var id: String { header.title }
    
    let header: GXHeader
    
    init(_ header: GXHeader) {
        self.header = header
    }
    
    func renderContent() -> HeaderContent {
        return HeaderContent()
    }
    
    func render(in content: HeaderContent) {
        content.header = header
    }
    func referenceSize(in bounds: CGRect) -> CGSize? {
        .init(width: bounds.width, height: 120)
    }
}

extension HeaderComponent {
    class HeaderContent: UIView {
        lazy var label: UILabel = {
           let t = UILabel()
            return t
        }()
        
        // MARK: Lifecycle

        override init(frame: CGRect) {
            super.init(frame: frame)

            backgroundColor = .white
            layer.cornerRadius = 12
            layer.shadowOffset = .init(width: 0, height: 1)
            layer.shadowRadius = 4
            layer.shadowOpacity = 0.3
            layer.shadowColor = UIColor(white: 0, alpha: 0.3).cgColor

            addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
                label.topAnchor.constraint(equalTo: topAnchor, constant: 8),
                label.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -8)
            ])
            print("sgx >>>> 创建content：\(self)")
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: Internal

        var header: GXHeader? {
            didSet {
                label.text = header?.title
            }
        }
    }
}
