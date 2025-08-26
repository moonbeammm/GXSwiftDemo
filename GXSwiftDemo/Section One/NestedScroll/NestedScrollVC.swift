//
//  VDDetailContainerBlocV3.swift
//  GXSwiftDemo
//
//  Created by 孙广鑫 on 2025/7/15.
//

import UIKit
import Stevia

class MockInfo {
    var videoWidth: CGFloat = 16
    var videoHeight: CGFloat = 9
    var playbackState: BFCPlayerPlaybackState = .prepared
    var isFullscreen: Bool = false
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
    
    private var lockScenes: Set<String> = Set()
    /// 滑动管理
    lazy var scrollManager: VDDetailScrollManager = {
        let t = VDDetailScrollManager(with: self.tabContainerVC.view)
        tabContainerVC.view.layer.masksToBounds = true
        tabContainerVC.view.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        tabContainerVC.view.layer.cornerRadius = 12
        t.onPanGestureDidScroll = { [weak self] offset in
            guard let self = self else { return }
            self.onPanGestureDidScroll(with: offset, info: self.layoutInfo)
        }
        t.onPanGestureEndScroll = { [weak self] offset, velocity in
            self?.onPanGestureEndScroll(offset, velocity: velocity)
        }
        return t
    }()
    
    lazy var playerVC: UIViewController = {
        let t = UIViewController()
        t.view.backgroundColor = .red
        return t
    }()
    lazy var blackBar: UIView = {
        let t = UIView()
        t.backgroundColor = .black.withAlphaComponent(0.5)
        return t
    }()
    lazy var tabContainerVC: TabContainerVC = {
        let t = TabContainerVC()
        t.view.backgroundColor = .blue
        return t
    }()
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
        configSubviews()
        initialLayout()
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
        reloadLayoutType("safe area insets did change", autoExpand: true)
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        switch traitCollection.verticalSizeClass {
        case .regular:
            mockInfo.isFullscreen = false
            reloadLayoutType("trait collection did change", autoExpand: true)
        case .compact:
            mockInfo.isFullscreen = true
            reloadLayoutType("trait collection did change", autoExpand: true)
        default: break
        }
    }
}

extension VDDetailContainerBlocV3 {
    public func lock(_ scene: String) {
        guard !lockScenes.contains(scene) else {
            print("\(Constant.tag) lockScenes has contains \(scene)")
            return
        }
        print("\(Constant.tag) lock scenes: \(scene)")
        lockScenes.insert(scene)
        changeLayoutType(scene, toType: .horizonToHorizon, autoExpand: true)
    }
    
    public func unlock(_ scene: String, autoExpand: Bool = false) {
        lockScenes.remove(scene)
        guard lockScenes.isEmpty else {
            print("\(Constant.tag) \(scene) unlock failed. current locks: \(lockScenes)")
            return
        }
        print("\(Constant.tag) unlock scenes: \(scene)")
        let to = layoutType(with: mockInfo.playbackState)
        changeLayoutType(scene, toType: to, autoExpand: autoExpand)
    }

    public func changeLayoutType(_ scene: String, toType: LayoutType, autoExpand: Bool) {
        print("\(Constant.tag) \(scene) change layout type to:\(toType) auto expand:\(autoExpand)")
        lockScenes.removeAll()
        changeLayoutType(to: toType, autoExpand: autoExpand)
    }
    
    public func reloadLayoutType(_ scene: String, autoExpand: Bool) {
        let offset = autoExpand ? 0.0 : scrollManager.offset
        scrollManager.offset = offset
        reloadConstraints(with: offset, info: layoutInfo)
    }
}

extension VDDetailContainerBlocV3 {
    private func initialLayout() {
        let to = layoutType(with: mockInfo.playbackState)
        changeLayoutType("initial layout", toType: to, autoExpand: true)
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
            mockInfo.videoHeight = mockInfo.videoHeight == 9 ? 18:9
            unlock("vertical btn click", autoExpand: true)
        } else if btn == fullScreenBtn {
            rotate(to: !mockInfo.isFullscreen)
        } else if btn == poperBtn {
            showPopup()
        }
    }
    
    private func showPopup() {
        let popupVC = PopupViewController()
        popupVC.showPopup(in: tabContainerVC)
    }
    
    private func layoutType(with playbackState: BFCPlayerPlaybackState) -> LayoutType {
        if playbackState == .stopped {
            // let to: LayoutType = enableFold ? .ceillingToHorizon : .horizonToHorizon
            return .horizonToHorizon
        } else if playbackState == .paused {
            // let to: LayoutType = resolve(VDCoverBloc.self).isShowCover ? .horizonToHorizon : .ceillingToMax
            return .ceillingToMax
        } else if playbackState == .failed {
            return .horizonToHorizon
        } else {
            return .horizonToMax
        }
    }
}

extension VDDetailContainerBlocV3 {
    func configSubviews() {
        _configSubviews()
        
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
