//
//  SheetViewController+Size.swift
//  GXSwiftDemo
//
//  Created by sgx on 2024/5/9.
//

import UIKit

// MARK: 更新size

extension SheetViewController {
    /// 业务方手动更新内在高度，即根据业务方设置的customView的高度自适应
    /// 注意：只有设置size为`.intrinsic`才会生效
    public func updateIntrinsicHeight() {
        contentViewController.updatePreferredHeight()
    }
    
    /// 将业务方传入的sizes根据高度做从低到高排序
    func updateOrderedSizes() {
        var concreteSizes: [(SheetSize, CGFloat)] = self.sizes.map {
            return ($0, self.height(for: $0))
        }
        concreteSizes.sort { $0.1 < $1.1 }
        self.orderedSizes = concreteSizes.map({ size, _ in size })
    }
    
    /// 根据SheetSize计算出具体高度
    func height(for size: SheetSize?) -> CGFloat {
        guard let size = size else { return 0 }
        let contentHeight: CGFloat
        let fullscreenHeight = self.view.bounds.height - self.view.safeAreaInsets.top
        switch (size) {
            case .intrinsic:
            contentHeight = self.contentViewController.preferredHeight + options.extraHeight
            case .specify(let height):
                contentHeight = height
            case .fullscreen:
                contentHeight = fullscreenHeight
            case .percent(let percent):
                contentHeight = (self.view.bounds.height) * CGFloat(percent)
            case .marginFromTop(let margin):
                contentHeight = (self.view.bounds.height) - margin
        }
        return min(fullscreenHeight, contentHeight)
    }
    
    /// 修改当前size
    func resize(
        to size: SheetSize,
        duration: TimeInterval = 0.2,
        animated: Bool = true,
        complete: (() -> Void)? = nil
    ) {
        let previousSize = self.currentSize
        self.currentSize = size
        
        let oldConstraintHeight = self.contentViewHeightConstraint?.constant ?? 0
        let newHeight = self.height(for: size)
        
        guard oldConstraintHeight != newHeight else {
            return
        }
        
        if animated {
            UIView.animate(withDuration: duration,
                           delay: 0,
                           options: self.options.transitionAnimationOptions,
                           animations: { [weak self] in
                self?.contentViewHeightConstraint?.constant = newHeight
                self?.view.layoutIfNeeded()
            }, completion: {[weak self] _ in
                self?.sizeModeChanged(previousSize, size)
                complete?()
            })
        } else {
            UIView.performWithoutAnimation {
                self.contentViewHeightConstraint?.constant = self.height(for: size)
                self.contentViewController.view.layoutIfNeeded()
            }
            self.sizeModeChanged(previousSize, size)
            complete?()
        }
    }
    
    func previousSize() -> SheetSize {
        var newSize = self.currentSize
        newSize = self.orderedSizes.first ?? self.currentSize
        for size in self.orderedSizes {
            if self.height(for: currentSize) > self.height(for: size) {
                newSize = size
            } else {
                break
            }
        }
        return newSize
    }
    
    func nextSize() -> SheetSize {
        var newSize = self.currentSize
        newSize = self.orderedSizes.last ?? self.currentSize
        for size in self.orderedSizes.reversed() {
            if self.height(for: currentSize) < self.height(for: size) {
                newSize = size
            } else {
                break
            }
        }
        return newSize
    }
}

extension SheetOptions {
    var extraHeight: CGFloat {
        return pullBarViewHeight + (UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0)
    }
}
