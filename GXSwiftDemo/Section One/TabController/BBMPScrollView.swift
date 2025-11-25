//
//  BBMPScrollView.swift
//  BFCTabContainer
//
//  Created by 香辣虾 on 2020/3/21.
//  Copyright © 2020 bilibili. All rights reserved.
//

import UIKit

class BBMPScrollView: UIScrollView {

    var minimumHeight: CGFloat = 0
    var maximumHeight: CGFloat = 0

    private var forwarder: BBMPScrollViewDelegateForwarder?
    private var observedViews: [UIScrollView] = []
    private var isRemovedObserve: Bool = false
    private var isObserving: Bool = false
    private var lock: Bool = false

    private var kvoContext = 0

    override var delegate: UIScrollViewDelegate? {
        get {
            return forwarder?.delegate
        }
        set {
            forwarder?.delegate = newValue
            super.delegate = nil
            super.delegate = forwarder
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }

    private func initialize() {
        forwarder = BBMPScrollViewDelegateForwarder(scrollView: self)
        super.delegate = forwarder
        panGestureRecognizer.cancelsTouchesInView = false

        addObserver(self, forKeyPath: #keyPath(contentOffset), options: [.new, .old], context: &kvoContext)
        isObserving = true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if otherGestureRecognizer.view == self {
            return false
        }

        // Ignore other gesture than pan
        guard gestureRecognizer is UIPanGestureRecognizer else {
            return false
        }

        // Lock horizontal pan gesture.
        let velocity = (gestureRecognizer as! UIPanGestureRecognizer).velocity(in: self)
        if abs(velocity.x) > abs(velocity.y) {
            return false
        }

        // Consider scroll view pan only
        guard let scrollView = otherGestureRecognizer.view as? UIScrollView else {
            return false
        }

        // Tricky case: UITableViewWrapperView
        if scrollView.superview is UITableView {
            return false
        }

        // tableview on the BBMPScrollView
        if NSStringFromClass(type(of: scrollView.superview ?? UIView())) == "UITableViewCellContentView" {
            return false
        }

        addObservedView(scrollView)

        return true
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &kvoContext && keyPath == #keyPath(contentOffset) {
            guard let change = change,
                  let new = (change[.newKey] as? NSValue)?.cgPointValue,
                  let old = (change[.oldKey] as? NSValue)?.cgPointValue else {
                return
            }

            let diff = old.y - new.y

            if diff == 0.0 || !isObserving {
                return
            }

            let maximumOffsetY = maximumHeight - minimumHeight

            if let obj = object as? UIScrollView, obj == self {
                // Adjust self scroll offset when scroll down
                if diff > 0 && lock {
                    scrollView(self, setContentOffset: old)
                } else if contentOffset.y < -contentInset.top && !bounces {
                    scrollView(self, setContentOffset: CGPoint(x: contentOffset.x, y: -contentInset.top))
                } else if contentOffset.y > maximumOffsetY {
                    scrollView(self, setContentOffset: CGPoint(x: contentOffset.x, y: maximumOffsetY))
                }
            } else if let scrollView = object as? UIScrollView {
                // Adjust the observed scrollview's content offset
                lock = (scrollView.contentOffset.y > -scrollView.contentInset.top)

                // Manage scroll up
                if contentOffset.y < maximumOffsetY && lock && diff < 0 {
                    self.scrollView(scrollView, setContentOffset: old)
                }
                // Disable bouncing when scroll down
                if !lock && ((contentOffset.y > -contentInset.top) || bounces) {
                    self.scrollView(scrollView, setContentOffset: CGPoint(x: scrollView.contentOffset.x, y: -scrollView.contentInset.top))
                }
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    private func addObserverToView(_ scrollView: UIScrollView) {
        lock = (scrollView.contentOffset.y >= -scrollView.contentInset.top)
        scrollView.addObserver(self, forKeyPath: #keyPath(UIScrollView.contentOffset), options: [.new, .old], context: &kvoContext)
    }

    private func removeObserverFromView(_ scrollView: UIScrollView) {
        do {
            scrollView.removeObserver(self, forKeyPath: #keyPath(UIScrollView.contentOffset), context: &kvoContext)
        } catch {
            // Ignore exceptions
        }
    }

    private func addObservedView(_ scrollView: UIScrollView) {
        if !observedViews.contains(scrollView) {
            observedViews.append(scrollView)
            addObserverToView(scrollView)
        }
    }

    func removeObservedViews() {
        for scrollView in observedViews {
            removeObserverFromView(scrollView)
        }
        observedViews.removeAll()
    }

    private func scrollView(_ scrollView: UIScrollView, setContentOffset offset: CGPoint) {
        isObserving = false
        scrollView.contentOffset = offset
        isObserving = true
    }

    func removeAllObserves() {
        if !isRemovedObserve {
            isRemovedObserve = true
            removeObserver(self, forKeyPath: #keyPath(contentOffset), context: &kvoContext)
        }
        removeObservedViews()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        lock = false
        removeObservedViews()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            lock = false
            removeObservedViews()
        }
    }

    deinit {
        removeAllObserves()
    }
}

// MARK: - DelegateForwarder
private class BBMPScrollViewDelegateForwarder: NSObject, UIScrollViewDelegate {

    weak var delegate: UIScrollViewDelegate?
    weak var scrollView: BBMPScrollView?

    init(scrollView: BBMPScrollView) {
        self.scrollView = scrollView
        super.init()
    }

    override func responds(to aSelector: Selector!) -> Bool {
        return delegate?.responds(to: aSelector) == true || super.responds(to: aSelector)
    }

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        return delegate
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        (scrollView as? BBMPScrollView)?.scrollViewDidEndDecelerating(scrollView)
        delegate?.scrollViewDidEndDecelerating?(scrollView)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        (scrollView as? BBMPScrollView)?.scrollViewDidEndDragging(scrollView, willDecelerate: decelerate)
        delegate?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
    }
}
