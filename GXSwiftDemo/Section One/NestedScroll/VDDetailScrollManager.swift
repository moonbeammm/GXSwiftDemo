//
//  VDDetailScrollManager.swift
//  BBVideoDetail
//
//  Created by sgx on 2025/7/28.
//

import UIKit

class VDDetailScrollManager: NSObject {
    internal var panGestureRecognizer: UIPanGestureRecognizer?
    
    typealias PanGestureInfo = (isTouchedTopbar: Bool, lastTouchPoint: CGPoint)
    var panGesture: PanGestureInfo = (false, CGPoint.zero)
    
    var observedViews = NSPointerArray.weakObjects()
    var scrollViewOffsetMap: [Int: CGFloat] = [:]
    var scrollViewBouncesMap: [Int: Bool] = [:]
    
    var displayLink: CADisplayLink?
    var inertialVelocity: CGFloat = 0

    var offsetRange: (min: CGFloat, max: CGFloat) = (min: 0, max: 0)
    var offset: CGFloat = 0
    
    var onPanGestureDidScroll: ((_ offset: CGFloat) -> Void)?
    var onPanGestureEndScroll: ((_ offset: CGFloat, _ velocity: CGFloat) -> Void)?

    public init(with gestureView: UIView) {
        super.init()
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panned(_:)))
        gestureView.addGestureRecognizer(panGestureRecognizer)
        panGestureRecognizer.delegate = self
        self.panGestureRecognizer = panGestureRecognizer
    }
}

extension VDDetailScrollManager {
    @objc
    func panned(_ gesture: UIPanGestureRecognizer) {
        // 以手指落下的点（0,0）为原点计算
        // y > 0则表示手指往下滑
        // y < 0则表示手指往上滑
        let point = gesture.translation(in: gesture.view?.superview)
        
        switch gesture.state {
        case .began:
            // 先重置
            stopInertialAnimation()
            // 初始用户手指落下的位置(以view的（0，0）为原点计算)
            let touchPoint = gesture.location(in: gesture.view)
            // 用户是否滑动的顶部bar区域
            let isTouchedTopbar: Bool = observedViews.count <= 0 || (touchPoint.y < PanConstant.pullBarEventHeight)
            panGesture = (isTouchedTopbar, CGPoint.zero)
        case .changed:
            let delta = point.y - panGesture.lastTouchPoint.y
            guard abs(delta) > 0 else { return }
            let direction: Direction = delta > 0 ? .down:.up
            let newOffset = self.offset - delta
            
            if panGesture.isTouchedTopbar {
                updatePanGestureOffset(newOffset)
            } else {
                onPanGestureDidScroll(newOffset, direction: direction, from: "manual")
            }
            
            panGesture.lastTouchPoint = point
        default:
            let velocity = gesture.velocity(in: gesture.view?.superview).y
            if offset > 0 && abs(velocity) > 20 { // 开始惯性
                startInertialAnimation(initialVelocity: velocity)
            } else { // 结束
                onPanGestureEndScroll?(offset, 0.2*velocity)
                reset()
            }
        }
    }
    
    func reset() {
        stopInertialAnimation()
        removeObserveViews()
        panGesture = (false, CGPoint.zero)
    }
    
    enum Direction {
        case none
        case up
        case down
    }
    
    func onPanGestureDidScroll(_ offset: CGFloat, direction: Direction, from: String) {
        if direction == .up { // 向上滑，优先收起播放器
            print("\(PanConstant.tag) on pan gesture did scroll from: \(from) offset: \(offset); direction: \(direction) offset range: \(offsetRange.min) <-> \(offsetRange.max)")
            if scrollViewOffsetMap.isEmpty {
                saveScrollViewOffsets()
            }
            updatePanGestureOffset(offset)
            if offset < (offsetRange.max) { // 播放器还未滑到最小值，重置scrollview offset
                restoreScrollViewOffsets()
            }
        } else if direction == .down { // 向下滑，优化scrollview滚到顶
            removeScrollViewOffsets()
            let isScrolledToTop = isScrolledToTop()
            print("\(PanConstant.tag) on pan gesture did scroll from: \(from) offset: \(offset); direction: \(direction) is scroll to top: \(isScrolledToTop) offset range: \(offsetRange.min) <-> \(offsetRange.max)")
            if isScrolledToTop { // scrollview已经滑到顶了，才开始滑动播放器
                updatePanGestureOffset(offset)
                keepScrollViewToTop()
            } else {
                
            }
        }
    }
    
    func updatePanGestureOffset(_ offset: CGFloat) {
        self.offset = max(min(offset, offsetRange.max), offsetRange.min)
        onPanGestureDidScroll?(self.offset)
    }
    
    // MARK: - 惯性动画
    private func startInertialAnimation(initialVelocity: CGFloat) {
        stopInertialAnimation()
        inertialVelocity = initialVelocity
        
        displayLink = CADisplayLink(target: self, selector: #selector(stepInertialAnimation))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    private func stopInertialAnimation() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func stepInertialAnimation() {
        guard displayLink != nil else { return }
        
        // 1. 速度衰减
        let deltaTime: CGFloat = 1/60.0
        inertialVelocity *= pow(PanConstant.decelerationRate, deltaTime * 60)
                
        // 2. 计算位移增量
        let delta = inertialVelocity * deltaTime
        guard abs(delta) > 0 else { return }
        let direction: Direction = delta > 0 ? .down:.up
        let newOffset = min(max(self.offset - delta, 0), offsetRange.max)
                        
        // 3. 停止条件（基于速度和边界值）
        if abs(inertialVelocity) < 5.0 ||
            (direction == .down && newOffset <= 0) ||
            (direction == .up && newOffset >= offsetRange.max) {
            reset()
            return
        }
        onPanGestureDidScroll(newOffset, direction: direction, from: "惯性")
    }
}

enum PanConstant {
    static let pullBarEventHeight = 44.0
    static let minVelocityToStop: CGFloat = 5.0  // 停止速度阈值（点/秒）
    static let decelerationRate: CGFloat = 0.98 // 系统默认减速率
    static let tag = "sgx >>> scroll"
}

// MARK: 手势冲突

extension VDDetailScrollManager: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Allowing gesture recognition on a UIControl seems to prevent its events from firing properly sometimes
        return true
    }
    
    // 控制多个手势识别器是否能够 同时识别（即是否允许它们同时触发并处理手势事件）
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if otherGestureRecognizer.view == self {
            return false
        }
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else {
            return false
        }
        let velocity = pan.velocity(in: pan.view?.superview)
        if abs(velocity.x) > abs(velocity.y) {
            return false
        }
        guard let scrollView = otherGestureRecognizer.view as? UIScrollView else {
            return false
        }
        if scrollView.superview?.isKind(of: UITableView.self) == true ||
            scrollView.superview?.isKind(of: UICollectionView.self) == true {
            return false
        }
        if let t = NSClassFromString("UITableViewCellContentView"), otherGestureRecognizer.view?.superview?.isKind(of: t) == true {
            return false
        }
        
        addObservedView(scrollView)
        
        return true
    }

    func addObservedView(_ scrollView: UIScrollView) {
        if !(observedViews.allObjects.contains { ($0 as? UIScrollView) == scrollView }) {
            print("\(PanConstant.tag) add oberved scroll view: \(scrollView)")
            saveAndInvalidScrollViewBounces(scrollView)
            observedViews.addPointer(Unmanaged.passUnretained(scrollView).toOpaque())
        }
    }
    
    func removeObserveViews() {
        print("\(PanConstant.tag) remove oberved scroll view! \(observedViews.allObjects)")
        removeScrollViewOffsets()
        recoverScrollViewBounces()
        observedViews = NSPointerArray.weakObjects()
    }
    
    // 时机A：保存bounces
    func saveAndInvalidScrollViewBounces(_ scrollView: UIScrollView) {
        let key = scrollView.hashValue
        scrollViewBouncesMap[key] = scrollView.bounces
        scrollView.bounces = false
    }
    
    // 时机B：恢复bounces
    func recoverScrollViewBounces() {
        guard let scrollViews = observedViews.allObjects as? [UIScrollView] else { return }
        for scrollView in scrollViews {
            let key = scrollView.hashValue
            if let bounces = scrollViewBouncesMap[key] {
                scrollView.bounces = bounces
            }
        }
        scrollViewBouncesMap.removeAll()
    }
    
    // 时机A：保存偏移量
    func saveScrollViewOffsets() {
        guard let scrollViews = observedViews.allObjects as? [UIScrollView] else { return }
        removeScrollViewOffsets()
        for scrollView in scrollViews {
            let key = scrollView.hashValue
            scrollViewOffsetMap[key] = scrollView.contentOffset.y
        }
    }

    // 时机B：恢复偏移量
    func restoreScrollViewOffsets() {
        guard let scrollViews = observedViews.allObjects as? [UIScrollView] else { return }
        for scrollView in scrollViews {
            let key = scrollView.hashValue
            if let savedOffset = scrollViewOffsetMap[key] {
                scrollView.contentOffset.y = savedOffset
            }
        }
    }
    
    // 时机C：移出偏移量
    func removeScrollViewOffsets() {
        scrollViewOffsetMap.removeAll()
    }
    
    func keepScrollViewToTop() {
        guard let scrollViews = observedViews.allObjects as? [UIScrollView] else { return }
        for scrollView in scrollViews {
            scrollView.contentOffset.y = -scrollView.contentInset.top
        }
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
