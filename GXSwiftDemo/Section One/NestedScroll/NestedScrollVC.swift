//
//  VDDetailContainerBlocV3.swift
//  GXSwiftDemo
//
//  Created by 孙广鑫 on 2025/7/15.
//

import UIKit
import Stevia

enum FF {
    case A // 不可以下滑进story，无广告全隐藏 - 对照组
    case B // 可以下滑进story，无广告全隐藏
    case C // 可以下滑进story，有广告全隐藏
    // 问题：开始上滑的时候offset.y为负数，会先清除offset，导致offset会跟广告位一起上移
    // 问题：下滑时，底部会出现白条
    case D // 不可以下滑进story，有广告全隐藏 ！！ 必须禁用下滑bounces
    
    var canDraggingToStory: Bool {
        return self == .B || self == .C
    }
}

class MockInfo {
    var videoWidth: CGFloat = 16
    var videoHeight: CGFloat = 9
    var playbackState: BFCPlayerPlaybackState = .prepared
    var isFullscreen: Bool = false
    static let ff: FF = .C
    static let hitBlackBar: Bool = true
}

enum BFCPlayerPlaybackState {
    case prepared
    case playing
    case paused
    case stopped
    case failed
}

class VDDetailContainerBlocV3: UIViewController {
    /// 从router拿宽高作为初始化layout，如果没有则使用horizonHeight做兜底
    var layoutInfo: LayoutInfo = .init(min: 0, max: 0, extraHeight: 0)
    /// 初始化默认状态为.normal，因为开启自动播放的竖屏视频进入详情页默认是展开的。
    /// 如果未开启自动播放的竖屏视频进入详情页，则在coverBloc内自己调用lock逻辑，
    /// 或者在这里处理？在这里处理不合理，我一个布局类去依赖封面出不出，没有封面类了我就不布局了？
    var layoutType: LayoutType = .horizonToMax
    /// 滑动阈值，简介向下滑动超过该阈值则进入story，否则回弹
    var pullDismissThreshod: CGFloat = -100.0

    // ✅ ExtraTab状态机
    enum ExtraTabState {
        case expanded      // 完全展开
        case collapsing    // 收起动画中
        case collapsed     // 完全收起
        case expanding     // 展开动画中
    }

    private var extraTabState: ExtraTabState = .expanded

    private var isExtraTabAnimating: Bool {
        return extraTabState == .collapsing || extraTabState == .expanding
    }

    private var lockScenes: Set<String> = Set()
    /// 滑动管理
    lazy var scrollManager: VDDetailGestureCoordinator = {
        let t = VDDetailGestureCoordinator(with: self.tabContainerVC.view)
//    case A // 不可以下滑进story，无广告全隐藏 - 对照组
//    case B // 可以下滑进story，无广告全隐藏
//    case C // 可以下滑进story，有广告全隐藏
//    case D // 不可以下滑进story，有广告全隐藏
        switch MockInfo.ff {
        case .A:
            t.shouldManageScrollViewBounces = false
            t.enableReachMaxOffset = false
        case .B:
            t.shouldManageScrollViewBounces = true
            t.enableReachMaxOffset = false
            
            tabContainerVC.view.layer.masksToBounds = true
            tabContainerVC.view.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
            tabContainerVC.view.layer.cornerRadius = 12
        case .C:
            t.shouldManageScrollViewBounces = true
            t.enableReachMaxOffset = true
            
            tabContainerVC.view.layer.masksToBounds = true
            tabContainerVC.view.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
            tabContainerVC.view.layer.cornerRadius = 12
        case .D:
            t.shouldManageScrollViewBounces = true
            t.enableReachMaxOffset = true
        }
        
        t.panGestureShouldBegin = { [weak self] in
            guard let self = self else { return false }
            // ✅ 动画期间禁止手势
            if self.isExtraTabAnimating {
                return false
            }
            // Lock场景
            if !self.lockScenes.isEmpty {
                return false
            }
            return true
        }
        t.onPanGestureBeginScroll = { [weak self] in
            guard let self = self else { return }
            self.onPanGestureBeginScroll(self.layoutInfo)
        }
        t.onPanGestureDidScroll = { [weak self] offset in
            guard let self = self else { return }
            self.onPanGestureDidScroll(with: offset, info: self.layoutInfo)
        }
        t.onPanGestureEndScroll = { [weak self] offset, velocity in
            self?.onPanGestureEndScroll(offset, velocity: velocity)
        }
        // ✅ 设置触发回调
        t.onReachMaxOffsetWhileScrollingUp = { [weak self] in
            return self?.handleReachMaxWhileScrollingUp() ?? false
        }
        t.onReachMaxOffsetWhileScrollingDown = { [weak self] in
            return self?.handleReachMaxWhileScrollingDown() ?? false
        }
        return t
    }()
    
    lazy var playerVC: UIViewController = {
        let t = UIViewController()
        t.view.backgroundColor = .red

        let label = UILabel()
        label.text = "播放器区域"
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        t.view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: t.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: t.view.centerYAnchor)
        ])

        return t
    }()
    lazy var blackBar: UIView = {
        let t = UIView()
        t.backgroundColor = .black.withAlphaComponent(0.5)
        
        let label = UILabel()
        label.text = "黑条"
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        t.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: t.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: t.centerYAnchor)
        ])
        
        return t
    }()
    lazy var tabContainerBloc: TabContainerBloc = {
        let t = TabContainerBloc()
        return t
    }()
    var tabContainerVC: BBMPTabController {
        tabContainerBloc.tabContainerVC
    }
    var contentVC: UIViewController? {
        self
    }
    lazy var playingBtn: UIButton = {
        let t = UIButton(type: .custom)
        t.setTitle("playing", for: .normal)
        t.addTarget(self, action: #selector(btnClick(_:)), for: .touchUpInside)
        t.backgroundColor = .purple
        return t
    }()
    lazy var pauseBtn: UIButton = {
        let t = UIButton(type: .custom)
        t.setTitle("pause", for: .normal)
        t.addTarget(self, action: #selector(btnClick(_:)), for: .touchUpInside)
        t.backgroundColor = .purple
        return t
    }()
    lazy var lockBtn: UIButton = {
        let t = UIButton(type: .custom)
        t.setTitle("lock", for: .normal)
        t.addTarget(self, action: #selector(btnClick(_:)), for: .touchUpInside)
        t.backgroundColor = .purple
        return t
    }()
    lazy var verticalBtn: UIButton = {
        let t = UIButton(type: .custom)
        t.setTitle("vertical", for: .normal)
        t.addTarget(self, action: #selector(btnClick(_:)), for: .touchUpInside)
        t.backgroundColor = .purple
        return t
    }()
    lazy var fullScreenBtn: UIButton = {
        let t = UIButton(type: .custom)
        t.setTitle("fullScreen", for: .normal)
        t.addTarget(self, action: #selector(btnClick(_:)), for: .touchUpInside)
        t.backgroundColor = .purple
        return t
    }()
    lazy var poperBtn: UIButton = {
        let t = UIButton(type: .custom)
        t.setTitle("popup", for: .normal)
        t.addTarget(self, action: #selector(btnClick(_:)), for: .touchUpInside)
        t.backgroundColor = .purple
        return t
    }()
    // mock数据
    lazy var mockInfo: MockInfo = {
        let t = MockInfo()
        return t
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        _configSubviews()
        initialLayout()
        tabContainerVC.bfc_reloadData()
        // 如果不调用，当前vc在第一次返回supportedInterfaceOrientations为portrait的话，后续就算更改返回值，也无法感应重力感应。
        // 因为系统不会再次询问了
        bfc_openGravity()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        navigationController?.navigationBar.isHidden = false
    }
    override public var shouldAutorotate: Bool {
        if bfc_forceRotate == true {
            return true
        }
        return super.shouldAutorotate
    }

    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if bfc_forceRotate == true {
            return bfc_forceOrientation
        }
        return super.supportedInterfaceOrientations
    }
    
    public func rotate(to fullScreen: Bool) {
        mockInfo.isFullscreen = fullScreen
        fullScreen ? bfc_rotateToLandscape() : bfc_rotateToPortrait()
    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        reloadLayout(with: "safe area insets did change", offset: 0.0)
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        switch traitCollection.verticalSizeClass {
        case .regular:
            mockInfo.isFullscreen = false
            reloadLayout(with: "trait collection did change", offset: 0.0)
        case .compact:
            mockInfo.isFullscreen = true
            reloadLayout(with: "trait collection did change", offset: 0.0)
        default: break
        }
    }
}

extension VDDetailContainerBlocV3 {
    public func lock(_ scene: String) {
        guard !lockScenes.contains(scene) else {
            return
        }
        lockScenes.insert(scene)
        reloadLayout(with: "lock scene: \(scene)", offset: 0.0)
    }
    
    public func unlock(_ scene: String, autoExpand: Bool = false) {
        lockScenes.remove(scene)
        guard lockScenes.isEmpty else {
            return
        }
        reloadLayout(with: "unlock scene: \(scene)", offset: autoExpand ? 0.0:nil)
    }

    public func reloadLayout(with scene: String, offset: CGFloat? = nil, updateCanvas: Bool = true, animation: Bool = false) {
        let to = layoutType(with: mockInfo.playbackState)
        _changeLayoutType(to: to, offset: offset, updateCanvas: updateCanvas, animation: animation)
    }
}

extension VDDetailContainerBlocV3 {
    private func initialLayout() {
        reloadLayout(with: "initial layout", offset: 0.0)
    }
    
    @objc
    private func btnClick(_ btn: UIButton) {
        if btn == playingBtn {
            mockInfo.playbackState = .playing
            unlock("playing btn click")
        } else if btn == pauseBtn {
            mockInfo.playbackState = .paused
            unlock("pause btn click")
        } else if btn == lockBtn {
            lock("lock btn click")
        } else if btn == verticalBtn {
            mockInfo.videoHeight = mockInfo.videoHeight == 9 ? 11:9
            unlock("vertical btn click", autoExpand: true)
        } else if btn == fullScreenBtn {
            rotate(to: !mockInfo.isFullscreen)
        } else if btn == poperBtn {
            if tabContainerBloc.extraBarTopMargin == 0 {
                tabContainerBloc.extraBarTopMargin = -80
            } else {
                tabContainerBloc.extraBarTopMargin = 0
            }
            tabContainerVC.bfc_reloadExtraTab()

            // ✅ 重置ExtraTab状态
            if tabContainerBloc.extraTabView != nil {
                extraTabState = .expanded
                tabContainerBloc.extraTabView?.transform = .identity
            } else {
                extraTabState = .expanded  // 没有ExtraTab时也设为expanded
            }
        }
    }
    
    private func layoutType(with playbackState: BFCPlayerPlaybackState) -> LayoutType {
        if playbackState == .stopped {
            return .horizonToHorizon
        } else if playbackState == .paused {
            return .ceillingToMax
        } else if playbackState == .failed {
            return .horizonToHorizon
        } else {
            return .horizonToMax
        }
    }
}

extension VDDetailContainerBlocV3 {
    func _configSubviews() {
        configSubviews()
        
        view.addSubview(playingBtn)
        view.addSubview(pauseBtn)
        view.addSubview(lockBtn)
        view.addSubview(verticalBtn)
        view.addSubview(fullScreenBtn)
        view.addSubview(poperBtn)
        
        playingBtn.translatesAutoresizingMaskIntoConstraints = false
        pauseBtn.translatesAutoresizingMaskIntoConstraints = false
        lockBtn.translatesAutoresizingMaskIntoConstraints = false
        verticalBtn.translatesAutoresizingMaskIntoConstraints = false
        fullScreenBtn.translatesAutoresizingMaskIntoConstraints = false
        poperBtn.translatesAutoresizingMaskIntoConstraints = false
        
        playingBtn.widthAnchor.constraint(equalToConstant: 60).isActive = true
        playingBtn.heightAnchor.constraint(equalToConstant: 40).isActive = true
        pauseBtn.widthAnchor.constraint(equalToConstant: 60).isActive = true
        pauseBtn.heightAnchor.constraint(equalToConstant: 40).isActive = true
        lockBtn.widthAnchor.constraint(equalToConstant: 60).isActive = true
        lockBtn.heightAnchor.constraint(equalToConstant: 40).isActive = true
        verticalBtn.widthAnchor.constraint(equalToConstant: 60).isActive = true
        verticalBtn.heightAnchor.constraint(equalToConstant: 40).isActive = true
        fullScreenBtn.widthAnchor.constraint(equalToConstant: 60).isActive = true
        fullScreenBtn.heightAnchor.constraint(equalToConstant: 40).isActive = true
        poperBtn.widthAnchor.constraint(equalToConstant: 60).isActive = true
        poperBtn.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        playingBtn.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        playingBtn.topAnchor.constraint(equalTo: view.topAnchor, constant: 100).isActive = true
        pauseBtn.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        pauseBtn.topAnchor.constraint(equalTo: playingBtn.bottomAnchor, constant: 10).isActive = true
        lockBtn.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        lockBtn.topAnchor.constraint(equalTo: pauseBtn.bottomAnchor, constant: 10).isActive = true
        verticalBtn.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        verticalBtn.topAnchor.constraint(equalTo: lockBtn.bottomAnchor, constant: 10).isActive = true
        fullScreenBtn.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        fullScreenBtn.topAnchor.constraint(equalTo: verticalBtn.bottomAnchor, constant: 10).isActive = true
        poperBtn.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        poperBtn.topAnchor.constraint(equalTo: fullScreenBtn.bottomAnchor, constant: 10).isActive = true
    }
}

// MARK: - ExtraTab Animation
extension VDDetailContainerBlocV3 {

    /// ✅ 向上滑动到达临界点的处理
    private func handleReachMaxWhileScrollingUp() -> Bool {
        guard let extraTabView = tabContainerBloc.extraTabView else {
            return false  // 没有ExtraTab，不拦截
        }

        switch extraTabState {
        case .expanded:
            // 触发收起动画
            collapseExtraTab()
            return true  // 拦截，动画期间禁止ScrollView滚动

        case .collapsing:
            // 动画进行中，继续拦截
            return true

        case .collapsed:
            // 已经收起，不拦截，允许ScrollView滚动
            return false

        case .expanding:
            // 理论上不应该出现（向上滑时不应该在展开）
            return true
        }
    }

    /// ✅ 向下滑动到达临界点的处理
    private func handleReachMaxWhileScrollingDown() -> Bool {
        guard let extraTabView = tabContainerBloc.extraTabView else {
            return false
        }

        switch extraTabState {
        case .collapsed:
            // 触发展开动画
            expandExtraTab()
            return true  // 拦截，动画期间禁止播放器展开

        case .expanding:
            // 动画进行中，继续拦截
            return true

        case .expanded:
            // 已经展开，不拦截，允许播放器继续展开
            return false

        case .collapsing:
            // 理论上不应该出现
            return true
        }
    }

    /// ✅ 收起ExtraTab动画
    private func collapseExtraTab() {
        guard let extraTabView = tabContainerBloc.extraTabView else { return }

        extraTabState = .collapsing
        extraTabView.collapse()

        let extraTabHeight = extraTabView.frame.height
        let duration: TimeInterval = 0.25

        UIView.animate(withDuration: duration) {
            print("收起 animation")
            // ExtraTabView向上移动
            extraTabView.transform = CGAffineTransform(translationX: 0, y: -(extraTabHeight/2.0))
            // ✅ Container也向上移动，消除断层
            self.tabContainerVC.bfc_updateContainerTopMargin(extraTabHeight/2.0, animated: false)
        } completion: { [weak self] finished in
            guard let self = self else { return }
            self.extraTabState = .collapsed
        }

    }

    /// ✅ 展开ExtraTab动画
    private func expandExtraTab() {
        guard let extraTabView = tabContainerBloc.extraTabView else { return }

        extraTabState = .expanding
        extraTabView.expand()

        let extraTabHeight = extraTabView.frame.height
        let duration: TimeInterval = 0.25

        // 3. 执行动画：ExtraTabView向下移动 + Container向下移动
        UIView.animate(withDuration: duration) {
            // ExtraTabView恢复原位
            extraTabView.transform = .identity
            // ✅ Container也恢复原位，保持连续
            self.tabContainerVC.bfc_updateContainerTopMargin(extraTabHeight, animated: false)
        } completion: { [weak self] finished in
            guard let self = self else { return }
            self.extraTabState = .expanded
        }
    }
}
