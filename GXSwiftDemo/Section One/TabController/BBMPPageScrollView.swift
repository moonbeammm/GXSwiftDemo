//
//  BBMPPageScrollView.swift
//  BFCTabContainer
//
//  Created by 香辣虾 on 2020/3/21.
//  Copyright © 2020 bilibili. All rights reserved.
//

import UIKit

class BBMPPageScrollView: UIScrollView {

    private(set) var container: UIStackView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        layoutViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
        layoutViews()
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // UITableViewCell 删除手势
        if NSStringFromClass(type(of: otherGestureRecognizer.view ?? UIView())) == "UITableViewWrapperView" &&
            otherGestureRecognizer is UIPanGestureRecognizer {
            return true
        }
        return false
    }

    private func setupViews() {
        container = UIStackView()
        container.axis = .horizontal
        container.alignment = .bottom
        container.distribution = .fillEqually
        container.spacing = 0
        addSubview(container)
    }

    private func layoutViews() {
        container.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            container.heightAnchor.constraint(equalTo: heightAnchor),
            container.widthAnchor.constraint(greaterThanOrEqualTo: widthAnchor)
        ])
    }
}
