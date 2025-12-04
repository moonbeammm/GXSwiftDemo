//
//  BBMPTabController+Layout.swift
//  GXSwiftDemo
//
//  Created by sgx on 2025/11/19.
//

import UIKit

extension BBMPTabController {
    
    func configSubviews() {
        view.addSubview(contentView)
        contentView.addSubview(container)
        container.addArrangedSubview(bfc_tabContainer)

        bfc_tabView.addSubview(bottomLine)
        bfc_tabView.addSubview(bfc_tabItemView)
        bfc_tabContainer.addArrangedSubview(bfc_tabView)
        bfc_tabContainer.addArrangedSubview(bfc_pageView)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: view.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: view.widthAnchor),
            contentView.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])

        updateContainer(topConstant: 0)

        bottomLine.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bottomLine.bottomAnchor.constraint(equalTo: bfc_tabView.bottomAnchor),
            bottomLine.leadingAnchor.constraint(equalTo: bfc_tabView.leadingAnchor),
            bottomLine.trailingAnchor.constraint(equalTo: bfc_tabView.trailingAnchor),
            bottomLine.heightAnchor.constraint(equalToConstant: 0.5)
        ])

        bfc_tabItemView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bfc_tabItemView.topAnchor.constraint(equalTo: bfc_tabView.topAnchor),
            bfc_tabItemView.leadingAnchor.constraint(equalTo: bfc_tabView.leadingAnchor),
            bfc_tabItemView.trailingAnchor.constraint(equalTo: bfc_tabView.trailingAnchor),
            bfc_tabItemView.bottomAnchor.constraint(equalTo: bfc_tabView.bottomAnchor)
        ])

        view.layoutIfNeeded()
    }
    // MARK: - Public Methods

    /// 刷新：默认vc与当前vc相同不会触发生命周期
    func bfc_reloadData() {
        if Thread.isMainThread {
            _reloadData(force: false)
        } else {
            DispatchQueue.main.async {
                self._reloadData(force: false)
            }
        }
    }

    /// 刷新：默认vc与当前vc相同会触发生命周期
    func bfc_reloadDataForce() {
        if Thread.isMainThread {
            _reloadData(force: true)
        } else {
            DispatchQueue.main.async {
                self._reloadData(force: true)
            }
        }
    }

    /// 刷新：重新加载额外tab
    func bfc_reloadExtraTab() {
        guard let dataSource = dataSource,
              let extraTabConfig = dataSource.bfc_extraTabViewConfig(in: self),
              let extraTabView = dataSource.bfc_extraTabView(in: self) else {
            self.extraTabView?.removeFromSuperview()
            self.extraTabView = nil
            updateContainer(topConstant: 0)
            contentView.layoutIfNeeded()
            return
        }

        // 移除上一个
        self.extraTabView?.removeFromSuperview()
        contentView.insertSubview(extraTabView, at: 0)

        extraTabView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            extraTabView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: extraTabConfig.topMargin),
            extraTabView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            extraTabView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            extraTabView.widthAnchor.constraint(equalTo: contentView.widthAnchor),
            extraTabView.heightAnchor.constraint(equalToConstant: extraTabConfig.height)
        ])

        contentView.layoutIfNeeded()
        updateContainer(topConstant: extraTabConfig.height + extraTabConfig.topMargin)

        // 做动画
        if extraTabConfig.animation {
            UIView.animate(withDuration: TimeInterval(extraTabConfig.animationDuration),
                          delay: TimeInterval(extraTabConfig.delay),
                          options: .curveEaseInOut) {
                self.contentView.layoutIfNeeded()
            }
        }
        self.extraTabView = extraTabView
    }

    /// 刷新：重新加载底部
    func bfc_reloadBottom() {
        guard let dataSource = dataSource,
              let bottomTabConfig = dataSource.bfc_bottomTabViewConfig(in: self),
              let bottomTabView = dataSource.bfc_bottomTabView(in: self) else {
            self.bottomTabView?.removeFromSuperview()
            self.bottomTabView = nil
            return
        }

        // 移除上一个
        self.bottomTabView?.removeFromSuperview()
        container.addArrangedSubview(bottomTabView)
        container.layoutIfNeeded()

        bottomTabView.translatesAutoresizingMaskIntoConstraints = false
        bottomTabView.heightAnchor.constraint(equalToConstant: bottomTabConfig.height).isActive = true

        bottomTabView.layoutIfNeeded()
        bottomTabView.transform = CGAffineTransform(translationX: 0, y: bottomTabConfig.height)

        // 做动画
        if bottomTabConfig.animation {
            UIView.animate(withDuration: TimeInterval(bottomTabConfig.animationDuration),
                          delay: TimeInterval(bottomTabConfig.delay),
                          options: .curveEaseInOut,
                          animations: {
                bottomTabView.transform = .identity
            })
        } else {
            bottomTabView.transform = .identity
        }
        self.bottomTabView = bottomTabView
    }

    /// 切换到选中下标
    func bfc_selectToIndex(_ index: Int, animated: Bool) {
        if Thread.isMainThread {
            _selectToIndex(index, animated: animated, forceLifecycle: false)
        } else {
            DispatchQueue.main.async {
                self._selectToIndex(index, animated: animated, forceLifecycle: false)
            }
        }
    }

    // MARK: - Private Methods

    private func resetConfig(withSelectVC: Bool) {
        loadedViewControllers.removeAll()
        numbersOfViewController = 0
        selectIndex = BBMPTabControllerUnselect
        expectIndex = BBMPTabControllerUnselect
        if withSelectVC {
            selectViewController = nil
        }
        bfc_pageView.setContentOffset(.zero, animated: false)
    }

    private func _reloadData(force: Bool) {
        _reloadTabRightView()
        bfc_tabItemView.reloadData()
        _reloadDataForce(force: force)
    }

    

    private func _reloadTabRightView() {
        // 更新tab栏rightView
        rightView?.removeFromSuperview()

        // 移除旧的 tabItemView 约束
        NSLayoutConstraint.deactivate(tabItemViewConstraints)
        tabItemViewConstraints.removeAll()

        if let rightView = dataSource?.bfc_tabRightView(in: self) {
            bfc_tabView.addSubview(rightView)
            rightView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                rightView.rightAnchor.constraint(equalTo: bfc_tabView.leftAnchor, constant: view.frame.width - 12),
                rightView.topAnchor.constraint(equalTo: bfc_tabView.topAnchor, constant: 5),
                rightView.heightAnchor.constraint(equalToConstant: 30)
            ])

            // 添加带 inset 的约束
            tabItemViewConstraints = [
                bfc_tabItemView.topAnchor.constraint(equalTo: bfc_tabView.topAnchor),
                bfc_tabItemView.leadingAnchor.constraint(equalTo: bfc_tabView.leadingAnchor),
                bfc_tabItemView.trailingAnchor.constraint(equalTo: bfc_tabView.trailingAnchor, constant: -(140 + 12)),
                bfc_tabItemView.bottomAnchor.constraint(equalTo: bfc_tabView.bottomAnchor)
            ]
            self.rightView = rightView
        } else {
            // 恢复完整约束
            tabItemViewConstraints = [
                bfc_tabItemView.topAnchor.constraint(equalTo: bfc_tabView.topAnchor),
                bfc_tabItemView.leadingAnchor.constraint(equalTo: bfc_tabView.leadingAnchor),
                bfc_tabItemView.trailingAnchor.constraint(equalTo: bfc_tabView.trailingAnchor),
                bfc_tabItemView.bottomAnchor.constraint(equalTo: bfc_tabView.bottomAnchor)
            ]
        }
        NSLayoutConstraint.activate(tabItemViewConstraints)
        view.layoutIfNeeded()
    }

    private func _reloadDataForce(force: Bool) {
        bfc_scrollView.removeObservedViews()

        let numbersOfViewController = max(0, dataSource?.bfc_numbersOfViewController(in: self) ?? 0)

        // 获取选中态
        var selectIdx = 0
        if let idx = delegate?.bfc_defaultSelectIndex?(in: self) {
            selectIdx = max(0, min(numbersOfViewController - 1, idx))
        }

        let selectVC = dataSource?.bfc_viewController(at: selectIdx, in: self)
        let ignore = selectVC === selectViewController && !force

        // 移除所有视图
        for subVC in loadedViewControllers.values {
            // 生命周期管理
            if !ignore && subVC === selectViewController && bfc_vcStatus.rawValue < BBMPVCStatus.viewWillDisappear.rawValue {
                updateStatus(.viewWillDisappear, vc: subVC, animated: false)
            }
            subVC.view.removeFromSuperview()
            subVC.removeFromParent()
            // 生命周期管理
            if !ignore && subVC === selectViewController && bfc_vcStatus.rawValue < BBMPVCStatus.viewDidDisappear.rawValue {
                updateStatus(.viewDidDisappear, vc: subVC, animated: false)
            }
        }

        // 还原配置
        resetConfig(withSelectVC: !ignore)
        // 更新number
        self.numbersOfViewController = numbersOfViewController

        for index in 0..<self.numbersOfViewController {
            if selectIdx == index {
                insertVC(selectVC, toIndex: selectIdx)
            } else {
                let place = UIViewController()
                place.title = placeHolderKey
                place.view.backgroundColor = .clear
                insertVC(place, toIndex: index)
            }
        }

        // 判断是否需要提前load其他视图
        for index in 0..<self.numbersOfViewController {
            if delegate?.bfc_needPreloadViewController?(at: index, in: self) == true {
                _ = loadVCAtIndex(index)
            }
        }

        view.layoutIfNeeded()

        // 更新选中位置
        _selectToIndex(selectIdx, animated: false, forceLifecycle: force)
        // 更新额外tab区
        bfc_reloadExtraTab()
        // 更新底部区域
        bfc_reloadBottom()
        // 更新皮肤区域
        bfc_reloadSkin()
        // 刷新完成回调
        delegate?.bfc_reloadFinish?(in: self)
    }

    func tabAdaptSkin(progress: CGFloat) {
        if bfc_skinBgView.superview != nil {
            let newAlpha = 1 - bfc_skinBgView.alpha + progress
            bottomLine.alpha = newAlpha
            let newX = -1 * UIScreen.main.bounds.width * progress
            skinBgViewLeadingConstraint?.constant = newX
        }
    }

    private func bfc_reloadSkin() {
        guard let skinConfig = dataSource?.bfc_skinTabViewConfig(in: self) else {
            bfc_skinBgView.removeFromSuperview()
            skinBgViewLeadingConstraint = nil
            return
        }

        bfc_skinBgView.removeFromSuperview()
        skinBgViewLeadingConstraint = nil

        if skinConfig.hasSkin {
            contentView.insertSubview(bfc_skinBgView, at: 0)
            bfc_skinBgView.translatesAutoresizingMaskIntoConstraints = false

            let leadingConstraint = bfc_skinBgView.leadingAnchor.constraint(equalTo: container.leadingAnchor)
            skinBgViewLeadingConstraint = leadingConstraint

            NSLayoutConstraint.activate([
                bfc_skinBgView.topAnchor.constraint(equalTo: container.topAnchor),
                leadingConstraint,
                bfc_skinBgView.widthAnchor.constraint(equalToConstant: skinConfig.width),
                bfc_skinBgView.heightAnchor.constraint(equalToConstant: skinConfig.height)
            ])
        }
    }

    private func updateContainer(topConstant: CGFloat) {
        // 移除旧约束
        NSLayoutConstraint.deactivate(containerConstraints)
        containerConstraints.removeAll()

        // 添加新约束
        container.translatesAutoresizingMaskIntoConstraints = false
        containerConstraints = [
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: topConstant),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ]
        NSLayoutConstraint.activate(containerConstraints)
    }

    // ✅ 公开方法：用于ExtraTab动画时更新container的topMargin
    func bfc_updateContainerTopMargin(_ topConstant: CGFloat, animated: Bool = false) {
        updateContainer(topConstant: topConstant)

        if animated {
            UIView.animate(withDuration: 0.25) {
                self.contentView.layoutIfNeeded()
            }
        } else {
            contentView.layoutIfNeeded()
        }
    }

}
