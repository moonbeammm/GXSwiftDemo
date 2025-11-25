//
//  BBMPTabScrollView.swift
//  BFCTabContainer
//
//  Created by 香辣虾 on 2020/3/21.
//  Copyright © 2020 bilibili. All rights reserved.
//

import UIKit

protocol BBMPTabScrollViewDataSource: AnyObject {
    /// item个数
    func bfc_numbersOfItem(in tabScrollView: BBMPTabScrollView) -> Int
    /// 下标对应item
    func bfc_tabItem(at index: Int, in tabScrollView: BBMPTabScrollView) -> BBMPTabItem
}

protocol BBMPTabScrollViewDelegate: UIScrollViewDelegate {
    /// 默认配置
    func bfc_tabConfig(in tabScrollView: BBMPTabScrollView) -> BBMPTabConfig?
    /// 选中对应下标回调
    func bfc_selectTabItem(at index: Int, in tabScrollView: BBMPTabScrollView)
}

@objc protocol BBMPTabScrollViewLayout: UIScrollViewDelegate {
    /// 自定义item布局
    /// - Parameters:
    ///   - items: 需要布局的items
    /// - Returns: 视图contentSize（用于设置滚动范围）
    @objc optional func bfc_layoutItems(_ items: [BBMPTabItem], in tabScrollView: BBMPTabScrollView) -> CGSize

    /// 自定义滚动样式
    /// - Parameters:
    ///   - progress: 进度
    ///   - animated: 是否动画
    ///   - isSelect: 是否更新选中态
    @objc optional func bfc_scorllToProgress(_ progress: CGFloat, animated: Bool, isSelect: Bool, in tabScrollView: BBMPTabScrollView)
}

class BBMPTabScrollView: UIScrollView {

    weak var dataSource: BBMPTabScrollViewDataSource?
    weak var scrollDelegate: BBMPTabScrollViewDelegate?
    weak var layout: BBMPTabScrollViewLayout?

    /// 指示器
    private(set) var indicator: UIView!
    /// 底部分割线
    private(set) var separator: UIView!

    /// 当前选中下标
    private(set) var selectIndex: Int = -1
    /// 当前选中item
    private(set) weak var selectItem: BBMPTabItem?

    private var numbersOfItem: Int = 0
    private var items: [BBMPTabItem] = []
    private var tabConfig: BBMPTabConfig = BBMPTabConfig.defaultConfig()
    private var container: UIStackView!

    private let itemTagDefault = 100

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        container = UIStackView()
        container.axis = .horizontal
        container.distribution = .equalSpacing
        container.alignment = .fill
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            container.heightAnchor.constraint(equalTo: heightAnchor)
        ])

        indicator = UIView()
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.layer.masksToBounds = true

        separator = UIView()
    }

    private var containerConstraints: [NSLayoutConstraint] = []

    private func resetConfig() {
        numbersOfItem = 0
        selectIndex = -1
        items.removeAll()

        if let config = scrollDelegate?.bfc_tabConfig(in: self) {
            tabConfig = config
        } else {
            tabConfig = BBMPTabConfig.defaultConfig()
        }

        // Container
        container.spacing = tabConfig.itemConfig.horizonMargin

        // 移除旧约束
        NSLayoutConstraint.deactivate(containerConstraints)
        containerConstraints.removeAll()

        // 添加新约束
        containerConstraints = [
            container.heightAnchor.constraint(equalTo: heightAnchor),
            container.topAnchor.constraint(equalTo: topAnchor, constant: tabConfig.contentInset.top),
            container.leadingAnchor.constraint(equalTo: leadingAnchor, constant: tabConfig.contentInset.left),
            container.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -tabConfig.contentInset.right),
            container.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -tabConfig.contentInset.bottom)
        ]
        NSLayoutConstraint.activate(containerConstraints)

        // Indicator
        let indicatorConfig = tabConfig.indicatorConfig
        indicator.heightAnchor.constraint(equalToConstant: indicatorConfig.height).isActive = true
        indicator.layer.cornerRadius = indicatorConfig.cornerRadius

        setNeedsLayout()
        layoutIfNeeded()
    }

    func reloadData() {
        // 删除所有内容
        container.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let currentSelectIndex = selectIndex
        resetConfig()

        // 添加item
        if let dataSource = dataSource {
            numbersOfItem = dataSource.bfc_numbersOfItem(in: self)
        }

        let itemConfig = tabConfig.itemConfig
        for index in 0..<numbersOfItem {
            let item = dataSource!.bfc_tabItem(at: index, in: self)
            item.delegate = self
            item.tag = itemTagDefault + index
            item.addTarget(self, action: #selector(itemClick(_:)), for: .touchUpInside)
            items.append(item)
            container.addArrangedSubview(item)

            var width = item.itemWidth > 0 ? item.itemWidth : itemConfig.itemWidth
            width += itemConfig.itemExpandWidth

            item.translatesAutoresizingMaskIntoConstraints = false
            item.widthAnchor.constraint(equalToConstant: width).isActive = true
        }

        // 调整item位置
        if let layout = layout,
           let size = layout.bfc_layoutItems?(items, in: self) {
            contentSize = size
        }

        // 添加指示条
        if numbersOfItem > 0 {
            addSubview(indicator)
        }

        selectToIndex(currentSelectIndex)
        setNeedsLayout()
        layoutIfNeeded()
    }

    @objc private func itemClick(_ item: BBMPTabItem) {
        let index = item.tag - itemTagDefault
        if !item.disable {
            selectToIndex(index, animated: true)
        }
        scrollDelegate?.bfc_selectTabItem(at: index, in: self)
    }

    func selectToIndex(_ index: Int) {
        selectToIndex(index, animated: false)
    }

    func selectToIndex(_ index: Int, animated: Bool) {
        scorllToProgress(CGFloat(index), animated: animated, isSelect: true)
        if let item = viewWithTag(index + itemTagDefault) as? BBMPTabItem {
            selectItem = item
            selectIndex = index
        }
    }

    func scorllToProgress(_ progress: CGFloat) {
        scorllToProgress(progress, animated: false, isSelect: false)
    }

    private var indicatorConstraints: [NSLayoutConstraint] = []

    private func scorllToProgress(_ progress: CGFloat, animated: Bool, isSelect: Bool) {
        if let layout = layout {
            layout.bfc_scorllToProgress?(progress, animated: animated, isSelect: isSelect, in: self)
        } else {
            let selectIdx = Int(floor(progress + 0.5))
            let expectIdx = progress > CGFloat(selectIdx) ? min(selectIdx + 1, numbersOfItem - 1) : max(0, selectIdx - 1)

            var selectItem = viewWithTag(selectIdx + itemTagDefault) as? BBMPTabItem
            let expectItem = viewWithTag(expectIdx + itemTagDefault) as? BBMPTabItem

            if selectItem == nil, let expect = expectItem {
                selectItem = expect
            }
            
            guard let selectItem = selectItem else { return }

            if isSelect {
                // 更新item选中态
                for item in items {
                    item.isSelected = (item == selectItem)
                }
            }

            let expectPercent = 1 - abs(CGFloat(expectIdx) - progress)
            let x: CGFloat
            if let expect = expectItem {
                x = (expect.frame.midX - selectItem.frame.midX) * expectPercent
            } else {
                x = 0
            }

            var w: CGFloat = 0.0
            if tabConfig.indicatorConfig.width > 0 {
                w = tabConfig.indicatorConfig.width
            } else {
                let expectWidth = expectItem?.itemWidth ?? selectItem.itemWidth
                w = (selectItem.itemWidth - expectWidth) * abs(CGFloat(expectIdx) - progress) +
                    (expectWidth - tabConfig.indicatorConfig.horizonMargin * 2)
            }

            let duration = animated ? 0.25 : 0
            UIView.animate(withDuration: duration) {
                // 移除旧约束
                NSLayoutConstraint.deactivate(self.indicatorConstraints)
                self.indicatorConstraints.removeAll()

                // 添加新约束
                self.indicatorConstraints = [
                    self.indicator.bottomAnchor.constraint(equalTo: self.container.bottomAnchor, constant: -self.tabConfig.indicatorConfig.bottomMargin),
                    self.indicator.centerXAnchor.constraint(equalTo: selectItem.centerXAnchor, constant: x),
                    self.indicator.widthAnchor.constraint(equalToConstant: w)
                ]
                NSLayoutConstraint.activate(self.indicatorConstraints)

                self.setNeedsLayout()
                self.layoutIfNeeded()
                self.scrollRectToVisible(selectItem.frame, animated: animated)
            }
        }
    }
}

// MARK: - BBMPTabItemProtocol
extension BBMPTabScrollView: BBMPTabItemProtocol {
    func onItemContentChanged() {
        reloadData()
    }
}
