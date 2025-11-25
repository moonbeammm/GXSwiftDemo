//
//  BBMPTabItem.swift
//  BFCTabContainer
//
//  Created by 香辣虾 on 2020/3/21.
//  Copyright © 2020 bilibili. All rights reserved.
//

import UIKit

protocol BBMPTabItemProtocol: AnyObject {
    func onItemContentChanged()
}

class BBMPTabItem: UIControl {
    var itemWidth: CGFloat = 0
    var disable: Bool = false
    weak var delegate: BBMPTabItemProtocol?
}

class BBMPTitleTabItem: BBMPTabItem {
    var title: String? {
        didSet {
            titleLabel.text = title
        }
    }

    var titleFont: UIFont?
    var titleSelectFont: UIFont?
    var titleColor: UIColor?
    var titleSelectColor: UIColor?

    var autoSize: Bool = true
    var autoMargin: CGFloat = 0

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        titleLabel.frame = bounds
        titleLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(titleLabel)
        isSelected = false
        // 注意：BFCUIAccessibility 需要在 Swift 中使用对应的可访问性 API
        accessibilityTraits = .button
    }

    override var isSelected: Bool {
        didSet {
            if isSelected {
                titleLabel.textColor = titleSelectColor ?? (titleColor ?? .black)
                titleLabel.font = titleSelectFont ?? (titleFont ?? .systemFont(ofSize: 17))
                accessibilityIdentifier = "tab_\(titleLabel.text ?? "")_selected"
            } else {
                titleLabel.textColor = titleColor ?? .black
                titleLabel.font = titleFont ?? .systemFont(ofSize: 17)
                accessibilityIdentifier = "tab_\(titleLabel.text ?? "")_unselected"
            }
        }
    }

    override var itemWidth: CGFloat {
        get {
            if autoSize {
                return titleLabel.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: frame.size.height)).width + autoMargin
            } else {
                return super.itemWidth
            }
        }
        set {
            super.itemWidth = newValue
        }
    }
}
