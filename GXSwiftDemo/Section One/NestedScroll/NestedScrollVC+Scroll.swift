//
//  VDDetailContainerBlocV3+Scroll.swift
//  BBVideoDetail
//
//  Created by 孙广鑫 on 2025/7/28.
//

import UIKit
import Stevia

enum LayoutType {
    case ceillingToMax // 最大高度到最大，最小高度粉条
    case ceillingToHorizon // 最大高度16：9，最小高度粉条
    case horizonToMax // 最大高度到最大，最小高度16：9
    case horizonToHorizon // 最大最小都是16：9
}

struct LayoutInfo {
    var minHeight: CGFloat
    var maxHeight: CGFloat
    var extraHeight: CGFloat
    var extraOffset: CGFloat
    init(min: CGFloat, max: CGFloat,
         extraHeight: CGFloat,
         extraOffset: CGFloat = 0) {
        self.minHeight = min
        self.maxHeight = max
        self.extraHeight = extraHeight
        self.extraOffset = extraOffset
    }
    func isEqual(_ object: LayoutInfo) -> Bool {
        if abs(minHeight - object.minHeight) < 0.01 &&
           abs(maxHeight - object.maxHeight) < 0.01 &&
           abs(extraHeight - object.extraHeight) < 0.01 &&
           abs(extraOffset - object.extraOffset) < 0.01 {
            return true
        } else {
            return false
        }
    }
}

// MARK: Update Layout Info

extension VDDetailContainerBlocV3 {
    func changeLayoutType(to type: LayoutType, autoExpand: Bool) {
        layoutType = type
        let newLayout = layoutInfo(with: type)
        guard !newLayout.isEqual(self.layoutInfo), let view = contentVC?.view else {
            print("\(Constant.tag) change layout type to:\(type) cancel, layout info is equal.")
            return
        }
        
        let lastPlayerHeight = playerVC.view.heightConstraint?.constant ?? self.layoutInfo.maxHeight
        self.layoutInfo = newLayout

        let maxOffset = newLayout.maxHeight + newLayout.extraOffset - newLayout.minHeight
        let minOffset = -(view.bounds.height - newLayout.maxHeight - newLayout.extraHeight - Constant.safeAreaTop) // 如果当前视频不允许进入story，则min为0
        
        let pullDismissThreshod = -(view.bounds.height - newLayout.maxHeight - newLayout.extraHeight - Constant.safeAreaTop) / 3.0
        
        var newOffset: CGFloat
        if autoExpand {
            newOffset = 0.0
        } else {
            newOffset = newLayout.maxHeight + newLayout.extraHeight - lastPlayerHeight
        }
        newOffset = newOffset > maxOffset ? 0.0 : newOffset
        
        print("\(Constant.tag) change layout type to:\(type) newOffset:\(newOffset) min:\(minOffset) max:\(maxOffset) last player height:\(lastPlayerHeight) pullDismissThreshod:\(pullDismissThreshod)")
        
        self.pullDismissThreshod = pullDismissThreshod
        scrollManager.offsetRange = (min: ceil(minOffset), max: floor(maxOffset))
        scrollManager.offset = newOffset
        onPanGestureDidScroll(with: newOffset, info: newLayout)
    }
    
    func layoutInfo(with type: LayoutType) -> LayoutInfo {
        var layoutInfo: LayoutInfo
        let maxHeight = Constant.SCREEN_WIDTH / minRatio()
        switch type {
        case .horizonToMax:
            layoutInfo = LayoutInfo(min: Constant.horizonHeight,
                              max: maxHeight,
                              extraHeight: Constant.blackBarHeight)
        case .ceillingToMax:
            layoutInfo = LayoutInfo(min: Constant.ceilingHeight,
                              max: maxHeight,
                              extraHeight: Constant.blackBarHeight,
                              extraOffset: Constant.blackBarHeight)
        case .horizonToHorizon:
            layoutInfo = LayoutInfo(min: Constant.horizonHeight,
                              max: Constant.horizonHeight,
                              extraHeight: Constant.blackBarHeight)
        case .ceillingToHorizon:
            layoutInfo = LayoutInfo(min: Constant.ceilingHeight,
                              max: Constant.horizonHeight,
                              extraHeight: Constant.blackBarHeight)
        }
        return layoutInfo
    }
}

// MARK: Scroll

extension VDDetailContainerBlocV3 {
    func onPanGestureEndScroll(_ offset: CGFloat, velocity: CGFloat) {
        print("\(Constant.tag) on pan gesture end scroll offset:\(offset) velocity:\(velocity)")
        guard offset < 0 else { return }
        if offset <= pullDismissThreshod || velocity * 0.2 > 500 { // dismiss
            let offset = view.bounds.height
            curveEaseOutAnimation(alpha: 0.0, offset: offset, endOffset: -offset)
        } else {
            curveEaseOutAnimation(alpha: 1.0, offset: offset, endOffset: 0.0)
        }
    }
    
    func onPanGestureDidScroll(with offset: CGFloat, info: LayoutInfo) {
        var playerHeight: CGFloat
        let topMargin = info.maxHeight + info.extraHeight + Constant.safeAreaTop - offset
        
        if topMargin <= (Constant.horizonHeight + Constant.safeAreaTop) {
            playerHeight = topMargin - Constant.safeAreaTop
            print("\(Constant.tag) 在小于播放器高度区域滚动 playerheight:\(playerHeight) topmargin:\(topMargin)")
        } else if topMargin < (Constant.horizonHeight + info.extraHeight + Constant.safeAreaTop),
                  topMargin > (Constant.horizonHeight + Constant.safeAreaTop) {
            playerHeight = Constant.horizonHeight
            
            let alpha = (topMargin - playerHeight - Constant.safeAreaTop) / info.extraHeight
            let result = min(max(alpha, 0.0), 1.0)
            // playerBloc.player.context.controlWidgetService?.alpha = result
            print("\(Constant.tag) 在黑条范围内滚动 playerheight:\(playerHeight) topmargin:\(topMargin) alpha:\(alpha) result:\(result)")
        } else if info.maxHeight > Constant.horizonHeight,
                  topMargin >= (Constant.horizonHeight + info.extraHeight + Constant.safeAreaTop),
                  topMargin < (info.maxHeight + info.extraHeight + Constant.safeAreaTop) {
            playerHeight = topMargin - info.extraHeight - Constant.safeAreaTop
            print("\(Constant.tag) 在大于16：9，小于竖屏最大高度区域滚动（应该只有竖屏视频才会进） playerheight:\(playerHeight) topmargin:\(topMargin)")
        } else {
            playerHeight = info.maxHeight
            
            let alpha = 1 - (offset / pullDismissThreshod)
            let result = min(max(alpha, 0.0), 1.0)
            // playerBloc.player.context.controlWidgetService?.alpha = result
            print("\(Constant.tag) 在超出播放器最大高度区域滚动 playerheight:\(playerHeight) topmargin:\(topMargin) alpha:\(alpha) result:\(result)")
        }
        
        updatePlayerConstraints(playerHeight, extraHeight: info.extraHeight)
        updateTabContainerConstraints(isFullScreen ? Constant.SCREEN_WIDTH : topMargin, info: info)
        
        contentVC?.setNeedsStatusBarAppearanceUpdate()
        contentVC?.setNeedsUpdateOfHomeIndicatorAutoHidden()
    }
}

// MARK: Update Constraints

extension VDDetailContainerBlocV3 {
    func updatePlayerConstraints(_ playerHeight: CGFloat, extraHeight: CGFloat) {
        guard let contentVC = contentVC else {
            return
        }
        playerVC.view.topConstraint?.constant = Constant.safeAreaTop
        if isFullScreen {
            if let topConstraint = playerVC.view.topConstraint {
                topConstraint.constant = isVerticalScreen ? 0 : Constant.safeAreaTop
            }

            if let heightConstraint = playerVC.view.heightConstraint {
                heightConstraint.isActive = false
            }

            if let bottomConstraint = playerVC.view.bottomConstraint {
                bottomConstraint.isActive = true
            } else {
                let playerViewBottomConstraint = playerVC.view.bottomAnchor.constraint(equalTo: contentVC.view.bottomAnchor)
                playerViewBottomConstraint.priority = UILayoutPriority.required
                playerViewBottomConstraint.isActive = true
            }
        } else {
            if let topConstraint = playerVC.view.topConstraint {
                topConstraint.constant = Constant.safeAreaTop
            }
            if let bottomConstraint = playerVC.view.bottomConstraint {
                bottomConstraint.isActive = false
            }
            let currentHeight = playerVC.view.heightConstraint?.constant ?? 0.0
            // let canvasHeight = playerBloc.player.context.playback?.canvasRect().height ?? 0.0
            guard abs(currentHeight - (playerHeight + extraHeight)) >= 1.0
                  /*|| abs(canvasHeight - (playerHeight + extraHeight)) >= 1.0*/ else {
                return
            }
            if let heightConstraint = playerVC.view.heightConstraint {
                heightConstraint.isActive = true
                heightConstraint.constant = playerHeight + extraHeight
            } else {
                let playerViewHeightConstraint = playerVC.view.heightAnchor.constraint(equalToConstant: playerHeight + extraHeight)
                playerViewHeightConstraint.priority = UILayoutPriority.required
                playerViewHeightConstraint.isActive = true
            }
        }
    }
    func updateTabContainerConstraints(_ topMargin: CGFloat, info: LayoutInfo) {
        tabContainerVC.view.topConstraint?.constant = topMargin
        // 没用用底部约束的原因是转屏全屏时高度会变成0
        tabContainerVC.view.heightConstraint?.constant = -info.minHeight
    }
}

// MARK: Helper

extension VDDetailContainerBlocV3 {
    func curveEaseOutAnimation(alpha: CGFloat, offset: CGFloat, endOffset: CGFloat) {
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.8,
            options: [.curveEaseOut],
            animations: { [weak self] in
                guard let view = self?.tabContainerVC.view else { return }
                view.alpha = alpha
                view.transform = CGAffineTransform(translationX: 0, y: offset)
            },
            completion: { [weak self] _ in
                guard let self = self else { return }
                self.tabContainerVC.view.alpha = 1.0
                self.tabContainerVC.view.transform = CGAffineTransform.identity

                self.scrollManager.offset = endOffset
                self.onPanGestureDidScroll(with: endOffset, info: self.layoutInfo)
            }
        )
    }
    private var isFullScreen: Bool {
        return mockInfo.isFullscreen
    }
    private var isVerticalScreen: Bool {
        return mockInfo.videoWidth < mockInfo.videoHeight
    }
    private func minRatio() -> CGFloat {
        let minRatio = Constant.SCREEN_WIDTH / (Constant.SCREEN_HEIGHT - Constant.bottomMinMargin - Constant.safeAreaTop - Constant.blackBarHeight)
        let currentRatio = mockInfo.videoWidth / mockInfo.videoHeight

        let result = max(minRatio, min(currentRatio, Constant.maxRatio))
        return result
    }
}

// MARK: Constraints

extension VDDetailContainerBlocV3 {
    func _configSubviews() {
        playerVC.willMove(toParent: self)
        self.addChild(playerVC)
        playerVC.didMove(toParent: self)
        tabContainerVC.willMove(toParent: self)
        self.addChild(tabContainerVC)
        tabContainerVC.didMove(toParent: self)
        
        view.addSubview(playerVC.view)
        playerVC.view.addSubview(blackBar)
        view.addSubview(tabContainerVC.view)
        
        playerVC.view.translatesAutoresizingMaskIntoConstraints = false
        playerVC.view.topAnchor.constraint(equalTo: view.topAnchor, constant: Constant.safeAreaTop).isActive = true
        playerVC.view.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        playerVC.view.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
        blackBar.translatesAutoresizingMaskIntoConstraints = false
        blackBar.leftAnchor.constraint(equalTo: playerVC.view.leftAnchor).isActive = true
        blackBar.rightAnchor.constraint(equalTo: playerVC.view.rightAnchor).isActive = true
        blackBar.heightAnchor.constraint(equalToConstant: Constant.blackBarHeight).isActive = true
        blackBar.bottomAnchor.constraint(equalTo: playerVC.view.bottomAnchor).isActive = true
        
        tabContainerVC.view.translatesAutoresizingMaskIntoConstraints = false
        tabContainerVC.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tabContainerVC.view.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        tabContainerVC.view.widthAnchor.constraint(equalToConstant: Constant.SCREEN_WIDTH).isActive = true
        tabContainerVC.view.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
    }
}

extension VDDetailContainerBlocV3 {
    enum Constant {
        static let tag = "布局"
        static let ceilingHeight: CGFloat = 64.0
        static let horizonHeight: CGFloat = SCREEN_WIDTH / (16.0 / 9.0)
        static let maxRatio: CGFloat = 16.0 / 9.0
        // https://www.tapd.cn/43363994/prong/stories/view/1143363994004352889
        // 播放器最大高度 = 屏高 - bottomMinMargin - safeAreaTop - blackBarHeight
        static let bottomMinMargin: CGFloat = 244.0
        static let blackBarHeight: CGFloat = 58.0 // TODO：接入实验！！！！
        static var safeAreaTop: CGFloat {
            guard let window = UIApplication.shared.keyWindow else { return 0.0 }
            let safeAreaTop = window.safeAreaInsets.bottom > 0 ? window.safeAreaInsets.top : 0.0
            return safeAreaTop
        }
        static var SCREEN_WIDTH: CGFloat {
            min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        }
        static var SCREEN_HEIGHT: CGFloat {
            max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        }
    }
}
