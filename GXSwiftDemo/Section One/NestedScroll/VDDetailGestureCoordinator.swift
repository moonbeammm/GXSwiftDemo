//
//  VDDetailGestureCoordinator.swift
//  BBVideoDetail
//
//  Created by sgx on 2025/7/28.
//

import UIKit

// MARK: - Enumerations

/**
 * 滚动方向枚举
 */
enum ScrollDirection {
    case none
    case up     // 向上滑动（增加偏移量）
    case down   // 向下滑动（减少偏移量）
}

/**
 * 滚动来源类型
 */
enum ScrollSource {
    case userPan        // 用户手势拖拽
    case inertial       // 惯性滚动动画
}

/**
 * 手势状态枚举
 */
enum GestureState {
    case idle                   // 空闲状态
    case dragging               // 正在拖拽中
    case inertialAnimation      // 惯性动画中
}

// MARK: - Configuration

/**
 * 手势协调器配置常量
 */
private enum Configuration {
    /// 惯性动画相关参数
    enum InertialAnimation {
        static let decelerationRate: CGFloat = 0.98         // 减速率，系统默认值
        static let minimumVelocityThreshold: CGFloat = 80.0 // 停止速度阈值（点/秒）
    }
    
    /// 手势识别参数
    enum Gesture {
        static let minimumVelocityForInertial: CGFloat = 20.0  // 启动惯性动画的最小速度
        static let minimumDeltaForUpdate: CGFloat = 0.0        // 更新UI的最小位移差
    }
}

// MARK: - Class Implementation

/**
 * 视频详情页手势协调器
 *
 * ## 核心职责
 * - 管理容器视图的上下拖拽手势交互
 * - 协调容器滚动与内部ScrollView的滚动冲突
 * - 处理拖拽结束后的惯性动画
 *
 * ## 交互机制
 * - **向上拖拽**：优先调整容器偏移量，达到边界后允许内部ScrollView继续滚动
 * - **向下拖拽**：当内部ScrollView滚动到顶部时，开始调整容器偏移量；否则优先滚动ScrollView内容
 *
 * ## 使用场景
 * 视频详情页中需要协调多层滚动冲突的场景，通过抽象的偏移量来通知业务方进行相应的布局调整
 *
 * ## 使用示例
 * ```swift
 * let coordinator = VDDetailGestureCoordinator(gestureView: containerView)
 * coordinator.offsetRange = (min: -200, max: 300)  // 设置滚动范围
 * coordinator.shouldManageScrollViewBounces = false  // 可选：禁用自动 bounces 管理
 * coordinator.onPanGestureDidScroll = { offset in
 *     // 业务方根据偏移量调整UI布局
 *     updateContainerLayout(withOffset: offset)
 * }
 * coordinator.onPanGestureEndScroll = { offset, velocity in
 *     // 处理拖拽结束逻辑（dismiss或recover）
 * }
 * ```
 */
class VDDetailGestureCoordinator: NSObject {
    
    // MARK: - Properties
    
    /// 手势识别器
    private var panGestureRecognizer: UIPanGestureRecognizer?
    
    /// 上次触摸点位置
    private var lastTouchPoint: CGPoint = CGPoint.zero
    
    /// 当前手势状态
    private var currentState: GestureState = .idle
    
    /// 观察的ScrollView列表（弱引用）
    private var observedViews = NSPointerArray.weakObjects()
    
    /// ScrollView偏移量保存映射表
    private var scrollViewOffsetMap: [Int: CGFloat] = [:]
    
    /// ScrollView bounce状态保存映射表
    private var scrollViewBouncesMap: [Int: Bool] = [:]
    
    /// 惯性动画显示链接
    private var displayLink: CADisplayLink?
    
    /// 惯性动画速度
    private var inertialVelocity: CGFloat = 0

    /// 滚动偏移量范围 (min: 最小偏移, max: 最大偏移)
    var offsetRange: (min: CGFloat, max: CGFloat) = (min: 0, max: 0)
    
    /// 当前滚动偏移量（抽象数值，由业务方解释其具体含义）
    var offset: CGFloat = 0

    /// 是否在滑动时自动管理 ScrollView 的 bounces 属性
    /// - true: 向上滑动时恢复 bounces，向下滑动时禁用 bounces（默认行为）
    /// - false: 不对 ScrollView 的 bounces 属性进行任何修改，由业务方自行管理
    var shouldManageScrollViewBounces: Bool = true

    // MARK: - Callback Properties
    
    /// 手势是否应该开始的判断回调
    var panGestureShouldBegin: (() -> Bool)?
    
    /// 手势开始时的回调
    var onPanGestureBeginScroll: (() -> Void)?
    
    /// 手势滚动过程中的回调 (参数: 当前抽象偏移量)
    var onPanGestureDidScroll: ((_ offset: CGFloat) -> Void)?
    
    /// 手势结束时的回调 (参数: 最终偏移量, 结束时的速度)
    var onPanGestureEndScroll: ((_ offset: CGFloat, _ velocity: CGFloat) -> Void)?

    internal var childKeyValueObservations: [Int: NSKeyValueObservation] = [:]
    // MARK: - Initialization
    
    /**
     * 初始化手势协调器
     * @param gestureView 要添加手势识别器的视图
     */
    public init(with gestureView: UIView) {
        super.init()
        setupPanGestureRecognizer(on: gestureView)
    }
    
    /**
     * 配置平移手势识别器
     */
    private func setupPanGestureRecognizer(on view: UIView) {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        view.addGestureRecognizer(panGestureRecognizer)
        panGestureRecognizer.delegate = self
        self.panGestureRecognizer = panGestureRecognizer
    }
}

// MARK: - Pan Gesture Handling

extension VDDetailGestureCoordinator {
    
    /**
     * 平移手势处理主入口
     *
     * 处理流程：
     * - 手势开始：重置状态，通知开始滚动
     * - 手势变化：计算偏移量增量，协调滚动优先级
     * - 手势结束：根据速度判断是否启动惯性动画
     */
    @objc
    private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        // 以手指落下的点（0,0）为原点计算偏移量
        // y > 0 表示手指往下滑，y < 0 表示手指往上滑
        let translation = gesture.translation(in: gesture.view?.superview)
        
        switch gesture.state {
        case .began:
            handlePanGestureBegan()
            
        case .changed:
            let deltaY = translation.y - lastTouchPoint.y
            guard abs(deltaY) > Configuration.Gesture.minimumDeltaForUpdate else { return }
            
            let direction: ScrollDirection = deltaY > 0 ? .down : .up
            let targetOffset = self.offset - deltaY
            
            coordinateScrolling(targetOffset: targetOffset, direction: direction, source: .userPan)
            lastTouchPoint = translation
            
        default: // .ended, .cancelled, .failed
            let velocity = gesture.velocity(in: gesture.view?.superview).y
            handlePanGestureEnded(velocity: velocity)
        }
    }
    
    /**
     * 处理手势开始事件
     */
    private func handlePanGestureBegan() {
        currentState = .dragging
        onPanGestureBeginScroll?()
        
        // 停止正在进行的惯性动画
        stopInertialAnimation()
        // 重置触摸点
        lastTouchPoint = CGPoint.zero
    }
    
    /**
     * 处理手势结束事件
     * @param velocity 手势结束时的速度
     */
    private func handlePanGestureEnded(velocity: CGFloat) {
        let shouldStartInertial = offset > 0 && abs(velocity) > Configuration.Gesture.minimumVelocityForInertial
        
        if shouldStartInertial {
            startInertialAnimation(initialVelocity: velocity)
        } else {
            onPanGestureEndScroll?(offset, velocity)
            resetGestureState()
        }
    }
    
    /**
     * 重置手势状态
     */
    private func resetGestureState() {
        currentState = .idle
        stopInertialAnimation()
        clearScrollViewObservation()
        lastTouchPoint = CGPoint.zero
    }
}

// MARK: - Scroll Coordination

/*
 * 滚动协调核心逻辑流程图：
 *
 * coordinateScrolling()
 *        ↓
 * 判断滚动方向 → 向上滑动: handleUpwardScrolling()
 *            → 向下滑动: handleDownwardScrolling()
 *        ↓
 * updateOffset() → 更新容器偏移量 → 触发业务方回调
 */
extension VDDetailGestureCoordinator {
    
    /**
     * 协调容器滚动与ScrollView的滚动优先级
     *
     * ## 滚动策略：
     * - **向上滑动**：容器未到边界时，优先调整容器偏移量；到达边界后，允许ScrollView滚动
     * - **向下滑动**：ScrollView在顶部时，优先调整容器偏移量；ScrollView不在顶部时，优先滚动ScrollView
     *
     * @param targetOffset 目标偏移量（抽象数值，具体含义由业务方定义）
     * @param direction 滚动方向
     * @param source 滚动来源（用户手势/惯性动画）
     */
    private func coordinateScrolling(targetOffset: CGFloat, direction: ScrollDirection, source: ScrollSource) {
        switch direction {
        case .up:
            handleUpwardScrolling(targetOffset: targetOffset, source: source)
        case .down:
            handleDownwardScrolling(targetOffset: targetOffset, source: source)
        case .none:
            break
        }
    }
    
    /**
     * 处理向上滑动逻辑
     * 策略：优先调整容器偏移量，到达边界后允许ScrollView滚动
     */
    private func handleUpwardScrolling(targetOffset: CGFloat, source: ScrollSource) {
        // VKLogInfo(.common, .layout, "向上滑动协调 - 目标偏移: \(targetOffset), 方向: up, 范围: \(offsetRange.min) <-> \(offsetRange.max)")
        print("sgx >> scroll view did scroll222")


        // 如果启用了 bounces 管理且内部ScrollView还没有滚动到顶部，恢复其bounce效果
        if shouldManageScrollViewBounces && !isAllScrollViewsAtTop() {
            restoreScrollViewBounces()
        }
        
        if !isAllScrollViewsSafe() {
            return
        }

        // 保存ScrollView当前偏移量（首次保存）
        if scrollViewOffsetMap.isEmpty {
            saveScrollViewOffsets()
        }

        // 更新容器偏移量
        updateContainerOffset(targetOffset)

        // 如果容器还未到达边界，重置ScrollView偏移量到保存的位置
        //print("sgx >>> offset:\(offset) rangemax:\(offsetRange.max)")
        if offset < offsetRange.max {
            restoreScrollViewOffsets()
        }
    }
    
    
    
    /**
     * 处理向下滑动逻辑
     * 策略：ScrollView在顶部时，优先调整容器偏移量；否则优先滚动ScrollView
     */
    private func handleDownwardScrolling(targetOffset: CGFloat, source: ScrollSource) {
        // 如果启用了 bounces 管理，禁用ScrollView的bounce效果，防止下拉时出现空白
        if shouldManageScrollViewBounces {
            disableScrollViewBounces()
        }
        // 清除保存的偏移量映射
        clearScrollViewOffsets()

        // VKLogInfo(.common, .layout, "向下滑动协调 - 目标偏移: \(targetOffset), 方向: down, 所有ScrollView在顶部: \(isAllScrollViewsAtTop()), 范围: \(offsetRange.min) <-> \(offsetRange.max)")

        if isAllScrollViewsAtTop() {
            // ScrollView已经在顶部，开始调整容器偏移量
            updateContainerOffset(targetOffset)
            // 如果启用了 bounces 管理，保持ScrollView在顶部位置
            if shouldManageScrollViewBounces {
                keepScrollViewsAtTop()
            } else {
                if offset > offsetRange.min {
                    keepScrollViewsAtTop()
                }
            }
        }
        // 如果ScrollView不在顶部，则不更新容器偏移量，让ScrollView自然滚动
    }
    
    /**
     * 更新容器偏移量并触发业务方回调
     * @param targetOffset 目标偏移量
     */
    private func updateContainerOffset(_ targetOffset: CGFloat) {
        let clampedOffset = max(min(targetOffset, offsetRange.max), offsetRange.min)
        self.offset = clampedOffset
        onPanGestureDidScroll?(self.offset)
    }
}

// MARK: - Inertial Animation

extension VDDetailGestureCoordinator {
    
    /**
     * 开始惯性滚动动画
     * @param initialVelocity 初始速度
     */
    private func startInertialAnimation(initialVelocity: CGFloat) {
        stopInertialAnimation()
        
        currentState = .inertialAnimation
        inertialVelocity = initialVelocity
        
        displayLink = CADisplayLink(target: self, selector: #selector(stepInertialAnimation))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    /**
     * 停止惯性滚动动画
     */
    private func stopInertialAnimation() {
        displayLink?.invalidate()
        displayLink = nil
        
        if currentState == .inertialAnimation {
            currentState = .idle
        }
    }

    /**
     * 惯性动画步进函数
     *
     * 动画逻辑：
     * 1. 根据减速率逐帧降低速度
     * 2. 计算当前帧的位移增量
     * 3. 检查停止条件（速度过低或到达边界）
     * 4. 更新偏移量并继续或结束动画
     */
    @objc
    private func stepInertialAnimation() {
        guard displayLink != nil else { return }

        // 1. 速度衰减（60fps基准）
        let deltaTime: CGFloat = 1.0 / 60.0
        inertialVelocity *= pow(Configuration.InertialAnimation.decelerationRate, deltaTime * 60)

        // 2. 计算位移增量
        let deltaOffset = inertialVelocity * deltaTime
        guard abs(deltaOffset) > Configuration.Gesture.minimumDeltaForUpdate else {
            // 过滤脏数据
            return
        }
        
        let direction: ScrollDirection = deltaOffset > 0 ? .down : .up
        let targetOffset = min(max(self.offset - deltaOffset, 0), offsetRange.max)
        
        // VKLogInfo(.common, .layout, "惯性动画步进 - 速度:\(inertialVelocity) 增量:\(deltaOffset) 方向:\(direction) 目标偏移:\(targetOffset)")
        
        // 3. 检查停止条件
        let reachedBoundary = (direction == .down && targetOffset <= 0) ||
                             (direction == .up && targetOffset >= offsetRange.max)
        let velocityTooLow = abs(inertialVelocity) < Configuration.InertialAnimation.minimumVelocityThreshold
        
        if reachedBoundary {
            coordinateScrolling(targetOffset: targetOffset, direction: direction, source: .inertial)
            finishInertialAnimation("到达边界")
            return
        } else if velocityTooLow {
            finishInertialAnimation("速度过低")
            return
        }
        
        // 4. 更新偏移量
        coordinateScrolling(targetOffset: targetOffset, direction: direction, source: .inertial)
    }
    
    /**
     * 完成惯性动画
     * @param reason 结束原因（用于日志）
     */
    private func finishInertialAnimation(_ reason: String) {
        resetGestureState()
    }
}

// MARK: - ScrollView Management

extension VDDetailGestureCoordinator {
    
    /**
     * 添加需要观察的ScrollView
     * @param scrollView 要观察的ScrollView
     */
    private func addObservedScrollView(_ scrollView: UIScrollView) {
        let scrollViewExists = observedViews.allObjects.contains { ($0 as? UIScrollView) == scrollView }
        
        if !scrollViewExists {
            // VKLogInfo(.common, .layout, "添加观察的ScrollView: \(scrollView)")
            // 保存ScrollView的bounce状态
            saveScrollViewBounces()
            observedViews.addPointer(Unmanaged.passUnretained(scrollView).toOpaque())
        }
    }
    
    /**
     * 清除所有ScrollView观察
     */
    private func clearScrollViewObservation() {
        // VKLogInfo(.common, .layout, "清除所有ScrollView观察: \(observedViews.allObjects)")
        clearScrollViewOffsets()
        restoreScrollViewBounces()
        clearScrollViewBounces()
        observedViews = NSPointerArray.weakObjects()
    }
    
    // MARK: ScrollView Bounce Management
    
    /**
     * 保存所有ScrollView的bounce状态
     */
    private func saveScrollViewBounces() {
        guard let scrollViews = observedViews.allObjects as? [UIScrollView] else { return }
        
        for scrollView in scrollViews {
            let key = scrollView.hashValue
            scrollViewBouncesMap[key] = scrollView.bounces
        }
    }
    
    /**
     * 清空bounce状态映射表
     */
    private func clearScrollViewBounces() {
        scrollViewBouncesMap.removeAll()
    }
    
    /**
     * 禁用所有ScrollView的bounce效果
     * 用于向下拖拽时防止出现空白区域
     */
    private func disableScrollViewBounces() {
        guard let scrollViews = observedViews.allObjects as? [UIScrollView] else { return }
        
        for scrollView in scrollViews where scrollView.bounces != false {
            scrollView.bounces = false
        }
    }
    
    /**
     * 恢复所有ScrollView的bounce状态
     */
    private func restoreScrollViewBounces() {
        guard let scrollViews = observedViews.allObjects as? [UIScrollView],
              !scrollViewBouncesMap.isEmpty else { return }
        
        for scrollView in scrollViews {
            let key = scrollView.hashValue
            if let originalBounces = scrollViewBouncesMap[key],
               scrollView.bounces != originalBounces {
                scrollView.bounces = originalBounces
            }
        }
    }
    
    // MARK: ScrollView Offset Management
    
    /**
     * 保存所有ScrollView的当前偏移量
     * 用于向上滑动时保持ScrollView位置不变
     */
    private func saveScrollViewOffsets() {
        guard let scrollViews = observedViews.allObjects as? [UIScrollView] else { return }
        
        clearScrollViewOffsets()
        for scrollView in scrollViews {
            let key = scrollView.hashValue
            print("sgx >> safe \(key), offsety:\(scrollView.contentOffset.y)")
            scrollViewOffsetMap[key] = ceil(scrollView.contentOffset.y)
        }
    }

    /**
     * 恢复所有ScrollView到保存的偏移量
     */
    private func restoreScrollViewOffsets() {
        guard let scrollViews = observedViews.allObjects as? [UIScrollView] else { return }
        
        for scrollView in scrollViews {
            let key = scrollView.hashValue
            if let savedOffset = scrollViewOffsetMap[key] {
                print("sgx >> restore \(key), offsety:\(savedOffset) currentoffset:\(scrollView.contentOffset.y)")
                scrollView.contentOffset.y = savedOffset
                
//                if !self.childKeyValueObservations.keys.contains(key) {
//                    let keyValueObservation = scrollView.observe(\.contentOffset, options: [.initial, .new, .old]) { [weak self] (scrollView, change) in
//                        guard let self = self else {
//                            return
//                        }
//                        
//                        guard let newValue = change.newValue else {
//                            return
//                        }
//                        
//                        guard let oldValue = change.oldValue else {
//                            return
//                        }
//                        
//                        if abs(newValue.y - oldValue.y) < 0.1 {
//                            return
//                        }
//                        let key = scrollView.hashValue
//                        if let savedOffset = self.scrollViewOffsetMap[key] {
//                            scrollView.contentOffset.y = savedOffset
//                        }
//                    }
//                    self.childKeyValueObservations[key] = keyValueObservation
//                }
            }
        }
    }
    
    /**
     * 清除保存的偏移量映射表
     */
    private func clearScrollViewOffsets() {
        scrollViewOffsetMap.removeAll()
        
//        let observations = childKeyValueObservations
//        observations.values.forEach({ $0.invalidate() })
//        childKeyValueObservations.removeAll()
    }
    
    /**
     * 保持所有ScrollView在顶部位置
     */
    private func keepScrollViewsAtTop() {
        guard let scrollViews = observedViews.allObjects as? [UIScrollView] else { return }
        
        for scrollView in scrollViews {
            scrollView.contentOffset.y = -scrollView.contentInset.top
        }
    }
    
    /** 向下滑动时，是否滑到顶部边界了
     * 检查所有观察的ScrollView是否都在顶部位置
     * @return 如果所有可见的ScrollView都在顶部则返回true
     */
    private func isAllScrollViewsAtTop() -> Bool {
        for object in observedViews.allObjects {
            if let scrollView = object as? UIScrollView,
               !scrollView.isHidden,
               scrollView.alpha > 0,
               scrollView.superview != nil {
                if scrollView.contentOffset.y > -scrollView.contentInset.top {
                    return false
                }
            }
        }
        return true
    }
    
    private func isAllScrollViewsSafe() -> Bool {
        for object in observedViews.allObjects {
            if let scrollView = object as? UIScrollView,
               !scrollView.isHidden,
               scrollView.alpha > 0,
               scrollView.superview != nil {
                if scrollView.contentOffset.y < -scrollView.contentInset.top {
                    return false
                }
            }
        }
        return true
    }
}

// MARK: - Gesture Delegate & Conflict Resolution

extension VDDetailGestureCoordinator: UIGestureRecognizerDelegate {
    
    /**
     * 判断手势是否应该接收触摸事件
     *
     * 注意：在UIControl上启用手势识别可能会影响其事件正常触发
     */
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // 重置状态，为新的手势做准备
        resetGestureState()
        return panGestureShouldBegin?() ?? true
    }

    /**
     * 控制多个手势识别器是否能够同时识别
     *
     * 手势冲突解决策略：
     * - 只允许垂直方向的滚动手势同时识别
     * - 排除TableView、CollectionView等复杂滚动组件
     * - 将符合条件的ScrollView添加到观察列表
     *
     * @param gestureRecognizer 当前手势识别器
     * @param otherGestureRecognizer 其他手势识别器
     * @return 是否允许同时识别
     */
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//        print("sgx >> gesture recognizer: \(otherGestureRecognizer.view) is scrollView \(otherGestureRecognizer.view as? UIScrollView)")
        // 1. 排除自身手势冲突
        if otherGestureRecognizer.view == self {
            print("sgx >> gesture recognizer: false1")
            return false
        }
        
        // 2. 确保当前手势是平移手势
        guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer else {
            print("sgx >> gesture recognizer: false2")
            return false
        }
        
        // 3. 只允许垂直方向的手势同时识别
        let velocity = panGesture.velocity(in: panGesture.view?.superview)
        if abs(velocity.x) > abs(velocity.y) {
            // 水平方向滑动优先级更高，不允许同时识别
            print("sgx >> gesture recognizer: false3")
            return false
        }
        
        // 4. 确保另一个手势的view是ScrollView
        guard let scrollView = otherGestureRecognizer.view as? UIScrollView else {
            print("sgx >> gesture recognizer: false4")
            return false
        }
        
        // 5. 排除复杂的滚动组件
        if isComplexScrollComponent(scrollView, otherGestureRecognizer: otherGestureRecognizer) {
            print("sgx >> gesture recognizer: false5")
            return false
        }
        //print("sgx >> gesture recognizer: true:\(otherGestureRecognizer.view)")
        // 6. 添加到观察列表并允许同时识别
        addObservedScrollView(scrollView)
        return true
    }
    
    /**
     * 判断是否为复杂的滚动组件
     * @param scrollView 要判断的ScrollView
     * @param otherGestureRecognizer 其他手势识别器
     * @return 是否为复杂组件
     */
    private func isComplexScrollComponent(_ scrollView: UIScrollView, otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // TableView和CollectionView有自己的手势处理逻辑
        if scrollView.superview?.isKind(of: UITableView.self) == true ||
           scrollView.superview?.isKind(of: UICollectionView.self) == true {
            return true
        }
        
        // TableViewCell内容视图也需要排除
        if let cellContentViewClass = NSClassFromString("UITableViewCellContentView"),
           otherGestureRecognizer.view?.superview?.isKind(of: cellContentViewClass) == true {
            return true
        }
        
        return false
    }
}
