//
//  SheetViewController+Gesture-New.swift
//  GXSwiftDemo
//
//  Created by sgx on 2024/5/9.
//

import UIKit

extension SheetViewController {
    func calculateHeight(_ point: CGPoint) -> (CGFloat, CGFloat) {
        let minHeight = self.height(for: self.orderedSizes.first)
        let maxHeight = max(self.height(for: self.orderedSizes.last), panGesture.firstTouchSize.height)
        
        var newHeight = max(0, panGesture.firstTouchSize.height + (panGesture.firstTouchPoint.y - point.y))
        
        var offset: CGFloat = 0
        
        // 滑动低于了最小高度
        if newHeight < minHeight {
            offset = minHeight - newHeight
            newHeight = minHeight
        }
        // 滑动超出了最大高度
        if newHeight > maxHeight {
            // 滑到顶部的弹性效果
            // logConstraintValueForYPosition（）计算出的结果会比maxHeight大一点，比newHeight小一点
            // 然后再回弹到maxHeight
            newHeight = logConstraintValueForYPosition(verticalLimit: maxHeight, yPosition: newHeight)
        }
        return (newHeight, offset)
    }
    
    func updateOriginY(newHeight: CGFloat, offset: CGFloat) {
        self.contentViewHeightConstraint?.constant = newHeight
        
        // 滑动的低于最小高度的差值
        if offset > 0 {
            self.maskView.alpha = 1 - max(0, min(1, offset / max(1, newHeight)))
            self.contentViewController.view.transform = CGAffineTransform(translationX: 0, y: offset)
        } else {
            self.contentViewController.view.transform = CGAffineTransform(translationX: 0, y: offset)
//            self.contentViewController.view.transform = CGAffineTransform.identity
        }
    }
    
    @objc
    func panned(_ gesture: UIPanGestureRecognizer) {
        // 以手指落下的点（0,0）为原点计算
        let point = gesture.translation(in: gesture.view?.superview)
        
        switch gesture.state {
        case .began:
            // 是否响应pan手势
            let isFocused = isScrolledToTop()
            // 初始用户手指落下的位置(以view的（0，0）为原点计算)
            let touchPoint = gesture.location(in: gesture.view)
            // 用户是否滑动的顶部bar区域
            let isTouchedTopbar: Bool = (touchPoint.y < options.pullBarEventHeight)
            // 是否在滑动中
            let isPanning = true
            // 第一次手指落下的点
            let firstTouchPoint = gesture.translation(in: gesture.view?.superview)
            // 第一次手指落下时contentView的Size
            let firstTouchSize = self.contentViewController.view.bounds.size
            panGesture = (isFocused, isTouchedTopbar, isPanning, firstTouchPoint, firstTouchSize)
            panBegan()
        case .changed:
            let t = calculateHeight(point)
            if panGesture.isTouchedTopbar {
                updateOriginY(newHeight: t.0, offset: t.1)
            } else if panGesture.isFocused {
                // 用户向上滑动，则取消focused
                if point.y < 0 {
                    panGesture.isFocused = false
                } else {
                    updateOriginY(newHeight: t.0, offset: t.1)
                }
            }
            self.rectChanged(frame: self.contentViewController.view.frame, offset: point.y - panGesture.firstTouchPoint.y)
            panChanged()
        case .ended:
            guard panGesture.isTouchedTopbar || panGesture.isFocused else {
                return
            }
            // 计算最新高度和偏移量
            let t = calculateHeight(point)
            let newHeight = t.0
            let offset = t.1
            // 用户手指滑动速率
            let velocity = (0.2 * gesture.velocity(in: self.view).y)
            let animationDuration = TimeInterval(abs(velocity*0.0002) + 0.2)
            
            // 用户滑动的非常快，直接dismiss弹窗
            guard velocity <= options.pullDismissThreshod else {
                // They swiped hard, always just close the sheet when they do
                dismiss(withDuration: animationDuration)
                return
            }
            
            // 预期的最终高度
            let finalHeight = newHeight - offset - velocity
            var newSize: SheetSize
            // 向下滑动距离超过了最小高度，则直接dismiss
            let minOffset = panGesture.firstTouchSize.height * options.dismissScale
            let heightOffset = panGesture.firstTouchSize.height - finalHeight
            if heightOffset > 0 { // // 向下划>0;
                if heightOffset > minOffset {
                    if currentSize == sizes.first {
                        dismiss(withDuration: animationDuration)
                        return
                    } else {
                        newSize = previousSize()
                    }
                } else {
                    // recover
                    newSize = currentSize
                }
            } else { // 向上划<0
                // next
                newSize = nextSize()
            }
            
            // 更新当前size
            let previousSize = self.currentSize
            self.currentSize = newSize
            
            let newContentHeight = self.height(for: newSize)
            
            updateHeight(withDuration: animationDuration,
                         newHeight: newContentHeight) { [weak self] in
                guard let self = self else { return }
                self.panGesture.isPanning = false
                self.rectChanged(frame: self.contentViewController.view.frame, offset: 0)
                self.sizeModeChanged(previousSize, newSize)
            }
            panGesture = (false, false, false, CGPoint.zero, CGSize.zero)
            removeObserveViews()
            panEnded()
        case .cancelled, .failed:
            UIView.animate(withDuration: 0.3,
                           delay: 0,
                           options: [.curveEaseOut],
                           animations: { [weak self] in
                guard let self = self else { return }
                self.contentViewController.view.transform = CGAffineTransform.identity
                self.contentViewHeightConstraint?.constant = self.height(for: self.currentSize)
                self.maskView.alpha = 1
            }, completion: {[weak self] _ in
                guard let self = self else { return }
                self.panGesture.isPanning = false
            })
            panGesture = (false, false, false, CGPoint.zero, CGSize.zero)
            removeObserveViews()
            panCancelOrFailed()
        case .possible:
            break
        @unknown default:
            break // Do nothing
        }
    }
}

extension SheetViewController {
    // https://medium.com/thoughts-on-thoughts/recreating-apple-s-rubber-band-effect-in-swift-dbf981b40f35
    private func logConstraintValueForYPosition(verticalLimit: CGFloat, yPosition : CGFloat) -> CGFloat {
      return verticalLimit * (1 + log10(yPosition/verticalLimit))
    }
}

// MARK: 手势冲突

extension SheetViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if otherGestureRecognizer.view == self {
            return false
        }
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else {
            return false
        }
        let velocity = pan.velocity(in: self.view)
        if abs(velocity.x) > abs(velocity.y) {
            return false
        }
        guard let scrollView = otherGestureRecognizer.view as? UIScrollView else {
            return false
        }
        if scrollView.superview?.isKind(of: UITableView.self) == true {
            return false
        }
        if let t = NSClassFromString("UITableViewCellContentView"), otherGestureRecognizer.view?.superview?.isKind(of: t) == true {
            return false
        }
        
        addObservedView(scrollView)
        
        return true
    }

    func addObservedView(_ scrollView: UIScrollView) {
        observedViews.addPointer(Unmanaged.passUnretained(scrollView).toOpaque())
    }
    
    func removeObserveViews() {
        observedViews = NSPointerArray.weakObjects()
    }
    
    func isScrolledToTop() -> Bool {
        // 遍历所有滚动
        for t in observedViews.allObjects {
            if let s = t as? UIScrollView, !s.isHidden, s.alpha > 0, s.superview != nil {
                if s.contentOffset.y > -s.contentInset.top {
                    return false
                }
            }
        }
        return true
    }
}
